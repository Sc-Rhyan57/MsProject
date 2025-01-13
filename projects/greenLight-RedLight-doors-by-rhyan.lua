-- Carregar API de Notificações e Orion Library
local MsdoorsNotify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc-Rhyan57/Notification-doorsAPI/refs/heads/main/Msdoors/MsdoorsApi.lua"))()
local OrionLib = loadstring(game:HttpGetAsync('https://raw.githubusercontent.com/Sc-Rhyan57/Msdoors/refs/heads/main/Library/OrionLibrary_msdoors.lua'))()

-- Variáveis Globais
_G.ReplicatedStorage = game:GetService("ReplicatedStorage")
_G.Players = game:GetService("Players")
_G.TextChatService = game:GetService("TextChatService")
_G.luzAtual = "🟢"
_G.tempoTrocaLuzVerde = math.random(25, 35) -- Aumentado o tempo para "cor segura"
_G.tempoTrocaLuzVermelha = math.random(50, 70) -- Aumentado o tempo para luz vermelha
_G.salaAtual = 0
_G.jogadoresMortos = {}
_G.loopsAtivos = true
_G.itensLoopAtivo = true
_G.pausarPorSala = false -- Controla a pausa do sistema
_G.notificacaoSalaEspecial = false -- Para evitar notificações repetitivas
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

-- Funções de notificação e mensagens
function Notificar(titulo, descricao, tempo, cor)
    MsdoorsNotify(
        titulo,
        descricao,
        "",
        "rbxassetid://6023426923",
        cor or Color3.new(0, 1, 0),
        tempo or 5
    )
end

function SendChatMessage(message)
    if _G.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local textChannel = _G.TextChatService.TextChannels.RBXGeneral
        textChannel:SendAsync(message)
    else
        _G.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
    end
end

-- Mensagem inicial ao carregar o script
SendChatMessage("⚠️ Mod carregado! Será ativo na porta 2.")
Notificar(
    "Mod Carregado!",
    "O sistema será ativado na porta 2.",
    10,
    Color3.new(1, 1, 0)
)

-- Reviver todos os jogadores e remover entidades
function reviverTodos()
    local args = {
        [1] = "RevivePlayer",
        [2] = {["Players"] = {}}
    }
    for _, player in ipairs(_G.Players:GetPlayers()) do
        args[2]["Players"][player.Name] = player.Name
    end

    -- Deletar todas as entidades
    local deleteArgs = {
        [1] = "DELETE ALL",
        [2] = {}
    }
    _G.ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(deleteArgs))

    _G.ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    Notificar("Reviver Jogadores", "Todos os jogadores foram revividos e entidades removidas!", 10, Color3.new(0, 1, 0))
    SendChatMessage("⚠️ Todos os jogadores foram revividos e as entidades foram removidas!")
end

-- Sistema de dar itens aleatórios
function darItensAleatorios()
    for _, player in ipairs(_G.Players:GetPlayers()) do
        local itemAleatorio = _G.itensAleatorios[math.random(#_G.itensAleatorios)]
        local args = {
            [1] = "Give Items",
            [2] = {["Players"] = {[player.Name] = player.Name}, ["Items"] = {[itemAleatorio] = itemAleatorio}}
        }
        _G.ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))
    end
    Notificar("Itens Recebidos", "Você recebeu um item aleatório!", 5, Color3.new(0, 1, 0))
end

-- Verificar se todos estão mortos
function verificarMortos()
    _G.jogadoresMortos = {}
    _G.jogadoresVivos = {}
    for _, player in ipairs(_G.Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            table.insert(_G.jogadoresVivos, player)
        else
            table.insert(_G.jogadoresMortos, player)
        end
    end
    if #_G.jogadoresVivos == 0 and #_G.jogadoresMortos > 0 then
        reviverTodos()
    end
end

-- Alterar a luz da sala
function alterarLuz(cor)
    _G.luzAtual = cor

    local args = {
        [1] = "LightRoom",
        [2] = {["Light Color"] = cor == "🟢" and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)}
    }
    _G.ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))

    if cor == "🟢" then
        SendChatMessage("⚠️ Permissão para se mover!")
        Notificar("Cor Segura", "Você está seguro! Continue se movendo.", 5, Color3.new(0, 1, 0))
    elseif cor == "🔴" then
        SendChatMessage("⚠️ Cor de perigo! Pare agora!")
        Notificar("Cor de Perigo", "Parado! Quem se mover será eliminado.", 5, Color3.new(1, 0, 0))

        -- Verificar movimentos
        spawn(function()
            while _G.loopsAtivos and _G.luzAtual == "🔴" do
                for _, player in ipairs(_G.Players:GetPlayers()) do
                    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 and humanoid.MoveDirection.Magnitude > 0 then
                        local entidade = _G.entidadesAleatorias[math.random(#_G.entidadesAleatorias)]
                        local morteAleatoria = math.random(1, 2) == 1 and "KillPlayer" or "ExplodePlayer"
                        local args = {
                            [1] = morteAleatoria,
                            [2] = {["Players"] = {[player.Name] = player.Name}}
                        }
                        _G.ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(args))

                        local entidadeArgs = {
                            [1] = entidade,
                            [2] = {["Players"] = {[player.Name] = player.Name}}
                        }
                        _G.ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(entidadeArgs))

                        SendChatMessage(player.Name .. " foi eliminado e invocou " .. entidade .. "!")
                    end
                end
                verificarMortos()
                wait(1)
            end
        end)
    end
end

-- Pausar ou retomar sistema com base no nome da sala
function verificarNomeSalaAtual()
    local salaAtual = game.Workspace.CurrentRooms:FindFirstChild(game.Players.LocalPlayer:GetAttribute("CurrentRoom"))
    if salaAtual and salaAtual:GetAttribute("RawName") then
        local nomeSala = salaAtual:GetAttribute("RawName")
        if nomeSala:find("SeekIntro") or nomeSala:find("Seek") or nomeSala:find("Halt") then
            if not _G.notificacaoSalaEspecial then
                _G.pausarPorSala = true
                _G.loopsAtivos = false
                _G.itensLoopAtivo = false
                _G.notificacaoSalaEspecial = true
                Notificar("Sistema Pausado", "Sistema pausado devido à sala especial: " .. nomeSala, 10, Color3.new(1, 0, 0))
                SendChatMessage("⚠️ Sistema pausado devido à sala especial: " .. nomeSala)
            end
        else
            if _G.pausarPorSala then
                _G.pausarPorSala = false
                _G.loopsAtivos = true
                _G.itensLoopAtivo = true
                _G.notificacaoSalaEspecial = false
                Notificar("Sistema Retomado", "Sistema retomado. Você saiu de uma sala especial.", 10, Color3.new(0, 1, 0))
                SendChatMessage("✅ Sistema retomado. Você saiu de uma sala especial.")
            end
        end
    end
end

-- Loop para monitorar o nome das salas e controlar o sistema
spawn(function()
    while true do
        verificarNomeSalaAtual()
        wait(1)
    end
end)

-- Loop para troca de luz com notificações específicas
spawn(function()
    while _G.loopsAtivos do
        local tempoRestante = _G.luzAtual == "🟢" and _G.tempoTrocaLuzVerde or _G.tempoTrocaLuzVermelha
        for i = tempoRestante, 1, -1 do
            if i == 10 then
                if _G.luzAtual == "🟢" then
                    SendChatMessage("⚠️ Faltam 10 segundos para permissão para se mover!")
                else
                    SendChatMessage("⚠️ Faltam 10 segundos para cor de perigo!")
                end
            elseif i == 3 then
                if _G.luzAtual == "🟢" then
                    SendChatMessage("⚠️ Permissão para se mover em 3 segundos!")
                else
                    SendChatMessage("⚠️ Alerta de perigo em 3 segundos!")
                end
            end
            wait(1)
        end
        alterarLuz(_G.luzAtual == "🟢" and "🔴" or "🟢")
    end
end)

-- Loop para itens aleatórios
spawn(function()
    while true do
        if _G.loopsAtivos 
and _G.itensLoopAtivo then
            wait(math.random(60, 120)) -- Dá itens a cada 1 a 2 minutos
            darItensAleatorios()
        else
            wait(1) -- Pausa para não sobrecarregar
        end
    end
end)
