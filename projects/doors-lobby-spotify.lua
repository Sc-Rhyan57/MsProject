local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:FindFirstChild("PlayerGui")

if not playerGui then
    warn("PlayerGui não encontrado!")
    return
end

local mainUI = playerGui:FindFirstChild("MainUI")
if not mainUI then
    warn("MainUI não encontrado!")
    return
end

local initiator = mainUI:FindFirstChild("Initiator")
if not initiator then
    warn("Initiator não encontrado!")
    return
end

local mainLobby = initiator:FindFirstChild("Main_Lobby")
if not mainLobby then
    warn("Main_Lobby não encontrado!")
    return
end

local lobbyMusic = mainLobby:FindFirstChild("Music")
local outsideMusic = mainLobby:FindFirstChild("MusicOutside")

if not lobbyMusic or not outsideMusic then
    warn("Os objetos de áudio não foram encontrados!")
    return
end

local jsonUrl = "https://raw.githubusercontent.com/Msdoors/Msdoors.gg/refs/heads/main/Scripts/lobby/m%C3%BAsic.json"
local musicas = {}
local musicQueue = {}
local playedHistory = { [1] = {}, [2] = {} }
local isPlaying = { [1] = false, [2] = false }

local function msg(message)
    print("[Música]: " .. message)
end

local function GetJson(url)
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
            warn("Erro ao decodificar JSON!")
            return {}
        end
    else
        warn("Erro ao buscar JSON!")
        return {}
    end
end

local function GetGitAudioID(githubLink, soundName)
    local fileName = "Msdoors-" .. tostring(soundName) .. ".mp3"

    if isfile(fileName) then
        msg("🎵 Música já baixada: [" .. soundName .. "]")
        return (getcustomasset or getsynasset)(fileName)
    end

    msg("📥 Baixando música: [" .. soundName .. "]")
    local success, audioData = pcall(function()
        return game:HttpGet(githubLink, true)
    end)

    if not success then
        warn("❌ Falha ao baixar o áudio: " .. githubLink)
        return nil
    end

    writefile(fileName, audioData)
    msg("✅ Música baixada! [" .. soundName .. "]")
    
    return (getcustomasset or getsynasset)(fileName)
end

local function LoadMusicData()
    msg("📥 Carregando lista de músicas...")

    local jsonData = GetJson(jsonUrl)
    if not next(jsonData) then
        warn("⚠️ Nenhuma música carregada.")
        return
    end

    for _, categoria in pairs(jsonData) do
        for _, musica in pairs(categoria) do
            table.insert(musicas, { Name = musica.Name, Link = musica.Link })
        end
    end

    for i, musica in ipairs(musicas) do
        msg("📀 Baixando " .. musica.Name .. " (" .. i .. "/" .. #musicas .. ")")
        local soundId = GetGitAudioID(musica.Link, musica.Name)
        if soundId then
            table.insert(musicQueue, { Name = musica.Name, SoundId = soundId })
            msg("🎶 Sucesso ao baixar: " .. musica.Name)
        end
    end
end

local function PlayMusic(locationIndex)
    if #musicQueue == 0 then
        warn("⚠️ Nenhuma música carregada!")
        return
    end

    if isPlaying[locationIndex] then
        return
    end

    if #playedHistory[locationIndex] >= #musicQueue then
        msg("🔄 Todas as músicas já tocaram no " .. (locationIndex == 1 and "Interior" or "Exterior") .. ", resetando histórico!")
        playedHistory[locationIndex] = {}
    end

    local newIndex
    repeat
        newIndex = math.random(1, #musicQueue)
    until not playedHistory[locationIndex][newIndex]

    playedHistory[locationIndex][newIndex] = true
    local selectedMusic = musicQueue[newIndex]
    local targetMusic = (locationIndex == 1 and lobbyMusic or outsideMusic)

    if targetMusic then
        isPlaying[locationIndex] = true
        targetMusic.SoundId = selectedMusic.SoundId
        targetMusic.TimePosition = 0
        targetMusic.Looped = false
        targetMusic:Play()

        
        msg("▶️ Tocando: " .. selectedMusic.Name .. (locationIndex == 1 and " (Interior)" or " (Exterior)"))

        targetMusic.Ended:Once(function()
            isPlaying[locationIndex] = false
            PlayMusic(locationIndex)
        end)
    end
end

LoadMusicData()
task.wait(2)

PlayMusic(1) -- Música interna
PlayMusic(2) -- Música externa
