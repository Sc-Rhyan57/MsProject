if shared.showloaded then
    warn("[ ARIGATO ] ALREADY LOADED.")
    return
end
shared.showloaded = true

shared.G = shared.G or {
    BPM = 128,
    bassHistory = {},
    lastRealBeat = 0,
    silenceTimer = 0,
    tornadoActive = false,
    camStuckTimer = 0,
    lastCamMode = "orbit",
    mutedSounds = {},
    GYRO_RINGS = {},
    beatCount = 0,
    beatStrength = 0,
    choreoIdx = 1,
    chromaticActive = false,
    colorSplitActive = false,
    currentAnimTrack = nil,
    elapsed = 0,
    finished = false,
    hexShapeAngle = 0,
    hexShapeEdges = {},
    hiddenParts = {},
    idleAnimPlaying = false,
    lastBeatTick = 0,
    lastLyricTime = 0,
    lyricBeatCount = 0,
    lyricEffectConn = nil,
    lyricIdx = 1,
    nebulaParts = {},
    orbitParts = {},
    origPlayerTransp = {},
    outerOrbitParts = {},
    pentaAngle = 0,
    pentaParts = {},
    playerGiantDone = false,
    portalRings = {},
    ringOrbitParts = {},
    showLights = {},
    starAngle = 0,
    starEdgeParts = {},
    starParts = {},
    startTick = 0,
    waveBars = {},
    camAngle = math.pi,
    camDist = 22,
    camHeight = 9,
    camMode = "orbit",
    camFOV = 70,
    camTarget = "singer",
    camShakeX = 0,
    camShakeY = 0,
    camShakeDecay = 0,
    desiredCamCF = CFrame.new(0,0,0),
    isFloating = false,
    singerBaseY = 0,
    singerFlyActive = false,
    glitching = false,
    specBars = {},
    waveParts3d = {},
    ribbonParts = {},
    meteorParts = {},
    prismParts = {},
    cometParts = {},
    orbitBoards = {},
    orbitBoardCount = 0,
    playerCloneOrigScales = {},
    cinemaSegTop = {},
    cinemaSegBot = {},
    cinemaWaveOffset = 0,
    cinemaBarsActive = false,
    cinemaClosing = false,
    skyConfettiConn = nil,
    audioBlurActive = false,
}

shared.G_players       = game:GetService("Players")
shared.G_runService    = game:GetService("RunService")
shared.G_tweenService  = game:GetService("TweenService")
shared.G_chatService   = game:GetService("Chat")
shared.G_lighting      = game:GetService("Lighting")
shared.G_starterGui    = game:GetService("StarterGui")
shared.G_debris        = game:GetService("Debris")
shared.G_camera        = workspace.CurrentCamera
shared.G_localPlayer   = shared.G_players.LocalPlayer

shared.G_AUDIO_URL  = "https://github.com/Sc-Rhyan57/MsProject/raw/refs/heads/main/projects/data/Waka%20Waka/wakawaka.ogg"
shared.G_LYRICS_URL = "https://raw.githubusercontent.com/Sc-Rhyan57/MsProject/refs/heads/main/projects/data/Waka%20Waka/Wakawaka.txt"

shared.G_BAR_COLORS = {
    levitate = Color3.fromRGB(100,200,255),
    dance    = Color3.fromRGB(255,80,200),
    point    = Color3.fromRGB(200,255,80),
    laugh    = Color3.fromRGB(255,200,60),
    wave     = Color3.fromRGB(80,255,200),
    robot    = Color3.fromRGB(80,160,255),
    shrug    = Color3.fromRGB(200,100,255),
    spin     = Color3.fromRGB(255,100,100),
}

shared.G_lyricStroke = nil
shared.G_colorCorrection = nil
shared.G_sound = nil
shared.G_audioAnalyzer = nil
shared.G_lyricOuter = nil
shared.G_lyricLabel = nil
shared.G_subLabel = nil
shared.G_flashFrame = nil
shared.G_colorCorrectionR = nil
shared.G_colorCorrectionB = nil
shared.G_bloom = nil
shared.G_blur = nil
shared.G_singerHRP = nil
shared.G_singerHum = nil
shared.G_singerHead = nil
shared.G_singerBasePos = nil
shared.G_playerCloneHRP = nil
shared.G_playerCloneHum = nil
shared.G_playerClone = nil
shared.G_playerHRP = nil
shared.G_playerHum = nil
shared.G_playerChar = nil
shared.G_playerHead = nil
shared.G_singer = nil
shared.G_singerParticles = nil
shared.G_playerParticles = nil
shared.G_spotLight = nil
shared.G_pointLight = nil
shared.G_singerSpotDown = nil
shared.G_stagePlatform = nil
shared.G_mainFolder = nil
shared.G_singerNameTag = nil
shared.G_colorSplitFrame1 = nil
shared.G_colorSplitFrame2 = nil
shared.G_scanlines = nil
shared.G_conn = nil
shared.G_singerFlyConn = nil
shared.G_karaokeConn = nil
shared.G_sg = nil

local G             = shared.G
local Players       = shared.G_players
local RunService    = shared.G_runService
local TweenService  = shared.G_tweenService
local ChatService   = shared.G_chatService
local Lighting      = shared.G_lighting
local StarterGui    = shared.G_starterGui
local Debris        = shared.G_debris
local Camera        = shared.G_camera
local LocalPlayer   = shared.G_localPlayer

local player = LocalPlayer
if player and player.PlayerGui:FindFirstChild("LoadingUI") and player.PlayerGui.LoadingUI.Enabled then
    repeat task.wait() until not player.PlayerGui:FindFirstChild("LoadingUI") or not player.PlayerGui.LoadingUI.Enabled
else
    repeat task.wait() until game:IsLoaded()
end

local CINEMA_SEGMENTS    = 90
local CINEMA_SEG_WIDTH   = 50
local CINEMA_TOTAL_WIDTH = 3500
local CINEMA_START_X     = -1110
local CINEMA_WAVE_SPEED  = 3.2
local CINEMA_BAR_H_LUA   = 75

local function cancelCinemaTweens()
    for i = 1, CINEMA_SEGMENTS do
        cancelTween("cTopIn"..i); cancelTween("cBotIn"..i)
        cancelTween("cTopOut"..i); cancelTween("cBotOut"..i)
        cancelTween("cTopAlpha"..i); cancelTween("cBotAlpha"..i)
    end
end

local function initCinematicBars()
    for i = 1, CINEMA_SEGMENTS do
        local x = CINEMA_START_X + (i-1) * CINEMA_SEG_WIDTH
        makeLuaSprite("cTopSeg"..i, "empty", x, -350)
        makeGraphic("cTopSeg"..i, CINEMA_SEG_WIDTH, 350, "000000")
        setObjectCamera("cTopSeg"..i, "hud")
        setScrollFactor("cTopSeg"..i, 0, 0)
        setObjectOrder("cTopSeg"..i, 0)
        setProperty("cTopSeg"..i..".alpha", 0)
        addLuaSprite("cTopSeg"..i, false)

        makeLuaSprite("cBotSeg"..i, "empty", x, 720)
        makeGraphic("cBotSeg"..i, CINEMA_SEG_WIDTH, 350, "000000")
        setObjectCamera("cBotSeg"..i, "hud")
        setScrollFactor("cBotSeg"..i, 0, 0)
        setObjectOrder("cBotSeg"..i, 0)
        setProperty("cBotSeg"..i..".alpha", 0)
        addLuaSprite("cBotSeg"..i, false)
    end
end

local function openCinematicBars(speed, distance)
    G.cinemaClosing = false
    G.cinemaBarsActive = true
    cancelCinemaTweens()
    for i = 1, CINEMA_SEGMENTS do
        local delay = (i / CINEMA_SEGMENTS) * 0.35
        local topY = -350 + distance
        local botY = 720 - distance
        setProperty("cTopSeg"..i..".alpha", 1)
        setProperty("cBotSeg"..i..".alpha", 1)
        setProperty("cTopSeg"..i..".y", -350)
        setProperty("cBotSeg"..i..".y", 720)
        doTweenY("cTopIn"..i, "cTopSeg"..i, topY, speed + delay, "quartOut")
        doTweenY("cBotIn"..i, "cBotSeg"..i, botY, speed + delay, "quartOut")
    end
end

local function closeCinematicBars(speed)
    G.cinemaClosing = true
    cancelCinemaTweens()
    for i = 1, CINEMA_SEGMENTS do
        local delay = ((CINEMA_SEGMENTS - i) / CINEMA_SEGMENTS) * 0.3
        doTweenY("cTopOut"..i, "cTopSeg"..i, -350, speed + delay, "quartIn")
        doTweenY("cBotOut"..i, "cBotSeg"..i, 720, speed + delay, "quartIn")
        doTweenAlpha("cTopAlpha"..i, "cTopSeg"..i, 0, speed + delay, "linear")
        doTweenAlpha("cBotAlpha"..i, "cBotSeg"..i, 0, speed + delay, "linear")
    end
    runTimer("resetCinemaBars", speed + 0.4)
end

local function GetGitAudioID(githubLink, soundName)
    local fileName = "customObject_Sound_" .. tostring(soundName) .. ".ogg"
    local ok, data = pcall(function() return game:HttpGet(githubLink) end)
    if not ok then warn("Falha ao baixar audio: " .. githubLink); return nil end
    writefile(fileName, data)
    return (getcustomasset or getsynasset)(fileName)
end

local function PlayGitSound(githubLink, soundName, volume, parent)
    local sid = GetGitAudioID(githubLink, soundName)
    if not sid then return nil end
    local s = Instance.new("Sound")
    s.SoundId = sid
    s.Volume  = volume or 0.5
    s.RollOffMaxDistance = 9999
    s.RollOffMinDistance = 9999
    s.Parent  = parent or workspace
    s:Play()
    s.Ended:Connect(function()
        s:Destroy()
        pcall(delfile, "customObject_Sound_" .. tostring(soundName) .. ".ogg")
    end)
    return s
end

local function setBarColor(color)
    if not color then return end
    TweenService:Create(shared.G_lyricStroke, TweenInfo.new(0.3), {Color = color}):Play()
    TweenService:Create(shared.G_colorCorrection, TweenInfo.new(0.4), {TintColor = color}):Play()
end

local function getLoudness()
    return 0
end
--[[
local function getLoudness()
    local ok, rms = pcall(function() return shared.G_audioAnalyzer.RmsLevel end)
    if ok and rms and rms > 0 then return math.clamp(rms, 0, 1) end
    return math.clamp((shared.G_sound and shared.G_sound.PlaybackLoudness or 0) / 100, 0, 1)
end
]]--

local function getFreqBands()
    local ok, spec = pcall(function() return shared.G_audioAnalyzer:GetSpectrum() end)
    local loudness = getLoudness()
    if not ok or not spec or #spec == 0 then
        return loudness, loudness * 0.5, loudness * 0.25
    end
    local n = #spec
    local bassN = math.max(1, math.floor(n * 0.08))
    local midN  = math.max(1, math.floor(n * 0.35))
    local bass, mid, treble = 0, 0, 0
    for i = 1, bassN do bass = bass + (spec[i] or 0) end
    for i = bassN+1, bassN+midN do mid = mid + (spec[i] or 0) end
    for i = bassN+midN+1, n do treble = treble + (spec[i] or 0) end
    bass   = math.clamp(math.sqrt(bass / bassN) * 2, 0, 1)
    mid    = math.clamp(math.sqrt(mid / math.max(1, midN)) * 2, 0, 1)
    treble = math.clamp(math.sqrt(treble / math.max(1, n-bassN-midN)) * 2, 0, 1)
    return bass, mid, treble
end

local function pushBassHistory(v)
    table.insert(G.bassHistory, v)
    if #G.bassHistory > 43 then table.remove(G.bassHistory, 1) end
end

local function avgBassHistory()
    if #G.bassHistory == 0 then return 0 end
    local s = 0
    for _, v in ipairs(G.bassHistory) do s = s + v end
    return s / #G.bassHistory
end

local function isRealBeat(bass)
    return bass > avgBassHistory() * 1.45 and bass > 0.12 and (tick() - G.lastRealBeat) > 0.22
end

local function parseLyrics()
    local lines = {}
    local ok, raw = pcall(function() return game:HttpGet(shared.G_LYRICS_URL) end)
    if not ok then return lines end

    local function parseTime(h, m, s, ms)
        h = tonumber(h) or 0; m = tonumber(m) or 0
        s = tonumber(s) or 0; ms = tonumber(ms) or 0
        local msLen = #tostring(math.floor(ms))
        if msLen <= 2 then ms = ms / 100
        elseif msLen == 3 then ms = ms / 1000
        else ms = ms / (10 ^ msLen) end
        return h * 3600 + m * 60 + s + ms
    end

    local function stripInlineTags(str)
        str = str:gsub("<[^>]+>", "")
        str = str:gsub("{\\[^}]+}", "")
        str = str:gsub("%[/*[a-zA-Z][^%]]*%]", "")
        str = str:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&"):gsub("&#39;", "'"):gsub("&quot;", '"')
        str = str:gsub("%s+", " ")
        return str:match("^%s*(.-)%s*$") or ""
    end

    local function parseColorTag(str)
        local color = nil
        local colorName = str:match("<font[^>]+color=[\"']?#?(%x%x%x%x%x%x)[\"']?")
        if colorName then
            local r = tonumber(colorName:sub(1,2), 16) or 255
            local g = tonumber(colorName:sub(3,4), 16) or 255
            local b = tonumber(colorName:sub(5,6), 16) or 255
            color = Color3.fromRGB(r, g, b)
        end
        local assColor = str:match("\\c&H(%x%x%x%x%x%x%x%x)&") or str:match("\\1c&H(%x%x%x%x%x%x%x%x)&")
        if assColor then
            local b2 = tonumber(assColor:sub(1,2), 16) or 255
            local g2 = tonumber(assColor:sub(3,4), 16) or 255
            local r2 = tonumber(assColor:sub(5,6), 16) or 255
            color = Color3.fromRGB(r2, g2, b2)
        end
        return color
    end

    local function tryExecBlock(str)
        local code = str:match("%[%[(.-)%]%]")
        if code then
            local fn, err = loadstring(code)
            if fn then task.spawn(pcall, fn)
            else warn("[parseLyrics] Erro: " .. tostring(err)) end
            return true
        end
        return false
    end

    local function addEntry(t, text, sub, color)
        text = text or ""; sub = sub or ""
        if text == "" and sub == "" then return end
        local entry = {time = t, jp = text, en = sub}
        if color then entry.color = color end
        table.insert(lines, entry)
    end

    local fmt = "lrc"
    if raw:match("^WEBVTT") then fmt = "vtt"
    elseif raw:match("%d+:%d+:%d+[%.,]%d+%s%-%->%s") then fmt = "srt"
    elseif raw:match("%[Script Info%]") or raw:match("^Dialogue:") then fmt = "ass"
    elseif raw:match("<%?xml") or raw:match("<tt ") or raw:match("<timedText") then fmt = "ttml"
    end

    if fmt == "vtt" then
        local block = ""
        for line in (raw .. "\n\n"):gmatch("([^\n]*)\n") do
            if line:match("^%s*$") then
                local ts = block:match("(%d+:%d+:%d+[%.,]%d+)%s%-%->%s") or block:match("(%d+:%d+[%.,]%d+)%s%-%->%s")
                if ts then
                    local h, m, s, ms = ts:match("(%d+):(%d+):(%d+)[%.,](%d+)")
                    if not h then m, s, ms = ts:match("(%d+):(%d+)[%.,](%d+)"); h = 0 end
                    local t = parseTime(h, m, s, ms)
                    local textPart = block:gsub(".*%-%->%s*[^\n]*\n?", ""):match("^%s*(.-)%s*$") or ""
                    local color = parseColorTag(textPart)
                    textPart = stripInlineTags(textPart)
                    if not tryExecBlock(textPart) and textPart ~= "" then addEntry(t, textPart, "", color) end
                end
                block = ""
            else
                block = block .. line .. "\n"
            end
        end
    elseif fmt == "srt" then
        local block = ""
        for line in (raw .. "\n\n"):gmatch("([^\n]*)\n") do
            if line:match("^%s*$") then
                local ts = block:match("(%d+:%d+:%d+[%.,]%d+)%s%-%->%s")
                if ts then
                    local h, m, s, ms = ts:match("(%d+):(%d+):(%d+)[%.,](%d+)")
                    local t = parseTime(h, m, s, ms)
                    local textPart = block:gsub("^%d+%s*\n", ""):gsub("[^\n]+%-%->.-\n", ""):match("^%s*(.-)%s*$") or ""
                    local color = parseColorTag(textPart)
                    textPart = stripInlineTags(textPart)
                    if not tryExecBlock(textPart) and textPart ~= "" then addEntry(t, textPart, "", color) end
                end
                block = ""
            else
                block = block .. line .. "\n"
            end
        end
    elseif fmt == "ass" then
        for line in raw:gmatch("[^\n]+") do
            if line:match("^Dialogue:") then
                local fields = {}
                for f in (line:gsub("^Dialogue:%s*", "") .. ","):gmatch("([^,]*),") do table.insert(fields, f) end
                local startStr = fields[2] or ""
                local h, m, s, cs = startStr:match("(%d+):(%d+):(%d+)%.(%d+)")
                if h then
                    local t = parseTime(h, m, s, cs)
                    local textPart = table.concat(fields, ",", 10):match("^%s*(.-)%s*$") or ""
                    local color = parseColorTag("{" .. (line:match("{[^}]*\\[1c][^}]*}") or "") .. "}")
                    textPart = textPart:gsub("{[^}]+}", "")
                    textPart = stripInlineTags(textPart)
                    if not tryExecBlock(textPart) and textPart ~= "" then addEntry(t, textPart, "", color) end
                end
            end
        end
    elseif fmt == "ttml" then
        for p in raw:gmatch("<p[^>]+>.-</p>") do
            local begin = p:match('begin="([^"]+)"')
            if begin then
                local h, m, s, ms = begin:match("(%d+):(%d+):(%d+)[%.,](%d+)")
                if not h then m, s, ms = begin:match("(%d+):(%d+)[%.,](%d+)"); h = 0 end
                if not m then s, ms = begin:match("(%d+)[%.,](%d+)"); h = 0; m = 0 end
                local t = parseTime(h, m, s, ms)
                local color = parseColorTag(p)
                local textPart = p:gsub("<br%s*/?>", " "):gsub("<[^>]+>", ""):match("^%s*(.-)%s*$") or ""
                textPart = stripInlineTags(textPart)
                if not tryExecBlock(textPart) and textPart ~= "" then addEntry(t, textPart, "", color) end
            end
        end
    else
        for line in raw:gmatch("[^\n]+") do
            local isBg = line:match("^%[bg:") or line:match("^%[v%d+b:")
            if not isBg then
                local execMatch = line:match("%[%d+:%d+[%.:]%d+%]%s*(.+)")
                if execMatch and execMatch:match("^%[%[") then
                    tryExecBlock(execMatch)
                else
                    local h2, m2, s2, ms2 = line:match("^%[(%d+):(%d+):(%d+)[%.,](%d+)%]")
                    local t2
                    if h2 then
                        t2 = parseTime(h2, m2, s2, ms2)
                    else
                        local m3, s3, ms3 = line:match("^%[(%d+):(%d+)%.(%d+)%]")
                        if m3 then t2 = parseTime(0, m3, s3, ms3) end
                    end
                    if t2 then
                        local rest = line:gsub("^%[[^%]]+%]%s*", "")
                        rest = rest:gsub("^v%d+[ab]?:%s*", "")
                        rest = rest:gsub("<[^>]+>", "")
                        rest = rest:gsub("%*%*%*%*", "")
                        rest = rest:match("^%s*(.-)%s*$") or ""
                        local color = parseColorTag(rest)
                        rest = stripInlineTags(rest)
                        local jp2 = rest:match("^(.-)%^") or rest
                        local en2 = rest:match("%^(.+)$") or ""
                        jp2 = jp2:match("^%s*(.-)%s*$") or ""
                        if jp2 ~= "" or en2 ~= "" then addEntry(t2, jp2, en2, color) end
                    end
                end
            end
        end
    end

    table.sort(lines, function(a, b) return a.time < b.time end)
    return lines
end

shared.G_lyrics = parseLyrics()

shared.G_playerChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
shared.G_playerHRP  = shared.G_playerChar:FindFirstChild("HumanoidRootPart")
shared.G_playerHum  = shared.G_playerChar:FindFirstChildOfClass("Humanoid")
shared.G_playerHead = shared.G_playerChar:FindFirstChild("Head")

local playerChar = shared.G_playerChar
local playerHRP  = shared.G_playerHRP
local playerHum  = shared.G_playerHum
local playerHead = shared.G_playerHead

if playerHum then playerHum.WalkSpeed = 0; playerHum.JumpHeight = 0 end
if playerHRP  then playerHRP.Anchored = true end

G.origPlayerTransp = {}
for _, part in ipairs(playerChar:GetDescendants()) do
    if part:IsA("BasePart") or part:IsA("MeshPart") then
        G.origPlayerTransp[part] = part.Transparency
        part.Transparency = 1
    end
end

pcall(function()
    for _, t in ipairs({
        Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Health,
        Enum.CoreGuiType.Backpack,   Enum.CoreGuiType.Chat,
        Enum.CoreGuiType.EmotesMenu
    }) do StarterGui:SetCoreGuiEnabled(t, false) end
end)

shared.G_origAmbient    = Lighting.Ambient
shared.G_origOutdoor    = Lighting.OutdoorAmbient
shared.G_origBrightness = Lighting.Brightness
shared.G_origClockTime  = Lighting.ClockTime
shared.G_origFogEnd     = Lighting.FogEnd
shared.G_origFogColor   = Lighting.FogColor
shared.G_origFOV        = Camera.FieldOfView

local origAmbient    = shared.G_origAmbient
local origOutdoor    = shared.G_origOutdoor
local origBrightness = shared.G_origBrightness
local origClockTime  = shared.G_origClockTime
local origFogEnd     = shared.G_origFogEnd
local origFogColor   = shared.G_origFogColor
local origFOV        = shared.G_origFOV

Lighting.ClockTime      = 0
Lighting.Brightness     = 2.2
Lighting.Ambient        = Color3.fromRGB(30, 60, 10)
Lighting.OutdoorAmbient = Color3.fromRGB(20, 50, 5)
Lighting.FogEnd         = 500
Lighting.FogColor       = Color3.fromRGB(10, 30, 5)

shared.G_sky = Instance.new("Sky", Lighting)
shared.G_sky.SkyboxBk = "rbxassetid://159454282"; shared.G_sky.SkyboxDn = "rbxassetid://159454282"
shared.G_sky.SkyboxFt = "rbxassetid://159454282"; shared.G_sky.SkyboxLf = "rbxassetid://159454282"
shared.G_sky.SkyboxRt = "rbxassetid://159454282"; shared.G_sky.SkyboxUp = "rbxassetid://159454282"
shared.G_sky.StarCount = 5000; shared.G_sky.CelestialBodiesShown = false

shared.G_colorCorrection = Instance.new("ColorCorrectionEffect", Lighting)
shared.G_colorCorrection.Brightness = 0.03; shared.G_colorCorrection.Contrast = 0.18
shared.G_colorCorrection.Saturation = 0.5;  shared.G_colorCorrection.TintColor = Color3.fromRGB(180, 220, 100)

shared.G_colorCorrectionR = Instance.new("ColorCorrectionEffect", Lighting)
shared.G_colorCorrectionR.TintColor = Color3.fromRGB(255, 160, 160); shared.G_colorCorrectionR.Enabled = false

shared.G_colorCorrectionB = Instance.new("ColorCorrectionEffect", Lighting)
shared.G_colorCorrectionB.TintColor = Color3.fromRGB(160, 160, 255); shared.G_colorCorrectionB.Enabled = false

shared.G_bloom = Instance.new("BloomEffect", Lighting)
shared.G_bloom.Intensity = 1.1; shared.G_bloom.Size = 22; shared.G_bloom.Threshold = 0.88

shared.G_sunRays = Instance.new("SunRaysEffect", Lighting)
shared.G_sunRays.Intensity = 0.22; shared.G_sunRays.Spread = 0.5

shared.G_blur = Instance.new("BlurEffect", Lighting)
shared.G_blur.Size = 0; shared.G_blur.Enabled = true

shared.G_depthOfField = Instance.new("DepthOfFieldEffect", Lighting)
shared.G_depthOfField.FarIntensity = 0.08; shared.G_depthOfField.NearIntensity = 0
shared.G_depthOfField.FocusDistance = 12; shared.G_depthOfField.InFocusRadius = 30
shared.G_depthOfField.Enabled = true

local colorCorrection  = shared.G_colorCorrection
local colorCorrectionR = shared.G_colorCorrectionR
local colorCorrectionB = shared.G_colorCorrectionB
local bloom            = shared.G_bloom
local blur             = shared.G_blur

local function doChromaticAberration(duration, strength)
    if G.chromaticActive then return end
    G.chromaticActive = true
    strength = strength or 0.4
    colorCorrectionR.Enabled = true; colorCorrectionB.Enabled = true
    colorCorrectionR.Brightness = strength; colorCorrectionB.Brightness = -strength * 0.5
    colorCorrectionR.Saturation = 1.5; colorCorrectionB.Saturation = 1.5
    task.delay(duration or 0.3, function()
        TweenService:Create(colorCorrectionR, TweenInfo.new(0.25), {Brightness = 0, Saturation = 0}):Play()
        TweenService:Create(colorCorrectionB, TweenInfo.new(0.25), {Brightness = 0, Saturation = 0}):Play()
        task.delay(0.3, function()
            colorCorrectionR.Enabled = false; colorCorrectionB.Enabled = false
            G.chromaticActive = false
        end)
    end)
end

local function doAudioBlurEffect()
    if G.audioBlurActive then return end
    G.audioBlurActive = true
    local snd = shared.G_sound
    local origVol = snd and snd.Volume or 0
    TweenService:Create(blur, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {Size = 18}):Play()
    TweenService:Create(Lighting, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {FogEnd = 120, Brightness = 0.6}):Play()
    if snd and snd.Parent then
        TweenService:Create(snd, TweenInfo.new(0.35), {Volume = origVol * 0.18}):Play()
    end
    task.delay(1.6, function()
        TweenService:Create(blur, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Size = 0}):Play()
        TweenService:Create(Lighting, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {FogEnd = 500, Brightness = 2.2}):Play()
        if snd and snd.Parent then
            TweenService:Create(snd, TweenInfo.new(0.7), {Volume = origVol}):Play()
        end
        task.delay(0.8, function() G.audioBlurActive = false end)
    end)
end

shared.G_singer = Players:CreateHumanoidModelFromUserId(Players:GetUserIdFromNameAsync("rhyan571"))
shared.G_singer.Name = LocalPlayer.Name; shared.G_singer.Parent = workspace

shared.G_singerHum  = shared.G_singer:FindFirstChildOfClass("Humanoid")
shared.G_singerHRP  = shared.G_singer:FindFirstChild("HumanoidRootPart")
shared.G_singerHead = shared.G_singer:FindFirstChild("Head")

local singer     = shared.G_singer
local singerHum  = shared.G_singerHum
local singerHRP  = shared.G_singerHRP
local singerHead = shared.G_singerHead

if singerHum then
    singerHum.WalkSpeed = 0; singerHum.JumpHeight = 0
    singerHum.NameDisplayDistance = 0; singerHum.HealthDisplayDistance = 0
end

for _, part in ipairs(singer:GetDescendants()) do
    if part:IsA("BasePart") or part:IsA("MeshPart") then part.Reflectance = 0 end
end

if singerHRP and playerHRP then
    local front = playerHRP.CFrame * CFrame.new(0, 0, -14)
    singerHRP.CFrame = CFrame.new(front.Position, playerHRP.Position)
    singerHRP.Anchored = true
    shared.G_singerBasePos = singerHRP.CFrame
end

local singerBasePos = shared.G_singerBasePos

if singerHead then
    shared.G_singerNameTag = Instance.new("BillboardGui", singerHead)
    shared.G_singerNameTag.Size = UDim2.new(0, 160, 0, 40)
    shared.G_singerNameTag.StudsOffset = Vector3.new(0, 4.5, 0)
    shared.G_singerNameTag.AlwaysOnTop = true
    local nameLabel = Instance.new("TextLabel", shared.G_singerNameTag)
    nameLabel.Size = UDim2.new(1,0,1,0); nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255,220,80)
    nameLabel.TextStrokeTransparency = 0; nameLabel.TextStrokeColor3 = Color3.fromRGB(180,100,0)
    nameLabel.Font = Enum.Font.GothamBold; nameLabel.TextSize = 22
    nameLabel.Text = "rhyan57"
end

shared.G_playerClone = Players:CreateHumanoidModelFromUserId(LocalPlayer.UserId)
shared.G_playerClone.Name = LocalPlayer.Name; shared.G_playerClone.Parent = workspace
shared.G_playerCloneHum = shared.G_playerClone:FindFirstChildOfClass("Humanoid")
shared.G_playerCloneHRP = shared.G_playerClone:FindFirstChild("HumanoidRootPart")

local playerClone    = shared.G_playerClone
local playerCloneHum = shared.G_playerCloneHum
local playerCloneHRP = shared.G_playerCloneHRP

if playerCloneHum then
    playerCloneHum.WalkSpeed = 0; playerCloneHum.JumpHeight = 0
    playerCloneHum.NameDisplayDistance = 0; playerCloneHum.HealthDisplayDistance = 0
end
if playerCloneHRP and playerHRP then
    playerCloneHRP.CFrame = playerHRP.CFrame; playerCloneHRP.Anchored = true
end
for _, part in ipairs(playerClone:GetDescendants()) do
    if part:IsA("BasePart") or part:IsA("MeshPart") then
        part.CastShadow = false; part.Material = Enum.Material.SmoothPlastic; part.Reflectance = 0
    end
end

G.playerCloneOrigScales = {}
if playerCloneHum then
    for _, n in ipairs({"BodyHeightScale","BodyWidthScale","BodyDepthScale","HeadScale"}) do
        local obj = playerCloneHum:FindFirstChild(n)
        if obj then G.playerCloneOrigScales[n] = obj.Value end
    end
end

local function growPlayerGiant()
    if G.playerGiantDone then return end
    G.playerGiantDone = true
    task.spawn(function()
        if not playerCloneHRP or not playerCloneHum then return end
        doChromaticAberration(0.6, 0.8)
        local growNames = {"BodyHeightScale","BodyWidthScale","BodyDepthScale","HeadScale"}
        local ringColors = {Color3.fromRGB(255,200,0),Color3.fromRGB(0,200,100),Color3.fromRGB(255,80,0),Color3.fromRGB(0,180,255)}
        for i = 1, 15 do
            for _, n in ipairs(growNames) do
                local obj = playerCloneHum:FindFirstChild(n)
                if obj then TweenService:Create(obj, TweenInfo.new(0.12, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Value = 1 + i * 0.45}):Play() end
            end
            task.spawn(function()
                local ring = Instance.new("Part", shared.G_mainFolder)
                ring.Size = Vector3.new(2, 0.4, 2); ring.Shape = Enum.PartType.Cylinder
                ring.Material = Enum.Material.Neon; ring.Color = ringColors[(i % #ringColors) + 1]
                ring.Anchored = true; ring.CanCollide = false; ring.CastShadow = false; ring.Transparency = 0.15
                ring.CFrame = CFrame.new(playerCloneHRP.Position) * CFrame.Angles(0, 0, math.pi/2)
                TweenService:Create(ring, TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = Vector3.new(3 + i * 8, 0.4, 3 + i * 8), Transparency = 1
                }):Play()
                Debris:AddItem(ring, 0.8)
            end)
            local pointGlow = Instance.new("PointLight", playerCloneHRP)
            pointGlow.Brightness = 5; pointGlow.Range = 25 + i * 3; pointGlow.Color = ringColors[(i % #ringColors) + 1]
            Debris:AddItem(pointGlow, 0.15)
            task.wait(0.07)
        end
        for _, n in ipairs(growNames) do
            local obj = playerCloneHum:FindFirstChild(n)
            if obj then TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Value = 7}):Play() end
        end
        task.spawn(function()
            local bigRing = Instance.new("Part", shared.G_mainFolder)
            bigRing.Size = Vector3.new(4, 0.6, 4); bigRing.Shape = Enum.PartType.Cylinder
            bigRing.Material = Enum.Material.Neon; bigRing.Color = Color3.fromRGB(255,220,0)
            bigRing.Anchored = true; bigRing.CanCollide = false; bigRing.CastShadow = false; bigRing.Transparency = 0
            bigRing.CFrame = CFrame.new(playerCloneHRP.Position) * CFrame.Angles(0, 0, math.pi/2)
            TweenService:Create(bigRing, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = Vector3.new(200, 0.6, 200), Transparency = 1
            }):Play()
            Debris:AddItem(bigRing, 1.4)
        end)
        doChromaticAberration(0.5, 1.0)
        task.wait(4)
        for _, n in ipairs(growNames) do
            local obj = playerCloneHum:FindFirstChild(n)
            if obj then TweenService:Create(obj, TweenInfo.new(1.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Value = G.playerCloneOrigScales[n] or 1}):Play() end
        end
        task.wait(1.5)
        G.playerGiantDone = false
    end)
end

G.hiddenParts = {}

local function hideNearbyParts()
    task.spawn(function()
        pcall(function() workspace.Terrain.Transparency = 1 end)
        while not G.finished do
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                    local isShowPart = obj:IsDescendantOf(singer) or obj:IsDescendantOf(playerClone)
                        or (shared.G_mainFolder and obj:IsDescendantOf(shared.G_mainFolder))
                    if isShowPart then continue end
                    local nearPlayer = playerHRP and (obj.Position - playerHRP.Position).Magnitude < 900
                    local nearSinger = singerHRP and (obj.Position - singerHRP.Position).Magnitude < 900
                    if (nearPlayer or nearSinger) and not G.hiddenParts[obj] then
                        G.hiddenParts[obj] = obj.Transparency
                        obj.Transparency = 1; obj.CastShadow = false
                    end
                end
            end
            task.wait(1.5)
        end
    end)
end

shared.G_mainFolder = Instance.new("Folder", workspace)
shared.G_mainFolder.Name = "_arigato_fx"
local mainFolder = shared.G_mainFolder
hideNearbyParts()

shared.G_spotLight = Instance.new("SpotLight", singerHRP or workspace)
shared.G_spotLight.Brightness = 4; shared.G_spotLight.Range = 70; shared.G_spotLight.Angle = 45
shared.G_spotLight.Color = Color3.fromRGB(255, 220, 80); shared.G_spotLight.Face = Enum.NormalId.Top

shared.G_pointLight = Instance.new("PointLight", singerHead or workspace)
shared.G_pointLight.Brightness = 1.5; shared.G_pointLight.Range = 22; shared.G_pointLight.Color = Color3.fromRGB(200, 220, 80)

shared.G_singerSpotDown = Instance.new("SpotLight", singerHRP or workspace)
shared.G_singerSpotDown.Brightness = 2.5; shared.G_singerSpotDown.Range = 55; shared.G_singerSpotDown.Angle = 40
shared.G_singerSpotDown.Color = Color3.fromRGB(100, 200, 50); shared.G_singerSpotDown.Face = Enum.NormalId.Bottom

local spotLight       = shared.G_spotLight
local pointLight      = shared.G_pointLight
local singerSpotDown  = shared.G_singerSpotDown

if singerHRP then
    shared.G_stagePlatform = Instance.new("Part", mainFolder)
    shared.G_stagePlatform.Size = Vector3.new(22, 0.5, 22)
    shared.G_stagePlatform.Anchored = true; shared.G_stagePlatform.CanCollide = false; shared.G_stagePlatform.CastShadow = false
    shared.G_stagePlatform.Material = Enum.Material.Neon; shared.G_stagePlatform.Color = Color3.fromRGB(0, 120, 40)
    shared.G_stagePlatform.Transparency = 0.35
    shared.G_stagePlatform.CFrame = CFrame.new(singerHRP.Position - Vector3.new(0, 5.5, 0))
    local stageGlow = Instance.new("PointLight", shared.G_stagePlatform)
    stageGlow.Brightness = 1.2; stageGlow.Range = 30; stageGlow.Color = Color3.fromRGB(0, 200, 80)
    local stageRing = Instance.new("Part", mainFolder)
    stageRing.Size = Vector3.new(26, 0.3, 26); stageRing.Shape = Enum.PartType.Cylinder
    stageRing.Anchored = true; stageRing.CanCollide = false; stageRing.CastShadow = false
    stageRing.Material = Enum.Material.Neon; stageRing.Color = Color3.fromRGB(255, 200, 0)
    stageRing.Transparency = 0.5
    stageRing.CFrame = CFrame.new(singerHRP.Position - Vector3.new(0, 5.3, 0)) * CFrame.Angles(0, 0, math.pi/2)
end

local stagePlatform = shared.G_stagePlatform

local showLightFolder = Instance.new("Folder", mainFolder)
showLightFolder.Name = "showlights"
G.showLights = {}
local NUM_SHOW_LIGHTS = 10

for i = 1, NUM_SHOW_LIGHTS do
    local base = Instance.new("Part", showLightFolder)
    base.Size = Vector3.new(1, 1, 1); base.Anchored = true; base.CanCollide = false; base.CastShadow = false
    base.Material = Enum.Material.Neon; base.Color = Color3.fromHSV((i-1)/NUM_SHOW_LIGHTS, 1, 0.85); base.Transparency = 0.35
    local top = Instance.new("Part", showLightFolder)
    top.Size = Vector3.new(0.5, 1.5, 0.5); top.Anchored = true; top.CanCollide = false; top.CastShadow = false
    top.Material = Enum.Material.Neon; top.Color = base.Color
    local a0 = Instance.new("Attachment", base); local a1 = Instance.new("Attachment", top)
    local beam = Instance.new("Beam", showLightFolder)
    beam.Attachment0 = a0; beam.Attachment1 = a1
    beam.Width0 = 2; beam.Width1 = 0.04; beam.FaceCamera = true; beam.LightEmission = 0.7; beam.LightInfluence = 0
    beam.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, base.Color),
        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(((i-1)/NUM_SHOW_LIGHTS + 0.5) % 1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
    })
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.7, 0.45), NumberSequenceKeypoint.new(1, 1),
    })
    beam.Segments = 8
    local sl = Instance.new("SpotLight", top)
    sl.Brightness = 3; sl.Range = 65; sl.Angle = 14; sl.Color = base.Color
    table.insert(G.showLights, {base=base, top=top, beam=beam, sl=sl, idx=i})
end

local function updateShowLights(t)
    if not singerHRP then return end
    local pos = singerHRP.Position
    for _, sl in ipairs(G.showLights) do
        local i = sl.idx
        local baseAngle = (i-1)*(math.pi*2/NUM_SHOW_LIGHTS)
        local baseR = 32
        sl.base.Position = pos + Vector3.new(math.cos(baseAngle)*baseR, -2, math.sin(baseAngle)*baseR)
        local swingSpeed = 0.7 + (i % 3) * 0.35
        local swingAmp   = math.pi / 4.5
        local targetAngle = baseAngle + math.sin(t * swingSpeed + i * 1.1) * swingAmp
        local targetDist  = 18 + math.sin(t * 0.55 + i) * 10
        local targetHeight = 32 + math.cos(t * 0.45 + i * 0.8) * 16
        sl.top.Position = pos + Vector3.new(math.cos(targetAngle)*targetDist, targetHeight, math.sin(targetAngle)*targetDist)
        local hue = ((t * 0.06 + (i-1)/NUM_SHOW_LIGHTS) % 1)
        local newColor = Color3.fromHSV(hue, 1, 0.9)
        sl.base.Color = newColor; sl.sl.Color = newColor
        sl.beam.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, newColor),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV((hue+0.5)%1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
        })
    end
end

local pentaFolder = Instance.new("Folder", mainFolder)
pentaFolder.Name = "pentagon"
G.pentaParts = {}
local NUM_SIDES = 6; local PENTA_RADIUS = 18

for i = 1, NUM_SIDES do
    local p = Instance.new("Part", pentaFolder)
    p.Size = Vector3.new(0.7, 9, 1.2); p.Anchored = true; p.CanCollide = false
    p.Material = Enum.Material.Neon; p.CastShadow = false
    p.Color = Color3.fromHSV((i-1)/NUM_SIDES, 1, 1)
    local a0 = Instance.new("Attachment", p); a0.Position = Vector3.new(0, 0.5, 0)
    local a1 = Instance.new("Attachment", p); a1.Position = Vector3.new(0, -0.5, 0)
    local tr = Instance.new("Trail", p)
    tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.18; tr.MinLength = 0
    tr.Color = ColorSequence.new(p.Color, Color3.fromRGB(255,255,255))
    tr.Transparency = NumberSequence.new(0.2, 1); tr.LightEmission = 1
    table.insert(G.pentaParts, p)
end

local function updatePentagon(angle)
    if not singerHRP or not singerHRP.Parent then return end
    local base = singerHRP.CFrame * CFrame.new(0, 2, 10)
    for i, p in ipairs(G.pentaParts) do
        local a1 = angle + (i-1)*(math.pi*2/NUM_SIDES)
        local a2 = angle + i    *(math.pi*2/NUM_SIDES)
        local r  = PENTA_RADIUS
        local p1 = base.Position + Vector3.new(math.cos(a1)*r, math.sin(a1)*r*0.5, math.sin(a1)*0.5)
        local p2 = base.Position + Vector3.new(math.cos(a2)*r, math.sin(a2)*r*0.5, math.sin(a2)*0.5)
        local mid  = (p1+p2)/2; local len  = (p2-p1).Magnitude; local look = (p2-p1).Unit
        p.Size   = Vector3.new(0.7, len, 1.2)
        p.CFrame = CFrame.lookAt(mid, mid+look) * CFrame.Angles(math.pi/2, 0, 0)
        p.Color  = Color3.fromHSV(((angle*0.05 + (i-1)/NUM_SIDES) % 1), 1, 1)
    end
end

local orbitFolder = Instance.new("Folder", mainFolder)
orbitFolder.Name = "orbit"
G.orbitParts = {}
local NUM_ORBIT = 29; local ORBIT_RADIUS = 22

for i = 1, NUM_ORBIT do
    local p = Instance.new("Part", orbitFolder)
    p.Size = Vector3.new(1.6, 1.6, 1.6); p.Shape = Enum.PartType.Ball
    p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Neon; p.CastShadow = false
    p.Color = Color3.fromHSV((i-1)/NUM_ORBIT, 1, 1)
    local pl = Instance.new("PointLight", p); pl.Brightness = 1.5; pl.Range = 10; pl.Color = p.Color
    local att0 = Instance.new("Attachment", p); att0.Position = Vector3.new(0, 0.5, 0)
    local att1 = Instance.new("Attachment", p); att1.Position = Vector3.new(0, -0.5, 0)
    local tr = Instance.new("Trail", p)
    tr.Attachment0 = att0; tr.Attachment1 = att1
    tr.Lifetime = 0.25; tr.MinLength = 0; tr.LightEmission = 1
    tr.Color = ColorSequence.new(p.Color, Color3.fromRGB(255,255,255))
    tr.Transparency = NumberSequence.new(0.2, 1)
    table.insert(G.orbitParts, p)
end

G.outerOrbitParts = {}
local NUM_OUTER = 16
for i = 1, NUM_OUTER do
    local p = Instance.new("Part", orbitFolder)
    p.Size = Vector3.new(3, 3, 3); p.Shape = Enum.PartType.Ball
    p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Neon; p.CastShadow = false
    p.Color = Color3.fromHSV((i-1)/NUM_OUTER, 1, 1)
    local pl = Instance.new("PointLight", p); pl.Brightness = 2; pl.Range = 16; pl.Color = p.Color
    table.insert(G.outerOrbitParts, p)
end

G.ringOrbitParts = {}
local NUM_RING_ORBIT = 19
for i = 1, NUM_RING_ORBIT do
    local ring = Instance.new("Part", orbitFolder)
    ring.Size = Vector3.new(0.4, 6, 6); ring.Shape = Enum.PartType.Cylinder
    ring.Anchored = true; ring.CanCollide = false; ring.Material = Enum.Material.Neon; ring.CastShadow = false
    ring.Color = Color3.fromHSV((i-1)/NUM_RING_ORBIT, 1, 1); ring.Transparency = 0.35
    table.insert(G.ringOrbitParts, ring)
end

local function updateOrbit(t)
    if not singerHRP or not singerHRP.Parent then return end
    local center = singerHRP.Position + Vector3.new(0, 6, 0)
    for i, p in ipairs(G.orbitParts) do
        local angle = t * 1.3 + (i-1)*(math.pi*2/NUM_ORBIT)
        p.Position = center + Vector3.new(math.cos(angle)*ORBIT_RADIUS, math.sin(t*2 + i)*5, math.sin(angle)*ORBIT_RADIUS)
        p.Color = Color3.fromHSV(((t*0.1 + (i-1)/NUM_ORBIT) % 1), 1, 1)
        local pl = p:FindFirstChildOfClass("PointLight")
        if pl then pl.Color = p.Color end
    end
    local outerR = 42
    for i, p in ipairs(G.outerOrbitParts) do
        local angle = -t * 0.65 + (i-1)*(math.pi*2/NUM_OUTER)
        p.Position = singerHRP.Position + Vector3.new(math.cos(angle)*outerR, math.sin(t*1.4 + i*1.3)*10 + 12, math.sin(angle)*outerR)
        p.Color = Color3.fromHSV(((t*0.08 + (i-1)/NUM_OUTER + 0.5) % 1), 1, 1)
        local pl = p:FindFirstChildOfClass("PointLight")
        if pl then pl.Color = p.Color end
    end
    local ringR = 28
    for i, ring in ipairs(G.ringOrbitParts) do
        local inclination = (i - 1) * (math.pi / NUM_RING_ORBIT)
        local speed = 0.28 + (i - 1) * 0.06
        local angle = t * speed + (i - 1) * (math.pi * 2 / NUM_RING_ORBIT)
        local tiltCF = CFrame.Angles(inclination, 0, 0)
        local localPos = Vector3.new(math.cos(angle) * ringR, 0, math.sin(angle) * ringR)
        local worldOffset = tiltCF:VectorToWorldSpace(localPos)
        local pos = singerHRP.Position + worldOffset + Vector3.new(0, 8, 0)
        ring.CFrame = CFrame.new(pos) * tiltCF * CFrame.Angles(0, angle, math.pi / 2)
        ring.Color = Color3.fromHSV(((t * 0.07 + (i - 1) / NUM_RING_ORBIT) % 1), 1, 1)
        ring.Transparency = 0.2 + math.abs(math.sin(t * 0.9 + i)) * 0.3
    end
end

local starFolder = Instance.new("Folder", mainFolder)
starFolder.Name = "stars"
G.starParts = {}
local NUM_STARS = 40
for i = 1, NUM_STARS do
    local s = Instance.new("Part", starFolder)
    s.Size = Vector3.new(0.5,0.5,0.5); s.Shape = Enum.PartType.Ball
    s.Anchored = true; s.CanCollide = false; s.Material = Enum.Material.Neon; s.CastShadow = false
    s.Color = Color3.fromHSV(math.random(), 1, 1)
    table.insert(G.starParts, {part=s, ox=math.random(-70,70), oy=math.random(25,90), oz=math.random(-70,70), phase=math.random()*math.pi*2, speed=math.random()*0.6+0.3})
end

local function updateStars(t)
    if not singerHRP then return end
    for _, sd in ipairs(G.starParts) do
        local twinkle = math.abs(math.sin(t*sd.speed + sd.phase))
        local sz = twinkle*0.7+0.1
        sd.part.Size = Vector3.new(sz,sz,sz)
        sd.part.Position = singerHRP.Position + Vector3.new(sd.ox, sd.oy, sd.oz)
        sd.part.Color = Color3.fromHSV(((t*0.05 + sd.phase) % 1), 1, 1)
    end
end

local nebulaFolder = Instance.new("Folder", mainFolder)
nebulaFolder.Name = "nebula"
G.nebulaParts = {}
local NUM_NEBULA = 16
for i = 1, NUM_NEBULA do
    local p = Instance.new("Part", nebulaFolder)
    p.Size = Vector3.new(math.random(7,16), math.random(7,16), 0.2)
    p.Anchored = true; p.CanCollide = false; p.CastShadow = false
    p.Material = Enum.Material.Neon; p.Color = Color3.fromHSV((i-1)/NUM_NEBULA, 0.8, 1); p.Transparency = 0.72
    table.insert(G.nebulaParts, {part=p, rA=math.random()*math.pi*2, rD=math.random(35, 65), rH=math.random(18, 55), phase=math.random()*math.pi*2, speed=math.random()*0.18+0.04})
end

local function updateNebula(t)
    if not singerHRP then return end
    for _, nd in ipairs(G.nebulaParts) do
        local angle = nd.rA + t * nd.speed
        local pos = singerHRP.Position + Vector3.new(math.cos(angle)*nd.rD, nd.rH + math.sin(t*0.3 + nd.phase)*6, math.sin(angle)*nd.rD)
        nd.part.CFrame = CFrame.new(pos) * CFrame.Angles(math.sin(t*0.1+nd.phase)*0.3, angle, 0)
        nd.part.Color = Color3.fromHSV(((t * 0.04 + nd.phase) % 1), 0.85, 1)
        nd.part.Transparency = 0.62 + math.sin(t * nd.speed * 2 + nd.phase) * 0.15
    end
end

local confettiFolder = Instance.new("Folder", mainFolder)
confettiFolder.Name = "confetti"

local COPA_COLORS = {
    Color3.fromRGB(255, 220, 0),    -- Amarelo (Brasil/Colômbia)
    Color3.fromRGB(0, 180, 80),    -- Verde (México/Arábia Saudita)
    Color3.fromRGB(255, 80, 0),    -- Laranja (Holanda)
    Color3.fromRGB(255, 255, 255),  -- Branco (Alemanha/Inglaterra)
    Color3.fromRGB(0, 32, 91),      -- Azul Escuro (França/Itália)
    Color3.fromRGB(218, 41, 28),    -- Vermelho (Canadá/Espanha)
    Color3.fromRGB(116, 172, 223),  -- Azul Claro (Argentina/Uruguai)
    Color3.fromRGB(141, 20, 59),    -- Vinho (Catar/Venezuela)
    Color3.fromRGB(0, 0, 0),        -- Preto (Nova Zelândia)
    Color3.fromRGB(254, 203, 0),    -- Amarelo Ouro (Equador)
    Color3.fromRGB(227, 27, 35),    -- Vermelho Vivo (Bélgica/Suíça)
    Color3.fromRGB(12, 35, 64),     -- Azul Marinho (EUA/Japão)
    Color3.fromRGB(0, 104, 71),     -- Verde Escuro (Nigéria/Camarões)
    Color3.fromRGB(218, 18, 26),    -- Vermelho Sangue (Marrocos/Portugal)
    Color3.fromRGB(0, 123, 196),    -- Azul Royal (Suécia/Ucrânia)
    Color3.fromRGB(244, 195, 0),    -- Amarelo Canário (Austrália)
    Color3.fromRGB(200, 16, 46),    -- Vermelho Escuro (Coreia do Sul)
    Color3.fromRGB(0, 154, 68),     -- Verde Copa (Argélia/Senegal)
    Color3.fromRGB(196, 30, 58),    -- Carmim (Croácia/Sérvia)
    Color3.fromRGB(0, 94, 184),     -- Azul Escocês (Escócia)
    Color3.fromRGB(224, 0, 37),     -- Vermelho Turco (Turquia)
    Color3.fromRGB(206, 17, 38),    -- Vermelho Intenso (Tunísia/Egito)
    Color3.fromRGB(255, 242, 0),    -- Amarelo Brilhante (Jamaica)
    Color3.fromRGB(11, 29, 58),     -- Azul Petróleo (Panamá/Honduras)
    Color3.fromRGB(0, 166, 81),     -- Verde Bandeira (Mali/Costa do Marfim)
    Color3.fromRGB(221, 0, 0),      -- Vermelho Fogo (Dinamarca/Áustria)
    Color3.fromRGB(0, 81, 186),     -- Azul Celeste (Grécia)
    Color3.fromRGB(252, 209, 22),   -- Amarelo Sol (Gana/Iraque)
    Color3.fromRGB(213, 0, 50),     -- Magenta/Vermelho (Peru/Chile)
    Color3.fromRGB(0, 114, 206),    -- Azul Vivo (Ubequistão)
    Color3.fromRGB(0, 107, 63),     -- Verde Musgo (Irã)
    Color3.fromRGB(166, 25, 46),    -- Cereja (República Checa)
    Color3.fromRGB(255, 204, 0),    -- Amarelo Torrado (Romênia)
    Color3.fromRGB(0, 47, 108),     -- Azul Noturno (Costa Rica)
    Color3.fromRGB(117, 16, 35),    -- Bordô (Geórgia)
    Color3.fromRGB(0, 145, 213),    -- Azul Turquesa (U do Norte)
    Color3.fromRGB(204, 9, 47),     -- Escarlate (Angola/Zâmbia)
    Color3.fromRGB(0, 122, 61),     -- Verde Oliva (África do Sul)
    Color3.fromRGB(198, 12, 48),    -- Vermelho Coral (Polônia)
    Color3.fromRGB(0, 51, 153),     -- Azul Elétrico (Noruega)
    Color3.fromRGB(253, 185, 19),   -- Amarelo Ocre (Omã)
    Color3.fromRGB(204, 0, 0),      -- Vermelho Puro (Hungria)
    Color3.fromRGB(0, 165, 81),     -- Verde Menta (Bolívia)
    Color3.fromRGB(0, 76, 151),     -- Azul Profundo (Eslováquia)
    Color3.fromRGB(210, 16, 52),    -- Rubi (País de Gales)
    Color3.fromRGB(255, 103, 31),   -- Laranja Escuro (Irlanda)
    Color3.fromRGB(15, 71, 175),    -- Azul Índigo (Paraguai)
    Color3.fromRGB(255, 198, 30),   -- Amarelo Neon (Emirados Árabes)
}

local function spawnConfetti(count, origin)
    origin = origin or (singerHRP and singerHRP.Position or Vector3.new(0,10,0))
    for i = 1, count do
        task.spawn(function()
            local c = Instance.new("Part", confettiFolder)
            c.Size = Vector3.new(0.35, 0.06, 0.7); c.Material = Enum.Material.Neon
            c.Anchored = false; c.CanCollide = false; c.CastShadow = false
            c.Color = COPA_COLORS[math.random(1, #COPA_COLORS)]
            c.CFrame = CFrame.new(origin + Vector3.new(math.random(-6,6), math.random(0,6), math.random(-6,6)))
                * CFrame.Angles(math.random()*math.pi*2, math.random()*math.pi*2, math.random()*math.pi*2)
            local bv = Instance.new("BodyVelocity", c)
            bv.Velocity = Vector3.new(math.random(-18,18), math.random(10,35), math.random(-18,18))
            bv.MaxForce = Vector3.new(1e5,1e5,1e5)
            TweenService:Create(c, TweenInfo.new(2, Enum.EasingStyle.Sine), {Transparency = 1}):Play()
            Debris:AddItem(c, 2.3)
        end)
    end
end

local function spawnSkyConfetti(count)
    if not playerHRP then return end
    local origin = playerHRP.Position + Vector3.new(0, 55, 0)
    for i = 1, count do
        task.spawn(function()
            local c = Instance.new("Part", confettiFolder)
            c.Size = Vector3.new(0.4, 0.07, 0.8); c.Material = Enum.Material.Neon
            c.Anchored = false; c.CanCollide = false; c.CastShadow = false
            c.Color = COPA_COLORS[math.random(1, #COPA_COLORS)]
            c.CFrame = CFrame.new(origin + Vector3.new(math.random(-35,35), math.random(-5,12), math.random(-35,35)))
                * CFrame.Angles(math.random()*math.pi*2, math.random()*math.pi*2, math.random()*math.pi*2)
            local bv = Instance.new("BodyVelocity", c)
            bv.Velocity = Vector3.new(math.random(-8,8), math.random(-22,-6), math.random(-8,8))
            bv.MaxForce = Vector3.new(1e5,1e5,1e5)
            TweenService:Create(c, TweenInfo.new(3.5, Enum.EasingStyle.Sine), {Transparency = 1}):Play()
            Debris:AddItem(c, 3.8)
        end)
    end
end

shared.G_skyConfettiConn = RunService.RenderStepped:Connect(function()
    if G.finished then
        if shared.G_skyConfettiConn then shared.G_skyConfettiConn:Disconnect() end
        return
    end
    if math.random(1, 5) == 1 then
        spawnSkyConfetti(math.random(4, 9))
    end
end)

local spiralFolder = Instance.new("Folder", mainFolder)
spiralFolder.Name = "spiral"

local function spawnSpiralRings(count)
    if not singerHRP then return end
    task.spawn(function()
        for i = 1, count do
            task.spawn(function()
                local r = Instance.new("Part", spiralFolder)
                r.Size = Vector3.new(0.4, 0.4, 0.4); r.Shape = Enum.PartType.Ball
                r.Material = Enum.Material.Neon; r.Anchored = true; r.CanCollide = false; r.CastShadow = false
                r.Color = Color3.fromHSV((i-1)/count, 1, 1)
                local startPos = singerHRP.Position
                local angle = (i-1) * (math.pi * 2 / count)
                local t = 0
                local c2
                c2 = RunService.RenderStepped:Connect(function(dt)
                    t = t + dt * 3
                    if not singerHRP or not singerHRP.Parent or t > 2 then r:Destroy(); c2:Disconnect(); return end
                    local radius = (1 - t/2) * 14; local height = t * 18
                    r.Position = startPos + Vector3.new(math.cos(angle + t*2)*radius, height, math.sin(angle + t*2)*radius)
                    r.Color = Color3.fromHSV(((t * 0.2 + (i-1)/count) % 1), 1, 1)
                    local sz = math.max(0.1, 1.5 - t * 0.6)
                    r.Size = Vector3.new(sz,sz,sz); r.Transparency = math.min(1, t * 0.5)
                end)
            end)
            task.wait(0.04)
        end
    end)
end

local function spawnDNAHelix(duration)
    if not singerHRP then return end
    task.spawn(function()
        local numDots = 30
        local t = 0
        local helixFolder = Instance.new("Folder", spiralFolder)
        for i = 1, numDots do
            for j = 1, 2 do
                local dot = Instance.new("Part", helixFolder)
                dot.Size = Vector3.new(0.7,0.7,0.7); dot.Shape = Enum.PartType.Ball
                dot.Material = Enum.Material.Neon; dot.Anchored = true
                dot.CanCollide = false; dot.CastShadow = false
                dot.Color = Color3.fromHSV((i-1)/numDots, 1, 1)
                local c2
                c2 = RunService.RenderStepped:Connect(function(dt)
                    t = t + dt
                    if not singerHRP or not singerHRP.Parent or t > duration then dot:Destroy(); c2:Disconnect(); return end
                    local baseAngle = (i-1) * (math.pi * 2 / numDots) + t * 1.5 + (j == 2 and math.pi or 0)
                    dot.Position = singerHRP.Position + Vector3.new(math.cos(baseAngle)*8, (i-1)*1.1 - 10, math.sin(baseAngle)*8)
                    dot.Color = Color3.fromHSV(((t*0.08 + (i-1)/numDots + (j-1)*0.5) % 1), 1, 1)
                end)
            end
        end
    end)
end

local function spawnGeometricRing(radius, height, numParts, speed, duration)
    if not singerHRP then return end
    task.spawn(function()
        local parts = {}
        local t = 0
        for i = 1, numParts do
            local p = Instance.new("Part", spiralFolder)
            p.Size = Vector3.new(0.5, 5, 0.5); p.Material = Enum.Material.Neon
            p.Anchored = true; p.CanCollide = false; p.CastShadow = false
            p.Color = Color3.fromHSV((i-1)/numParts, 1, 1)
            table.insert(parts, p)
        end
        local c2
        c2 = RunService.RenderStepped:Connect(function(dt)
            t = t + dt
            if not singerHRP or not singerHRP.Parent or t > duration then
                for _, pp in ipairs(parts) do pcall(function() pp:Destroy() end) end
                c2:Disconnect(); return
            end
            for i, pp in ipairs(parts) do
                local angle = (i-1)*(math.pi*2/numParts) + t * speed
                pp.CFrame = CFrame.new(singerHRP.Position + Vector3.new(math.cos(angle)*radius, height + math.sin(t*2+i)*3, math.sin(angle)*radius))
                    * CFrame.Angles(0, angle + math.pi/2, math.sin(t + i) * 0.3)
                pp.Color = Color3.fromHSV(((t*0.06 + (i-1)/numParts) % 1), 1, 1)
                pp.Transparency = math.max(0, math.min(1, (t - duration + 0.5) / 0.5))
            end
        end)
    end)
end

local function spawnFloorHexGrid()
    if not singerHRP then return end
    local hexFolder = Instance.new("Folder", mainFolder)
    hexFolder.Name = "hexgrid"
    local hexCount = 24
    local hexData = {}
    for i = 1, hexCount do
        local h = Instance.new("Part", hexFolder)
        h.Size = Vector3.new(3.5, 0.15, 3.5); h.Anchored = true; h.CanCollide = false; h.CastShadow = false
        h.Material = Enum.Material.Neon; h.Color = Color3.fromHSV((i-1)/hexCount, 1, 1); h.Transparency = 0.6
        local baseAngle = (i-1) * (math.pi * 2 / hexCount); local baseR = math.random(3, 12)
        h.CFrame = CFrame.new(singerHRP.Position.X + math.cos(baseAngle)*baseR, singerHRP.Position.Y - 5.2, singerHRP.Position.Z + math.sin(baseAngle)*baseR)
        table.insert(hexData, {part=h, baseAngle=baseAngle, phase=math.random()*math.pi*2})
    end
    local t = 0
    local hexConn
    hexConn = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        if G.finished then hexConn:Disconnect(); hexFolder:Destroy(); return end
        for _, hd in ipairs(hexData) do
            hd.part.Color = Color3.fromHSV(((t*0.04 + hd.baseAngle/(math.pi*2)) % 1), 1, 1)
            hd.part.Transparency = 0.4 + math.abs(math.sin(t * 1.5 + hd.phase)) * 0.35
        end
    end)
end
spawnFloorHexGrid()

local specFolder = Instance.new("Folder", mainFolder)
specFolder.Name = "spectrum3d"
local NUM_SPEC = 48
G.specBars = {}
if singerHRP then
    for i = 1, NUM_SPEC do
        local angle = (i-1) * (math.pi*2 / NUM_SPEC)
        local bar = Instance.new("Part", specFolder)
        bar.Anchored = true; bar.CanCollide = false; bar.CastShadow = false
        bar.Material = Enum.Material.Neon; bar.Size = Vector3.new(0.5, 1, 0.5)
        bar.Color = Color3.fromHSV((i-1)/NUM_SPEC, 1, 1)
        local pl = Instance.new("PointLight", bar); pl.Brightness = 1; pl.Range = 5; pl.Color = bar.Color
        table.insert(G.specBars, {part=bar, angle=angle, pl=pl})
    end
end

local waveFolder2 = Instance.new("Folder", mainFolder)
waveFolder2.Name = "waveform3d"
local NUM_WAVE = 64
G.waveParts3d = {}
if singerHRP then
    for i = 1, NUM_WAVE do
        local wp = Instance.new("Part", waveFolder2)
        wp.Anchored = true; wp.CanCollide = false; wp.CastShadow = false
        wp.Material = Enum.Material.Neon; wp.Size = Vector3.new(0.3, 0.3, 0.3)
        wp.Shape = Enum.PartType.Ball; wp.Color = Color3.fromHSV((i-1)/NUM_WAVE, 0.8, 1)
        table.insert(G.waveParts3d, wp)
    end
end

local function updateSpectrum3D(t)
    if not singerHRP or #G.specBars == 0 then return end
    local spec; pcall(function() spec = shared.G_audioAnalyzer:GetSpectrum() end)
    local center = singerHRP.Position; local r = 14
    for i, bd in ipairs(G.specBars) do
        local rawVal
        if spec and #spec > 0 then
            rawVal = math.clamp(math.sqrt(spec[math.max(1, math.floor(math.pow(#spec, i/NUM_SPEC)))] or 0) * 2, 0, 1)
        else
            rawVal = math.abs(math.sin(t * 3 + i * 0.4)) * getLoudness()
        end
        local h = math.clamp(rawVal * 16, 0.3, 20)
        local hue = ((t * 0.05 + (i-1)/NUM_SPEC) % 1)
        bd.part.Size = Vector3.new(0.5, h, 0.5)
        bd.part.CFrame = CFrame.new(center + Vector3.new(math.cos(bd.angle)*r, h/2 - 4, math.sin(bd.angle)*r))
        bd.part.Color = Color3.fromHSV(hue, 1, 1); bd.pl.Color = bd.part.Color
        bd.pl.Brightness = 0.5 + rawVal * 2
    end
end

local function updateWaveform3D(t)
    if not singerHRP or #G.waveParts3d == 0 then return end
    local loudness = getLoudness()
    local center = singerHRP.Position + Vector3.new(0, 8, 0); local lineLen = 30
    for i, wp in ipairs(G.waveParts3d) do
        local frac = (i-1) / (NUM_WAVE-1)
        local wave = math.sin(t * 6 + frac * math.pi * 4) * loudness * 3 + math.sin(t * 11 + frac * math.pi * 8) * loudness * 1.2
        wp.Position = center + Vector3.new((frac - 0.5) * lineLen, wave, 0)
        wp.Color = Color3.fromHSV(((t * 0.08 + frac) % 1), 1, 1)
        wp.Size = Vector3.new(0.3 + loudness * 0.4, 0.3 + math.abs(wave) * 0.15, 0.3)
    end
end

local waveFolder = Instance.new("Folder", mainFolder)
waveFolder.Name = "soundwaves"
local NUM_WAVE_BARS = 32
G.waveBars = {}
for i = 1, NUM_WAVE_BARS do
    local bar = Instance.new("Part", waveFolder)
    bar.Anchored = true; bar.CanCollide = false; bar.CastShadow = false
    bar.Material = Enum.Material.Neon; bar.Size = Vector3.new(0.55, 1, 0.55)
    bar.Color = Color3.fromHSV((i-1)/NUM_WAVE_BARS, 1, 1); bar.Transparency = 0.1
    local bpl = Instance.new("PointLight", bar); bpl.Brightness = 1.2; bpl.Range = 6; bpl.Color = bar.Color
    table.insert(G.waveBars, bar)
end

local function updateSoundWaves(t, bStr)
    if not singerHRP then return end
    local center = singerHRP.Position; local waveRadius = 9
    for i, bar in ipairs(G.waveBars) do
        local angle = (i-1) * (math.pi*2 / NUM_WAVE_BARS)
        local freqSim = math.abs(math.sin(t * (2 + i * 0.18) + i * 0.4)) * (0.7 + bStr * 0.8)
        local barH = 0.5 + freqSim * 8
        bar.Size = Vector3.new(0.55, barH, 0.55)
        bar.CFrame = CFrame.new(center.X + math.cos(angle)*waveRadius, center.Y + barH/2, center.Z + math.sin(angle)*waveRadius)
        bar.Color = Color3.fromHSV(((t * 0.08 + (i-1)/NUM_WAVE_BARS) % 1), 1, 1)
        local bpl2 = bar:FindFirstChildOfClass("PointLight")
        if bpl2 then bpl2.Color = bar.Color; bpl2.Brightness = 0.8 + freqSim * 2 end
    end
end

local starShapeFolder = Instance.new("Folder", mainFolder)
starShapeFolder.Name = "starshape"
local NUM_STAR_POINTS = 5
G.starEdgeParts = {}

local function rebuildStarEdges()
    for _, p in ipairs(G.starEdgeParts) do pcall(function() p:Destroy() end) end
    G.starEdgeParts = {}
    if not singerHRP then return end
    local totalVerts = NUM_STAR_POINTS * 2
    for i = 1, totalVerts do
        local edge = Instance.new("Part", starShapeFolder)
        edge.Size = Vector3.new(0.45, 0.25, 1); edge.Anchored = true; edge.CanCollide = false; edge.CastShadow = false
        edge.Material = Enum.Material.Neon; edge.Color = Color3.fromHSV((i-1)/totalVerts, 1, 1); edge.Transparency = 0.1
        local spl = Instance.new("PointLight", edge); spl.Brightness = 2; spl.Range = 10; spl.Color = edge.Color
        table.insert(G.starEdgeParts, edge)
    end
end
rebuildStarEdges()

local function updateStarShape(t)
    G.starAngle = G.starAngle + 0.008
    if not singerHRP or #G.starEdgeParts == 0 then return end
    local cx = singerHRP.Position.X; local cz = singerHRP.Position.Z; local cy = singerHRP.Position.Y - 5.0
    local outerR = 16; local innerR = 7; local allVerts = {}
    for i = 1, NUM_STAR_POINTS do
        local outerAngle = (i-1)*(math.pi*2/NUM_STAR_POINTS) - math.pi/2 + G.starAngle
        local innerAngle = outerAngle + math.pi/NUM_STAR_POINTS
        table.insert(allVerts, Vector3.new(cx + math.cos(outerAngle)*outerR, cy, cz + math.sin(outerAngle)*outerR))
        table.insert(allVerts, Vector3.new(cx + math.cos(innerAngle)*innerR, cy, cz + math.sin(innerAngle)*innerR))
    end
    for i, edge in ipairs(G.starEdgeParts) do
        local v1 = allVerts[i]; local v2 = allVerts[(i % #allVerts) + 1]
        if v1 and v2 then
            local mid = (v1 + v2) / 2; local len = (v2 - v1).Magnitude; local look = (v2 - v1).Unit
            edge.Size = Vector3.new(0.45 + math.abs(math.sin(t*2+i))*0.3, 0.25, len)
            edge.CFrame = CFrame.lookAt(mid, mid + look)
            edge.Color = Color3.fromHSV(((t*0.06 + (i-1)/#G.starEdgeParts) % 1), 1, 1)
            local spl2 = edge:FindFirstChildOfClass("PointLight")
            if spl2 then spl2.Color = edge.Color end
        end
    end
end

local hexagonShapeFolder = Instance.new("Folder", mainFolder)
hexagonShapeFolder.Name = "hexshape"
G.hexShapeEdges = {}

local function rebuildHexEdges()
    for _, e in ipairs(G.hexShapeEdges) do pcall(function() e:Destroy() end) end
    G.hexShapeEdges = {}
    if not singerHRP then return end
    for i = 1, 6 do
        local edge3 = Instance.new("Part", hexagonShapeFolder)
        edge3.Size = Vector3.new(0.5, 0.3, 1); edge3.Anchored = true; edge3.CanCollide = false; edge3.CastShadow = false
        edge3.Material = Enum.Material.Neon; edge3.Color = Color3.fromHSV((i-1)/6, 1, 1); edge3.Transparency = 0.1
        local hpl = Instance.new("PointLight", edge3); hpl.Brightness = 2.5; hpl.Range = 12; hpl.Color = edge3.Color
        table.insert(G.hexShapeEdges, edge3)
    end
end
rebuildHexEdges()

local function updateHexShape(t)
    G.hexShapeAngle = G.hexShapeAngle + 0.012
    if not singerHRP or #G.hexShapeEdges == 0 then return end
    local sides2 = 6; local radius = 20 + math.sin(t*0.4)*4
    local cx = singerHRP.Position.X; local cz = singerHRP.Position.Z; local cy = singerHRP.Position.Y - 5.0
    for i, edge3 in ipairs(G.hexShapeEdges) do
        local a1 = (i-1)*(math.pi*2/sides2) + G.hexShapeAngle; local a2 = i*(math.pi*2/sides2) + G.hexShapeAngle
        local v1 = Vector3.new(cx + math.cos(a1)*radius, cy, cz + math.sin(a1)*radius)
        local v2 = Vector3.new(cx + math.cos(a2)*radius, cy, cz + math.sin(a2)*radius)
        local mid3 = (v1+v2)/2; local len3 = (v2-v1).Magnitude; local look3 = (v2-v1).Unit
        edge3.Size = Vector3.new(0.5, 0.3, len3); edge3.CFrame = CFrame.lookAt(mid3, mid3+look3)
        edge3.Color = Color3.fromHSV(((t*0.06 + (i-1)/sides2) % 1), 1, 1)
        local hpl2 = edge3:FindFirstChildOfClass("PointLight")
        if hpl2 then hpl2.Color = edge3.Color end
    end
end

local portalFolder = Instance.new("Folder", mainFolder)
portalFolder.Name = "portal"
G.portalRings = {}
local NUM_PORTAL = 8

local function buildPortal()
    for _, p in ipairs(G.portalRings) do pcall(function() p:Destroy() end) end
    G.portalRings = {}
    if not singerHRP then return end
    for i = 1, NUM_PORTAL do
        local ring2 = Instance.new("Part", portalFolder)
        ring2.Size = Vector3.new(0.3, 10+i*2, 10+i*2); ring2.Shape = Enum.PartType.Cylinder
        ring2.Anchored = true; ring2.CanCollide = false; ring2.CastShadow = false
        ring2.Material = Enum.Material.Neon; ring2.Color = Color3.fromHSV((i-1)/NUM_PORTAL, 1, 1)
        ring2.Transparency = 0.55 + i*0.03
        ring2.CFrame = CFrame.new(singerHRP.Position + Vector3.new(0, 4+i*2.5, 0))
        table.insert(G.portalRings, ring2)
    end
end
buildPortal()

local function updatePortal(t)
    if not singerHRP or #G.portalRings == 0 then return end
    local center = singerHRP.Position + Vector3.new(0, 6, 0)
    local orbitAxes = {
        Vector3.new(0,1,0), Vector3.new(1,0,0), Vector3.new(0,0,1),
        Vector3.new(1,1,0).Unit, Vector3.new(0,1,1).Unit, Vector3.new(1,0,1).Unit,
        Vector3.new(1,1,1).Unit, Vector3.new(-1,1,0).Unit,
    }
    for i, ring2 in ipairs(G.portalRings) do
        local axis = orbitAxes[i] or orbitAxes[1]
        local speed = 0.22 + i * 0.05; local orbitRadius = 38 + i * 5
        local angle = t * speed + (i - 1) * (math.pi * 2 / NUM_PORTAL)
        local up = math.abs(axis:Dot(Vector3.new(0,1,0))) < 0.99 and Vector3.new(0,1,0) or Vector3.new(1,0,0)
        local tangent  = axis:Cross(up).Unit; local binormal = axis:Cross(tangent).Unit
        local pos = center + tangent * math.cos(angle) * orbitRadius + binormal * math.sin(angle) * orbitRadius
        ring2.CFrame = CFrame.new(pos) * CFrame.fromAxisAngle(axis, t * (0.4 + i * 0.07)) * CFrame.Angles(0, 0, math.pi/2)
        ring2.Color = Color3.fromHSV(((t * 0.05 + (i - 1) / NUM_PORTAL) % 1), 1, 1)
        ring2.Transparency = 0.35 + math.abs(math.sin(t * 0.6 + i)) * 0.3
    end
end

local shockwaveRingFolder = Instance.new("Folder", mainFolder)
shockwaveRingFolder.Name = "beatrings"

local function spawnBeatRing(pos, color, bStr)
    task.spawn(function()
        local ring3 = Instance.new("Part", shockwaveRingFolder)
        local initSz = 1 + bStr * 2
        ring3.Size = Vector3.new(initSz, 0.3, initSz); ring3.Shape = Enum.PartType.Cylinder
        ring3.Material = Enum.Material.Neon; ring3.Color = color or Color3.fromRGB(255,200,0)
        ring3.Anchored = true; ring3.CanCollide = false; ring3.CastShadow = false; ring3.Transparency = 0.1
        ring3.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi/2)
        local targetSz = 18 + bStr * 12
        TweenService:Create(ring3, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = Vector3.new(targetSz, 0.3, targetSz), Transparency = 1
        }):Play()
        Debris:AddItem(ring3, 0.65)
    end)
end

local triangleFolder = Instance.new("Folder", mainFolder)
triangleFolder.Name = "triangles"

local function spawnFloatingTriangle(pos, size, duration)
    task.spawn(function()
        local sides = 3; local triParts = {}
        for i = 1, sides do
            local a1 = (i-1)*(math.pi*2/sides); local a2 = i*(math.pi*2/sides)
            local v1 = Vector3.new(math.cos(a1)*size, 0, math.sin(a1)*size)
            local v2 = Vector3.new(math.cos(a2)*size, 0, math.sin(a2)*size)
            local midT = pos + (v1+v2)/2; local lenT = (v2-v1).Magnitude; local lookT = (v2-v1).Unit
            local edgeT = Instance.new("Part", triangleFolder)
            edgeT.Size = Vector3.new(0.35, 0.35, lenT); edgeT.Anchored = true; edgeT.CanCollide = false
            edgeT.CastShadow = false; edgeT.Material = Enum.Material.Neon
            edgeT.Color = Color3.fromHSV(math.random(), 1, 1); edgeT.Transparency = 0.1
            edgeT.CFrame = CFrame.lookAt(midT, midT+lookT)
            table.insert(triParts, edgeT)
        end
        local t2 = 0; local connT
        connT = RunService.RenderStepped:Connect(function(dt)
            t2 = t2 + dt
            if t2 > duration then
                for _, p in ipairs(triParts) do pcall(function() p:Destroy() end) end
                connT:Disconnect(); return
            end
            for j, p in ipairs(triParts) do
                p.CFrame = p.CFrame * CFrame.Angles(0, dt*1.2, 0)
                p.Position = p.Position + Vector3.new(0, dt*1.8, 0)
                p.Transparency = math.min(1, t2/duration)
                p.Color = Color3.fromHSV(((t2*0.15 + (j-1)/sides) % 1), 1, 1)
            end
        end)
    end)
end

local gyroFolder = Instance.new("Folder", mainFolder)
gyroFolder.Name = "gyrorings"
G.GYRO_RINGS = {}
local GYRO_COUNT = 6
local GYRO_RADII = {25, 32, 39, 46, 53, 60}
local GYRO_AXES  = {
    Vector3.new(1,0,0), Vector3.new(0,1,0), Vector3.new(0,0,1),
    Vector3.new(1,1,0).Unit, Vector3.new(0,1,1).Unit, Vector3.new(1,0,1).Unit,
}
for i = 1, GYRO_COUNT do
    local r = GYRO_RADII[i]
    local gr = Instance.new("Part", gyroFolder)
    gr.Size = Vector3.new(r*2, 0.55, r*2); gr.Shape = Enum.PartType.Cylinder
    gr.Material = Enum.Material.Neon; gr.Anchored = true; gr.CanCollide = false; gr.CastShadow = false
    gr.Color = Color3.fromHSV((i-1)/GYRO_COUNT, 1, 1); gr.Transparency = 0.4
    local gpl = Instance.new("PointLight", gr); gpl.Brightness = 1.2; gpl.Range = 16; gpl.Color = gr.Color
    table.insert(G.GYRO_RINGS, {part=gr, pl=gpl, axis=GYRO_AXES[i], radius=r, speed=(i%2==0 and 1 or -1)*(0.28+i*0.07), phase=(i-1)*math.pi/GYRO_COUNT})
end

local function updateGyroRings(t)
    if not singerHRP or not singerHRP.Parent then return end
    local center = singerHRP.Position + Vector3.new(0, 8, 0)
    for i, gd in ipairs(G.GYRO_RINGS) do
        local orbitAngle  = t * (0.12 + i * 0.03) + gd.phase
        local orbitRadius = 38 + (i - 1) * 7
        local orbitHeight = math.sin(t * 0.4 + gd.phase) * 10
        local pos = center + Vector3.new(math.cos(orbitAngle)*orbitRadius, orbitHeight, math.sin(orbitAngle)*orbitRadius)
        gd.part.CFrame = CFrame.new(pos) * CFrame.fromAxisAngle(gd.axis, t * gd.speed + gd.phase) * CFrame.Angles(0, 0, math.pi/2)
        local col = Color3.fromHSV(((t * 0.05 + gd.phase / (math.pi * 2)) % 1), 1, 1)
        gd.part.Color = col; gd.pl.Color = col
        gd.part.Transparency = 0.35 + math.abs(math.sin(t * 0.4 + gd.phase)) * 0.35
    end
end

local function spawnPillarRing(count, height, radius)
    if not singerHRP then return end
    task.spawn(function()
        local parts = {}
        for i = 1, count do
            local angle = (i-1)*(math.pi*2/count)
            local p = Instance.new("Part", mainFolder)
            p.Size = Vector3.new(0.5, height or 12, 0.5); p.Material = Enum.Material.Neon
            p.Anchored = true; p.CanCollide = false; p.CastShadow = false
            p.Color = Color3.fromHSV((i-1)/count, 1, 1)
            p.CFrame = CFrame.new(singerHRP.Position + Vector3.new(math.cos(angle)*(radius or 12), (height or 12)/2 - 5, math.sin(angle)*(radius or 12)))
            TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Vector3.new(0.5, (height or 12)*1.5, 0.5)}):Play()
            local pl = Instance.new("PointLight", p); pl.Brightness = 3; pl.Range = 12; pl.Color = p.Color
            table.insert(parts, p)
        end
        task.delay(1.8, function()
            for _, pp in ipairs(parts) do
                TweenService:Create(pp, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
                Debris:AddItem(pp, 0.5)
            end
        end)
    end)
end

local cubeFolder = Instance.new("Folder", mainFolder)
cubeFolder.Name = "cubes"

local function spawnExplosiveCubes(count, origin)
    origin = origin or (singerHRP and singerHRP.Position or Vector3.new(0,10,0))
    for i = 1, count do
        task.spawn(function()
            local cube = Instance.new("Part", cubeFolder)
            cube.Size = Vector3.new(math.random(1,3), math.random(1,3), math.random(1,3))
            cube.Material = Enum.Material.Neon; cube.Anchored = false; cube.CanCollide = false; cube.CastShadow = false
            cube.Color = COPA_COLORS[math.random(1,#COPA_COLORS)]; cube.CFrame = CFrame.new(origin)
            local pl2 = Instance.new("PointLight", cube); pl2.Brightness = 2; pl2.Range = 9; pl2.Color = cube.Color
            local bv = Instance.new("BodyVelocity", cube)
            bv.Velocity = Vector3.new(math.random(-28,28), math.random(12,50), math.random(-28,28))
            bv.MaxForce = Vector3.new(1e5,1e5,1e5)
            TweenService:Create(cube, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = Vector3.new(0.1,0.1,0.1), Transparency = 1}):Play()
            Debris:AddItem(cube, 1.7)
        end)
    end
end

local function shockwave(color, scale)
    if not singerHRP or not singerHRP.Parent then return end
    scale = scale or 1
    task.spawn(function()
        for i = 1, 3 do
            local ring = Instance.new("Part", mainFolder)
            ring.Size = Vector3.new(2, 0.35, 2); ring.Shape = Enum.PartType.Cylinder; ring.Material = Enum.Material.Neon
            ring.Color = color or Color3.fromRGB(255,200,0); ring.Anchored = true; ring.CanCollide = false; ring.CastShadow = false
            ring.Transparency = 0.15
            ring.CFrame = CFrame.new(singerHRP.Position + Vector3.new(0, (i-1)*2, 0)) * CFrame.Angles(0, 0, math.pi/2)
            TweenService:Create(ring, TweenInfo.new(0.75 + i*0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = Vector3.new(80*scale, 0.35, 80*scale), Transparency = 1
            }):Play()
            Debris:AddItem(ring, 0.95 + i*0.1); task.wait(0.04)
        end
    end)
end

local function spawnLaserRing(height, colors)
    if not singerHRP then return end
    task.spawn(function()
        local count = 19; local radius = 7; local parts = {}
        for i = 1, count do
            local p = Instance.new("Part", mainFolder)
            p.Size = Vector3.new(0.35, 9, 0.35); p.Material = Enum.Material.Neon
            p.Anchored = true; p.CanCollide = false; p.CastShadow = false
            p.Color = (colors and colors[(i % #colors)+1]) or Color3.fromHSV((i-1)/count, 1, 1)
            local ang = (i-1) * (math.pi*2/count)
            p.CFrame = CFrame.new(singerHRP.Position + Vector3.new(math.cos(ang)*radius, height or 3, math.sin(ang)*radius))
            local pl = Instance.new("PointLight", p); pl.Brightness = 2; pl.Range = 8; pl.Color = p.Color
            table.insert(parts, p)
        end
        task.delay(0.9, function()
            for _, p in ipairs(parts) do
                TweenService:Create(p, TweenInfo.new(0.4), {Transparency = 1}):Play()
                Debris:AddItem(p, 0.5)
            end
        end)
    end)
end

local function spawnStarburstRing()
    if not singerHRP then return end
    task.spawn(function()
        local numSpikes = 16
        for i = 1, numSpikes do
            local p = Instance.new("Part", mainFolder)
            p.Size = Vector3.new(0.3, 0.3, 14); p.Material = Enum.Material.Neon
            p.Anchored = true; p.CanCollide = false; p.CastShadow = false
            p.Color = Color3.fromHSV((i-1)/numSpikes, 1, 1)
            local angle = (i-1) * (math.pi * 2 / numSpikes)
            local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
            p.CFrame = CFrame.lookAt(singerHRP.Position + Vector3.new(0, 4, 0), singerHRP.Position + Vector3.new(0, 4, 0) + dir) * CFrame.new(0, 0, -7)
            TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
            Debris:AddItem(p, 0.7)
        end
    end)
end

local function addParticles(part)
    if not part then return nil end
    local pe = Instance.new("ParticleEmitter", part)
    pe.Rate = 0; pe.Lifetime = NumberRange.new(0.5, 2)
    pe.Speed = NumberRange.new(5, 18); pe.SpreadAngle = Vector2.new(70, 70)
    pe.LightEmission = 1; pe.LightInfluence = 0
    pe.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,220,0)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0,200,80)),
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255,80,0)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,255,255)),
    })
    pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(0.5, 1.4), NumberSequenceKeypoint.new(1, 0)})
    pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    pe.RotSpeed = NumberRange.new(-220, 220); pe.Rotation = NumberRange.new(0, 360)
    return pe
end

shared.G_singerParticles = addParticles(singerHRP)
shared.G_playerParticles = addParticles(playerHRP)
local singerParticles = shared.G_singerParticles
local playerParticles = shared.G_playerParticles

local function burstParticles(pe, count)
    if pe and pe.Parent then pe:Emit(count or 20) end
end

local EMOTE_IDS = {
    dance    = "rbxassetid://507771019",
    wave     = "rbxassetid://507770718",
    point    = "rbxassetid://507770453",
    cheer    = "rbxassetid://507770677",
    laugh    = "rbxassetid://507770818",
    robot    = "rbxassetid://3360695866",
    flip     = "rbxassetid://507770239",
    shrug    = "rbxassetid://3360692915",
    salute   = "rbxassetid://3360689775",
    headbang = "rbxassetid://6899663224",
    twerk    = "rbxassetid://6899544869",
    clap     = "rbxassetid://6899663224",
    groove   = "rbxassetid://6899663224",
    celebrate = "rbxassetid://507770677",
    
    wave        = "rbxassetid://507770718",
    point       = "rbxassetid://507770453",
    cheer       = "rbxassetid://507770677",
    laugh       = "rbxassetid://507770818",
    dance       = "rbxassetid://507771019",
    dance2      = "rbxassetid://507771341",
    dance3      = "rbxassetid://507771619",

    -- Emotes Oficiais da Loja (R15)
    robot       = "rbxassetid://3360695866",
    shrug       = "rbxassetid://3360692915",
    salute      = "rbxassetid://3360689775",
    tilt        = "rbxassetid://3360704386",
    stadium     = "rbxassetid://3360686498",
    flex        = "rbxassetid://3360677536",
    breathe     = "rbxassetid://3360641154",
    bow         = "rbxassetid://3360655416",
    rest        = "rbxassetid://3360662369",
    confused    = "rbxassetid://3360647185",
    
    -- Novas Adições (Animações de Dança, Poses e Reações)
    hype        = "rbxassetid://3658428525",
    applause    = "rbxassetid://4513192233",
    iconic      = "rbxassetid://5141315510",
    line_dance  = "rbxassetid://4049037604",
    my_avatar   = "rbxassetid://4841434944",
    pro_gamer   = "rbxassetid://4512004245",
    savage      = "rbxassetid://5537750864",
    shuffle     = "rbxassetid://4315494291",
    spin        = "rbxassetid://5160359858",
    surprised   = "rbxassetid://4841029257",
    victory     = "rbxassetid://4254199732",
    wind        = "rbxassetid://4049034261",
    zombie      = "rbxassetid://6161111666"
}

local function playSingerAnim(animId)
    if not singerHum then return end
    if G.currentAnimTrack then pcall(function() G.currentAnimTrack:Stop(0.3) end); G.currentAnimTrack = nil end
    if shared.G_singerFlyConn then shared.G_singerFlyConn:Disconnect(); shared.G_singerFlyConn = nil; G.singerFlyActive = false end
    local anim = Instance.new("Animation"); anim.AnimationId = animId
    local ok, track = pcall(function() return singerHum:LoadAnimation(anim) end)
    if ok and track then track.Looped = true; track:Play(0.3); G.currentAnimTrack = track end
end

local function singerDance()     playSingerAnim(EMOTE_IDS.dance)     end
local function singerCheer()     playSingerAnim(EMOTE_IDS.cheer)     end
local function singerPoint()     playSingerAnim(EMOTE_IDS.point)     end
local function singerLaugh()     playSingerAnim(EMOTE_IDS.laugh)     end
local function singerWave()      playSingerAnim(EMOTE_IDS.wave)      end
local function singerSalute()    playSingerAnim(EMOTE_IDS.salute)    end
local function singerRobot()     playSingerAnim(EMOTE_IDS.robot)     end
local function singerFlip()      playSingerAnim(EMOTE_IDS.flip)      end
local function singerShrug()     playSingerAnim(EMOTE_IDS.shrug)     end
local function singerHeadbang()  playSingerAnim(EMOTE_IDS.headbang)  end
local function singerGroove()    playSingerAnim(EMOTE_IDS.groove)    end
local function singerCelebrate() playSingerAnim(EMOTE_IDS.celebrate) end

local function singerLevitate(duration)
    if G.singerFlyActive then return end
    G.singerFlyActive = true
    if G.currentAnimTrack then pcall(function() G.currentAnimTrack:Stop(0.35) end); G.currentAnimTrack = nil end
    local torso = singer:FindFirstChild("Torso"); local hrp = singer:FindFirstChild("HumanoidRootPart")
    if not torso or not hrp then G.singerFlyActive = false; return end
    local rj = hrp:FindFirstChild("RootJoint"); local nk = torso:FindFirstChild("Neck")
    local rs = torso:FindFirstChild("Right Shoulder"); local ls = torso:FindFirstChild("Left Shoulder")
    local rh = torso:FindFirstChild("Right Hip"); local lh = torso:FindFirstChild("Left Hip")
    if not (rj and nk and rs and ls and rh and lh) then G.singerFlyActive = false; return end
    local orig = {rj = rj.C0, nk = nk.C0, rs = rs.C0, ls = ls.C0, rh = rh.C0, lh = lh.C0}
    local flyT = 0; local blend = 0; local BLEND = 0.5
    local TARGET_RJ = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-90), 0, math.rad(180))
    local TARGET_NK = CFrame.new(0, 1, 0) * CFrame.Angles(math.rad(-90), 0, math.rad(180)) * CFrame.Angles(math.rad(25), 0, 0)
    local TARGET_RS = CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(-85), 0, math.rad(-15))
    local TARGET_LS = CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, math.rad(-90), 0) * CFrame.Angles(math.rad(-85), 0, math.rad(15))
    local TARGET_RH = CFrame.new(1, -1, 0) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(15), 0, math.rad(-5))
    local TARGET_LH = CFrame.new(-1, -1, 0) * CFrame.Angles(0, math.rad(-90), 0) * CFrame.Angles(math.rad(15), 0, math.rad(5))
    if shared.G_singerFlyConn then shared.G_singerFlyConn:Disconnect() end
    shared.G_singerFlyConn = RunService.RenderStepped:Connect(function(dt)
        if not singerHRP or not singerHRP.Parent or G.finished then
            shared.G_singerFlyConn:Disconnect(); shared.G_singerFlyConn = nil; G.singerFlyActive = false; return
        end
        flyT = flyT + dt; blend = math.min(1, blend + dt / BLEND)
        local e = blend * blend * (3 - 2 * blend)
        local s1 = math.sin(flyT * 0.9); local s2 = math.sin(flyT * 1.6); local s3 = math.sin(flyT * 2.4)
        rj.C0 = rj.C0:Lerp(TARGET_RJ * CFrame.Angles(math.rad(s1*1.5)*e, math.rad(s2*0.8)*e, 0), 0.12)
        nk.C0 = nk.C0:Lerp(TARGET_NK * CFrame.Angles(math.rad(s1*2)*e, 0, 0), 0.14)
        rs.C0 = rs.C0:Lerp(TARGET_RS * CFrame.Angles(math.rad(s2*3)*e, 0, math.rad(s3*1.5)*e), 0.13)
        ls.C0 = ls.C0:Lerp(TARGET_LS * CFrame.Angles(math.rad(s2*3)*e, 0, math.rad(-s3*1.5)*e), 0.13)
        rh.C0 = rh.C0:Lerp(TARGET_RH * CFrame.Angles(math.rad(s1*2.5)*e, 0, 0), 0.11)
        lh.C0 = lh.C0:Lerp(TARGET_LH * CFrame.Angles(math.rad(-s1*2.5)*e, 0, 0), 0.11)
        if flyT >= (duration or 999) then
            shared.G_singerFlyConn:Disconnect(); shared.G_singerFlyConn = nil; G.singerFlyActive = false
            TweenService:Create(rj, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {C0 = orig.rj}):Play()
            TweenService:Create(nk, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {C0 = orig.nk}):Play()
            TweenService:Create(rs, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {C0 = orig.rs}):Play()
            TweenService:Create(ls, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {C0 = orig.ls}):Play()
            TweenService:Create(rh, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {C0 = orig.rh}):Play()
            TweenService:Create(lh, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {C0 = orig.lh}):Play()
        end
    end)
end

singerDance()

shared.G_sg = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
shared.G_sg.Name = "WakaWakaShowGui"
shared.G_sg.IgnoreGuiInset = true
shared.G_sg.ResetOnSpawn = false
shared.G_sg.DisplayOrder = 999
shared.G_sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local sg = shared.G_sg

local function makeFrame(parent, props)
    local f = Instance.new("Frame", parent); f.BorderSizePixel = 0
    for k,v in pairs(props) do f[k] = v end
    return f
end

local BAR_H = 75
local cinemaTop = makeFrame(sg, {Size = UDim2.new(1,4,0,BAR_H+4), Position = UDim2.new(-0.002,0,0,-(BAR_H+4)), BackgroundColor3 = Color3.new(0,0,0), ZIndex = 10})
local cinemaBot = makeFrame(sg, {Size = UDim2.new(1,4,0,BAR_H+4), Position = UDim2.new(-0.002,0,1,0), BackgroundColor3 = Color3.new(0,0,0), ZIndex = 10})
TweenService:Create(cinemaTop, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(-0.002,0,0,-2)}):Play()
TweenService:Create(cinemaBot, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(-0.002,0,1,-(BAR_H+2))}):Play()

shared.G_lyricOuter = makeFrame(sg, {
    Size = UDim2.new(0.72, 0, 0, 76), Position = UDim2.new(0.5, 0, 1, -(BAR_H + 96)),
    AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = Color3.fromRGB(0, 40, 10),
    BackgroundTransparency = 0.3, ZIndex = 9,
})
Instance.new("UICorner", shared.G_lyricOuter).CornerRadius = UDim.new(0, 12)
shared.G_lyricStroke = Instance.new("UIStroke", shared.G_lyricOuter)
shared.G_lyricStroke.Color = Color3.fromRGB(255,200,0); shared.G_lyricStroke.Thickness = 2.8; shared.G_lyricStroke.Transparency = 0.15

local lyricOuter = shared.G_lyricOuter

shared.G_lyricLabel = Instance.new("TextLabel", lyricOuter)
shared.G_lyricLabel.Size = UDim2.new(1,-22,0,40); shared.G_lyricLabel.Position = UDim2.new(0,11,0,4)
shared.G_lyricLabel.BackgroundTransparency = 1; shared.G_lyricLabel.TextColor3 = Color3.new(1,1,1)
shared.G_lyricLabel.TextStrokeTransparency = 0.1; shared.G_lyricLabel.TextStrokeColor3 = Color3.fromRGB(180,120,0)
shared.G_lyricLabel.Font = Enum.Font.GothamBold; shared.G_lyricLabel.TextSize = 28
shared.G_lyricLabel.TextXAlignment = Enum.TextXAlignment.Center; shared.G_lyricLabel.Text = ""; shared.G_lyricLabel.ZIndex = 11; shared.G_lyricLabel.RichText = false

local lyricLabel = shared.G_lyricLabel

shared.G_subLabel = Instance.new("TextLabel", lyricOuter)
shared.G_subLabel.Size = UDim2.new(1,-22,0,26); shared.G_subLabel.Position = UDim2.new(0,11,0,44)
shared.G_subLabel.BackgroundTransparency = 1; shared.G_subLabel.TextColor3 = Color3.fromRGB(255,230,150)
shared.G_subLabel.TextStrokeTransparency = 0.4; shared.G_subLabel.Font = Enum.Font.Gotham; shared.G_subLabel.TextSize = 16
shared.G_subLabel.TextXAlignment = Enum.TextXAlignment.Center; shared.G_subLabel.Text = ""; shared.G_subLabel.ZIndex = 11; shared.G_subLabel.RichText = true

local subLabel = shared.G_subLabel

shared.G_flashFrame = makeFrame(sg, {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 1, ZIndex = 20})
local flashFrame = shared.G_flashFrame

local vignetteFrame = makeFrame(sg, {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ZIndex = 8})
local vgGrad = Instance.new("UIGradient", vignetteFrame)
vgGrad.Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0))
vgGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(1, 0.22)})
vgGrad.Rotation = 90

shared.G_scanlines = Instance.new("Frame", sg)
shared.G_scanlines.Name = "scanlines"; shared.G_scanlines.Size = UDim2.new(1,0,1,0)
shared.G_scanlines.BackgroundTransparency = 1; shared.G_scanlines.ZIndex = 19
local slGrad = Instance.new("UIGradient", shared.G_scanlines)
slGrad.Rotation = 0
slGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.92), NumberSequenceKeypoint.new(0.02, 1), NumberSequenceKeypoint.new(0.04, 0.92), NumberSequenceKeypoint.new(1, 0.92)})
slGrad.Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0))

Camera.CameraType  = Enum.CameraType.Scriptable
Camera.FieldOfView = G.camFOV

local function tweenFOV(fov, t)
    G.camFOV = fov
    TweenService:Create(Camera, TweenInfo.new(t or 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {FieldOfView = fov}):Play()
end

local function getTargetPos()
    if G.camTarget == "player" and playerCloneHRP and playerCloneHRP.Parent then return playerCloneHRP.Position end
    if singerHRP and singerHRP.Parent then return singerHRP.Position end
    return Vector3.new(0,0,0)
end

local function getSingerBodyCenter()
    if singerHead and singerHead.Parent then return singerHead.Position end
    if singerHRP and singerHRP.Parent then return singerHRP.Position + Vector3.new(0, 1.5, 0) end
    return Vector3.new(0,1.5,0)
end

local function getTargetCamCF()
    local target     = getTargetPos()
    local bodyCenter = getSingerBodyCenter()
    local headOff    = Vector3.new(0, G.camHeight, 0)
    local camAngle   = G.camAngle
    local camDist    = G.camDist
    local camHeight  = G.camHeight
    local elapsed    = G.elapsed

    if G.camMode == "orbit" then
        local camPos = target + headOff + Vector3.new(math.cos(camAngle)*camDist, camHeight*0.15, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, bodyCenter)
    elseif G.camMode == "close" then
        local camPos = bodyCenter + Vector3.new(math.cos(camAngle)*camDist, 0, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, bodyCenter)
    elseif G.camMode == "face" then
        local facePos = (singerHead and singerHead.Parent) and singerHead.Position or bodyCenter
        local camPos = facePos + Vector3.new(math.cos(camAngle)*camDist, 0.2, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, facePos)
    elseif G.camMode == "playerface" then
        local playerHead = playerClone and playerClone:FindFirstChild("Head")
        local facePos = (playerHead and playerHead.Parent) and playerHead.Position or (playerCloneHRP and playerCloneHRP.Position + Vector3.new(0, 4, 0) or Vector3.new(0,4,0))
        local camPos = facePos + Vector3.new(math.cos(camAngle)*5, 0.2, math.sin(camAngle)*5)
        return CFrame.lookAt(camPos, facePos)
    elseif G.camMode == "top" then
        local topDist = 44 + math.sin(elapsed * 0.5) * 8
        return CFrame.lookAt(target + Vector3.new(math.sin(elapsed*0.3)*6, topDist, math.cos(elapsed*0.3)*6), bodyCenter)
    elseif G.camMode == "dramatic" then
        local camPos = bodyCenter + Vector3.new(math.cos(camAngle)*camDist, -5, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, bodyCenter + Vector3.new(0, 7, 0))
    elseif G.camMode == "worm" then
        local camPos = target + Vector3.new(math.cos(camAngle)*camDist, -7, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, bodyCenter)
    elseif G.camMode == "fnf" then
        local sp = singerHRP and singerHRP.Position or Vector3.new(0,0,0)
        local pp = playerCloneHRP and playerCloneHRP.Position or Vector3.new(0,0,12)
        local mid = (sp + pp) / 2
        return CFrame.lookAt(mid + Vector3.new(0, 12, 36), mid + Vector3.new(0, 6, 0))
    elseif G.camMode == "lowangle" then
        local camPos = target + Vector3.new(math.cos(camAngle)*camDist, -12, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, target + Vector3.new(0, 3, 0))
    elseif G.camMode == "dutch" then
        local base = CFrame.lookAt(
            target + headOff + Vector3.new(math.cos(camAngle)*camDist, camHeight*0.1, math.sin(camAngle)*camDist), bodyCenter)
        return base * CFrame.Angles(0, 0, math.rad(18))
    elseif G.camMode == "spin360" then
        local spinAngle = elapsed * 1.8
        return CFrame.lookAt(bodyCenter + Vector3.new(math.cos(spinAngle)*camDist, camHeight*0.3, math.sin(spinAngle)*camDist), bodyCenter)
    elseif G.camMode == "cinematic" then
        local slideX = math.sin(elapsed * 0.22) * 8
        return CFrame.lookAt(bodyCenter + Vector3.new(slideX + math.cos(camAngle)*camDist, camHeight*0.6, math.sin(camAngle)*camDist), bodyCenter + Vector3.new(0, 1.5, 0))
    elseif G.camMode == "shoulderL" then
        local facePos2 = (singerHead and singerHead.Parent) and singerHead.Position or bodyCenter
        local rightDir = singerHRP and singerHRP.CFrame.RightVector or Vector3.new(1,0,0)
        return CFrame.lookAt(facePos2 - rightDir * 2.2 + Vector3.new(0, 0.5, 0) + (singerHRP and singerHRP.CFrame.LookVector * (-camDist*0.6) or Vector3.new(0,0,-8)), facePos2 + Vector3.new(0, -0.2, 0))
    elseif G.camMode == "shoulderR" then
        local facePos3 = (singerHead and singerHead.Parent) and singerHead.Position or bodyCenter
        local rightDir2 = singerHRP and singerHRP.CFrame.RightVector or Vector3.new(1,0,0)
        return CFrame.lookAt(facePos3 + rightDir2 * 2.2 + Vector3.new(0, 0.5, 0) + (singerHRP and singerHRP.CFrame.LookVector * (-camDist*0.6) or Vector3.new(0,0,-8)), facePos3 + Vector3.new(0, -0.2, 0))
    elseif G.camMode == "birdseye" then
        return CFrame.lookAt(target + Vector3.new(math.sin(elapsed*0.08)*10, 65, math.cos(elapsed*0.08)*10), bodyCenter)
    end
    return Camera.CFrame
end

local function addCameraShake(intensity, decay)
    G.camShakeX = math.random(-100,100)/100 * intensity
    G.camShakeY = math.random(-100,100)/100 * intensity
    G.camShakeDecay = decay or 0.85
end

local function glitch(times, strength)
    if G.glitching then return end
    G.glitching = true; strength = strength or 1
    local orig = Camera.CFrame
    task.spawn(function()
        for _ = 1, (times or 5) do
            Camera.CFrame = orig
                * CFrame.new(math.random(-10,10)*0.055*strength, math.random(-5,5)*0.035*strength, 0)
                * CFrame.Angles(0, 0, math.rad(math.random(-5,5)*strength))
            task.wait(0.035)
        end
        Camera.CFrame = orig; G.glitching = false
    end)
end

local function lightningFlash()
    doChromaticAberration(0.2, 0.5)
    glitch(5, 1.8)
    addCameraShake(0.4, 0.8)
    TweenService:Create(flashFrame, TweenInfo.new(0.06), {BackgroundTransparency = 0.15}):Play()
    task.delay(0.06, function()
        TweenService:Create(flashFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
    end)
end

local function colorShift(r, g, b, t)
    TweenService:Create(colorCorrection, TweenInfo.new(t or 0.35, Enum.EasingStyle.Quint), {TintColor = Color3.fromRGB(r,g,b)}):Play()
end

local function skyColor(r, g, b)
    TweenService:Create(Lighting, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {
        Ambient = Color3.fromRGB(r//3, g//3, b//3), OutdoorAmbient = Color3.fromRGB(r//2, g//2, b//2),
        FogColor = Color3.fromRGB(r//2, g//2, b//2), FogEnd = 500 + math.random(0,200), Brightness = 1.4 + math.random()*0.6,
    }):Play()
    TweenService:Create(bloom, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {Intensity = 0.8 + math.random()*1.0, Size = 18 + math.random()*18}):Play()
end

local function punchCam(scale)
    scale = scale or 1
    local base = G.camFOV
    tweenFOV(base - 9*scale, 0.08)
    task.delay(0.12, function() tweenFOV(base + 14*scale, 0.2) end)
    task.delay(0.38, function() tweenFOV(base, 0.28) end)
    addCameraShake(0.25 * scale, 0.82)
end

local function zoomToFace(who, fov, duration, holdTime)
    local prevMode = G.camMode; local prevFOV = G.camFOV; local prevTarget = G.camTarget
    G.camTarget = who or "singer"
    G.camMode   = (who == "player") and "playerface" or "face"
    tweenFOV(fov or 35, duration or 0.5)
    if holdTime then
        task.delay(holdTime, function()
            G.camMode = prevMode; G.camTarget = prevTarget
            tweenFOV(prevFOV, duration or 0.5)
        end)
    end
end

local function scaleSinger(targetScale, duration)
    if not singerHum then return end
    for _, n in ipairs({"BodyHeightScale","BodyWidthScale","BodyDepthScale","HeadScale"}) do
        local obj = singerHum:FindFirstChild(n)
        if obj then TweenService:Create(obj, TweenInfo.new(duration or 0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Value = targetScale}):Play() end
    end
end

local function floatSinger(height, duration)
    if not singerHRP then return end
    G.isFloating = true
    local targetPos = singerBasePos and singerBasePos.Position + Vector3.new(0, height, 0) or singerHRP.Position + Vector3.new(0, height, 0)
    local targetCF  = CFrame.new(targetPos) * (singerBasePos and singerBasePos.Rotation or CFrame.identity)
    TweenService:Create(singerHRP, TweenInfo.new(duration * 0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
    scaleSinger(4.5, 0.35); burstParticles(singerParticles, 22)
    shockwave(Color3.fromHSV(math.random(), 1, 1)); singerLevitate(duration)
    task.delay(duration * 0.5, function() scaleSinger(3.5, 0.25) end)
    task.delay(duration, function()
        G.isFloating = false; scaleSinger(3, 0.4); singerDance()
        if singerHRP and singerHRP.Parent and singerBasePos then
            TweenService:Create(singerHRP, TweenInfo.new(0.65, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {CFrame = singerBasePos}):Play()
            task.delay(0.1, function() shockwave(Color3.fromRGB(255,200,0)); burstParticles(singerParticles, 16) end)
        end
    end)
end

local function slamDown()
    if not singerHRP then return end
    scaleSinger(5.5, 0.15)
    task.delay(0.15, function()
        if singerBasePos then TweenService:Create(singerHRP, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {CFrame = singerBasePos}):Play() end
        task.delay(0.25, function()
            scaleSinger(3, 0.3)
            TweenService:Create(flashFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.6}):Play()
            task.delay(0.3, function() TweenService:Create(flashFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play() end)
            glitch(9, 2.2); shockwave(Color3.fromRGB(255,200,0))
            spawnExplosiveCubes(10, singerHRP and singerHRP.Position); burstParticles(singerParticles, 35)
            punchCam(1.8); spawnLaserRing(0); task.delay(0.1, function() spawnLaserRing(5) end)
            doChromaticAberration(0.3, 0.7)
        end)
    end)
end

local function doTornado()
    if G.tornadoActive or not singerHRP then return end
    G.tornadoActive = true
    local tornadoFolder = Instance.new("Folder", mainFolder)
    local parts = {}
    local NUM_T = 30
    for i = 1, NUM_T do
        local p = Instance.new("Part", tornadoFolder)
        p.Anchored = true; p.CanCollide = false; p.CastShadow = false; p.Material = Enum.Material.Neon
        p.Size = Vector3.new(0.6, 0.6, 0.6); p.Shape = Enum.PartType.Ball
        p.Color = Color3.fromHSV((i-1)/NUM_T, 1, 1)
        table.insert(parts, {part=p, phase=(i-1)*(math.pi*2/NUM_T), idx=i})
    end
    local prevCamMode = G.camMode; local prevCamDist = G.camDist; local prevFOV = G.camFOV
    G.camMode = "top"; tweenFOV(95, 1.2)
    local t2 = 0; local tornadoConn
    tornadoConn = RunService.RenderStepped:Connect(function(dt)
        if G.finished then tornadoConn:Disconnect(); return end
        t2 = t2 + dt
        local center = singerHRP.Position
        for _, d in ipairs(parts) do
            local progress = math.min(t2 / 2.5, 1)
            local radius = 12 * (1 - progress * 0.5); local height = t2 * 14 * progress
            local angle = d.phase + t2 * 3.5
            d.part.Position = center + Vector3.new(math.cos(angle)*radius, height, math.sin(angle)*radius)
            d.part.Color = Color3.fromHSV(((t2 * 0.1 + (d.idx-1)/NUM_T) % 1), 1, 1)
            d.part.Transparency = math.clamp(t2 / 4, 0, 0.8)
        end
        if t2 >= 4 then
            tornadoConn:Disconnect()
            for _, d in ipairs(parts) do
                TweenService:Create(d.part, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Position = singerHRP.Position, Transparency = 1}):Play()
            end
            task.delay(0.9, function() pcall(function() tornadoFolder:Destroy() end) end)
            G.camMode = prevCamMode; G.camDist = prevCamDist; tweenFOV(prevFOV, 1)
            G.tornadoActive = false
        end
    end)
end

local function doSuperBurst()
    local pos = singerHRP and singerHRP.Position or Vector3.new(0,10,0)
    spawnExplosiveCubes(25, pos); shockwave(Color3.fromRGB(255,200,0))
    task.delay(0.15, function() shockwave(Color3.fromRGB(0,200,80)) end)
    task.delay(0.30, function() shockwave(Color3.fromRGB(255,80,0)) end)
    burstParticles(singerParticles, 70); burstParticles(playerParticles, 35)
    lightningFlash(); punchCam(2.2)
    spawnLaserRing(4); task.delay(0.18, function() spawnLaserRing(9) end); task.delay(0.36, function() spawnLaserRing(14) end)
    spawnConfetti(50, pos); scaleSinger(5.5, 0.18); task.delay(0.5, function() scaleSinger(3, 0.4) end)
    spawnStarburstRing(); doChromaticAberration(0.45, 0.9)
    addCameraShake(0.6, 0.75)
    spawnSkyConfetti(25)
    doAudioBlurEffect()
end

G.lyricBeatCount = 0

local function pulseLyricBeat(bpm)
    if G.lyricEffectConn then G.lyricEffectConn:Disconnect() end
    local interval = 60 / (bpm or 128); local lastBeat = tick()
    G.lyricEffectConn = RunService.RenderStepped:Connect(function()
        if tick() - lastBeat >= interval then
            lastBeat = tick(); G.lyricBeatCount = G.lyricBeatCount + 1
            shared.G_lyricStroke.Color = Color3.fromHSV((G.lyricBeatCount * 0.07) % 1, 1, 1)
            TweenService:Create(lyricOuter, TweenInfo.new(0.07, Enum.EasingStyle.Quint), {Size = UDim2.new(0.67, 0, 0, 78)}):Play()
            task.delay(0.13, function()
                TweenService:Create(lyricOuter, TweenInfo.new(0.16, Enum.EasingStyle.Quint), {Size = UDim2.new(0.65, 0, 0, 72)}):Play()
            end)
        end
    end)
end
pulseLyricBeat(128)

local lyricWorldFolder = Instance.new("Folder", mainFolder)
lyricWorldFolder.Name = "lyricworld"
G.orbitBoards = {}

local function updateLyricBoards(t)
    if not playerHRP then return end
    local center = playerHRP.Position
    for i = #G.orbitBoards, 1, -1 do
        local d = G.orbitBoards[i]
        if not d.board or not d.board.Parent then
            table.remove(G.orbitBoards, i)
        else
            d.angle = d.angle + d.speed * (1/60)
            local bob = math.sin(t * 2.1 + d.phase) * 1.2
            local pos = center + Vector3.new(math.cos(d.angle)*d.radius, d.height + bob, math.sin(d.angle)*d.radius)
            local look = Vector3.new(center.X, pos.Y, center.Z)
            d.board.CFrame = CFrame.lookAt(pos, look) * CFrame.Angles(0, math.pi, math.sin(t*1.8 + d.phase)*0.06)
        end
    end
end

local function spawnWorldLyric(text)
    if not playerHRP or text == "" then return end
    task.spawn(function()
        G.orbitBoardCount = G.orbitBoardCount + 1
        local idx = G.orbitBoardCount; local hue = (idx * 0.19) % 1
        local board = Instance.new("Part", lyricWorldFolder)
        board.Size = Vector3.new(0.05, 3.8, 13); board.Anchored = true; board.CanCollide = false
        board.CastShadow = false; board.Transparency = 1; board.Material = Enum.Material.Neon
        board.Color = Color3.fromHSV(hue, 1, 1)
        local radius = 18 + (idx % 4) * 3; local height = 2 + (idx % 3) * 1.5
        local speed  = 0.45 + (idx % 5) * 0.09; local angle = (idx - 1) * (math.pi * 2 / 6); local phase = idx * 1.3
        board.CFrame = CFrame.new(playerHRP.Position + Vector3.new(math.cos(angle)*radius, height, math.sin(angle)*radius))
        local sg2 = Instance.new("SurfaceGui", board)
        sg2.Face = Enum.NormalId.Front; sg2.AlwaysOnTop = true
        sg2.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg2.PixelsPerStud = 50
        local back = Instance.new("Frame", sg2)
        back.Size = UDim2.new(1,0,1,0); back.BackgroundColor3 = Color3.new(0,0,0); back.BackgroundTransparency = 0.4
        Instance.new("UICorner", back).CornerRadius = UDim.new(0.15, 0)
        local sk = Instance.new("UIStroke", back); sk.Color = Color3.fromHSV(hue, 1, 1); sk.Thickness = 3.5; sk.Transparency = 0
        local lbl = Instance.new("TextLabel", back)
        lbl.Size = UDim2.new(1,-16,1,-8); lbl.Position = UDim2.new(0,8,0,4); lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.new(1,1,1); lbl.TextStrokeTransparency = 0; lbl.TextStrokeColor3 = Color3.fromHSV(hue, 0.5, 1)
        lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true; lbl.Text = text
        table.insert(G.orbitBoards, {board=board, angle=angle, radius=radius, height=height, speed=speed, phase=phase})
        TweenService:Create(board, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Transparency = 0.15, Size = Vector3.new(0.05, 4.2, 14.5)}):Play()
        task.delay(4.5, function()
            TweenService:Create(board, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Transparency = 1, Size = Vector3.new(0.05, 1.5, 6)}):Play()
            task.wait(0.85); pcall(function() board:Destroy() end)
        end)
    end)
end

local function showLyric(entry)
    if entry.isExec then task.spawn(pcall, entry.fn); return end
    if shared.G_karaokeConn then shared.G_karaokeConn:Disconnect(); shared.G_karaokeConn = nil end
    if singerHead and singerHead.Parent and entry.jp ~= "" then pcall(function() ChatService:Chat(singerHead, entry.jp) end) end
    local worldText = entry.jp ~= "" and entry.jp or entry.en
    if worldText ~= "" then spawnWorldLyric(worldText) end
    if math.random(1, 3) == 1 then spawnConfetti(12, singerHRP and singerHRP.Position) end
    local hue = math.random()
    lyricLabel.TextSize = 36; lyricLabel.Rotation = math.random(-4, 4)
    TweenService:Create(lyricLabel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 28, Rotation = 0}):Play()
    subLabel.TextColor3 = Color3.fromRGB(255, 230, 150); subLabel.TextSize = 20; subLabel.Text = entry.en
    TweenService:Create(subLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {TextSize = 16, TextColor3 = Color3.fromRGB(255, 230, 150)}):Play()
    TweenService:Create(lyricOuter, TweenInfo.new(0.06), {BackgroundTransparency = 0.04, Size = UDim2.new(0.68, 0, 0, 80)}):Play()
    task.delay(0.4, function() TweenService:Create(lyricOuter, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.4, Size = UDim2.new(0.65, 0, 0, 72)}):Play() end)
    TweenService:Create(shared.G_lyricStroke, TweenInfo.new(0.05), {Color = Color3.fromHSV(hue, 1, 1), Thickness = 4}):Play()
    task.delay(0.45, function() TweenService:Create(shared.G_lyricStroke, TweenInfo.new(0.35), {Color = Color3.fromRGB(255, 200, 0), Thickness = 2.8}):Play() end)
    TweenService:Create(blur, TweenInfo.new(0.05), {Size = 5}):Play()
    task.delay(0.12, function() TweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = 0}):Play() end)
    doChromaticAberration(0.1, 0.25)
    local words = {}
    for w in entry.jp:gmatch("%S+") do table.insert(words, w) end
    lyricLabel.TextColor3 = Color3.new(1, 1, 1); lyricLabel.Text = ""
    local idx = 0
    shared.G_karaokeConn = RunService.RenderStepped:Connect(function()
        if G.finished then shared.G_karaokeConn:Disconnect(); shared.G_karaokeConn = nil; return end
        if idx < #words then idx = idx + 1; lyricLabel.Text = table.concat(words, " ", 1, idx)
        else shared.G_karaokeConn:Disconnect(); shared.G_karaokeConn = nil end
    end)
end

local function checkIdleAnim(elapsed)
    if elapsed - G.lastLyricTime > 4 and not G.idleAnimPlaying then
        G.idleAnimPlaying = true
        local rng = math.random(1, 12)
        if rng <= 2 then
            floatSinger(16, 8); setBarColor(shared.G_BAR_COLORS.levitate); shockwave(Color3.fromRGB(0,200,80)); burstParticles(singerParticles, 18)
        elseif rng == 3 then
            singerDance(); setBarColor(shared.G_BAR_COLORS.dance); spawnExplosiveCubes(8, singerHRP and singerHRP.Position)
        elseif rng == 4 then
            singerPoint(); setBarColor(shared.G_BAR_COLORS.point); zoomToFace("player", 40, 0.4, 2.5)
        elseif rng == 5 then
            singerLaugh(); setBarColor(shared.G_BAR_COLORS.laugh); glitch(6, 1.2)
        elseif rng == 6 then
            singerWave(); setBarColor(shared.G_BAR_COLORS.wave); shockwave(Color3.fromRGB(255,200,0))
        elseif rng == 7 then
            singerRobot(); setBarColor(shared.G_BAR_COLORS.robot); spawnLaserRing(3); task.delay(0.18, function() spawnLaserRing(8) end)
        elseif rng == 8 then
            singerShrug(); setBarColor(shared.G_BAR_COLORS.shrug); spawnConfetti(18, singerHRP and singerHRP.Position)
        elseif rng == 9 then
            singerHeadbang(); setBarColor(shared.G_BAR_COLORS.dance); spawnSkyConfetti(20); doAudioBlurEffect()
        elseif rng == 10 then
            singerGroove(); setBarColor(shared.G_BAR_COLORS.spin); spawnConfetti(25, singerHRP and singerHRP.Position); spawnStarburstRing()
        elseif rng == 11 then
            singerCelebrate(); setBarColor(shared.G_BAR_COLORS.wave); spawnSkyConfetti(30); spawnExplosiveCubes(12, singerHRP and singerHRP.Position)
        else
            singerFlip(); setBarColor(shared.G_BAR_COLORS.spin); scaleSinger(4.5, 0.2); task.delay(0.5, function() scaleSinger(3, 0.3) end)
            shockwave(Color3.fromHSV(math.random(), 1, 1)); spawnStarburstRing()
        end
        task.delay(9, function() G.idleAnimPlaying = false end)
    end
end

local choreo = {
    {0, function() singerDance(); tweenFOV(65, 1.5); colorShift(180,220,80); G.camMode = "orbit"; G.camDist = 22 end},
    {9.22, function()
        zoomToFace("singer", 38, 0.6, 2.5); colorShift(255,220,80); skyColor(60,50,0)
        singerCelebrate(); punchCam(); spawnLaserRing(5); spawnPillarRing(8, 14, 10); spawnSkyConfetti(20)
    end},
    {13.15, function()
        floatSinger(20, 2); G.camMode = "dramatic"; G.camDist = 18; tweenFOV(60, 0.5)
        lightningFlash(); singerCheer(); shockwave(Color3.fromRGB(0,200,80))
        burstParticles(singerParticles, 28); spawnLaserRing(7); doChromaticAberration(0.35, 0.6)
        spawnSkyConfetti(25); doAudioBlurEffect()
    end},
    {17.75, function()
        glitch(7, 1.6); G.camMode = "orbit"; G.camDist = 28; tweenFOV(72, 0.4)
        colorShift(100,200,80); skyColor(0,60,10); spawnExplosiveCubes(14, singerHRP and singerHRP.Position)
        singerHeadbang(); spawnLaserRing(4); task.delay(0.2, function() spawnLaserRing(9) end)
        spawnGeometricRing(12, 6, 12, 1.2, 2.5)
    end},
    {21.07, function()
        zoomToFace("singer", 34, 0.5, 3); colorShift(255,200,80); skyColor(60,40,0)
        singerPoint(); spawnLaserRing(2); spawnSpiralRings(12); spawnSkyConfetti(15)
    end},
    {24.16, function()
        G.camMode = "orbit"; G.camAngle = G.camAngle + math.pi * 0.7; G.camDist = 20; tweenFOV(65, 0.3)
        punchCam(1.3); shockwave(Color3.fromRGB(255,200,0))
        singerDance(); spawnLaserRing(5); addCameraShake(0.3, 0.8); spawnSkyConfetti(18)
    end},
    {28.45, function()
        lightningFlash(); colorShift(255,220,80); skyColor(70,60,0); doSuperBurst()
        G.camMode = "worm"; G.camDist = 22; tweenFOV(76, 0.4)
    end},
    {33.33, function()
        zoomToFace("singer", 30, 0.5, 2.5); colorShift(80,200,80); skyColor(0,60,10)
        singerGroove(); spawnDNAHelix(3); spawnSkyConfetti(20)
    end},
    {36.63, function()
        slamDown(); G.camMode = "orbit"; G.camDist = 32; tweenFOV(70, 0.5)
        colorShift(255,180,0); skyColor(70,40,0); spawnPillarRing(10, 16, 14); doAudioBlurEffect()
    end},
    {40.0, function()
        zoomToFace("player", 36, 0.5, 2.5); singerLaugh(); growPlayerGiant(); spawnSkyConfetti(30)
    end},
    {45.0, function()
        G.camMode = "face"; G.camDist = 6; tweenFOV(55, 0.4); colorShift(255,180,50)
        spawnExplosiveCubes(12, singerHRP and singerHRP.Position); shockwave(Color3.fromRGB(255,180,50)); singerCelebrate()
        spawnSkyConfetti(22)
    end},
    {50.0, function()
        G.camMode = "orbit"; G.camDist = 35; tweenFOV(80, 0.5)
        colorShift(100,200,50); skyColor(20,60,0); doSuperBurst(); spawnGeometricRing(18, 10, 16, 0.6, 3)
    end},
    {55.18, function()
        glitch(11, 2.2); G.camMode = "dramatic"; G.camDist = 20; tweenFOV(65, 0.4)
        colorShift(200,220,80); skyColor(50,60,0); singerHeadbang(); burstParticles(singerParticles, 45)
        doChromaticAberration(0.4, 0.8); spawnSpiralRings(16); doAudioBlurEffect()
    end},
    {58.45, function()
        floatSinger(40, 3); G.camMode = "birdseye"; G.camDist = 45; tweenFOV(88, 0.6)
        colorShift(255,255,200); skyColor(70,70,20); spawnExplosiveCubes(22, singerHRP and singerHRP.Position)
        shockwave(Color3.fromRGB(255,220,0)); spawnStarburstRing(); spawnSkyConfetti(35)
    end},
    {1*60+5.73, function()
        zoomToFace("singer", 32, 0.5, 3); colorShift(255,200,80); skyColor(70,40,0); singerCelebrate()
        spawnPillarRing(12, 18, 16); G.camMode = "dutch"; spawnSkyConfetti(20)
    end},
    {1*60+14.07, function()
        glitch(7, 1.6); floatSinger(30, 2.5); G.camMode = "spin360"; tweenFOV(92, 0.5)
        colorShift(80,255,80); skyColor(0,70,10); spawnExplosiveCubes(18, singerHRP and singerHRP.Position)
        spawnDNAHelix(3.5); doAudioBlurEffect(); spawnSkyConfetti(28)
    end},
    {1*60+18.16, function()
        G.camMode = "orbit"; G.camDist = 24; tweenFOV(70, 0.4)
        colorShift(255,220,80); skyColor(60,50,0); punchCam(1.5); singerGroove()
        spawnGeometricRing(10, 4, 8, 1.5, 2)
    end},
    {1*60+25.25, function()
        glitch(6, 1.3); G.camMode = "dramatic"; G.camDist = 16; tweenFOV(62, 0.4)
        colorShift(255,200,50); skyColor(80,50,0); shockwave(Color3.fromRGB(255,180,0))
        burstParticles(singerParticles, 35); singerLaugh(); spawnSpiralRings(18)
    end},
    {1*60+32.90, function()
        lightningFlash(); slamDown(); zoomToFace("singer", 28, 0.4, 2.5)
        colorShift(255,80,0); skyColor(80,20,0); doSuperBurst(); singerSalute(); G.camMode = "lowangle"
    end},
    {2*60+11.68, function()
        G.camMode = "orbit"; G.camDist = 18; tweenFOV(68, 0.4)
        colorShift(255,200,80); skyColor(60,40,0); singerDance(); spawnLaserRing(5); spawnPillarRing(8, 12, 12)
        spawnSkyConfetti(25)
    end},
    {2*60+20.0, function()
        zoomToFace("player", 34, 0.5, 2.5); burstParticles(playerParticles, 30); growPlayerGiant(); spawnSkyConfetti(35)
    end},
    {2*60+29.62, function()
        floatSinger(50, 3); glitch(13, 2.8); G.camMode = "cinematic"; tweenFOV(95, 0.6)
        colorShift(180,255,80); skyColor(0,60,10); spawnExplosiveCubes(30, singerHRP and singerHRP.Position)
        shockwave(Color3.fromRGB(0,200,80)); burstParticles(singerParticles, 70)
        task.delay(0.1, function() spawnLaserRing(6) end); task.delay(0.3, function() spawnLaserRing(12) end)
        spawnDNAHelix(4); doChromaticAberration(0.6, 1.0); addCameraShake(0.8, 0.7)
        doAudioBlurEffect(); spawnSkyConfetti(40)
    end},
    {2*60+37.95, function()
        lightningFlash(); G.camMode = "orbit"; G.camDist = 40; tweenFOV(85, 0.5)
        colorShift(255,255,200); skyColor(80,80,20); doSuperBurst(); singerCelebrate()
        spawnLaserRing(10); spawnGeometricRing(20, 12, 18, 0.5, 3)
    end},
    {2*60+42.70, function()
        zoomToFace("singer", 30, 0.5, 3); colorShift(80,220,80); skyColor(0,60,10)
        singerHeadbang(); spawnSpiralRings(20); G.camMode = "shoulderL"; spawnSkyConfetti(20)
    end},
    {2*60+48.36, function()
        G.camMode = "orbit"; G.camDist = 50; tweenFOV(90, 0.5); glitch(9, 2.2)
        colorShift(255,200,0); skyColor(70,50,0); doSuperBurst()
        spawnExplosiveCubes(35, singerHRP and singerHRP.Position); singerFlip()
        task.delay(0.1, function() spawnLaserRing(5) end); task.delay(0.25, function() spawnLaserRing(11) end); task.delay(0.4, function() spawnLaserRing(17) end)
        spawnStarburstRing(); doChromaticAberration(0.5, 1.0); addCameraShake(1.0, 0.7); spawnSkyConfetti(50)
    end},
}

shared.G_sound = PlayGitSound(shared.G_AUDIO_URL, "WakaWakaCopa", 2, Camera)
shared.G_audioAnalyzer = Instance.new("AudioAnalyzer", workspace)
shared.G_audioAnalyzer.SpectrumEnabled = true
pcall(function()
    local audioPlayer = Instance.new("AudioPlayer", workspace)
    audioPlayer.AssetId = shared.G_sound and shared.G_sound.SoundId or ""
    local wire = Instance.new("Wire", workspace)
    wire.SourceInstance = audioPlayer; wire.TargetInstance = shared.G_audioAnalyzer
end)

task.spawn(function()
    for _, s in ipairs(workspace:GetDescendants()) do
        if s:IsA("Sound") and s ~= shared.G_sound and s.Volume > 0 then G.mutedSounds[s] = s.Volume; s.Volume = 0 end
    end
    workspace.DescendantAdded:Connect(function(d)
        if G.finished then return end
        if d:IsA("Sound") and d ~= shared.G_sound then task.wait(0.1); G.mutedSounds[d] = d.Volume; d.Volume = 0 end
    end)
end)

G.startTick = tick()
G.pentaAngle = 0
G.elapsed = 0

local extraFolder = Instance.new("Folder", mainFolder)
extraFolder.Name = "extraFX"
local NUM_RIBBONS = 12
G.ribbonParts = {}
for i = 1, NUM_RIBBONS do
    local p = Instance.new("Part", extraFolder)
    p.Size = Vector3.new(0.18, 0.18, 0.18); p.Anchored = true; p.CanCollide = false; p.CastShadow = false
    p.Material = Enum.Material.Neon; p.Color = Color3.fromHSV((i-1)/NUM_RIBBONS, 1, 1)
    local a0 = Instance.new("Attachment", p); a0.Position = Vector3.new(0, 0.5, 0)
    local a1 = Instance.new("Attachment", p); a1.Position = Vector3.new(0, -0.5, 0)
    local tr = Instance.new("Trail", p)
    tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.9; tr.MinLength = 0; tr.LightEmission = 1
    tr.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 0)})
    tr.Color = ColorSequence.new(Color3.fromHSV((i-1)/NUM_RIBBONS, 1, 1), Color3.fromRGB(255,255,255))
    tr.Transparency = NumberSequence.new(0, 1); tr.FaceCamera = true
    table.insert(G.ribbonParts, {part=p, phase=(i-1)*(math.pi*2/NUM_RIBBONS), speed=0.6+i*0.08})
end

local NUM_METEORS = 8
G.meteorParts = {}
for i = 1, NUM_METEORS do
    local p = Instance.new("Part", extraFolder)
    p.Size = Vector3.new(0.5, 0.5, 2.5); p.Anchored = true; p.CanCollide = false; p.CastShadow = false
    p.Material = Enum.Material.Neon; p.Color = Color3.fromHSV(math.random(), 1, 1)
    local a0 = Instance.new("Attachment", p); a0.Position = Vector3.new(0, 0, 1)
    local a1 = Instance.new("Attachment", p); a1.Position = Vector3.new(0, 0, -1)
    local tr = Instance.new("Trail", p)
    tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.5; tr.MinLength = 0; tr.LightEmission = 1
    tr.Color = ColorSequence.new(p.Color, Color3.fromRGB(255,255,255)); tr.Transparency = NumberSequence.new(0, 1); tr.FaceCamera = true
    local pl = Instance.new("PointLight", p); pl.Brightness = 3; pl.Range = 14; pl.Color = p.Color
    table.insert(G.meteorParts, {part=p, pl=pl, angle=math.random()*math.pi*2, height=math.random(20,55), dist=math.random(55,90), speed=0.4+math.random()*0.6, phase=math.random()*math.pi*2})
end

local NUM_PRISMS = 7
G.prismParts = {}
for i = 1, NUM_PRISMS do
    local p = Instance.new("Part", extraFolder)
    p.Size = Vector3.new(2.5, 2.5, 0.3); p.Anchored = true; p.CanCollide = false; p.CastShadow = false
    p.Material = Enum.Material.Neon; p.Color = Color3.fromHSV((i-1)/NUM_PRISMS, 1, 1); p.Transparency = 0.45
    local pl = Instance.new("PointLight", p); pl.Brightness = 2; pl.Range = 18; pl.Color = p.Color
    table.insert(G.prismParts, {part=p, pl=pl, angle=(i-1)*(math.pi*2/NUM_PRISMS), dist=math.random(30,60), height=math.random(10,35), speed=0.15+i*0.04, phase=math.random()*math.pi*2})
end

local NUM_COMETS = 5
G.cometParts = {}
for i = 1, NUM_COMETS do
    local p = Instance.new("Part", extraFolder)
    p.Size = Vector3.new(0.8, 0.8, 0.8); p.Shape = Enum.PartType.Ball
    p.Anchored = true; p.CanCollide = false; p.CastShadow = false; p.Material = Enum.Material.Neon
    p.Color = Color3.fromHSV((i-1)/NUM_COMETS, 1, 1)
    local a0 = Instance.new("Attachment", p); a0.Position = Vector3.new(0.3, 0, 0)
    local a1 = Instance.new("Attachment", p); a1.Position = Vector3.new(-0.3, 0, 0)
    local tr = Instance.new("Trail", p)
    tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 1.4; tr.MinLength = 0; tr.LightEmission = 1
    tr.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0)})
    tr.Color = ColorSequence.new(p.Color, Color3.fromRGB(255,255,255)); tr.Transparency = NumberSequence.new(0, 1); tr.FaceCamera = true
    local pl = Instance.new("PointLight", p); pl.Brightness = 5; pl.Range = 22; pl.Color = p.Color
    table.insert(G.cometParts, {part=p, pl=pl, a=(i-1)*(math.pi*2/NUM_COMETS), r=math.random(65,110), h=math.random(25,70), spd=0.25+i*0.07, ph=math.random()*math.pi*2, tilt=math.random()*math.pi})
end

local function updateExtraFX(t)
    if not singerHRP or not singerHRP.Parent then return end
    local center = singerHRP.Position
    for i, rd in ipairs(G.ribbonParts) do
        local angle  = t * rd.speed + rd.phase
        local radius = 14 + math.sin(t * 0.7 + rd.phase) * 6
        local height = math.sin(t * 1.1 + rd.phase * 2) * 18 + 10
        rd.part.Position = center + Vector3.new(math.cos(angle)*radius, height, math.sin(angle)*radius)
        rd.part.Color = Color3.fromHSV(((t * 0.09 + (i-1)/NUM_RIBBONS) % 1), 1, 1)
        local tr = rd.part:FindFirstChildOfClass("Trail")
        if tr then tr.Color = ColorSequence.new(Color3.fromHSV(((t * 0.09 + (i-1)/NUM_RIBBONS) % 1), 1, 1), Color3.fromRGB(255,255,255)) end
    end
    for i, md in ipairs(G.meteorParts) do
        local angle = t * md.speed + md.phase
        local tiltAxis = Vector3.new(math.sin(md.phase), 0.6, math.cos(md.phase)).Unit
        local up   = math.abs(tiltAxis:Dot(Vector3.new(0,1,0))) < 0.99 and Vector3.new(0,1,0) or Vector3.new(1,0,0)
        local tang = tiltAxis:Cross(up).Unit; local bin = tiltAxis:Cross(tang).Unit
        local pos  = center + tang*math.cos(angle)*md.dist + bin*math.sin(angle)*md.dist + Vector3.new(0, md.height, 0)
        local nextAngle = angle + 0.05
        local nextPos = center + tang*math.cos(nextAngle)*md.dist + bin*math.sin(nextAngle)*md.dist + Vector3.new(0, md.height, 0)
        md.part.CFrame = CFrame.lookAt(pos, nextPos)
        local hue = ((t * 0.07 + (i-1)/NUM_METEORS) % 1)
        md.part.Color = Color3.fromHSV(hue, 1, 1); md.pl.Color = md.part.Color
        local tr = md.part:FindFirstChildOfClass("Trail")
        if tr then tr.Color = ColorSequence.new(Color3.fromHSV(hue, 1, 1), Color3.fromRGB(255,255,255)) end
    end
    for i, pd in ipairs(G.prismParts) do
        local angle = t * pd.speed + pd.phase; local vertAngle = t * pd.speed * 0.7 + pd.phase * 1.3
        local pos = center + Vector3.new(math.cos(angle)*pd.dist, pd.height + math.sin(vertAngle)*12, math.sin(angle)*pd.dist)
        pd.part.CFrame = CFrame.new(pos) * CFrame.Angles(t * 0.4 + pd.phase, t * 0.3 + pd.phase * 0.7, t * 0.5)
        local hue = ((t * 0.05 + (i-1)/NUM_PRISMS) % 1)
        pd.part.Color = Color3.fromHSV(hue, 1, 1); pd.pl.Color = pd.part.Color
        pd.part.Transparency = 0.3 + math.abs(math.sin(t * 0.8 + pd.phase)) * 0.35
    end
    for i, cd in ipairs(G.cometParts) do
        local angle = t * cd.spd + cd.ph
        local up2   = math.abs(math.cos(cd.tilt)) < 0.99 and Vector3.new(0,1,0) or Vector3.new(1,0,0)
        local axis  = Vector3.new(math.sin(cd.tilt), math.cos(cd.tilt), math.sin(cd.tilt*0.7)).Unit
        local tang2 = axis:Cross(up2).Unit; local bin2 = axis:Cross(tang2).Unit
        local pos = center + tang2*math.cos(angle)*cd.r + bin2*math.sin(angle)*cd.r + Vector3.new(0, cd.h, 0)
        cd.part.Position = pos
        local hue = ((t * 0.06 + (i-1)/NUM_COMETS) % 1)
        cd.part.Color = Color3.fromHSV(hue, 1, 1); cd.pl.Color = cd.part.Color
        cd.pl.Brightness = 3 + math.abs(math.sin(t * 1.2 + cd.ph)) * 3
        local tr = cd.part:FindFirstChildOfClass("Trail")
        if tr then tr.Color = ColorSequence.new(Color3.fromHSV(hue, 1, 1), Color3.fromRGB(255,255,255)) end
    end
end

local lyrics = shared.G_lyrics

shared.G_conn = RunService.RenderStepped:Connect(function(dt)
    if G.finished then return end

    G.elapsed = (shared.G_sound and shared.G_sound.Parent and pcall(function() return shared.G_sound.IsPlaying end) and shared.G_sound.IsPlaying)
        and shared.G_sound.TimePosition
        or (tick() - G.startTick)

    local bass, mid, treble = getFreqBands()
    pushBassHistory(bass)

    if isRealBeat(bass) then
        G.lastRealBeat = tick(); G.beatCount = G.beatCount + 1
        G.beatStrength = 0.5 + bass * 0.8 + mid * 0.3; G.silenceTimer = 0
        if singerHRP then spawnBeatRing(singerHRP.Position, Color3.fromHSV((G.beatCount*0.13)%1,1,1), G.beatStrength) end
        if G.beatCount % 4 == 0 then punchCam(0.3 + G.beatStrength * 0.4) end
        if G.beatCount % 8 == 0 then
            if singerHRP then spawnFloatingTriangle(singerHRP.Position + Vector3.new(math.random(-5,5),3,math.random(-5,5)), math.random(3,7), 2) end
        end
        if G.beatCount % 16 == 0 then
            if treble > 0.55 then lightningFlash(); spawnSpiralRings(10)
            elseif mid > 0.5 then shockwave(Color3.fromHSV(math.random(),1,1)); spawnStarburstRing()
            else spawnLaserRing(4); doChromaticAberration(0.2, 0.4) end
        end
        if G.beatCount % 32 == 0 then doSuperBurst() end
        if G.beatCount % 48 == 0 then spawnSkyConfetti(30) end
        burstParticles(singerParticles, math.floor(2 + G.beatStrength * 6))
        G.BPM = math.clamp(60 / math.max(0.1, tick() - G.lastRealBeat + 0.001), 80, 180)
    else
        G.silenceTimer = G.silenceTimer + dt
    end

    if G.silenceTimer > 1.5 and not G.tornadoActive and G.elapsed > 5 then
        doTornado(); G.silenceTimer = 0
    end

    if mid > 0.65 then
        TweenService:Create(colorCorrection, TweenInfo.new(0.1), {TintColor = Color3.fromHSV((G.elapsed * 0.3) % 1, 0.4, 1)}):Play()
    end

    G.camStuckTimer = G.camStuckTimer + dt
    if G.lastCamMode ~= G.camMode then G.lastCamMode = G.camMode; G.camStuckTimer = 0 end
    if G.camStuckTimer > 18 and not G.tornadoActive then
        G.camStuckTimer = 0
        local nextChoreoTime = math.huge
        for _, c in ipairs(choreo) do
            if c[1] > G.elapsed then nextChoreoTime = c[1]; break end
        end
        if nextChoreoTime - G.elapsed > 4 then
            local modes = {"orbit","dramatic","cinematic","lowangle","dutch","shoulderL","shoulderR"}
            G.camMode = modes[math.random(1, #modes)]; G.camDist = math.random(20, 30); tweenFOV(math.random(62, 78), 0.8)
        end
    end

    G.pentaAngle = G.pentaAngle + dt * 0.9
    updatePentagon(G.pentaAngle)
    updateOrbit(G.elapsed); updateStars(G.elapsed); updateNebula(G.elapsed)
    updateShowLights(G.elapsed); updateGyroRings(G.elapsed); updateExtraFX(G.elapsed)
    checkIdleAnim(G.elapsed); updateLyricBoards(G.elapsed)
    updateSpectrum3D(G.elapsed); updateWaveform3D(G.elapsed)
    updateSoundWaves(G.elapsed, G.beatStrength)
    updateStarShape(G.elapsed); updateHexShape(G.elapsed); updatePortal(G.elapsed)

    if stagePlatform and singerHRP then
        stagePlatform.Color = Color3.fromHSV((G.elapsed * 0.07) % 1, 1, 1)
        stagePlatform.Transparency = 0.25 + math.abs(math.sin(G.elapsed * 2.8)) * 0.18
    end

    if playerCloneHRP and playerHRP then playerCloneHRP.CFrame = playerHRP.CFrame end

    G.camAngle = G.camAngle + dt * 0.14

    if G.camShakeDecay > 0 then
        G.camShakeX = G.camShakeX * G.camShakeDecay; G.camShakeY = G.camShakeY * G.camShakeDecay
        if math.abs(G.camShakeX) < 0.001 then G.camShakeX = 0; G.camShakeY = 0; G.camShakeDecay = 0 end
    end

    G.desiredCamCF = G.desiredCamCF:Lerp(getTargetCamCF(), 0.1)
    local shakeCF = CFrame.new(G.camShakeX, G.camShakeY, 0) * CFrame.Angles(0, 0, math.rad(G.camShakeX * 3))
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = G.desiredCamCF * shakeCF

    if shared.G_sound and shared.G_sound.Parent then pcall(function() shared.G_sound.RollOffMaxDistance = 9999 end) end

    while G.lyricIdx <= #lyrics and lyrics[G.lyricIdx].time <= G.elapsed do
        G.lastLyricTime = G.elapsed; G.idleAnimPlaying = false
        showLyric(lyrics[G.lyricIdx]); G.lyricIdx = G.lyricIdx + 1
    end

    while G.choreoIdx <= #choreo and choreo[G.choreoIdx][1] <= G.elapsed do
        task.spawn(choreo[G.choreoIdx][2]); G.choreoIdx = G.choreoIdx + 1
    end

    checkIdleAnim(G.elapsed)

    if singerHRP and singerHRP.Parent and singerBasePos and not G.isFloating then
        local bob = CFrame.new(0, math.sin(G.elapsed*2)*0.025, 0)
            * CFrame.Angles(0, math.sin(G.elapsed*0.5)*0.012, math.sin(G.elapsed*2.5)*0.009)
        singerHRP.CFrame = singerBasePos * bob
    end

    local lightHue = (G.elapsed * 0.14) % 1
    spotLight.Color = Color3.fromHSV(lightHue, 0.7, 1)
    pointLight.Color = Color3.fromHSV((lightHue + 0.33) % 1, 0.7, 1)
    singerSpotDown.Color = Color3.fromHSV((lightHue + 0.66) % 1, 0.7, 1)

    if shared.G_singerNameTag then
        local nameLabel2 = shared.G_singerNameTag:FindFirstChildOfClass("TextLabel")
        if nameLabel2 then nameLabel2.TextColor3 = Color3.fromHSV((G.elapsed * 0.22) % 1, 1, 1) end
    end

    local soundDone = false
    if shared.G_sound and shared.G_sound.Parent then
        pcall(function() soundDone = not shared.G_sound.IsPlaying and G.elapsed > 5 end)
    else
        soundDone = tick() - G.startTick > 175
    end

    if soundDone then
        G.finished = true
        if shared.G_conn then shared.G_conn:Disconnect() end
        if shared.G_skyConfettiConn then shared.G_skyConfettiConn:Disconnect() end
        for s, vol in pairs(G.mutedSounds) do pcall(function() s.Volume = vol end) end
        TweenService:Create(flashFrame, TweenInfo.new(2), {BackgroundTransparency = 0.1}):Play()
        task.delay(0.5, function() TweenService:Create(flashFrame, TweenInfo.new(1.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play() end)
        doSuperBurst()
        task.wait(0.8)
        TweenService:Create(cinemaTop, TweenInfo.new(1.5, Enum.EasingStyle.Quint), {Position = UDim2.new(-0.002,0,0,-(BAR_H+4))}):Play()
        TweenService:Create(cinemaBot, TweenInfo.new(1.5, Enum.EasingStyle.Quint), {Position = UDim2.new(-0.002,0,1,0)}):Play()
        TweenService:Create(lyricOuter, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
        TweenService:Create(colorCorrection, TweenInfo.new(2.5), {TintColor = Color3.new(1,1,1), Saturation = 0, Brightness = 0}):Play()
        TweenService:Create(Lighting, TweenInfo.new(2.5), {
            Ambient = origAmbient, OutdoorAmbient = origOutdoor,
            Brightness = origBrightness, ClockTime = origClockTime,
            FogEnd = origFogEnd, FogColor = origFogColor,
        }):Play()
        tweenFOV(origFOV, 2)
        task.wait(2)
        if G.lyricEffectConn then G.lyricEffectConn:Disconnect() end
        for _, obj in ipairs({sg, mainFolder, singer, playerClone, shared.G_sky, bloom, colorCorrection, colorCorrectionR, colorCorrectionB, shared.G_depthOfField, shared.G_sunRays, blur}) do
            pcall(function() obj:Destroy() end)
        end
        for part, origT in pairs(G.hiddenParts) do pcall(function() part.Transparency = origT end) end
        for part, origT in pairs(G.origPlayerTransp) do pcall(function() part.Transparency = origT end) end
        Camera.CameraType  = Enum.CameraType.Custom
        Camera.FieldOfView = origFOV
        if playerHum then playerHum.WalkSpeed = 16; playerHum.JumpHeight = 7.2 end
        if playerHRP then playerHRP.Anchored = false end
        pcall(function()
            for _, t in ipairs({Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Health, Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Chat}) do
                StarterGui:SetCoreGuiEnabled(t, true)
            end
        end)
    end
end)
