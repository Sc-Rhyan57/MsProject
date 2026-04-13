local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ChatService  = game:GetService("Chat")
local Lighting     = game:GetService("Lighting")
local StarterGui   = game:GetService("StarterGui")
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
Lighting.Brightness     = 1.8
Lighting.Ambient        = Color3.fromRGB(80, 40, 100)
Lighting.OutdoorAmbient = Color3.fromRGB(60, 30, 80)
Lighting.FogEnd         = 800
Lighting.FogColor       = Color3.fromRGB(40, 0, 80)

local sky = Instance.new("Sky", Lighting)
sky.SkyboxBk = "rbxassetid://159454282"
sky.SkyboxDn = "rbxassetid://159454282"
sky.SkyboxFt = "rbxassetid://159454282"
sky.SkyboxLf = "rbxassetid://159454282"
sky.SkyboxRt = "rbxassetid://159454282"
sky.SkyboxUp = "rbxassetid://159454282"
sky.StarCount = 3000
sky.CelestialBodiesShown = false

local colorCorrection = Instance.new("ColorCorrectionEffect", Lighting)
colorCorrection.Brightness  = 0
colorCorrection.Contrast    = 0.15
colorCorrection.Saturation  = 0.4
colorCorrection.TintColor   = Color3.fromRGB(200, 150, 255)

local bloom = Instance.new("BloomEffect", Lighting)
bloom.Intensity = 1.2
bloom.Size      = 28
bloom.Threshold = 0.9

local sunRays = Instance.new("SunRaysEffect", Lighting)
sunRays.Intensity = 0.25
sunRays.Spread    = 0.5

local blur = Instance.new("BlurEffect", Lighting)
blur.Size    = 0
blur.Enabled = true

local depthOfField = Instance.new("DepthOfFieldEffect", Lighting)
depthOfField.FarIntensity  = 0
depthOfField.NearIntensity = 0
depthOfField.FocusDistance = 10
depthOfField.InFocusRadius = 25
depthOfField.Enabled = true

local singer = Players:CreateHumanoidModelFromUserId(Players:GetUserIdFromNameAsync(LocalPlayer.Name))
singer.Name   = "ArigatoSinger"
singer.Parent = workspace

local singerHum  = singer:FindFirstChildOfClass("Humanoid")
local singerHRP  = singer:FindFirstChild("HumanoidRootPart")
local singerHead = singer:FindFirstChild("Head")

if singerHum then
    singerHum.WalkSpeed  = 0
    singerHum.JumpHeight = 0
    singerHum.NameDisplayDistance    = 0
    singerHum.HealthDisplayDistance  = 0
end

local singerBasePos
if singerHRP and playerHRP then
    local front = playerHRP.CFrame * CFrame.new(0, 0, -12)
    singerHRP.CFrame = CFrame.new(front.Position, playerHRP.Position)
    singerHRP.Anchored = true
    singerBasePos = singerHRP.CFrame
end

if singerHum then
    local sc = {BodyHeightScale=3, BodyWidthScale=3, BodyDepthScale=3, HeadScale=3}
    for n, v in pairs(sc) do
        local obj = singerHum:FindFirstChild(n)
        if obj then obj.Value = v end
    end
end

local cloneChar = Players:CreateHumanoidModelFromUserId(Players:GetUserIdFromNameAsync(LocalPlayer.Name))
cloneChar.Name   = "ArigatoOrbitClone"
cloneChar.Parent = workspace
local cloneHum = cloneChar:FindFirstChildOfClass("Humanoid")
local cloneHRP = cloneChar:FindFirstChild("HumanoidRootPart")
if cloneHum then
    cloneHum.WalkSpeed = 0; cloneHum.JumpHeight = 0
    cloneHum.NameDisplayDistance = 0; cloneHum.HealthDisplayDistance = 0
end
if cloneHRP then cloneHRP.Anchored = true end
for _, part in ipairs(cloneChar:GetDescendants()) do
    if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("SpecialMesh") then
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.Transparency = 1
        end
    end
end
local cloneTrailAtt0 = Instance.new("Attachment")
local cloneTrailAtt1 = Instance.new("Attachment")
if cloneHRP then
    cloneTrailAtt0.Position = Vector3.new(0,1,0)
    cloneTrailAtt1.Position = Vector3.new(0,-1,0)
    cloneTrailAtt0.Parent = cloneHRP
    cloneTrailAtt1.Parent = cloneHRP
    local cloneTrail = Instance.new("Trail", cloneHRP)
    cloneTrail.Attachment0   = cloneTrailAtt0
    cloneTrail.Attachment1   = cloneTrailAtt1
    cloneTrail.Lifetime      = 0.35
    cloneTrail.MinLength     = 0
    cloneTrail.LightEmission = 1
    cloneTrail.Color         = ColorSequence.new(Color3.fromRGB(255,80,220), Color3.fromRGB(80,200,255))
    cloneTrail.Transparency  = NumberSequence.new(0, 1)
    local clonePE = Instance.new("ParticleEmitter", cloneHRP)
    clonePE.Rate          = 25
    clonePE.Lifetime      = NumberRange.new(0.3, 0.8)
    clonePE.Speed         = NumberRange.new(2, 6)
    clonePE.LightEmission = 1
    clonePE.LightInfluence= 0
    clonePE.Color         = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,80,220)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80,200,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,80)),
    })
    clonePE.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,0)})
    clonePE.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
end

local cloneOrbitAngle = 0
local cloneOrbitRadius = 18
local cloneOrbitSpeed  = 0.6

local spotLight = Instance.new("SpotLight", singerHRP or workspace)
spotLight.Brightness = 8
spotLight.Range      = 80
spotLight.Angle      = 50
spotLight.Color      = Color3.fromRGB(255, 180, 255)
spotLight.Face       = Enum.NormalId.Top

local pointLight = Instance.new("PointLight", singerHead or workspace)
pointLight.Brightness = 3
pointLight.Range      = 30
pointLight.Color      = Color3.fromRGB(200, 100, 255)

local singerSpotDown = Instance.new("SpotLight", singerHRP or workspace)
singerSpotDown.Brightness = 5
singerSpotDown.Range      = 60
singerSpotDown.Angle      = 45
singerSpotDown.Color      = Color3.fromRGB(150, 80, 255)
singerSpotDown.Face       = Enum.NormalId.Bottom

local mainFolder = Instance.new("Folder", workspace)
mainFolder.Name = "_arigato_fx"

local stagePlatform
if singerHRP then
    stagePlatform = Instance.new("Part", mainFolder)
    stagePlatform.Size = Vector3.new(18, 0.5, 18)
    stagePlatform.Anchored = true; stagePlatform.CanCollide = false; stagePlatform.CastShadow = false
    stagePlatform.Material = Enum.Material.Neon
    stagePlatform.Color = Color3.fromRGB(80, 0, 160)
    stagePlatform.Transparency = 0.3
    stagePlatform.CFrame = CFrame.new(singerHRP.Position - Vector3.new(0, 5, 0))
    local stageGrid = Instance.new("SelectionBox", mainFolder)
    stageGrid.Adornee = stagePlatform
    stageGrid.Color3 = Color3.fromRGB(200, 80, 255)
    stageGrid.LineThickness = 0.04
    stageGrid.SurfaceTransparency = 1
end

local nebulaFolder = Instance.new("Folder", mainFolder)
nebulaFolder.Name = "nebula"
local nebulaParts = {}
local NUM_NEBULA = 12
for i = 1, NUM_NEBULA do
    local p = Instance.new("Part", nebulaFolder)
    p.Size = Vector3.new(math.random(6,14), math.random(6,14), 0.2)
    p.Anchored = true; p.CanCollide = false; p.CastShadow = false
    p.Material = Enum.Material.Neon
    p.Color = Color3.fromHSV((i-1)/NUM_NEBULA, 0.7, 1)
    p.Transparency = 0.7
    local rA = math.random() * math.pi * 2
    local rD = math.random(30, 60)
    local rH = math.random(15, 50)
    table.insert(nebulaParts, {part=p, rA=rA, rD=rD, rH=rH, phase=math.random()*math.pi*2, speed=math.random()*0.2+0.05})
end

local function updateNebula(t)
    if not singerHRP then return end
    for _, nd in ipairs(nebulaParts) do
        local p = nd.part
        local angle = nd.rA + t * nd.speed
        local pos = singerHRP.Position + Vector3.new(
            math.cos(angle) * nd.rD,
            nd.rH + math.sin(t * 0.3 + nd.phase) * 5,
            math.sin(angle) * nd.rD
        )
        p.CFrame = CFrame.new(pos) * CFrame.Angles(math.sin(t*0.1+nd.phase)*0.3, angle, 0)
        local hue = ((t * 0.04 + nd.phase) % 1)
        p.Color = Color3.fromHSV(hue, 0.8, 1)
        p.Transparency = 0.6 + math.sin(t * nd.speed * 2 + nd.phase) * 0.15
    end
end

local confettiFolder = Instance.new("Folder", mainFolder)
confettiFolder.Name = "confetti"
local function spawnConfetti(count, origin)
    origin = origin or (singerHRP and singerHRP.Position or Vector3.new(0,10,0))
    for i = 1, count do
        task.spawn(function()
            local c = Instance.new("Part", confettiFolder)
            c.Size = Vector3.new(0.3, 0.05, 0.6)
            c.Material = Enum.Material.Neon
            c.Anchored = false; c.CanCollide = false; c.CastShadow = false
            c.Color = Color3.fromHSV(math.random(), 1, 1)
            c.CFrame = CFrame.new(origin + Vector3.new(math.random(-5,5), math.random(0,5), math.random(-5,5)))
                * CFrame.Angles(math.random()*math.pi*2, math.random()*math.pi*2, math.random()*math.pi*2)
            local bv = Instance.new("BodyVelocity", c)
            bv.Velocity = Vector3.new(math.random(-15,15), math.random(8,30), math.random(-15,15))
            bv.MaxForce = Vector3.new(1e5,1e5,1e5)
            TweenService:Create(c, TweenInfo.new(2, Enum.EasingStyle.Sine), {Transparency = 1}):Play()
            game:GetService("Debris"):AddItem(c, 2.2)
        end)
    end
end

local showLightFolder = Instance.new("Folder", mainFolder)
showLightFolder.Name = "showlights"
local showLights = {}
local NUM_SHOW_LIGHTS = 6

for i = 1, NUM_SHOW_LIGHTS do
    local base = Instance.new("Part", showLightFolder)
    base.Size = Vector3.new(0.8, 0.8, 0.8)
    base.Anchored = true; base.CanCollide = false; base.CastShadow = false
    base.Material = Enum.Material.Neon
    base.Color = Color3.fromHSV((i-1)/NUM_SHOW_LIGHTS, 1, 1)
    base.Transparency = 0.2

    local top = Instance.new("Part", showLightFolder)
    top.Size = Vector3.new(0.4, 1.2, 0.4)
    top.Anchored = true; top.CanCollide = false; top.CastShadow = false
    top.Material = Enum.Material.Neon
    top.Color = base.Color

    local a0 = Instance.new("Attachment", base)
    a0.Position = Vector3.new(0,0,0)
    local a1 = Instance.new("Attachment", top)
    a1.Position = Vector3.new(0,0,0)

    local beam = Instance.new("Beam", showLightFolder)
    beam.Attachment0 = a0; beam.Attachment1 = a1
    beam.Width0 = 2.5; beam.Width1 = 0.05
    beam.FaceCamera = true
    beam.LightEmission = 1; beam.LightInfluence = 0
    beam.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, base.Color),
        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(((i-1)/NUM_SHOW_LIGHTS + 0.5) % 1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
    })
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.7, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    beam.Segments = 6
    beam.CurveSize0 = 0; beam.CurveSize1 = 0

    local sl = Instance.new("SpotLight", top)
    sl.Brightness = 6; sl.Range = 80; sl.Angle = 15
    sl.Color = base.Color

    table.insert(showLights, {base=base, top=top, beam=beam, sl=sl, idx=i})
end

local function updateShowLights(t)
    if not singerHRP then return end
    local pos = singerHRP.Position
    for _, sl in ipairs(showLights) do
        local i = sl.idx
        local baseAngle = (i-1)*(math.pi*2/NUM_SHOW_LIGHTS)
        local baseR = 28
        local bx = math.cos(baseAngle) * baseR
        local bz = math.sin(baseAngle) * baseR
        sl.base.Position = pos + Vector3.new(bx, -2, bz)

        local swingSpeed = 0.8 + (i % 3) * 0.3
        local swingAmp   = math.pi / 5
        local targetAngle = baseAngle + math.sin(t * swingSpeed + i * 1.1) * swingAmp
        local targetDist  = 20 + math.sin(t * 0.5 + i) * 8
        local targetHeight = 30 + math.cos(t * 0.4 + i * 0.7) * 14
        local tx = math.cos(targetAngle) * targetDist
        local tz = math.sin(targetAngle) * targetDist
        sl.top.Position = pos + Vector3.new(tx, targetHeight, tz)

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

local beamColors = {
    {Color3.fromRGB(255,80,220), Color3.fromRGB(150,50,255)},
    {Color3.fromRGB(80,200,255), Color3.fromRGB(0,100,255)},
    {Color3.fromRGB(255,200,80), Color3.fromRGB(255,80,80)},
    {Color3.fromRGB(80,255,160), Color3.fromRGB(0,200,100)},
    {Color3.fromRGB(255,255,100), Color3.fromRGB(200,80,255)},
}

local pentaFolder = Instance.new("Folder", mainFolder)
pentaFolder.Name  = "pentagon"
local pentaParts  = {}
local NUM_SIDES   = 6
local PENTA_RADIUS = 16
local PENTA_COLORS = {
    Color3.fromRGB(255,80,220),
    Color3.fromRGB(120,80,255),
    Color3.fromRGB(80,200,255),
    Color3.fromRGB(255,200,80),
    Color3.fromRGB(80,255,160),
    Color3.fromRGB(255,100,100),
}

for i = 1, NUM_SIDES do
    local p = Instance.new("Part", pentaFolder)
    p.Size       = Vector3.new(0.6, 8, 1)
    p.Anchored   = true
    p.CanCollide = false
    p.Material   = Enum.Material.Neon
    p.Color      = PENTA_COLORS[i]
    p.CastShadow = false
    local a0 = Instance.new("Attachment", p); a0.Position = Vector3.new(0,  0.5, 0)
    local a1 = Instance.new("Attachment", p); a1.Position = Vector3.new(0, -0.5, 0)
    local tr = Instance.new("Trail", p)
    tr.Attachment0    = a0; tr.Attachment1 = a1
    tr.Lifetime       = 0.18
    tr.MinLength      = 0
    tr.Color          = ColorSequence.new(PENTA_COLORS[i], Color3.fromRGB(255,255,255))
    tr.Transparency   = NumberSequence.new(0.3, 1)
    tr.LightEmission  = 1
    table.insert(pentaParts, p)
end

local function updatePentagon(angle)
    if not singerHRP or not singerHRP.Parent then return end
    local backOffset = CFrame.new(0, 2, 10)
    local base = singerHRP.CFrame * backOffset
    for i, p in ipairs(pentaParts) do
        local a1 = angle + (i-1)*(math.pi*2/NUM_SIDES)
        local a2 = angle + i    *(math.pi*2/NUM_SIDES)
        local r  = PENTA_RADIUS
        local p1 = base.Position + Vector3.new(math.cos(a1)*r, math.sin(a1)*r*0.5, math.sin(a1)*0.5)
        local p2 = base.Position + Vector3.new(math.cos(a2)*r, math.sin(a2)*r*0.5, math.sin(a2)*0.5)
        local mid  = (p1+p2)/2
        local len  = (p2-p1).Magnitude
        local look = (p2-p1).Unit
        p.Size   = Vector3.new(0.6, len, 1)
        p.CFrame = CFrame.lookAt(mid, mid+look) * CFrame.Angles(math.pi/2, 0, 0)
        local hue = ((angle*0.05 + (i-1)/NUM_SIDES) % 1)
        p.Color   = Color3.fromHSV(hue, 1, 1)
    end
end

local orbitFolder = Instance.new("Folder", mainFolder)
orbitFolder.Name  = "orbit"
local orbitParts  = {}
local NUM_ORBIT   = 18
local ORBIT_RADIUS = 20

for i = 1, NUM_ORBIT do
    local p = Instance.new("Part", orbitFolder)
    p.Size       = Vector3.new(1.5, 1.5, 1.5)
    p.Shape      = Enum.PartType.Ball
    p.Anchored   = true
    p.CanCollide = false
    p.Material   = Enum.Material.Neon
    p.CastShadow = false
    p.Color      = Color3.fromHSV((i-1)/NUM_ORBIT, 1, 1)
    local pl = Instance.new("PointLight", p)
    pl.Brightness = 2; pl.Range = 12; pl.Color = p.Color
    table.insert(orbitParts, p)
end

local outerOrbitParts = {}
local NUM_OUTER = 8
for i = 1, NUM_OUTER do
    local p = Instance.new("Part", orbitFolder)
    p.Size = Vector3.new(2.5, 2.5, 2.5)
    p.Shape = Enum.PartType.Ball
    p.Anchored = true; p.CanCollide = false
    p.Material = Enum.Material.Neon; p.CastShadow = false
    p.Color = Color3.fromHSV((i-1)/NUM_OUTER, 1, 1)
    local pl = Instance.new("PointLight", p)
    pl.Brightness = 3; pl.Range = 18; pl.Color = p.Color
    table.insert(outerOrbitParts, p)
end

local function updateOrbit(t)
    if not singerHRP or not singerHRP.Parent then return end
    local center = singerHRP.Position + Vector3.new(0, 6, 0)
    for i, p in ipairs(orbitParts) do
        local angle = t * 1.2 + (i-1)*(math.pi*2/NUM_ORBIT)
        local x = math.cos(angle) * ORBIT_RADIUS
        local z = math.sin(angle) * ORBIT_RADIUS
        local y = math.sin(t*2 + i) * 4
        p.Position = center + Vector3.new(x, y, z)
        local hue  = ((t*0.1 + (i-1)/NUM_ORBIT) % 1)
        p.Color    = Color3.fromHSV(hue, 1, 1)
        local pl   = p:FindFirstChildOfClass("PointLight")
        if pl then pl.Color = p.Color end
    end
    local outerR = 38
    for i, p in ipairs(outerOrbitParts) do
        local angle = -t * 0.7 + (i-1)*(math.pi*2/NUM_OUTER)
        local x = math.cos(angle) * outerR
        local z = math.sin(angle) * outerR
        local y = math.sin(t*1.5 + i*1.3) * 8 + 10
        p.Position = singerHRP.Position + Vector3.new(x, y, z)
        local hue = ((t*0.08 + (i-1)/NUM_OUTER + 0.5) % 1)
        p.Color = Color3.fromHSV(hue, 1, 1)
        local pl = p:FindFirstChildOfClass("PointLight")
        if pl then pl.Color = p.Color end
    end
end

local starFolder = Instance.new("Folder", mainFolder)
starFolder.Name = "stars"
local starParts = {}
local NUM_STARS = 30

for i = 1, NUM_STARS do
    local s = Instance.new("Part", starFolder)
    s.Size = Vector3.new(0.4,0.4,0.4)
    s.Shape = Enum.PartType.Ball
    s.Anchored = true; s.CanCollide = false
    s.Material = Enum.Material.Neon; s.CastShadow = false
    s.Color = Color3.fromHSV(math.random(), 1, 1)
    local randX = math.random(-60,60)
    local randY = math.random(20,80)
    local randZ = math.random(-60,60)
    table.insert(starParts, {part=s, ox=randX, oy=randY, oz=randZ, phase=math.random()*math.pi*2, speed=math.random()*0.5+0.3})
end

local function updateStars(t)
    if not singerHRP then return end
    for _, sd in ipairs(starParts) do
        local p = sd.part
        local twinkle = math.abs(math.sin(t*sd.speed + sd.phase))
        p.Size = Vector3.new(twinkle*0.6+0.1, twinkle*0.6+0.1, twinkle*0.6+0.1)
        p.Position = singerHRP.Position + Vector3.new(sd.ox, sd.oy, sd.oz)
        p.Color = Color3.fromHSV(((t*0.05 + sd.phase) % 1), 1, 1)
    end
end

local lyricWorldFolder = Instance.new("Folder", mainFolder)
lyricWorldFolder.Name = "lyricworld"
local activeLyricParts = {}

local function spawnWorldLyric(text)
    if not singerHRP or text == "" then return end
    task.spawn(function()
        local board = Instance.new("Part", lyricWorldFolder)
        board.Size = Vector3.new(0.1, 3.5, 12)
        board.Anchored = true; board.CanCollide = false; board.CastShadow = false
        board.Transparency = 0.4
        board.Material = Enum.Material.Neon
        board.Color = Color3.fromHSV(math.random(), 1, 1)
        local angle = math.random() * math.pi * 2
        local dist  = math.random(18, 35)
        local height = math.random(8, 20)
        board.CFrame = CFrame.new(
            singerHRP.Position + Vector3.new(math.cos(angle)*dist, height, math.sin(angle)*dist)
        ) * CFrame.Angles(0, angle + math.pi/2, 0)
        local sg2 = Instance.new("SurfaceGui", board)
        sg2.Face = Enum.NormalId.Front
        sg2.AlwaysOnTop = false
        sg2.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        sg2.PixelsPerStud = 50
        local lbl = Instance.new("TextLabel", sg2)
        lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextStrokeTransparency = 0
        lbl.TextStrokeColor3 = Color3.fromHSV(math.random(), 1, 1)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextScaled = true
        lbl.Text = text
        TweenService:Create(board, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = Vector3.new(0.1, 4, 14)
        }):Play()
        table.insert(activeLyricParts, board)
        task.delay(3.5, function()
            TweenService:Create(board, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
                Transparency = 1
            }):Play()
            task.wait(0.7)
            pcall(function() board:Destroy() end)
            for i, v in ipairs(activeLyricParts) do
                if v == board then table.remove(activeLyricParts, i) break end
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
            cube.Size       = Vector3.new(math.random(1,3), math.random(1,3), math.random(1,3))
            cube.Material   = Enum.Material.Neon
            cube.Anchored   = false
            cube.CanCollide = false
            cube.CastShadow = false
            cube.Color      = Color3.fromHSV(math.random(), 1, 1)
            cube.CFrame     = CFrame.new(origin)
            local pl2 = Instance.new("PointLight", cube)
            pl2.Brightness = 2; pl2.Range = 8; pl2.Color = cube.Color
            local bv = Instance.new("BodyVelocity", cube)
            bv.Velocity = Vector3.new(math.random(-25,25), math.random(10,45), math.random(-25,25))
            bv.MaxForce = Vector3.new(1e5,1e5,1e5)
            TweenService:Create(cube, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = Vector3.new(0.1,0.1,0.1), Transparency = 1
            }):Play()
            game:GetService("Debris"):AddItem(cube, 1.6)
        end)
    end
end

local function shockwave(color)
    if not singerHRP or not singerHRP.Parent then return end
    task.spawn(function()
        local ring = Instance.new("Part", mainFolder)
        ring.Size         = Vector3.new(2, 0.3, 2)
        ring.Shape        = Enum.PartType.Cylinder
        ring.Material     = Enum.Material.Neon
        ring.Color        = color or Color3.fromRGB(255,100,255)
        ring.Anchored     = true
        ring.CanCollide   = false
        ring.CastShadow   = false
        ring.Transparency = 0.2
        ring.CFrame       = CFrame.new(singerHRP.Position) * CFrame.Angles(0, 0, math.pi/2)
        TweenService:Create(ring, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = Vector3.new(70, 0.3, 70), Transparency = 1
        }):Play()
        game:GetService("Debris"):AddItem(ring, 0.9)
    end)
end

local function spawnLaserRing(height)
    if not singerHRP then return end
    task.spawn(function()
        local count = 12
        local radius = 6
        local parts = {}
        for i = 1, count do
            local p = Instance.new("Part", mainFolder)
            p.Size = Vector3.new(0.3, 8, 0.3)
            p.Material = Enum.Material.Neon
            p.Anchored = true; p.CanCollide = false; p.CastShadow = false
            p.Color = Color3.fromHSV((i-1)/count, 1, 1)
            local ang = (i-1) * (math.pi*2/count)
            p.CFrame = CFrame.new(singerHRP.Position + Vector3.new(math.cos(ang)*radius, height or 3, math.sin(ang)*radius))
            table.insert(parts, p)
        end
        task.delay(0.8, function()
            for _, p in ipairs(parts) do
                TweenService:Create(p, TweenInfo.new(0.5), {Transparency = 1}):Play()
                game:GetService("Debris"):AddItem(p, 0.6)
            end
        end)
    end)
end

local function addParticles(part)
    if not part then return nil end
    local pe = Instance.new("ParticleEmitter", part)
    pe.Rate          = 0
    pe.Lifetime      = NumberRange.new(0.5, 1.8)
    pe.Speed         = NumberRange.new(4, 14)
    pe.SpreadAngle   = Vector2.new(60, 60)
    pe.LightEmission = 1
    pe.LightInfluence= 0
    pe.Color         = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,80,220)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80,200,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,255,100)),
    })
    pe.Size          = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.6),
        NumberSequenceKeypoint.new(0.5, 1.2),
        NumberSequenceKeypoint.new(1,   0),
    })
    pe.Transparency  = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    pe.RotSpeed = NumberRange.new(-200, 200)
    pe.Rotation = NumberRange.new(0, 360)
    return pe
end

local singerParticles = addParticles(singerHRP)
local playerParticles = addParticles(playerHRP)

local function burstParticles(pe, count)
    if pe and pe.Parent then pe:Emit(count or 20) end
end

local EMOTE_IDS = {
    dance  = "rbxassetid://507771019",
    wave   = "rbxassetid://507770718",
    point  = "rbxassetid://507770453",
    cheer  = "rbxassetid://507770677",
    laugh  = "rbxassetid://507770818",
    sit    = "rbxassetid://507770872",
    salute = "rbxassetid://3360689775",
    tpose  = "rbxassetid://3360686468",
    robot  = "rbxassetid://3360695866",
    flip   = "rbxassetid://507770239",
}

local currentAnimTrack = nil

local function playSingerAnim(animId)
    if not singerHum then return end
    if currentAnimTrack then
        pcall(function() currentAnimTrack:Stop(0.3) end)
        currentAnimTrack = nil
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local ok, track = pcall(function() return singerHum:LoadAnimation(anim) end)
    if ok and track then
        track.Looped = true
        track:Play(0.3)
        currentAnimTrack = track
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
local function singerRandom()
    local list = {EMOTE_IDS.dance, EMOTE_IDS.cheer, EMOTE_IDS.wave, EMOTE_IDS.laugh, EMOTE_IDS.robot, EMOTE_IDS.salute}
    playSingerAnim(list[math.random(1, #list)])
end

singerDance()

local sg = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
sg.Name           = "ArigatoShowGui"
sg.IgnoreGuiInset = true
sg.ResetOnSpawn   = false
sg.DisplayOrder   = 999
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function makeFrame(parent, props)
    local f = Instance.new("Frame", parent)
    f.BorderSizePixel = 0
    for k,v in pairs(props) do f[k] = v end
    return f
end

local BAR_H = 70

local cinemaTop = makeFrame(sg, {
    Size     = UDim2.new(1, 4, 0, BAR_H + 4),
    Position = UDim2.new(-0.002, 0, 0, -(BAR_H + 4)),
    BackgroundColor3 = Color3.new(0,0,0),
    ZIndex   = 10,
})
local cinemaBot = makeFrame(sg, {
    Size     = UDim2.new(1, 4, 0, BAR_H + 4),
    Position = UDim2.new(-0.002, 0, 1, 0),
    BackgroundColor3 = Color3.new(0,0,0),
    ZIndex   = 10,
})

TweenService:Create(cinemaTop, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(-0.002,0,0,-2)}):Play()
TweenService:Create(cinemaBot, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(-0.002,0,1,-(BAR_H+2))}):Play()

local lyricOuter = makeFrame(sg, {
    Size = UDim2.new(0.65, 0, 0, 68),
    Position = UDim2.new(0.175, 0, 1, -155),
    BackgroundColor3 = Color3.fromRGB(30, 0, 60),
    BackgroundTransparency = 0.35,
    ZIndex = 9,
})
local lyricCorner = Instance.new("UICorner", lyricOuter)
lyricCorner.CornerRadius = UDim.new(0, 10)
local lyricStroke = Instance.new("UIStroke", lyricOuter)
lyricStroke.Color     = Color3.fromRGB(200, 100, 255)
lyricStroke.Thickness = 2.5
lyricStroke.Transparency = 0.2

local lyricLabel = Instance.new("TextLabel", lyricOuter)
lyricLabel.Size               = UDim2.new(1,-20,0,38)
lyricLabel.Position           = UDim2.new(0,10,0,3)
lyricLabel.BackgroundTransparency = 1
lyricLabel.TextColor3         = Color3.new(1,1,1)
lyricLabel.TextStrokeTransparency = 0.15
lyricLabel.TextStrokeColor3   = Color3.fromRGB(160,0,255)
lyricLabel.Font               = Enum.Font.GothamBold
lyricLabel.TextSize           = 26
lyricLabel.TextXAlignment     = Enum.TextXAlignment.Center
lyricLabel.Text               = ""
lyricLabel.ZIndex             = 11
lyricLabel.ClipsDescendants   = false

local subLabel = Instance.new("TextLabel", lyricOuter)
subLabel.Size               = UDim2.new(1,-20,0,24)
subLabel.Position           = UDim2.new(0,10,0,42)
subLabel.BackgroundTransparency = 1
subLabel.TextColor3         = Color3.fromRGB(220, 185, 255)
subLabel.TextStrokeTransparency = 0.4
subLabel.Font               = Enum.Font.Gotham
subLabel.TextSize            = 15
subLabel.TextXAlignment      = Enum.TextXAlignment.Center
subLabel.Text                = ""
subLabel.ZIndex              = 11

local flashFrame = makeFrame(sg, {
    Size = UDim2.new(1,0,1,0),
    BackgroundColor3 = Color3.new(1,1,1),
    BackgroundTransparency = 1,
    ZIndex = 20,
})

local vignetteFrame = makeFrame(sg, {
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    ZIndex = 8,
})
local vgGrad = Instance.new("UIGradient", vignetteFrame)
vgGrad.Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0))
vgGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,   0.25),
    NumberSequenceKeypoint.new(0.4, 1),
    NumberSequenceKeypoint.new(1,   0.25),
})
vgGrad.Rotation = 90



Camera.CameraType  = Enum.CameraType.Scriptable
Camera.FieldOfView = 70

local camAngle  = math.pi
local camDist   = 22
local camHeight = 8
local camMode   = "orbit"
local camFOV    = 70
local camTarget = "singer"

local function tweenFOV(fov, t)
    camFOV = fov
    TweenService:Create(Camera, TweenInfo.new(t or 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        FieldOfView = fov
    }):Play()
end

local function getTargetPos()
    if camTarget == "player" and playerHRP and playerHRP.Parent then
        return playerHRP.Position
    end
    if singerHRP and singerHRP.Parent then
        return singerHRP.Position
    end
    return Vector3.new(0,0,0)
end

local function getSingerBodyCenter()
    if singerHRP and singerHRP.Parent then
        return singerHRP.Position + Vector3.new(0, 5, 0)
    end
    return Vector3.new(0,5,0)
end

local function getTargetCamCF()
    local target   = getTargetPos()
    local bodyCenter = getSingerBodyCenter()
    local headOff  = Vector3.new(0, camHeight, 0)

    if camMode == "orbit" then
        return CFrame.lookAt(
            target + headOff + Vector3.new(math.cos(camAngle)*camDist, camHeight*0.1, math.sin(camAngle)*camDist),
            bodyCenter
        )
    elseif camMode == "close" then
        local bp = bodyCenter
        return CFrame.lookAt(
            bp + Vector3.new(math.cos(camAngle)*camDist, 2, math.sin(camAngle)*camDist),
            bp
        )
    elseif camMode == "face" then
        local bp = bodyCenter + Vector3.new(0, 2, 0)
        return CFrame.lookAt(
            bp + Vector3.new(math.cos(camAngle)*camDist, 0, math.sin(camAngle)*camDist),
            bp
        )
    elseif camMode == "playerface" then
        local hp = (playerHead and playerHead.Position or target) + Vector3.new(0, 1, 0)
        return CFrame.lookAt(
            hp + Vector3.new(math.cos(camAngle)*3.5, 0, math.sin(camAngle)*3.5),
            hp
        )
    elseif camMode == "top" then
        return CFrame.lookAt(target + Vector3.new(0, 38, 0.01), target)
    elseif camMode == "dramatic" then
        local bp = bodyCenter
        return CFrame.lookAt(
            bp + Vector3.new(math.cos(camAngle)*camDist, -2, math.sin(camAngle)*camDist),
            bp + Vector3.new(0, 4, 0)
        )
    elseif camMode == "worm" then
        return CFrame.lookAt(
            target + Vector3.new(math.cos(camAngle)*camDist, -5, math.sin(camAngle)*camDist),
            target + Vector3.new(0, 8, 0)
        )
    elseif camMode == "fnf_left" then
        local sp = singerHRP and singerHRP.Position or Vector3.new(0,0,0)
        local pp = playerHRP and playerHRP.Position or Vector3.new(0,0,12)
        local mid = (sp + pp) / 2
        return CFrame.lookAt(mid + Vector3.new(0, 8, 28), mid + Vector3.new(0, 4, 0))
    end
    return Camera.CFrame
end

local function flash(r, g, b, dur)
    flashFrame.BackgroundColor3 = Color3.fromRGB(r,g,b)
    flashFrame.BackgroundTransparency = 0.05
    TweenService:Create(flashFrame, TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quint), {
        BackgroundTransparency = 1
    }):Play()
end

local glitching = false
local function glitch(times, strength)
    if glitching then return end
    glitching = true
    strength  = strength or 1
    local orig = Camera.CFrame
    task.spawn(function()
        for _ = 1, (times or 5) do
            Camera.CFrame = orig
                * CFrame.new(math.random(-10,10)*0.05*strength, math.random(-5,5)*0.03*strength, 0)
                * CFrame.Angles(0, 0, math.rad(math.random(-4,4)*strength))
            task.wait(0.04)
        end
        Camera.CFrame = orig
        glitching = false
    end)
end

local function lightningFlash()
    flash(255,255,255, 0.06)
    task.delay(0.09,  function() flash(200,80,255, 0.1) end)
    task.delay(0.22,  function() flash(255,255,255, 0.05) end)
    glitch(4, 1.5)
end

local function colorShift(r, g, b, t)
    TweenService:Create(colorCorrection, TweenInfo.new(t or 0.35, Enum.EasingStyle.Quint), {
        TintColor = Color3.fromRGB(r,g,b)
    }):Play()
end

local skyColorIdx = 0
local function skyColor(r, g, b)
    skyColorIdx = skyColorIdx + 1
    TweenService:Create(Lighting, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {
        Ambient        = Color3.fromRGB(r//3, g//3, b//3),
        OutdoorAmbient = Color3.fromRGB(r//2, g//2, b//2),
        FogColor       = Color3.fromRGB(r//2, g//2, b//2),
        FogEnd         = 600 + math.random(0, 300),
        Brightness     = 1.5 + math.random()*0.6,
    }):Play()
    TweenService:Create(colorCorrection, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
        TintColor = Color3.fromRGB(
            math.clamp(r + 60, 0, 255),
            math.clamp(g + 30, 0, 255),
            math.clamp(b + 80, 0, 255)
        )
    }):Play()
    TweenService:Create(bloom, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
        Intensity = 1.0 + math.random()*1.2,
        Size = 20 + math.random()*20,
    }):Play()
end

local function punchCam(scale)
    scale = scale or 1
    local base = camFOV
    tweenFOV(base - 8*scale, 0.08)
    task.delay(0.12, function() tweenFOV(base + 12*scale, 0.18) end)
    task.delay(0.35, function() tweenFOV(base, 0.25) end)
end

local function zoomToFace(who, fov, duration, holdTime)
    local prevMode   = camMode
    local prevFOV    = camFOV
    local prevTarget = camTarget
    camTarget = who or "singer"
    camMode   = (who == "player") and "playerface" or "face"
    tweenFOV(fov or 35, duration or 0.5)
    if holdTime then
        task.delay(holdTime, function()
            camMode   = prevMode
            camTarget = prevTarget
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
    burstParticles(singerParticles, 20)
    shockwave(Color3.fromHSV(math.random(), 1, 1))
    task.delay(duration * 0.5, function()
        scaleSinger(3.5, 0.25)
    end)
    task.delay(duration, function()
        isFloating = false
        scaleSinger(3, 0.4)
        if singerHRP and singerHRP.Parent and singerBasePos then
            TweenService:Create(singerHRP, TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
                CFrame = singerBasePos
            }):Play()
            task.delay(0.1, function()
                shockwave(Color3.fromRGB(255,200,80))
                burstParticles(singerParticles, 15)
            end)
        end
    end)
end

local function slamDown()
    if not singerHRP then return end
    scaleSinger(5, 0.15)
    task.delay(0.15, function()
        if singerBasePos then
            TweenService:Create(singerHRP, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                CFrame = singerBasePos
            }):Play()
        end
        task.delay(0.25, function()
            scaleSinger(3, 0.3)
            flash(255,180,80, 0.3)
            glitch(8, 2)
            shockwave(Color3.fromRGB(255,200,80))
            spawnExplosiveCubes(8, singerHRP and singerHRP.Position)
            burstParticles(singerParticles, 30)
            punchCam(1.5)
            spawnLaserRing(0)
            task.delay(0.1, function() spawnLaserRing(4) end)
        end)
    end)
end

local function doSuperBurst()
    local pos = singerHRP and singerHRP.Position or Vector3.new(0,10,0)
    spawnExplosiveCubes(20, pos)
    shockwave(Color3.fromRGB(255,80,220))
    task.delay(0.15, function() shockwave(Color3.fromRGB(80,200,255)) end)
    task.delay(0.30, function() shockwave(Color3.fromRGB(255,255,80)) end)
    burstParticles(singerParticles, 60)
    burstParticles(playerParticles, 30)
    lightningFlash()
    punchCam(2)
    spawnLaserRing(4)
    task.delay(0.2, function() spawnLaserRing(8) end)
    task.delay(0.4, function() spawnLaserRing(12) end)
    spawnConfetti(30, pos)
    scaleSinger(5, 0.2)
    task.delay(0.5, function() scaleSinger(3, 0.4) end)
end

local function showLyric(entry)
    lyricLabel.Text = entry.jp
    subLabel.Text   = entry.en

    if singerHead and singerHead.Parent and entry.jp ~= "" then
        pcall(function() ChatService:Chat(singerHead, entry.jp) end)
    end

    local worldText = entry.jp ~= "" and entry.jp or entry.en
    if worldText ~= "" then
        spawnWorldLyric(worldText)
    end

    if math.random(1, 3) == 1 then
        spawnConfetti(10, singerHRP and singerHRP.Position)
    end

    lyricLabel.TextSize  = 32
    lyricLabel.TextColor3 = Color3.fromHSV(math.random(), 1, 1)

    TweenService:Create(lyricLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        TextSize   = 26,
        TextColor3 = Color3.new(1, 1, 1),
    }):Play()

    TweenService:Create(lyricOuter, TweenInfo.new(0.08), {
        BackgroundTransparency = 0.1,
    }):Play()

    task.delay(0.5, function()
        TweenService:Create(lyricOuter, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {
            BackgroundTransparency = 0.45,
        }):Play()
    end)

    local hue = math.random()
    TweenService:Create(lyricStroke, TweenInfo.new(0.06), {
        Color = Color3.fromHSV(hue, 1, 1)
    }):Play()
    task.delay(0.5, function()
        TweenService:Create(lyricStroke, TweenInfo.new(0.4), {
            Color = Color3.fromRGB(200, 100, 255)
        }):Play()
    end)
end

local lastLyricTime  = 0
local idleAnimPlaying = false

local function checkIdleAnim(elapsed)
    if elapsed - lastLyricTime > 4 and not idleAnimPlaying then
        idleAnimPlaying = true
        local rng = math.random(1, 7)
        if rng == 1 then
            floatSinger(15, 1.5)
            singerCheer()
            shockwave(Color3.fromRGB(100,200,255))
            burstParticles(singerParticles, 15)
        elseif rng == 2 then
            singerDance()
            spawnExplosiveCubes(6, singerHRP and singerHRP.Position)
        elseif rng == 3 then
            singerPoint()
            zoomToFace("player", 40, 0.4, 2.5)
        elseif rng == 4 then
            singerLaugh()
            glitch(5, 1)
        elseif rng == 5 then
            singerWave()
            shockwave(Color3.fromRGB(255,200,80))
        elseif rng == 6 then
            singerRobot()
            spawnLaserRing(3)
            task.delay(0.15, function() spawnLaserRing(7) end)
        else
            singerSalute()
            burstParticles(singerParticles, 20)
        end
        task.delay(3.8, function() idleAnimPlaying = false end)
    end
end

local choreo = {
    {0, function()
        singerDance()
        tweenFOV(65, 1.5)
        colorShift(200,150,255)
        camMode = "orbit"; camDist = 22
    end},
    {9.22, function()
        zoomToFace("singer", 38, 0.6, 2.5)
        colorShift(255,150,255)
        skyColor(60,0,80)
        singerDance()
        punchCam()
        spawnLaserRing(5)
    end},
    {13.15, function()
        floatSinger(20, 2)
        camMode = "dramatic"; camDist = 18
        tweenFOV(60, 0.5)
        lightningFlash()
        singerCheer()
        shockwave(Color3.fromRGB(200,80,255))
        burstParticles(singerParticles, 25)
        spawnLaserRing(6)
    end},
    {17.75, function()
        glitch(6, 1.5)
        flash(255,80,200, 0.2)
        camMode = "orbit"; camDist = 28
        tweenFOV(72, 0.4)
        colorShift(100,200,255)
        skyColor(0,20,80)
        spawnExplosiveCubes(12, singerHRP and singerHRP.Position)
        singerWave()
        spawnLaserRing(4); task.delay(0.2, function() spawnLaserRing(8) end)
    end},
    {21.07, function()
        zoomToFace("singer", 34, 0.5, 3)
        colorShift(200,255,150)
        skyColor(0,60,20)
        singerPoint()
        spawnLaserRing(2)
    end},
    {24.16, function()
        camMode = "orbit"
        camAngle = camAngle + math.pi * 0.7
        camDist  = 20
        tweenFOV(65, 0.3)
        flash(255,255,100, 0.15)
        punchCam(1.2)
        shockwave(Color3.fromRGB(255,255,80))
        singerDance()
        spawnLaserRing(5)
    end},
    {28.45, function()
        lightningFlash()
        colorShift(255,255,200)
        skyColor(80,60,0)
        doSuperBurst()
        camMode = "worm"; camDist = 22
        tweenFOV(76, 0.4)
    end},
    {33.33, function()
        zoomToFace("singer", 30, 0.5, 2.5)
        colorShift(255,100,80)
        skyColor(80,10,0)
        singerCheer()
        spawnLaserRing(6)
    end},
    {36.63, function()
        slamDown()
        camMode = "orbit"; camDist = 32
        tweenFOV(70, 0.5)
        colorShift(80,200,255)
        skyColor(0,40,80)
    end},
    {40.0, function()
        zoomToFace("player", 36, 0.5, 2.5)
        flash(255,200,255, 0.2)
        singerLaugh()
    end},
    {45.0, function()
        camMode = "face"; camDist = 9
        tweenFOV(58, 0.4)
        colorShift(255,180,100)
        spawnExplosiveCubes(10, singerHRP and singerHRP.Position)
        shockwave(Color3.fromRGB(255,180,100))
        singerDance()
    end},
    {50.0, function()
        camMode = "orbit"; camDist = 35
        tweenFOV(80, 0.5)
        colorShift(150,80,255)
        skyColor(40,0,80)
        doSuperBurst()
        singerRobot()
    end},
    {55.18, function()
        glitch(10, 2)
        flash(180,50,255, 0.25)
        camMode = "dramatic"; camDist = 20
        tweenFOV(65, 0.4)
        colorShift(200,80,255)
        skyColor(40,0,80)
        singerDance()
        burstParticles(singerParticles, 40)
        spawnLaserRing(4)
        task.delay(0.1,function() spawnLaserRing(3) end); task.delay(0.25,function() spawnLaserRing(7) end)
    end},
    {58.45, function()
        floatSinger(40, 3)
        camMode = "orbit"; camDist = 45
        tweenFOV(88, 0.6)
        colorShift(255,255,255)
        skyColor(60,60,80)
        spawnExplosiveCubes(20, singerHRP and singerHRP.Position)
        shockwave(Color3.fromRGB(255,255,255))
        spawnConfetti(40, singerHRP and singerHRP.Position)
        singerFlip()
    end},
    {1*60+5.73, function()
        zoomToFace("singer", 32, 0.5, 3)
        colorShift(255,150,200)
        skyColor(60,0,40)
        singerCheer()
        spawnLaserRing(8)
    end},
    {1*60+14.07, function()
        glitch(6, 1.5)
        floatSinger(30, 2.5)
        camMode = "top"
        tweenFOV(92, 0.5)
        colorShift(80,255,200)
        skyColor(0,60,40)
        spawnExplosiveCubes(15, singerHRP and singerHRP.Position)
        spawnLaserRing(10)
    end},
    {1*60+18.16, function()
        camMode = "orbit"; camDist = 24
        tweenFOV(70, 0.4)
        flash(200,255,80, 0.2)
        colorShift(200,255,150)
        skyColor(20,60,0)
        punchCam(1.5)
        singerPoint()
        spawnLaserRing(3)
    end},
    {1*60+25.25, function()
        glitch(5, 1.2)
        camMode = "dramatic"; camDist = 16
        tweenFOV(62, 0.4)
        colorShift(255,180,80)
        skyColor(80,40,0)
        shockwave(Color3.fromRGB(255,150,50))
        burstParticles(singerParticles, 30)
        singerLaugh()
    end},
    {1*60+32.90, function()
        lightningFlash()
        slamDown()
        zoomToFace("singer", 28, 0.4, 2.5)
        colorShift(255,80,80)
        skyColor(80,0,0)
        doSuperBurst()
        singerSalute()
    end},
    {2*60+11.68, function()
        camMode = "orbit"; camDist = 18
        tweenFOV(68, 0.4)
        flash(255,80,200, 0.3)
        colorShift(255,100,255)
        skyColor(60,0,60)
        singerDance()
        spawnLaserRing(5)
    end},
    {2*60+20.0, function()
        zoomToFace("player", 34, 0.5, 2.5)
        flash(200,150,255, 0.2)
        burstParticles(playerParticles, 25)
    end},
    {2*60+29.62, function()
        floatSinger(50, 3)
        glitch(12, 2.5)
        camMode = "top"
        tweenFOV(95, 0.6)
        colorShift(150,200,255)
        skyColor(0,20,60)
        spawnExplosiveCubes(25, singerHRP and singerHRP.Position)
        shockwave(Color3.fromRGB(150,200,255))
        burstParticles(singerParticles, 60)
        task.delay(0.1, function() spawnLaserRing(6) end)
        task.delay(0.3, function() spawnLaserRing(12) end)
    end},
    {2*60+37.95, function()
        lightningFlash()
        flash(255,255,255, 0.4)
        camMode = "orbit"; camDist = 40
        tweenFOV(85, 0.5)
        colorShift(255,255,255)
        skyColor(80,80,80)
        doSuperBurst()
        singerCheer()
        spawnLaserRing(10)
    end},
    {2*60+42.70, function()
        zoomToFace("singer", 30, 0.5, 3)
        colorShift(200,100,255)
        skyColor(40,0,60)
        singerRobot()
    end},
    {2*60+48.36, function()
        camMode = "orbit"; camDist = 50
        tweenFOV(90, 0.5)
        glitch(8, 2)
        colorShift(80,80,255)
        skyColor(0,0,80)
        doSuperBurst()
        spawnExplosiveCubes(30, singerHRP and singerHRP.Position)
        singerFlip()
        task.delay(0.1, function() spawnLaserRing(5) end)
        task.delay(0.25, function() spawnLaserRing(10) end)
        task.delay(0.4, function() spawnLaserRing(15) end)
    end},
}

local choreoIdx = 1
local lyricIdx  = 1

local sound     = PlayGitSound(AUDIO_URL, "ArigatoTokyo", 2, Camera)
local startTick = tick()
local started   = sound ~= nil

if not started then
    warn("[ArigatoShow] Falha ao carregar audio, continuando sem som")
    started = true
end

local pentaAngle = 0
local elapsed    = 0
local finished   = false
local conn

conn = RunService.RenderStepped:Connect(function(dt)
    if finished then return end

    elapsed = (sound and sound.Parent and pcall(function() return sound.IsPlaying end) and sound.IsPlaying)
        and sound.TimePosition
        or (tick() - startTick)

    pentaAngle = pentaAngle + dt * 0.9
    updatePentagon(pentaAngle)
    updateOrbit(elapsed)
    updateStars(elapsed)
    updateNebula(elapsed)
    updateShowLights(elapsed)

    if stagePlatform and singerHRP then
        local hue = (elapsed * 0.08) % 1
        stagePlatform.Color = Color3.fromHSV(hue, 1, 1)
        local pulse = 0.25 + math.abs(math.sin(elapsed * 3)) * 0.15
        stagePlatform.Transparency = pulse
    end

    cloneOrbitAngle = cloneOrbitAngle + dt * cloneOrbitSpeed
    if cloneHRP and singerHRP and singerHRP.Parent then
        local cx = math.cos(cloneOrbitAngle) * cloneOrbitRadius
        local cz = math.sin(cloneOrbitAngle) * cloneOrbitRadius
        local cy = math.sin(elapsed * 1.5) * 6 + 8
        cloneHRP.CFrame = CFrame.new(singerHRP.Position + Vector3.new(cx, cy, cz))
            * CFrame.Angles(0, -cloneOrbitAngle, math.sin(elapsed)*0.4)
    end

    camAngle = camAngle + dt * 0.15
    Camera.CFrame = Camera.CFrame:Lerp(getTargetCamCF(), 0.09)

    if sound and sound.Parent then
        pcall(function() sound.RollOffMaxDistance = 9999 end)
    end

    while lyricIdx <= #lyrics and lyrics[lyricIdx].time <= elapsed do
        lastLyricTime  = elapsed
        idleAnimPlaying = false
        showLyric(lyrics[lyricIdx])
        lyricIdx = lyricIdx + 1
    end

    while choreoIdx <= #choreo and choreo[choreoIdx][1] <= elapsed do
        task.spawn(choreo[choreoIdx][2])
        choreoIdx = choreoIdx + 1
    end

    checkIdleAnim(elapsed)

    if singerHRP and singerHRP.Parent and singerBasePos and not isFloating then
        local bob = CFrame.new(0, math.sin(elapsed*2)*0.02, 0)
            * CFrame.Angles(0, math.sin(elapsed*0.5)*0.01, math.sin(elapsed*2.5)*0.008)
        singerHRP.CFrame = singerBasePos * bob
    end

    local soundDone = false
    if sound and sound.Parent then
        pcall(function() soundDone = not sound.IsPlaying and elapsed > 5 end)
    else
        soundDone = tick() - startTick > 175
    end

    if soundDone then
        finished = true
        if conn then conn:Disconnect() end

        flash(255,255,255, 2)
        doSuperBurst()
        task.wait(0.8)

        TweenService:Create(cinemaTop, TweenInfo.new(1.5, Enum.EasingStyle.Quint), {Position = UDim2.new(-0.002,0,0,-(BAR_H+4))}):Play()
        TweenService:Create(cinemaBot, TweenInfo.new(1.5, Enum.EasingStyle.Quint), {Position = UDim2.new(-0.002,0,1,0)}):Play()
        TweenService:Create(lyricOuter, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
        TweenService:Create(colorCorrection, TweenInfo.new(2.5), {
            TintColor = Color3.new(1,1,1), Saturation = 0, Brightness = 0
        }):Play()
        TweenService:Create(Lighting, TweenInfo.new(2.5), {
            Ambient        = origAmbient,
            OutdoorAmbient = origOutdoor,
            Brightness     = origBrightness,
            ClockTime      = origClockTime,
            FogEnd         = origFogEnd,
            FogColor       = origFogColor,
        }):Play()
        tweenFOV(origFOV, 2)

        task.wait(2)

        pcall(function() sg:Destroy() end)
        pcall(function() mainFolder:Destroy() end)
        pcall(function() singer:Destroy() end)
        pcall(function() cloneChar:Destroy() end)
        pcall(function() sky:Destroy() end)
        pcall(function() bloom:Destroy() end)
        pcall(function() colorCorrection:Destroy() end)
        pcall(function() depthOfField:Destroy() end)
        pcall(function() sunRays:Destroy() end)
        pcall(function() blur:Destroy() end)

        Camera.CameraType  = Enum.CameraType.Custom
        Camera.FieldOfView = origFOV

        if playerHum then
            playerHum.WalkSpeed  = 16
            playerHum.JumpHeight = 7.2
        end
        if playerHRP then playerHRP.Anchored = false end

        pcall(function()
            for _, t in ipairs({
                Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Health,
                Enum.CoreGuiType.Backpack,   Enum.CoreGuiType.Chat,
            }) do StarterGui:SetCoreGuiEnabled(t, true) end
        end)
    end
end)
