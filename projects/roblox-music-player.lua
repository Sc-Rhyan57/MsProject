-- 📌 Carregando Orion Library
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Giangplay/Script/main/Orion_Library_PE_V2.lua"))()
local HttpService = game:GetService("HttpService")
local Window = OrionLib:MakeWindow({Name = "🎵 Music Player", HidePremium = false, SaveConfig = true, ConfigFolder = "MusicPlayer"})

-- 📌 Caminho do arquivo JSON onde as playlists são armazenadas
local playlistPath = "msproject/data/playlist/Playlists.json"

-- 📌 Criando pastas necessárias
if not isfolder("msproject") then makefolder("msproject") end
if not isfolder("msproject/data") then makefolder("msproject/data") end
if not isfolder("msproject/data/playlist") then makefolder("msproject/data/playlist") end
if not isfile(playlistPath) then writefile(playlistPath, "{}") end

-- 📌 Função para carregar a playlist do JSON
local function LoadPlaylist()
    local data = readfile(playlistPath)
    return HttpService:JSONDecode(data)
end

-- 📌 Função para salvar a playlist no JSON
local function SavePlaylist(playlist)
    writefile(playlistPath, HttpService:JSONEncode(playlist))
end

-- 📌 Sistema de Reprodução (Agora suporta qualquer formato!)
local function GetAudioFile(githubLink, soundName)
    local ext = githubLink:match("^.+(%..+)$") or ".mp3"
    local fileName = "customObject_Sound_" .. tostring(soundName) .. ext

    local success, audioData = pcall(function()
        return game:HttpGet(githubLink)
    end)

    if not success then
        warn("Falha ao baixar o áudio: " .. githubLink)
        return nil
    end

    writefile(fileName, audioData)
    return (getcustomasset or getsynasset)(fileName)
end

local function PlayGitSound(githubLink, soundName, volume)
    local soundId = GetAudioFile(githubLink, soundName)

    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 0.5
        sound.Parent = workspace
        sound:Play()

        OrionLib:MakeNotification({Name = "🎵 Tocando agora", Content = soundName, Time = 3})
        print("🎵 Tocando agora: " .. soundName)

        sound.Ended:Connect(function()
            sound:Destroy()
            delfile("customObject_Sound_" .. tostring(soundName) .. ".mp3")
        end)

        -- Timer para avisar 10s antes de acabar
        task.spawn(function()
            while sound.Playing do
                if sound.TimeLength - sound.TimePosition <= 10 then
                    print("⏳ Próxima música em 10s: " .. soundName)
                    OrionLib:MakeNotification({Name = "⏳ Aviso", Content = "Próxima música em 10s!", Time = 3})
                    break
                end
                task.wait(1)
            end
        end)

        return sound
    end

    return nil
end

-- 📌 Variáveis para Play/Pause
local CurrentSound = nil
local IsPlaying = false

local function PlayPauseMusic()
    if CurrentSound then
        if IsPlaying then
            CurrentSound:Pause()
            IsPlaying = false
            OrionLib:MakeNotification({Name = "⏸️ Pausado", Content = "Música pausada", Time = 3})
            print("⏸️ Música pausada.")
        else
            CurrentSound:Resume()
            IsPlaying = true
            OrionLib:MakeNotification({Name = "▶️ Retomado", Content = "Música retomada", Time = 3})
            print("▶️ Música retomada.")
        end
    end
end

-- 📌 Criando interface no Orion
local MainTab = Window:MakeTab({Name = "🎶 Player", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local PlaylistTab = Window:MakeTab({Name = "📂 Playlist", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- 📌 Inputs para tocar música
MainTab:AddTextbox({
    Name = "🔗 URL da Música",
    Default = "",
    TextDisappear = true,
    Callback = function(value)
        _G.CurrentMusicURL = value
    end
})

MainTab:AddTextbox({
    Name = "🎵 Nome da Música",
    Default = "",
    TextDisappear = true,
    Callback = function(value)
        _G.CurrentMusicName = value
    end
})

MainTab:AddSlider({
    Name = "🔊 Volume",
    Min = 0,
    Max = 10,
    Default = 5,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 0.1,
    Callback = function(value)
        _G.CurrentMusicVolume = value
    end
})

MainTab:AddButton({
    Name = "▶️ Tocar Música",
    Callback = function()
        if _G.CurrentMusicURL and _G.CurrentMusicName then
            if CurrentSound then CurrentSound:Destroy() end
            CurrentSound = PlayGitSound(_G.CurrentMusicURL, _G.CurrentMusicName, _G.CurrentMusicVolume)
            IsPlaying = true
        else
            warn("Preencha todos os campos!")
        end
    end
})

MainTab:AddButton({
    Name = "⏯️ Play/Pause",
    Callback = function()
        PlayPauseMusic()
    end
})

-- 📌 Sistema de Playlist
PlaylistTab:AddTextbox({
    Name = "🎵 Nome da Música",
    Default = "",
    TextDisappear = true,
    Callback = function(value)
        _G.PlaylistMusicName = value
    end
})

PlaylistTab:AddTextbox({
    Name = "🔗 Link da Música",
    Default = "",
    TextDisappear = true,
    Callback = function(value)
        _G.PlaylistMusicURL = value
    end
})

PlaylistTab:AddButton({
    Name = "➕ Adicionar à Playlist",
    Callback = function()
        if _G.PlaylistMusicName and _G.PlaylistMusicURL then
            local playlist = LoadPlaylist()
            table.insert(playlist, {Nome = _G.PlaylistMusicName, Link = _G.PlaylistMusicURL})
            SavePlaylist(playlist)
            OrionLib:MakeNotification({Name = "🎵 Playlist", Content = "Música adicionada!", Time = 3})
        else
            warn("Preencha todos os campos!")
        end
    end
})

PlaylistTab:AddButton({
    Name = "📜 Mostrar Playlist",
    Callback = function()
        local playlist = LoadPlaylist()
        for _, musica in pairs(playlist) do
            print("🎵 Nome:", musica.Nome, "🔗 Link:", musica.Link)
        end
        OrionLib:MakeNotification({Name = "🎵 Playlist", Content = "Playlist carregada no console!", Time = 3})
    end
})

PlaylistTab:AddButton({
    Name = "⛔ Limpar Playlist",
    Callback = function()
        SavePlaylist({})
        OrionLib:MakeNotification({Name = "🎵 Playlist", Content = "Playlist apagada!", Time = 3})
    end
})

-- 📌 Criar uma lista para tocar músicas da playlist
local playlist = LoadPlaylist()
for _, musica in pairs(playlist) do
    PlaylistTab:AddButton({
        Name = "▶️ " .. musica.Nome,
        Callback = function()
            if CurrentSound then CurrentSound:Destroy() end
            CurrentSound = PlayGitSound(musica.Link, musica.Nome, 0.5)
            IsPlaying = true
        end
    })
end

OrionLib:Init()
