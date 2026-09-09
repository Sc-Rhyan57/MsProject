local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Giangplay/Script/main/Orion_Library_PE_V2.lua"))()
local MsdoorsNotify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc-Rhyan57/Notification-doorsAPI/refs/heads/main/Msdoors/MsdoorsApi.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LatestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")

_G.savingRooms = false
_G.removeLoot = false
_G.notifications = true
_G.deleteRooms = false
_G.saveEntities = false

local entityMap = {
    Honcho = true,
    RushMoving = true,
    CustomEntity = true,
    AmbushMoving = true,
    GlitchRush = true,
    GlitchAmbush = true,
    Snare = true,
    FigureRig = true,
    HonchoRig = true,
    A60 = true,
    A120 = true,
    GiggleCeiling = true,
    GrumbleRig = true,
    BackdoorRush = true,
    FigureRagdoll = true,
    JeffTheKiller = true,
    DronesStampede = true,
    Scribbles = true,
    BashMoving = true,
    Creak = true,
    NoiseModel = true,
    MonumentEntity = true,
    MandrakeLive = true,
    Groundskeeper = true,
    LiveEntityBramble = true,
    Eyes = true,
    MouseHole = true,
    FrozenAmbush = true
}

local entityConnections = {}

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

local function SalvarEntidadesECodigos(state)
    if state then
        local entFolder = ReplicatedStorage:FindFirstChild("Msproject-entidades")
        if not entFolder then
            entFolder = Instance.new("Folder")
            entFolder.Name = "Msproject-entidades"
            entFolder.Parent = ReplicatedStorage
        end
        
        local codesFolder = entFolder:FindFirstChild("Codes")
        if not codesFolder then
            codesFolder = Instance.new("Folder")
            codesFolder.Name = "Codes"
            codesFolder.Parent = entFolder
        end
        
        local miniFolder = entFolder:FindFirstChild("Minigames")
        if not miniFolder then
            miniFolder = Instance.new("Folder")
            miniFolder.Name = "Minigames"
            miniFolder.Parent = entFolder
        end
        
        local modFolder = entFolder:FindFirstChild("Modules")
        if not modFolder then
            modFolder = Instance.new("Folder")
            modFolder.Name = "Modules"
            modFolder.Parent = entFolder
        end

        for _, child in pairs(Workspace:GetChildren()) do
            if entityMap[child.Name] then
                local clone = child:Clone()
                clone.Parent = entFolder
            end
        end
        
        table.insert(entityConnections, Workspace.ChildAdded:Connect(function(child)
            if entityMap[child.Name] then
                local clone = child:Clone()
                clone.Parent = entFolder
            end
        end))
        
        local floorRep = ReplicatedStorage:FindFirstChild("FloorReplicated")
        if floorRep then
            local clientRemote = floorRep:FindFirstChild("ClientRemote")
            if clientRemote then
                for _, child in pairs(clientRemote:GetChildren()) do
                    local clone = child:Clone()
                    clone.Parent = codesFolder
                end
                table.insert(entityConnections, clientRemote.ChildAdded:Connect(function(child)
                    local clone = child:Clone()
                    clone.Parent = codesFolder
                end))
            end
            
            local minigames = floorRep:FindFirstChild("Minigames")
            if minigames then
                for _, child in pairs(minigames:GetChildren()) do
                    local clone = child:Clone()
                    clone.Parent = miniFolder
                end
                table.insert(entityConnections, minigames.ChildAdded:Connect(function(child)
                    local clone = child:Clone()
                    clone.Parent = miniFolder
                end))
            end
        end
        
        local pGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            local modulesPath = pGui:FindFirstChild("MainUI")
            if modulesPath then modulesPath = modulesPath:FindFirstChild("Initiator") end
            if modulesPath then modulesPath = modulesPath:FindFirstChild("Main_Game") end
            if modulesPath then modulesPath = modulesPath:FindFirstChild("RemoteListener") end
            if modulesPath then modulesPath = modulesPath:FindFirstChild("Modules") end
            
            if modulesPath then
                for _, child in pairs(modulesPath:GetChildren()) do
                    local clone = child:Clone()
                    clone.Parent = modFolder
                end
                table.insert(entityConnections, modulesPath.ChildAdded:Connect(function(child)
                    local clone = child:Clone()
                    clone.Parent = modFolder
                end))
            end
        end
    else
        for _, conn in pairs(entityConnections) do
            conn:Disconnect()
        end
        entityConnections = {}
    end
end

local function MonitorarTrocaDeSala()
    ConsoleLog("MONITORANDO TROCA DE SALA...")

    local lastRoom = LatestRoom.Value
    local maxClonedRoom = 0

    LatestRoom:GetPropertyChangedSignal("Value"):Connect(function()
        if not _G.savingRooms then return end

        local internalRoom = LatestRoom.Value
        local currentRoom = internalRoom + 1
        
        if not currentRoom or internalRoom == lastRoom then return end
        lastRoom = internalRoom
        
        if currentRoom == 1300 then
            ConsoleLog("PORTA 1300 DETECTADA! PARANDO O SALVAMENTO...")
            _G.savingRooms = false 

            NotifyMsdoors(
                "Porta 1300 Alcancada!",
                "O sistema de salvamento foi desativado automaticamente."
            )

            return
        end

        for i = maxClonedRoom + 1, currentRoom do
            ClonarSala(i)
        end
        maxClonedRoom = currentRoom

        if _G.deleteRooms then
            for _, room in pairs(Workspace.CurrentRooms:GetChildren()) do
                local num = tonumber(room.Name)
                if num and num < currentRoom then
                    room:Destroy()
                end
            end
        end
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
        if value and (LatestRoom.Value + 1) == 1300 then
            ConsoleLog("TENTATIVA DE ATIVAR NA PORTA 1300! O SALVAMENTO NÃO SERÁ INICIADO.")
            NotifyMsdoors("Erro!", "Você já está na porta 1300. O sistema não será ativado.")
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
    Name = "Deletar salas no progresso",
    Default = false,
    Callback = function(value)
        _G.deleteRooms = value
    end
})

Tab:AddToggle({
    Name = "Salvar Entidades e seus códigos",
    Default = false,
    Callback = function(value)
        _G.saveEntities = value
        SalvarEntidadesECodigos(value)
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
    Name = "Salvar Mapa no dispositivo atual[PORTA 1300]",
    Callback = function(value)
        if value and (LatestRoom.Value + 1) == 1300 then
            ConsoleLog("TENTATIVA DE ATIVAR NA PORTA 1300! O SALVAMENTO NÃO SERÁ INICIADO.")
            Notify("Son", "Você já está na porta 1300. O sistema não será ativado.", "#00FF34")
            
            else
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc-Rhyan57/MsProject/refs/heads/main/projects/SaveAll.lua"))()
    end
      end    
})

OrionLib:Init()
