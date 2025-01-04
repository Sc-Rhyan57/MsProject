-- MSproject Notification API v2.0.0

getgenv().MSproject = getgenv().MSproject or {}
MSproject.NotificationConfig = {
    Theme = {
        Light = {
            Background = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 240, 240))
            }),
            Text = Color3.fromRGB(50, 50, 50)
        },
        Dark = {
            Background = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 35)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 30))
            }),
            Text = Color3.fromRGB(255, 255, 255)
        }
    },
    Types = {
        success = {
            gradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(29, 185, 84)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 160, 72))
            }),
            icon = "rbxassetid://7733715400",
            sound = "rbxassetid://6518811702"
        },
        error = {
            gradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 61, 61)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 52, 52))
            }),
            icon = "rbxassetid://7733715400",
            sound = "rbxassetid://6518811702"
        },
        info = {
            gradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(64, 156, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 135, 220))
            }),
            icon = "rbxassetid://7733715400",
            sound = "rbxassetid://6518811702"
        },
        warning = {
            gradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 184, 48)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 159, 41))
            }),
            icon = "rbxassetid://7733715400",
            sound = "rbxassetid://6518811702"
        }
    },
    Settings = {
        DisplayTime = 5,
        MaxNotifications = 5,
        Padding = 10,
        Width = 300,
        Height = 80,
        CornerRadius = UDim.new(0, 10),
        Position = "TopRight",
        Theme = "Dark",
        EnableSounds = true,
        Volume = 0.5
    }
}

local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

local TweenService = game:GetService("TweenService")

local function createTween(object, info, properties)
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function createButton(text, callback, colors)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 80, 0, 25)
    button.BackgroundColor3 = colors.default or Color3.fromRGB(70, 70, 75)
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    button.AutoButtonColor = false

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    button.MouseEnter:Connect(function()
        createTween(button, TweenInfo.new(0.3), {
            BackgroundColor3 = colors.hover or Color3.fromRGB(80, 80, 85)
        })
    end)

    button.MouseLeave:Connect(function()
        createTween(button, TweenInfo.new(0.3), {
            BackgroundColor3 = colors.default or Color3.fromRGB(70, 70, 75)
        })
    end)

    button.MouseButton1Click:Connect(function()
        createTween(button, TweenInfo.new(0.1), {
            BackgroundColor3 = colors.click or Color3.fromRGB(60, 60, 65)
        }).Completed:Wait()
        
        createTween(button, TweenInfo.new(0.1), {
            BackgroundColor3 = colors.default or Color3.fromRGB(70, 70, 75)
        })
        
        if callback then
            callback()
        end
    end)

    return button
end

local function getNotificationPosition()
    local position = MSproject.NotificationConfig.Settings.Position
    local offset = MSproject.NotificationConfig.Settings.Padding
    local width = MSproject.NotificationConfig.Settings.Width
    local height = MSproject.NotificationConfig.Settings.Height

    local positions = {
        TopRight = UDim2.new(1, -(width + offset), 0, offset),
        TopLeft = UDim2.new(0, offset, 0, offset),
        BottomRight = UDim2.new(1, -(width + offset), 1, -(height + offset)),
        BottomLeft = UDim2.new(0, offset, 1, -(height + offset))
    }

    return positions[position] or positions.TopRight
end

local activeNotifications = {}

local function createNotification(title, message, options)
    local notification = {}
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "MSprojectNotification"
    gui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, MSproject.NotificationConfig.Settings.Width, 0, MSproject.NotificationConfig.Settings.Height)
    mainFrame.Position = getNotificationPosition()
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = MSproject.NotificationConfig.Settings.CornerRadius
    corner.Parent = mainFrame
    
    local blur = Instance.new("BlurEffect")
    blur.Size = 10
    blur.Parent = game:GetService("Lighting")
    
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 45
    gradient.Color = MSproject.NotificationConfig.Types[options.type].gradient
    gradient.Parent = mainFrame
    
    local gradientTween = TweenService:Create(gradient, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
        Offset = Vector2.new(1, 0)
    })
    gradientTween:Play()
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -20)
    content.Position = UDim2.new(0, 10, 0, 10)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -30, 0, 25)
    titleLabel.Position = UDim2.new(0, 30, 0, 0)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = MSproject.NotificationConfig.Theme[MSproject.NotificationConfig.Settings.Theme].Text
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = content
    
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0, 0, 0, 2)
    icon.Image = MSproject.NotificationConfig.Types[options.type].icon
    icon.ImageColor3 = MSproject.NotificationConfig.Theme[MSproject.NotificationConfig.Settings.Theme].Text
    icon.BackgroundTransparency = 1
    icon.Parent = content
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, 0, 1, -35)
    messageLabel.Position = UDim2.new(0, 0, 0, 30)
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.Text = message
    messageLabel.TextColor3 = MSproject.NotificationConfig.Theme[MSproject.NotificationConfig.Settings.Theme].Text
    messageLabel.TextSize = 14
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.BackgroundTransparency = 1
    messageLabel.Parent = content
    
    if options.buttons then
        local buttonHolder = Instance.new("Frame")
        buttonHolder.Size = UDim2.new(1, 0, 0, 30)
        buttonHolder.Position = UDim2.new(0, 0, 1, -30)
        buttonHolder.BackgroundTransparency = 1
        buttonHolder.Parent = content
        
        local buttonLayout = Instance.new("UIListLayout")
        buttonLayout.FillDirection = Enum.FillDirection.Horizontal
        buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        buttonLayout.Padding = UDim.new(0, 10)
        buttonLayout.Parent = buttonHolder
        
        for _, buttonInfo in ipairs(options.buttons) do
            local btn = createButton(buttonInfo.text, buttonInfo.callback, buttonInfo.colors or {})
            btn.Parent = buttonHolder
        end
    end
    
    if MSproject.NotificationConfig.Settings.EnableSounds and options.playSound ~= false then
        local sound = Instance.new("Sound")
        sound.SoundId = MSproject.NotificationConfig.Types[options.type].sound
        sound.Volume = MSproject.NotificationConfig.Settings.Volume
        sound.Parent = gui
        sound:Play()
    end

    local function animateIn()
        local startPos = mainFrame.Position + UDim2.new(0, MSproject.NotificationConfig.Settings.Width + 50, 0, 0)
        mainFrame.Position = startPos
        createTween(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = getNotificationPosition()
        })
    end

    local function animateOut()
        return createTween(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = mainFrame.Position + UDim2.new(0, MSproject.NotificationConfig.Settings.Width + 50, 0, 0)
        })
    end
    
    notification.gui = gui
    notification.frame = mainFrame
    notification.blur = blur
    notification.animateIn = animateIn
    notification.animateOut = animateOut
    
    return notification
end

function NotificationSystem:Init()
    local system = setmetatable({}, NotificationSystem)
    system.notifications = {}
    return system
end

function NotificationSystem:Show(title, message, options)
    options = options or {}
    options.type = options.type or "info"

    while #activeNotifications >= MSproject.NotificationConfig.Settings.MaxNotifications do
        local oldest = table.remove(activeNotifications, 1)
        oldest.animateOut().Completed:Wait()
        oldest.gui:Destroy()
        if oldest.blur then
            oldest.blur:Destroy()
        end
    end

    local notification = createNotification(title, message, options)
    
    local player = game.Players.LocalPlayer
    if player then
        notification.gui.Parent = player.PlayerGui
    end
    
    notification.animateIn()
    table.insert(activeNotifications, notification)
    
    if options.duration ~= 0 then
        local duration = options.duration or MSproject.NotificationConfig.Settings.DisplayTime
        task.delay(duration, function()
            local index = table.find(activeNotifications, notification)
            if index then
                table.remove(activeNotifications, index)
                notification.animateOut().Completed:Wait()
                notification.gui:Destroy()
                if notification.blur then
                    notification.blur:Destroy()
                end
            end
        end)
    end
    
    return notification
end

getgenv().MSNotify = function(title, message, options)
    local system = NotificationSystem:Init()
    return system:Show(title, message, options)
end

getgenv().MSNotifyConfig = function(settings)
    for key, value in pairs(settings) do
        MSproject.NotificationConfig.Settings[key] = value
    end
end

return NotificationSystem
