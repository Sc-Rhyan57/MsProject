local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function msg(message)
    local mainGame = require(LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game)
    mainGame.caption(message, true)
end

msg("Red Light Green Light iniciado!")
task.wait(0.6)
msg("Carregando mod...")

_G["msproject-ambushInf"] = {
    ambushs = 3,
    modAtivo = true,
    cooldown = 1,
    debug = true,
    jaInvocado = false
}

task.wait(3)
warn("[Msproject] » Configurado para invocar " .. _G["msproject-ambushInf"].ambushs .. " Ambushs uma única vez")
msg(" Mod Carregado!")
task.wait(3)
msg("Made by  Rhyan57")

local function invocarAmbush()
    local argumentos = {
        [1] = "Ambush",
        [2] = {}
    }
    ReplicatedStorage.RemotesFolder.AdminPanelRunCommand:FireServer(unpack(argumentos))

    if _G["msproject-ambushInf"].debug then
        print("[Msproject] » Ambush invocado!")
    end
end

local function processarAmbush()
    if _G["msproject-ambushInf"].jaInvocado then
        return  -- Se já invocou uma vez, sai da função
    end

    _G["msproject-ambushInf"].jaInvocado = true  -- Marca como já invocado

    for i = 1, _G["msproject-ambushInf"].ambushs do
        invocarAmbush()
        task.wait(_G["msproject-ambushInf"].cooldown)
    end

    if _G["msproject-ambushInf"].debug then
        print("Ciclo de invocação de Ambush concluído, não invocará mais.")
    end
end

-- Detecção de AmbushMoving para iniciar a invocação apenas uma vez
game.Workspace.ChildAdded:Connect(function(child)
    if child.Name == "AmbushMoving" and not _G["msproject-ambushInf"].jaInvocado then
        processarAmbush()
    end
end)

for _, child in pairs(game.Workspace:GetChildren()) do
    if child.Name == "AmbushMoving" and not _G["msproject-ambushInf"].jaInvocado then
        processarAmbush()
    end
end

if _G["msproject-ambushInf"].debug then
    print("==========[ AMBUSHS INSPIRADO POR REGINALDOO ]==========")
    print("[Msproject] » Invocará " .. _G["msproject-ambushInf"].ambushs .. " Ambushs uma única vez")
end
