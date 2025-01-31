-- Advanced Modern Music Player
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local MusicPlayer = {}

-- Ultra-Modern Configuration
MusicPlayer.Config = {
    MusicLibraryUrl = "https://your-github-raw-json-link",
    DefaultErrorImage = "rbxassetid://YOUR_ERROR_IMAGE_ID",
    Theme = {
        PrimaryColor = Color3.fromRGB(33, 150, 243),  -- Modern Blue
        SecondaryColor = Color3.fromRGB(0, 230, 118)  -- Vibrant Green
    }
}

-- Advanced Error Handling System
local function SafeHttpGet(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        warn("[MusicPlayer] Failed to fetch URL: " .. tostring(url))
        return nil
    end
    return result
end

-- Image and Asset Management
local function GetGitImageID(githubLink, imageName)
    local fileName = "customObject_Image_" .. tostring(imageName) .. ".png"
    
    local imageData = SafeHttpGet(githubLink)
    if not imageData then
        warn("Falha ao baixar imagem: " .. tostring(githubLink))
        return nil
    end
    
    writefile(fileName, imageData)
    return (getcustomasset or getsynasset)(fileName)
end

-- URL Music Loader
function MusicPlayer:LoadMusicFromURL(url)
    -- Validate URL
    if not url or url == "" then
        self:ShowErrorNotification("URL inválida")
        return nil
    end
    
    local audioData = SafeHttpGet(url)
    if not audioData then
        self:ShowErrorNotification("Erro ao carregar música")
        return nil
    end
    
    local fileName = "temp_music_" .. HttpService:GenerateGUID(false) .. ".mp3"
    writefile(fileName, audioData)
    
    return (getcustomasset or getsynasset)(fileName)
end

-- Ultra Modern Neon UI Creation
function MusicPlayer:CreateModernUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Clean Previous UI
    local existingUI = playerGui:FindFirstChild("ModernMusicPlayer")
    if existingUI then existingUI:Destroy() end
    
    -- Main Screen GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ModernMusicPlayer"
    screenGui.Parent = playerGui
    
    -- Main Frame with Gradient Background
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
    mainFrame.Position = UDim2.new(0.2, 0, 0.15, 0)
    mainFrame.BackgroundColor3 = MusicPlayer.Config.Theme.PrimaryColor
    mainFrame.BorderSizePixel = 0
    
    -- Gradient Effect
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, MusicPlayer.Config.Theme.PrimaryColor),
        ColorSequenceKeypoint.new(1, MusicPlayer.Config.Theme.SecondaryColor)
    })
    gradient.Rotation = 45
    gradient.Parent = mainFrame
    
    -- Corner Radius
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0.05, 0)
    cornerRadius.Parent = mainFrame
    
    -- URL Input Section
    local urlInput = Instance.new("TextBox")
    urlInput.Size = UDim2.new(0.7, 0, 0.1, 0)
    urlInput.Position = UDim2.new(0.15, 0, 0.1, 0)
    urlInput.PlaceholderText = "Cole a URL da música aqui..."
    urlInput.Parent = mainFrame
    
    -- Search Button
    local searchButton = Instance.new("TextButton")
    searchButton.Size = UDim2.new(0.2, 0, 0.1, 0)
    searchButton.Position = UDim2.new(0.4, 0, 0.25, 0)
    searchButton.Text = "Buscar"
    searchButton.BackgroundColor3 = Color3.fromRGB(0, 230, 118)
    searchButton.Parent = mainFrame
    
    -- Album Cover Image
    local albumCover = Instance.new("ImageLabel")
    albumCover.Size = UDim2.new(0.4, 0, 0.4, 0)
    albumCover.Position = UDim2.new(0.3, 0, 0.4, 0)
    albumCover.BackgroundTransparency = 1
    albumCover.Image = MusicPlayer.Config.DefaultErrorImage
    albumCover.Parent = mainFrame
    
    -- Neon Effect
    local neonEffect = Instance.new("UIStroke")
    neonEffect.Color = Color3.fromRGB(255, 255, 255)
    neonEffect.Thickness = 3
    neonEffect.Transparency = 0.5
    neonEffect.Parent = albumCover
    
    -- Music Control Buttons
    local playButton = Instance.new("TextButton")
    playButton.Size = UDim2.new(0.2, 0, 0.1, 0)
    playButton.Position = UDim2.new(0.4, 0, 0.85, 0)
    playButton.Text = "▶ Play"
    playButton.BackgroundColor3 = Color3.fromRGB(0, 230, 118)
    playButton.Parent = mainFrame
    
    -- Error Notification System
    function MusicPlayer:ShowErrorNotification(message)
        local notification = Instance.new("TextLabel")
        notification.Size = UDim2.new(0.6, 0, 0.1, 0)
        notification.Position = UDim2.new(0.2, 0, 0.9, 0)
        notification.Text = message
        notification.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        notification.TextColor3 = Color3.fromRGB(255, 255, 255)
        notification.Parent = mainFrame
        
        game.Debris:AddItem(notification, 3)
    end
    
    -- Play Music from URL
    searchButton.MouseButton1Click:Connect(function()
        local musicUrl = urlInput.Text
        local musicId = self:LoadMusicFromURL(musicUrl)
        
        if musicId then
            local sound = Instance.new("Sound")
            sound.SoundId = musicId
            sound.Parent = workspace
            sound:Play()
        end
    end)
    
    mainFrame.Parent = screenGui
    return screenGui
end

-- Initialization
function MusicPlayer:Init()
    local player = Players.LocalPlayer
    if not player then
        Players.PlayerAdded:Wait()
    end
    
    -- Validate Configuration
    if not MusicPlayer.Config.MusicLibraryUrl or 
       not MusicPlayer.Config.DefaultErrorImage then
        warn("[MusicPlayer] Configuração incompleta!")
        return
    end
    
    self:CreateModernUI()
end

return MusicPlayer
