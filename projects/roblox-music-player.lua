-- Advanced Spotify-like Music Player V3
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MusicPlayer = {}

-- Enhanced Configuration
MusicPlayer.Config = {
    MusicLibraryUrl = "https://raw.githubusercontent.com/Sc-Rhyan57/MsProject/refs/heads/main/projects/data/Library/music.json",
    DefaultErrorImage = "rbxassetid://YOUR_ERROR_IMAGE",
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

-- Advanced Notification System
function MusicPlayer:ShowNotification(message, type)
    local player = Players.LocalPlayer
    local playerGui = player.PlayerGui
    
    local notificationContainer = playerGui:FindFirstChild("NotificationContainer") or 
        Instance.new("ScreenGui", playerGui)
    notificationContainer.Name = "NotificationContainer"
    
    local notification = Instance.new("Frame", notificationContainer)
    notification.Size = UDim2.new(0.3, 0, 0.1, 0)
    notification.Position = UDim2.new(0.35, 0, 0.1, 0)
    notification.BackgroundColor3 = type == "error" and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(29, 185, 84)
    notification.BackgroundTransparency = 0.2
    
    local notificationText = Instance.new("TextLabel", notification)
    notificationText.Size = UDim2.new(1, 0, 1, 0)
    notificationText.Text = message
    notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notificationText.BackgroundTransparency = 1
    
    local corner = Instance.new("UICorner", notification)
    corner.CornerRadius = UDim.new(0.1, 0)
    
    game.Debris:AddItem(notification, 3)
end

-- Advanced Image and Asset Management
function MusicPlayer:LoadAlbumCover(imageUrl, imageName)
    if not imageUrl then return self.Config.DefaultErrorImage end
    
    local fileName = "album_cover_" .. tostring(imageName) .. ".png"
    
    local success, imageData = pcall(function()
        return game:HttpGet(imageUrl)
    end)
    
    if not success then
        self:ShowNotification("Failed to load album cover", "error")
        return self.Config.DefaultErrorImage
    end
    
    writefile(fileName, imageData)
    return (getcustomasset or getsynasset)(fileName)
end

-- Enhanced Music Player with Advanced Controls
function MusicPlayer:CreateMusicPlayer(musicLibrary)
    local player = Players.LocalPlayer
    local playerGui = player.PlayerGui
    
    -- Create Main Music Player UI
    local musicPlayerGui = Instance.new("ScreenGui", playerGui)
    musicPlayerGui.Name = "SpotifyLikeMusicPlayer"
    
    local mainFrame = Instance.new("Frame", musicPlayerGui)
    mainFrame.Size = UDim2.new(1, 0, 0.2, 0)
    mainFrame.Position = UDim2.new(0, 0, 0.8, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    
    -- Music Library List
    local musicListFrame = Instance.new("ScrollingFrame", mainFrame)
    musicListFrame.Size = UDim2.new(1, 0, 1, 0)
    musicListFrame.BackgroundTransparency = 1
    musicListFrame.ScrollBarThickness = 5
    musicListFrame.CanvasSize = UDim2.new(#musicLibrary.library * 0.2, 0, 1, 0)
    
    -- Current Playing Track
    local currentSound = nil
    local currentTrack = nil
    
    -- Create Music Track Buttons
    for i, track in ipairs(musicLibrary.library) do
        local trackButton = Instance.new("ImageButton", musicListFrame)
        trackButton.Size = UDim2.new(0.2, 0, 1, 0)
        trackButton.Position = UDim2.new((i-1)*0.2, 0, 0, 0)
        trackButton.Image = self:LoadAlbumCover(track.imageUrl, track.name)
        
        trackButton.MouseButton1Click:Connect(function()
            -- Stop previous track
            if currentSound then
                currentSound:Stop()
            end
            
            -- Create and play new track
            currentSound = Instance.new("Sound", workspace)
            currentSound.SoundId = track.audioUrl
            currentSound.Volume = 0.5
            currentSound:Play()
            
            currentTrack = track
            
            -- Update UI to show current track
            self:ShowNotification("Now Playing: " .. track.name, "info")
        end)
    end
    
    -- Minimize/Maximize Button
    local minimizeButton = Instance.new("TextButton", mainFrame)
    minimizeButton.Size = UDim2.new(0.1, 0, 0.2, 0)
    minimizeButton.Position = UDim2.new(0.9, 0, 0, 0)
    minimizeButton.Text = "➖"
    minimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    
    local isMinimized = false
    minimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        
        local targetSize = isMinimized and UDim2.new(1, 0, 0.1, 0) or UDim2.new(1, 0, 0.2, 0)
        local targetPosition = isMinimized and UDim2.new(0, 0, 0.9, 0) or UDim2.new(0, 0, 0.8, 0)
        
        local sizeTween = TweenService:Create(mainFrame, TweenInfo.new(0.3), {
            Size = targetSize,
            Position = targetPosition
        })
        sizeTween:Play()
        
        minimizeButton.Text = isMinimized and "➕" or "➖"
    end)
    
    return musicPlayerGui
end

-- Initialization Function
function MusicPlayer:Init()
    local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
    
    -- Validate Configuration
    if not self.Config.MusicLibraryUrl then
        self:ShowNotification("Incomplete Configuration!", "error")
        return
    end
    
    -- Load Music Library with Error Handling
    local success, musicLibrary = pcall(function()
        local libraryData = game:HttpGet(self.Config.MusicLibraryUrl)
        return HttpService:JSONDecode(libraryData)
    end)
    
    if not success then
        self:ShowNotification("Failed to load music library", "error")
        return
    end
    
    -- Create Music Player UI
    local musicPlayerGui = self:CreateMusicPlayer(musicLibrary)
    
    -- Optional: Startup Sound
    local startupSound = Instance.new("Sound", player.Character)
    startupSound.SoundId = self.Config.Sounds.Startup
    startupSound.Volume = 0.5
    startupSound:Play()
end

return MusicPlayer
