local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Giangplay/Script/main/Orion_Library_PE_V2.lua"))()
local MsdoorsNotify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc-Rhyan57/Notification-doorsAPI/refs/heads/main/Msdoors/MsdoorsApi.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Params = {
 RepoURL = "https://raw.githubusercontent.com/luau/SynSaveInstance/main/",
 SSI = "saveinstance"
}

_G.savingRooms = false
_G.removeLoot = false
_G.notifications = true

if not ReplicatedStorage:FindFirstChild("msproject-rooms") then
    local RoomFolder = Instance.new("Folder")
    RoomFolder.Name = "msproject-rooms"
    RoomFolder.Parent = ReplicatedStorage
end

local function ConsoleLog(msg)
    print("[ MSPROJECT : SAVE ROOMS(V1) ] " .. msg)
end

local function Notify(title, desc, color)
    OrionLib:MakeNotification({
        Name = title,
        Content = "<font color='"..color.."'>"..desc.."</font>",
        Image = "rbxassetid://4483345998",
        Time = 3
    })
end

local function NotifyMsdoors(title, desc)
    MsdoorsNotify(
        title, 
        desc, 
        "O sistema de salvamento foi pausado!", 
        "rbxassetid://6023426923", 
        Color3.new(1, 0, 0), 
        5
    )
end

local salasClonadas = {}

local function ClonarSala(roomNumber)
    local room = Workspace.CurrentRooms:FindFirstChild(tostring(roomNumber))
    if not room then return end

    if salasClonadas[roomNumber] or ReplicatedStorage["msproject-rooms"]:FindFirstChild(tostring(roomNumber)) then
        salasClonadas[roomNumber] = true
        return
    end

    local roomClone = room:Clone()
    roomClone.Name = tostring(roomNumber)
    roomClone.Parent = ReplicatedStorage["msproject-rooms"]
    salasClonadas[roomNumber] = true
  
    local roomName = room:GetAttribute("RawName") or "Desconhecido"

    ConsoleLog("SALA CLONADA [ NOME: " .. roomName .. " | NÚMERO: " .. roomNumber .. " ]")
    if _G.notifications then
        Notify("Sala Clonada!", "NOME: " .. roomName .. " | NÚMERO: " .. roomNumber, "#00FF34")
    end
end

local function MonitorarTrocaDeSala()
    ConsoleLog("MONITORANDO TROCA DE SALA...")

    local player = Players.LocalPlayer
    local lastRoom = player:GetAttribute("CurrentRoom")
    player:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
        if not _G.savingRooms then return end

        local currentRoom = player:GetAttribute("CurrentRoom")
        if not currentRoom or currentRoom == lastRoom then return end
        lastRoom = currentRoom
        if tonumber(currentRoom) == 100 then
            ConsoleLog("PORTA 100 DETECTADA! PARANDO O SALVAMENTO...")
            _G.savingRooms = false 

            NotifyMsdoors(
                "Porta 100 Alcancada!",
                "O sistema de salvamento foi desativado automaticamente."
            )

            return
        end
        ClonarSala(currentRoom)
        ClonarSala(currentRoom + 1)
    end)
end

ReplicatedStorage["msproject-rooms"].DescendantAdded:Connect(function(ins)
    if _G.removeLoot and (ins.Name == "GoldPile" or ins.Name == "Battery" or ins.Name == "Bandage") then
        ins:Destroy()
    end
end)

local Window = OrionLib:MakeWindow({Name = "SAVE ROOMS : MSPROJECT", HidePremium = false, SaveConfig = true, ConfigFolder = "Msproject"})

local Tab = Window:MakeTab({
    Name = "Save",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})
Tab:AddToggle({
    Name = "Ativar Salvamento de Salas",
    Default = false,
    Callback = function(value)
        if value and Players.LocalPlayer:GetAttribute("CurrentRoom") == 100 then
            ConsoleLog("TENTATIVA DE ATIVAR NA PORTA 100! O SALVAMENTO NÃO SERÁ INICIADO.")
            NotifyMsdoors("Erro!", "Você já está na porta 100. O sistema não será ativado.")
            return
        end

        _G.savingRooms = value
        if value then
            ConsoleLog("SALVAMENTO ATIVADO!")
            MonitorarTrocaDeSala()
            ClonarSala(0)
            ClonarSala(1)
        else
            ConsoleLog("SALVAMENTO DESATIVADO!")
        end
    end
})

Tab:AddToggle({
    Name = "Remover Loots",
    Default = false,
    Callback = function(value)
        _G.removeLoot = value
    end
})

Tab:AddToggle({
    Name = "Notificações",
    Default = true,
    Callback = function(value)
        _G.notifications = value
    end
})
Tab:AddLabel("")
Tab:AddButton({
	Name = "Salvar Mapa no dispositivo atual[PORTA 100]",
	Callback = function()
local currentRoom = LocalPlayer:GetAttribute("CurrentRoom")
if tonumber(currentRoom) == 100 then
    local function moveToFolder(parent, folderName)
        if not parent then return end

        local folder = Instance.new("Folder")
        folder.Name = "msproject:" .. folderName
        folder.Parent = ReplicatedStorage

        for _, child in pairs(parent:GetChildren()) do
            child.Parent = folder
        end
    end
    moveToFolder(LocalPlayer:FindFirstChild("PlayerGui"), "PlayerGui")
    moveToFolder(LocalPlayer:FindFirstChild("PlayerScripts"), "PlayerScripts")

    print("[ MSPROJECT: SALVANDO JOGO NO DISPOSITIVO ATUAL...")
    NotifyMsdoors("Salvando...","O jogo está sendo salvo no dispositivo atual[ PODE LAGAR! ].")
    task.wait(3)
    local synsaveinstance = loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)()
    local Options = {}
    synsaveinstance(Options)
    else
    print("[ MSPROJECT: Você precisa estar na porta 100 para salvas as salas em seu dispositivo! ]")
    NotifyMsdoors("ATENÇÃO","Você precisa estar na porta 100 para salvas as salas em seu dispositivo!")
            end
  	end    
})

OrionLib:Init()
