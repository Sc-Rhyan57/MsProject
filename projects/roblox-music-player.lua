local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MusicPlayer = {}

-- Configuração
MusicPlayer.Config = {
    MusicLibraryUrl = "https://raw.githubusercontent.com/Sc-Rhyan57/MsProject/refs/heads/main/projects/data/Library/music.json",
    PlaylistFolder = "msproject/data/playlists/",
    DefaultErrorImage = "rbxassetid://YOUR_ERROR_IMAGE",
    Themes = {
        Dark = {
            Background = Color3.fromRGB(18, 18, 18),
            PrimaryText = Color3.fromRGB(255, 255, 255),
            SecondaryText = Color3.fromRGB(179, 179, 179),
            Accent = Color3.fromRGB(29, 185, 84)
        }
    }
}

-- Notificação avançada
function MusicPlayer:ShowNotification(message, type)
    local player = Players.LocalPlayer
    local playerGui = player:FindFirstChild("PlayerGui") or Instance.new("ScreenGui", player)
    
    local notification = Instance.new("Frame", playerGui)
    notification.Size = UDim2.new(0.3, 0, 0.1, 0)
    notification.Position = UDim2.new(0.35, 0, 0.1, 0)
    notification.BackgroundColor3 = type == "error" and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(29, 185, 84)
    
    local notificationText = Instance.new("TextLabel", notification)
    notificationText.Size = UDim2.new(1, 0, 1, 0)
    notificationText.Text = message
    notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    game.Debris:AddItem(notification, 3)
end

-- Carregar capas de álbuns
function MusicPlayer:LoadAlbumCover(imageUrl, imageName)
    if not imageUrl then return self.Config.DefaultErrorImage end
    local fileName = "album_cover_" .. tostring(imageName) .. ".png"

    local success, imageData = pcall(function()
        return game:HttpGet(imageUrl)
    end)

    if not success then
        self:ShowNotification("Erro ao carregar a capa", "error")
        return self.Config.DefaultErrorImage
    end

    writefile(fileName, imageData)
    return (getcustomasset or getsynasset)(fileName)
end

-- Criar a UI do player
function MusicPlayer:CreateMusicPlayer(musicLibrary)
    local player = Players.LocalPlayer
    local playerGui = player:FindFirstChild("PlayerGui") or Instance.new("ScreenGui", player)
    
    local mainFrame = Instance.new("Frame", playerGui)
    mainFrame.Size = UDim2.new(1, 0, 0.2, 0)
    mainFrame.Position = UDim2.new(0, 0, 0.8, 0)
    mainFrame.BackgroundColor3 = self.Config.Themes.Dark.Background
    
    -- Criar botão de Playlist
    local playlistButton = Instance.new("TextButton", mainFrame)
    playlistButton.Size = UDim2.new(0.1, 0, 0.2, 0)
    playlistButton.Position = UDim2.new(0.9, 0, 0, 0)
    playlistButton.Text = "📜"
    playlistButton.BackgroundColor3 = self.Config.Themes.Dark.Accent

    playlistButton.MouseButton1Click:Connect(function()
        self:ShowNotification("Abrindo playlists...", "info")
        self:OpenPlaylistUI()
    end)
    
    -- Criar lista de músicas
    local musicListFrame = Instance.new("ScrollingFrame", mainFrame)
    musicListFrame.Size = UDim2.new(1, 0, 1, 0)
    musicListFrame.CanvasSize = UDim2.new(#musicLibrary.library * 0.2, 0, 1, 0)

    local currentSound = nil
    for i, track in ipairs(musicLibrary.library) do
        local trackButton = Instance.new("ImageButton", musicListFrame)
        trackButton.Size = UDim2.new(0.2, 0, 1, 0)
        trackButton.Position = UDim2.new((i - 1) * 0.2, 0, 0, 0)
        trackButton.Image = self:LoadAlbumCover(track.imageUrl, track.name)

        trackButton.MouseButton1Click:Connect(function()
            if currentSound then currentSound:Stop() end
            currentSound = Instance.new("Sound", workspace)
            currentSound.SoundId = track.audioUrl
            currentSound.Volume = 0.5
            currentSound:Play()
            self:ShowNotification("Tocando: " .. track.name, "info")
        end)
    end
end

-- Criar sistema de playlists
function MusicPlayer:SavePlaylist(playlistName, tracks)
    local path = self.Config.PlaylistFolder .. playlistName .. ".json"
    local data = HttpService:JSONEncode({playlist = tracks})
    writefile(path, data)
end

function MusicPlayer:LoadPlaylist(playlistName)
    local path = self.Config.PlaylistFolder .. playlistName .. ".json"
    if not isfile(path) then
        self:ShowNotification("Playlist não encontrada", "error")
        return nil
    end
    return HttpService:JSONDecode(readfile(path))
end

function MusicPlayer:OpenPlaylistUI()
    local player = Players.LocalPlayer
    local playerGui = player:FindFirstChild("PlayerGui") or Instance.new("ScreenGui", player)

    local playlistFrame = Instance.new("Frame", playerGui)
    playlistFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
    playlistFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
    playlistFrame.BackgroundColor3 = self.Config.Themes.Dark.Background

    local closeButton = Instance.new("TextButton", playlistFrame)
    closeButton.Size = UDim2.new(0.1, 0, 0.1, 0)
    closeButton.Position = UDim2.new(0.9, 0, 0, 0)
    closeButton.Text = "❌"
    
    closeButton.MouseButton1Click:Connect(function()
        playlistFrame:Destroy()
    end)

    -- Listar playlists
    local playlistList = Instance.new("ScrollingFrame", playlistFrame)
    playlistList.Size = UDim2.new(1, 0, 0.9, 0)
    
    for _, file in pairs(listfiles(self.Config.PlaylistFolder)) do
        local playlistName = file:match("([^/]+)%.json$")
        local button = Instance.new("TextButton", playlistList)
        button.Text = playlistName
        button.Size = UDim2.new(1, 0, 0.1, 0)
        
        button.MouseButton1Click:Connect(function()
            local playlistData = self:LoadPlaylist(playlistName)
            if playlistData then
                self:CreateMusicPlayer(playlistData)
            end
        end)
    end
end

-- Inicialização
function MusicPlayer:Init()
    local success, musicLibrary = pcall(function()
        local data = game:HttpGet(self.Config.MusicLibraryUrl)
        return HttpService:JSONDecode(data)
    end)

    if not success then
        self:ShowNotification("Erro ao carregar a biblioteca", "error")
        return
    end

    self:CreateMusicPlayer(musicLibrary)
end

return MusicPlayer
