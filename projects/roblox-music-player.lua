-- Advanced Modern Music Player V2

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local MusicPlayer = {}

-- Advanced Configuration
MusicPlayer.Config = {
    MusicLibraryUrl = "https://raw.githubusercontent.com/Sc-Rhyan57/MsProject/refs/heads/main/projects/data/Library/music.json",
    DefaultErrorImage = "rbxassetid://YOUR_ERRO",
    Themes = {
        Dark = {
            Background = Color3.fromRGB(18, 18, 18),
            PrimaryText = Color3.fromRGB(255, 255, 255),
            SecondaryText = Color3.fromRGB(179, 179, 179),
            Accent = Color3.fromRGB(29, 185, 84)
        }
    },
    Sounds = {
        Startup = "rbxassetid://4590662766",
        ButtonClick = "rbxassetid://12221967"
    }
}

-- Advanced Error and Notification System
function MusicPlayer:ShowNotification(message, type)
    local player = Players.LocalPlayer
    local playerGui = player.PlayerGui
    
    -- Create or find notification container
    local notificationContainer = playerGui:FindFirstChild("NotificationContainer")
    if not notificationContainer then
        notificationContainer = Instance.new("ScreenGui")
        notificationContainer.Name = "NotificationContainer"
        notificationContainer.Parent = playerGui
    end
    
    -- Create notification
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0.3, 0, 0.1, 0)
    notification.Position = UDim2.new(0.35, 0, 0.1, 0)
    notification.BackgroundColor3 = type == "error" and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(29, 185, 84)
    notification.BackgroundTransparency = 0.2
    
    local notificationText = Instance.new("TextLabel")
    notificationText.Size = UDim2.new(1, 0, 1, 0)
    notificationText.Text = message
    notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notificationText.BackgroundTransparency = 1
    notificationText.Parent = notification
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.1, 0)
    corner.Parent = notification
    
    notification.Parent = notificationContainer
    
    -- Auto-remove
    game.Debris:AddItem(notification, 3)
end

-- Advanced Image Management
function MusicPlayer:LoadAlbumCover(imageUrl, imageName)
    if not imageUrl then return self.Config.DefaultErrorImage end
    
    local fileName = "album_cover_" .. tostring(imageName) .. ".png"
    
    local success, imageData = pcall(function()
        return game:HttpGet(imageUrl)
    end)
    
    if not success then
        self:ShowNotification("Falha ao carregar capa", "error")
        return self.Config.DefaultErrorImage
    end
    
    writefile(fileName, imageData)
    return (getcustomasset or getsynasset)(fileName)
end

-- Advanced Sound Management
function MusicPlayer:CreateMusicPlayer(musicData)
    -- Create sound object
    local sound = Instance.new("Sound")
    sound.SoundId = musicData.audioUrl
    sound.Volume = 0.5
    sound.Parent = workspace
    
    -- Mini Player UI
    local player = Players.LocalPlayer
    local playerGui = player.PlayerGui
    
    local miniPlayer = Instance.new("ScreenGui")
    miniPlayer.Name = "MiniMusicPlayer"
    miniPlayer.Parent = playerGui
    
    local miniFrame = Instance.new("Frame")
    miniFrame.Size = UDim2.new(0.3, 0, 0.1, 0)
    miniFrame.Position = UDim2.new(0.35, 0, 0.9, 0)
    miniFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    miniFrame.Parent = miniPlayer
    
    -- Album Cover
    local albumCover = Instance.new("ImageLabel")
    albumCover.Size = UDim2.new(0.2, 0, 1, 0)
    albumCover.Image = self:LoadAlbumCover(musicData.imageUrl, musicData.name)
    albumCover.Parent = miniFrame
    
    -- Play/Pause Button
    local playPauseButton = Instance.new("TextButton")
    playPauseButton.Size = UDim2.new(0.2, 0, 1, 0)
    playPauseButton.Position = UDim2.new(0.2, 0, 0, 0)
    playPauseButton.Text = "❚❚"
    playPauseButton.BackgroundTransparency = 1
    playPauseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    -- Next Button
    local nextButton = Instance.new("TextButton")
    nextButton.Size = UDim2.new(0.2, 0, 1, 0)
    nextButton.Position = UDim2.new(0.4, 0, 0, 0)
    nextButton.Text = "▶▶"
    nextButton.BackgroundTransparency = 1
    nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    playPauseButton.MouseButton1Click:Connect(function()
        if sound.IsPlaying then
            sound:Pause()
            playPauseButton.Text = "▶"
        else
            sound:Play()
            playPauseButton.Text = "❚❚"
        end
    end)
    
    return sound, miniPlayer
end

-- Main UI Creator with Multiple Pages
function MusicPlayer:CreateModernSpotifyUI()
    local player = Players.LocalPlayer
    local playerGui = player.PlayerGui
    
    -- Main ScreenGui
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "SpotifyLikePlayer"
    mainGui.Parent = playerGui
    
    -- Navigation Frame
    local navigationFrame = Instance.new("Frame")
    navigationFrame.Size = UDim2.new(0.2, 0, 1, 0)
    navigationFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    navigationFrame.Parent = mainGui
    
    -- Page Frames
    local pagesFrame = Instance.new("Frame")
    pagesFrame.Size = UDim2.new(0.8, 0, 1, 0)
    pagesFrame.Position = UDim2.new(0.2, 0, 0, 0)
    pagesFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    pagesFrame.Parent = mainGui
    
    -- Navigation Buttons
    local navButtons = {
        {name = "Início", page = "Home"},
        {name = "Buscar", page = "Search"},
        {name = "Playlists", page = "Playlists"},
        {name = "Biblioteca", page = "Library"}
    }
    
    -- Minimize/Maximize Buttons
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0.1, 0, 0.1, 0)
    minimizeButton.Position = UDim2.new(0.9, 0, 0, 0)
    minimizeButton.Text = "-"
    minimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    minimizeButton.Parent = mainGui
    
    local isMinimized = false
    minimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized    
        local tween = TweenService:Create(mainGui, TweenInfo.new(0.3), {
            Size = isMinimized and UDim2.new(0.3, 0, 0.2, 0) or UDim2.new(1, 0, 1, 0)
        })
        tween:Play()
    end)
    
    -- Startup Sound
    local startupSound = Instance.new("Sound")
    startupSound.SoundId = self.Config.Sounds.Startup
    startupSound.Volume = 0.5
    startupSound.Parent = player.Character
    startupSound:Play()
    
    return mainGui
end

-- Initialization Function
function MusicPlayer:Init()
    local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
    
    -- Validate Configuration
    if not self.Config.MusicLibraryUrl or 
       not self.Config.DefaultErrorImage or 
       not self.Config.Sounds.Startup then
        self:ShowNotification("Configuração Incompleta!", "error")
        return
    end
    
    -- Create Modern UI
    local ui = self:CreateModernSpotifyUI()
    
    -- Optional: Load Music Library
    pcall(function()
        local musicLibrary = game:HttpGet(self.Config.MusicLibraryUrl)
        local parsedLibrary = HttpService:JSONDecode(musicLibrary)
        
        -- Example of how to use the library
        if #parsedLibrary.library > 0 then
            local firstSong = parsedLibrary.library[1]
            local sound, miniPlayer = self:CreateMusicPlayer(firstSong)
        end
    end)
end

return MusicPlayer
