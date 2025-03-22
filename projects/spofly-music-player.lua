-- Spofly: Sistema Avançado de Reprodução de Música
-- Pode ser usado em qualquer jogo do Roblox
-- Baseado no sistema original MsDoors e expandido com muitos recursos

-- Serviços
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Variáveis
local Player = Players.LocalPlayer
local SpoFly = {}
SpoFly.Version = "1.0.0"
SpoFly.DefaultPlaylistUrl = "https://raw.githubusercontent.com/Msdoors/Msdoors.gg/refs/heads/main/Scripts/lobby/m%C3%BAsic.json"
SpoFly.Songs = {}
SpoFly.CurrentSong = nil
SpoFly.CurrentPlaylist = "default"
SpoFly.Volume = 0.5
SpoFly.Playing = false
SpoFly.RepeatMode = 0 -- 0: None, 1: Playlist, 2: Song
SpoFly.ShuffleMode = false
SpoFly.CurrentIndex = 1
SpoFly.PlayOrder = {}
SpoFly.LikedSongs = {}
SpoFly.PlayedHistory = {}
SpoFly.Sound = nil

-- Configuração de pastas
SpoFly.Folders = {
    Root = "msproject/spofly",
    Songs = "msproject/spofly/songs",
    Playlists = "msproject/spofly/playlists",
    Likes = "msproject/spofly/likes"
}

-- Cores e temas
SpoFly.Theme = {
    Primary = Color3.fromRGB(30, 215, 96),     -- Verde Spotify
    Secondary = Color3.fromRGB(25, 20, 20),    -- Cinza escuro quase preto
    Text = Color3.fromRGB(255, 255, 255),      -- Branco
    TextSecondary = Color3.fromRGB(170, 170, 170), -- Cinza claro
    Background = Color3.fromRGB(18, 18, 18),   -- Preto
    BackgroundSecondary = Color3.fromRGB(40, 40, 40), -- Cinza mais escuro
    Accent = Color3.fromRGB(255, 75, 43),      -- Vermelho para botões de curtir
}

-- Importar a biblioteca Linoria
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/Library.lua'))()

-- Funções de utilidade
local function Log(message, level)
    level = level or "INFO"
    local prefix = "[SpoFly]"
    local colorMap = {
        ["INFO"] = "🎵",
        ["WARN"] = "⚠️",
        ["ERROR"] = "❌",
        ["SUCCESS"] = "✅"
    }
    print(prefix .. " " .. (colorMap[level] or "") .. " " .. tostring(message))
end

local function EnsureFolders()
    for _, path in pairs(SpoFly.Folders) do
        if not isfolder(path) then
            makefolder(path)
            Log("Pasta criada: " .. path, "INFO")
        end
    end
end

local function SaveToFile(data, filePath)
    local success, err = pcall(function()
        writefile(filePath, HttpService:JSONEncode(data))
    end)
    
    if not success then
        Log("Erro ao salvar arquivo: " .. filePath .. " - " .. tostring(err), "ERROR")
        return false
    end
    
    return true
end

local function LoadFromFile(filePath)
    if not isfile(filePath) then
        return nil
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(filePath))
    end)
    
    if not success then
        Log("Erro ao carregar arquivo: " .. filePath, "ERROR")
        return nil
    end
    
    return data
end

local function FetchJson(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local decoded, jsonData = pcall(function()
            return HttpService:JSONDecode(result)
        end)

        if decoded then
            return jsonData
        else
            Log("Erro ao decodificar JSON!", "ERROR")
            return {}
        end
    else
        Log("Erro ao buscar JSON!", "ERROR")
        return {}
    end
end

local function DownloadAudio(url, songName)
    local fileName = SpoFly.Folders.Songs .. "/spofly-" .. songName:gsub("%s+", "_"):gsub("[^%w_-]", ""):lower() .. ".mp3"
    
    if isfile(fileName) then
        Log("Música já baixada: [" .. songName .. "]", "INFO")
        return (getcustomasset or getsynasset)(fileName)
    end
    
    Log("Baixando música: [" .. songName .. "]", "INFO")
    local success, audioData = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if not success then
        Log("Falha ao baixar o áudio: " .. url, "ERROR")
        return nil
    end
    
    writefile(fileName, audioData)
    Log("Música baixada! [" .. songName .. "]", "SUCCESS")
    
    return (getcustomasset or getsynasset)(fileName)
end

local function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

-- Funções principais do reprodutor
function SpoFly:Initialize()
    Log("Inicializando SpoFly " .. self.Version, "INFO")
    EnsureFolders()
    
    -- Carregar curtidas salvas
    local likesPath = self.Folders.Likes .. "/likes.json"
    if isfile(likesPath) then
        self.LikedSongs = LoadFromFile(likesPath) or {}
        Log("Carregado " .. #self.LikedSongs .. " músicas curtidas", "INFO")
    else
        SaveToFile({}, likesPath)
    end
    
    -- Criar objeto de som
    self.Sound = Instance.new("Sound")
    self.Sound.Name = "SpoFlySound"
    self.Sound.Volume = self.Volume
    self.Sound.Parent = game:GetService("SoundService")
    
    self:CreateInterface()
    self:LoadDefaultPlaylist()
    
    -- Eventos do Sound
    self.Sound.Ended:Connect(function()
        self:OnSongEnded()
    end)
    
    Log("SpoFly inicializado com sucesso!", "SUCCESS")
    return self
end

function SpoFly:LoadDefaultPlaylist()
    Log("Carregando playlist padrão...", "INFO")
    
    local defaultPlaylistPath = self.Folders.Playlists .. "/playlist1.json"
    local playlist = nil
    
    if isfile(defaultPlaylistPath) then
        playlist = LoadFromFile(defaultPlaylistPath)
    end
    
    if not playlist then
        Log("Playlist padrão não encontrada, baixando da fonte original", "INFO")
        playlist = self:FetchPlaylistFromUrl(self.DefaultPlaylistUrl)
        
        if playlist and #playlist > 0 then
            SaveToFile(playlist, defaultPlaylistPath)
        end
    end
    
    if playlist and #playlist > 0 then
        self.Songs = playlist
        self:GeneratePlayOrder()
        Log("Playlist carregada com " .. #self.Songs .. " músicas", "SUCCESS")
        
        -- Atualizar a interface
        self:UpdateSongsList()
        self:PrepareSong(1)
    else
        Log("Nenhuma música encontrada na playlist", "WARN")
    end
end

function SpoFly:FetchPlaylistFromUrl(url)
    local songs = {}
    local jsonData = FetchJson(url)
    
    if not next(jsonData) then
        Log("Nenhuma música encontrada no link fornecido", "WARN")
        return songs
    end
    
    for _, categoria in pairs(jsonData) do
        for _, musica in pairs(categoria) do
            table.insert(songs, {
                name = musica.Name,
                url = musica.Link,
                artist = musica.Artist or "Desconhecido",
                duration = musica.Duration or 0,
                soundId = nil
            })
        end
    end
    
    return songs
end

function SpoFly:GeneratePlayOrder()
    self.PlayOrder = {}
    
    for i = 1, #self.Songs do
        table.insert(self.PlayOrder, i)
    end
    
    if self.ShuffleMode then
        self:ShuffleSongs()
    end
end

function SpoFly:ShuffleSongs()
    local shuffledOrder = {}
    local order = table.clone(self.PlayOrder)
    
    while #order > 0 do
        local index = math.random(1, #order)
        table.insert(shuffledOrder, order[index])
        table.remove(order, index)
    end
    
    self.PlayOrder = shuffledOrder
    
    -- Se estiver tocando uma música, encontrar seu novo índice
    if self.CurrentSong then
        for i, idx in ipairs(self.PlayOrder) do
            if idx == self.CurrentIndex then
                self.CurrentIndex = i
                break
            end
        end
    end
end

function SpoFly:PrepareSong(index)
    if not self.Songs or #self.Songs == 0 then
        Log("Nenhuma música na playlist", "WARN")
        return false
    end
    
    if index < 1 or index > #self.PlayOrder then
        Log("Índice de música inválido: " .. tostring(index), "ERROR")
        return false
    end
    
    local songIndex = self.PlayOrder[index]
    local song = self.Songs[songIndex]
    
    if not song then
        Log("Música não encontrada", "ERROR")
        return false
    end
    
    self.CurrentIndex = index
    self.CurrentSong = song
    
    -- Carregar arquivo de áudio
    if not song.soundId then
        song.soundId = DownloadAudio(song.url, song.name)
        
        if not song.soundId then
            Log("Não foi possível carregar a música: " .. song.name, "ERROR")
            return false
        end
    end
    
    -- Atualizar a interface
    self:UpdateNowPlaying()
    
    -- Atualizar o Sound
    self.Sound.SoundId = song.soundId
    self.Sound.TimePosition = 0
    
    Log("Música preparada: " .. song.name, "INFO")
    return true
end

function SpoFly:Play()
    if not self.CurrentSong then
        if not self:PrepareSong(1) then
            return false
        end
    end
    
    self.Sound:Play()
    self.Playing = true
    self.UIElements.PlayButton.Text = "⏸️"
    
    self:StartProgressUpdater()
    Log("Tocando: " .. self.CurrentSong.name, "INFO")
    return true
end

function SpoFly:Pause()
    if self.Sound and self.Playing then
        self.Sound:Pause()
        self.Playing = false
        self.UIElements.PlayButton.Text = "▶️"
        Log("Pausado: " .. (self.CurrentSong and self.CurrentSong.name or ""), "INFO")
    end
end

function SpoFly:TogglePlay()
    if self.Playing then
        self:Pause()
    else
        self:Play()
    end
end

function SpoFly:Stop()
    if self.Sound then
        self.Sound:Stop()
        self.Sound.TimePosition = 0
        self.Playing = false
        self.UIElements.PlayButton.Text = "▶️"
        self:UpdateProgressBar(0, 0)
        Log("Parado", "INFO")
    end
end

function SpoFly:Next()
    if #self.PlayOrder == 0 then return end
    
    local nextIndex = self.CurrentIndex + 1
    if nextIndex > #self.PlayOrder then
        if self.RepeatMode == 1 then
            nextIndex = 1
        else
            self:Stop()
            return
        end
    end
    
    self:Stop()
    self:PrepareSong(nextIndex)
    self:Play()
end

function SpoFly:Previous()
    if #self.PlayOrder == 0 then return end
    
    if self.Sound.TimePosition > 3 then
        -- Se estiver tocando há mais de 3 segundos, voltar ao início da música atual
        self.Sound.TimePosition = 0
        return
    end
    
    local prevIndex = self.CurrentIndex - 1
    if prevIndex < 1 then
        if self.RepeatMode == 1 then
            prevIndex = #self.PlayOrder
        else
            prevIndex = 1
        end
    end
    
    self:Stop()
    self:PrepareSong(prevIndex)
    self:Play()
end

function SpoFly:SetVolume(volume)
    volume = math.clamp(volume, 0, 1)
    self.Volume = volume
    self.Sound.Volume = volume
    self.UIElements.VolumeSlider:Set(volume * 100)
    Log("Volume: " .. math.floor(volume * 100) .. "%", "INFO")
end

function SpoFly:ToggleShuffle()
    self.ShuffleMode = not self.ShuffleMode
    self:GeneratePlayOrder()
    
    -- Atualizar interface
    self.UIElements.ShuffleButton.TextColor3 = self.ShuffleMode and self.Theme.Primary or self.Theme.TextSecondary
    Log("Modo aleatório: " .. (self.ShuffleMode and "Ativado" or "Desativado"), "INFO")
end

function SpoFly:ToggleRepeat()
    self.RepeatMode = (self.RepeatMode + 1) % 3
    
    -- Atualizar interface
    local buttonText = "🔁"
    local buttonColor = self.Theme.TextSecondary
    
    if self.RepeatMode == 1 then
        buttonText = "🔁"
        buttonColor = self.Theme.Primary
    elseif self.RepeatMode == 2 then
        buttonText = "🔂"
        buttonColor = self.Theme.Primary
    end
    
    self.UIElements.RepeatButton.Text = buttonText
    self.UIElements.RepeatButton.TextColor3 = buttonColor
    
    local modeText = {"Desativado", "Repetir Playlist", "Repetir Música"}
    Log("Modo repetição: " .. modeText[self.RepeatMode + 1], "INFO")
end

function SpoFly:OnSongEnded()
    if self.RepeatMode == 2 then
        -- Repetir a mesma música
        self.Sound.TimePosition = 0
        self.Sound:Play()
    else
        -- Próxima música
        self:Next()
    end
end

function SpoFly:ToggleLike()
    if not self.CurrentSong then return end
    
    local songName = self.CurrentSong.name
    local isLiked = false
    
    -- Verificar se a música já está curtida
    for i, name in ipairs(self.LikedSongs) do
        if name == songName then
            table.remove(self.LikedSongs, i)
            isLiked = false
            break
        end
        isLiked = true
    end
    
    -- Se não encontrou, adicionar à lista
    if isLiked then
        table.insert(self.LikedSongs, songName)
    end
    
    -- Salvar curtidas
    SaveToFile(self.LikedSongs, self.Folders.Likes .. "/likes.json")
    
    -- Atualizar interface
    self.UIElements.LikeButton.Text = self:IsLiked(songName) and "♥" or "♡"
    self.UIElements.LikeButton.TextColor3 = self:IsLiked(songName) and self.Theme.Accent or self.Theme.TextSecondary
    
    Log(self:IsLiked(songName) and "Música curtida: " or "Curtida removida: " .. songName, "INFO")
    
    -- Atualizar a lista de músicas (para atualizar os ícones de curtida)
    self:UpdateSongsList()
end

function SpoFly:IsLiked(songName)
    for _, name in ipairs(self.LikedSongs) do
        if name == songName then
            return true
        end
    end
    return false
end

function SpoFly:SeekTo(position)
    if not self.Sound then return end
    
    position = math.clamp(position, 0, self.Sound.TimeLength)
    self.Sound.TimePosition = position
    Log("Avançando para: " .. FormatTime(position), "INFO")
end

function SpoFly:CreateInterface()
    -- Criar janela principal
    local Window = Library:CreateWindow({
        Title = "SpoFly Music Player",
        Center = true,
        AutoShow = true,
        TabPadding = 8
    })
    
    -- Abas
    local PlayerTab = Window:AddTab("Player")
    local PlaylistTab = Window:AddTab("Playlist")
    local SettingsTab = Window:AddTab("Configurações")
    
    -- Elementos da interface
    self.UIElements = {}
    
    -- Seção do player
    local PlayerSection = PlayerTab:AddLeftGroupbox("Tocando Agora")
    
    self.UIElements.SongTitle = PlayerSection:AddLabel("Selecione uma música", true)
    self.UIElements.ArtistLabel = PlayerSection:AddLabel("", true)
    
    -- Barra de progresso
    PlayerSection:AddDivider()
    self.UIElements.ProgressSlider = PlayerSection:AddSlider("Progresso", {
        Text = "Progresso",
        Min = 0,
        Max = 100,
        Default = 0,
        Rounding = 0,
        Compact = false
    })
    
    self.UIElements.TimeLabel = PlayerSection:AddLabel("00:00 / 00:00", true)
    
    -- Controles de reprodução
    local ControlsSection = PlayerTab:AddRightGroupbox("Controles")
    
    ControlsSection:AddButton({
        Text = "⏮️",
        Func = function() self:Previous() end,
        DoubleClick = false
    })
    
    self.UIElements.PlayButton = ControlsSection:AddButton({
        Text = "▶️",
        Func = function() self:TogglePlay() end,
        DoubleClick = false
    })
    
    ControlsSection:AddButton({
        Text = "⏭️",
        Func = function() self:Next() end,
        DoubleClick = false
    })
    
    ControlsSection:AddDivider()
    
    self.UIElements.ShuffleButton = ControlsSection:AddButton({
        Text = "🔀",
        Func = function() self:ToggleShuffle() end,
        DoubleClick = false
    })
    
    self.UIElements.RepeatButton = ControlsSection:AddButton({
        Text = "🔁",
        Func = function() self:ToggleRepeat() end,
        DoubleClick = false
    })
    
    self.UIElements.LikeButton = ControlsSection:AddButton({
        Text = "♡",
        Func = function() self:ToggleLike() end,
        DoubleClick = false
    })
    
    -- Volume
    ControlsSection:AddDivider()
    ControlsSection:AddLabel("Volume", true)
    
    self.UIElements.VolumeSlider = ControlsSection:AddSlider("Volumo", {
        Text = "Volume",
        Min = 0,
        Max = 100,
        Default = 50,
        Rounding = 0,
        Compact = false,
        Callback = function(Value)
            self:SetVolume(Value / 100)
        end
    })
    
    -- Aba de Playlist
    local PlaylistSection = PlaylistTab:AddLeftGroupbox("Suas Músicas")
    self.UIElements.SongsHolder = PlaylistSection:AddDivider()
    self.UIElements.SongButtons = {}
    
    local PlaylistsSection = PlaylistTab:AddRightGroupbox("Playlists")
    
    PlaylistsSection:AddInput("PlaylistURL", {
        Default = "",
        Numeric = false,
        Finished = false,
        Text = "URL da Playlist",
        Tooltip = "Cole o link para um arquivo JSON com lista de músicas",
        Placeholder = "https://exemplo.com/playlist.json"
    })
    
    PlaylistsSection:AddButton({
        Text = "Importar Playlist",
        Func = function()
            local url = Library.Options.PlaylistURL.Value
            if url and url ~= "" then
                self:ImportPlaylist(url)
            else
                Log("URL da playlist não fornecida", "WARN")
            end
        end,
        DoubleClick = false
    })
    
    PlaylistsSection:AddButton({
        Text = "Carregar Playlist Salva",
        Func = function()
            self:LoadSavedPlaylists()
        end,
        DoubleClick = false
    })
    
    PlaylistsSection:AddButton({
        Text = "Mostrar Curtidas",
        Func = function()
            self:ShowLikedSongs()
        end,
        DoubleClick = false
    })
    
    -- Aba de Configurações
    local SettingsSection = SettingsTab:AddLeftGroupbox("Configurações")
    
    SettingsSection:AddToggle("AutoPlay", {
        Text = "Reprodução Automática",
        Default = true,
        Tooltip = "Iniciar automaticamente a próxima música"
    })
    
    SettingsSection:AddToggle("SaveHistory", {
        Text = "Salvar Histórico",
        Default = true,
        Tooltip = "Salvar histórico de reprodução"
    })
    
    SettingsSection:AddButton({
        Text = "Limpar Cache",
        Func = function()
            self:ClearCache()
        end,
        DoubleClick = true
    })
    
    SettingsSection:AddButton({
        Text = "Reiniciar SpoFly",
        Func = function()
            self:Restart()
        end,
        DoubleClick = true
    })
    
    local AboutSection = SettingsTab:AddRightGroupbox("Sobre")
    AboutSection:AddLabel("SpoFly v" .. self.Version, true)
    AboutSection:AddLabel("Reprodutor de Música Avançado", true)
    AboutSection:AddLabel("Funciona em qualquer jogo!", true)
    AboutSection:AddDivider()
    AboutSection:AddLabel("Inspirado no sistema de música MsDoors", true)
    
    -- Configurar manipulador do slider de progresso
    self.UIElements.ProgressSlider:OnChanged(function(Value)
        if self.UIElements.ProgressSlider.Dragging then
            local position = (Value / 100) * self.Sound.TimeLength
            self:SeekTo(position)
        end
    end)
    
    -- Inicializar cores dos botões
    self.UIElements.ShuffleButton.TextColor3 = self.Theme.TextSecondary
    self.UIElements.RepeatButton.TextColor3 = self.Theme.TextSecondary
    self.UIElements.LikeButton.TextColor3 = self.Theme.TextSecondary
    
    Library:OnUnload(function()
        self:Stop()
        self.Sound:Destroy()
        Log("SpoFly descarregado", "INFO")
    end)
    
    Log("Interface criada", "SUCCESS")
end

function SpoFly:StartProgressUpdater()
    -- Parar qualquer atualizador existente
    if self.ProgressUpdater then
        self.ProgressUpdater:Disconnect()
        self.ProgressUpdater = nil
    end
    
    -- Criar novo atualizador
    self.ProgressUpdater = RunService.RenderStepped:Connect(function()
        if not self.Playing or not self.Sound then return end
        
        local current = self.Sound.TimePosition
        local total = self.Sound.TimeLength
        
        if not self.UIElements.ProgressSlider.Dragging then
            self:UpdateProgressBar(current, total)
        end
    end)
end

function SpoFly:UpdateProgressBar(current, total)
    -- Atualizar slider
    local percentage = total > 0 and (current / total) * 100 or 0
    self.UIElements.ProgressSlider:Set(percentage)
    
    -- Atualizar texto do tempo
    self.UIElements.TimeLabel:Set(FormatTime(current) .. " / " .. FormatTime(total))
end

function SpoFly:UpdateNowPlaying()
    if not self.CurrentSong then
        self.UIElements.SongTitle:Set("Selecione uma música")
        self.UIElements.ArtistLabel:Set("")
        self.UIElements.LikeButton.Text = "♡"
        self.UIElements.LikeButton.TextColor3 = self.Theme.TextSecondary
        return
    end
    
    self.UIElements.SongTitle:Set(self.CurrentSong.name)
    self.UIElements.ArtistLabel:Set(self.CurrentSong.artist or "")
    
    -- Atualizar botão de curtir
    local isLiked = self:IsLiked(self.CurrentSong.name)
    self.UIElements.LikeButton.Text = isLiked and "♥" or "♡"
    self.UIElements.LikeButton.TextColor3 = isLiked and self.Theme.Accent or self.Theme.TextSecondary
end

function SpoFly:UpdateSongsList()
    -- Limpar botões existentes
    for _, button in pairs(self.UIElements.SongButtons) do
        button:Remove()
    end
    
    self.UIElements.SongButtons = {}
    
    -- Adicionar novos botões para cada música
    for i, song in ipairs(self.Songs) do
        local isCurrentSong = self.CurrentSong and self.CurrentSong.name == song.name
        local isLiked = self:IsLiked(song.name)
        local buttonText = (isCurrentSong and "▶️ " or "") .. song.name .. (isLiked and " ♥" or "")
        
        local button = self.UIElements.SongsHolder:AddButton({
            Text = buttonText,
            Func = function()
                self:Stop()
                
                -- Encontre o índice na ordem de reprodução
                local playOrderIndex = 1
                for j, songIndex in ipairs(self.PlayOrder) do
                    if songIndex == i then
                        playOrderIndex = j
                        break
                    end
                end
                
                self:PrepareSong(playOrderIndex)
                self:Play()
            end,
            DoubleClick = false
        })
        
        if isCurrentSong then
            button.TextColor3 = self.Theme.Primary
        end
        
        if isLiked then
            -- Não podemos modificar só parte do texto, então apenas usamos uma cor diferente
            button.TextColor3 = isCurrentSong and self.Theme.Primary or self.Theme.TextSecondary
        end
        
        table.insert(self.UIElements.SongButtons, button)
    end
    
    Log("Lista de músicas atualizada", "INFO")
end

function SpoFly:ImportPlaylist(url)
    Log("Importando playlist de: " .. url, "INFO")
    
    local playlist = self:FetchPlaylistFromUrl(url)
    
    if playlist and #playlist > 0 then
        local playlistName = "playlist" .. os.time() .. ".json"
        local path = self.Folders.Playlists .. "/" .. playlistName
        
        SaveToFile(playlist, path)
        
        Log("Playlist importada com " .. #playlist .. " músicas", "SUCCESS")
        Log("Salvo como: " .. playlistName, "INFO")
        
        -- Perguntar se deseja carregar a playlist
        Library:Notify("Playlist importada com " .. #playlist .. " músicas. Deseja carregar agora?", 
            function(Value)
                if Value then
                    self.Songs = playlist
                    self:GeneratePlayOrder()
                    self:UpdateSongsList()
                    self:PrepareSong(1)
                    
                    if Library.Options.AutoPlay.Value then
                        self:Play()
                    end
                end
            end
        )
    else
        Log("Falha ao importar playlist, nenhuma música encontrada", "ERROR")
        Library:Notify("Falha ao importar playlist. Verifique o URL e tente novamente.")
    end
end

function SpoFly:LoadSavedPlaylists()
    local playlists = {}
    
    -- Listar todos os arquivos na pasta de playlists
    local success, files = pcall(function()
        return listfiles(self.Folders.Playlists)
    end)
    
    if success and files then
        for _, file in ipairs(files) do
            -- Extrair apenas o nome do arquivo do caminho completo
            local fileName = string.match(file, "[^/\\]+$")
            if fileName and string.find(fileName, ".json") then
                table.insert(playlists, {Name = fileName, Path = file})
            end
        end
    end
    
    if #playlists == 0 then
        Log("Nenhuma playlist salva encontrada", "WARN")
        Library:Notify("Nenhuma playlist salva encontrada.")
        return
    end
    
    -- Criar seletor de playlists
    local dropdown = {}
    for _, playlist in ipairs(playlists) do
        table.insert(dropdown, playlist.Name)
    end
    
    local DropSection = Library:CreateWindow({
        Title = "Selecionar Playlist",
        AutoShow = true
    })
    
    local playlistDropdown = DropSection:AddDropdown("PlaylistSelection", {
        Values = dropdown,
        Default = 1,
        Multi = false,
        Text = "Escolha uma Playlist",
        Tooltip = "Selecione uma playlist salva para carregar"
    })
    
    DropSection:AddButton({
        Text = "Carregar Playlist",
        Func = function()
            local selectedPlaylist = playlistDropdown.Value
            if selectedPlaylist then
                local path = self.Folders.Playlists .. "/" .. selectedPlaylist
                local loadedPlaylist = LoadFromFile(path)
                
                if loadedPlaylist and #loadedPlaylist > 0 then
                    self.Songs = loadedPlaylist
                    self:GeneratePlayOrder()
                    self:UpdateSongsList()
                    self:PrepareSong(1)
                    
                    if Library.Options.AutoPlay.Value then
                        self:Play()
                    end
                    
                    Log("Playlist carregada: " .. selectedPlaylist, "SUCCESS")
                    DropSection:Close()
                else
                    Log("Erro ao carregar playlist", "ERROR")
                    Library:Notify("Falha ao carregar playlist.")
                end
            else
                Library:Notify("Selecione uma playlist primeiro!")
            end
        end,
        DoubleClick = false
    })
    
    DropSection:AddButton({
        Text = "Fechar",
        Func = function()
            DropSection:Close()
        end,
        DoubleClick = false
    })
end

function SpoFly:ShowLikedSongs()
    local likedSongs = self.LikedSongs
    if #likedSongs == 0 then
        Log("Nenhuma música curtida encontrada", "WARN")
        Library:Notify("Nenhuma música curtida ainda.")
        return
    end
    
    local LikedWindow = Library:CreateWindow({
        Title = "Músicas Curtidas",
        AutoShow = true
    })
    
    local LikedSection = LikedWindow:AddLeftGroupbox("Músicas")
    
    for _, songName in ipairs(likedSongs) do
        LikedSection:AddButton({
            Text = songName,
            Func = function()
                for i, song in ipairs(self.Songs) do
                    if song.name == songName then
                        self:Stop()
                        self:PrepareSong(i)
                        self:Play()
                        break
                    end
                end
            end,
            DoubleClick = false
        })
    end
    
    LikedWindow:AddButton({
        Text = "Fechar",
        Func = function()
            LikedWindow:Close()
        end,
        DoubleClick = false
    })
end

function SpoFly:ClearCache()
    Log("Limpando cache de músicas...", "INFO")
    
    local success, files = pcall(function()
        return listfiles(self.Folders.Songs)
    end)
    
    if success and files then
        for _, file in ipairs(files) do
            delfile(file)
        end
        Log("Cache de músicas limpo!", "SUCCESS")
        Library:Notify("Cache de músicas foi apagado.")
    else
        Log("Falha ao acessar a pasta de músicas", "ERROR")
        Library:Notify("Erro ao limpar cache.")
    end
end

function SpoFly:Restart()
    Log("Reiniciando SpoFly...", "INFO")
    self:Stop()
    self = SpoFly:Initialize()
end

return SpoFly:Initialize()
