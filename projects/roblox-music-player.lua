-- Roblox Advanced Music Player System
local MusicPlayer = {}

-- Configurações Principais com URLs temporárias para placeholder
MusicPlayer.Config = {
    DataPath = "Msproject/data/",
    PlaylistsFolder = "playlists/",
    MusicLibraryUrl = "https://raw.githubusercontent.com/example/music-library/main/library.json",
    LyricsRepositoryUrl = "https://raw.githubusercontent.com/example/lyrics/main/",
    DefaultVideoPlaceholder = "https://example.com/default-video.mp4"
}

-- Serviços do Roblox
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Habilitar HttpService se não estiver ativado
if not HttpService.HttpEnabled then
    HttpService.HttpEnabled = true
end

-- Funções de Utilitário para Manipulação de Arquivos
local function SafeWriteFile(fileName, content)
    local success, err = pcall(function()
        writefile(fileName, content)
    end)
    if not success then
        warn("Erro ao salvar arquivo: " .. tostring(err))
    end
end

local function SafeReadFile(fileName)
    local success, content = pcall(function()
        return readfile(fileName)
    end)
    return success and content or nil
end

-- Funções de Download e Gerenciamento de Mídia
function MusicPlayer:GetGitAudioID(githubLink, soundName)
    local fileName = "customObject_Sound_" .. tostring(soundName) .. ".mp3"
    
    local success, audioData = pcall(function()
        return game:HttpGet(githubLink)
    end)
    
    if not success then
        warn("Falha ao baixar o áudio: " .. tostring(githubLink))
        return nil
    end
    
    SafeWriteFile(fileName, audioData)
    return (getcustomasset or getsynasset)(fileName)
end

function MusicPlayer:PlayGitSound(githubLink, soundName, volume)
    local soundId = self:GetGitAudioID(githubLink, soundName)
    
    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 0.5
        sound.Parent = workspace
        sound:Play()
        
        sound.Ended:Connect(function()
            sound:Destroy()
            pcall(function() delfile("customObject_Sound_" .. tostring(soundName) .. ".mp3") end)
        end)
        
        return sound
    end
    
    return nil
end

-- Modificações para melhorar a robustez
function MusicPlayer:SearchMusic(query)
    local musicLibrary = self:LoadMusicLibrary()
    if not musicLibrary then return {} end
    
    local results = {}
    query = string.lower(query or "")
    
    for _, music in ipairs(musicLibrary) do
        if type(music.name) == "string" and 
           string.lower(music.name):find(query) then
            table.insert(results, music)
        end
    end
    
    return results
end

-- Carregamento da Biblioteca de Músicas com tratamento de erro
function MusicPlayer:LoadMusicLibrary()
    local success, musicLibraryData = pcall(function()
        return game:HttpGet(self.Config.MusicLibraryUrl)
    end)
    
    if success and musicLibraryData then
        local success, musicLibrary = pcall(function()
            return HttpService:JSONDecode(musicLibraryData)
        end)
        
        if success then
            return musicLibrary
        end
    end
    
    warn("Falha ao carregar biblioteca de músicas")
    return {}
end

-- Interface de Usuário Avançada com melhorias
function MusicPlayer:CreateSpotifyLikeUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Verifica se a UI já existe
    if playerGui:FindFirstChild("SpotifyLikePlayer") then
        playerGui.SpotifyLikePlayer:Destroy()
    end
    
    -- Criação do frame principal
    local musicPlayerFrame = Instance.new("ScreenGui")
    musicPlayerFrame.Name = "SpotifyLikePlayer"
    musicPlayerFrame.Parent = playerGui
    
    -- Criação do frame de música
    local musicFrame = Instance.new("Frame")
    musicFrame.Size = UDim2.new(0.5, 0, 0.7, 0)
    musicFrame.Position = UDim2.new(0.25, 0, 0.15, 0)
    musicFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    musicFrame.Parent = musicPlayerFrame
    
    -- Variável para armazenar a música atual
    local currentMusic = nil
    
    -- Barra de pesquisa
    local searchBar = Instance.new("TextBox")
    searchBar.Size = UDim2.new(0.8, 0, 0.05, 0)
    searchBar.Position = UDim2.new(0.1, 0, 0.02, 0)
    searchBar.PlaceholderText = "Pesquisar músicas..."
    searchBar.Parent = musicFrame
    
    -- Lista de resultados
    local resultsFrame = Instance.new("ScrollingFrame")
    resultsFrame.Size = UDim2.new(0.9, 0, 0.4, 0)
    resultsFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
    resultsFrame.Parent = musicFrame
    
    -- Frame de detalhes da música
    local detailsFrame = Instance.new("Frame")
    detailsFrame.Size = UDim2.new(1, 0, 0.4, 0)
    detailsFrame.Position = UDim2.new(0, 0, 0.6, 0)
    detailsFrame.Parent = musicFrame
    
    -- Texto de letra
    local lyricsText = Instance.new("TextLabel")
    lyricsText.Size = UDim2.new(0.9, 0, 0.8, 0)
    lyricsText.Position = UDim2.new(0.05, 0, 0.1, 0)
    lyricsText.Text = "Selecione uma música para ver a letra"
    lyricsText.TextScaled = true
    lyricsText.Parent = detailsFrame
    
    -- Botão para adicionar à playlist
    local addToPlaylistButton = Instance.new("TextButton")
    addToPlaylistButton.Size = UDim2.new(0.3, 0, 0.1, 0)
    addToPlaylistButton.Position = UDim2.new(0.35, 0, 0.9, 0)
    addToPlaylistButton.Text = "Adicionar à Playlist"
    addToPlaylistButton.BackgroundColor3 = Color3.fromRGB(29, 185, 84)
    addToPlaylistButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    addToPlaylistButton.Parent = musicFrame
    
    -- InputBox para nome da playlist
    local playlistNameInput = Instance.new("TextBox")
    playlistNameInput.Size = UDim2.new(0.3, 0, 0.05, 0)
    playlistNameInput.Position = UDim2.new(0.35, 0, 0.8, 0)
    playlistNameInput.PlaceholderText = "Nome da Playlist"
    playlistNameInput.Parent = musicFrame
    
    -- Limpar resultados anteriores
    local function clearResults()
        for _, child in ipairs(resultsFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end
    
    -- Buscar e exibir resultados
    local function performSearch()
        clearResults()
        local searchResults = self:SearchMusic(searchBar.Text)
        
        for i, music in ipairs(searchResults) do
            local resultButton = Instance.new("TextButton")
            resultButton.Size = UDim2.new(1, 0, 0.1, 0)
            resultButton.Position = UDim2.new(0, 0, (i-1)*0.1, 0)
            resultButton.Text = tostring(music.name or "Música Desconhecida")
            resultButton.Parent = resultsFrame
            
            resultButton.MouseButton1Click:Connect(function()
                currentMusic = music
                
                -- Parar música atual, se existir
                local existingSound = workspace:FindFirstChildOfClass("Sound")
                if existingSound then
                    existingSound:Destroy()
                end
                
                -- Verificações adicionais
                if music.audioUrl then
                    self:PlayGitSound(music.audioUrl, music.name)
                else
                    warn("URL de áudio não encontrada para " .. tostring(music.name))
                end
                
                -- Atualizar letra
                lyricsText.Text = "Letra não disponível"
                if music.lyricsUrl then
                    local success, lyrics = pcall(function()
                        return game:HttpGet(music.lyricsUrl)
                    end)
                    if success and lyrics then
                        lyricsText.Text = lyrics
                    end
                end
            end)
        end
    end
    
    -- Evento de busca
    searchBar.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            performSearch()
        end
    end)
    
    -- Evento do botão de adicionar à playlist
    addToPlaylistButton.MouseButton1Click:Connect(function()
        if currentMusic and playlistNameInput.Text ~= "" then
            local playlistName = playlistNameInput.Text
            
            -- Criar pasta de playlists se não existir
            local playlistFolder = Instance.new("Folder")
            playlistFolder.Name = "Playlists"
            playlistFolder.Parent = workspace
            
            -- Criar ou atualizar playlist
            local playlistValue = Instance.new("StringValue")
            playlistValue.Name = playlistName
            
            local musicValue = Instance.new("StringValue")
            musicValue.Name = tostring(currentMusic.name)
            musicValue.Value = tostring(currentMusic.audioUrl)
            musicValue.Parent = playlistValue
            
            playlistValue.Parent = playlistFolder
            
            -- Feedback visual
            addToPlaylistButton.Text = "Adicionado!"
            wait(2)
            addToPlaylistButton.Text = "Adicionar à Playlist"
        end
    end)
    
    return musicPlayerFrame
end

-- Função Principal de Inicialização
function MusicPlayer:Init()
    -- Aguardar jogador estar no jogo
    local player = Players.LocalPlayer
    if not player then
        Players.PlayerAdded:Wait()
        player = Players.LocalPlayer
    end
    
    -- Criar UI
    self:CreateSpotifyLikeUI()
end

-- Retornar o módulo
return MusicPlayer
