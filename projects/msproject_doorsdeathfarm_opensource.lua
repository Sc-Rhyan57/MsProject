local player = game.Players.LocalPlayer
if player and player.PlayerGui:FindFirstChild("LoadingUI") and player.PlayerGui.LoadingUI.Enabled then
    repeat task.wait() until not player.PlayerGui:FindFirstChild("LoadingUI") and true or not player.PlayerGui.LoadingUI.Enabled
end
local MsdoorsNotify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc-Rhyan57/Notification-doorsAPI/refs/heads/main/Msdoors/MsdoorsApi.lua"))()

MsdoorsNotify(
    "Started!", 
    "Waiting...(DON'T TOUCH ANYTHING!)", 
    "", 
    "rbxassetid://6023426923", 
    Color3.new(0, 1, 0), 
    5
)

task.wait(0.5)

local args = {
    [1] = {},
    [2] = false
}
game:GetService("ReplicatedStorage").RemotesFolder.PreRunShop:FireServer(unpack(args))
local skipButton = workspace.CurrentRooms["0"].StarterElevator.Model.Model.SkipButton.SkipPrompt
if skipButton then
    fireproximityprompt(skipButton)
end

task.wait(10) --[[ Rhyan57: Se você remover este Task.wait é 100% de chance do sistema quebrar ]]--
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local WAYPOINT_SPACING = 2
local NODE_TRANSPARENCY = 0.3
local BEAM_TRANSPARENCY = 0.2
local PATH_COLOR = Color3.fromRGB(0, 255, 0)
local PATH_STUCK_THRESHOLD = 3
local DIRECT_MOVE_DISTANCE = 15
local INTERACTION_DISTANCE = 6
local DOOR_INTERACTION_DISTANCE = 10
local NODE_SIZE = 0.7
local MOVE_SPEED = 25 --[[ Rhyan57: Não se preocupe! o script usa Speed Byppas então você pode definir uma velocidade entre 1 a 100(ou mais) ]]--
local PATH_TIMEOUT = 8
local TELEPORT_RETRY_DELAY = 0.05 --[[ Rhyan57: Se VOCÊ POR ISSO MENOS QUE 0.05 O ROBLOX COM CERTEZA VAI CRACHAR SE VOCÊ TIVER UM DISPOSITIVO BATATA :content: ]]--

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Collision

local function SetupCollision()
    Collision = Character:FindFirstChild("Collision")
    if not Collision then
        for _, part in pairs(Character:GetChildren()) do
            if part:IsA("BasePart") and part.Name:lower():find("collision") then
                Collision = part
                break
            end
        end
    end
    
    if not Collision then
        Collision = RootPart
    end
    
    local CollisionClone = Collision:Clone()
    CollisionClone.CanCollide = false
    CollisionClone.Massless = true
    CollisionClone.CanQuery = false
    CollisionClone.Name = "CollisionClone"
    
    if CollisionClone:FindFirstChild("CollisionCrouch") then
        CollisionClone.CollisionCrouch:Destroy()
    end
    
    CollisionClone.Parent = Character
    
    task.spawn(function()
        while true do
            if RootPart.Anchored then
                CollisionClone.Massless = true
                repeat task.wait() until not RootPart.Anchored
                task.wait(0.15)
            else
                CollisionClone.Massless = not CollisionClone.Massless
            end
            task.wait(0.24)
        end
    end)
end

SetupCollision()

LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
    Character = NewCharacter
    RootPart = Character:WaitForChild("HumanoidRootPart")
    SetupCollision()
end)

local NodeFolder = Instance.new("Folder")
NodeFolder.Name = "PathfindingNodes"
NodeFolder.Parent = workspace

local BeamFolder = Instance.new("Folder")
BeamFolder.Name = "PathfindingBeams"
BeamFolder.Parent = workspace

local initialPosition = HumanoidRootPart.Position

local function DeleteObjects()
    local objectsToDelete = {
        workspace.CurrentRooms["0"].Parts.FrontDesk,
        workspace.CurrentRooms["0"].Assets.Luggage_Cart_Crouch,
        workspace.CurrentRooms["0"].Parts.Desk_LampStart,
        workspace.CurrentRooms["0"].Parts:GetChildren()[64],
        workspace.CurrentRooms["0"].Assets:GetChildren()[16],
        workspace.CurrentRooms["0"].Assets.Rug,
        workspace.CurrentRooms["0"].Assets.Desk_Bell,
        workspace.CurrentRooms["0"].RiftSpawn,
        workspace.CurrentRooms["0"].Parts.PlayerCollision,
        game:GetService("ReplicatedStorage").ClientModules.GuidingRespawn,
        game:GetService("ReplicatedStorage").ClientModules.EntityModules.Void,
        game:GetService("ReplicatedStorage").RemotesFolder.CamShake
    }
    
    for _, object in ipairs(objectsToDelete) do
        if object then
            pcall(function() object:Destroy() end)
        end
    end
end

local function CreateVisualNode(position)
    local node = Instance.new("Part")
    node.Shape = Enum.PartType.Ball
    node.Size = Vector3.new(NODE_SIZE, NODE_SIZE, NODE_SIZE)
    node.Position = position
    node.Anchored = true
    node.CanCollide = false
    node.Material = Enum.Material.Neon
    node.Color = PATH_COLOR
    node.Transparency = NODE_TRANSPARENCY
    node.Parent = NodeFolder
    
    return node
end

local function CreateBeam(startNode, endNode)
    local attachment1 = Instance.new("Attachment")
    attachment1.Parent = startNode
    
    local attachment2 = Instance.new("Attachment")
    attachment2.Parent = endNode
    
    local beam = Instance.new("Beam")
    beam.Attachment0 = attachment1
    beam.Attachment1 = attachment2
    beam.Width0 = 0.3
    beam.Width1 = 0.3
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Color = ColorSequence.new(PATH_COLOR)
    beam.Transparency = NumberSequence.new(BEAM_TRANSPARENCY)
    beam.Parent = BeamFolder
    
    return beam
end

local function ClearPathVisuals()
    NodeFolder:ClearAllChildren()
    BeamFolder:ClearAllChildren()
end

local function CalculatePath(startPosition, targetPosition, isForDoor)
    local distance = (startPosition - targetPosition).Magnitude
    
    if distance < DIRECT_MOVE_DISTANCE and not isForDoor then
        return {{Position = startPosition}, {Position = targetPosition}}
    end
    
    local path = PathfindingService:CreatePath({
        AgentCanJump = true,
        AgentHeight = 5,
        AgentRadius = 2,
        AgentCanClimb = false,
        WaypointSpacing = WAYPOINT_SPACING
    })
    
    local success, errorMessage = pcall(function()
        path:ComputeAsync(startPosition, targetPosition)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    end
    
    path = PathfindingService:CreatePath({
        AgentCanJump = true,
        AgentHeight = 5,
        AgentRadius = 0.5,
        AgentCanClimb = false,
        WaypointSpacing = WAYPOINT_SPACING
    })
    
    success, errorMessage = pcall(function()
        path:ComputeAsync(startPosition, targetPosition)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    end
    
    return {{Position = startPosition}, {Position = targetPosition}}
end

local function VisualizePath(waypoints)
    ClearPathVisuals()
    
    if not waypoints or #waypoints < 2 then
        return
    end
    
    local previousNode = nil
    
    for i, waypoint in ipairs(waypoints) do
        local node = CreateVisualNode(waypoint.Position)
        
        if previousNode then
            CreateBeam(previousNode, node)
        end
        
        previousNode = node
    end
end

local function MoveToPathDirectly(waypoints)
    if not waypoints or #waypoints < 2 then
        return false
    end
    
    local targetPosition = waypoints[#waypoints].Position
    Humanoid:MoveTo(targetPosition)
    Humanoid.WalkSpeed = MOVE_SPEED
    
    local startTime = tick()
    local previousDistance = (HumanoidRootPart.Position - targetPosition).Magnitude
    local stuckCounter = 0
    
    while tick() - startTime < PATH_TIMEOUT do
        local currentDistance = (HumanoidRootPart.Position - targetPosition).Magnitude
        
        if currentDistance < 3 then
            return true
        end
        
        if math.abs(previousDistance - currentDistance) < 0.1 then
            stuckCounter = stuckCounter + 1
            if stuckCounter >= PATH_STUCK_THRESHOLD then
                Humanoid.Jump = true
                task.wait(0.1)
                stuckCounter = 0
            end
        else
            stuckCounter = 0
        end
        
        previousDistance = currentDistance
        task.wait(0.05)
    end
    
    return false
end

local function FindPrimaryPart(model)
    if not model then return nil end
    
    if model:IsA("Model") and model.PrimaryPart then
        return model.PrimaryPart
    end
    
    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            return child
        end
    end
    
    return nil
end

local function LookAtPosition(position)
    if not position then return end
    
    local lookDirection = (position - HumanoidRootPart.Position).Unit
    local lookCFrame = CFrame.new(HumanoidRootPart.Position, HumanoidRootPart.Position + lookDirection)
    
    HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * (lookCFrame - lookCFrame.Position)
    task.wait(0.02)
end

local function FindKeyHitbox()
    local attempts = {
        function() return workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox.KeyHitbox end,
        function() return workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox end,
        function() 
            local keyObtain = workspace.CurrentRooms["0"].Assets:FindFirstChild("KeyObtain")
            if keyObtain then
                return FindPrimaryPart(keyObtain)
            end
            return nil
        end
    }
    
    for _, attemptFunc in ipairs(attempts) do
        local success, result = pcall(attemptFunc)
        if success and result then
            -- Increase the hitbox size
            pcall(function()
                result.Size = result.Size * 2  -- Doubled the hitbox size
            end)
            return result
        end
    end
    
    local keyHitbox = nil
    
    local assetConnection
    if workspace.CurrentRooms["0"].Assets:FindFirstChild("KeyObtain") then
        assetConnection = workspace.CurrentRooms["0"].Assets.KeyObtain.DescendantAdded:Connect(function(descendant)
            if descendant.Name == "KeyHitbox" or descendant.Name == "Hitbox" then
                keyHitbox = descendant
                -- Increase the hitbox size
                pcall(function()
                    keyHitbox.Size = keyHitbox.Size * 2  -- Doubled the hitbox size
                end)
            end
        end)
    end
    
    local assetsConnection = workspace.CurrentRooms["0"].Assets.DescendantAdded:Connect(function(descendant)
        if (descendant.Name == "KeyHitbox" or descendant.Name == "Hitbox") and
           (descendant.Parent and descendant.Parent.Name == "KeyObtain" or 
            descendant.Parent and descendant.Parent.Parent and descendant.Parent.Parent.Name == "KeyObtain") then
            keyHitbox = descendant
            -- Increase the hitbox size
            pcall(function()
                keyHitbox.Size = keyHitbox.Size * 2  -- Doubled the hitbox size
            end)
        end
        
        if descendant.Name == "KeyObtain" then
            local hitbox = descendant:FindFirstChild("Hitbox") or descendant:WaitForChild("Hitbox", 2)
            if hitbox then
                keyHitbox = hitbox
                -- Increase the hitbox size
                pcall(function()
                    keyHitbox.Size = keyHitbox.Size * 2  -- Doubled the hitbox size
                end)
            end
        end
    end)
    
    local startTime = tick()
    while not keyHitbox and tick() - startTime < 5 do
        for _, attemptFunc in ipairs(attempts) do
            local success, result = pcall(attemptFunc)
            if success and result then
                keyHitbox = result
                -- Increase the hitbox size
                pcall(function()
                    keyHitbox.Size = keyHitbox.Size * 2  -- Doubled the hitbox size
                end)
                break
            end
        end
        
        if keyHitbox then break end
        task.wait(0.20)
    end
    
    if assetConnection then assetConnection:Disconnect() end
    assetsConnection:Disconnect()
    
    if not keyHitbox then
        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
            local assets = room:FindFirstChild("Assets")
            if assets then
                local keyObtain = assets:FindFirstChild("KeyObtain")
                if keyObtain then
                    for _, desc in pairs(keyObtain:GetDescendants()) do
                        if desc:IsA("BasePart") then
                            -- Increase the hitbox size
                            pcall(function()
                                desc.Size = desc.Size * 2  -- Doubled the hitbox size
                            end)
                            return desc
                        end
                    end
                end
            end
        end
    end
    
    return keyHitbox
end

local function HasKey()
    local playerName = LocalPlayer.Name
    return workspace:FindFirstChild(playerName) and workspace[playerName]:FindFirstChild("Key")
end

local function InteractWithTouchInterest(object)
    if not object or not object:IsA("BasePart") then
        return false
    end
    
    -- For all proximity prompts, increase MaxActivationDistance and enable PromptClip
    for _, desc in pairs(object:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            desc.MaxActivationDistance = 90
            desc.RequiresLineOfSight = false
            pcall(function() desc.PromptClip = true end)
        end
    end
    
    if object.Parent then
        for _, desc in pairs(object.Parent:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                desc.MaxActivationDistance = 90
                desc.RequiresLineOfSight = false
                pcall(function() desc.PromptClip = true end)
            end
        end
    end
    
    local touchInterest = object:FindFirstChildOfClass("TouchTransmitter") or object:FindFirstChild("TouchInterest")
    if not touchInterest then
        if object.Parent and object.Parent:IsA("BasePart") then
            touchInterest = object.Parent:FindFirstChildOfClass("TouchTransmitter") or object.Parent:FindFirstChild("TouchInterest")
        end
        
        if not touchInterest then
            for _, child in pairs(object:GetChildren()) do
                if child:IsA("BasePart") then
                    touchInterest = child:FindFirstChildOfClass("TouchTransmitter") or child:FindFirstChild("TouchInterest")
                    if touchInterest then break end
                end
            end
        end
    end
    
    -- Specifically for workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox.TouchInterest
    pcall(function()
        if workspace.CurrentRooms["0"].Assets.KeyObtain and 
           workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox and
           workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox:FindFirstChild("TouchInterest") then
            local keyTouchInterest = workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox.TouchInterest
            for i = 1, 10 do  -- Interact 10x faster
                firetouchinterest(HumanoidRootPart, workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox, 0)
                task.wait(0.001)  -- Much faster wait time 
                firetouchinterest(HumanoidRootPart, workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox, 1)
                task.wait(0.001)  -- Much faster wait time
            end
        end
    end)
    
    local firetouchinterest = firetouchinterest or function(part1, part2, toggle)
        if toggle == 0 then
            part1.CFrame = part2.CFrame
            task.wait(0.03)  -- Much faster (10x)
            part1.CFrame = part1.CFrame * CFrame.new(0, 10, 0)
        end
    end
    
    for attemptNum = 1, 5 do  -- Increased number of attempts
        pcall(function()
            firetouchinterest(HumanoidRootPart, object, 0)
            task.wait(0.001)  -- Much faster (10x)
            firetouchinterest(HumanoidRootPart, object, 1)
        end)
        
        task.wait(0.01)  -- Much faster wait between attempts
        
        if HasKey() then
            return true
        end
    end
    
    local originalPosition = HumanoidRootPart.CFrame
    
    pcall(function()
        -- Position in front of the hitbox instead of inside it
        local hitboxCFrame = object.CFrame
        local frontPosition = hitboxCFrame.Position - hitboxCFrame.LookVector * 2
        HumanoidRootPart.CFrame = CFrame.new(frontPosition, object.Position)
        task.wait(0.01)  -- Much faster wait
        
        -- Try to interact from this position
        for i = 1, 5 do
            firetouchinterest(HumanoidRootPart, object, 0)
            task.wait(0.001)
            firetouchinterest(HumanoidRootPart, object, 1)
            task.wait(0.001)
        end
        
        task.wait(0.01)
        HumanoidRootPart.CFrame = originalPosition
    end)
    
    task.wait(0.01)
    return HasKey()
end

local isHandlingEyes = false
local eyesDetected = false
local eyesConnection = nil
local heartbeatConnection = nil

local function HandleEyes(eyes)
    if not eyes then return end
game:GetService("ReplicatedStorage").RemotesFolder.MotorReplication:FireServer(-900)


game:GetService("ReplicatedStorage").RemotesFolder.MotorReplication:FireServer(0)
    eyesDetected = true
end

local function StartEyesMonitoring()
    if eyesConnection then eyesConnection:Disconnect() end
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    
    eyesConnection = workspace.ChildAdded:Connect(function(child)
        if child.Name == "Eyes" then
            HandleEyes(child)
        end
    end)
    
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        local eyes = workspace:FindFirstChild("Eyes")
        if eyes and not eyesDetected then
            HandleEyes(eyes)
        end
    end)
    
    local existingEyes = workspace:FindFirstChild("Eyes")
    if existingEyes then
        HandleEyes(existingEyes)
    end
    
    local function stopEyesMonitoring()
        if eyesConnection then eyesConnection:Disconnect() end
        if heartbeatConnection then heartbeatConnection:Disconnect() end
        RunService:UnbindFromRenderStep("EyesAimbot")
    end
    
    return stopEyesMonitoring
end

local function GetAllDoorParts(door)
    if not door then return {} end
    
    local doorParts = {}
    
    if door:IsA("BasePart") then
        table.insert(doorParts, door)
    end
    
    if door:IsA("Model") and door.PrimaryPart then
        table.insert(doorParts, door.PrimaryPart)
    end
    
    for _, child in pairs(door:GetDescendants()) do
        if child:IsA("BasePart") then
            if child.Name:find("Knob") or child.Name:find("Handle") or child.Name:find("Lock") then
                table.insert(doorParts, 1, child)
            else
                table.insert(doorParts, child)
            end
        end
    end
    
    return doorParts
end

local function InteractWithDoor(door)
    if not door then return false end
    
    local lockPrompt = door.Lock and door.Lock:FindFirstChild("UnlockPrompt")
    if lockPrompt and lockPrompt:IsA("ProximityPrompt") then
        local waypoints = CalculatePath(HumanoidRootPart.Position, door.Lock.Position, true)
        VisualizePath(waypoints)
        MoveToPathDirectly(waypoints)
        
        LookAtPosition(door.Lock.Position)
        
        lockPrompt.HoldDuration = 0
        lockPrompt.MaxActivationDistance = 13
        lockPrompt.RequiresLineOfSight = false
        pcall(function() lockPrompt.PromptClip = true end)
        
        for attempt = 1, 3 do
            pcall(function()
                fireproximityprompt(lockPrompt)
            end)
            task.wait(0.2)
            
            if not HasKey() then
                return true
            end
        end
        
        return not HasKey()
    else
        local doorParts = GetAllDoorParts(door)
        
        if #doorParts == 0 then
            return false
        end
        
        local mainDoorPart = doorParts[1]
        
        local waypoints = CalculatePath(HumanoidRootPart.Position, mainDoorPart.Position, true)
        VisualizePath(waypoints)
        MoveToPathDirectly(waypoints)
        
        LookAtPosition(mainDoorPart.Position)
        
        for _, part in ipairs(doorParts) do
            for _, desc in ipairs(part:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    desc.HoldDuration = 0
                    desc.MaxActivationDistance = 13
                    desc.RequiresLineOfSight = false
                    pcall(function() desc.PromptClip = true end)
                    
                    for attempt = 1, 3 do
                        pcall(function()
                            fireproximityprompt(desc)
                        end)
                        
                        task.wait(0.1)
                        
                        if not HasKey() then
                            return true
                        end
                    end
                end
            end
        end
        
        return not HasKey()
    end
end

local teleportConnection = nil
local teleportKeyConnection = nil
local keyTeleportSuccess = false
local returnTeleportSuccess = false

local function AutomateDoors()
    local stopEyesMonitoring = StartEyesMonitoring()
    
    pcall(DeleteObjects)
    
    local keyHitbox = FindKeyHitbox()
    if not keyHitbox then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:find("KeyObtain") and obj:IsA("BasePart") then
                keyHitbox = obj
                break
            end
        end
        
        if not keyHitbox then
            return
        end
    end
    
    keyTeleportSuccess = false
    
    teleportKeyConnection = RunService.Heartbeat:Connect(function()
        if HasKey() then
            keyTeleportSuccess = true
            if teleportKeyConnection then
                teleportKeyConnection:Disconnect()
                teleportKeyConnection = nil
            end
            return
        end
        
        pcall(function()
            local hitboxPosition = keyHitbox.Position
            local offset = keyHitbox.CFrame.LookVector * 3 
            local teleportPosition = hitboxPosition - offset
            
            HumanoidRootPart.CFrame = CFrame.new(teleportPosition, hitboxPosition)
        end)
        
        LookAtPosition(keyHitbox.Position)

        InteractWithTouchInterest(keyHitbox)
        
        pcall(function()
            if workspace.CurrentRooms["0"].Assets.KeyObtain and 
               workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox then
                
                for i = 1, 3 do 
                    firetouchinterest(HumanoidRootPart, workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox, 0)
                    task.wait(0.001)
                    firetouchinterest(HumanoidRootPart, workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox, 1)
                    task.wait(0.001)
                    firetouchinterest(HumanoidRootPart, workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox, 0)
                    task.wait(0.001)
                    firetouchinterest(HumanoidRootPart, workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox, 1)
                    task.wait(0.001)
                end
            end
        end)
    end)
    
    repeat task.wait() until keyTeleportSuccess or not teleportKeyConnection
    
    returnTeleportSuccess = false
    
    if HasKey() then
        teleportConnection = RunService.Heartbeat:Connect(function()
            local distance = (HumanoidRootPart.Position - initialPosition).Magnitude
            
            if distance < 5 then
                returnTeleportSuccess = true
                if teleportConnection then
                    teleportConnection:Disconnect()
                    teleportConnection = nil
                end
                return
            end
            
            pcall(function()
                HumanoidRootPart.CFrame = CFrame.new(initialPosition)
            end)
        end)
        
        repeat task.wait() until returnTeleportSuccess or not teleportConnection
        
        local door = workspace.CurrentRooms["0"].Door
        if not door then
            for _, obj in pairs(workspace.CurrentRooms["0"]:GetDescendants()) do
                if obj.Name == "Door" then
                    door = obj
                    break
                end
            end
        end
        
        if door then
            InteractWithDoor(door)
        end
    end
    
    ClearPathVisuals()
end

local success, errorMsg = pcall(function()
    AutomateDoors()
end)

if not success then
    if HasKey() then
        local door = workspace.CurrentRooms["0"].Door
        if door then
            InteractWithDoor(door)
        end
    end
    
    StartEyesMonitoring()
end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local queuedToTeleport = false

local function RegisterExecuteOnTeleport()
    if queuedToTeleport then return end
    queuedToTeleport = true
    
    local scriptToExecute = [[ loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc-Rhyan57/MsProject/refs/heads/main/projects/msproject_doorsdeathfarm_opensource.lua"))() ]]
    
    queue_on_teleport(scriptToExecute)
    print("Script registrado para executar após o teleporte!")
end

local function HandleDeath()
    if (humanoid.Health <= 0 or player:GetAttribute("Alive") == "false") then
        print("[DeathFarm] Condição de morte detectada!")
        
        ReplicatedStorage.RemotesFolder.Statistics:FireServer()
        print("[DeathFarm] Statistics invocado!")
        
        RegisterExecuteOnTeleport()
        
        ReplicatedStorage.RemotesFolder.PlayAgain:FireServer()
        print("[DeathFarm] PlayAgain solicitado!")
    end
end

humanoid.HealthChanged:Connect(function(health)
    if health <= 0 then
        HandleDeath()
    end
end)

player:GetAttributeChangedSignal("Alive"):Connect(function()
    if player:GetAttribute("Alive") == "false" then
        HandleDeath()
    end
end)

local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    
    humanoid.HealthChanged:Connect(function(health)
        if health <= 0 then
            HandleDeath()
        end
    end)
end

player.CharacterAdded:Connect(onCharacterAdded)

TeleportService.OnTeleport:Connect(function(teleportState)
    if teleportState == Enum.TeleportState.Started then
        print("[DeathFarm] Teleporte iniciado! Registrando script...")
        RegisterExecuteOnTeleport()
    end
end)
