local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")

-- Global Variables
getgenv().Msproject_Config = {
    Target = nil,
    TargetName = "",
    Enabled = false,
    Power = 50000,
    MaxPower = 50000,
    Range = 999,
    PullDelay = 0.1
}

-- Enhanced Network System
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        ControlledParts = {},
        PartOwnership = {},
        Velocity = Vector3.new(25.95, 25.95, 25.95)
    }
end

-- Sound System
local function playSound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Enhanced Target Finding System
local function findTarget(input)
    -- Try exact name match first
    local target = Players:FindFirstChild(input)
    
    if not target then
        -- Try display name
        for _, player in ipairs(Players:GetPlayers()) do
            if player.DisplayName:lower() == input:lower() then
                target = player
                break
            end
        end
    end
    
    if not target then
        -- Try partial name match
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name:lower():find(input:lower()) or 
               player.DisplayName:lower():find(input:lower()) then
                target = player
                break
            end
        end
    end
    
    -- Try UserID
    if not target and tonumber(input) then
        pcall(function()
            target = Players:GetPlayerByUserId(tonumber(input))
        end)
    end
    
    return target
end

-- GUI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerSniperV3"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 280)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Player Sniper V3"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -35, 0, 0)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 25
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Parent = TitleBar

-- Content Frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -40)
ContentFrame.Position = UDim2.new(0, 10, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Target Input
local TargetInput = Instance.new("TextBox")
TargetInput.Size = UDim2.new(1, 0, 0, 35)
TargetInput.Position = UDim2.new(0, 0, 0, 10)
TargetInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
TargetInput.Text = ""
TargetInput.PlaceholderText = "Enter Player Name/DisplayName/ID"
TargetInput.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
TargetInput.TextSize = 14
TargetInput.Font = Enum.Font.Gotham
TargetInput.Parent = ContentFrame

local TargetCorner = Instance.new("UICorner")
TargetCorner.CornerRadius = UDim.new(0, 6)
TargetCorner.Parent = TargetInput

-- Target Display
local TargetDisplay = Instance.new("TextLabel")
TargetDisplay.Size = UDim2.new(1, 0, 0, 25)
TargetDisplay.Position = UDim2.new(0, 0, 0, 55)
TargetDisplay.BackgroundTransparency = 1
TargetDisplay.Text = "Current Target: None"
TargetDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
TargetDisplay.TextSize = 14
TargetDisplay.Font = Enum.Font.Gotham
TargetDisplay.Parent = ContentFrame

-- Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, 0, 0, 35)
ToggleButton.Position = UDim2.new(0, 0, 0, 90)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
ToggleButton.Text = "DISABLED"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 16
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Parent = ContentFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleButton

-- Power Slider
local PowerLabel = Instance.new("TextLabel")
PowerLabel.Size = UDim2.new(1, 0, 0, 25)
PowerLabel.Position = UDim2.new(0, 0, 0, 135)
PowerLabel.BackgroundTransparency = 1
PowerLabel.Text = "Power: " .. Msproject_Config.Power
PowerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
PowerLabel.TextSize = 14
PowerLabel.Font = Enum.Font.Gotham
PowerLabel.Parent = ContentFrame

local PowerSlider = Instance.new("TextButton")
PowerSlider.Size = UDim2.new(1, 0, 0, 10)
PowerSlider.Position = UDim2.new(0, 0, 0, 160)
PowerSlider.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
PowerSlider.Text = ""
PowerSlider.AutoButtonColor = false
PowerSlider.Parent = ContentFrame

local PowerCorner = Instance.new("UICorner")
PowerCorner.CornerRadius = UDim.new(0, 6)
PowerCorner.Parent = PowerSlider

local PowerFill = Instance.new("Frame")
PowerFill.Size = UDim2.new(Msproject_Config.Power/Msproject_Config.MaxPower, 0, 1, 0)
PowerFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
PowerFill.BorderSizePixel = 0
PowerFill.Parent = PowerSlider

local PowerFillCorner = Instance.new("UICorner")
PowerFillCorner.CornerRadius = UDim.new(0, 6)
PowerFillCorner.Parent = PowerFill

-- Stats Display
local StatsDisplay = Instance.new("TextLabel")
StatsDisplay.Size = UDim2.new(1, 0, 0, 60)
StatsDisplay.Position = UDim2.new(0, 0, 0, 180)
StatsDisplay.BackgroundTransparency = 1
StatsDisplay.Text = "Parts Controlled: 0\nRange: " .. Msproject_Config.Range .. "\nStatus: Ready"
StatsDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
StatsDisplay.TextSize = 14
StatsDisplay.Font = Enum.Font.Gotham
StatsDisplay.TextYAlignment = Enum.TextYAlignment.Top
StatsDisplay.Parent = ContentFrame

-- Enhanced Part Control System
local function updatePartOwnership(part)
    if Network.PartOwnership[part] == nil then
        Network.PartOwnership[part] = true
        Network.ControlledParts[part] = true
        part.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0.001, 0.001, 0.001, 0.001)
        part.Velocity = Network.Velocity
        part.Massless = true
        part.Color = Color3.new(1, 0, 0)
    end
end

local function releasePartOwnership(part)
    Network.PartOwnership[part] = nil
    Network.ControlledParts[part] = nil
    part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
        part.Massless = true
        part.Color = Color3.new(1, 0, 0)
end

-- Enhanced Stats Display Update
local function updateStatsDisplay()
    local controlledCount = 0
    for _ in pairs(Network.ControlledParts) do
        controlledCount = controlledCount + 1
    end
    
    StatsDisplay.Text = string.format(
        "Parts Controlled: %d\nRange: %d\nStatus: %s",
        controlledCount,
        Msproject_Config.Range,
        Msproject_Config.Enabled and "Active" or "Ready"
    )
end

-- Improved Part Control Logic
local function updatePartPosition(part, targetPosition)
    local direction = (targetPosition - part.Position)
    local distance = direction.Magnitude
    
    if distance > 1 then
        direction = direction.Unit
        local velocity = direction * math.min(Msproject_Config.Power, distance * 10)
        part.Velocity = velocity
    else
        part.Velocity = Vector3.new(0, 0, 0)
        part.Massless = true
        part.Color = Color3.new(1, 0, 0)
    end
end

-- GUI Functionality
local minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame:TweenSize(UDim2.new(0, 250, 0, 30), "Out", "Quad", 0.3, true)
        MinimizeButton.Text = "+"
        ContentFrame.Visible = false
    else
        MainFrame:TweenSize(UDim2.new(0, 250, 0, 280), "Out", "Quad", 0.3, true)
        MinimizeButton.Text = "-"
        ContentFrame.Visible = true
    end
    playSound("12221967")
end)

TargetInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local target = findTarget(TargetInput.Text)
        if target then
            Msproject_Config.Target = target
            Msproject_Config.TargetName = target.Name
            TargetDisplay.Text = "Current Target: " .. target.Name
            StarterGui:SetCore("SendNotification", {
                Title = "Target Set",
                Text = "Now targeting: " .. target.Name,
                Duration = 3
            })
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "Player not found!",
                Duration = 3
            })
        end
    end
end)

ToggleButton.MouseButton1Click:Connect(function()
    if not Msproject_Config.Target then
        StarterGui:SetCore("SendNotification", {
            Title = "Error",
            Text = "Please set a target player first!",
            Duration = 3
        })
        return
    end
    
    Msproject_Config.Enabled = not Msproject_Config.Enabled
    ToggleButton.Text = Msproject_Config.Enabled and "ENABLED" or "DISABLED"
    ToggleButton.BackgroundColor3 = Msproject_Config.Enabled and 
        Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    
    playSound("12221967")
end)

-- Power Slider Functionality
local isDragging = false

PowerSlider.MouseButton1Down:Connect(function()
    isDragging = true
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and isDragging then
        local sliderPosition = math.clamp(
            (input.Position.X - PowerSlider.AbsolutePosition.X) / PowerSlider.AbsoluteSize.X,
            0,
            1
        )
        
        Msproject_Config.Power = math.floor(sliderPosition * Msproject_Config.MaxPower)
        PowerFill.Size = UDim2.new(sliderPosition, 0, 1, 0)
        PowerLabel.Text = "Power: " .. Msproject_Config.Power
    end
end)

-- Make GUI draggable
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Main Control Loop
local lastPull = 0
RunService.Heartbeat:Connect(function()
    if not Msproject_Config.Enabled or not Msproject_Config.Target then 
        -- Release all parts when disabled
        for part in pairs(Network.ControlledParts) do
            releasePartOwnership(part)
        end
        updateStatsDisplay()
        return 
    end
    
    local targetChar = Msproject_Config.Target.Character
    if not targetChar then return end
    
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    -- Update controlled parts
    if tick() - lastPull >= Msproject_Config.PullDelay then
        lastPull = tick()
        
        -- Release parts that are too far
        for part in pairs(Network.ControlledParts) do
            if (part.Position - targetRoot.Position).Magnitude > Msproject_Config.Range then
                releasePartOwnership(part)
            end
        end
        
        -- Find new parts to control
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part.Anchored 
               and not part:IsDescendantOf(Players.LocalPlayer.Character)
               and (part.Position - targetRoot.Position).Magnitude <= Msproject_Config.Range 
               and not Network.ControlledParts[part] then
                
                updatePartOwnership(part)
            end
        end
    end
    
    -- Update positions of controlled parts
    for part in pairs(Network.ControlledParts) do
        if part.Parent then -- Check if part still exists
            updatePartPosition(part, targetRoot.Position)
        else
            Network.ControlledParts[part] = nil
        end
    end
    
    -- Update stats display every frame
    updateStatsDisplay()
end)

-- Set simulation radius
RunService.Stepped:Connect(function()
    sethiddenproperty(Players.LocalPlayer, "SimulationRadius", math.huge)
end)

-- Initial Setup
StarterGui:SetCore("SendNotification", {
    Title = "Script Loaded!",
    Text = "Player Sniper V3 is ready to use",
    Duration = 5
})

-- Chat message (Updated for new chat system)

local function SendChatMessage(message)

    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then

        local textChannel = TextChatService.TextChannels.RBXGeneral

        textChannel:SendAsync(message)

    else

        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")

    end

end

SendChatMessage("👋 Rhyan57 is the best")
