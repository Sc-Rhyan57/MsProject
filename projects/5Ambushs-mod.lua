local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
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
    debug = true
}
wait(3)
warn("[Msproject] » Configurado para invocar " .. _G["msproject-ambushInf"].ambushs .. " Ambushs quando detectado")
msg(" Mod Carregado!")
wait(3)
msg("Made by  Rhyan57")

local MsdoorsNotify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc-Rhyan57/Notification-doorsAPI/refs/heads/main/Msdoors/MsdoorsApi.lua"))()
MsdoorsNotify("Entre no meu Discord", "https://dsc.gg/msdoors-gg", "", "rbxassetid://8248378219", Color3.new(114,137,218), 19)

local function invocarAmbush()
    local argumentos = {
        [1] = "Ambush",
        [2] = {}
    }
    game:GetService("ReplicatedStorage").RemotesFolder.AdminPanelRunCommand:FireServer(unpack(argumentos))
    
    if _G["msproject-ambushInf"].debug then
        print("[Msproject] » Ambush invocado!")
    end
end

local function processarAmbush()
    if not _G["msproject-ambushInf"].modAtivo then
        return
    end
    
    _G["msproject-ambushInf"].modAtivo = false
    
    for i = 1, _G["msproject-ambushInf"].ambushs do
        invocarAmbush()
        task.wait(_G["msproject-ambushInf"].cooldown)
    end
    
    task.wait(2)
    _G["msproject-ambushInf"].modAtivo = true
    
    if _G["msproject-ambushInf"].debug then
        print("Ciclo de invocação de Ambush concluído")
    end
end

local function verificarWorkspace(objeto)
    if objeto.Name == "AmbushMoving" then
        if _G["msproject-ambushInf"].debug then
            print("AmbushMoving detectado no Workspace")
        end
        processarAmbush()
    end
end

game.Workspace.ChildAdded:Connect(function(child)
    verificarWorkspace(child)
end)

for _, child in pairs(game.Workspace:GetChildren()) do
    verificarWorkspace(child)
end

if _G["msproject-ambushInf"].debug then
    print("==========[ 5 AMBUSHS INSPIRADO POR REGINALDOO ]==========")
    print("[Msproject] » Configurado para invocar " .. _G["msproject-ambushInf"].ambushs .. " Ambushs quando detectado")
end
