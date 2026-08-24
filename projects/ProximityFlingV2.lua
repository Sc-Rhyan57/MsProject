local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local collectedParts = {}
local currentHighlight = nil

local function getIgnoreFolder()
    local gameFolder = workspace:FindFirstChild("Game")
    if gameFolder then
        local playersFolder = gameFolder:FindFirstChild("Players")
        if playersFolder then
            return playersFolder
        end
    end
    return nil
end

local function isWeldedToAnchored(part)
    for _, joint in pairs(part:GetJoints()) do
        local part0 = joint.Part0
        local part1 = joint.Part1
        if part0 and part0 ~= part and part0.Anchored then return true end
        if part1 and part1 ~= part and part1.Anchored then return true end
    end
    return false
end

local function shouldIgnore(part)
    local ignoreFolder = getIgnoreFolder()
    if ignoreFolder and part:IsDescendantOf(ignoreFolder) then
        return true
    end
    
    local islandFolder = workspace:FindFirstChild("Island")
    if islandFolder and part:IsDescendantOf(islandFolder) then
        return true
    end

    -- Ignora QUALQUER personagem de jogador
    local model = part:FindFirstAncestorOfClass("Model")
    if model and Players:GetPlayerFromCharacter(model) then
        return true
    end

    if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then
        return true
    end
    
    local charParts = {"Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
    for _, name in ipairs(charParts) do
        if part.Name == name then return true end
    end
    return false
end

local function setTargetHighlight(targetChar)
    if currentHighlight and currentHighlight.Parent == targetChar then return end
    if currentHighlight then currentHighlight:Destroy() end
    if targetChar then
        currentHighlight = Instance.new("Highlight")
        currentHighlight.Name = "MsdoorsFlingTarget"
        currentHighlight.FillColor = Color3.fromRGB(255, 0, 0)
        currentHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        currentHighlight.FillTransparency = 0.5
        currentHighlight.Parent = targetChar
    end
end

local function addPart(part)
    if not part:IsA("BasePart") then return end
    if part.Anchored then return end
    
    local rootPart = part
    pcall(function() rootPart = part:GetRootPart() end)
    if rootPart and rootPart.Anchored then return end

    if isWeldedToAnchored(part) then return end

    if shouldIgnore(part) then return end
    if table.find(collectedParts, part) then return end
    
    for _, c in pairs(part:GetChildren()) do
        if c:IsA("BodyPosition") or c:IsA("BodyGyro") or c:IsA("BodyAngularVelocity") then
            c:Destroy()
        end
    end
    
    local bp = Instance.new("BodyPosition")
    bp.Name = "MsdoorsFlingBP"
    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bp.Position = part.Position
    bp.Parent = part
    
    table.insert(collectedParts, part)
end

local function scanParts()
    local balder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Lobby") and workspace.Game.Lobby:FindFirstChild("Props") and workspace.Game.Lobby.Props:FindFirstChild("Balder")
    if balder then
        for _, v in pairs(balder:GetDescendants()) do
            addPart(v)
        end
    end
    for _, v in pairs(workspace:GetDescendants()) do
        addPart(v)
    end
end

task.spawn(function()
    while task.wait(2) do
        scanParts()
    end
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local nearestTarget = nil
    local nearestDist = 67
    
    local flatRootPos = Vector3.new(root.Position.X, 0, root.Position.Z)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local tHead = player.Character:FindFirstChild("Head")
            local tRoot = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
            local targetPart = tHead or tRoot
            if targetPart and not targetPart.Anchored then
                local flatTargetPos = Vector3.new(targetPart.Position.X, 0, targetPart.Position.Z)
                local dist = (flatTargetPos - flatRootPos).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestTarget = targetPart
                end
            end
        end
    end

    if nearestTarget then
        setTargetHighlight(nearestTarget.Parent)
    else
        setTargetHighlight(nil)
    end

    for i = #collectedParts, 1, -1 do
        local part = collectedParts[i]
        if not part or not part.Parent or part.Anchored or isWeldedToAnchored(part) then
            table.remove(collectedParts, i)
            if part and part.Parent then
                local bp = part:FindFirstChild("MsdoorsFlingBP")
                if bp then bp:Destroy() end
            end
        else
            local bp = part:FindFirstChild("MsdoorsFlingBP")
            if bp then
                pcall(function()
                    if nearestTarget then
                        part.CanCollide = false
                        bp.Position = nearestTarget.Position + Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1))
                        part.AssemblyLinearVelocity = Vector3.new(math.random(-5000, 5000), math.random(-5000, 5000), math.random(-5000, 5000))
                        part.AssemblyAngularVelocity = Vector3.new(math.random(-90000, 90000), math.random(-90000, 90000), math.random(-90000, 90000))
                    else
                        part.CanCollide = false
                        bp.Position = root.Position + Vector3.new(math.random(-10, 10), 30, math.random(-10, 10))
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.new(math.random(-90000, 90000), math.random(-90000, 90000), math.random(-90000, 90000))
                    end
                end)
            else
                table.remove(collectedParts, i)
            end
        end
    end
end)
