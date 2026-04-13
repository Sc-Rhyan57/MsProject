if shared.showloaded then
    warn("[ ARIGATO ] ALREADY LOADED.")
   return
end

shared.showloaded = true
shared.G = shared.G or {
    BPM = 128,
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
}

local player = game.Players.LocalPlayer
if player and player.PlayerGui:FindFirstChild("LoadingUI") and player.PlayerGui.LoadingUI.Enabled then
    repeat task.wait() until not player.PlayerGui:FindFirstChild("LoadingUI") or not player.PlayerGui.LoadingUI.Enabled
else
    repeat task.wait() until game:IsLoaded()
end

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ChatService  = game:GetService("Chat")
local Lighting     = game:GetService("Lighting")
local StarterGui   = game:GetService("StarterGui")
local Debris       = game:GetService("Debris")
local Camera       = workspace.CurrentCamera
local LocalPlayer  = Players.LocalPlayer

local AUDIO_URL  = "https://raw.githubusercontent.com/Sc-Rhyan57/MsProject/refs/heads/main/projects/data/Arigato/Tokyo%20(online-audio-converter.com).ogg"
local LYRICS_URL = "https://raw.githubusercontent.com/Sc-Rhyan57/MsProject/refs/heads/main/projects/data/Arigato/lyrics.txt"

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

local function parseLyrics()
    local lines = {}
    local ok, raw = pcall(function() return game:HttpGet(LYRICS_URL) end)
    if not ok then return lines end
    for line in raw:gmatch("[^\n]+") do
        local m, s, cs, rest = line:match("%[(%d+):(%d+)%.(%d+)%]%s*(.*)")
        if m then
            local t  = tonumber(m)*60 + tonumber(s) + tonumber(cs)/100
            local jp = rest:match("^(.-)%^") or rest
            local en = rest:match("%^(.+)$") or ""
            if jp ~= "" or en ~= "" then
                table.insert(lines, {time = t, jp = jp, en = en})
            end
        end
    end
    table.sort(lines, function(a,b) return a.time < b.time end)
    return lines
end

local lyrics = parseLyrics()

local playerChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local playerHRP  = playerChar:FindFirstChild("HumanoidRootPart")
local playerHum  = playerChar:FindFirstChildOfClass("Humanoid")
local playerHead = playerChar:FindFirstChild("Head")

if playerHum then playerHum.WalkSpeed = 0; playerHum.JumpHeight = 0 end
if playerHRP  then playerHRP.Anchored = true end

shared.G.origPlayerTransp = {}
for _, part in ipairs(playerChar:GetDescendants()) do
    if part:IsA("BasePart") or part:IsA("MeshPart") then
        shared.G.origPlayerTransp[part] = part.Transparency
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

local origAmbient    = Lighting.Ambient
local origOutdoor    = Lighting.OutdoorAmbient
local origBrightness = Lighting.Brightness
local origClockTime  = Lighting.ClockTime
local origFogEnd     = Lighting.FogEnd
local origFogColor   = Lighting.FogColor
local origFOV        = Camera.FieldOfView

Lighting.ClockTime      = 0
Lighting.Brightness     = 2.2
Lighting.Ambient        = Color3.fromRGB(60, 20, 100)
Lighting.OutdoorAmbient = Color3.fromRGB(40, 10, 80)
Lighting.FogEnd         = 700
Lighting.FogColor       = Color3.fromRGB(20, 0, 60)

local sky = Instance.new("Sky", Lighting)
sky.SkyboxBk = "rbxassetid://159454282"
sky.SkyboxDn = "rbxassetid://159454282"
sky.SkyboxFt = "rbxassetid://159454282"
sky.SkyboxLf = "rbxassetid://159454282"
sky.SkyboxRt = "rbxassetid://159454282"
sky.SkyboxUp = "rbxassetid://159454282"
sky.StarCount = 5000
sky.CelestialBodiesShown = false

local colorCorrection = Instance.new("ColorCorrectionEffect", Lighting)
colorCorrection.Brightness  = 0.04
colorCorrection.Contrast    = 0.25
colorCorrection.Saturation  = 0.6
colorCorrection.TintColor   = Color3.fromRGB(200, 120, 255)

local colorCorrectionR = Instance.new("ColorCorrectionEffect", Lighting)
colorCorrectionR.TintColor = Color3.fromRGB(255, 160, 160)
colorCorrectionR.Enabled   = false

local colorCorrectionB = Instance.new("ColorCorrectionEffect", Lighting)
colorCorrectionB.TintColor = Color3.fromRGB(160, 160, 255)
colorCorrectionB.Enabled   = false

local bloom = Instance.new("BloomEffect", Lighting)
bloom.Intensity = 1.8
bloom.Size      = 32
bloom.Threshold = 0.85

local sunRays = Instance.new("SunRaysEffect", Lighting)
sunRays.Intensity = 0.35
sunRays.Spread    = 0.7

local blur = Instance.new("BlurEffect", Lighting)
blur.Size    = 0
blur.Enabled = true

local depthOfField = Instance.new("DepthOfFieldEffect", Lighting)
depthOfField.FarIntensity  = 0.1
depthOfField.NearIntensity = 0
depthOfField.FocusDistance = 12
depthOfField.InFocusRadius = 30
depthOfField.Enabled = true

shared.G.chromaticActive = false
local function doChromaticAberration(duration, strength)
    if shared.G.chromaticActive then return end
    shared.G.chromaticActive = true
    strength = strength or 0.4
    colorCorrectionR.Enabled = true
    colorCorrectionB.Enabled = true
    colorCorrectionR.Brightness = strength
    colorCorrectionB.Brightness = -strength * 0.5
    colorCorrectionR.Saturation = 1.5
    colorCorrectionB.Saturation = 1.5
    task.delay(duration or 0.3, function()
        TweenService:Create(colorCorrectionR, TweenInfo.new(0.25), {Brightness = 0, Saturation = 0}):Play()
        TweenService:Create(colorCorrectionB, TweenInfo.new(0.25), {Brightness = 0, Saturation = 0}):Play()
        task.delay(0.3, function()
            colorCorrectionR.Enabled = false
            colorCorrectionB.Enabled = false
            shared.G.chromaticActive = false
        end)
    end)
end

local singer = Players:CreateHumanoidModelFromUserId(LocalPlayer.UserId)
singer.Name   = LocalPlayer.Name
singer.Parent = workspace

local singerHum  = singer:FindFirstChildOfClass("Humanoid")
local singerHRP  = singer:FindFirstChild("HumanoidRootPart")
local singerHead = singer:FindFirstChild("Head")

if singerHum then
    singerHum.WalkSpeed  = 0
    singerHum.JumpHeight = 0
    singerHum.NameDisplayDistance   = 0
    singerHum.HealthDisplayDistance = 0
end

for _, part in ipairs(singer:GetDescendants()) do
    if part:IsA("BasePart") or part:IsA("MeshPart") then
        part.Reflectance = 0
    end
end

local singerBasePos
if singerHRP and playerHRP then
    local front = playerHRP.CFrame * CFrame.new(0, 0, -14)
    singerHRP.CFrame = CFrame.new(front.Position, playerHRP.Position)
    singerHRP.Anchored = true
    singerBasePos = singerHRP.CFrame
end


local singerNameTag
if singerHead then
    singerNameTag = Instance.new("BillboardGui", singerHead)
    singerNameTag.Size = UDim2.new(0, 160, 0, 40)
    singerNameTag.StudsOffset = Vector3.new(0, 4.5, 0)
    singerNameTag.AlwaysOnTop = true
    local nameLabel = Instance.new("TextLabel", singerNameTag)
    nameLabel.Size = UDim2.new(1,0,1,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255,160,255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(100,0,200)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 22
    nameLabel.Text = "rhyan57 ♪"
end

local playerClone = Players:CreateHumanoidModelFromUserId(LocalPlayer.UserId)
playerClone.Name   = LocalPlayer.Name
playerClone.Parent = workspace
local playerCloneHum = playerClone:FindFirstChildOfClass("Humanoid")
local playerCloneHRP = playerClone:FindFirstChild("HumanoidRootPart")
if playerCloneHum then
    playerCloneHum.WalkSpeed = 0; playerCloneHum.JumpHeight = 0
    playerCloneHum.NameDisplayDistance = 0; playerCloneHum.HealthDisplayDistance = 0
end
if playerCloneHRP and playerHRP then
    playerCloneHRP.CFrame = playerHRP.CFrame
    playerCloneHRP.Anchored = true
end
for _, part in ipairs(playerClone:GetDescendants()) do
    if part:IsA("BasePart") or part:IsA("MeshPart") then
        part.CastShadow = false
        part.Material = Enum.Material.SmoothPlastic
        part.Reflectance = 0
    end
    if part:IsA("SpecialMesh") then
        part.TextureId = part.TextureId
    end
end

local playerCloneOrigScales = {}
if playerCloneHum then
    for _, n in ipairs({"BodyHeightScale","BodyWidthScale","BodyDepthScale","HeadScale"}) do
        local obj = playerCloneHum:FindFirstChild(n)
        if obj then playerCloneOrigScales[n] = obj.Value end
    end
end

shared.G.playerGiantDone = false

local function growPlayerGiant()
    if shared.G.playerGiantDone then return end
    shared.G.playerGiantDone = true
    task.spawn(function()
        if not playerCloneHRP or not playerCloneHum then return end

        doChromaticAberration(0.6, 0.8)

        local growNames = {"BodyHeightScale","BodyWidthScale","BodyDepthScale","HeadScale"}

        for i = 1, 15 do
            for _, n in ipairs(growNames) do
                local obj = playerCloneHum:FindFirstChild(n)
                if obj then
                    TweenService:Create(obj, TweenInfo.new(0.12, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Value = 1 + i * 0.45}):Play()
                end
            end
            local ringColors = {
                Color3.fromRGB(255,80,220),
                Color3.fromRGB(80,200,255),
                Color3.fromRGB(255,255,80),
                Color3.fromRGB(80,255,160),
            }
            task.spawn(function()
                local ring = Instance.new("Part", mainFolder)
                ring.Size = Vector3.new(2, 0.4, 2)
                ring.Shape = Enum.PartType.Cylinder
                ring.Material = Enum.Material.Neon
                ring.Color = ringColors[(i % #ringColors) + 1]
                ring.Anchored = true; ring.CanCollide = false; ring.CastShadow = false
                ring.Transparency = 0.15
                ring.CFrame = CFrame.new(playerCloneHRP.Position) * CFrame.Angles(0, 0, math.pi/2)
                TweenService:Create(ring, TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = Vector3.new(3 + i * 8, 0.4, 3 + i * 8), Transparency = 1
                }):Play()
                Debris:AddItem(ring, 0.8)
            end)
            local pointGlow = Instance.new("PointLight", playerCloneHRP)
            pointGlow.Brightness = 8; pointGlow.Range = 30 + i * 4
            pointGlow.Color = ringColors[(i % #ringColors) + 1]
            Debris:AddItem(pointGlow, 0.15)
            task.wait(0.07)
        end

        for _, n in ipairs(growNames) do
            local obj = playerCloneHum:FindFirstChild(n)
            if obj then
                TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Value = 7}):Play()
            end
        end

        task.spawn(function()
            local bigRing = Instance.new("Part", mainFolder)
            bigRing.Size = Vector3.new(4, 0.6, 4)
            bigRing.Shape = Enum.PartType.Cylinder
            bigRing.Material = Enum.Material.Neon
            bigRing.Color = Color3.fromRGB(255,200,255)
            bigRing.Anchored = true; bigRing.CanCollide = false; bigRing.CastShadow = false
            bigRing.Transparency = 0
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
            if obj then
                TweenService:Create(obj, TweenInfo.new(1.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Value = playerCloneOrigScales[n] or 1}):Play()
            end
        end
        task.wait(1.5)
        shared.G.playerGiantDone = false
    end)
end

shared.G.hiddenParts = {}
shared.G.finished = false

local function hideNearbyParts()
    task.spawn(function()
        pcall(function() workspace.Terrain.Transparency = 1 end)
        while not shared.G.finished do
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                    local isShowPart = obj:IsDescendantOf(singer) or obj:IsDescendantOf(playerClone)
                        or (mainFolder and obj:IsDescendantOf(mainFolder))
                    if isShowPart then continue end
                    local nearPlayer = playerHRP and (obj.Position - playerHRP.Position).Magnitude < 900
                    local nearSinger = singerHRP and (obj.Position - singerHRP.Position).Magnitude < 900
                    if (nearPlayer or nearSinger) and not shared.G.hiddenParts[obj] then
                        shared.G.hiddenParts[obj] = obj.Transparency
                        obj.Transparency = 1
                        obj.CastShadow = false
                    end
                end
            end
            task.wait(1.5)
        end
    end)
end

local mainFolder = Instance.new("Folder", workspace)
mainFolder.Name = "_arigato_fx"

hideNearbyParts()

local spotLight = Instance.new("SpotLight", singerHRP or workspace)
spotLight.Brightness = 10; spotLight.Range = 90; spotLight.Angle = 55
spotLight.Color = Color3.fromRGB(255, 160, 255); spotLight.Face = Enum.NormalId.Top

local pointLight = Instance.new("PointLight", singerHead or workspace)
pointLight.Brightness = 4; pointLight.Range = 35; pointLight.Color = Color3.fromRGB(200, 80, 255)

local singerSpotDown = Instance.new("SpotLight", singerHRP or workspace)
singerSpotDown.Brightness = 6; singerSpotDown.Range = 70; singerSpotDown.Angle = 50
singerSpotDown.Color = Color3.fromRGB(120, 60, 255); singerSpotDown.Face = Enum.NormalId.Bottom

local stagePlatform
if singerHRP then
    stagePlatform = Instance.new("Part", mainFolder)
    stagePlatform.Size = Vector3.new(22, 0.5, 22)
    stagePlatform.Anchored = true; stagePlatform.CanCollide = false; stagePlatform.CastShadow = false
    stagePlatform.Material = Enum.Material.Neon
    stagePlatform.Color = Color3.fromRGB(60, 0, 140)
    stagePlatform.Transparency = 0.3
    stagePlatform.CFrame = CFrame.new(singerHRP.Position - Vector3.new(0, 5.5, 0))

    local stageGlow = Instance.new("PointLight", stagePlatform)
    stageGlow.Brightness = 2; stageGlow.Range = 40; stageGlow.Color = Color3.fromRGB(180, 0, 255)

    local stageRing = Instance.new("Part", mainFolder)
    stageRing.Size = Vector3.new(26, 0.3, 26)
    stageRing.Shape = Enum.PartType.Cylinder
    stageRing.Anchored = true; stageRing.CanCollide = false; stageRing.CastShadow = false
    stageRing.Material = Enum.Material.Neon
    stageRing.Color = Color3.fromRGB(255, 80, 220)
    stageRing.Transparency = 0.5
    stageRing.CFrame = CFrame.new(singerHRP.Position - Vector3.new(0, 5.3, 0)) * CFrame.Angles(0, 0, math.pi/2)
end

local showLightFolder = Instance.new("Folder", mainFolder)
showLightFolder.Name = "showlights"
shared.G.showLights = {}
local NUM_SHOW_LIGHTS = 8

for i = 1, NUM_SHOW_LIGHTS do
    local base = Instance.new("Part", showLightFolder)
    base.Size = Vector3.new(1, 1, 1); base.Anchored = true; base.CanCollide = false; base.CastShadow = false
    base.Material = Enum.Material.Neon
    base.Color = Color3.fromHSV((i-1)/NUM_SHOW_LIGHTS, 1, 1)
    base.Transparency = 0.2

    local top = Instance.new("Part", showLightFolder)
    top.Size = Vector3.new(0.5, 1.5, 0.5); top.Anchored = true; top.CanCollide = false; top.CastShadow = false
    top.Material = Enum.Material.Neon; top.Color = base.Color

    local a0 = Instance.new("Attachment", base)
    local a1 = Instance.new("Attachment", top)

    local beam = Instance.new("Beam", showLightFolder)
    beam.Attachment0 = a0; beam.Attachment1 = a1
    beam.Width0 = 3; beam.Width1 = 0.05
    beam.FaceCamera = true; beam.LightEmission = 1; beam.LightInfluence = 0
    beam.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, base.Color),
        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(((i-1)/NUM_SHOW_LIGHTS + 0.5) % 1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
    })
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.7, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    beam.Segments = 8

    local sl = Instance.new("SpotLight", top)
    sl.Brightness = 7; sl.Range = 90; sl.Angle = 18; sl.Color = base.Color

    table.insert(shared.G.showLights, {base=base, top=top, beam=beam, sl=sl, idx=i})
end

local function updateShowLights(t)
    if not singerHRP then return end
    local pos = singerHRP.Position
    for _, sl in ipairs(shared.G.showLights) do
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
        local newColor = Color3.fromHSV(hue, 1, 1)
        sl.base.Color = newColor; sl.sl.Color = newColor
        sl.beam.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, newColor),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV((hue+0.5)%1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
        })
    end
end
local pentaFolder = Instance.new("Folder", mainFolder)
pentaFolder.Name  = "pentagon"
shared.G.pentaParts = {}
local NUM_SIDES   = 6
local PENTA_RADIUS = 18
local PENTA_COLORS = {
    Color3.fromRGB(255,60,200),
    Color3.fromRGB(100,60,255),
    Color3.fromRGB(60,200,255),
    Color3.fromRGB(255,220,60),
    Color3.fromRGB(60,255,140),
    Color3.fromRGB(255,80,80),
}

for i = 1, NUM_SIDES do
    local p = Instance.new("Part", pentaFolder)
    p.Size = Vector3.new(0.7, 9, 1.2); p.Anchored = true; p.CanCollide = false
    p.Material = Enum.Material.Neon; p.Color = PENTA_COLORS[i]; p.CastShadow = false
    local a0 = Instance.new("Attachment", p); a0.Position = Vector3.new(0, 0.5, 0)
    local a1 = Instance.new("Attachment", p); a1.Position = Vector3.new(0, -0.5, 0)
    local tr = Instance.new("Trail", p)
    tr.Attachment0 = a0; tr.Attachment1 = a1
    tr.Lifetime = 0.18; tr.MinLength = 0
    tr.Color = ColorSequence.new(PENTA_COLORS[i], Color3.fromRGB(255,255,255))
    tr.Transparency = NumberSequence.new(0.2, 1)
    tr.LightEmission = 1
    table.insert(shared.G.pentaParts, p)
end

local function updatePentagon(angle)
    if not singerHRP or not singerHRP.Parent then return end
    local backOffset = CFrame.new(0, 2, 10)
    local base = singerHRP.CFrame * backOffset
    for i, p in ipairs(shared.G.pentaParts) do
        local a1 = angle + (i-1)*(math.pi*2/NUM_SIDES)
        local a2 = angle + i    *(math.pi*2/NUM_SIDES)
        local r  = PENTA_RADIUS
        local p1 = base.Position + Vector3.new(math.cos(a1)*r, math.sin(a1)*r*0.5, math.sin(a1)*0.5)
        local p2 = base.Position + Vector3.new(math.cos(a2)*r, math.sin(a2)*r*0.5, math.sin(a2)*0.5)
        local mid  = (p1+p2)/2
        local len  = (p2-p1).Magnitude
        local look = (p2-p1).Unit
        p.Size   = Vector3.new(0.7, len, 1.2)
        p.CFrame = CFrame.lookAt(mid, mid+look) * CFrame.Angles(math.pi/2, 0, 0)
        local hue = ((angle*0.05 + (i-1)/NUM_SIDES) % 1)
        p.Color   = Color3.fromHSV(hue, 1, 1)
    end
end

local orbitFolder = Instance.new("Folder", mainFolder)
orbitFolder.Name  = "orbit"
shared.G.orbitParts = {}
local NUM_ORBIT   = 20
local ORBIT_RADIUS = 22

for i = 1, NUM_ORBIT do
    local p = Instance.new("Part", orbitFolder)
    p.Size = Vector3.new(1.6, 1.6, 1.6); p.Shape = Enum.PartType.Ball
    p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Neon; p.CastShadow = false
    p.Color = Color3.fromHSV((i-1)/NUM_ORBIT, 1, 1)
    local pl = Instance.new("PointLight", p); pl.Brightness = 2.5; pl.Range = 14; pl.Color = p.Color
    local att0 = Instance.new("Attachment", p); att0.Position = Vector3.new(0, 0.5, 0)
    local att1 = Instance.new("Attachment", p); att1.Position = Vector3.new(0, -0.5, 0)
    local tr = Instance.new("Trail", p)
    tr.Attachment0 = att0; tr.Attachment1 = att1
    tr.Lifetime = 0.25; tr.MinLength = 0; tr.LightEmission = 1
    tr.Color = ColorSequence.new(p.Color, Color3.fromRGB(255,255,255))
    tr.Transparency = NumberSequence.new(0.2, 1)
    table.insert(shared.G.orbitParts, p)
end

shared.G.outerOrbitParts = {}
local NUM_OUTER = 10
for i = 1, NUM_OUTER do
    local p = Instance.new("Part", orbitFolder)
    p.Size = Vector3.new(3, 3, 3); p.Shape = Enum.PartType.Ball
    p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Neon; p.CastShadow = false
    p.Color = Color3.fromHSV((i-1)/NUM_OUTER, 1, 1)
    local pl = Instance.new("PointLight", p); pl.Brightness = 4; pl.Range = 22; pl.Color = p.Color
    table.insert(shared.G.outerOrbitParts, p)
end

shared.G.ringOrbitParts = {}
local NUM_RING_ORBIT = 6
for i = 1, NUM_RING_ORBIT do
    local ring = Instance.new("Part", orbitFolder)
    ring.Size = Vector3.new(0.4, 6, 6)
    ring.Shape = Enum.PartType.Cylinder
    ring.Anchored = true; ring.CanCollide = false; ring.Material = Enum.Material.Neon; ring.CastShadow = false
    ring.Color = Color3.fromHSV((i-1)/NUM_RING_ORBIT, 1, 1)
    ring.Transparency = 0.3
    table.insert(shared.G.ringOrbitParts, ring)
end

local function updateOrbit(t)
    if not singerHRP or not singerHRP.Parent then return end
    local center = singerHRP.Position + Vector3.new(0, 6, 0)
    for i, p in ipairs(shared.G.orbitParts) do
        local angle = t * 1.3 + (i-1)*(math.pi*2/NUM_ORBIT)
        local x = math.cos(angle) * ORBIT_RADIUS
        local z = math.sin(angle) * ORBIT_RADIUS
        local y = math.sin(t*2 + i) * 5
        p.Position = center + Vector3.new(x, y, z)
        local hue  = ((t*0.1 + (i-1)/NUM_ORBIT) % 1)
        p.Color    = Color3.fromHSV(hue, 1, 1)
        local pl   = p:FindFirstChildOfClass("PointLight")
        if pl then pl.Color = p.Color end
    end
    local outerR = 42
    for i, p in ipairs(shared.G.outerOrbitParts) do
        local angle = -t * 0.65 + (i-1)*(math.pi*2/NUM_OUTER)
        local x = math.cos(angle) * outerR
        local z = math.sin(angle) * outerR
        local y = math.sin(t*1.4 + i*1.3) * 10 + 12
        p.Position = singerHRP.Position + Vector3.new(x, y, z)
        local hue = ((t*0.08 + (i-1)/NUM_OUTER + 0.5) % 1)
        p.Color = Color3.fromHSV(hue, 1, 1)
        local pl = p:FindFirstChildOfClass("PointLight")
        if pl then pl.Color = p.Color end
    end
    local ringR = 26
    for i, ring in ipairs(shared.G.ringOrbitParts) do
        local angle = t * 0.4 + (i-1)*(math.pi*2/NUM_RING_ORBIT)
        local x = math.cos(angle) * ringR
        local z = math.sin(angle) * ringR
        local y = math.sin(t * 0.8 + i) * 8 + 4
        ring.CFrame = CFrame.new(singerHRP.Position + Vector3.new(x, y, z))
            * CFrame.Angles(angle, t * 0.6 + i, math.sin(t*0.3 + i) * 0.5)
        ring.Color = Color3.fromHSV(((t*0.07 + (i-1)/NUM_RING_ORBIT) % 1), 1, 1)
        ring.Transparency = 0.25 + math.abs(math.sin(t * 0.8 + i)) * 0.35
    end
end

local starFolder = Instance.new("Folder", mainFolder)
starFolder.Name = "stars"
shared.G.starParts = {}
local NUM_STARS = 40

for i = 1, NUM_STARS do
    local s = Instance.new("Part", starFolder)
    s.Size = Vector3.new(0.5,0.5,0.5); s.Shape = Enum.PartType.Ball
    s.Anchored = true; s.CanCollide = false; s.Material = Enum.Material.Neon; s.CastShadow = false
    s.Color = Color3.fromHSV(math.random(), 1, 1)
    local randX = math.random(-70,70); local randY = math.random(25,90); local randZ = math.random(-70,70)
    table.insert(shared.G.starParts, {part=s, ox=randX, oy=randY, oz=randZ, phase=math.random()*math.pi*2, speed=math.random()*0.6+0.3})
end

local function updateStars(t)
    if not singerHRP then return end
    for _, sd in ipairs(shared.G.starParts) do
        local p = sd.part
        local twinkle = math.abs(math.sin(t*sd.speed + sd.phase))
        local sz = twinkle*0.7+0.1
        p.Size = Vector3.new(sz,sz,sz)
        p.Position = singerHRP.Position + Vector3.new(sd.ox, sd.oy, sd.oz)
        p.Color = Color3.fromHSV(((t*0.05 + sd.phase) % 1), 1, 1)
    end
end

local nebulaFolder = Instance.new("Folder", mainFolder)
nebulaFolder.Name = "nebula"
shared.G.nebulaParts = {}
local NUM_NEBULA = 16

for i = 1, NUM_NEBULA do
    local p = Instance.new("Part", nebulaFolder)
    p.Size = Vector3.new(math.random(7,16), math.random(7,16), 0.2)
    p.Anchored = true; p.CanCollide = false; p.CastShadow = false
    p.Material = Enum.Material.Neon
    p.Color = Color3.fromHSV((i-1)/NUM_NEBULA, 0.8, 1)
    p.Transparency = 0.72
    local rA = math.random() * math.pi * 2
    local rD = math.random(35, 65)
    local rH = math.random(18, 55)
    table.insert(shared.G.nebulaParts, {part=p, rA=rA, rD=rD, rH=rH, phase=math.random()*math.pi*2, speed=math.random()*0.18+0.04})
end

local function updateNebula(t)
    if not singerHRP then return end
    for _, nd in ipairs(shared.G.nebulaParts) do
        local p = nd.part
        local angle = nd.rA + t * nd.speed
        local pos = singerHRP.Position + Vector3.new(
            math.cos(angle) * nd.rD,
            nd.rH + math.sin(t * 0.3 + nd.phase) * 6,
            math.sin(angle) * nd.rD
        )
        p.CFrame = CFrame.new(pos) * CFrame.Angles(math.sin(t*0.1+nd.phase)*0.3, angle, 0)
        local hue = ((t * 0.04 + nd.phase) % 1)
        p.Color = Color3.fromHSV(hue, 0.85, 1)
        p.Transparency = 0.62 + math.sin(t * nd.speed * 2 + nd.phase) * 0.15
    end
end

local confettiFolder = Instance.new("Folder", mainFolder)
confettiFolder.Name = "confetti"

local function spawnConfetti(count, origin)
    origin = origin or (singerHRP and singerHRP.Position or Vector3.new(0,10,0))
    for i = 1, count do
        task.spawn(function()
            local c = Instance.new("Part", confettiFolder)
            c.Size = Vector3.new(0.35, 0.06, 0.7)
            c.Material = Enum.Material.Neon
            c.Anchored = false; c.CanCollide = false; c.CastShadow = false
            c.Color = Color3.fromHSV(math.random(), 1, 1)
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

local spiralFolder = Instance.new("Folder", mainFolder)
spiralFolder.Name = "spiral"

local function spawnSpiralRings(count)
    if not singerHRP then return end
    task.spawn(function()
        for i = 1, count do
            task.spawn(function()
                local r = Instance.new("Part", spiralFolder)
                r.Size = Vector3.new(0.4, 0.4, 0.4)
                r.Shape = Enum.PartType.Ball
                r.Material = Enum.Material.Neon
                r.Anchored = true; r.CanCollide = false; r.CastShadow = false
                r.Color = Color3.fromHSV((i-1)/count, 1, 1)
                local startPos = singerHRP.Position
                local angle = (i-1) * (math.pi * 2 / count)
                local t = 0
                local conn2
                conn2 = RunService.RenderStepped:Connect(function(dt)
                    t = t + dt * 3
                    if not singerHRP or not singerHRP.Parent or t > 2 then
                        r:Destroy(); conn2:Disconnect(); return
                    end
                    local radius = (1 - t/2) * 14
                    local height = t * 18
                    r.Position = startPos + Vector3.new(
                        math.cos(angle + t * 2) * radius,
                        height,
                        math.sin(angle + t * 2) * radius
                    )
                    r.Color = Color3.fromHSV(((t * 0.2 + (i-1)/count) % 1), 1, 1)
                    local sz = math.max(0.1, 1.5 - t * 0.6)
                    r.Size = Vector3.new(sz,sz,sz)
                    r.Transparency = math.min(1, t * 0.5)
                end)
            end)
            task.wait(0.04)
        end
    end)
end

local function spawnDNAHelix(duration)
    if not singerHRP then return end
    task.spawn(function()
        local helixParts = {}
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
                local conn2
                conn2 = RunService.RenderStepped:Connect(function(dt)
                    t = t + dt
                    if not singerHRP or not singerHRP.Parent or t > duration then
                        dot:Destroy(); conn2:Disconnect(); return
                    end
                    local baseAngle = (i-1) * (math.pi * 2 / numDots) + t * 1.5 + (j == 2 and math.pi or 0)
                    local r2 = 8
                    dot.Position = singerHRP.Position + Vector3.new(
                        math.cos(baseAngle) * r2,
                        (i-1) * 1.1 - 10,
                        math.sin(baseAngle) * r2
                    )
                    dot.Color = Color3.fromHSV(((t*0.08 + (i-1)/numDots + (j-1)*0.5) % 1), 1, 1)
                end)
                table.insert(helixParts, dot)
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
            p.Size = Vector3.new(0.5, 5, 0.5)
            p.Material = Enum.Material.Neon; p.Anchored = true
            p.CanCollide = false; p.CastShadow = false
            p.Color = Color3.fromHSV((i-1)/numParts, 1, 1)
            table.insert(parts, p)
        end
        local conn2
        conn2 = RunService.RenderStepped:Connect(function(dt)
            t = t + dt
            if not singerHRP or not singerHRP.Parent or t > duration then
                for _, pp in ipairs(parts) do pcall(function() pp:Destroy() end) end
                conn2:Disconnect(); return
            end
            for i, pp in ipairs(parts) do
                local angle = (i-1)*(math.pi*2/numParts) + t * speed
                pp.CFrame = CFrame.new(
                    singerHRP.Position + Vector3.new(
                        math.cos(angle) * radius,
                        height + math.sin(t * 2 + i) * 3,
                        math.sin(angle) * radius
                    )
                ) * CFrame.Angles(0, angle + math.pi/2, math.sin(t + i) * 0.3)
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
    local hexParts = {}
    for i = 1, hexCount do
        local h = Instance.new("Part", hexFolder)
        h.Size = Vector3.new(3.5, 0.15, 3.5)
        h.Anchored = true; h.CanCollide = false; h.CastShadow = false
        h.Material = Enum.Material.Neon
        h.Color = Color3.fromHSV((i-1)/hexCount, 1, 1)
        h.Transparency = 0.6
        local baseAngle = (i-1) * (math.pi * 2 / hexCount)
        local baseR = math.random(3, 12)
        local baseY = singerHRP.Position.Y - 5.2
        h.CFrame = CFrame.new(
            singerHRP.Position.X + math.cos(baseAngle)*baseR,
            baseY,
            singerHRP.Position.Z + math.sin(baseAngle)*baseR
        )
        table.insert(hexParts, {part=h, baseAngle=baseAngle, baseR=baseR, phase=math.random()*math.pi*2})
    end

    local t = 0
    local hexConn
    hexConn = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        if shared.G.finished then hexConn:Disconnect(); hexFolder:Destroy(); return end
        for _, hd in ipairs(hexParts) do
            local hue = ((t*0.04 + hd.baseAngle/(math.pi*2)) % 1)
            hd.part.Color = Color3.fromHSV(hue, 1, 1)
            local pulse = 0.4 + math.abs(math.sin(t * 1.5 + hd.phase)) * 0.35
            hd.part.Transparency = pulse
        end
    end)
end

spawnFloorHexGrid()

shared.G.BPM = 128
local beatInterval = 60 / shared.G.BPM
shared.G.lastBeatTick = 0
shared.G.beatCount = 0
shared.G.beatStrength = 0

local waveFolder = Instance.new("Folder", mainFolder)
waveFolder.Name = "soundwaves"
local NUM_WAVE_BARS = 32
shared.G.waveBars = {}
for i = 1, NUM_WAVE_BARS do
    local bar = Instance.new("Part", waveFolder)
    bar.Anchored = true; bar.CanCollide = false; bar.CastShadow = false
    bar.Material = Enum.Material.Neon
    bar.Size = Vector3.new(0.55, 1, 0.55)
    bar.Color = Color3.fromHSV((i-1)/NUM_WAVE_BARS, 1, 1)
    bar.Transparency = 0.1
    local bpl = Instance.new("PointLight", bar); bpl.Brightness = 1.2; bpl.Range = 6; bpl.Color = bar.Color
    table.insert(shared.G.waveBars, bar)
end

local function updateSoundWaves(t, bStr)
    if not singerHRP then return end
    local center = singerHRP.Position
    local waveRadius = 9
    for i, bar in ipairs(shared.G.waveBars) do
        local angle = (i-1) * (math.pi*2 / NUM_WAVE_BARS)
        local freqSim = math.abs(math.sin(t * (2 + i * 0.18) + i * 0.4)) * (0.7 + bStr * 0.8)
        local barH = 0.5 + freqSim * 8
        bar.Size = Vector3.new(0.55, barH, 0.55)
        local px = center.X + math.cos(angle) * waveRadius
        local pz = center.Z + math.sin(angle) * waveRadius
        bar.CFrame = CFrame.new(px, center.Y + barH/2, pz)
        local hue = ((t * 0.08 + (i-1)/NUM_WAVE_BARS) % 1)
        bar.Color = Color3.fromHSV(hue, 1, 1)
        local bpl2 = bar:FindFirstChildOfClass("PointLight")
        if bpl2 then bpl2.Color = bar.Color; bpl2.Brightness = 0.8 + freqSim * 2 end
    end
end

local starShapeFolder = Instance.new("Folder", mainFolder)
starShapeFolder.Name = "starshape"
local NUM_STAR_POINTS = 5
shared.G.starEdgeParts = {}
shared.G.starAngle = 0

local function rebuildStarEdges()
    for _, p in ipairs(shared.G.starEdgeParts) do pcall(function() p:Destroy() end) end
    shared.G.starEdgeParts = {}
    if not singerHRP then return end
    local totalVerts = NUM_STAR_POINTS * 2
    for i = 1, totalVerts do
        local edge = Instance.new("Part", starShapeFolder)
        edge.Size = Vector3.new(0.45, 0.25, 1)
        edge.Anchored = true; edge.CanCollide = false; edge.CastShadow = false
        edge.Material = Enum.Material.Neon
        edge.Color = Color3.fromHSV((i-1)/totalVerts, 1, 1)
        edge.Transparency = 0.1
        local spl = Instance.new("PointLight", edge); spl.Brightness = 2; spl.Range = 10; spl.Color = edge.Color
        table.insert(shared.G.starEdgeParts, edge)
    end
end
rebuildStarEdges()

local function updateStarShape(t)
    shared.G.starAngle = shared.G.starAngle + 0.008
    if not singerHRP or #shared.G.starEdgeParts == 0 then return end
    local cx = singerHRP.Position.X
    local cz = singerHRP.Position.Z
    local cy = singerHRP.Position.Y - 5.0
    local outerR = 16; local innerR = 7
    local allVerts = {}
    for i = 1, NUM_STAR_POINTS do
        local outerAngle = (i-1)*(math.pi*2/NUM_STAR_POINTS) - math.pi/2 + shared.G.starAngle
        local innerAngle = outerAngle + math.pi/NUM_STAR_POINTS
        table.insert(allVerts, Vector3.new(cx + math.cos(outerAngle)*outerR, cy, cz + math.sin(outerAngle)*outerR))
        table.insert(allVerts, Vector3.new(cx + math.cos(innerAngle)*innerR, cy, cz + math.sin(innerAngle)*innerR))
    end
    for i, edge in ipairs(shared.G.starEdgeParts) do
        local v1 = allVerts[i]
        local v2 = allVerts[(i % #allVerts) + 1]
        if v1 and v2 then
            local mid = (v1 + v2) / 2
            local len = (v2 - v1).Magnitude
            local look = (v2 - v1).Unit
            edge.Size = Vector3.new(0.45 + math.abs(math.sin(t*2+i))*0.3, 0.25, len)
            edge.CFrame = CFrame.lookAt(mid, mid + look)
            local hue = ((t*0.06 + (i-1)/#shared.G.starEdgeParts) % 1)
            edge.Color = Color3.fromHSV(hue, 1, 1)
            local spl2 = edge:FindFirstChildOfClass("PointLight")
            if spl2 then spl2.Color = edge.Color end
        end
    end
end

local hexagonShapeFolder = Instance.new("Folder", mainFolder)
hexagonShapeFolder.Name = "hexshape"
shared.G.hexShapeEdges = {}
shared.G.hexShapeAngle = 0

local function rebuildHexEdges(radius)
    for _, e in ipairs(shared.G.hexShapeEdges) do pcall(function() e:Destroy() end) end
    shared.G.hexShapeEdges = {}
    if not singerHRP then return end
    for i = 1, 6 do
        local edge3 = Instance.new("Part", hexagonShapeFolder)
        edge3.Size = Vector3.new(0.5, 0.3, 1)
        edge3.Anchored = true; edge3.CanCollide = false; edge3.CastShadow = false
        edge3.Material = Enum.Material.Neon
        edge3.Color = Color3.fromHSV((i-1)/6, 1, 1)
        edge3.Transparency = 0.1
        local hpl = Instance.new("PointLight", edge3); hpl.Brightness = 2.5; hpl.Range = 12; hpl.Color = edge3.Color
        table.insert(shared.G.hexShapeEdges, edge3)
    end
end
rebuildHexEdges(20)

local function updateHexShape(t)
    shared.G.hexShapeAngle = shared.G.hexShapeAngle + 0.012
    if not singerHRP or #shared.G.hexShapeEdges == 0 then return end
    local sides2 = 6
    local radius = 20 + math.sin(t*0.4)*4
    local cx = singerHRP.Position.X; local cz = singerHRP.Position.Z
    local cy = singerHRP.Position.Y - 5.0
    for i, edge3 in ipairs(shared.G.hexShapeEdges) do
        local a1 = (i-1)*(math.pi*2/sides2) + shared.G.hexShapeAngle
        local a2 = i*(math.pi*2/sides2) + shared.G.hexShapeAngle
        local v1 = Vector3.new(cx + math.cos(a1)*radius, cy, cz + math.sin(a1)*radius)
        local v2 = Vector3.new(cx + math.cos(a2)*radius, cy, cz + math.sin(a2)*radius)
        local mid3 = (v1+v2)/2
        local len3 = (v2-v1).Magnitude
        local look3 = (v2-v1).Unit
        edge3.Size = Vector3.new(0.5, 0.3, len3)
        edge3.CFrame = CFrame.lookAt(mid3, mid3+look3)
        local hue3 = ((t*0.06 + (i-1)/sides2) % 1)
        edge3.Color = Color3.fromHSV(hue3, 1, 1)
        local hpl2 = edge3:FindFirstChildOfClass("PointLight")
        if hpl2 then hpl2.Color = edge3.Color end
    end
end

local portalFolder = Instance.new("Folder", mainFolder)
portalFolder.Name = "portal"
shared.G.portalRings = {}
local NUM_PORTAL = 8

local function buildPortal()
    for _, p in ipairs(shared.G.portalRings) do pcall(function() p:Destroy() end) end
    shared.G.portalRings = {}
    if not singerHRP then return end
    for i = 1, NUM_PORTAL do
        local ring2 = Instance.new("Part", portalFolder)
        ring2.Size = Vector3.new(0.3, 10+i*2, 10+i*2)
        ring2.Shape = Enum.PartType.Cylinder
        ring2.Anchored = true; ring2.CanCollide = false; ring2.CastShadow = false
        ring2.Material = Enum.Material.Neon
        ring2.Color = Color3.fromHSV((i-1)/NUM_PORTAL, 1, 1)
        ring2.Transparency = 0.55 + i*0.03
        ring2.CFrame = CFrame.new(singerHRP.Position + Vector3.new(0, 4+i*2.5, 0))
        table.insert(shared.G.portalRings, ring2)
    end
end
buildPortal()

local function updatePortal(t)
    if not singerHRP or #shared.G.portalRings == 0 then return end
    for i, ring2 in ipairs(shared.G.portalRings) do
        ring2.CFrame = CFrame.new(singerHRP.Position + Vector3.new(0, 4+i*2.5, 0))
            * CFrame.Angles(t * (0.3 + i*0.08), t * 0.15, 0)
        local hue = ((t*0.05 + (i-1)/NUM_PORTAL) % 1)
        ring2.Color = Color3.fromHSV(hue, 1, 1)
        ring2.Transparency = 0.45 + math.abs(math.sin(t*0.6+i))*0.3
    end
end

local shockwaveRingFolder = Instance.new("Folder", mainFolder)
shockwaveRingFolder.Name = "beatrings"

local function spawnBeatRing(pos, color, bStr)
    task.spawn(function()
        local ring3 = Instance.new("Part", shockwaveRingFolder)
        local initSz = 1 + bStr * 2
        ring3.Size = Vector3.new(initSz, 0.3, initSz)
        ring3.Shape = Enum.PartType.Cylinder
        ring3.Material = Enum.Material.Neon
        ring3.Color = color or Color3.fromRGB(255,100,255)
        ring3.Anchored = true; ring3.CanCollide = false; ring3.CastShadow = false
        ring3.Transparency = 0.1
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
        local sides = 3
        local triParts = {}
        for i = 1, sides do
            local a1 = (i-1)*(math.pi*2/sides)
            local a2 = i*(math.pi*2/sides)
            local v1 = Vector3.new(math.cos(a1)*size, 0, math.sin(a1)*size)
            local v2 = Vector3.new(math.cos(a2)*size, 0, math.sin(a2)*size)
            local midT = pos + (v1+v2)/2
            local lenT = (v2-v1).Magnitude
            local lookT = (v2-v1).Unit
            local edgeT = Instance.new("Part", triangleFolder)
            edgeT.Size = Vector3.new(0.35, 0.35, lenT)
            edgeT.Anchored = true; edgeT.CanCollide = false; edgeT.CastShadow = false
            edgeT.Material = Enum.Material.Neon
            edgeT.Color = Color3.fromHSV(math.random(), 1, 1)
            edgeT.Transparency = 0.1
            edgeT.CFrame = CFrame.lookAt(midT, midT+lookT)
            table.insert(triParts, edgeT)
        end
        local t2 = 0
        local connT
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

local zoomBlurFrame = nil
shared.G.colorSplitActive = false
local colorSplitFrame1 = nil
local colorSplitFrame2 = nil
local scanlines = nil

local function doZoomBlurHit(duration)
    if not zoomBlurFrame then return end
    TweenService:Create(zoomBlurFrame, TweenInfo.new(0.05), {BackgroundTransparency = 0.75}):Play()
    task.delay(duration or 0.12, function()
        TweenService:Create(zoomBlurFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
    end)
end

local function doColorSplit(duration, strength)
    if shared.G.colorSplitActive or not colorSplitFrame1 then return end
    shared.G.colorSplitActive = true
    strength = strength or 0.015
    colorSplitFrame1.Position = UDim2.new(-strength, 0, 0, 0); colorSplitFrame1.BackgroundTransparency = 0.75
    colorSplitFrame2.Position = UDim2.new(strength, 0, 0, 0); colorSplitFrame2.BackgroundTransparency = 0.75
    task.delay(duration or 0.2, function()
        TweenService:Create(colorSplitFrame1, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
        TweenService:Create(colorSplitFrame2, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
        task.delay(0.25, function() shared.G.colorSplitActive = false end)
    end)
end

local gyroFolder = Instance.new("Folder", mainFolder)
gyroFolder.Name = "gyrorings"
shared.G.GYRO_RINGS = {}
local GYRO_COUNT = 6
local GYRO_RADII = {25, 32, 39, 46, 53, 60}
local GYRO_AXES  = {
    Vector3.new(1,0,0), Vector3.new(0,1,0), Vector3.new(0,0,1),
    Vector3.new(1,1,0).Unit, Vector3.new(0,1,1).Unit, Vector3.new(1,0,1).Unit,
}
for i = 1, GYRO_COUNT do
    local r = GYRO_RADII[i]
    local gr = Instance.new("Part", gyroFolder)
    gr.Size = Vector3.new(r*2, 0.55, r*2)
    gr.Shape = Enum.PartType.Cylinder
    gr.Material = Enum.Material.Neon
    gr.Anchored = true; gr.CanCollide = false; gr.CastShadow = false
    gr.Color = Color3.fromHSV((i-1)/GYRO_COUNT, 1, 1)
    gr.Transparency = 0.35
    local gpl = Instance.new("PointLight", gr)
    gpl.Brightness = 1.8; gpl.Range = 20; gpl.Color = gr.Color
    table.insert(shared.G.GYRO_RINGS, {part=gr, pl=gpl, axis=GYRO_AXES[i], radius=r, speed=(i%2==0 and 1 or -1)*(0.28+i*0.07), phase=(i-1)*math.pi/GYRO_COUNT})
end

local function updateGyroRings(t)
    if not singerHRP or not singerHRP.Parent then return end
    local center = singerHRP.Position + Vector3.new(0, 8, 0)
    for _, gd in ipairs(shared.G.GYRO_RINGS) do
        local angle = t * gd.speed + gd.phase
        gd.part.CFrame = CFrame.new(center) * CFrame.fromAxisAngle(gd.axis, angle) * CFrame.Angles(0, 0, math.pi/2)
        local col = Color3.fromHSV(((t*0.05 + gd.phase/(math.pi*2)) % 1), 1, 1)
        gd.part.Color = col
        gd.pl.Color = col
        gd.part.Transparency = 0.3 + math.abs(math.sin(t*0.4 + gd.phase)) * 0.35
    end
end

local function spawnPillarRing(count, height, radius)
    if not singerHRP then return end
    task.spawn(function()
        local parts = {}
        for i = 1, count do
            local angle = (i-1)*(math.pi*2/count)
            local p = Instance.new("Part", mainFolder)
            p.Size = Vector3.new(0.5, height or 12, 0.5)
            p.Material = Enum.Material.Neon; p.Anchored = true
            p.CanCollide = false; p.CastShadow = false
            p.Color = Color3.fromHSV((i-1)/count, 1, 1)
            local pos = singerHRP.Position + Vector3.new(
                math.cos(angle)*(radius or 12), (height or 12)/2 - 5, math.sin(angle)*(radius or 12)
            )
            p.CFrame = CFrame.new(pos)
            TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = Vector3.new(0.5, (height or 12)*1.5, 0.5)
            }):Play()
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
cubeFolder.Name  = "cubes"

local function spawnExplosiveCubes(count, origin)
    origin = origin or (singerHRP and singerHRP.Position or Vector3.new(0,10,0))
    for i = 1, count do
        task.spawn(function()
            local cube = Instance.new("Part", cubeFolder)
            cube.Size = Vector3.new(math.random(1,3), math.random(1,3), math.random(1,3))
            cube.Material = Enum.Material.Neon; cube.Anchored = false
            cube.CanCollide = false; cube.CastShadow = false
            cube.Color = Color3.fromHSV(math.random(), 1, 1)
            cube.CFrame = CFrame.new(origin)
            local pl2 = Instance.new("PointLight", cube); pl2.Brightness = 2; pl2.Range = 9; pl2.Color = cube.Color
            local bv = Instance.new("BodyVelocity", cube)
            bv.Velocity = Vector3.new(math.random(-28,28), math.random(12,50), math.random(-28,28))
            bv.MaxForce = Vector3.new(1e5,1e5,1e5)
            TweenService:Create(cube, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = Vector3.new(0.1,0.1,0.1), Transparency = 1
            }):Play()
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
            ring.Size = Vector3.new(2, 0.35, 2)
            ring.Shape = Enum.PartType.Cylinder; ring.Material = Enum.Material.Neon
            ring.Color = color or Color3.fromRGB(255,100,255)
            ring.Anchored = true; ring.CanCollide = false; ring.CastShadow = false
            ring.Transparency = 0.15
            ring.CFrame = CFrame.new(singerHRP.Position + Vector3.new(0, (i-1)*2, 0)) * CFrame.Angles(0, 0, math.pi/2)
            TweenService:Create(ring, TweenInfo.new(0.75 + i*0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = Vector3.new(80*scale, 0.35, 80*scale), Transparency = 1
            }):Play()
            Debris:AddItem(ring, 0.95 + i*0.1)
            task.wait(0.04)
        end
    end)
end

local function spawnLaserRing(height, colors)
    if not singerHRP then return end
    task.spawn(function()
        local count = 14
        local radius = 7
        local parts = {}
        for i = 1, count do
            local p = Instance.new("Part", mainFolder)
            p.Size = Vector3.new(0.35, 9, 0.35)
            p.Material = Enum.Material.Neon; p.Anchored = true; p.CanCollide = false; p.CastShadow = false
            local hue = (colors and colors[(i % #colors)+1]) or Color3.fromHSV((i-1)/count, 1, 1)
            p.Color = hue
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
            p.Size = Vector3.new(0.3, 0.3, 14)
            p.Material = Enum.Material.Neon; p.Anchored = true; p.CanCollide = false; p.CastShadow = false
            p.Color = Color3.fromHSV((i-1)/numSpikes, 1, 1)
            local angle = (i-1) * (math.pi * 2 / numSpikes)
            local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
            p.CFrame = CFrame.lookAt(singerHRP.Position + Vector3.new(0, 4, 0), singerHRP.Position + Vector3.new(0, 4, 0) + dir)
                * CFrame.new(0, 0, -7)
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
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,60,200)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255,200,60)),
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(60,200,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(60,255,140)),
    })
    pe.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(0.5, 1.4), NumberSequenceKeypoint.new(1, 0)
    })
    pe.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)
    })
    pe.RotSpeed = NumberRange.new(-220, 220)
    pe.Rotation = NumberRange.new(0, 360)
    return pe
end

local singerParticles = addParticles(singerHRP)
local playerParticles = addParticles(playerHRP)

local function burstParticles(pe, count)
    if pe and pe.Parent then pe:Emit(count or 20) end
end

local EMOTE_IDS = {
    dance    = "rbxassetid://507771019",
    wave     = "rbxassetid://507770718",
    point    = "rbxassetid://507770453",
    cheer    = "rbxassetid://507770677",
    laugh    = "rbxassetid://507770818",
    sit      = "rbxassetid://507770872",
    salute   = "rbxassetid://3360689775",
    robot    = "rbxassetid://3360695866",
    flip     = "rbxassetid://507770239",
    shrug    = "rbxassetid://3360692915",
    spin     = "rbxassetid://5893839727",
}

shared.G.currentAnimTrack = nil

local function playSingerAnim(animId)
    if not singerHum then return end
    if shared.G.currentAnimTrack then pcall(function() shared.G.currentAnimTrack:Stop(0.3) end); shared.G.currentAnimTrack = nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local ok, track = pcall(function() return singerHum:LoadAnimation(anim) end)
    if ok and track then
        track.Looped = true; track:Play(0.3); shared.G.currentAnimTrack = track
    end
end

local function singerDance()  playSingerAnim(EMOTE_IDS.dance)  end
local function singerCheer()  playSingerAnim(EMOTE_IDS.cheer)  end
local function singerPoint()  playSingerAnim(EMOTE_IDS.point)  end
local function singerLaugh()  playSingerAnim(EMOTE_IDS.laugh)  end
local function singerWave()   playSingerAnim(EMOTE_IDS.wave)   end
local function singerSalute() playSingerAnim(EMOTE_IDS.salute) end
local function singerRobot()  playSingerAnim(EMOTE_IDS.robot)  end
local function singerFlip()   playSingerAnim(EMOTE_IDS.flip)   end
local function singerShrug()  playSingerAnim(EMOTE_IDS.shrug)  end
local function singerSpin()   playSingerAnim(EMOTE_IDS.spin)   end

singerDance()

local sg = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
sg.Name = "ArigatoShowGui"; sg.IgnoreGuiInset = true
sg.ResetOnSpawn = false; sg.DisplayOrder = 999
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function makeFrame(parent, props)
    local f = Instance.new("Frame", parent)
    f.BorderSizePixel = 0
    for k,v in pairs(props) do f[k] = v end
    return f
end

local BAR_H = 75

local cinemaTop = makeFrame(sg, {
    Size = UDim2.new(1,4,0,BAR_H+4), Position = UDim2.new(-0.002,0,0,-(BAR_H+4)),
    BackgroundColor3 = Color3.new(0,0,0), ZIndex = 10,
})
local cinemaBot = makeFrame(sg, {
    Size = UDim2.new(1,4,0,BAR_H+4), Position = UDim2.new(-0.002,0,1,0),
    BackgroundColor3 = Color3.new(0,0,0), ZIndex = 10,
})

TweenService:Create(cinemaTop, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(-0.002,0,0,-2)}):Play()
TweenService:Create(cinemaBot, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(-0.002,0,1,-(BAR_H+2))}):Play()

local lyricOuter = makeFrame(sg, {
    Size = UDim2.new(0.65,0,0,72), Position = UDim2.new(0.175,0,1,-162),
    BackgroundColor3 = Color3.fromRGB(20,0,55), BackgroundTransparency = 0.3, ZIndex = 9,
})
Instance.new("UICorner", lyricOuter).CornerRadius = UDim.new(0, 12)
local lyricStroke = Instance.new("UIStroke", lyricOuter)
lyricStroke.Color = Color3.fromRGB(210,80,255); lyricStroke.Thickness = 2.8; lyricStroke.Transparency = 0.15

local lyricLabel = Instance.new("TextLabel", lyricOuter)
lyricLabel.Size = UDim2.new(1,-22,0,40); lyricLabel.Position = UDim2.new(0,11,0,4)
lyricLabel.BackgroundTransparency = 1; lyricLabel.TextColor3 = Color3.new(1,1,1)
lyricLabel.TextStrokeTransparency = 0.1; lyricLabel.TextStrokeColor3 = Color3.fromRGB(140,0,255)
lyricLabel.Font = Enum.Font.GothamBold; lyricLabel.TextSize = 28
lyricLabel.TextXAlignment = Enum.TextXAlignment.Center; lyricLabel.Text = ""; lyricLabel.ZIndex = 11

local subLabel = Instance.new("TextLabel", lyricOuter)
subLabel.Size = UDim2.new(1,-22,0,26); subLabel.Position = UDim2.new(0,11,0,44)
subLabel.BackgroundTransparency = 1; subLabel.TextColor3 = Color3.fromRGB(215,175,255)
subLabel.TextStrokeTransparency = 0.4; subLabel.Font = Enum.Font.Gotham
subLabel.TextSize = 16; subLabel.TextXAlignment = Enum.TextXAlignment.Center
subLabel.Text = ""; subLabel.ZIndex = 11

local flashFrame = makeFrame(sg, {
    Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(1,1,1),
    BackgroundTransparency = 1, ZIndex = 20,
})

local vignetteFrame = makeFrame(sg, {
    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ZIndex = 8,
})
local vgGrad = Instance.new("UIGradient", vignetteFrame)
vgGrad.Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0))
vgGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.22),
    NumberSequenceKeypoint.new(0.42, 1),
    NumberSequenceKeypoint.new(1, 0.22),
})
vgGrad.Rotation = 90

zoomBlurFrame = Instance.new("Frame", sg)
zoomBlurFrame.Name = "zoomblur"
zoomBlurFrame.Size = UDim2.new(1,0,1,0)
zoomBlurFrame.BackgroundTransparency = 1
zoomBlurFrame.ZIndex = 17
zoomBlurFrame.BackgroundColor3 = Color3.new(0,0,0)

colorSplitFrame1 = Instance.new("Frame", sg)
colorSplitFrame1.Size = UDim2.new(1,0,1,0); colorSplitFrame1.BackgroundTransparency = 1; colorSplitFrame1.ZIndex = 21
colorSplitFrame1.BackgroundColor3 = Color3.fromRGB(255,0,100)
colorSplitFrame2 = Instance.new("Frame", sg)
colorSplitFrame2.Size = UDim2.new(1,0,1,0); colorSplitFrame2.BackgroundTransparency = 1; colorSplitFrame2.ZIndex = 21
colorSplitFrame2.BackgroundColor3 = Color3.fromRGB(0,100,255)

scanlines = Instance.new("Frame", sg)
scanlines.Name = "scanlines"
scanlines.Size = UDim2.new(1,0,1,0)
scanlines.BackgroundTransparency = 1
scanlines.ZIndex = 19
local slGrad = Instance.new("UIGradient", scanlines)
slGrad.Rotation = 0
slGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.92),
    NumberSequenceKeypoint.new(0.02, 1),
    NumberSequenceKeypoint.new(0.04, 0.92),
    NumberSequenceKeypoint.new(1, 0.92),
})
slGrad.Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0))

local camAngle  = math.pi
local camDist   = 22
local camHeight = 9
local camMode   = "orbit"
local camFOV    = 70
local camTarget = "singer"
local camShakeX = 0
local camShakeY = 0
local camShakeDecay = 0

Camera.CameraType  = Enum.CameraType.Scriptable
Camera.FieldOfView = 70

local desiredCamCF = CFrame.new(0,0,0)

local function tweenFOV(fov, t)
    camFOV = fov
    TweenService:Create(Camera, TweenInfo.new(t or 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        FieldOfView = fov
    }):Play()
end

local function getTargetPos()
    if camTarget == "player" and playerCloneHRP and playerCloneHRP.Parent then
        return playerCloneHRP.Position
    end
    if singerHRP and singerHRP.Parent then return singerHRP.Position end
    return Vector3.new(0,0,0)
end

local function getSingerBodyCenter()
    if singerHead and singerHead.Parent then return singerHead.Position + Vector3.new(0, 0, 0) end
    if singerHRP and singerHRP.Parent then return singerHRP.Position + Vector3.new(0, 1.5, 0) end
    return Vector3.new(0,1.5,0)
end

local function getPlayerBodyCenter()
    if playerCloneHRP and playerCloneHRP.Parent then return playerCloneHRP.Position + Vector3.new(0, 4, 0) end
    return Vector3.new(0,4,0)
end

local function getTargetCamCF()
    local target     = getTargetPos()
    local bodyCenter = getSingerBodyCenter()
    local headOff    = Vector3.new(0, camHeight, 0)

    if camMode == "orbit" then
        local camPos = target + headOff + Vector3.new(math.cos(camAngle)*camDist, camHeight*0.15, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, bodyCenter)
    elseif camMode == "close" then
        local camPos = bodyCenter + Vector3.new(math.cos(camAngle)*camDist, 0, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, bodyCenter)
    elseif camMode == "face" then
        local facePos = (singerHead and singerHead.Parent) and singerHead.Position or (singerHRP and (singerHRP.Position + Vector3.new(0, 1.5, 0)) or bodyCenter)
        local focusPoint = facePos + Vector3.new(0, 0, 0)
        local camPos = focusPoint + Vector3.new(math.cos(camAngle)*camDist, 0.2, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, focusPoint)
    elseif camMode == "playerface" then
        local playerHead = playerClone and playerClone:FindFirstChild("Head")
        local facePos = (playerHead and playerHead.Parent) and playerHead.Position or getPlayerBodyCenter()
        local focusPoint = facePos + Vector3.new(0, 0, 0)
        local camPos = focusPoint + Vector3.new(math.cos(camAngle)*5, 0.2, math.sin(camAngle)*5)
        return CFrame.lookAt(camPos, focusPoint)
    elseif camMode == "top" then
        return CFrame.lookAt(target + Vector3.new(0, 44, 0.01), bodyCenter)
    elseif camMode == "dramatic" then
        local camPos = bodyCenter + Vector3.new(math.cos(camAngle)*camDist, -5, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, bodyCenter + Vector3.new(0, 7, 0))
    elseif camMode == "worm" then
        local camPos = target + Vector3.new(math.cos(camAngle)*camDist, -7, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, bodyCenter)
    elseif camMode == "fnf" then
        local sp = singerHRP and singerHRP.Position or Vector3.new(0,0,0)
        local pp = playerCloneHRP and playerCloneHRP.Position or Vector3.new(0,0,12)
        local mid = (sp + pp) / 2
        return CFrame.lookAt(mid + Vector3.new(0, 12, 36), mid + Vector3.new(0, 6, 0))
    elseif camMode == "lowangle" then
        local camPos = target + Vector3.new(math.cos(camAngle)*camDist, -12, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, target + Vector3.new(0, 3, 0))
    elseif camMode == "dutch" then
        local base = CFrame.lookAt(
            target + headOff + Vector3.new(math.cos(camAngle)*camDist, camHeight*0.1, math.sin(camAngle)*camDist),
            bodyCenter
        )
        return base * CFrame.Angles(0, 0, math.rad(18))
    elseif camMode == "spin360" then
        local spinAngle = shared.G.elapsed * 1.8
        local camPos = bodyCenter + Vector3.new(math.cos(spinAngle)*camDist, camHeight*0.3, math.sin(spinAngle)*camDist)
        return CFrame.lookAt(camPos, bodyCenter)
    elseif camMode == "cinematic" then
        local slideX = math.sin(shared.G.elapsed * 0.22) * 8
        local camPos = bodyCenter + Vector3.new(slideX + math.cos(camAngle)*camDist, camHeight*0.6, math.sin(camAngle)*camDist)
        return CFrame.lookAt(camPos, bodyCenter + Vector3.new(0, 1.5, 0))
    elseif camMode == "shoulderL" then
        local facePos2 = (singerHead and singerHead.Parent) and singerHead.Position or bodyCenter
        local rightDir = singerHRP and singerHRP.CFrame.RightVector or Vector3.new(1,0,0)
        local camPos2 = facePos2 - rightDir * 2.2 + Vector3.new(0, 0.5, 0) + (singerHRP and singerHRP.CFrame.LookVector * (-camDist * 0.6) or Vector3.new(0,0,-8))
        return CFrame.lookAt(camPos2, facePos2 + Vector3.new(0, -0.2, 0))
    elseif camMode == "shoulderR" then
        local facePos3 = (singerHead and singerHead.Parent) and singerHead.Position or bodyCenter
        local rightDir2 = singerHRP and singerHRP.CFrame.RightVector or Vector3.new(1,0,0)
        local camPos3 = facePos3 + rightDir2 * 2.2 + Vector3.new(0, 0.5, 0) + (singerHRP and singerHRP.CFrame.LookVector * (-camDist * 0.6) or Vector3.new(0,0,-8))
        return CFrame.lookAt(camPos3, facePos3 + Vector3.new(0, -0.2, 0))
    elseif camMode == "birdseye" then
        local camPos4 = target + Vector3.new(math.sin(shared.G.elapsed*0.08)*10, 65, math.cos(shared.G.elapsed*0.08)*10)
        return CFrame.lookAt(camPos4, bodyCenter)
    end
    return Camera.CFrame
end

local function addCameraShake(intensity, decay)
    camShakeX = math.random(-100,100)/100 * intensity
    camShakeY = math.random(-100,100)/100 * intensity
    camShakeDecay = decay or 0.85
end

local function flash(r, g, b, dur)
    flashFrame.BackgroundColor3 = Color3.fromRGB(r,g,b)
    flashFrame.BackgroundTransparency = 0.04
    TweenService:Create(flashFrame, TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quint), {
        BackgroundTransparency = 1
    }):Play()
end

local glitching = false
local function glitch(times, strength)
    if glitching then return end
    glitching = true; strength = strength or 1
    local orig = Camera.CFrame
    task.spawn(function()
        for _ = 1, (times or 5) do
            Camera.CFrame = orig
                * CFrame.new(math.random(-10,10)*0.055*strength, math.random(-5,5)*0.035*strength, 0)
                * CFrame.Angles(0, 0, math.rad(math.random(-5,5)*strength))
            task.wait(0.035)
        end
        Camera.CFrame = orig; glitching = false
    end)
end

local function lightningFlash()
    flash(255,255,255, 0.06)
    task.delay(0.08,  function() flash(200,70,255, 0.1) end)
    task.delay(0.20,  function() flash(255,255,255, 0.05) end)
    glitch(5, 1.8)
    doChromaticAberration(0.2, 0.5)
    addCameraShake(0.4, 0.8)
end

local function colorShift(r, g, b, t)
    TweenService:Create(colorCorrection, TweenInfo.new(t or 0.35, Enum.EasingStyle.Quint), {
        TintColor = Color3.fromRGB(r,g,b)
    }):Play()
end

local function skyColor(r, g, b)
    TweenService:Create(Lighting, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {
        Ambient        = Color3.fromRGB(r//3, g//3, b//3),
        OutdoorAmbient = Color3.fromRGB(r//2, g//2, b//2),
        FogColor       = Color3.fromRGB(r//2, g//2, b//2),
        FogEnd         = 600 + math.random(0,300),
        Brightness     = 1.6 + math.random()*0.7,
    }):Play()
    TweenService:Create(bloom, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
        Intensity = 1.0 + math.random()*1.5, Size = 22 + math.random()*22,
    }):Play()
end

local function punchCam(scale)
    scale = scale or 1
    local base = camFOV
    tweenFOV(base - 9*scale, 0.08)
    task.delay(0.12, function() tweenFOV(base + 14*scale, 0.2) end)
    task.delay(0.38, function() tweenFOV(base, 0.28) end)
    addCameraShake(0.25 * scale, 0.82)
end

local function zoomToFace(who, fov, duration, holdTime)
    local prevMode = camMode; local prevFOV = camFOV; local prevTarget = camTarget
    camTarget = who or "singer"
    camMode   = (who == "player") and "playerface" or "face"
    tweenFOV(fov or 35, duration or 0.5)
    if holdTime then
        task.delay(holdTime, function()
            camMode = prevMode; camTarget = prevTarget
            tweenFOV(prevFOV, duration or 0.5)
        end)
    end
end

local singerBaseY = singerHRP and singerHRP.Position.Y or 0
local isFloating = false

local function scaleSinger(targetScale, duration)
    if not singerHum then return end
    local names = {"BodyHeightScale","BodyWidthScale","BodyDepthScale","HeadScale"}
    for _, n in ipairs(names) do
        local obj = singerHum:FindFirstChild(n)
        if obj then
            TweenService:Create(obj, TweenInfo.new(duration or 0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Value = targetScale}):Play()
        end
    end
end

local function floatSinger(height, duration)
    if not singerHRP then return end
    isFloating = true
    local targetPos = singerBasePos and singerBasePos.Position + Vector3.new(0, height, 0) or singerHRP.Position + Vector3.new(0, height, 0)
    local targetCF  = CFrame.new(targetPos) * (singerBasePos and singerBasePos.Rotation or CFrame.identity)
    TweenService:Create(singerHRP, TweenInfo.new(duration * 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        CFrame = targetCF
    }):Play()
    scaleSinger(4.5, 0.35)
    burstParticles(singerParticles, 22)
    shockwave(Color3.fromHSV(math.random(), 1, 1))
    task.delay(duration * 0.5, function() scaleSinger(3.5, 0.25) end)
    task.delay(duration, function()
        isFloating = false; scaleSinger(3, 0.4)
        if singerHRP and singerHRP.Parent and singerBasePos then
            TweenService:Create(singerHRP, TweenInfo.new(0.65, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
                CFrame = singerBasePos
            }):Play()
            task.delay(0.1, function()
                shockwave(Color3.fromRGB(255,200,80))
                burstParticles(singerParticles, 16)
            end)
        end
    end)
end

local function slamDown()
    if not singerHRP then return end
    scaleSinger(5.5, 0.15)
    task.delay(0.15, function()
        if singerBasePos then
            TweenService:Create(singerHRP, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                CFrame = singerBasePos
            }):Play()
        end
        task.delay(0.25, function()
            scaleSinger(3, 0.3)
            flash(255,180,80, 0.3)
            glitch(9, 2.2)
            shockwave(Color3.fromRGB(255,200,80))
            spawnExplosiveCubes(10, singerHRP and singerHRP.Position)
            burstParticles(singerParticles, 35)
            punchCam(1.8)
            spawnLaserRing(0); task.delay(0.1, function() spawnLaserRing(5) end)
            doChromaticAberration(0.3, 0.7)
            doZoomBlurHit(0.18)
            doColorSplit(0.25, 0.022)
        end)
    end)
end

local function doSuperBurst()
    local pos = singerHRP and singerHRP.Position or Vector3.new(0,10,0)
    spawnExplosiveCubes(25, pos)
    shockwave(Color3.fromRGB(255,60,200))
    task.delay(0.15, function() shockwave(Color3.fromRGB(60,200,255)) end)
    task.delay(0.30, function() shockwave(Color3.fromRGB(255,255,60)) end)
    burstParticles(singerParticles, 70)
    burstParticles(playerParticles, 35)
    lightningFlash()
    punchCam(2.2)
    spawnLaserRing(4); task.delay(0.18, function() spawnLaserRing(9) end); task.delay(0.36, function() spawnLaserRing(14) end)
    spawnConfetti(35, pos)
    scaleSinger(5.5, 0.18); task.delay(0.5, function() scaleSinger(3, 0.4) end)
    spawnStarburstRing()
    doChromaticAberration(0.45, 0.9)
    addCameraShake(0.6, 0.75)
    doZoomBlurHit(0.25)
    doColorSplit(0.35, 0.03)
end

shared.G.lyricEffectConn = nil
shared.G.lyricBeatCount = 0

local function pulseLyricBeat(bpm)
    if shared.G.lyricEffectConn then shared.G.lyricEffectConn:Disconnect() end
    local interval = 60 / (bpm or 128)
    local lastBeat = tick()
    shared.G.lyricEffectConn = RunService.RenderStepped:Connect(function()
        if tick() - lastBeat >= interval then
            lastBeat = tick(); shared.G.lyricBeatCount = shared.G.lyricBeatCount + 1
            local hue = (shared.G.lyricBeatCount * 0.07) % 1
            lyricStroke.Color = Color3.fromHSV(hue, 1, 1)
            TweenService:Create(lyricOuter, TweenInfo.new(0.07, Enum.EasingStyle.Quint), {
                Size = UDim2.new(0.67, 0, 0, 78)
            }):Play()
            task.delay(0.13, function()
                TweenService:Create(lyricOuter, TweenInfo.new(0.16, Enum.EasingStyle.Quint), {
                    Size = UDim2.new(0.65, 0, 0, 72)
                }):Play()
            end)
        end
    end)
end
pulseLyricBeat(128)

local lyricWorldFolder = Instance.new("Folder", mainFolder)
lyricWorldFolder.Name = "lyricworld"

local function spawnWorldLyric(text)
    if not singerHRP or text == "" then return end
    task.spawn(function()
        local board = Instance.new("Part", lyricWorldFolder)
        board.Size = Vector3.new(0.1, 4, 14); board.Anchored = true; board.CanCollide = false; board.CastShadow = false
        board.Transparency = 0.35; board.Material = Enum.Material.Neon
        board.Color = Color3.fromHSV(math.random(), 1, 1)
        local angle = math.random() * math.pi * 2
        local dist  = math.random(20, 40)
        local height = math.random(10, 22)
        board.CFrame = CFrame.new(singerHRP.Position + Vector3.new(math.cos(angle)*dist, height, math.sin(angle)*dist))
            * CFrame.Angles(0, angle + math.pi/2, 0)
        local sg2 = Instance.new("SurfaceGui", board)
        sg2.Face = Enum.NormalId.Front; sg2.AlwaysOnTop = false
        sg2.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg2.PixelsPerStud = 50
        local lbl = Instance.new("TextLabel", sg2)
        lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.new(1,1,1); lbl.TextStrokeTransparency = 0
        lbl.TextStrokeColor3 = Color3.fromHSV(math.random(), 1, 1)
        lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true; lbl.Text = text
        TweenService:Create(board, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = Vector3.new(0.1, 4.5, 15)
        }):Play()
        task.delay(3.5, function()
            TweenService:Create(board, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
            task.wait(0.7); pcall(function() board:Destroy() end)
        end)
    end)
end

local function showLyric(entry)
    lyricLabel.Text = entry.jp; subLabel.Text = entry.en
    if singerHead and singerHead.Parent and entry.jp ~= "" then
        pcall(function() ChatService:Chat(singerHead, entry.jp) end)
    end
    local worldText = entry.jp ~= "" and entry.jp or entry.en
    if worldText ~= "" then spawnWorldLyric(worldText) end
    if math.random(1, 3) == 1 then spawnConfetti(12, singerHRP and singerHRP.Position) end

    local hue = math.random()
    lyricLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
    lyricLabel.TextSize = 36; lyricLabel.Rotation = math.random(-4,4)

    TweenService:Create(lyricLabel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextSize = 28, TextColor3 = Color3.new(1,1,1), Rotation = 0,
    }):Play()

    subLabel.TextColor3 = Color3.fromHSV((hue+0.5)%1, 0.7, 1)
    subLabel.TextSize = 20
    TweenService:Create(subLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
        TextSize = 16, TextColor3 = Color3.fromRGB(215,175,255),
    }):Play()

    TweenService:Create(lyricOuter, TweenInfo.new(0.06), {
        BackgroundTransparency = 0.04, Size = UDim2.new(0.68,0,0,80),
    }):Play()
    task.delay(0.4, function()
        TweenService:Create(lyricOuter, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
            BackgroundTransparency = 0.4, Size = UDim2.new(0.65,0,0,72),
        }):Play()
    end)

    TweenService:Create(lyricStroke, TweenInfo.new(0.05), {
        Color = Color3.fromHSV(hue,1,1), Thickness = 4,
    }):Play()
    task.delay(0.45, function()
        TweenService:Create(lyricStroke, TweenInfo.new(0.35), {
            Color = Color3.fromRGB(210,80,255), Thickness = 2.8,
        }):Play()
    end)

    TweenService:Create(blur, TweenInfo.new(0.05), {Size = 5}):Play()
    task.delay(0.12, function() TweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = 0}):Play() end)
    doChromaticAberration(0.1, 0.25)
end

shared.G.lastLyricTime = 0
shared.G.idleAnimPlaying = false

local function checkIdleAnim(elapsed)
    if elapsed - shared.G.lastLyricTime > 4 and not shared.G.idleAnimPlaying then
        shared.G.idleAnimPlaying = true
        local rng = math.random(1, 10)
        if rng == 1 then
            floatSinger(16, 1.5); singerCheer(); shockwave(Color3.fromRGB(100,200,255)); burstParticles(singerParticles, 18)
        elseif rng == 2 then
            singerDance(); spawnExplosiveCubes(8, singerHRP and singerHRP.Position)
        elseif rng == 3 then
            singerPoint(); zoomToFace("player", 40, 0.4, 2.5)
        elseif rng == 4 then
            singerLaugh(); glitch(6, 1.2)
        elseif rng == 5 then
            singerWave(); shockwave(Color3.fromRGB(255,200,80))
        elseif rng == 6 then
            singerRobot(); spawnLaserRing(3); task.delay(0.18, function() spawnLaserRing(8) end)
        elseif rng == 7 then
            singerSalute(); burstParticles(singerParticles, 22)
        elseif rng == 8 then
            singerShrug(); spawnConfetti(18, singerHRP and singerHRP.Position)
        elseif rng == 9 then
            singerSpin(); scaleSinger(4.5, 0.2); task.delay(0.5, function() scaleSinger(3, 0.3) end)
            shockwave(Color3.fromHSV(math.random(), 1, 1)); spawnStarburstRing()
        else
            spawnDNAHelix(3.5); spawnGeometricRing(14, 8, 10, 0.8, 3)
        end
        task.delay(4, function() shared.G.idleAnimPlaying = false end)
    end
end

local choreo = {
    {0, function()
        singerDance(); tweenFOV(65, 1.5); colorShift(200,140,255); camMode = "orbit"; camDist = 22
    end},
    {9.22, function()
        zoomToFace("singer", 38, 0.6, 2.5); colorShift(255,140,255); skyColor(60,0,80)
        singerDance(); punchCam(); spawnLaserRing(5); spawnPillarRing(8, 14, 10)
    end},
    {13.15, function()
        floatSinger(20, 2); camMode = "dramatic"; camDist = 18; tweenFOV(60, 0.5)
        lightningFlash(); singerCheer(); shockwave(Color3.fromRGB(200,80,255))
        burstParticles(singerParticles, 28); spawnLaserRing(7)
        doChromaticAberration(0.35, 0.6)
    end},
    {17.75, function()
        glitch(7, 1.6); flash(255,80,200, 0.22); camMode = "orbit"; camDist = 28; tweenFOV(72, 0.4)
        colorShift(100,200,255); skyColor(0,20,80); spawnExplosiveCubes(14, singerHRP and singerHRP.Position)
        singerWave(); spawnLaserRing(4); task.delay(0.2, function() spawnLaserRing(9) end)
        spawnGeometricRing(12, 6, 12, 1.2, 2.5)
    end},
    {21.07, function()
        zoomToFace("singer", 34, 0.5, 3); colorShift(200,255,140); skyColor(0,60,20)
        singerPoint(); spawnLaserRing(2); spawnSpiralRings(12)
    end},
    {24.16, function()
        camMode = "orbit"; camAngle = camAngle + math.pi * 0.7; camDist = 20; tweenFOV(65, 0.3)
        flash(255,255,100, 0.15); punchCam(1.3); shockwave(Color3.fromRGB(255,255,80))
        singerDance(); spawnLaserRing(5); addCameraShake(0.3, 0.8)
    end},
    {28.45, function()
        lightningFlash(); colorShift(255,255,200); skyColor(80,60,0); doSuperBurst()
        camMode = "worm"; camDist = 22; tweenFOV(76, 0.4)
    end},
    {33.33, function()
        zoomToFace("singer", 30, 0.5, 2.5); colorShift(255,100,80); skyColor(80,10,0)
        singerCheer(); spawnDNAHelix(3)
    end},
    {36.63, function()
        slamDown(); camMode = "orbit"; camDist = 32; tweenFOV(70, 0.5)
        colorShift(80,200,255); skyColor(0,40,80); spawnPillarRing(10, 16, 14)
    end},
    {40.0, function()
        zoomToFace("player", 36, 0.5, 2.5); flash(255,200,255, 0.2); singerLaugh()
        growPlayerGiant()
    end},
    {45.0, function()
        camMode = "face"; camDist = 6; tweenFOV(55, 0.4); colorShift(255,180,100)
        spawnExplosiveCubes(12, singerHRP and singerHRP.Position)
        shockwave(Color3.fromRGB(255,180,100)); singerDance()
    end},
    {50.0, function()
        camMode = "orbit"; camDist = 35; tweenFOV(80, 0.5)
        colorShift(140,80,255); skyColor(40,0,80); doSuperBurst(); spawnGeometricRing(18, 10, 16, 0.6, 3)
    end},
    {55.18, function()
        glitch(11, 2.2); flash(180,50,255, 0.28); camMode = "dramatic"; camDist = 20; tweenFOV(65, 0.4)
        colorShift(200,80,255); skyColor(40,0,80); singerDance(); burstParticles(singerParticles, 45)
        doChromaticAberration(0.4, 0.8); spawnSpiralRings(16)
    end},
    {58.45, function()
        floatSinger(40, 3); camMode = "birdseye"; camDist = 45; tweenFOV(88, 0.6)
        colorShift(255,255,255); skyColor(60,60,80); spawnExplosiveCubes(22, singerHRP and singerHRP.Position)
        shockwave(Color3.fromRGB(255,255,255)); spawnStarburstRing()
        doColorSplit(0.4, 0.025)
    end},
    {1*60+5.73, function()
        zoomToFace("singer", 32, 0.5, 3); colorShift(255,140,200); skyColor(60,0,40); singerCheer()
        spawnPillarRing(12, 18, 16); camMode = "dutch"
    end},
    {1*60+14.07, function()
        glitch(7, 1.6); floatSinger(30, 2.5); camMode = "spin360"; tweenFOV(92, 0.5)
        colorShift(80,255,200); skyColor(0,60,40); spawnExplosiveCubes(18, singerHRP and singerHRP.Position)
        spawnDNAHelix(3.5); doColorSplit(0.3, 0.02)
    end},
    {1*60+18.16, function()
        camMode = "orbit"; camDist = 24; tweenFOV(70, 0.4); flash(200,255,80, 0.22)
        colorShift(200,255,140); skyColor(20,60,0); punchCam(1.5); singerPoint()
        spawnGeometricRing(10, 4, 8, 1.5, 2)
    end},
    {1*60+25.25, function()
        glitch(6, 1.3); camMode = "dramatic"; camDist = 16; tweenFOV(62, 0.4)
        colorShift(255,170,80); skyColor(80,40,0); shockwave(Color3.fromRGB(255,140,50))
        burstParticles(singerParticles, 35); singerLaugh(); spawnSpiralRings(18)
    end},
    {1*60+32.90, function()
        lightningFlash(); slamDown(); zoomToFace("singer", 28, 0.4, 2.5)
        colorShift(255,80,80); skyColor(80,0,0); doSuperBurst(); singerSalute()
        camMode = "lowangle"
    end},
    {2*60+11.68, function()
        camMode = "orbit"; camDist = 18; tweenFOV(68, 0.4); flash(255,80,200, 0.32)
        colorShift(255,100,255); skyColor(60,0,60); singerDance()
        spawnLaserRing(5); spawnPillarRing(8, 12, 12)
    end},
    {2*60+20.0, function()
        zoomToFace("player", 34, 0.5, 2.5); flash(200,140,255, 0.22)
        burstParticles(playerParticles, 30); growPlayerGiant()
    end},
    {2*60+29.62, function()
        floatSinger(50, 3); glitch(13, 2.8); camMode = "cinematic"; tweenFOV(95, 0.6)
        colorShift(140,200,255); skyColor(0,20,60); spawnExplosiveCubes(30, singerHRP and singerHRP.Position)
        shockwave(Color3.fromRGB(140,200,255)); burstParticles(singerParticles, 70)
        task.delay(0.1, function() spawnLaserRing(6) end)
        task.delay(0.3, function() spawnLaserRing(12) end)
        spawnDNAHelix(4); doChromaticAberration(0.6, 1.0); addCameraShake(0.8, 0.7)
        doColorSplit(0.5, 0.03); doZoomBlurHit(0.2)
    end},
    {2*60+37.95, function()
        lightningFlash(); flash(255,255,255, 0.4); camMode = "orbit"; camDist = 40; tweenFOV(85, 0.5)
        colorShift(255,255,255); skyColor(80,80,80); doSuperBurst(); singerCheer()
        spawnLaserRing(10); spawnGeometricRing(20, 12, 18, 0.5, 3)
    end},
    {2*60+42.70, function()
        zoomToFace("singer", 30, 0.5, 3); colorShift(200,100,255); skyColor(40,0,60)
        singerRobot(); spawnSpiralRings(20); camMode = "shoulderL"
        doColorSplit(0.2, 0.018)
    end},
    {2*60+48.36, function()
        camMode = "orbit"; camDist = 50; tweenFOV(90, 0.5); glitch(9, 2.2)
        colorShift(80,80,255); skyColor(0,0,80); doSuperBurst()
        spawnExplosiveCubes(35, singerHRP and singerHRP.Position); singerFlip()
        task.delay(0.1, function() spawnLaserRing(5) end)
        task.delay(0.25, function() spawnLaserRing(11) end)
        task.delay(0.4, function() spawnLaserRing(17) end)
        spawnStarburstRing(); doChromaticAberration(0.5, 1.0)
        addCameraShake(1.0, 0.7)
    end},
}

shared.G.choreoIdx = 1
shared.G.lyricIdx = 1

local sound     = PlayGitSound(AUDIO_URL, "ArigatoTokyo", 2, Camera)
shared.G.startTick = tick()
local started   = sound ~= nil

if not started then
    warn("[ArigatoShow] Falha ao carregar audio, continuando sem som")
    started = true
end

shared.G.pentaAngle = 0
shared.G.elapsed = 0
local conn

conn = RunService.RenderStepped:Connect(function(dt)
    if shared.G.finished then return end

    shared.G.elapsed = (sound and sound.Parent and pcall(function() return sound.IsPlaying end) and sound.IsPlaying)
        and sound.TimePosition
        or (tick() - shared.G.startTick)

    shared.G.pentaAngle = shared.G.pentaAngle + dt * 0.9
    updatePentagon(shared.G.pentaAngle)
    updateOrbit(shared.G.elapsed)
    updateStars(shared.G.elapsed)
    updateNebula(shared.G.elapsed)
    updateShowLights(shared.G.elapsed)
    updateGyroRings(shared.G.elapsed)

    local nowTick = tick()
    local dynamicBeatInterval = 60 / shared.G.BPM
    if nowTick - shared.G.lastBeatTick >= dynamicBeatInterval then
        shared.G.lastBeatTick = nowTick
        shared.G.beatCount = shared.G.beatCount + 1
        shared.G.beatStrength = 0.7 + math.abs(math.sin(shared.G.elapsed * 0.3)) * 0.6
        if singerHRP then
            local hue = (shared.G.beatCount * 0.13) % 1
            spawnBeatRing(singerHRP.Position, Color3.fromHSV(hue, 1, 1), shared.G.beatStrength)
        end
        if shared.G.beatCount % 4 == 0 then
            punchCam(0.4 + shared.G.beatStrength * 0.3)
            doColorSplit(0.15, 0.008 + shared.G.beatStrength * 0.012)
        end
        if shared.G.beatCount % 8 == 0 then
            doZoomBlurHit(0.1)
            if singerHRP then
                spawnFloatingTriangle(singerHRP.Position + Vector3.new(math.random(-5,5), 3, math.random(-5,5)), math.random(3,7), 2)
            end
        end
        if shared.G.beatCount % 16 == 0 then
            shared.G.BPM = 120 + math.random(0, 20)
        end
        burstParticles(singerParticles, math.floor(3 + shared.G.beatStrength * 5))
    end

    updateSoundWaves(shared.G.elapsed, shared.G.beatStrength)
    updateStarShape(shared.G.elapsed)
    updateHexShape(shared.G.elapsed)
    updatePortal(shared.G.elapsed)

    if stagePlatform and singerHRP then
        local hue = (shared.G.elapsed * 0.07) % 1
        stagePlatform.Color = Color3.fromHSV(hue, 1, 1)
        local pulse = 0.22 + math.abs(math.sin(shared.G.elapsed * 2.8)) * 0.18
        stagePlatform.Transparency = pulse
    end

    if playerCloneHRP and playerHRP then
        playerCloneHRP.CFrame = playerHRP.CFrame
    end

    camAngle = camAngle + dt * 0.14

    if camShakeDecay > 0 then
        camShakeX = camShakeX * camShakeDecay
        camShakeY = camShakeY * camShakeDecay
        if math.abs(camShakeX) < 0.001 then camShakeX = 0; camShakeY = 0; camShakeDecay = 0 end
    end

    desiredCamCF = desiredCamCF:Lerp(getTargetCamCF(), 0.1)
    local shakeCF = CFrame.new(camShakeX, camShakeY, 0)
        * CFrame.Angles(0, 0, math.rad(camShakeX * 3))
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = desiredCamCF * shakeCF
    Camera.FieldOfView = camFOV

    if sound and sound.Parent then
        pcall(function() sound.RollOffMaxDistance = 9999 end)
    end

    while shared.G.lyricIdx <= #lyrics and lyrics[shared.G.lyricIdx].time <= shared.G.elapsed do
        shared.G.lastLyricTime = shared.G.elapsed; shared.G.idleAnimPlaying = false
        showLyric(lyrics[shared.G.lyricIdx]); shared.G.lyricIdx = shared.G.lyricIdx + 1
    end

    while shared.G.choreoIdx <= #choreo and choreo[shared.G.choreoIdx][1] <= shared.G.elapsed do
        task.spawn(choreo[shared.G.choreoIdx][2]); shared.G.choreoIdx = shared.G.choreoIdx + 1
    end

    checkIdleAnim(shared.G.elapsed)

    if singerHRP and singerHRP.Parent and singerBasePos and not isFloating then
        local bob = CFrame.new(0, math.sin(shared.G.elapsed*2)*0.025, 0)
            * CFrame.Angles(0, math.sin(shared.G.elapsed*0.5)*0.012, math.sin(shared.G.elapsed*2.5)*0.009)
        singerHRP.CFrame = singerBasePos * bob
    end

    local lightHue = (shared.G.elapsed * 0.14) % 1
    spotLight.Color = Color3.fromHSV(lightHue, 1, 1)
    pointLight.Color = Color3.fromHSV((lightHue + 0.33) % 1, 1, 1)
    singerSpotDown.Color = Color3.fromHSV((lightHue + 0.66) % 1, 1, 1)

    if singerNameTag then
        local nameLabel2 = singerNameTag:FindFirstChildOfClass("TextLabel")
        if nameLabel2 then nameLabel2.TextColor3 = Color3.fromHSV((shared.G.elapsed * 0.22) % 1, 1, 1) end
    end

    local soundDone = false
    if sound and sound.Parent then
        pcall(function() soundDone = not sound.IsPlaying and shared.G.elapsed > 5 end)
    else
        soundDone = tick() - shared.G.startTick > 175
    end

    if soundDone then
        shared.G.finished = true
        if conn then conn:Disconnect() end

        flash(255,255,255, 2); doSuperBurst()
        task.wait(0.8)

        TweenService:Create(cinemaTop, TweenInfo.new(1.5, Enum.EasingStyle.Quint), {Position = UDim2.new(-0.002,0,0,-(BAR_H+4))}):Play()
        TweenService:Create(cinemaBot, TweenInfo.new(1.5, Enum.EasingStyle.Quint), {Position = UDim2.new(-0.002,0,1,0)}):Play()
        TweenService:Create(lyricOuter, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
        TweenService:Create(colorCorrection, TweenInfo.new(2.5), {
            TintColor = Color3.new(1,1,1), Saturation = 0, Brightness = 0
        }):Play()
        TweenService:Create(Lighting, TweenInfo.new(2.5), {
            Ambient = origAmbient, OutdoorAmbient = origOutdoor,
            Brightness = origBrightness, ClockTime = origClockTime,
            FogEnd = origFogEnd, FogColor = origFogColor,
        }):Play()
        tweenFOV(origFOV, 2)
        task.wait(2)

        if shared.G.lyricEffectConn then shared.G.lyricEffectConn:Disconnect() end
        pcall(function() sg:Destroy() end)
        pcall(function() mainFolder:Destroy() end)
        pcall(function() singer:Destroy() end)
        pcall(function() playerClone:Destroy() end)
        pcall(function() sky:Destroy() end)
        pcall(function() bloom:Destroy() end)
        pcall(function() colorCorrection:Destroy() end)
        pcall(function() colorCorrectionR:Destroy() end)
        pcall(function() colorCorrectionB:Destroy() end)
        pcall(function() depthOfField:Destroy() end)
        pcall(function() sunRays:Destroy() end)
        pcall(function() blur:Destroy() end)
        pcall(function() waveFolder:Destroy() end)
        pcall(function() starShapeFolder:Destroy() end)
        pcall(function() hexagonShapeFolder:Destroy() end)
        pcall(function() portalFolder:Destroy() end)
        pcall(function() shockwaveRingFolder:Destroy() end)
        pcall(function() triangleFolder:Destroy() end)
        pcall(function() zoomBlurFrame:Destroy() end)
        pcall(function() colorSplitFrame1:Destroy() end)
        pcall(function() colorSplitFrame2:Destroy() end)
        pcall(function() scanlines:Destroy() end)

        for part, origT in pairs(shared.G.hiddenParts) do
            pcall(function() part.Transparency = origT end)
        end
        for part, origT in pairs(shared.G.origPlayerTransp) do
            pcall(function() part.Transparency = origT end)
        end

        Camera.CameraType  = Enum.CameraType.Custom
        Camera.FieldOfView = origFOV

        if playerHum then playerHum.WalkSpeed = 16; playerHum.JumpHeight = 7.2 end
        if playerHRP then playerHRP.Anchored = false end

        pcall(function()
            for _, t in ipairs({
                Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Health,
                Enum.CoreGuiType.Backpack,   Enum.CoreGuiType.Chat,
            }) do StarterGui:SetCoreGuiEnabled(t, true) end
        end)
    end
end)
