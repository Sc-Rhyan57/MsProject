local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

if shared.glrl_loaded then return end
shared.glrl_loaded = true

local Executor = {}
do
    if syn and syn.request then
        Executor.request = syn.request
    elseif http_request then
        Executor.request = http_request
    elseif request then
        Executor.request = request
    elseif http and http.request then
        Executor.request = http.request
    end

    if syn and syn.websocket then
        Executor.websocket = syn.websocket
    elseif WebSocket then
        Executor.websocket = WebSocket
    end

    if getcustomasset then
        Executor.getcustomasset = getcustomasset
    elseif getsynasset then
        Executor.getcustomasset = getsynasset
    end

    if writefile then
        Executor.writefile = writefile
    elseif syn and syn.write_file then
        Executor.writefile = syn.write_file
    end

    if readfile then
        Executor.readfile = readfile
    elseif syn and syn.read_file then
        Executor.readfile = syn.read_file
    end

    if gethwid then
        Executor.gethwid = gethwid
    end

    if setclipboard then
        Executor.clipboard = function(t) setclipboard(t) end
    elseif syn and syn.write_clipboard then
        Executor.clipboard = function(t) syn.write_clipboard(t) end
    elseif toclipboard then
        Executor.clipboard = function(t) toclipboard(t) end
    elseif writeclipboard then
        Executor.clipboard = function(t) writeclipboard(t) end
    elseif clipboard and clipboard.set then
        Executor.clipboard = function(t) clipboard.set(t) end
    end

    Executor.httpenabled = Executor.request ~= nil
end

local Notify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Msdoors/Msdoors.gg/refs/heads/main/Scripts/Msdoors/Notification/Source.lua"))()
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/ThemeManager.lua"))()

local LocalPlayer = Players.LocalPlayer

local Core = {
    version = "2.3.0",
    initialized = false,
    active = false,

    config = {
        light = "green",
        greenTime = {min = 50, max = 70},
        redTime = {min = 25, max = 35},
        currentRoom = 0,
        pausedByRoom = false,
        specialRoomNotified = false,
        gameWon = false,
        host = LocalPlayer.Name,
        voteActive = false,
        debugMode = false,
        autoRevive = true,
        itemDropTime = {min = 60, max = 120},
        specialRooms = {"SeekIntro", "Seek", "Halt"},
        commandsEnabled = true,
        modEnabled = true,
        difficulty = 1,
        roundNumber = 0,
        maxDifficulty = 5,
        winRoom = 100,
        entitySpawnEnabled = false,
        entitySpawnInterval = {min = 15, max = 45},
        redAcceptDelay = 2,
    },

    state = {
        votes = {yes = 0, no = 0},
        deadPlayers = {},
        playerScores = {},
        survivalTime = {},
        roundStats = {deaths = 0, itemsGiven = 0, entitiesSpawned = 0},
        lastDead = nil,
        acceptingMovement = false,
    },

    discord = {
        enabled = false,
        useWebhook = true,
        webhookUrl = "",
        botToken = "",
        channelId = "",
    },

    api = {
        enabled = false,
        url = "https://rlrl.onrender.com",
        sessionId = nil,
    },

    cache = {players = {}, lastUpdate = 0},

    items = {
        common = {"Flashlight","Lighter","Candle","Shakelight","Glowsticks","Vitamins","Bread","Cheese","Donut","Nanner","AloeVera","Key","Lockpick","BatteryPack","Compass","LibraryHintPaper","NannerPeel"},
        uncommon = {"Bulklight","Straplight","Lantern","Smoothie","GweenSoda","BandagePack","TipJar","StarVial","Shears","AlarmClock","LaserPointer","HintBook","KeyIron","KeyElectrical","KeyRetro","GeneratorFuse","LibraryHintPaperHard"},
        rare = {"Crucifix","SkeletonKey","StarJug","HolyGrenade","Bomb","BigBomb","Knockbomb","BoxingGloves","StopSign","SnakeBox","Multitool","BigPropTool"},
        legendary = {"RiftSmoothie","RiftCandle","RiftJar","StarBottle","GoldGun","KeyBackdoor"},
    },

    entities = {
        common = {"Eyes","Screech"},
        uncommon = {"Rush","Ambush","Glitch"},
        rare = {"Figure","A-60","Blitz","A-90"},
        legendary = {"A-120","Jeff The Killer","Lookman"},
    },

    specialEntities = {"A-90"},

    sounds = {
        green = "https://github.com/Sc-Rhyan57/MsProject/raw/refs/heads/main/projects/data/sounds/doll-green-light.mp3",
        red = "https://github.com/Sc-Rhyan57/MsProject/raw/refs/heads/main/projects/data/sounds/doll-red-light.mp3",
    },
}

local function CreateFlatList(tbl)
    local result = {}
    for _, items in pairs(tbl) do
        for _, item in ipairs(items) do
            table.insert(result, item)
        end
    end
    return result
end

Core.itemsList = CreateFlatList(Core.items)
Core.entitiesList = CreateFlatList(Core.entities)

local function XorCrypt(data, key)
    local result = {}
    for i = 1, #data do
        local byte = string.byte(data, i)
        local kbyte = string.byte(key, ((i - 1) % #key) + 1)
        table.insert(result, string.char(bit32.bxor(byte, kbyte)))
    end
    return table.concat(result)
end

local function GenerateHWID()
    local ok, hwid = pcall(function()
        if Executor.gethwid then return Executor.gethwid() end
        return nil
    end)
    if ok and hwid and type(hwid) == "string" and #hwid > 0 then return hwid end
    local clientId = game:GetService("RbxAnalyticsService"):GetClientId()
    if clientId and clientId ~= "" then return clientId end
    return "unknown-" .. tostring(tick())
end

local function GetAudioFromGit(url, name)
    if not Executor.writefile or not Executor.getcustomasset then return nil end
    local fileName = "customObject_Sound_" .. name .. ".mp3"
    local ok, data = pcall(function() return game:HttpGet(url) end)
    if not ok then return nil end
    Executor.writefile(fileName, data)
    return Executor.getcustomasset(fileName)
end

local soundCache = {}
local function PlaySound(url, name, volume)
    if not soundCache[name] then
        soundCache[name] = GetAudioFromGit(url, name)
    end
    local soundId = soundCache[name]
    if not soundId then return nil end
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 5
    sound.Parent = workspace
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
    return sound
end

local function Caption(message)
    pcall(function()
        require(LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption(message, true)
    end)
end

local function NotifyPlayer(title, desc, time, color)
    Notify({
        Title = title,
        Description = desc,
        Reason = "",
        Color = color or Color3.fromRGB(0, 255, 0),
        Style = "Doors",
        Duration = time or 6,
        NotifyStyle = "Linoria",
    })
end

local function SendChat(message)
    if Core.config.debugMode then message = "[DEBUG] " .. message end
    task.spawn(function()
        pcall(function()
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                TextChatService.TextChannels.RBXGeneral:SendAsync(message)
            else
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
            end
        end)
    end)
end

local function ExecuteCommand(cmd, args)
    ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(cmd, args)
end

local function IsPlayerAlive(player)
    return player.Character
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.Health > 0
end

local function IsPlayerMoving(player)
    return player.Character
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.MoveDirection.Magnitude > 0
end

local function GetPlayerHealth(player)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        return math.max(1, player.Character.Humanoid.Health)
    end
    return 100
end

local function UpdatePlayerCache()
    local currentTime = tick()
    if currentTime - Core.cache.lastUpdate < 0.5 then return Core.cache.players end
    Core.cache.players = Players:GetPlayers()
    Core.cache.lastUpdate = currentTime
    return Core.cache.players
end

local function GetAlivePlayers()
    local alive = {}
    for _, player in ipairs(UpdatePlayerCache()) do
        if IsPlayerAlive(player) then table.insert(alive, player) end
    end
    return alive
end

local function BuildPlayersList()
    local list = {}
    for _, player in ipairs(UpdatePlayerCache()) do
        table.insert(list, {
            name = player.Name,
            displayName = player.DisplayName,
            userId = player.UserId,
            alive = IsPlayerAlive(player),
        })
    end
    return list
end

local function DiscordSend(content, embeds)
    if not Core.discord.enabled or not Executor.httpenabled then return end
    task.spawn(function()
        local OSTime = os.time()
        local Time = os.date("!*t", OSTime)
        local timestamp = string.format("%d-%02d-%02dT%02d:%02d:%02dZ", Time.year, Time.month, Time.day, Time.hour, Time.min, Time.sec)

        local body = {content = content or "", tts = false, embeds = {}}
        if embeds then
            for _, e in ipairs(embeds) do
                e.timestamp = e.timestamp or timestamp
                table.insert(body.embeds, e)
            end
        end

        if Core.discord.useWebhook and Core.discord.webhookUrl ~= "" then
            pcall(function()
                Executor.request({
                    Url = Core.discord.webhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(body),
                })
            end)
        elseif not Core.discord.useWebhook and Core.discord.botToken ~= "" and Core.discord.channelId ~= "" then
            pcall(function()
                Executor.request({
                    Url = "https://discord.com/api/v10/channels/" .. Core.discord.channelId .. "/messages",
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json",
                        ["Authorization"] = "Bot " .. Core.discord.botToken,
                    },
                    Body = HttpService:JSONEncode(body),
                })
            end)
        end
    end)
end

local function DiscordEvent(title, desc, color)
    DiscordSend(nil, {{
        title = title,
        description = desc,
        color = color or 3066993,
        footer = {text = "GLRL v" .. Core.version .. " | " .. game.PlaceId},
    }})
end

local function ApiUpdate(data)
    if not Core.api.enabled or not Core.api.sessionId or not Executor.httpenabled then return end
    local alivePlayers = GetAlivePlayers()
    local allPlayers = UpdatePlayerCache()
    data.alive = #alivePlayers
    data.total = #allPlayers
    data.players = BuildPlayersList()
    data.room = data.room or Core.config.currentRoom
    data.difficulty = data.difficulty or Core.config.difficulty
    data.itemsGiven = Core.state.roundStats.itemsGiven
    data.entitiesSpawned = Core.state.roundStats.entitiesSpawned
    data.deaths = Core.state.roundStats.deaths
    task.spawn(function()
        pcall(function()
            Executor.request({
                Url = Core.api.url .. "/api/rh1/session-update",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({sessionId = Core.api.sessionId, data = data}),
            })
        end)
    end)
end

local function ApiChatRelay(playerName, text)
    if not Core.api.enabled or not Core.api.sessionId or not Executor.httpenabled then return end
    task.spawn(function()
        pcall(function()
            Executor.request({
                Url = Core.api.url .. "/api/rh1/session-update",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    sessionId = Core.api.sessionId,
                    data = {chatMessage = text, player = playerName},
                }),
            })
        end)
    end)
end

local function ApiHeartbeat()
    if not Core.api.enabled or not Core.api.sessionId or not Executor.httpenabled then return end
    task.spawn(function()
        pcall(function()
            Executor.request({
                Url = Core.api.url .. "/api/rh1/heartbeat",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({sessionId = Core.api.sessionId}),
            })
        end)
    end)
end

local function ApiConnect()
    if not Executor.httpenabled then
        NotifyPlayer("API", "⚠️ Executor does not support HTTP!", 5, Color3.fromRGB(255, 0, 0))
        return
    end
    local hwid = GenerateHWID()
    local userId = tostring(LocalPlayer.UserId)
    local key = userId:sub(1, 8)
    local payload = HttpService:JSONEncode({
        userId = userId,
        username = LocalPlayer.Name,
        hwid = hwid,
        gameId = tostring(game.PlaceId),
        jobId = game.JobId,
    })
    local encrypted = XorCrypt(payload, key)
    local bytes = {string.byte(encrypted, 1, #encrypted)}

    local ok, res = pcall(function()
        return Executor.request({
            Url = Core.api.url .. "/api/rh1/create-session",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["X-Data"] = HttpService:JSONEncode({d = bytes}),
            },
            Body = HttpService:JSONEncode({userId = userId}),
        })
    end)

    if ok and res and res.StatusCode == 200 then
        local dok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if dok and data and data.success then
            Core.api.sessionId = data.sessionId
            local sessionUrl = Core.api.url .. "/api/rh1/session-view?id=" .. data.sessionId
            if Executor.clipboard then Executor.clipboard(sessionUrl) end
            NotifyPlayer("API", "✅ Session created! Link copied.", 8, Color3.fromRGB(0, 200, 255))
            DiscordEvent("Session created", "Host: " .. LocalPlayer.Name, 3447003)
            task.spawn(function()
                while Core.api.sessionId do
                    task.wait(5)
                    ApiHeartbeat()
                end
            end)
            return
        end
    end
    NotifyPlayer("API", "⚠️ Failed to connect!", 5, Color3.fromRGB(255, 0, 0))
end

local movementLoop = nil

local function SetLight(color)
    Core.config.light = color
    ExecuteCommand("LightRoom", {
        ["Light Color"] = color == "green" and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    })

    if color == "green" then
        PlaySound(Core.sounds.green, "GreenLight", 5)
        SendChat("🟩 - MOVE!")
        NotifyPlayer("Green Light", "Movement allowed!", 4, Color3.fromRGB(0, 255, 0))
        if movementLoop then task.cancel(movementLoop) movementLoop = nil end
        Core.state.acceptingMovement = false
        DiscordEvent("Green Light", "Movement allowed | Room " .. Core.config.currentRoom, 3066993)
        ApiUpdate({event = "green", room = Core.config.currentRoom})
    else
        PlaySound(Core.sounds.red, "RedLight", 5)
        SendChat("🟥 - STOP WALKING!")
        NotifyPlayer("Red Light", "STOP MOVING!", 4, Color3.fromRGB(255, 0, 0))
        DiscordEvent("Red Light", "Players must stop | Room " .. Core.config.currentRoom, 15158332)
        ApiUpdate({event = "red", room = Core.config.currentRoom})
        Core.state.acceptingMovement = true
        task.delay(Core.config.redAcceptDelay, function()
            Core.state.acceptingMovement = false
        end)
        movementLoop = task.spawn(function()
            task.wait(Core.config.redAcceptDelay)
            while Core.active and Core.config.light == "red" do
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        local humanoid = player.Character.Humanoid
                        if humanoid.Health > 0 and humanoid.MoveDirection.Magnitude > 0 then
                            PunishMovement(player)
                        end
                    end
                end
                CheckAllDead()
                task.wait(0.5)
            end
        end)
    end
end

local function IncreaseDifficulty()
    Core.config.roundNumber += 2
    if Core.config.difficulty < Core.config.maxDifficulty then
        Core.config.difficulty = math.min(Core.config.maxDifficulty, 1 + math.floor(Core.config.roundNumber / 3))
        Core.config.greenTime.max = math.max(40, 70 - (Core.config.difficulty * 5))
        Core.config.redTime.min = math.max(15, 25 - (Core.config.difficulty * 2))
        SendChat("Difficulty increased: Level " .. Core.config.difficulty)
        NotifyPlayer("Difficulty", "Level " .. Core.config.difficulty, 3, Color3.fromRGB(255, 165, 0))
        DiscordEvent("Difficulty", "Level " .. Core.config.difficulty .. " | Room " .. Core.config.currentRoom, 16776960)
        ApiUpdate({event = "difficulty", difficulty = Core.config.difficulty})
    end
end

local function GiveReward(player, rarity)
    local itemPool = rarity and Core.items[rarity] or Core.itemsList
    local item = itemPool[math.random(#itemPool)]
    ExecuteCommand("Give Items", {
        ["Players"] = {[player.Name] = player.Name},
        ["Items"] = {[item] = item},
    })
    Core.state.roundStats.itemsGiven += 1
    return item
end

local function GiveRewardToAll(rarity)
    for _, player in ipairs(UpdatePlayerCache()) do GiveReward(player, rarity) end
    SendChat("Items " .. (rarity or "random") .. " distributed!")
    NotifyPlayer("Items", "You received a " .. (rarity or "random") .. " item!", 5, Color3.fromRGB(0, 255, 0))
    ApiUpdate({event = "item", room = Core.config.currentRoom})
end

local function ReviveAll()
    ExecuteCommand("DELETE ALL", {})
    local reviveArgs = {["Players"] = {}}
    for _, player in ipairs(UpdatePlayerCache()) do
        reviveArgs["Players"][player.Name] = player.Name
    end
    ExecuteCommand("RevivePlayer", reviveArgs)
    Core.config.light = "green"
    Core.state.roundStats.deaths = 0
    SendChat("All players revived! Entities removed!")
    NotifyPlayer("Revive", "All players have been revived!", 5, Color3.fromRGB(0, 255, 0))
    DiscordEvent("Revive All", "All players revived | Room " .. Core.config.currentRoom, 3066993)
    ApiUpdate({event = "green", room = Core.config.currentRoom})
    ApiUpdate({event = "revive_all", room = Core.config.currentRoom})
    SetLight("green")
end

local function CheckAllDead()
    if not Core.config.autoRevive then return false end
    local deadCount = 0
    local totalPlayers = #UpdatePlayerCache()
    for _, player in ipairs(Core.cache.players) do
        if not IsPlayerAlive(player) then deadCount += 1 end
    end
    if deadCount >= totalPlayers then ReviveAll() return true end
    return false
end

local function SpawnEntity(entity, targetPlayer)
    local players = targetPlayer and {targetPlayer} or UpdatePlayerCache()
    if entity == "A-90" then
        for _, p in ipairs(players) do ExecuteCommand("A90Player", {["Players"] = {[p.Name] = p.Name}}) end
    elseif entity == "Screech" then
        for _, p in ipairs(players) do ExecuteCommand("ScreechPlayer", {["Players"] = {[p.Name] = p.Name}}) end
    elseif entity == "Glitch" then
        for _, p in ipairs(players) do ExecuteCommand("GlitchPlayer", {["Players"] = {[p.Name] = p.Name}}) end
    else
        ExecuteCommand(entity, {})
    end
    Core.state.roundStats.entitiesSpawned += 1
end

local function PunishMovement(player)
    local entity = Core.entitiesList[math.random(#Core.entitiesList)]
    local killMethod = math.random(1, 2) == 1 and "KillPlayer" or "ExplodePlayer"
    ExecuteCommand(killMethod, {["Players"] = {[player.Name] = player.Name}})
    task.wait(0.1)
    SpawnEntity(entity, player)
    Core.state.roundStats.deaths += 1
    Core.state.deadPlayers[player.UserId] = {name = player.Name, time = os.time(), entity = entity}
    Core.state.lastDead = player.Name
    SendChat(player.Name .. " moved on red light! " .. entity .. " appeared!")
    DiscordEvent("Death", player.Name .. " moved | Entity: **" .. entity .. "** | Room " .. Core.config.currentRoom, 15158332)
    ApiUpdate({event = "death", player = player.Name, entity = entity, room = Core.config.currentRoom})
end

local entitySpawnThread = nil
local function StartRandomEntitySpawning()
    if entitySpawnThread then task.cancel(entitySpawnThread) end
    entitySpawnThread = task.spawn(function()
        while Core.active and Core.config.modEnabled and Core.config.entitySpawnEnabled do
            local waitTime = math.random(Core.config.entitySpawnInterval.min, Core.config.entitySpawnInterval.max)
            task.wait(waitTime)
            if not Core.active then break end
            local entity = Core.entitiesList[math.random(#Core.entitiesList)]
            SpawnEntity(entity, nil)
            SendChat(entity .. " appeared randomly!")
            ApiUpdate({event = "entity_spawn", entity = entity, room = Core.config.currentRoom})
        end
    end)
end

local function StopRandomEntitySpawning()
    if entitySpawnThread then task.cancel(entitySpawnThread) entitySpawnThread = nil end
end

local function ToggleMod(enable)
    Core.config.modEnabled = enable
    Core.active = enable
    if not enable then
        SetLight("green")
        if movementLoop then task.cancel(movementLoop) movementLoop = nil end
        StopRandomEntitySpawning()
        ApiUpdate({event = "pause", reason = "manual", room = Core.config.currentRoom})
    else
        StartRandomEntitySpawning()
        ApiUpdate({event = "resume", room = Core.config.currentRoom})
    end
    local status = enable and "enabled" or "disabled"
    SendChat("💿 Mod " .. status .. "!")
    NotifyPlayer("System", "Mod " .. status .. "!", 5, enable and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
end

local function IsSpecialRoom(roomName)
    for _, special in ipairs(Core.config.specialRooms) do
        if roomName:find(special) then return true end
    end
    return false
end

local function MonitorRoom()
    local currentRoom = LocalPlayer:GetAttribute("CurrentRoom")
    if not currentRoom then return end
    Core.config.currentRoom = currentRoom
    local room = workspace.CurrentRooms:FindFirstChild(tostring(currentRoom))

    if room and room:GetAttribute("RawName") then
        local roomName = room:GetAttribute("RawName")
        if IsSpecialRoom(roomName) then
            if not Core.config.specialRoomNotified then
                Core.config.pausedByRoom = true
                Core.active = false
                Core.config.specialRoomNotified = true
                StopRandomEntitySpawning()
                SendChat("⚠️ System paused - Special room detected!")
                NotifyPlayer("Special Room", "System temporarily paused", 5, Color3.fromRGB(255, 0, 0))
                ApiUpdate({event = "pause", reason = roomName, room = currentRoom})
            end
        else
            if Core.config.pausedByRoom then
                Core.config.pausedByRoom = false
                Core.active = true
                Core.config.specialRoomNotified = false
                StartRandomEntitySpawning()
                SendChat("⚠️ System resumed - Normal room detected!")
                NotifyPlayer("System Resumed", "Continuing normal operation", 5, Color3.fromRGB(0, 255, 0))
                ApiUpdate({event = "resume", room = currentRoom})
            end
        end
    end

    if currentRoom >= 2 and not Core.initialized then
        Core.initialized = true
        Core.active = true
        StartRandomEntitySpawning()
        SendChat("Mod activated!")
        SendChat("[TIP] Red = STOP | Green = MOVE | Watch the chat!")
        NotifyPlayer("System Active", "Red = STOP | Green = MOVE!", 5, Color3.fromRGB(0, 255, 0))
        DiscordEvent("Mod started", "Host: " .. Core.config.host .. " | Room: " .. currentRoom, 3066993)
        ApiUpdate({event = "mod_start", room = currentRoom})
    end

    if currentRoom >= Core.config.winRoom and not Core.config.gameWon then
        Core.config.gameWon = true
        local alivePlayers = GetAlivePlayers()
        if #alivePlayers > 0 then
            SendChat("🎉 CONGRATULATIONS! Door " .. Core.config.winRoom .. " reached!")
            SendChat(#alivePlayers .. " players survived!")
            NotifyPlayer("VICTORY", "Challenge complete!", 10, Color3.fromRGB(0, 255, 0))
            for _, player in ipairs(alivePlayers) do
                ExecuteCommand("Apply Changes", {
                    ["Players"] = {[player.Name] = player.Name},
                    ["Max Health"] = 200, ["Star Shield"] = 100,
                    ["Health"] = 200, ["Speed Boost"] = 20, ["God Mode"] = true,
                })
            end
            GiveRewardToAll("legendary")
            DiscordEvent("Victory!", #alivePlayers .. " players reached door " .. Core.config.winRoom, 16766720)
            ApiUpdate({event = "win", room = currentRoom})
        end
    end

    ApiUpdate({event = "room_change", room = currentRoom})
end

local TimerGui = Instance.new("ScreenGui")
TimerGui.Name = "GLRLTimer"
TimerGui.ResetOnSpawn = false
TimerGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local TimerFrame = Instance.new("Frame")
TimerFrame.Size = UDim2.new(0, 220, 0, 80)
TimerFrame.Position = UDim2.new(0.84, 0, 0.08, 0)
TimerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TimerFrame.BackgroundTransparency = 0.3
TimerFrame.BorderSizePixel = 0
TimerFrame.Parent = TimerGui
Instance.new("UICorner", TimerFrame).CornerRadius = UDim.new(0, 8)

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Size = UDim2.new(1, 0, 0.5, 0)
TimerLabel.BackgroundTransparency = 1
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimerLabel.TextSize = 18
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.Parent = TimerFrame

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, 0, 0.5, 0)
StatsLabel.Position = UDim2.new(0, 0, 0.5, 0)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatsLabel.TextSize = 14
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.Parent = TimerFrame

local Commands = {}

function Commands:godmode(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    local hp = GetPlayerHealth(player)
    ExecuteCommand("Apply Changes", {["Players"] = {[player.Name] = player.Name}, ["Health"] = hp, ["Max Health"] = 100, ["God Mode"] = true})
    SendChat(player.Name .. " - God Mode enabled!")
end

function Commands:vida(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    ExecuteCommand("Apply Changes", {["Players"] = {[player.Name] = player.Name}, ["Max Health"] = 100, ["Star Shield"] = 100, ["Health"] = 100, ["God Mode"] = false})
end

function Commands:revive(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    ExecuteCommand("RevivePlayer", {["Players"] = {[player.Name] = player.Name}})
end

function Commands:speed(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    local hp = GetPlayerHealth(player)
    ExecuteCommand("Apply Changes", {["Players"] = {[player.Name] = player.Name}, ["Health"] = hp, ["Max Health"] = math.max(hp, 100), ["Speed Boost"] = 25})
    SendChat(player.Name .. " - Speed boost applied!")
end

function Commands:resetspeed(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    local hp = GetPlayerHealth(player)
    ExecuteCommand("Apply Changes", {["Players"] = {[player.Name] = player.Name}, ["Health"] = hp, ["Max Health"] = math.max(hp, 100), ["Speed Boost"] = 0})
    SendChat(player.Name .. " - Speed reset!")
end

function Commands:item(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    local item = GiveReward(player, nil)
    SendChat(player.Name .. " received: " .. item)
end

function Commands:shield(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    local hp = GetPlayerHealth(player)
    ExecuteCommand("Apply Changes", {["Players"] = {[player.Name] = player.Name}, ["Health"] = hp, ["Max Health"] = math.max(hp, 100), ["Star Shield"] = 100})
end

function Commands:pxitem(player, args)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    if not args[2] then SendChat("Use: !pxitem [item name]") return end
    local itemName = args[2]:lower()
    local foundItem = nil
    for _, items in pairs(Core.items) do
        for _, item in ipairs(items) do
            if item:lower() == itemName then foundItem = item break end
        end
        if foundItem then break end
    end
    if not foundItem then SendChat("❌ Item not found! Use !items to see the list.") return end
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == player.UserId then target = p break end
    end
    if not target then return end
    ExecuteCommand("Give Items", {
        ["Players"] = {[target.Name] = target.Name},
        ["Items"] = {[foundItem] = foundItem},
    })
    Core.state.roundStats.itemsGiven += 1
    SendChat(target.Name .. " received: " .. foundItem)
    ApiUpdate({event = "item", player = target.Name, room = Core.config.currentRoom})
end

function Commands:items()
    SendChat("Item List by Rarity:")
    task.wait(0.3)
    for rarity, items in pairs(Core.items) do
        SendChat("- " .. rarity:upper() .. ": " .. table.concat(items, ", "))
        task.wait(0.3)
    end
end

function Commands:entities()
    SendChat("Entity List by Rarity:")
    task.wait(0.3)
    for rarity, entities in pairs(Core.entities) do
        SendChat("- " .. rarity:upper() .. ": " .. table.concat(entities, ", "))
        task.wait(0.3)
    end
end

function Commands:stats()
    local alive = #GetAlivePlayers()
    local total = #UpdatePlayerCache()
    SendChat("Stats:")
    task.wait(0.3)
    SendChat("- Alive: " .. alive .. "/" .. total)
    task.wait(0.3)
    SendChat("- Room: " .. Core.config.currentRoom)
    task.wait(0.3)
    SendChat("- Difficulty: " .. Core.config.difficulty)
    task.wait(0.3)
    SendChat("- Deaths: " .. Core.state.roundStats.deaths)
end

function Commands:comandos()
    SendChat("Available commands:")
    task.wait(0.5)
    SendChat("- General: !pxitem, !vida, !revive, !godmode, !speed, !resetspeed, !item, !shield")
    task.wait(0.5)
    SendChat("- Info: !items, !entities, !comandos, !stats")
    task.wait(0.5)
    SendChat("- Host: !togglemod, !spawn, !randomentity, !kill, !debug, !cmds, !difficulty, !allitems, !giveall")
end

function Commands:togglemod(player)
    if player.Name ~= Core.config.host then SendChat("Host only!") return end
    ToggleMod(not Core.config.modEnabled)
end

function Commands:debug(player)
    if player.Name ~= Core.config.host then SendChat("Host only!") return end
    Core.config.debugMode = not Core.config.debugMode
    SendChat("Debug: " .. (Core.config.debugMode and "Enabled" or "Disabled"))
end

function Commands:cmds(player)
    if player.Name ~= Core.config.host then SendChat("Host only!") return end
    Core.config.commandsEnabled = not Core.config.commandsEnabled
    SendChat("Commands " .. (Core.config.commandsEnabled and "enabled" or "disabled") .. " for players!")
end

function Commands:difficulty(player)
    if player.Name ~= Core.config.host then SendChat("Host only!") return end
    IncreaseDifficulty()
end

function Commands:allitems(player)
    if player.Name ~= Core.config.host then SendChat("Host only!") return end
    GiveRewardToAll(nil)
end

function Commands:giveall(player, args)
    if player.Name ~= Core.config.host then SendChat("Host only!") return end
    GiveRewardToAll(args[2])
end

function Commands:spawn(player, args)
    if player.Name ~= Core.config.host then SendChat("Host only!") return end
    if not args[2] then
        SendChat("Use: !spawn [entity]")
        SendChat("Available: " .. table.concat(Core.entitiesList, ", "))
        return
    end
    local entityName = args[2]:lower()
    local found = nil
    for _, entity in ipairs(Core.entitiesList) do
        if entity:lower() == entityName then found = entity break end
    end
    if not found then SendChat("Entity not found!") return end
    SpawnEntity(found, nil)
    SendChat(found .. " has been summoned!")
    ApiUpdate({event = "entity_spawn", entity = found, room = Core.config.currentRoom})
end

function Commands:randomentity(player)
    if player.Name ~= Core.config.host then SendChat("Host only!") return end
    local entity = Core.entitiesList[math.random(#Core.entitiesList)]
    SpawnEntity(entity, nil)
    SendChat(entity .. " summoned randomly!")
    ApiUpdate({event = "entity_spawn", entity = entity, room = Core.config.currentRoom})
end

function Commands:kill(player, args)
    if player.Name ~= Core.config.host then SendChat("Host only!") return end
    if Core.config.voteActive then SendChat("A vote is already in progress!") return end
    if not args[2] then SendChat("Use: !kill [name]") return end
    local targetId = args[2]:lower()
    local target = nil
    for _, plr in ipairs(UpdatePlayerCache()) do
        if plr.Name:lower() == targetId or tostring(plr.UserId) == targetId then target = plr break end
    end
    if not target then SendChat("Player not found!") return end
    Core.config.voteActive = true
    Core.state.votes = {yes = 0, no = 0}
    SendChat("Vote: eliminate " .. target.Name .. "? Type Y or N (19s)")
    ApiUpdate({event = "vote_start", player = target.Name, room = Core.config.currentRoom})
    local voters = {}
    local conn = TextChatService.MessageReceived:Connect(function(msg)
        if not Core.config.voteActive then return end
        local voter = msg.TextSource
        if voters[voter.UserId] then return end
        local vote = msg.Text:lower()
        if vote == "y" then Core.state.votes.yes += 1 voters[voter.UserId] = true
        elseif vote == "n" then Core.state.votes.no += 1 voters[voter.UserId] = true end
    end)
    task.wait(19)
    Core.config.voteActive = false
    conn:Disconnect()
    if Core.state.votes.yes > Core.state.votes.no then
        ExecuteCommand("KillPlayer", {["Players"] = {[target.Name] = target.Name}})
        SendChat(target.Name .. " was eliminated! (" .. Core.state.votes.yes .. " vs " .. Core.state.votes.no .. ")")
        ApiUpdate({event = "vote_result", player = target.Name, result = "eliminated", room = Core.config.currentRoom})
    else
        SendChat(target.Name .. " was spared! (" .. Core.state.votes.no .. " vs " .. Core.state.votes.yes .. ")")
        ApiUpdate({event = "vote_result", player = target.Name, result = "spared", room = Core.config.currentRoom})
    end
end

TextChatService.MessageReceived:Connect(function(message)
    local text = message.Text
    local player = message.TextSource
    if not player then return end

    local playerObj = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == player.UserId then playerObj = p break end
    end
    local playerName = playerObj and playerObj.Name or "Unknown"

    ApiChatRelay(playerName, text)

    local ltext = text:lower()
    local args = ltext:split(" ")
    local command = args[1]
    if command:sub(1, 1) == "!" then
        local cmdName = command:sub(2)
        if Commands[cmdName] then Commands[cmdName](Commands, player, args) end
    end
end)

task.spawn(function()
    while true do
        if Core.active and Core.config.modEnabled then
            local timeRange = Core.config.light == "green" and Core.config.greenTime or Core.config.redTime
            local timeLeft = math.random(timeRange.min, timeRange.max)

            ApiUpdate({event = "timer_start", nextChange = timeLeft, room = Core.config.currentRoom})

            for i = timeLeft, 1, -1 do
                if not Core.active then break end
                local alive = #GetAlivePlayers()
                local total = #UpdatePlayerCache()
                TimerLabel.Text = string.format("%s Next: %ds", Core.config.light == "green" and "G" or "R", i)
                StatsLabel.Text = string.format("Room %d | Alive: %d/%d | Dif: %d", Core.config.currentRoom, alive, total, Core.config.difficulty)
                if i == 10 then SendChat("10 seconds to light change!") end
                if i == 3 then SendChat("3 seconds!") end
                task.wait(1)
            end

            if Core.active then
                SetLight(Core.config.light == "green" and "red" or "green")
                if Core.config.light == "green" and math.random(1, 10) == 1 then
                    IncreaseDifficulty()
                end
            end
        else
            TimerLabel.Text = "System Paused"
            StatsLabel.Text = "Room " .. Core.config.currentRoom
            task.wait(1)
        end
    end
end)

LocalPlayer:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
    MonitorRoom()
end)
MonitorRoom()

task.spawn(function()
    while true do
        local waitTime = math.random(Core.config.itemDropTime.min, Core.config.itemDropTime.max)
        task.wait(waitTime)
        if Core.active and Core.config.modEnabled and Core.config.autoItemDrop ~= false then
            GiveRewardToAll(autoDropRarity)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(30)
        if Core.active then
            for userId, data in pairs(Core.state.survivalTime) do
                Core.state.survivalTime[userId] = (data or 0) + 30
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    Core.state.playerScores[player.UserId] = 0
    Core.state.survivalTime[player.UserId] = 0
    task.wait(2)
    SendChat("Welcome " .. player.DisplayName .. "! Use !comandos to see commands.")
    DiscordEvent("Player joined", player.Name .. " (" .. player.DisplayName .. ")", 3447003)
    ApiUpdate({event = "player_join", player = player.Name, room = Core.config.currentRoom})
end)

Players.PlayerRemoving:Connect(function(player)
    Core.state.playerScores[player.UserId] = nil
    Core.state.survivalTime[player.UserId] = nil
    Core.state.deadPlayers[player.UserId] = nil
    ApiUpdate({event = "player_leave", player = player.Name, room = Core.config.currentRoom})
end)

local Window = Library:CreateWindow({
    Title = "GLRL " .. Core.version,
    Footer = "by rhyan57",
    Icon = 95869322194132,
    NotifySide = "Right",
    ToggleKeybind = Enum.KeyCode.RightShift,
})

local TabMain     = Window:AddTab("Main")
local TabDiff     = Window:AddTab("Difficulty")
local TabEntities = Window:AddTab("Entities")
local TabItems    = Window:AddTab("Items")
local TabDiscord  = Window:AddTab("Discord")
local TabAPI      = Window:AddTab("API Session")

local GbControl  = TabMain:AddLeftGroupbox("Control")
local GbSettings = TabMain:AddRightGroupbox("Settings")

GbControl:AddButton({Text = "Activate Mod", Func = function() ToggleMod(true) end})
GbControl:AddButton({Text = "Pause Mod", Func = function() ToggleMod(false) end})
GbControl:AddButton({Text = "Force Green Light", Func = function()
    if not Core.active then NotifyPlayer("Error", "Mod is not active!", 3, Color3.fromRGB(255,0,0)) return end
    SetLight("green")
end})
GbControl:AddButton({Text = "Force Red Light", Func = function()
    if not Core.active then NotifyPlayer("Error", "Mod is not active!", 3, Color3.fromRGB(255,0,0)) return end
    SetLight("red")
end})
GbControl:AddButton({Text = "Revive All", Func = function() ReviveAll() end})
GbControl:AddButton({Text = "Give Items to All", Func = function() GiveRewardToAll(nil) end})
GbControl:AddButton({Text = "Random Entity", Func = function()
    if not Core.active then NotifyPlayer("Error", "Mod is not active!", 3, Color3.fromRGB(255,0,0)) return end
    local e = Core.entitiesList[math.random(#Core.entitiesList)]
    SpawnEntity(e, nil)
    SendChat(e .. " summoned!")
    ApiUpdate({event = "entity_spawn", entity = e, room = Core.config.currentRoom})
end})

GbSettings:AddToggle("AutoRevive", {
    Text = "Auto Revive when all dead",
    Default = true,
    Callback = function(v) Core.config.autoRevive = v end,
})
GbSettings:AddToggle("CommandsEnabled", {
    Text = "Chat commands enabled",
    Default = true,
    Callback = function(v) Core.config.commandsEnabled = v end,
})
GbSettings:AddToggle("DebugMode", {
    Text = "Debug Mode",
    Default = false,
    Callback = function(v) Core.config.debugMode = v end,
})
GbSettings:AddInput("WinRoom", {
    Text = "Victory door",
    Default = "100",
    Numeric = true,
    Finished = true,
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then Core.config.winRoom = n NotifyPlayer("Config", "Victory door: " .. n, 3) end
    end,
})
GbSettings:AddSlider("RedAcceptDelay", {
    Text = "Red light accept delay (s)",
    Default = 2,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Suffix = "s",
    Tooltip = "Grace period after red light alert before movement is detected",
    Callback = function(v) Core.config.redAcceptDelay = v end,
})

local GbGreenTime = TabDiff:AddLeftGroupbox("Green Time (seconds)")
local GbRedTime   = TabDiff:AddRightGroupbox("Red Time (seconds)")
local GbDiffCtrl  = TabDiff:AddLeftGroupbox("Difficulty Control")

GbGreenTime:AddSlider("GreenMin", {Text="Minimum", Default=50, Min=10, Max=120, Rounding=0, Callback=function(v) Core.config.greenTime.min=v end})
GbGreenTime:AddSlider("GreenMax", {Text="Maximum", Default=70, Min=10, Max=120, Rounding=0, Callback=function(v) Core.config.greenTime.max=v end})
GbRedTime:AddSlider("RedMin", {Text="Minimum", Default=25, Min=5, Max=60, Rounding=0, Callback=function(v) Core.config.redTime.min=v end})
GbRedTime:AddSlider("RedMax", {Text="Maximum", Default=35, Min=5, Max=60, Rounding=0, Callback=function(v) Core.config.redTime.max=v end})
GbDiffCtrl:AddSlider("MaxDifficulty", {Text="Max Difficulty", Default=5, Min=1, Max=10, Rounding=0, Callback=function(v) Core.config.maxDifficulty=v end})
GbDiffCtrl:AddButton({Text = "Increase Difficulty Now", Func = function() IncreaseDifficulty() end})
GbDiffCtrl:AddButton({Text = "Reset Difficulty", Func = function()
    Core.config.difficulty = 1
    Core.config.roundNumber = 0
    Core.config.greenTime = {min=50, max=70}
    Core.config.redTime = {min=25, max=35}
    SendChat("Difficulty reset!")
    ApiUpdate({event = "difficulty_reset", room = Core.config.currentRoom})
end})

local GbEntitySpawn  = TabEntities:AddLeftGroupbox("Auto Spawn")
local GbEntityManual = TabEntities:AddRightGroupbox("Manual Spawn")

GbEntitySpawn:AddToggle("EntitySpawnEnabled", {
    Text = "Auto spawn active",
    Default = false,
    Callback = function(v)
        Core.config.entitySpawnEnabled = v
        if v and Core.active then StartRandomEntitySpawning() else StopRandomEntitySpawning() end
    end,
})
GbEntitySpawn:AddSlider("EntitySpawnMin", {Text="Min interval (s)", Default=15, Min=5, Max=120, Rounding=0, Callback=function(v) Core.config.entitySpawnInterval.min=v end})
GbEntitySpawn:AddSlider("EntitySpawnMax", {Text="Max interval (s)", Default=45, Min=5, Max=180, Rounding=0, Callback=function(v) Core.config.entitySpawnInterval.max=v end})

local entityDropdownOptions = {}
for _, e in ipairs(Core.entitiesList) do table.insert(entityDropdownOptions, e) end
for _, e in ipairs(Core.specialEntities) do table.insert(entityDropdownOptions, e) end
local selectedEntity = entityDropdownOptions[1]

GbEntityManual:AddDropdown("EntitySelect", {
    Text = "Entity",
    Values = entityDropdownOptions,
    Default = 1,
    Callback = function(v) selectedEntity = v end,
})
GbEntityManual:AddButton({Text = "Spawn Selected", Func = function()
    SpawnEntity(selectedEntity, nil)
    SendChat(selectedEntity .. " summoned manually!")
    ApiUpdate({event = "entity_spawn", entity = selectedEntity, room = Core.config.currentRoom})
end})

local GbItemsManual = TabItems:AddLeftGroupbox("Give Items")
local GbItemsAuto   = TabItems:AddRightGroupbox("Auto Delivery")

local rarityOptions = {"Random", "common", "uncommon", "rare", "legendary"}
local selectedRarity = "Random"
local playerNames = {}
local selectedItemPlayer = "All"

local function RefreshPlayerDropdown()
    playerNames = {"All"}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(playerNames, p.Name)
    end
end
RefreshPlayerDropdown()

local PlayerDropdown = GbItemsManual:AddDropdown("ItemPlayerSelect", {
    Text = "Player",
    Values = playerNames,
    Default = 1,
    Callback = function(v) selectedItemPlayer = v end,
})

GbItemsManual:AddDropdown("ItemRaritySelect", {
    Text = "Rarity",
    Values = rarityOptions,
    Default = 1,
    Callback = function(v) selectedRarity = v end,
})

GbItemsManual:AddButton({Text = "Give Item", Func = function()
    local rarity = selectedRarity == "Random" and nil or selectedRarity
    if selectedItemPlayer == "All" then
        GiveRewardToAll(rarity)
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == selectedItemPlayer then
                local item = GiveReward(p, rarity)
                SendChat(p.Name .. " received: " .. item .. " (" .. (rarity or "random") .. ")")
                ApiUpdate({event = "item", player = p.Name, room = Core.config.currentRoom})
                break
            end
        end
    end
end})

GbItemsManual:AddButton({Text = "Refresh Player List", Func = function()
    RefreshPlayerDropdown()
    PlayerDropdown:SetValues(playerNames, 1)
    NotifyPlayer("Items", "Player list updated!", 2, Color3.fromRGB(0, 200, 255))
end})

GbItemsManual:AddButton({Text = "Random Item to All", Func = function() GiveRewardToAll(nil) end})
GbItemsManual:AddButton({Text = "Legendary to All", Func = function() GiveRewardToAll("legendary") end})
GbItemsManual:AddButton({Text = "Rare to All", Func = function() GiveRewardToAll("rare") end})
GbItemsManual:AddButton({Text = "Uncommon to All", Func = function() GiveRewardToAll("uncommon") end})
GbItemsManual:AddButton({Text = "Common to All", Func = function() GiveRewardToAll("common") end})

GbItemsAuto:AddToggle("AutoItemDrop", {
    Text = "Auto delivery active",
    Default = true,
    Callback = function(v)
        Core.config.autoItemDrop = v
    end,
})

GbItemsAuto:AddSlider("ItemDropMin", {
    Text = "Min interval (s)",
    Default = 60, Min = 10, Max = 300, Rounding = 0,
    Callback = function(v) Core.config.itemDropTime.min = v end,
})

GbItemsAuto:AddSlider("ItemDropMax", {
    Text = "Max interval (s)",
    Default = 120, Min = 10, Max = 600, Rounding = 0,
    Callback = function(v) Core.config.itemDropTime.max = v end,
})

local rarityAutoOptions = {"Random", "common", "uncommon", "rare", "legendary"}
local autoDropRarity = nil
GbItemsAuto:AddDropdown("AutoDropRarity", {
    Text = "Auto delivery rarity",
    Values = rarityAutoOptions,
    Default = 1,
    Callback = function(v) autoDropRarity = v == "Random" and nil or v end,
})

GbItemsAuto:AddLabel("Items delivered: 0"):SetText("Items delivered: 0")

local GbDiscordConfig = TabDiscord:AddLeftGroupbox("Configuration")
local GbDiscordTest   = TabDiscord:AddRightGroupbox("Test")

GbDiscordConfig:AddToggle("DiscordEnabled", {Text="Discord notifications active", Default=false, Callback=function(v) Core.discord.enabled=v end})
GbDiscordConfig:AddToggle("DiscordUseWebhook", {Text="Use Webhook (off = Bot Token)", Default=true, Callback=function(v) Core.discord.useWebhook=v end})
GbDiscordConfig:AddInput("DiscordWebhook", {Text="Webhook URL", Default="", Placeholder="https://discord.com/api/webhooks/...", Finished=true, Callback=function(v) Core.discord.webhookUrl=v end})
GbDiscordConfig:AddInput("DiscordBotToken", {Text="Bot Token", Default="", Placeholder="MTk4NjIy...", Finished=true, Callback=function(v) Core.discord.botToken=v end})
GbDiscordConfig:AddInput("DiscordChannelId", {Text="Channel ID (Bot Token)", Default="", Placeholder="123456789012345678", Finished=true, Callback=function(v) Core.discord.channelId=v end})

GbDiscordTest:AddButton({Text = "Send Test Message", Func = function()
    if not Core.discord.enabled then
        NotifyPlayer("Discord", "Enable notifications first!", 3, Color3.fromRGB(255,0,0))
        return
    end
    DiscordEvent("Test", "GLRL connected and running!\nHost: " .. Core.config.host, 3447003)
    NotifyPlayer("Discord", "Test message sent!", 3, Color3.fromRGB(0,255,0))
end})

local GbAPIConfig = TabAPI:AddLeftGroupbox("API Configuration")
local GbAPIStatus = TabAPI:AddRightGroupbox("Session Status")

GbAPIConfig:AddToggle("APIEnabled", {Text="Session system active", Default=false, Callback=function(v) Core.api.enabled=v end})
GbAPIConfig:AddInput("APIUrl", {
    Text = "API URL",
    Default = "https://rlrl.onrender.com",
    Placeholder = "Your api",
    Finished = true,
    Callback = function(v) Core.api.url=v end,
})
GbAPIConfig:AddButton({Text = "Connect (Create Session)", Func = function()
    if not Core.api.enabled then
        NotifyPlayer("API", "Enable the session system first!", 3, Color3.fromRGB(255,0,0))
        return
    end
    ApiConnect()
end})
GbAPIConfig:AddButton({Text = "Disconnect", Func = function()
    Core.api.sessionId = nil
    NotifyPlayer("API", "Disconnected!", 3, Color3.fromRGB(255,165,0))
end})

local SessionLabel = GbAPIStatus:AddLabel("Not connected")
task.spawn(function()
    while true do
        task.wait(2)
        if Core.api.sessionId then
            SessionLabel:SetText("ID: " .. Core.api.sessionId:sub(1, 20) .. "...")
        else
            SessionLabel:SetText("Not connected")
        end
    end
end)

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:SetFolder("GLRL")
ThemeManager:ApplyToTab(Window:AddTab("Themes"))

for _, player in ipairs(Players:GetPlayers()) do
    Core.state.playerScores[player.UserId] = 0
    Core.state.survivalTime[player.UserId] = 0
end

Caption("GLRL v" .. Core.version .. " loaded!")
task.wait(3)
Caption("Made by Rhyan57 | v" .. Core.version)
NotifyPlayer("Mod Loaded", "RShift to open the menu! Pass door 2 to activate.", 10, Color3.fromRGB(255,255,0))
SendChat("[ GLRL ] Green Light Red Light!(active after door 2)")
