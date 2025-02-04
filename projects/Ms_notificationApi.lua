-- MSproject Notification API v2.0.1 (modificado)

getgenv().MSproject = getgenv().MSproject or {}
MSproject.NotificationConfig.Settings.StackedOffset = 90 -- Espaço entre notificações empilhadas

local activeNotifications = {}

local function getNotificationPosition(index)
    local settings = MSproject.NotificationConfig.Settings
    local offset = settings.Padding + (index - 1) * settings.StackedOffset
    local width = settings.Width
    local height = settings.Height

    local positions = {
        TopRight = UDim2.new(1, -(width + settings.Padding), 0, offset),
        TopLeft = UDim2.new(0, settings.Padding, 0, offset),
        BottomRight = UDim2.new(1, -(width + settings.Padding), 1, -(height + offset)),
        BottomLeft = UDim2.new(0, settings.Padding, 1, -(height + offset))
    }

    return positions[settings.Position] or positions.TopRight
end

local function createNotification(title, message, options)
    options = options or {}
    local notification = {}

    local gui = Instance.new("ScreenGui")
    gui.Name = "MSprojectNotification"
    gui.ResetOnSpawn = false

    local index = #activeNotifications + 1
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, MSproject.NotificationConfig.Settings.Width, 0, MSproject.NotificationConfig.Settings.Height)
    mainFrame.Position = getNotificationPosition(index)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = MSproject.NotificationConfig.Settings.CornerRadius
    corner.Parent = mainFrame

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 45
    gradient.Color = MSproject.NotificationConfig.Types[options.type].gradient
    gradient.Parent = mainFrame

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

    if options.image then
        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Size = UDim2.new(0, 50, 0, 50)
        imageLabel.Position = UDim2.new(0, -60, 0.5, -25)
        imageLabel.Image = options.image
        imageLabel.BackgroundTransparency = 1
        imageLabel.Parent = content
    end

    if MSproject.NotificationConfig.Settings.EnableSounds and options.playSound ~= false then
        local sound = Instance.new("Sound")
        sound.SoundId = MSproject.NotificationConfig.Types[options.type].sound
        sound.Volume = MSproject.NotificationConfig.Settings.Volume
        sound.Parent = gui
        sound:Play()
    end

    local function animateIn()
        mainFrame.Position = getNotificationPosition(index) + UDim2.new(0, 300, 0, 0)
        local tween = game:GetService("TweenService"):Create(mainFrame, TweenInfo.new(0.5), { Position = getNotificationPosition(index) })
        tween:Play()
    end

    local function animateOut()
        local tween = game:GetService("TweenService"):Create(mainFrame, TweenInfo.new(0.5), { Position = mainFrame.Position + UDim2.new(0, 300, 0, 0) })
        tween:Play()
        return tween
    end

    notification.gui = gui
    notification.frame = mainFrame
    notification.animateIn = animateIn
    notification.animateOut = animateOut

    return notification
end

function NotificationSystem:Show(title, message, options)
    while #activeNotifications >= MSproject.NotificationConfig.Settings.MaxNotifications do
        local oldest = table.remove(activeNotifications, 1)
        oldest.animateOut().Completed:Wait()
        oldest.gui:Destroy()
    end

    local notification = createNotification(title, message, options)
    local player = game.Players.LocalPlayer
    if player then
        notification.gui.Parent = player.PlayerGui
    end

    table.insert(activeNotifications, notification)
    notification.animateIn()

    if options.duration ~= 0 then
        task.delay(options.duration or MSproject.NotificationConfig.Settings.DisplayTime, function()
            local index = table.find(activeNotifications, notification)
            if index then
                table.remove(activeNotifications, index)
                notification.animateOut().Completed:Wait()
                notification.gui:Destroy()
            end
        end)
    end
end

getgenv().MSNotify = function(title, message, options)
    local system = NotificationSystem:Init()
    return system:Show(title, message, options)
end
