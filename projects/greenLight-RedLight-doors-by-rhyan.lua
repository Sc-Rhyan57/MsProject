-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

-- Load Libraries
local MsdoorsNotify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc-Rhyan57/Notification-doorsAPI/refs/heads/main/Msdoors/MsdoorsApi.lua"))()
local OrionLib = loadstring(game:HttpGetAsync('https://raw.githubusercontent.com/Sc-Rhyan57/Msdoors/refs/heads/main/Library/OrionLibrary_msdoors.lua'))()

-- Prevent Multiple Loads
if _G.DoorsSix then
    MsdoorsNotify("Sistema", "O mod já está carregado!", "", "rbxassetid://6023426923", Color3.new(1, 0, 0), 5)
    return
end
_G.DoorsSixLoaded = true

-- Global Variables
_G.luzAtual = "🟢"
_G.tempoTrocaLuzVerde = math.random(50, 70)
_G.tempoTrocaLuzVermelha = math.random(25, 35)
_G.salaAtual = 0
_G.jogadoresMortos = {}
_G.loopsAtivos = true
_G.itensLoopAtivo = true
_G.pausarPorSala = false
_G.notificacaoSalaEspecial = false
_G.systemActive = false

-- Arrays
_G.itensAleatorios = {
    "TipJar", "Crucifix", "RiftSmoothie", "Flashlight", "StarVial",
    "Vitamins", "Bulklight", "Smoothie", "Lighter", "Shears",
    "BatteryPack", "Candle", "Shakelight", "BandagePack", "SkeletonKey",
    "AlarmClock", "StarBottle", "Glowsticks", "HolyGrenade", "RiftCandle",
    "Straplight", "LaserPointer", "GweenSoda", "Lockpick", "Cheese", "Bread"
}

_G.entidadesAleatorias = {
    "A90Player", "Jeff The Killer", "A-120", "A-60", "Lookman",
    "Blitz", "Gloombats", "Giggle", "Dread", "Jack", "Eyes",
    "Figure", "Ambush", "Rush"
}

-- Create Timer UI
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

-- Functions
local function SendMessage(message)
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = TextChatService.TextChannels.RBXGeneral
        channel:SendAsync(message)
    else
        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
    end
end

local function Notificar(titulo, descricao, tempo, cor)
    MsdoorsNotify(
        titulo,
        descricao,
        "",
        "rbxassetid://6023426923",
        cor or Color3.new(0, 1, 0),
        tempo or 5
    )
end

local function reviverTodos()
    local args = {
        [1] = "RevivePlayer",
        [2] = {["Players"] = {}}
    }
    for _, player in ipairs(Players:GetPlayers()) do
        args[2]["Players"][player.Name] = player.Name
    end
    
    -- Delete all entities
    local deleteArgs = {
        [1] = "DELETE ALL",
        [2] = {}
    }
    ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(deleteArgs))
    ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    
    wait(2)
    Notificar("Reviver", "Todos os jogadores foram revividos!", 10)
    SendMessage("✨ Todos os jogadores foram revividos e as entidades foram removidas!")
    _G.luzAtual = "🟢"
    alterarLuz("🟢")
end

local function darItensAleatorios()
    for _, player in ipairs(Players:GetPlayers()) do
        local itemAleatorio = _G.itensAleatorios[math.random(#_G.itensAleatorios)]
        local args = {
            [1] = "Give Items",
            [2] = {["Players"] = {[player.Name] = player.Name}, ["Items"] = {[itemAleatorio] = itemAleatorio}}
        }
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    end
    Notificar("Itens", "Você recebeu um item aleatório!", 5)
    SendMessage("🎁 Itens aleatórios distribuídos!")
end

local function verificarMortos()
    local todosJogadores = Players:GetPlayers()
    local jogadoresMortos = 0
    
    for _, player in ipairs(todosJogadores) do
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health <= 0 then
            jogadoresMortos = jogadoresMortos + 1
        end
    end
    
    if jogadoresMortos == #todosJogadores then
        reviverTodos()
    end
end

local function alterarLuz(cor)
    _G.luzAtual = cor
    
    local args = {
        [1] = "LightRoom",
        [2] = {["Light Color"] = cor == "🟢" and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)}
    }
    ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    
    if cor == "🟢" then
        SendMessage("Luz verde - Ande")
        Notificar("Luz Verde", "Movimento permitido!", 5)
    else
        SendMessage("🔴 Luz Vermelha - PARE IMEDIATAMENTE!")
        Notificar("Luz Vermelha", "PARE DE SE MOVER!", 5)
        
        -- Check player movement
        spawn(function()
            while _G.loopsAtivos and _G.luzAtual == "🔴" do
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Character and 
                       player.Character:FindFirstChild("Humanoid") and 
                       player.Character.Humanoid.Health > 0 and 
                       player.Character.Humanoid.MoveDirection.Magnitude > 0 then
                        
                        local entidade = _G.entidadesAleatorias[math.random(#_G.entidadesAleatorias)]
                        local morteAleatoria = math.random(1, 2) == 1 and "KillPlayer" or "ExplodePlayer"
                        
                        local args = {
                            [1] = morteAleatoria,
                            [2] = {["Players"] = {[player.Name] = player.Name}}
                        }
                        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
                        
                        local entidadeArgs = {
                            [1] = entidade,
                            [2] = {["Players"] = {[player.Name] = player.Name}}
                        }
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

-- Core game loop
spawn(function()
    while wait(1) do
        if _G.systemActive and _G.loopsAtivos then
            local tempoAtual = _G.luzAtual == "🟢" and _G.tempoTrocaLuzVerde or _G.tempoTrocaLuzVermelha
            
            for i = tempoAtual, 1, -1 do
                if _G.loopsAtivos then
                    TimerLabel.Text = string.format("%s Próximo: %ds", _G.luzAtual, i)
                    
                    if i == 10 then
                        SendMessage("⚠️ 10 segundos para mudança de luz!")
                    elseif i == 2 then
                        SendMessage("⚠️ 2 segundos para mudança de luz!")
                    end
                    wait(1)
                end
            end
            
            if _G.loopsAtivos then
                alterarLuz(_G.luzAtual == "🟢" and "🔴" or "🟢")
            end
        else
            TimerLabel.Text = "Sistema Pausado"
            wait(1)
        end
    end
end)

-- Room monitor
local function monitorarSala()
    local player = Players.LocalPlayer
    local currentRoom = player:GetAttribute("CurrentRoom")
    
    if currentRoom then
        _G.salaAtual = currentRoom
        local room = workspace.CurrentRooms:FindFirstChild(tostring(currentRoom))
        
        if room and room:GetAttribute("RawName") then
            local roomName = room:GetAttribute("RawName")
            if roomName:find("SeekIntro") or roomName:find("Seek") or roomName:find("Halt") then
                if not _G.notificacaoSalaEspecial then
                    _G.pausarPorSala = true
                    _G.loopsAtivos = false
                    _G.notificacaoSalaEspecial = true
                    Notificar("Sala Especial", "Sistema pausado temporariamente", 5, Color3.new(1, 0, 0))
                    SendMessage("⚠️ Sistema pausado - Sala especial detectada!")
                end
            else
                if _G.pausarPorSala then
                    _G.pausarPorSala = false
                    _G.loopsAtivos = true
                    _G.notificacaoSalaEspecial = false
                    Notificar("Sistema Retomado", "Continuando operação normal", 5)
                    SendMessage("✅ Sistema retomado - Você saiu da sala especial!")
                end
            end
        end
        
        -- Check for Door 2 activation
        if currentRoom >= 2 and not _G.systemActive then
            _G.systemActive = true
            SendMessage("✅ Mod ativado - Passando da porta 2!")
            SendMessage("📍 Quando estiver vermelho pare quando estiver verde ande.")
            Notificar("Sistema Ativo", "Quando estiver vermelho PARE quando estiver VERDE ande!", 5)
        end

        if currentRoom == 101 then
            local allPlayersAlive = true
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health <= 0 then
                    allPlayersAlive = false
                    break
                end
            end
            
            if allPlayersAlive then
                wait(5)
                SendMessage("⚠️ Você alcançou a porta 101! :P")
            end
        end
    end
end

-- Room monitor loop
spawn(function()
    while wait(1) do
        monitorarSala()
    end
end)

-- Random items loop
spawn(function()
    while wait(math.random(60, 120)) do
        if _G.systemActive and _G.loopsAtivos and _G.itensLoopAtivo then
            darItensAleatorios()
        end
    end
end)
-- Vida Comando
TextChatService.MessageReceived:Connect(function(message)
    if message.Text == "!godmode" then
        local player = message.TextSource
        local args = {
            [1] = "Apply Changes",
            [2] = {
                ["Players"] = {[player.Name] = player.Name},
                ["Max Health"] = 100,
                ["Star Shield"] = 0,
                ["Health"] = 100,
                ["Speed Boost"] = 15,
                ["God Mode"] = true
            }
        }

        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
        SendMessage("🛡️ " .. player.Name .. " usou o comando de godmode!")
    end
end)
-- Vida Comando
TextChatService.MessageReceived:Connect(function(message)
    if message.Text == "!vida" then
        local player = message.TextSource
        local args = {
            [1] = "Apply Changes",
            [2] = {
                ["Players"] = {[player.Name] = player.Name},
                ["Max Health"] = 100,
                ["Star Shield"] = 0,
                ["Health"] = 100,
                ["Speed Boost"] = 15,
                ["God Mode"] = false
            }
        }

        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
        SendMessage("♥️ " .. player.Name .. " usou o comando de vida!")
    end
end)

-- Revive command
TextChatService.MessageReceived:Connect(function(message)
    if message.Text == "!revive" then
        local player = message.TextSource
        local args = {
            [1] = "RevivePlayer",
            [2] = {["Players"] = {[player.Name] = player.Name}}
        }
        ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
        SendMessage("🔄 " .. player.Name .. " usou o comando de reviver!")
    end
end)

-- Initial messages
SendMessage("📍 Doors Six - By rhyan57")
SendMessage("CMDS: !vida, !revive, !godmode")
SendMessage("⚠️ Mod carregado! Será ativo na porta 2.")
Notificar("Mod Carregado", "O mod será ativado na porta 2.", 10, Color3.new(1, 1, 0))
