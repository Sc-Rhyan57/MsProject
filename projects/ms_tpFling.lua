local StarterGui = game:GetService("StarterGui")
StarterGui:SetCore("SendNotification", {
    Title = "Msproject Iniciado!";
    Text = "Divirta-se matando!";
    Duration = 5;
})

local StarterGui = game:GetService("StarterGui")
StarterGui:SetCore("SendNotification", {
    Title = "DreamAlt is Gay";
    Text = "KKKKKKKKKKKKKKKK";
    Duration = 15;
})

local StarterGui = game:GetService("StarterGui")
StarterGui:SetCore("SendNotification", {
    Title = "hm";
    Text = "Tá bom, chega de eastereggs.";
    Duration = 5;
})

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://4590657391"
sound.Volume = 1
sound.Parent = game.Workspace
sound:Play()

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/Sc-Rhyan57/Msdoors/refs/heads/main/Library/OrionLibrary_msdoors.lua')))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Noclip = nil
local PathBeam = nil

local function setupCharacter(char)
    Character = char
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)


local Window = OrionLib:MakeWindow({IntroText = "MsProjects",Icon = "rbxassetid://100573561401335", IntroIcon = "rbxassetid://95869322194132", Name = "MsProject | TpFling", HidePremium = false, SaveConfig = true, ConfigFolder = ".msproject/tpfling"})
local MainTab = Window:MakeTab({Name = "Principal", Icon = "rbxassetid://7734022107"})

local isEnabled = false
local aura = nil
local currentTarget = nil

local function enableNoclip()
    if Noclip then return end
    Noclip = RunService.Stepped:Connect(function()
        if Character then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    if Noclip then
        Noclip:Disconnect()
        Noclip = nil
    end
end

local function createPathToTarget(target)
    if PathBeam then PathBeam:Destroy() end
    
    PathBeam = Instance.new("Beam")
    local a0 = Instance.new("Attachment")
    local a1 = Instance.new("Attachment")
    
    a0.Parent = HumanoidRootPart
    a1.Parent = target.Character.HumanoidRootPart
    
    PathBeam.Attachment0 = a0
    PathBeam.Attachment1 = a1
    PathBeam.Width0 = 1
    PathBeam.Width1 = 1
    PathBeam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
    PathBeam.FaceCamera = true
    PathBeam.Parent = workspace
    
    return function()
        PathBeam:Destroy()
        a0:Destroy()
        a1:Destroy()
        PathBeam = nil
    end
end

local function createAura()
    if aura then return end
    
    aura = Instance.new("Part")
    aura.Shape = Enum.PartType.Ball
    aura.Size = Vector3.new(10, 10, 10)
    aura.Material = Enum.Material.ForceField
    aura.CanCollide = false
    aura.Anchored = true
    aura.Transparency = 0.5
    aura.Parent = workspace
    
    local hue = 0
    RunService.Heartbeat:Connect(function()
        if not isEnabled then
            aura:Destroy()
            aura = nil
            return
        end
        
        if HumanoidRootPart then
            aura.Position = HumanoidRootPart.Position
            hue = (hue + 1) % 360
            aura.Color = Color3.fromHSV(hue/360, 1, 1)
        end
    end)
end

local function moveToTarget(target, cleanupPath)
    local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then 
        if cleanupPath then cleanupPath() end
        return false 
    end

    local distance = (targetRoot.Position - HumanoidRootPart.Position).magnitude
    if distance > 10 then
        HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position, targetRoot.Position)
        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, -distance/2)
        return true
    end
    
    return false
end

local function flingPlayer(target)
    local targetCharacter = target.Character
    if not targetCharacter then return end
    
    local startTime = tick()
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    while tick() - startTime < 5 and isEnabled and currentTarget == target do
        HumanoidRootPart.CFrame = targetRoot.CFrame
        HumanoidRootPart.Velocity = Vector3.new(99999, 99999, 99999)
        task.wait()
    end
end

local hudText = Drawing.new("Text")
hudText.Visible = false
hudText.Center = true
hudText.Outline = true
hudText.Font = 2
hudText.Size = 20
hudText.Color = Color3.fromRGB(255, 255, 255)
hudText.Position = Vector2.new(game.Workspace.CurrentCamera.ViewportSize.X/2, 50)

local function updateHUD(targetName)
    hudText.Text = "Current Target: " .. targetName
    hudText.Visible = true
end

local function processTarget(target)
    if not target.Character or target == LocalPlayer then return end
    
    currentTarget = target
    updateHUD(target.Name)
    
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    local distance = (targetRoot.Position - HumanoidRootPart.Position).Magnitude
    local cleanupPath = nil
    
    if distance > 2000 then
        cleanupPath = createPathToTarget(target)
        enableNoclip()
        
        while distance > 10 and isEnabled do
            if not moveToTarget(target, cleanupPath) then break end
            distance = (targetRoot.Position - HumanoidRootPart.Position).Magnitude
            task.wait()
        end
        
        if cleanupPath then cleanupPath() end
        disableNoclip()
    end
    
    flingPlayer(target)
end

MainTab:AddToggle({
    Name = "Tp Fling",
    Default = false,
    Callback = function(Value)
        isEnabled = Value
        hudText.Visible = Value
        
        if not Value then
            disableNoclip()
            if PathBeam then PathBeam:Destroy() end
            return
        end
        
        createAura()
        spawn(function()
            while isEnabled do
                for _, target in pairs(Players:GetPlayers()) do
                    if not isEnabled then break end
                    processTarget(target)
                end
                task.wait(1)
            end
        end)
    end
})
local function SendChatMessage(message)

    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then

        local textChannel = TextChatService.TextChannels.RBXGeneral

        textChannel:SendAsync(message)

    else

        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")

    end

end

SendChatMessage("👋 Rhyan57 is the best")
