-- MSproject Notification API v2.0.0

-- MSproject Notification API v2.2.0 (Corrigido)

getgenv().MSproject = getgenv().MSproject or {}
MSproject.NotificationConfig = {
    Settings = {
        DisplayTime = 5,
        MaxNotifications = 5,
        Padding = 10,
        Width = 300,
        Height = 80,
        Position = "TopRight", -- Pode ser: "TopRight", "TopLeft", "BottomRight", "BottomLeft"
        Theme = "Dark",
        EnableSounds = true,
        Volume = 0.5
    }
}

local TweenService = game:GetService("TweenService")
local activeNotifications = {}

local function getStartPosition()
    local settings = MSproject.NotificationConfig.Settings
    local pos = settings.Position
    local xOffset = settings.Width + settings.Padding
    local yOffset = settings.Padding + (#activeNotifications * (settings.Height + 5))

    local positions = {
        TopRight = UDim2.new(1, xOffset, 0, yOffset),
        TopLeft = UDim2.new(0, -xOffset, 0, yOffset),
        BottomRight = UDim2.new(1, xOffset, 1, -yOffset - settings.Height),
        BottomLeft = UDim2.new(0, -xOffset, 1, -yOffset - settings.Height)
    }

    return positions[pos] or positions.TopRight
end

local function getFinalPosition()
    local settings = MSproject.NotificationConfig.Settings
    local pos = settings.Position
    local yOffset = settings.Padding + (#activeNotifications * (settings.Height + 5))

    local positions = {
        TopRight = UDim2.new(1, -settings.Width - settings.Padding, 0, yOffset),
        TopLeft = UDim2.new(0, settings.Padding, 0, yOffset),
        BottomRight = UDim2.new(1, -settings.Width - settings.Padding, 1, -yOffset - settings.Height),
        BottomLeft = UDim2.new(0, settings.Padding, 1, -yOffset - settings.Height)
    }

    return positions[pos] or positions.TopRight
end

local function createNotification(title, message, options)
    options = options or {}
    options.type = options.type or "info"

    local gui = Instance.new("ScreenGui")
    gui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, MSproject.NotificationConfig.Settings.Width, 0, MSproject.NotificationConfig.Settings.Height)
    mainFrame.Position = getStartPosition() -- Posição inicial corrigida
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.Parent = gui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0, 25)
    titleLabel.Position = UDim2.new(0, 5, 0, 5)
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Parent = mainFrame

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -10, 1, -35)
    messageLabel.Position = UDim2.new(0, 5, 0, 30)
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.TextWrapped = true
    messageLabel.Parent = mainFrame

    -- Animação corrigida para surgir do lado correto
    local tween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = getFinalPosition()
    })
    tween:Play()

    table.insert(activeNotifications, mainFrame)

    -- Remover notificação após o tempo definido
    task.delay(MSproject.NotificationConfig.Settings.DisplayTime, function()
        table.remove(activeNotifications, table.find(activeNotifications, mainFrame))
        mainFrame:Destroy()
        gui:Destroy()
    end)

    return mainFrame
end

getgenv().MSNotify = function(title, message, options)
    return createNotification(title, message, options)
end

return createNotification
