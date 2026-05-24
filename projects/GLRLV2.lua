local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

if shared.glrl_loaded then return end
shared.glrl_loaded = true

local Notify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Msdoors/Msdoors.gg/refs/heads/main/Scripts/Msdoors/Notification/Source.lua"))()
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/ThemeManager.lua"))()

local LocalPlayer = Players.LocalPlayer

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

local C = {
    version = "2.0.0",
    active = false,
    initialized = false,
    movementLoop = nil,

    config = {
        light = "green",
        greenTime = {min = 50, max = 70},
        redTime = {min = 25, max = 35},
        currentRoom = 0,
        pausedByRoom = false,
        specialRoomNotified = false,
        gameWon = false,
        winRoom = 100,
        host = LocalPlayer.Name,
        debugMode = false,
        autoRevive = true,
        itemDropTime = {min = 60, max = 120},
        specialRooms = {"SeekIntro", "Seek", "Halt"},
        commandsEnabled = true,
        modEnabled = true,
        difficulty = 1,
        roundNumber = 0,
        maxDifficulty = 5,
        entitySpawnEnabled = true,
        entitySpawnInterval = {min = 15, max = 45},
    },

    state = {
        votes = {yes = 0, no = 0},
        voteActive = false,
        deadPlayers = {},
        playerScores = {},
        survivalTime = {},
        roundStats = { deaths = 0, itemsGiven = 0, entitiesSpawned = 0 },
        lastDead = nil,
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
        url = "https://glrl-api.onrender.com",
        sessionId = nil,
        wsConnected = false,
    },

    cache = { players = {}, lastUpdate = 0 },

    items = {
        common = {"Flashlight","Lighter","Candle","Shakelight","Glowsticks","Vitamins","Bread","Cheese","Donut","Nanner","AloeVera","Key","Lockpick","BatteryPack","Compass","LibraryHintPaper","NannerPeel"},
        uncommon = {"Bulklight","Straplight","Lantern","Smoothie","GweenSoda","BandagePack","TipJar","StarVial","Shears","AlarmClock","LaserPointer","HintBook","KeyIron","KeyElectrical","KeyRetro","GeneratorFuse"},
        rare = {"Crucifix","SkeletonKey","StarJug","HolyGrenade","Bomb","BigBomb","Knockbomb","BoxingGloves","StopSign","SnakeBox","Multitool","BigPropTool"},
        legendary = {"RiftSmoothie","RiftCandle","RiftJar","StarBottle","GoldGun","KeyBackdoor"},
    },

    entities = {
        common = {"Eyes","Screech"},
        uncommon = {"Rush","Ambush","Glitch","Bramble","Surge"},
        rare = {"Figure","A-60","Blitz","Monument","GroundSpeeker"},
        legendary = {"A-120","Jeff The Killer","Lookman"},
    },

    specialEntities = {"A-90"},

    sounds = {
        green = "https://github.com/Sc-Rhyan57/MsProject/raw/refs/heads/main/projects/data/sounds/doll-green-light.mp3",
        red = "https://github.com/Sc-Rhyan57/MsProject/raw/refs/heads/main/projects/data/sounds/doll-red-light.mp3",
    },
}

local function CreateFlatList(tbl)
    local r = {}
    for _, v in pairs(tbl) do for _, i in ipairs(v) do table.insert(r, i) end end
    return r
end
C.itemsList = CreateFlatList(C.items)
C.entitiesList = CreateFlatList(C.entities)

local function generateHWID()
    local ok, hwid = pcall(function()
        if Executor.gethwid then return Executor.gethwid() end
        return nil
    end)
    if ok and hwid and type(hwid) == "string" and #hwid > 0 then return hwid end
    local clientId = game:GetService("RbxAnalyticsService"):GetClientId()
    if clientId and clientId ~= "" then return clientId end
    return "unknown-" .. tostring(tick())
end

local function XorCrypt(data, key)
    local result = {}
    for i = 1, #data do
        local byte = string.byte(data, i)
        local kbyte = string.byte(key, ((i - 1) % #key) + 1)
        table.insert(result, string.char(bit32.bxor(byte, kbyte)))
    end
    return table.concat(result)
end

local function Req(url, method, body, headers)
    if not Executor.httpenabled then return false, nil end
    local ok, res = pcall(function()
        return Executor.request({
            Url = url,
            Method = method or "GET",
            Headers = headers or {["Content-Type"] = "application/json"},
            Body = body and HttpService:JSONEncode(body) or nil,
        })
    end)
    if ok and res and res.StatusCode == 200 then
        local dok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        return dok, data
    end
    return false, nil
end

local function Exec(cmd, args)
    ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(cmd, args)
end

local function GetPlayerHealth(player)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        return player.Character.Humanoid.Health
    end
    return 100
end

local function IsAlive(p)
    return p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0
end

local function IsMoving(p)
    return p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.MoveDirection.Magnitude > 0
end

local function UpdateCache()
    local t = tick()
    if t - C.cache.lastUpdate < 0.5 then return C.cache.players end
    C.cache.players = Players:GetPlayers()
    C.cache.lastUpdate = t
    return C.cache.players
end

local function GetAlive()
    local r = {}
    for _, p in ipairs(UpdateCache()) do if IsAlive(p) then table.insert(r, p) end end
    return r
end

local function Caption(msg)
    pcall(function() require(LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption(msg, true) end)
end

local function Notif(title, desc, t, color)
    Notify({ Title = title, Description = desc, Reason = "", Color = color or Color3.fromRGB(0,255,0), Style = "Doors", Duration = t or 6, NotifyStyle = "Default" })
end

local function Chat(msg)
    if C.config.debugMode then msg = "[DEBUG] " .. msg end
    task.spawn(function()
        pcall(function()
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                TextChatService.TextChannels.RBXGeneral:SendAsync(msg)
            else
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
            end
        end)
    end)
end

local function GetAudioFromGit(url, name)
    if not Executor.writefile or not Executor.getcustomasset then return nil end
    local ok, data = pcall(function() return game:HttpGet(url) end)
    if not ok then return nil end
    local fname = "glrl_sound_" .. name .. ".mp3"
    Executor.writefile(fname, data)
    return Executor.getcustomasset(fname)
end

local soundCache = {}
local function PlaySound(url, name, volume)
    if not soundCache[name] then
        soundCache[name] = GetAudioFromGit(url, name)
    end
    local sid = soundCache[name]
    if not sid then return end
    local s = Instance.new("Sound")
    s.SoundId = sid
    s.Volume = volume or 5
    s.Parent = workspace
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

local function DiscordSend(content, embeds)
    if not C.discord.enabled or not Executor.httpenabled then return end
    task.spawn(function()
        local OSTime = os.time()
        local Time = os.date("!*t", OSTime)
        local timestamp = string.format("%d-%02d-%02dT%02d:%02d:%02dZ", Time.year, Time.month, Time.day, Time.hour, Time.min, Time.sec)

        if C.discord.useWebhook and C.discord.webhookUrl ~= "" then
            local body = { content = content or "", tts = false, embeds = {} }
            if embeds then
                for _, e in ipairs(embeds) do
                    e.timestamp = e.timestamp or timestamp
                    table.insert(body.embeds, e)
                end
            end
            pcall(function()
                Executor.request({
                    Url = C.discord.webhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(body),
                })
            end)
        elseif not C.discord.useWebhook and C.discord.botToken ~= "" and C.discord.channelId ~= "" then
            local body = { content = content or "", tts = false, embeds = {} }
            if embeds then
                for _, e in ipairs(embeds) do
                    e.timestamp = e.timestamp or timestamp
                    table.insert(body.embeds, e)
                end
            end
            pcall(function()
                Executor.request({
                    Url = "https://discord.com/api/v10/channels/" .. C.discord.channelId .. "/messages",
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json",
                        ["Authorization"] = "Bot " .. C.discord.botToken,
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
        footer = {text = "GLRL v" .. C.version .. " | " .. game.PlaceId},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }})
end

local function ApiConnect()
    local hwid = generateHWID()
    local key = tostring(LocalPlayer.UserId):sub(1, 8)
    local payload = HttpService:JSONEncode({
        userId = tostring(LocalPlayer.UserId),
        username = LocalPlayer.Name,
        hwid = hwid,
        gameId = tostring(game.PlaceId),
        jobId = game.JobId,
    })
    local encrypted = XorCrypt(payload, key)

    local ok, res = Req(C.api.url .. "/api/rh1/create-session", "POST", nil, {
        ["Content-Type"] = "application/json",
        ["X-Data"] = HttpService:JSONEncode({d = {string.byte(encrypted, 1, #encrypted)}})
    })

    if ok and res and res.success then
        C.api.sessionId = res.sessionId
        C.api.wsConnected = true
        local sessionUrl = C.api.url .. "/api/rh1/session-view?id=" .. res.sessionId
        if Executor.clipboard then Executor.clipboard(sessionUrl) end
        Notif("API", "Sessão criada! Link copiado para área de transferência.", 8, Color3.fromRGB(0, 200, 255))
        DiscordEvent("🌐 Sessão API criada", "ID: `" .. res.sessionId .. "`\nHost: " .. LocalPlayer.Name, 3447003)
    else
        Notif("API", "Falha ao conectar!", 5, Color3.fromRGB(255, 0, 0))
    end
end

local function ApiUpdate(data)
    if not C.api.enabled or not C.api.sessionId then return end
    task.spawn(function()
        Req(C.api.url .. "/api/rh1/session-update", "POST", {
            sessionId = C.api.sessionId,
            data = data,
        })
    end)
end

local function IncreaseDifficulty()
    C.config.roundNumber += 1
    if C.config.difficulty < C.config.maxDifficulty then
        C.config.difficulty = math.min(C.config.maxDifficulty, 1 + math.floor(C.config.roundNumber / 3))
    end
    local d = C.config.difficulty
    C.config.greenTime = {min = math.max(20, 50 - d * 6), max = math.max(30, 70 - d * 8)}
    C.config.redTime = {min = math.max(10, 25 - d * 2), max = math.max(15, 35 - d * 3)}
    C.config.entitySpawnInterval = {min = math.max(8, 15 - d * 2), max = math.max(15, 45 - d * 5)}
    Chat("📈 Dificuldade: Nível " .. d)
    Notif("Dificuldade", "Nível " .. d, 3, Color3.fromRGB(255, 165, 0))
    DiscordEvent("📈 Dificuldade aumentada", "Nível " .. d .. " | Sala " .. C.config.currentRoom, 16776960)
end

local function GiveReward(player, rarity)
    local pool = rarity and C.items[rarity] or C.itemsList
    local item = pool[math.random(#pool)]
    local hp = GetPlayerHealth(player)
    Exec("Give Items", {["Players"] = {[player.Name] = player.Name}, ["Items"] = {[item] = item}})
    C.state.roundStats.itemsGiven += 1
    return item
end

local function GiveRewardToAll(rarity)
    for _, p in ipairs(UpdateCache()) do GiveReward(p, rarity) end
    Chat("🎁 Itens " .. (rarity or "aleatórios") .. " distribuídos!")
    Notif("Itens", "Você recebeu um item " .. (rarity or "aleatório") .. "!", 5, Color3.fromRGB(0, 255, 0))
end

local function ReviveAll()
    Exec("DELETE ALL", {})
    local args = {["Players"] = {}}
    for _, p in ipairs(UpdateCache()) do args["Players"][p.Name] = p.Name end
    Exec("RevivePlayer", args)
    task.wait(1)
    C.config.light = "green"
    C.state.roundStats.deaths = 0
    Chat("✨ Todos revividos!")
    Notif("Reviver", "Todos foram revividos!", 5, Color3.fromRGB(0, 255, 0))
end

local function SpawnEntity(entity, targetPlayer)
    local players = targetPlayer and {targetPlayer} or UpdateCache()
    if entity == "A-90" then
        for _, p in ipairs(players) do
            Exec("A90Player", {["Players"] = {[p.Name] = p.Name}})
        end
    elseif entity == "Screech" then
        for _, p in ipairs(players) do
            Exec("ScreechPlayer", {["Players"] = {[p.Name] = p.Name}})
        end
    elseif entity == "Glitch" then
        for _, p in ipairs(players) do
            Exec("GlitchPlayer", {["Players"] = {[p.Name] = p.Name}})
        end
    elseif entity == "Void" then
        for _, p in ipairs(players) do
            Exec("VoidPlayer", {["Players"] = {[p.Name] = p.Name}})
        end
    elseif entity == "Fling" then
        for _, p in ipairs(players) do
            Exec("FlingPlayer", {["Players"] = {[p.Name] = p.Name}})
        end
    else
        Exec(entity, {})
    end
    C.state.roundStats.entitiesSpawned += 1
end

local function PunishMovement(player)
    local entity = C.entitiesList[math.random(#C.entitiesList)]
    local killMethod = math.random(1, 2) == 1 and "KillPlayer" or "ExplodePlayer"
    Exec(killMethod, {["Players"] = {[player.Name] = player.Name}})
    task.wait(0.1)
    SpawnEntity(entity, player)
    C.state.roundStats.deaths += 1
    C.state.deadPlayers[player.UserId] = {name = player.Name, time = os.time(), entity = entity}
    C.state.lastDead = player.Name
    Chat("💀 " .. player.Name .. " se moveu! " .. entity .. " apareceu!")
    DiscordEvent("💀 Jogador morreu", player.Name .. " se moveu na luz vermelha.\nEntidade: **" .. entity .. "**\nSala: " .. C.config.currentRoom, 15158332)
    ApiUpdate({event = "death", player = player.Name, entity = entity, room = C.config.currentRoom})
end

local function CheckAllDead()
    if not C.config.autoRevive then return end
    local total = #UpdateCache()
    local dead = 0
    for _, p in ipairs(C.cache.players) do if not IsAlive(p) then dead += 1 end end
    if dead >= total then ReviveAll() end
end

local entitySpawnThread = nil
local function StartRandomEntitySpawning()
    if entitySpawnThread then task.cancel(entitySpawnThread) end
    entitySpawnThread = task.spawn(function()
        while C.active and C.config.modEnabled and C.config.entitySpawnEnabled do
            local wait = math.random(C.config.entitySpawnInterval.min, C.config.entitySpawnInterval.max)
            task.wait(wait)
            if not C.active then break end
            local entity = C.entitiesList[math.random(#C.entitiesList)]
            SpawnEntity(entity, nil)
            Chat("👻 " .. entity .. " apareceu aleatoriamente!")
        end
    end)
end

local function StopRandomEntitySpawning()
    if entitySpawnThread then task.cancel(entitySpawnThread) entitySpawnThread = nil end
end

local function SetLight(color)
    C.config.light = color
    Exec("LightRoom", {["Light Color"] = color == "green" and Color3.new(0,1,0) or Color3.new(1,0,0)})

    if color == "green" then
        PlaySound(C.sounds.green, "GreenLight", 5)
        Chat("🟢 Luz Verde - Ande!")
        Notif("Luz Verde", "Movimento permitido!", 4, Color3.fromRGB(0, 255, 0))
        if C.movementLoop then task.cancel(C.movementLoop) C.movementLoop = nil end
        DiscordEvent("🟢 Luz Verde", "Movimento liberado | Sala " .. C.config.currentRoom, 3066993)
        ApiUpdate({event = "green", room = C.config.currentRoom})
    else
        PlaySound(C.sounds.red, "RedLight", 5)
        Chat("🔴 Luz Vermelha - PARE IMEDIATAMENTE!")
        Notif("Luz Vermelha", "PARE DE SE MOVER!", 4, Color3.fromRGB(255, 0, 0))
        DiscordEvent("🔴 Luz Vermelha", "Jogadores devem parar | Sala " .. C.config.currentRoom, 15158332)
        ApiUpdate({event = "red", room = C.config.currentRoom})
        C.movementLoop = task.spawn(function()
            while C.active and C.config.light == "red" do
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("Humanoid") then
                        local h = p.Character.Humanoid
                        if h.Health > 0 and h.MoveDirection.Magnitude > 0 then
                            PunishMovement(p)
                        end
                    end
                end
                CheckAllDead()
                task.wait(0.3)
            end
        end)
    end
end

local function ToggleMod(enable)
    C.config.modEnabled = enable
    C.active = enable
    if not enable then
        SetLight("green")
        if C.movementLoop then task.cancel(C.movementLoop) C.movementLoop = nil end
        StopRandomEntitySpawning()
    else
        StartRandomEntitySpawning()
    end
    Chat("🔄 Mod " .. (enable and "ativado" or "desativado") .. "!")
    Notif("Sistema", "Mod " .. (enable and "ativado" or "desativado") .. "!", 5, enable and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0))
end

local function IsSpecialRoom(name)
    for _, s in ipairs(C.config.specialRooms) do if name:find(s) then return true end end
    return false
end

local function MonitorRoom()
    local room = LocalPlayer:GetAttribute("CurrentRoom")
    if not room then return end
    C.config.currentRoom = room

    local roomObj = workspace.CurrentRooms:FindFirstChild(tostring(room))
    if roomObj and roomObj:GetAttribute("RawName") then
        local rname = roomObj:GetAttribute("RawName")
        if IsSpecialRoom(rname) then
            if not C.config.specialRoomNotified then
                C.config.pausedByRoom = true
                C.active = false
                C.config.specialRoomNotified = true
                StopRandomEntitySpawning()
                Chat("⚠️ Sistema pausado - Sala especial!")
                Notif("Sala Especial", "Sistema pausado", 5, Color3.fromRGB(255, 0, 0))
            end
        else
            if C.config.pausedByRoom then
                C.config.pausedByRoom = false
                C.active = true
                C.config.specialRoomNotified = false
                StartRandomEntitySpawning()
                Chat("✅ Sistema retomado!")
                Notif("Sistema Retomado", "Continuando", 5, Color3.fromRGB(0,255,0))
            end
        end
    end

    if room >= 2 and not C.initialized then
        C.initialized = true
        C.active = true
        StartRandomEntitySpawning()
        Chat("✅ Mod ativado! Vermelho = PARE | Verde = ANDE")
        Notif("Sistema Ativo", "Vermelho PARE | Verde ANDE!", 5, Color3.fromRGB(0,255,0))
        DiscordEvent("✅ Mod iniciado", "Host: " .. C.config.host .. " | Sala: " .. room, 3066993)
    end

    if room >= C.config.winRoom and not C.config.gameWon then
        C.config.gameWon = true
        local alive = GetAlive()
        if #alive > 0 then
            Chat("🏆 PARABÉNS! Porta " .. C.config.winRoom .. " alcançada! " .. #alive .. " jogadores sobreviveram!")
            Notif("VITÓRIA", "Desafio completo!", 10, Color3.fromRGB(0,255,0))
            for _, p in ipairs(alive) do
                local hp = GetPlayerHealth(p)
                Exec("Apply Changes", {["Players"] = {[p.Name] = p.Name}, ["Max Health"] = 200, ["Star Shield"] = 100, ["Health"] = 200, ["Speed Boost"] = 20, ["God Mode"] = true})
            end
            GiveRewardToAll("legendary")
            DiscordEvent("🏆 Vitória!", #alive .. " jogadores chegaram à porta " .. C.config.winRoom, 16766720)
        end
    end
end

local Commands = {}

local function HostOnly(player)
    if player.Name ~= C.config.host then Chat("❌ Apenas o host!") return false end
    return true
end

function Commands:speed(player)
    if not C.config.commandsEnabled and player.Name ~= C.config.host then return end
    local hp = GetPlayerHealth(player)
    Exec("Apply Changes", {["Players"] = {[player.Name] = player.Name}, ["Speed Boost"] = 25, ["Health"] = hp, ["Max Health"] = math.max(hp, 100)})
end

function Commands:resetspeed(player)
    if not C.config.commandsEnabled and player.Name ~= C.config.host then return end
    local hp = GetPlayerHealth(player)
    Exec("Apply Changes", {["Players"] = {[player.Name] = player.Name}, ["Speed Boost"] = 0, ["Health"] = hp, ["Max Health"] = math.max(hp, 100)})
end

function Commands:godmode(player)
    if not C.config.commandsEnabled and player.Name ~= C.config.host then return end
    local hp = GetPlayerHealth(player)
    Exec("Apply Changes", {["Players"] = {[player.Name] = player.Name}, ["Max Health"] = 100, ["Health"] = hp, ["God Mode"] = true})
end

function Commands:vida(player)
    if not C.config.commandsEnabled and player.Name ~= C.config.host then return end
    Exec("Apply Changes", {["Players"] = {[player.Name] = player.Name}, ["Max Health"] = 100, ["Star Shield"] = 100, ["Health"] = 100, ["God Mode"] = false})
end

function Commands:shield(player)
    if not C.config.commandsEnabled and player.Name ~= C.config.host then return end
    local hp = GetPlayerHealth(player)
    Exec("Apply Changes", {["Players"] = {[player.Name] = player.Name}, ["Star Shield"] = 100, ["Health"] = hp, ["Max Health"] = math.max(hp, 100)})
end

function Commands:revive(player)
    if not C.config.commandsEnabled and player.Name ~= C.config.host then return end
    Exec("RevivePlayer", {["Players"] = {[player.Name] = player.Name}})
end

function Commands:item(player)
    if not C.config.commandsEnabled and player.Name ~= C.config.host then return end
    local item = GiveReward(player, nil)
    Chat("🎁 " .. player.Name .. " recebeu: " .. item)
end

function Commands:stats()
    local alive = #GetAlive()
    local total = #UpdateCache()
    Chat("📊 Vivos: " .. alive .. "/" .. total .. " | Sala: " .. C.config.currentRoom .. " | Dif: " .. C.config.difficulty .. " | Mortes: " .. C.state.roundStats.deaths)
end

function Commands:comandos()
    Chat("📋 !speed !resetspeed !godmode !vida !shield !revive !item !stats !entities !items")
    task.wait(0.3)
    Chat("📋 Host: !togglemod !spawn !randomentity !kill !debug !cmds !difficulty !allitems !giveall !reviveall")
end

function Commands:items()
    for r, its in pairs(C.items) do
        Chat("- " .. r:upper() .. ": " .. table.concat(its, ", "))
        task.wait(0.3)
    end
end

function Commands:entities()
    for r, ents in pairs(C.entities) do
        Chat("- " .. r:upper() .. ": " .. table.concat(ents, ", "))
        task.wait(0.3)
    end
end

function Commands:togglemod(player)
    if not HostOnly(player) then return end
    ToggleMod(not C.config.modEnabled)
end

function Commands:debug(player)
    if not HostOnly(player) then return end
    C.config.debugMode = not C.config.debugMode
    Chat("🔧 Debug: " .. (C.config.debugMode and "ON" or "OFF"))
end

function Commands:cmds(player)
    if not HostOnly(player) then return end
    C.config.commandsEnabled = not C.config.commandsEnabled
    Chat("🔧 Comandos: " .. (C.config.commandsEnabled and "ativados" or "desativados"))
end

function Commands:difficulty(player)
    if not HostOnly(player) then return end
    IncreaseDifficulty()
end

function Commands:reviveall(player)
    if not HostOnly(player) then return end
    ReviveAll()
end

function Commands:allitems(player)
    if not HostOnly(player) then return end
    GiveRewardToAll(nil)
end

function Commands:giveall(player, args)
    if not HostOnly(player) then return end
    GiveRewardToAll(args[2])
end

function Commands:spawn(player, args)
    if not HostOnly(player) then return end
    if not args[2] then Chat("❌ !spawn [entidade]") return end
    local name = args[2]:lower()
    local found
    for _, e in ipairs(C.entitiesList) do if e:lower() == name then found = e break end end
    for _, e in ipairs(C.specialEntities) do if e:lower() == name then found = e break end end
    if not found then Chat("❌ Entidade não encontrada!") return end
    SpawnEntity(found, nil)
    Chat("👻 " .. found .. " invocado!")
end

function Commands:randomentity(player)
    if not HostOnly(player) then return end
    local e = C.entitiesList[math.random(#C.entitiesList)]
    SpawnEntity(e, nil)
    Chat("👻 " .. e .. " invocado aleatoriamente!")
end

function Commands:kill(player, args)
    if not HostOnly(player) then return end
    if C.state.voteActive then Chat("❌ Votação em andamento!") return end
    if not args[2] then Chat("❌ !kill [nome]") return end
    local targetId = args[2]:lower()
    local target
    for _, p in ipairs(UpdateCache()) do
        if p.Name:lower() == targetId or tostring(p.UserId) == targetId then target = p break end
    end
    if not target then Chat("❌ Jogador não encontrado!") return end
    C.state.voteActive = true
    C.state.votes = {yes = 0, no = 0}
    Chat("🎯 Votar: eliminar " .. target.Name .. "? Y/N (19s)")
    local voters = {}
    local conn = TextChatService.MessageReceived:Connect(function(msg)
        if not C.state.voteActive then return end
        local src = msg.TextSource
        if voters[src.UserId] then return end
        local v = msg.Text:lower()
        if v == "y" then C.state.votes.yes += 1 voters[src.UserId] = true
        elseif v == "n" then C.state.votes.no += 1 voters[src.UserId] = true end
    end)
    task.wait(19)
    C.state.voteActive = false
    conn:Disconnect()
    if C.state.votes.yes > C.state.votes.no then
        Exec("KillPlayer", {["Players"] = {[target.Name] = target.Name}})
        Chat("☠️ " .. target.Name .. " eliminado! (" .. C.state.votes.yes .. " vs " .. C.state.votes.no .. ")")
    else
        Chat("✨ " .. target.Name .. " foi poupado! (" .. C.state.votes.no .. " vs " .. C.state.votes.yes .. ")")
    end
end

TextChatService.MessageReceived:Connect(function(msg)
    local src = msg.TextSource
    local args = msg.Text:lower():split(" ")
    local cmd = args[1]
    if cmd:sub(1,1) == "!" then
        local name = cmd:sub(2)
        if Commands[name] then Commands[name](Commands, src, args) end
    end
end)

local Window = Library:CreateWindow({
    Title = "Green Light Red Light v" .. C.version,
    Footer = "by rhyan57",
    Icon = 95816097006870,
    NotifySide = "Right",
    ToggleKeybind = Enum.KeyCode.RightShift,
})

local TabMain = Window:AddTab("⚙️ Principal")
local TabDifficulty = Window:AddTab("📈 Dificuldade")
local TabEntities = Window:AddTab("👻 Entidades")
local TabDiscord = Window:AddTab("💬 Discord")
local TabAPI = Window:AddTab("🌐 API Session")

local GbControl = TabMain:AddLeftGroupbox("Controle")
local GbSettings = TabMain:AddRightGroupbox("Configurações")

GbControl:AddButton("▶ Ativar Mod", function()
    ToggleMod(true)
end)

GbControl:AddButton("⏸ Pausar Mod", function()
    ToggleMod(false)
end)

GbControl:AddButton("🟢 Forçar Luz Verde", function()
    if not C.active then Notif("Erro", "Mod não está ativo!", 3, Color3.fromRGB(255,0,0)) return end
    SetLight("green")
end)

GbControl:AddButton("🔴 Forçar Luz Vermelha", function()
    if not C.active then Notif("Erro", "Mod não está ativo!", 3, Color3.fromRGB(255,0,0)) return end
    SetLight("red")
end)

GbControl:AddButton("✨ Reviver Todos", function()
    ReviveAll()
end)

GbControl:AddButton("🎁 Dar Itens a Todos", function()
    GiveRewardToAll(nil)
end)

GbControl:AddButton("🎲 Spawnar Entidade Aleatória", function()
    if not C.active then Notif("Erro", "Mod não está ativo!", 3, Color3.fromRGB(255,0,0)) return end
    local e = C.entitiesList[math.random(#C.entitiesList)]
    SpawnEntity(e, nil)
    Chat("👻 " .. e .. " invocado!")
end)

GbSettings:AddToggle("AutoRevive", {
    Text = "Auto Reviver quando todos morrem",
    Default = true,
    Callback = function(v) C.config.autoRevive = v end,
})

GbSettings:AddToggle("CommandsEnabled", {
    Text = "Comandos por chat habilitados",
    Default = true,
    Callback = function(v) C.config.commandsEnabled = v end,
})

GbSettings:AddToggle("DebugMode", {
    Text = "Modo Debug",
    Default = false,
    Callback = function(v) C.config.debugMode = v end,
})

GbSettings:AddInput("WinRoom", {
    Text = "Porta de vitória",
    Default = "100",
    Numeric = true,
    Finished = true,
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then C.config.winRoom = n Notif("Config", "Porta de vitória: " .. n, 3) end
    end,
})

local GbGreenTime = TabDifficulty:AddLeftGroupbox("Tempo Verde (segundos)")
local GbRedTime = TabDifficulty:AddRightGroupbox("Tempo Vermelho (segundos)")
local GbDiffCtrl = TabDifficulty:AddLeftGroupbox("Controle de Dificuldade")

GbGreenTime:AddSlider("GreenMin", {
    Text = "Mínimo",
    Default = 50, Min = 10, Max = 120, Rounding = 0,
    Callback = function(v) C.config.greenTime.min = v end,
})
GbGreenTime:AddSlider("GreenMax", {
    Text = "Máximo",
    Default = 70, Min = 10, Max = 120, Rounding = 0,
    Callback = function(v) C.config.greenTime.max = v end,
})

GbRedTime:AddSlider("RedMin", {
    Text = "Mínimo",
    Default = 25, Min = 5, Max = 60, Rounding = 0,
    Callback = function(v) C.config.redTime.min = v end,
})
GbRedTime:AddSlider("RedMax", {
    Text = "Máximo",
    Default = 35, Min = 5, Max = 60, Rounding = 0,
    Callback = function(v) C.config.redTime.max = v end,
})

GbDiffCtrl:AddSlider("MaxDifficulty", {
    Text = "Dificuldade Máxima",
    Default = 5, Min = 1, Max = 10, Rounding = 0,
    Callback = function(v) C.config.maxDifficulty = v end,
})

GbDiffCtrl:AddButton("📈 Aumentar Dificuldade Agora", function()
    IncreaseDifficulty()
end)

GbDiffCtrl:AddButton("🔄 Resetar Dificuldade", function()
    C.config.difficulty = 1
    C.config.roundNumber = 0
    C.config.greenTime = {min = 50, max = 70}
    C.config.redTime = {min = 25, max = 35}
    Chat("🔄 Dificuldade resetada!")
end)

local GbEntitySpawn = TabEntities:AddLeftGroupbox("Spawn Aleatório")
local GbEntityManual = TabEntities:AddRightGroupbox("Spawn Manual")

GbEntitySpawn:AddToggle("EntitySpawnEnabled", {
    Text = "Spawn automático ativo",
    Default = true,
    Callback = function(v)
        C.config.entitySpawnEnabled = v
        if v and C.active then StartRandomEntitySpawning() else StopRandomEntitySpawning() end
    end,
})

GbEntitySpawn:AddSlider("EntitySpawnMin", {
    Text = "Intervalo mínimo (s)",
    Default = 15, Min = 5, Max = 120, Rounding = 0,
    Callback = function(v) C.config.entitySpawnInterval.min = v end,
})

GbEntitySpawn:AddSlider("EntitySpawnMax", {
    Text = "Intervalo máximo (s)",
    Default = 45, Min = 5, Max = 180, Rounding = 0,
    Callback = function(v) C.config.entitySpawnInterval.max = v end,
})

local entityDropdownOptions = {}
for _, e in ipairs(C.entitiesList) do table.insert(entityDropdownOptions, e) end
for _, e in ipairs(C.specialEntities) do table.insert(entityDropdownOptions, e) end

local selectedEntity = entityDropdownOptions[1]
GbEntityManual:AddDropdown("EntitySelect", {
    Text = "Entidade",
    Values = entityDropdownOptions,
    Default = 1,
    Callback = function(v) selectedEntity = v end,
})

GbEntityManual:AddButton("👻 Spawnar Selecionada", function()
    SpawnEntity(selectedEntity, nil)
    Chat("👻 " .. selectedEntity .. " invocado manualmente!")
end)

GbEntityManual:AddButton("💀 A-90 (spawnar agora)", function()
    SpawnEntity("A-90", nil)
    DiscordEvent("☠️ A-90 Invocado", "O A-90 foi invocado manualmente | Sala " .. C.config.currentRoom, 10038562)
end)

local GbDiscordConfig = TabDiscord:AddLeftGroupbox("Configuração")
local GbDiscordTest = TabDiscord:AddRightGroupbox("Teste")

GbDiscordConfig:AddToggle("DiscordEnabled", {
    Text = "Notificações Discord ativas",
    Default = false,
    Callback = function(v) C.discord.enabled = v end,
})

GbDiscordConfig:AddToggle("DiscordUseWebhook", {
    Text = "Usar Webhook (desligado = Bot Token)",
    Default = true,
    Callback = function(v) C.discord.useWebhook = v end,
})

GbDiscordConfig:AddInput("DiscordWebhook", {
    Text = "URL do Webhook",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Finished = true,
    Callback = function(v) C.discord.webhookUrl = v end,
})

GbDiscordConfig:AddInput("DiscordBotToken", {
    Text = "Bot Token",
    Default = "",
    Placeholder = "MTk4NjIyN...",
    Finished = true,
    Callback = function(v) C.discord.botToken = v end,
})

GbDiscordConfig:AddInput("DiscordChannelId", {
    Text = "ID do Canal (Bot Token)",
    Default = "",
    Placeholder = "123456789012345678",
    Finished = true,
    Callback = function(v) C.discord.channelId = v end,
})

GbDiscordTest:AddButton("📤 Enviar Mensagem de Teste", function()
    if not C.discord.enabled then
        Notif("Discord", "Ative as notificações primeiro!", 3, Color3.fromRGB(255,0,0))
        return
    end
    DiscordEvent("🧪 Teste", "GLRL conectado e funcionando!\nHost: " .. C.config.host, 3447003)
    Notif("Discord", "Mensagem de teste enviada!", 3, Color3.fromRGB(0, 255, 0))
end)

local GbAPIConfig = TabAPI:AddLeftGroupbox("Configuração da API")
local GbAPIStatus = TabAPI:AddRightGroupbox("Status da Sessão")

GbAPIConfig:AddToggle("APIEnabled", {
    Text = "Sistema de sessão ativo",
    Default = false,
    Callback = function(v) C.api.enabled = v end,
})

GbAPIConfig:AddInput("APIUrl", {
    Text = "URL da API",
    Default = "https://glrl-api.onrender.com",
    Placeholder = "https://sua-api.com",
    Finished = true,
    Callback = function(v) C.api.url = v end,
})

GbAPIConfig:AddButton("🔌 Conectar (Create Session)", function()
    if not C.api.enabled then
        Notif("API", "Ative o sistema de sessão primeiro!", 3, Color3.fromRGB(255,0,0))
        return
    end
    ApiConnect()
end)

GbAPIConfig:AddButton("❌ Desconectar", function()
    C.api.sessionId = nil
    C.api.wsConnected = false
    Notif("API", "Desconectado!", 3, Color3.fromRGB(255, 165, 0))
end)

GbAPIStatus:AddLabel("SessionLabel"):SetText("Sessão: Não conectado")
GbAPIStatus:AddLabel("SessionUrlLabel"):SetText("Link: -")

local SessionLabel = GbAPIStatus:AddLabel("Clique em Conectar acima")
task.spawn(function()
    while true do
        task.wait(2)
        if C.api.sessionId then
            SessionLabel:SetText("✅ ID: " .. C.api.sessionId:sub(1, 20) .. "...")
        else
            SessionLabel:SetText("❌ Não conectado")
        end
    end
end)

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:SetFolder("GLRL")
SaveManager:BuildConfigSection(TabMain:AddRightGroupbox("💾 Config"))
ThemeManager:ApplyToTab(Window:AddTab("🎨 Temas"))

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
StatsLabel.TextSize = 13
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.Parent = TimerFrame

task.spawn(function()
    while true do
        if C.active and C.config.modEnabled then
            local timeRange = C.config.light == "green" and C.config.greenTime or C.config.redTime
            local timeLeft = math.random(timeRange.min, timeRange.max)
            local icon = C.config.light == "green" and "🟢" or "🔴"

            if C.config.light == "red" then
                local a90Time = timeLeft - 2
                task.spawn(function()
                    task.wait(a90Time > 0 and a90Time or 0)
                    if C.active and C.config.light == "red" then
                        task.wait(2)
                        if C.active and C.config.light == "red" then
                            SpawnEntity("A-90", nil)
                            DiscordEvent("☠️ A-90", "A-90 spawnado automaticamente | Sala " .. C.config.currentRoom, 10038562)
                        end
                    end
                end)
            end

            for i = timeLeft, 1, -1 do
                if not C.active then break end
                local alive = #GetAlive()
                local total = #UpdateCache()
                TimerLabel.Text = icon .. " Próximo: " .. i .. "s"
                StatsLabel.Text = "Sala " .. C.config.currentRoom .. " | " .. alive .. "/" .. total .. " | Dif:" .. C.config.difficulty
                if i == 10 then Chat("⚠️ 10 segundos para mudança!") end
                if i == 3 then Chat("⚠️ 3 segundos!") end
                task.wait(1)
            end

            if C.active then
                SetLight(C.config.light == "green" and "red" or "green")
                if C.config.light == "green" and math.random(1, 5) <= C.config.difficulty then
                    IncreaseDifficulty()
                end
            end
        else
            TimerLabel.Text = "Sistema Pausado"
            StatsLabel.Text = "Sala " .. C.config.currentRoom
            task.wait(1)
        end
    end
end)

task.spawn(function()
    while true do task.wait(1) MonitorRoom() end
end)

task.spawn(function()
    while true do
        task.wait(math.random(C.config.itemDropTime.min, C.config.itemDropTime.max))
        if C.active and C.config.modEnabled then GiveRewardToAll() end
    end
end)

Players.PlayerAdded:Connect(function(p)
    C.state.playerScores[p.UserId] = 0
    C.state.survivalTime[p.UserId] = 0
    task.wait(2)
    Chat("👋 Bem-vindo " .. p.DisplayName .. "! Use !comandos para ver os comandos.")
    DiscordEvent("👋 Jogador entrou", p.Name .. " (" .. p.DisplayName .. ")", 3447003)
end)

Players.PlayerRemoving:Connect(function(p)
    C.state.playerScores[p.UserId] = nil
    C.state.survivalTime[p.UserId] = nil
    C.state.deadPlayers[p.UserId] = nil
end)

Caption("GLRL v" .. C.version .. " carregado! [RShift = Menu]")
task.wait(3)
Caption("Made by Rhyan57 | v" .. C.version)
Notif("GLRL Carregado", "RShift para abrir o menu! Passe da porta 2 para ativar.", 10, Color3.fromRGB(255, 255, 0))
Chat("[ GLRL v" .. C.version .. " ] Use !comandos | Menu: RShift")
