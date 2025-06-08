local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

getgenv().Msproject_Config = {
    Target = nil,
    TargetName = "",
    Enabled = false,
    Power = 95000,
    MaxPower = 100000,
    Range = 96000,
    PullDelay = 0.05
}

if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        ControlledParts = {},
        PartOwnership = {},
        Velocity = Vector3.new(90, 90, 90)
    }
end

local LocalPlayer = Players.LocalPlayer
local hasNetworkOwnership = pcall(function()
    return workspace.CurrentCamera:SetNetworkOwner()
end)

local function playSound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

local function findTarget(input)
    local target = Players:FindFirstChild(input)
    
    if not target then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.DisplayName:lower() == input:lower() then
                target = player
                break
            end
        end
    end
    
    if not target then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name:lower():find(input:lower()) or 
               player.DisplayName:lower():find(input:lower()) then
                target = player
                break
            end
        end
    end
    
    if not target and tonumber(input) then
        pcall(function()
            target = Players:GetPlayerByUserId(tonumber(input))
        end)
    end
    
    return target
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerSniperV4"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(100, 100, 120)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 20)
TitleFix.Position = UDim2.new(0, 0, 1, -20)
TitleFix.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎯 Player Sniper V4"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 35, 0, 35)
MinimizeButton.Position = UDim2.new(1, -40, 0, 2.5)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
MinimizeButton.Text = "−"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 18
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinimizeButton

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -30, 1, -55)
ContentFrame.Position = UDim2.new(0, 15, 0, 50)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local TargetSection = Instance.new("Frame")
TargetSection.Size = UDim2.new(1, 0, 0, 90)
TargetSection.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
TargetSection.Parent = ContentFrame

local TargetSectionCorner = Instance.new("UICorner")
TargetSectionCorner.CornerRadius = UDim.new(0, 8)
TargetSectionCorner.Parent = TargetSection

local TargetSectionStroke = Instance.new("UIStroke")
TargetSectionStroke.Color = Color3.fromRGB(60, 60, 80)
TargetSectionStroke.Thickness = 1
TargetSectionStroke.Parent = TargetSection

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -20, 0, 25)
TargetLabel.Position = UDim2.new(0, 10, 0, 5)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "🎯 Target Selection"
TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLabel.TextSize = 16
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = TargetSection

local TargetInput = Instance.new("TextBox")
TargetInput.Size = UDim2.new(1, -20, 0, 30)
TargetInput.Position = UDim2.new(0, 10, 0, 30)
TargetInput.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TargetInput.Text = ""
TargetInput.PlaceholderText = "Enter Player Name/DisplayName/ID"
TargetInput.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 170)
TargetInput.TextSize = 14
TargetInput.Font = Enum.Font.Gotham
TargetInput.Parent = TargetSection

local TargetInputCorner = Instance.new("UICorner")
TargetInputCorner.CornerRadius = UDim.new(0, 6)
TargetInputCorner.Parent = TargetInput

local TargetDisplay = Instance.new("TextLabel")
TargetDisplay.Size = UDim2.new(1, -20, 0, 20)
TargetDisplay.Position = UDim2.new(0, 10, 0, 65)
TargetDisplay.BackgroundTransparency = 1
TargetDisplay.Text = "Current Target: None"
TargetDisplay.TextColor3 = Color3.fromRGB(180, 180, 200)
TargetDisplay.TextSize = 13
TargetDisplay.Font = Enum.Font.Gotham
TargetDisplay.TextXAlignment = Enum.TextXAlignment.Left
TargetDisplay.Parent = TargetSection

local ControlSection = Instance.new("Frame")
ControlSection.Size = UDim2.new(1, 0, 0, 120)
ControlSection.Position = UDim2.new(0, 0, 0, 100)
ControlSection.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
ControlSection.Parent = ContentFrame

local ControlSectionCorner = Instance.new("UICorner")
ControlSectionCorner.CornerRadius = UDim.new(0, 8)
ControlSectionCorner.Parent = ControlSection

local ControlSectionStroke = Instance.new("UIStroke")
ControlSectionStroke.Color = Color3.fromRGB(60, 60, 80)
ControlSectionStroke.Thickness = 1
ControlSectionStroke.Parent = ControlSection

local ControlLabel = Instance.new("TextLabel")
ControlLabel.Size = UDim2.new(1, -20, 0, 25)
ControlLabel.Position = UDim2.new(0, 10, 0, 5)
ControlLabel.BackgroundTransparency = 1
ControlLabel.Text = "⚡ Control Panel"
ControlLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ControlLabel.TextSize = 16
ControlLabel.Font = Enum.Font.GothamBold
ControlLabel.TextXAlignment = Enum.TextXAlignment.Left
ControlLabel.Parent = ControlSection

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, -20, 0, 40)
ToggleButton.Position = UDim2.new(0, 10, 0, 35)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
ToggleButton.Text = "🔴 DISABLED"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 16
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Parent = ControlSection

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleButton

local PowerLabel = Instance.new("TextLabel")
PowerLabel.Size = UDim2.new(1, -20, 0, 20)
PowerLabel.Position = UDim2.new(0, 10, 0, 85)
PowerLabel.BackgroundTransparency = 1
PowerLabel.Text = "⚡ Power: " .. Msproject_Config.Power
PowerLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
PowerLabel.TextSize = 14
PowerLabel.Font = Enum.Font.Gotham
PowerLabel.TextXAlignment = Enum.TextXAlignment.Left
PowerLabel.Parent = ControlSection

local PowerSlider = Instance.new("TextButton")
PowerSlider.Size = UDim2.new(1, -20, 0, 12)
PowerSlider.Position = UDim2.new(0, 10, 0, 105)
PowerSlider.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
PowerSlider.Text = ""
PowerSlider.AutoButtonColor = false
PowerSlider.Parent = ControlSection

local PowerSliderCorner = Instance.new("UICorner")
PowerSliderCorner.CornerRadius = UDim.new(0, 6)
PowerSliderCorner.Parent = PowerSlider

local PowerFill = Instance.new("Frame")
PowerFill.Size = UDim2.new(Msproject_Config.Power/Msproject_Config.MaxPower, 0, 1, 0)
PowerFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
PowerFill.BorderSizePixel = 0
PowerFill.Parent = PowerSlider

local PowerFillCorner = Instance.new("UICorner")
PowerFillCorner.CornerRadius = UDim.new(0, 6)
PowerFillCorner.Parent = PowerFill

local StatsSection = Instance.new("Frame")
StatsSection.Size = UDim2.new(1, 0, 0, 110)
StatsSection.Position = UDim2.new(0, 0, 0, 230)
StatsSection.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
StatsSection.Parent = ContentFrame

local StatsSectionCorner = Instance.new("UICorner")
StatsSectionCorner.CornerRadius = UDim.new(0, 8)
StatsSectionCorner.Parent = StatsSection

local StatsSectionStroke = Instance.new("UIStroke")
StatsSectionStroke.Color = Color3.fromRGB(60, 60, 80)
StatsSectionStroke.Thickness = 1
StatsSectionStroke.Parent = StatsSection

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, -20, 0, 25)
StatsLabel.Position = UDim2.new(0, 10, 0, 5)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Text = "📊 Statistics"
StatsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatsLabel.TextSize = 16
StatsLabel.Font = Enum.Font.GothamBold
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.Parent = StatsSection

local StatsDisplay = Instance.new("TextLabel")
StatsDisplay.Size = UDim2.new(1, -20, 0, 75)
StatsDisplay.Position = UDim2.new(0, 10, 0, 30)
StatsDisplay.BackgroundTransparency = 1
StatsDisplay.Text = "🔧 Parts Controlled: 0\n📏 Range: " .. Msproject_Config.Range .. "\n⚡ Status: Ready\n🎯 Target Distance: N/A\nrhyan57"
StatsDisplay.TextColor3 = Color3.fromRGB(180, 180, 200)
StatsDisplay.TextSize = 13
StatsDisplay.Font = Enum.Font.Gotham
StatsDisplay.TextYAlignment = Enum.TextYAlignment.Top
StatsDisplay.TextXAlignment = Enum.TextXAlignment.Left
StatsDisplay.Parent = StatsSection

local function updatePartOwnership(part)
    if Network.PartOwnership[part] == nil then
        Network.PartOwnership[part] = true
        Network.ControlledParts[part] = true
        part.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0.001, 0.001, 0.001, 0.001)
        part.Velocity = Network.Velocity
        part.Massless = true
        
        if hasNetworkOwnership then
            pcall(function()
                part:SetNetworkOwner(LocalPlayer)
            end)
        end
    end
end

local function releasePartOwnership(part)
    Network.PartOwnership[part] = nil
    Network.ControlledParts[part] = nil
    if part and part.Parent then
        part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
        part.Massless = false
        
        if hasNetworkOwnership then
            pcall(function()
                part:SetNetworkOwner(nil)
            end)
        end
    end
end

local function updateStatsDisplay()
    local controlledCount = 0
    for _ in pairs(Network.ControlledParts) do
        controlledCount = controlledCount + 1
    end
    
    local targetDistance = "N/A"
    if Msproject_Config.Target and Msproject_Config.Target.Character then
        local targetRoot = Msproject_Config.Target.Character:FindFirstChild("HumanoidRootPart")
        local playerRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot and playerRoot then
            targetDistance = math.floor((targetRoot.Position - playerRoot.Position).Magnitude) .. " studs"
        end
    end
    
    StatsDisplay.Text = string.format(
        "🔧 Parts Controlled: %d\n📏 Range: %d\n⚡ Status: %s\n🎯 Target Distance: %s\nrhyan57",
        controlledCount,
        Msproject_Config.Range,
        Msproject_Config.Enabled and "Active" or "Ready",
        targetDistance
    )
end

local function updatePartPosition(part, targetPosition)
    local direction = (targetPosition - part.Position)
    local distance = direction.Magnitude
    
    if distance > 2 then
        direction = direction.Unit
        local velocity = direction * math.min(Msproject_Config.Power, distance * 15)
        part.Velocity = velocity
        part.AssemblyLinearVelocity = velocity
    else
        part.Velocity = Vector3.new(0, 0, 0)
        part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        part.Position = targetPosition
    end
end

local minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame:TweenSize(UDim2.new(0, 320, 0, 40), "Out", "Quad", 0.3, true)
        MinimizeButton.Text = "+"
        ContentFrame.Visible = false
    else
        MainFrame:TweenSize(UDim2.new(0, 320, 0, 400), "Out", "Quad", 0.3, true)
        MinimizeButton.Text = "−"
        ContentFrame.Visible = true
    end
    playSound("12221967")
end)

TargetInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local target = findTarget(TargetInput.Text)
        if target and target ~= LocalPlayer then
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
                Text = target == LocalPlayer and "Cannot target yourself!" or "Player not found!",
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
    ToggleButton.Text = Msproject_Config.Enabled and "🟢 ENABLED" or "🔴 DISABLED"
    ToggleButton.BackgroundColor3 = Msproject_Config.Enabled and 
        Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    
    playSound("12221967")
end)

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
        PowerLabel.Text = "⚡ Power: " .. Msproject_Config.Power
    end
end)

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

local lastPull = 0
local heartbeatConnection
heartbeatConnection = RunService.Heartbeat:Connect(function()
    if not Msproject_Config.Enabled or not Msproject_Config.Target then 
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
    
    local currentTime = tick()
    if currentTime - lastPull >= Msproject_Config.PullDelay then
        lastPull = currentTime
        
        for part in pairs(Network.ControlledParts) do
            if (part.Position - targetRoot.Position).Magnitude > Msproject_Config.Range then
                releasePartOwnership(part)
            end
        end
        
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") 
               and not part.Anchored 
               and not part:IsDescendantOf(LocalPlayer.Character)
               and not part:IsDescendantOf(targetChar)
               and not part.Parent:IsA("Accessory")
               and part.Parent.Name ~= "Handle"
               and (part.Position - targetRoot.Position).Magnitude <= Msproject_Config.Range 
               and not Network.ControlledParts[part] then
                
                local isPlayerPart = false
                for _, player in pairs(Players:GetPlayers()) do
                    if player.Character and part:IsDescendantOf(player.Character) then
                        isPlayerPart = true
                        break
                    end
                end
                
                if not isPlayerPart then
                    updatePartOwnership(part)
                end
            end
        end
    end
    
    for part in pairs(Network.ControlledParts) do
        if part.Parent then
            updatePartPosition(part, targetRoot.Position)
        else
            Network.ControlledParts[part] = nil
        end
    end
    
    updateStatsDisplay()
end)

RunService.Stepped:Connect(function()
    sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
end)

StarterGui:SetCore("SendNotification", {
    Title = "Script Loaded!",
    Text = "Player Sniper V4 is ready to use",
    Duration = 5
})

local function SendChatMessage(message)
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local textChannel = TextChatService.TextChannels.RBXGeneral
        textChannel:SendAsync(message)
    else
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
    end
end

SendChatMessage("Opa glr! ")
