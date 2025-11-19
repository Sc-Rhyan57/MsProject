local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

if shared.roundsix then
    require(Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("Mod já carregado!", true)
    return
end

local Notify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Msdoors/Msdoors.gg/refs/heads/main/Scripts/Msdoors/Notification/Source.lua"))()

shared.roundsix = {
    version = "0.1.0",
    initialized = false,
    active = false,
    
    config = {
        light = "🟢",
        greenTime = {min = 50, max = 70},
        redTime = {min = 25, max = 35},
        currentRoom = 0,
        pausedByRoom = false,
        specialRoomNotified = false,
        gameWon = false,
        host = Players.LocalPlayer.Name,
        voteActive = false,
        debugMode = false,
        autoRevive = true,
        itemDropTime = {min = 60, max = 120},
        specialRooms = {"SeekIntro", "Seek", "Halt"},
        commandsEnabled = true,
        modEnabled = true,
        difficulty = 1,
        roundNumber = 0,
        maxDifficulty = 5
    },
    
    state = {
        votes = {yes = 0, no = 0},
        deadPlayers = {},
        playerScores = {},
        survivalTime = {},
        roundStats = {
            deaths = 0,
            itemsGiven = 0,
            entitiesSpawned = 0
        }
    },
    
    cache = {
        players = {},
        rooms = {},
        lastUpdate = 0
    },
    
    items = {
        common = {
            "Flashlight", "Lighter", "Candle", "Shakelight", "Glowsticks", "Vitamins", 
            "Bread", "Cheese", "Donut", "Nanner", "AloeVera", "Key", "Lockpick", 
            "BatteryPack", "Compass", "LibraryHintPaper", "NannerPeel"
        },
        uncommon = {
            "Bulklight", "Straplight", "Lantern", "Smoothie", "GweenSoda", "BandagePack",
            "TipJar", "StarVial", "Shears", "AlarmClock", "LaserPointer", "HintBook",
            "KeyIron", "KeyElectrical", "KeyRetro", "GeneratorFuse", "LibraryHintPaperHard"
        },
        rare = {
            "Crucifix", "SkeletonKey", "StarJug", "HolyGrenade", "Bomb", "BigBomb",
            "Knockbomb", "BoxingGloves", "StopSign", "SnakeBox", "Multitool", "BigPropTool"
        },
        legendary = {
            "RiftSmoothie", "RiftCandle", "RiftJar", "StarBottle", "GoldGun", "KeyBackdoor"
        }
    },
    
    entities = {
        common = {"Eyes", "Screech"},
        uncommon = {"Rush", "Ambush", "Glitch"},
        rare = {"Figure", "A-60", "Blitz", "A-90"},
        legendary = {"A-120", "Jeff The Killer", "Lookman"}
    },
    
    sounds = {
        green = "https://github.com/Sc-Rhyan57/MsProject/raw/refs/heads/main/projects/data/sounds/doll-green-light.mp3",
        red = "https://github.com/Sc-Rhyan57/MsProject/raw/refs/heads/main/projects/data/sounds/doll-red-light.mp3"
    }
}

local Core = shared.roundsix
local LocalPlayer = Players.LocalPlayer

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

local function GetAudioFromGit(url, name)
    local fileName = `customObject_Sound_{name}.mp3`
    local success, data = pcall(function()
        return game:HttpGet(url)
    end)
    if not success then return nil end
    writefile(fileName, data)
    return (getcustomasset or getsynasset)(fileName)
end

local function PlaySound(url, name, volume)
    local soundId = GetAudioFromGit(url, name)
    if not soundId then return nil end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.Parent = workspace
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
        delfile(`customObject_Sound_{name}.mp3`)
    end)
    
    return sound
end

local function Caption(message)
    require(LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption(message, true)
end

local function NotifyPlayer(title, desc, time, color)
    Notify({
        Title = title,
        Description = desc,
        Reason = "",
        Color = color or Color3.fromRGB(0, 255, 0),
        Style = "Doors",
        Duration = time or 6,
        NotifyStyle = shared.msdoors and shared.msdoors.LibraryNotifyStyle or "Default"
    })
end

local function SendChat(message)
    if Core.config.debugMode then
        message = "[DEBUG] " .. message
    end
    
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

local function UpdatePlayerCache()
    local currentTime = tick()
    if currentTime - Core.cache.lastUpdate < 0.5 then
        return Core.cache.players
    end
    
    Core.cache.players = Players:GetPlayers()
    Core.cache.lastUpdate = currentTime
    return Core.cache.players
end

local function GetAlivePlayers()
    local alive = {}
    for _, player in ipairs(UpdatePlayerCache()) do
        if IsPlayerAlive(player) then
            table.insert(alive, player)
        end
    end
    return alive
end

local function GetDeadPlayers()
    local dead = {}
    for _, player in ipairs(UpdatePlayerCache()) do
        if not IsPlayerAlive(player) then
            table.insert(dead, player)
        end
    end
    return dead
end

local function IncreaseDifficulty()
    Core.config.roundNumber += 1
    if Core.config.difficulty < Core.config.maxDifficulty then
        Core.config.difficulty = math.min(
            Core.config.maxDifficulty,
            1 + math.floor(Core.config.roundNumber / 3)
        )
        
        Core.config.greenTime.max = math.max(40, 70 - (Core.config.difficulty * 5))
        Core.config.redTime.min = math.max(15, 25 - (Core.config.difficulty * 2))
        
        SendChat(`📈 Dificuldade aumentada: Nível {Core.config.difficulty}`)
        NotifyPlayer("Dificuldade", `Nível {Core.config.difficulty}`, 3, Color3.fromRGB(255, 165, 0))
    end
end

local function GiveReward(player, rarity)
    local itemPool = rarity and Core.items[rarity] or Core.itemsList
    local item = itemPool[math.random(#itemPool)]
    
    ExecuteCommand("Give Items", {
        ["Players"] = {[player.Name] = player.Name},
        ["Items"] = {[item] = item}
    })
    
    Core.state.roundStats.itemsGiven += 1
    return item
end

local function GiveRewardToAll(rarity)
    for _, player in ipairs(UpdatePlayerCache()) do
        GiveReward(player, rarity)
    end
    
    SendChat(`🎁 Itens {rarity or "aleatórios"} distribuídos!`)
    NotifyPlayer("Itens", `Você recebeu um item {rarity or "aleatório"}!`, 5, Color3.fromRGB(0, 255, 0))
end

local function ReviveAll()
    ExecuteCommand("DELETE ALL", {})
    
    local reviveArgs = {["Players"] = {}}
    for _, player in ipairs(UpdatePlayerCache()) do
        reviveArgs["Players"][player.Name] = player.Name
    end
    
    ExecuteCommand("RevivePlayer", reviveArgs)
    
    task.wait(1)
    
    Core.config.light = "🟢"
    Core.state.roundStats.deaths = 0
    
    SendChat("✨ Todos revividos! Entidades removidas!")
    NotifyPlayer("Reviver", "Todos foram revividos!", 5, Color3.fromRGB(0, 255, 0))
end

local function CheckAllDead()
    if not Core.config.autoRevive then return false end
    
    local deadCount = 0
    local totalPlayers = #UpdatePlayerCache()
    
    for _, player in ipairs(Core.cache.players) do
        if not IsPlayerAlive(player) then
            deadCount += 1
        end
    end
    
    if deadCount >= totalPlayers then
        ReviveAll()
        return true
    end
    
    return false
end

local function PunishMovement(player)
    local entity = Core.entitiesList[math.random(#Core.entitiesList)]
    local killMethod = math.random(1, 2) == 1 and "KillPlayer" or "ExplodePlayer"
    
    ExecuteCommand(killMethod, {
        ["Players"] = {[player.Name] = player.Name}
    })
    
    if entity == "A-90" then
        ExecuteCommand("A90Player", {
            ["Players"] = {[player.Name] = player.Name}
        })
    elseif entity == "Screech" then
        ExecuteCommand("ScreechPlayer", {
            ["Players"] = {[player.Name] = player.Name}
        })
    elseif entity == "Glitch" then
        ExecuteCommand("GlitchPlayer", {
            ["Players"] = {[player.Name] = player.Name}
        })
    else
        ExecuteCommand(entity, {
            ["Players"] = {[player.Name] = player.Name}
        })
    end
    
    Core.state.roundStats.deaths += 1
    Core.state.roundStats.entitiesSpawned += 1
    
    Core.state.deadPlayers[player.UserId] = {
        name = player.Name,
        time = os.time(),
        entity = entity
    }
    
    SendChat(`💀 {player.Name} se moveu na luz vermelha! {entity} apareceu!`)
end

local movementLoop = nil

local function SetLight(color)
    Core.config.light = color
    ExecuteCommand("LightRoom", {
        ["Light Color"] = color == "🟢" and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    })
    
    if color == "🟢" then
        PlaySound(Core.sounds.green, "GreenLight", 5)
        SendChat("🟢 Luz verde - Ande")
        NotifyPlayer("Luz Verde", "Movimento permitido!", 5, Color3.fromRGB(0, 255, 0))
        
        if movementLoop then
            task.cancel(movementLoop)
            movementLoop = nil
        end
    else
        PlaySound(Core.sounds.red, "RedLight", 5)
        SendChat("🔴 Luz Vermelha - PARE IMEDIATAMENTE!")
        NotifyPlayer("Luz Vermelha", "PARE DE SE MOVER!", 5, Color3.fromRGB(255, 0, 0))
        
        movementLoop = task.spawn(function()
            while Core.active and Core.config.light == "🔴" do
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

local function ToggleMod(enable)
    Core.config.modEnabled = enable
    Core.active = enable
    
    if not enable then
        Core.config.light = "🟢"
        SetLight("🟢")
        if movementLoop then
            task.cancel(movementLoop)
            movementLoop = nil
        end
    end
    
    local status = enable and "ativado" or "desativado"
    SendChat(`🔄 Mod {status}!`)
    NotifyPlayer("Sistema", `Mod {status}!`, 5, enable and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
end

local function IsSpecialRoom(roomName)
    for _, special in ipairs(Core.config.specialRooms) do
        if roomName:find(special) then
            return true
        end
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
                
                SendChat("⚠️ Sistema pausado - Sala especial detectada!")
                NotifyPlayer("Sala Especial", "Sistema pausado temporariamente", 5, Color3.fromRGB(255, 0, 0))
            end
        else
            if Core.config.pausedByRoom then
                Core.config.pausedByRoom = false
                Core.active = true
                Core.config.specialRoomNotified = false
                
                SendChat("✅ Sistema retomado - Sala normal detectada!")
                NotifyPlayer("Sistema Retomado", "Continuando operação normal", 5, Color3.fromRGB(0, 255, 0))
            end
        end
    end
    
    if currentRoom >= 2 and not Core.initialized then
        Core.initialized = true
        Core.active = true
        
        SendChat("✅ Mod ativado")
        SendChat("[DICA] Vermelho = PARE | Verde = ANDE | Fique de olho no chat!")
        NotifyPlayer("Sistema Ativo", "Vermelho PARE | Verde ANDE!", 5, Color3.fromRGB(0, 255, 0))
    end
    
    if currentRoom == 100 and not Core.config.gameWon then
        Core.config.gameWon = true
        
        local alivePlayers = GetAlivePlayers()
        
        if #alivePlayers > 0 then
            SendChat("🏆 PARABÉNS! Porta 100 alcançada!")
            SendChat(`🎉 {#alivePlayers} jogadores sobreviveram!`)
            NotifyPlayer("VITÓRIA", "Desafio completo!", 10, Color3.fromRGB(0, 255, 0))
            
            for _, player in ipairs(alivePlayers) do
                ExecuteCommand("Apply Changes", {
                    ["Players"] = {[player.Name] = player.Name},
                    ["Max Health"] = 200,
                    ["Star Shield"] = 100,
                    ["Health"] = 200,
                    ["Speed Boost"] = 20,
                    ["God Mode"] = true
                })
            end
            
            GiveRewardToAll("legendary")
            SendChat("🎁 Recompensas de vitória distribuídas!")
        end
    end
end

local TimerGui = Instance.new("ScreenGui")
local TimerFrame = Instance.new("Frame")
local TimerLabel = Instance.new("TextLabel")
local StatsLabel = Instance.new("TextLabel")

TimerGui.Name = "EventTimer"
TimerGui.ResetOnSpawn = false
TimerGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

TimerFrame.Size = UDim2.new(0, 200, 0, 80)
TimerFrame.Position = UDim2.new(0.84, 0, 0.08, 0)
TimerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TimerFrame.BackgroundTransparency = 0.3
TimerFrame.BorderSizePixel = 0
TimerFrame.Parent = TimerGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = TimerFrame

TimerLabel.Size = UDim2.new(1, 0, 0.5, 0)
TimerLabel.BackgroundTransparency = 1
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimerLabel.TextSize = 18
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.Parent = TimerFrame

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
    ExecuteCommand("Apply Changes", {
        ["Players"] = {[player.Name] = player.Name},
        ["Max Health"] = 100,
        ["God Mode"] = true
    })
end

function Commands:vida(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    ExecuteCommand("Apply Changes", {
        ["Players"] = {[player.Name] = player.Name},
        ["Max Health"] = 100,
        ["Star Shield"] = 100,
        ["Health"] = 100,
        ["God Mode"] = false
    })
end

function Commands:pxitem(player, args)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    if not args[2] then
        SendChat("❌ Use: !pxitem [nome do item]")
        return
    end
    
    local itemName = args[2]:lower()
    local foundItem = nil
    
    for _, items in pairs(Core.items) do
        for _, item in ipairs(items) do
            if item:lower() == itemName then
                foundItem = item
                break
            end
        end
        if foundItem then break end
    end
    
    if not foundItem then
        SendChat("❌ Item não encontrado! Use !items para ver a lista.")
        return
    end
    
    GiveReward(player, nil)
end

function Commands:revive(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    ExecuteCommand("RevivePlayer", {["Players"] = {[player.Name] = player.Name}})
end

function Commands:speed(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    ExecuteCommand("Apply Changes", {
        ["Players"] = {[player.Name] = player.Name},
        ["Speed Boost"] = 25
    })
end

function Commands:resetspeed(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    ExecuteCommand("Apply Changes", {
        ["Players"] = {[player.Name] = player.Name},
        ["Speed Boost"] = 0
    })
end

function Commands:item(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    local item = GiveReward(player, nil)
    SendChat(`🎁 {player.Name} recebeu: {item}`)
end

function Commands:shield(player)
    if not Core.config.commandsEnabled and player.Name ~= Core.config.host then return end
    ExecuteCommand("Apply Changes", {
        ["Players"] = {[player.Name] = player.Name},
        ["Star Shield"] = 100
    })
end

function Commands:items()
    SendChat("📦 Lista de Itens por Raridade:")
    task.wait(0.3)
    for rarity, items in pairs(Core.items) do
        SendChat(`- {rarity:upper()}: {table.concat(items, ", ")}`)
        task.wait(0.3)
    end
end

function Commands:entities()
    SendChat("👻 Lista de Entidades por Raridade:")
    task.wait(0.3)
    for rarity, entities in pairs(Core.entities) do
        SendChat(`- {rarity:upper()}: {table.concat(entities, ", ")}`)
        task.wait(0.3)
    end
end

function Commands:comandos()
    SendChat("📋 Comandos disponíveis:")
    task.wait(0.5)
    SendChat("- Gerais: !pxitem, !vida, !revive, !godmode, !speed, !resetspeed, !item, !shield")
    task.wait(0.5)
    SendChat("- Informações: !items, !entities, !comandos, !stats")
    task.wait(0.5)
    SendChat("- Host: !togglemod, !spawn, !spawnall, !randomentity, !kill, !debug, !cmds, !difficulty")
    task.wait(0.5)
    SendChat("- Host Items: !allitems, !giveall [item]")
end

function Commands:stats()
    local alive = #GetAlivePlayers()
    local total = #UpdatePlayerCache()
    SendChat(`📊 Estatísticas:`)
    task.wait(0.3)
    SendChat(`- Vivos: {alive}/{total}`)
    task.wait(0.3)
    SendChat(`- Sala: {Core.config.currentRoom}`)
    task.wait(0.3)
    SendChat(`- Dificuldade: {Core.config.difficulty}`)
    task.wait(0.3)
    SendChat(`- Mortes: {Core.state.roundStats.deaths}`)
    task.wait(0.3)
    SendChat(`- Itens dados: {Core.state.roundStats.itemsGiven}`)
end

function Commands:kill(player, args)
    if player.Name ~= Core.config.host then
        SendChat("❌ Apenas o host pode usar este comando!")
        return
    end
    
    if Core.config.voteActive then
        SendChat("❌ Uma votação já está em andamento!")
        return
    end
    
    if not args[2] then
        SendChat("❌ Use: !kill [nome/displayname/userid]")
        return
    end
    
    local targetId = args[2]:lower()
    local target = nil
    
    for _, plr in ipairs(UpdatePlayerCache()) do
        if plr.Name:lower() == targetId or 
           (plr.DisplayName and plr.DisplayName:lower() == targetId) or 
           tostring(plr.UserId) == targetId then
            target = plr
            break
        end
    end
    
    if not target then
        SendChat("❌ Jogador não encontrado!")
        return
    end
    
    Core.config.voteActive = true
    Core.state.votes = {yes = 0, no = 0}
    
    SendChat(`🎯 Votação: eliminar {target.DisplayName} (@{target.Name})`)
    SendChat("Digite Y (sim) ou N (não)")
    SendChat("⏰ Votação termina em 19 segundos")
    
    local voters = {}
    
    local voteConnection = TextChatService.MessageReceived:Connect(function(msg)
        if not Core.config.voteActive then return end
        
        local voter = msg.TextSource
        if voters[voter.UserId] then return end
        
        local vote = msg.Text:lower()
        if vote == "y" then
            Core.state.votes.yes += 1
            voters[voter.UserId] = true
        elseif vote == "n" then
            Core.state.votes.no += 1
            voters[voter.UserId] = true
        end
    end)
    
    task.wait(19)
    Core.config.voteActive = false
    voteConnection:Disconnect()
    
    if Core.state.votes.yes > Core.state.votes.no then
        ExecuteCommand("KillPlayer", {["Players"] = {[target.Name] = target.Name}})
        SendChat(`☠️ {target.DisplayName} foi eliminado! ({Core.state.votes.yes} vs {Core.state.votes.no})`)
    else
        SendChat(`✨ {target.DisplayName} foi poupado! ({Core.state.votes.no} vs {Core.state.votes.yes})`)
    end
end

function Commands:spawn(player, args)
    if player.Name ~= Core.config.host then
        SendChat("❌ Apenas o host pode usar este comando!")
        return
    end
    
    if not args[2] then
        SendChat("❌ Use: !spawn [entidade]")
        SendChat(`📋 Disponíveis: {table.concat(Core.entitiesList, ", ")}`)
        return
    end
    
    local entityName = args[2]:lower()
    local found = nil
    
    for _, entity in ipairs(Core.entitiesList) do
        if entity:lower() == entityName then
            found = entity
            break
        end
    end
    
    if not found then
        SendChat("❌ Entidade não encontrada!")
        return
    end
    
    if found == "A-90" then
        for _, plr in ipairs(UpdatePlayerCache()) do
            ExecuteCommand("A90Player", {["Players"] = {[plr.Name] = plr.Name}})
        end
    elseif found == "Screech" then
        for _, plr in ipairs(UpdatePlayerCache()) do
            ExecuteCommand("ScreechPlayer", {["Players"] = {[plr.Name] = plr.Name}})
        end
    elseif found == "Glitch" then
        for _, plr in ipairs(UpdatePlayerCache()) do
            ExecuteCommand("GlitchPlayer", {["Players"] = {[plr.Name] = plr.Name}})
        end
    else
        ExecuteCommand(found, {})
    end
    
    Core.state.roundStats.entitiesSpawned += 1
    SendChat(`👻 {found} foi invocado!`)
end

function Commands:randomentity(player)
    if player.Name ~= Core.config.host then
        SendChat("❌ Apenas o host pode usar este comando!")
        return
    end
    
    local entity = Core.entitiesList[math.random(#Core.entitiesList)]
    
    if entity == "A-90" then
        for _, plr in ipairs(UpdatePlayerCache()) do
            ExecuteCommand("A90Player", {["Players"] = {[plr.Name] = plr.Name}})
        end
    elseif entity == "Screech" then
        for _, plr in ipairs(UpdatePlayerCache()) do
            ExecuteCommand("ScreechPlayer", {["Players"] = {[plr.Name] = plr.Name}})
        end
    elseif entity == "Glitch" then
        for _, plr in ipairs(UpdatePlayerCache()) do
            ExecuteCommand("GlitchPlayer", {["Players"] = {[plr.Name] = plr.Name}})
        end
    else
        ExecuteCommand(entity, {})
    end
    
    Core.state.roundStats.entitiesSpawned += 1
    SendChat(`👻 {entity} foi invocado aleatoriamente!`)
end

function Commands:debug(player)
    if player.Name ~= Core.config.host then
        SendChat("❌ Apenas o host pode usar este comando!")
        return
    end
    
    Core.config.debugMode = not Core.config.debugMode
    SendChat(`🔧 Debug: {Core.config.debugMode and "Ativado" or "Desativado"}`)
end

function Commands:togglemod(player)
    if player.Name ~= Core.config.host then
        SendChat("❌ Apenas o host pode usar este comando!")
        return
    end
    
    ToggleMod(not Core.config.modEnabled)
end

function Commands:cmds(player)
    if player.Name ~= Core.config.host then
        SendChat("❌ Apenas o host pode usar este comando!")
        return
    end
    
    Core.config.commandsEnabled = not Core.config.commandsEnabled
    local status = Core.config.commandsEnabled and "ativados" or "desativados"
    SendChat(`🔧 Comandos {status} para jogadores!`)
end

function Commands:difficulty(player)
    if player.Name ~= Core.config.host then
        SendChat("❌ Apenas o host pode usar este comando!")
        return
    end
    
    IncreaseDifficulty()
end

TextChatService.MessageReceived:Connect(function(message)
    local text = message.Text:lower()
    local player = message.TextSource
    local args = text:split(" ")
    local command = args[1]
    
    if command:sub(1, 1) == "!" then
        local cmdName = command:sub(2)
        if Commands[cmdName] then
            Commands[cmdName](Commands, player, args)
        end
    end
end)

task.spawn(function()
    while true do
        if Core.active and Core.config.modEnabled then
            local timeRange = Core.config.light == "🟢" and Core.config.greenTime or Core.config.redTime
            local timeLeft = math.random(timeRange.min, timeRange.max)
            
            for i = timeLeft, 1, -1 do
                if not Core.active then break end
                
                local alive = #GetAlivePlayers()
                local total = #UpdatePlayerCache()
                
                TimerLabel.Text = string.format("%s Próximo: %ds", Core.config.light, i)
                StatsLabel.Text = string.format("Sala %d | Vivos: %d/%d | Dif: %d", 
                    Core.config.currentRoom, alive, total, Core.config.difficulty)
                
                if i == 10 then
                    SendChat("⚠️ 10 segundos para mudança!")
                elseif i == 3 then
                    SendChat("⚠️ 3 segundos!")
                end
                
                task.wait(1)
            end
            
            if Core.active then
                SetLight(Core.config.light == "🟢" and "🔴" or "🟢")
                
                if Core.config.light == "🟢" and math.random(1, 10) == 1 then
                    IncreaseDifficulty()
                end
            end
        else
            TimerLabel.Text = "Sistema Pausado"
            StatsLabel.Text = `Sala {Core.config.currentRoom}`
            task.wait(1)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        MonitorRoom()
    end
end)

task.spawn(function()
    while true do
        local waitTime = math.random(Core.config.itemDropTime.min, Core.config.itemDropTime.max)
        task.wait(waitTime)
        
        if Core.active and Core.config.modEnabled then
            GiveRewardToAll()
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
    if not Core.config.host then
        Core.config.host = player.Name
        SendChat(`👑 {player.Name} é o host do servidor!`)
    end
    
    Core.state.playerScores[player.UserId] = 0
    Core.state.survivalTime[player.UserId] = 0
    
    task.wait(2)
    SendChat(`👋 Bem-vindo {player.DisplayName}! Use !comandos para ver os comandos.`)
end)

Players.PlayerRemoving:Connect(function(player)
    Core.state.playerScores[player.UserId] = nil
    Core.state.survivalTime[player.UserId] = nil
    Core.state.deadPlayers[player.UserId] = nil
end)

local function Initialize()
    Caption("Red Light Green Light - Otimizado!")
    task.wait(3)
    Caption("Made by Rhyan57 | Optimized v0.1.0")
    
    NotifyPlayer("Discord", "https://dsc.gg/msdoors-gg", 15, Color3.fromRGB(114, 137, 218))
    
    SendChat("[ DOORS SIX | 0.1.0 - OPTIMIZED ]")
    SendChat("📋 Use !comandos para ver todos os comandos")
    SendChat("⚠️ Passe da porta 2 para ativar o mod")
    
    NotifyPlayer("Mod Carregado", "Passe da porta 2 para ativar!", 10, Color3.fromRGB(255, 255, 0))
    
    for _, player in ipairs(Players:GetPlayers()) do
        Core.state.playerScores[player.UserId] = 0
        Core.state.survivalTime[player.UserId] = 0
    end
end

Initialize()
    