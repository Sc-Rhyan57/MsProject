local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local function GetGitAudioID(githubLink, soundName)
    local fileName = "customObject_Sound_" .. tostring(soundName) .. ".mp3"
    
    local success, audioData = pcall(function()
        return game:HttpGet(githubLink)
    end)
    
    if not success then
        warn("Falha ao baixar o áudio: " .. githubLink)
        return nil
    end
    
    writefile(fileName, audioData)
    return (getcustomasset or getsynasset)(fileName)
end

local function PlayGitSound(githubLink, soundName, volume)
    local soundId = GetGitAudioID(githubLink, soundName)
    
    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 0.5
        sound.Parent = workspace
        sound:Play()
        
        sound.Ended:Connect(function()
            sound:Destroy()
            delfile("customObject_Sound_" .. tostring(soundName) .. ".mp3")
        end)
        
        return sound
    end
    
    return nil
end

local function msg(message)
    local mainGame = require(LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game)
    mainGame.caption(message, true)
end

msg("Red Light Green Light iniciado!")
task.wait(0.6)
msg("Carregando Assets...")
wait(3)
msg("Assets baixados!")
wait(3)
msg("Made by Rhyan57")

local MsdoorsNotify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc-Rhyan57/Notification-doorsAPI/refs/heads/main/Msdoors/MsdoorsApi.lua"))()

if _G.DoorsSix then
    MsdoorsNotify("Sistema", "O mod já está carregado!", "", "rbxassetid://6023426923", Color3.new(1, 0, 0), 5)
    return
end
_G.DoorsSixLoaded = true

MsdoorsNotify("Entre no meu Discord", "https://dsc.gg/msdoors-gg", "", "rbxassetid://8248378219", Color3.new(114,137,218), 19)

_G.Config = {
    luzAtual = "🟢",
    tempoTrocaLuzVerde = math.random(50, 70),
    tempoTrocaLuzVermelha = math.random(25, 35),
    salaAtual = 0,
    jogadoresMortos = {},
    loopsAtivos = true,
    itensLoopAtivo = true,
    pausarPorSala = false,
    notificacaoSalaEspecial = false,
    systemActive = false,
    gameWon = false,
    hostPlayer = game.Players.LocalPlayer.Name,
    voteInProgress = false,
    currentVotes = {yes = 0, no = 0},
    debugMode = false,
    autoReviveEnabled = true,
    itemDropInterval = {min = 60, max = 120},
    specialRooms = {"SeekIntro", "Seek", "Halt", "A-60", "A-90"},
    debugLogs = {},
    commandsEnabled = true,
    modEnabled = true,
    debugFilePath = ".msprojects/Doors/debug_logs.txt"
}

_G.Items = {
    common = {"Flashlight", "Vitamins", "Lighter", "Shakelight", "Candle", "Bread"},
    uncommon = {"Crucifix", "TipJar", "StarVial", "Bulklight", "Smoothie", "Shears"},
    rare = {"HolyGrenade", "SkeletonKey", "GoldKey", "Shield", "Sword"},
    legendary = {"RiftSmoothie", "RiftCandle", "StarBottle"}
}

_G.itensAleatorios = {}
for _, items in pairs(_G.Items) do
    for _, item in ipairs(items) do
        table.insert(_G.itensAleatorios, item)
    end
end

_G.Entities = {
    common = {"Eyes", "Halt", "Timothy", "Screech"},
    uncommon = {"Rush", "Ambush", "Glitch", "Shadow"},
    rare = {"Figure", "A-60", "A-90", "Blitz"},
    legendary = {"A-120", "Jeff The Killer", "Lookman"}
}

_G.entidadesAleatorias = {}
for _, entities in pairs(_G.Entities) do
    for _, entity in ipairs(entities) do
        table.insert(_G.entidadesAleatorias, entity)
    end
end

local TimerGui = Instance.new("ScreenGui")
local TimerFrame = Instance.new("Frame")
local TimerLabel = Instance.new("TextLabel")

TimerGui.Name = "EventTimer"
TimerGui.ResetOnSpawn = false
TimerGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

TimerFrame.Name = "TimerFrame"
TimerFrame.Size = UDim2.new(0, 150, 0, 50)
TimerFrame.Position = UDim2.new(0.85, 0, 0.1, 0)
TimerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TimerFrame.BackgroundTransparency = 0.5
TimerFrame.Parent = TimerGui

TimerLabel.Name = "TimerLabel"
TimerLabel.Size = UDim2.new(1, 0, 1, 0)
TimerLabel.BackgroundTransparency = 1
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimerLabel.TextSize = 20
TimerLabel.Font = Enum.Font.SourceSansBold
TimerLabel.Parent = TimerFrame

local function SendMessage(message)
    if _G.Config.debugMode then
        message = "[DEBUG] " .. message
    end
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = TextChatService.TextChannels.RBXGeneral
        channel:SendAsync(message)
    else
        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
    end
end

local function Notificar(titulo, descricao, tempo, cor)
    MsdoorsNotify(titulo, descricao, "", "rbxassetid://6023426923", cor or Color3.new(0, 1, 0), tempo or 5)
end

local function saveDebugLog(message)
    if _G.Config.debugMode then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local logMessage = string.format("[%s] %s", timestamp, message)
        table.insert(_G.Config.debugLogs, logMessage)
        print(logMessage)
        pcall(function()
            if not isfolder("msprojects") then
                makefolder("msprojects")
            end
            if not isfolder("msprojects/Doors") then
                makefolder("msprojects/Doors")
            end
            appendfile(_G.Config.debugFilePath, logMessage .. "\n")
        end)
    end
end

local function reviverTodos()
    local args = {[1] = "RevivePlayer", [2] = {["Players"] = {}}}
    for _, player in ipairs(Players:GetPlayers()) do
        args[2]["Players"][player.Name] = player.Name
    end
    local deleteArgs = {[1] = "DELETE ALL", [2] = {}}
    ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(deleteArgs))
    ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    wait(1)
    Notificar("Reviver", "Todos os jogadores foram revividos!", 5)
    SendMessage("✨ Todos os jogadores foram revividos e as entidades foram removidas!")
    _G.Config.luzAtual = "🟢"
    alterarLuz("🟢")
end

local function verificarMortos()
    local todosJogadores = Players:GetPlayers()
    local jogadoresMortos = 0
    for _, player in ipairs(todosJogadores) do
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health <= 0 then
            jogadoresMortos = jogadoresMortos + 1
        end
    end
    if jogadoresMortos == #todosJogadores and _G.Config.autoReviveEnabled then
        reviverTodos()
    end
end

local function darItensAleatorios(rarity)
    local itemPool = rarity and _G.Items[rarity] or _G.itensAleatorios
    for _, player in ipairs(Players:GetPlayers()) do
        local itemAleatorio = itemPool[math.random(#itemPool)]
        local args = {
            [1] = "Give Items",
            [2] = {
                ["Players"] = {[player.Name] = player.Name},
                ["Items"] = {[itemAleatorio] = itemAleatorio}
            }
        }
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    end
    Notificar("Itens", "Você recebeu um item " .. (rarity and rarity or "aleatório") .. "!", 5)
    SendMessage("🎁 Itens " .. (rarity and rarity or "aleatórios") .. " distribuídos!")
end

local function alterarLuz(cor)
    _G.Config.luzAtual = cor
    local args = {[1] = "LightRoom", [2] = {["Light Color"] = cor == "🟢" and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)}}
    ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    if cor == "🟢" then
        
PlayGitSound("https://github.com/Sc-Rhyan57/MsProject/raw/refs/heads/main/projects/data/sounds/doll-green-light.mp3", "LuzVermelha", 5)
        SendMessage("Luz verde - Ande")
        Notificar("Luz Verde", "Movimento permitido!", 5)
    else
        
        PlayGitSound("https://github.com/Sc-Rhyan57/MsProject/raw/refs/heads/main/projects/data/sounds/doll-red-light.mp3", "LuzVermelha", 5)
        SendMessage("🔴 Luz Vermelha - PARE IMEDIATAMENTE!")
        Notificar("Luz Vermelha", "PARE DE SE MOVER!", 5)
        spawn(function()
            while _G.Config.loopsAtivos and _G.Config.luzAtual == "🔴" do
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Character and player.Character:FindFirstChild("Humanoid") and 
                       player.Character.Humanoid.Health > 0 and player.Character.Humanoid.MoveDirection.Magnitude > 0 then
                        local entidade = _G.entidadesAleatorias[math.random(#_G.entidadesAleatorias)]
                        local morteAleatoria = math.random(1, 2) == 1 and "KillPlayer" or "ExplodePlayer"
                        local args = {[1] = morteAleatoria, [2] = {["Players"] = {[player.Name] = player.Name}}}
                        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
                        local entidadeArgs = {[1] = entidade, [2] = {["Players"] = {[player.Name] = player.Name}}}
                        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(entidadeArgs))
                        SendMessage("💀 " .. player.Name .. " se moveu na luz vermelha e invocou " .. entidade .. "!")
                    end
                end
                verificarMortos()
                wait(0.5)
            end
        end)
    end
end

local function toggleMod(enable)
    _G.Config.modEnabled = enable
    _G.Config.systemActive = enable
    _G.Config.loopsAtivos = enable
    _G.Config.itensLoopAtivo = enable
    if not enable then
        _G.Config.luzAtual = "🟢"
        alterarLuz("🟢")
        TimerLabel.Text = "Mod Desativado"
    end
    local status = enable and "ativado" or "desativado"
    SendMessage("🔄 Mod foi " .. status .. "!")
    Notificar("Sistema", "Mod " .. status .. "!", 5, enable and Color3.new(0, 1, 0) or Color3.new(1, 0, 0))
    saveDebugLog("Mod status changed: " .. status)
end

local function monitorarSala()
    local player = Players.LocalPlayer
    local currentRoom = player:GetAttribute("CurrentRoom")
    if currentRoom then
        _G.Config.salaAtual = currentRoom
        local room = workspace.CurrentRooms:FindFirstChild(tostring(currentRoom))
        if room and room:GetAttribute("RawName") then
            local roomName = room:GetAttribute("RawName")
            local isSpecialRoom = false
            for _, specialRoom in ipairs(_G.Config.specialRooms) do
                if roomName:find(specialRoom) then
                    isSpecialRoom = true
                    break
                end
            end
            if isSpecialRoom then
                if not _G.Config.notificacaoSalaEspecial then
                    _G.Config.pausarPorSala = true
                    _G.Config.loopsAtivos = false
                    _G.Config.notificacaoSalaEspecial = true
                    Notificar("Sala Especial", "Sistema pausado temporariamente", 5, Color3.new(1, 0, 0))
                    SendMessage("⚠️ Sistema pausado - Sala especial detectada!")
                end
            else
                if _G.Config.pausarPorSala then
                    _G.Config.pausarPorSala = false
                    _G.Config.loopsAtivos = true
                    _G.Config.notificacaoSalaEspecial = false
                    Notificar("Sistema Retomado", "Continuando operação normal", 5)
                    SendMessage("✅ Sistema retomado - Você saiu da sala especial!")
                end
            end
        end
        if currentRoom >= 2 and not _G.Config.systemActive then
            _G.Config.systemActive = true
            SendMessage("✅ Mod ativado - Passando da porta 2!")
            SendMessage("📍 Quando estiver vermelho pare quando estiver verde ande.[ Fique de olho ao chat! ]")
            Notificar("Sistema Ativo", "Quando estiver vermelho PARE quando estiver VERDE ande!", 5)
        end
        if currentRoom == 100 and not _G.Config.gameWon then
            _G.Config.gameWon = true
            local allPlayersAlive = true
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health <= 0 then
                    allPlayersAlive = false
                    break
                end
            end
            if allPlayersAlive then
                SendMessage("🏆 PARABÉNS! Você chegou na porta 100!")
                SendMessage("🎉 Todos os jogadores sobreviveram até o final!")
                Notificar("VITÓRIA", "Você completou o desafio!", 10, Color3.new(0, 1, 0))
                for _, player in ipairs(Players:GetPlayers()) do
                    local args = {
                        [1] = "Apply Changes",
                        [2] = {
                            ["Players"] = {[player.Name] = player.Name},
                            ["Max Health"] = 200,
                            ["Star Shield"] = 100,
                            ["Health"] = 200,
                            ["Speed Boost"] = 20,
                            ["God Mode"] = true
                        }
                    }
                    ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
                end
                darItensAleatorios("legendary")
                SendMessage("🎁 Recompensas de vitória distribuídas!")
            end
        end
    end
end

local Commands = {
    ["!godmode"] = function(player)
     if not _G.Config.commandsEnabled and player.Name ~= _G.Config.hostPlayer then return end
        local args = {
            [1] = "Apply Changes",
            [2] = {
                ["Players"] = {[player.Name] = player.Name},
                ["Max Health"] = 100,
                ["Star Shield"] = 0,
                ["Health"] = 100,
                ["God Mode"] = true
            }
        }
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    end,
    
    ["!vida"] = function(player)
        if not _G.Config.commandsEnabled and player.Name ~= _G.Config.hostPlayer then return end
        local args = {
            [1] = "Apply Changes",
            [2] = {
                ["Players"] = {[player.Name] = player.Name},
                ["Max Health"] = 100,
                ["Star Shield"] = 100,
                ["Health"] = 100,
                ["God Mode"] = false
            }
        }
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    end,

    ["!pxitem"] = function(player, args)
        if not _G.Config.commandsEnabled and player.Name ~= _G.Config.hostPlayer then return end
        if not args[2] then
            SendMessage("❌ Use: !pxitem [nome do item]")
            return
        end
        local itemName = args[2]
        local validItem = false
        local actualItemName
        for rarity, items in pairs(_G.Items) do
            for _, item in ipairs(items) do
                if item:lower() == itemName:lower() then
                    validItem = true
                    actualItemName = item
                    break
                end
            end
            if validItem then break end
        end
        if not validItem then
            SendMessage("❌ Item não encontrado! Use !items para ver a lista de itens disponíveis.")
            return
        end
        local args = {
            [1] = "Give Items",
            [2] = {
                ["Players"] = {[player.Name] = player.Name},
                ["Items"] = {[actualItemName] = actualItemName}
            }
        }
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    end,

    ["!revive"] = function(player)
        if not _G.Config.commandsEnabled and player.Name ~= _G.Config.hostPlayer then return end
        local args = {[1] = "RevivePlayer", [2] = {["Players"] = {[player.Name] = player.Name}}}
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    end,

    ["!speed"] = function(player)
        if not _G.Config.commandsEnabled and player.Name ~= _G.Config.hostPlayer then return end
        local args = {
            [1] = "Apply Changes",
            [2] = {
                ["Players"] = {[player.Name] = player.Name},
                ["Max Health"] = 100,
                ["Health"] = 100,
                ["Speed Boost"] = 25
            }
        }
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    end,

    ["!resetspeed"] = function(player)
        if not _G.Config.commandsEnabled and player.Name ~= _G.Config.hostPlayer then return end
        local args = {
            [1] = "Apply Changes",
            [2] = {
                ["Players"] = {[player.Name] = player.Name},
                ["Speed Boost"] = 0
            }
        }
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    end,

    ["!item"] = function(player)
        if not _G.Config.commandsEnabled and player.Name ~= _G.Config.hostPlayer then return end
        local itemAleatorio = _G.itensAleatorios[math.random(#_G.itensAleatorios)]
        local args = {
            [1] = "Give Items",
            [2] = {
                ["Players"] = {[player.Name] = player.Name},
                ["Items"] = {[itemAleatorio] = itemAleatorio}
            }
        }
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
        SendMessage("🎁 " .. player.Name .. " recebeu um item aleatório: " .. itemAleatorio)
    end,

    ["!shield"] = function(player)
        if not _G.Config.commandsEnabled and player.Name ~= _G.Config.hostPlayer then return end
        local args = {
            [1] = "Apply Changes",
            [2] = {
                ["Players"] = {[player.Name] = player.Name},
                ["Star Shield"] = 100,
                ["Max Health"] = 100
            }
        }
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    end,

    ["!items"] = function()
        if not _G.Config.commandsEnabled and player.Name ~= _G.Config.hostPlayer then return end
        SendMessage("📦 Lista de Itens por Raridade:")
        for rarity, items in pairs(_G.Items) do
            SendMessage("- " .. rarity:upper() .. ": " .. table.concat(items, ", "))
        end
    end,

    ["!entities"] = function()
        if not _G.Config.commandsEnabled and player.Name ~= _G.Config.hostPlayer then return end
        SendMessage("👻 Lista de Entidades por Raridade:")
        for rarity, entities in pairs(_G.Entities) do
            SendMessage("- " .. rarity:upper() .. ": " .. table.concat(entities, ", "))
        end
    end,

    ["!comandos"] = function()
        if not _G.Config.commandsEnabled and player.Name ~= _G.Config.hostPlayer then return end
        SendMessage("📍 Comandos disponíveis:")
        SendMessage("- Gerais: !pxitem, !vida, !revive, !godmode, !speed, !resetspeed, !item, !shield")
        SendMessage("- Informações: !items, !entities, !comandos")
        SendMessage("- Host: !togglemod, !spawn [entidade], !randomentity, !kill [player], !debug, !cmds")
    end,

    ["!kill"] = function(player, args)
        if player.Name ~= _G.Config.hostPlayer then
            SendMessage("❌ Apenas o host pode usar este comando!")
            return
        end
        if _G.Config.voteInProgress then
            SendMessage("❌ Uma votação já está em andamento!")
            return
        end
        if not args[2] then
            SendMessage("❌ Use: !kill [nome/displayname/userid do jogador]")
            return
        end
        local targetIdentifier = args[2]
        local targetPlayer
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Name:lower() == targetIdentifier:lower() or 
               (plr.DisplayName and plr.DisplayName:lower() == targetIdentifier:lower()) or 
               tostring(plr.UserId) == targetIdentifier then
                targetPlayer = plr
                break
            end
        end
        if not targetPlayer then
            SendMessage("❌ Jogador não encontrado! Tente usar nome, display name ou ID")
            return
        end
        _G.Config.voteInProgress = true
        _G.Config.currentVotes = {yes = 0, no = 0}
        SendMessage("🎯 Votação iniciada para eliminar " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")")
        SendMessage("Digite Y para eliminar ou N para não eliminar")
        SendMessage("⏰ Votação termina em 19 segundos")
        local voteConnection = TextChatService.MessageReceived:Connect(function(voteMsg)
            if _G.Config.voteInProgress then
                local vote = voteMsg.Text:lower()
                if vote == "y" then
                    _G.Config.currentVotes.yes = _G.Config.currentVotes.yes + 1
                elseif vote == "n" then
                    _G.Config.currentVotes.no = _G.Config.currentVotes.no + 1
                end
            end
        end)
        wait(19)
        _G.Config.voteInProgress = false
        voteConnection:Disconnect()
        if _G.Config.currentVotes.yes > _G.Config.currentVotes.no then
            local args = {[1] = "KillPlayer", [2] = {["Players"] = {[targetPlayer.Name] = targetPlayer.Name}}}
            ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
            SendMessage("☠️ Votação concluída: " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ") foi eliminado!")
        else
            SendMessage("✨ Votação concluída: " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ") foi poupado!")
        end
    end,

    ["!spawn"] = function(player, args)
        if player.Name ~= _G.Config.hostPlayer then
            SendMessage("❌ Apenas o host pode usar este comando!")
            return
        end
        if not args[2] then
            SendMessage("❌ Use: !spawn [nome da entidade]")
            SendMessage("📍 Entidades disponíveis: " .. table.concat(_G.entidadesAleatorias, ", "))
            return
        end
        local entityName = args[2]:lower()
        local validEntity = false
        local actualEntityName
        for _, entity in ipairs(_G.entidadesAleatorias) do
            if entity:lower() == entityName then
                validEntity = true
                actualEntityName = entity
                break
            end
        end
        if not validEntity then
            SendMessage("❌ Entidade não encontrada! Use uma entidade válida da lista.")
            return
        end
        local spawnArgs = {[1] = actualEntityName, [2] = {}}
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(spawnArgs))
        SendMessage("👻 " .. actualEntityName .. " foi invocado na sala!")
    end,

    ["!randomentity"] = function(player)
        if player.Name ~= _G.Config.hostPlayer then
            SendMessage("❌ Apenas o host pode usar este comando!")
            return
        end
        local randomEntity = _G.entidadesAleatorias[math.random(#_G.entidadesAleatorias)]
        local spawnArgs = {[1] = randomEntity, [2] = {}}
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(spawnArgs))
        SendMessage("👻 " .. randomEntity .. " foi invocado aleatoriamente na sala!")
    end,

    ["!debug"] = function(player)
        if player.Name ~= _G.Config.hostPlayer then
            SendMessage("❌ Apenas o host pode usar este comando!")
            return
        end
        _G.Config.debugMode = not _G.Config.debugMode
        SendMessage("🔧 Modo Debug: " .. (_G.Config.debugMode and "Ativado" or "Desativado"))
    end,

    ["!togglemod"] = function(player)
        if player.Name ~= _G.Config.hostPlayer then
            SendMessage("❌ Apenas o host pode usar este comando!")
            return
        end
        toggleMod(not _G.Config.modEnabled)
    end,

    ["!cmds"] = function(player)
        if player.Name ~= _G.Config.hostPlayer then
            SendMessage("❌ Apenas o host pode usar este comando!")
            return
        end
        _G.Config.commandsEnabled = not _G.Config.commandsEnabled
        local status = _G.Config.commandsEnabled and "ativados" or "desativados"
        SendMessage("🔧 Comandos " .. status .. " para jogadores!")
        saveDebugLog("Commands status changed: " .. status)
    end
}

TextChatService.MessageReceived:Connect(function(message)
    local text = message.Text:lower()
    local player = message.TextSource
    local args = text:split(" ")
    local command = args[1]
    if Commands[command] then
        Commands[command](player, args)
    end
end)

spawn(function()
    while wait(1) do
        if _G.Config.systemActive and _G.Config.loopsAtivos then
            local tempoAtual = _G.Config.luzAtual == "🟢" and _G.Config.tempoTrocaLuzVerde or _G.Config.tempoTrocaLuzVermelha
            for i = tempoAtual, 1, -1 do
                if _G.Config.loopsAtivos then
                    TimerLabel.Text = string.format("%s Próximo: %ds", _G.Config.luzAtual, i)
                    if i == 10 then
                        SendMessage("⚠️ 10 segundos para mudança de luz!")
                    elseif i == 2 then
                        SendMessage("⚠️ 2 segundos para mudança de luz!")
                    end
                    wait(1)
                end
            end
            if _G.Config.loopsAtivos then
                alterarLuz(_G.Config.luzAtual == "🟢" and "🔴" or "🟢")
            end
        else
            TimerLabel.Text = "Sistema Pausado"
            wait(1)
        end
    end
end)

spawn(function()
    while wait(1) do
        monitorarSala()
    end
end)

spawn(function()
    while wait(math.random(_G.Config.itemDropInterval.min, _G.Config.itemDropInterval.max)) do
        if _G.Config.systemActive and _G.Config.loopsAtivos and _G.Config.itensLoopAtivo then
            darItensAleatorios()
        end
    end
end)

game.Players.PlayerAdded:Connect(function(player)
    if not _G.Config.hostPlayer then
        _G.Config.hostPlayer = player.Name
        SendMessage("👑 " .. player.Name .. " é o host do servidor!")
    end
end)

SendMessage("📍 Doors Six - By rhyan57 (Enhanced)")
SendMessage("📍 Use !comandos para ver todos os comandos disponíveis")
task.wait(1)
SendMessage("⚠️ Mod carregado! o host deve passar da porta 2 para ativar o mod.")
Notificar("Mod Carregado", "Passe da porta 2 para ativa-lo.", 10, Color3.new(1, 1, 0))
        
