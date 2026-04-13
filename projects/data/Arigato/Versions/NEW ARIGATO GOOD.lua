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

if singerHRP and playerHRP then
    local front = playerHRP.CFrame * CFrame.new(0, 0, -12)
    singerHRP.CFrame = CFrame.new(front.Position, playerHRP.Position)
    singerHRP.Anchored = true
end

if singerHum then
    local sc = {BodyHeightScale=3, BodyWidthScale=3, BodyDepthScale=3, HeadScale=3}
    for n, v in pairs(sc) do
        local obj = singerHum:FindFirstChild(n)
        if obj then obj.Value = v end
    end
end

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

local mainFolder = Instance.new("Folder", workspace)
mainFolder.Name = "_arigato_fx"

-- ── PENTÁGONO NAS COSTAS ──────────────────────────────────────────────────
-- Nas costas = CFrame.new(0, 0, N) onde N é POSITIVO (z+ = costas no sistema local Roblox com LookAt no jogador)
-- singerHRP olha para o jogador, então "atrás dele" = direção oposta à frente

local pentaFolder = Instance.new("Folder", mainFolder)
pentaFolder.Name  = "pentagon"
local pentaParts  = {}
local NUM_SIDES   = 5
local PENTA_RADIUS = 16
local PENTA_COLORS = {
    Color3.fromRGB(255,80,220),
    Color3.fromRGB(120,80,255),
    Color3.fromRGB(80,200,255),
    Color3.fromRGB(255,200,80),
    Color3.fromRGB(80,255,160),
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
    tr.Lifetime       = 0.12
    tr.MinLength      = 0
    tr.Color          = ColorSequence.new(PENTA_COLORS[i], Color3.fromRGB(255,255,255))
    tr.Transparency   = NumberSequence.new(0.3, 1)
    tr.LightEmission  = 1
    table.insert(pentaParts, p)
end

local function updatePentagon(angle)
    if not singerHRP or not singerHRP.Parent then return end
    -- singerHRP.CFrame olha para o jogador. 
    -- A direção Z local POSITIVA aponta para TRÁS do cantor (oposta ao LookVector).
    -- Usamos CFrame.new(0, 2, 10) = 10 studs para trás + 2 studs acima.
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
    end
end

-- ── ANEIS RGB ORBITANDO ───────────────────────────────────────────────────
local orbitFolder = Instance.new("Folder", mainFolder)
orbitFolder.Name  = "orbit"
local orbitParts  = {}
local NUM_ORBIT   = 12
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
end

-- ── CUBOS EXPLOSIVOS ──────────────────────────────────────────────────────
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

-- ── SHOCKWAVE RING ────────────────────────────────────────────────────────
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

-- ── PARTICLE EMITTERS ─────────────────────────────────────────────────────
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

-- ── ANIMAÇÕES DO CANTOR ───────────────────────────────────────────────────
local EMOTE_IDS = {
    dance = "rbxassetid://507771019",
    wave  = "rbxassetid://507770718",
    point = "rbxassetid://507770453",
    cheer = "rbxassetid://507770677",
    laugh = "rbxassetid://507770818",
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

local function singerDance()  playSingerAnim(EMOTE_IDS.dance) end
local function singerCheer()  playSingerAnim(EMOTE_IDS.cheer) end
local function singerPoint()  playSingerAnim(EMOTE_IDS.point) end
local function singerLaugh()  playSingerAnim(EMOTE_IDS.laugh) end
local function singerWave()   playSingerAnim(EMOTE_IDS.wave)  end
local function singerRandom()
    local list = {EMOTE_IDS.dance, EMOTE_IDS.cheer, EMOTE_IDS.wave, EMOTE_IDS.laugh}
    playSingerAnim(list[math.random(1, #list)])
end

singerDance()

-- ── GUI ───────────────────────────────────────────────────────────────────
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

local cinemaTop = makeFrame(sg, {
    Size = UDim2.new(1,0,0,100),
    Position = UDim2.new(0,0,0,-100),
    BackgroundColor3 = Color3.new(0,0,0),
    ZIndex = 10,
})
local cinemaBot = makeFrame(sg, {
    Size = UDim2.new(1,0,0,100),
    Position = UDim2.new(0,0,1,0),
    BackgroundColor3 = Color3.new(0,0,0),
    ZIndex = 10,
})

TweenService:Create(cinemaTop, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play()
TweenService:Create(cinemaBot, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,1,-100)}):Play()

-- container de legenda com borda animada
local lyricOuter = makeFrame(sg, {
    Size = UDim2.new(0.72, 0, 0, 92),
    Position = UDim2.new(0.14, 0, 1, -205),
    BackgroundColor3 = Color3.fromRGB(60, 0, 120),
    BackgroundTransparency = 0.35,
    ZIndex = 9,
})
local lyricCorner = Instance.new("UICorner", lyricOuter)
lyricCorner.CornerRadius = UDim.new(0, 14)
local lyricStroke = Instance.new("UIStroke", lyricOuter)
lyricStroke.Color     = Color3.fromRGB(200, 100, 255)
lyricStroke.Thickness = 2.5
lyricStroke.Transparency = 0.2

local lyricLabel = Instance.new("TextLabel", lyricOuter)
lyricLabel.Size               = UDim2.new(1,-24,0,50)
lyricLabel.Position           = UDim2.new(0,12,0,4)
lyricLabel.BackgroundTransparency = 1
lyricLabel.TextColor3         = Color3.new(1,1,1)
lyricLabel.TextStrokeTransparency = 0.15
lyricLabel.TextStrokeColor3   = Color3.fromRGB(160,0,255)
lyricLabel.Font               = Enum.Font.GothamBold
lyricLabel.TextSize           = 28
lyricLabel.TextXAlignment     = Enum.TextXAlignment.Center
lyricLabel.Text               = ""
lyricLabel.ZIndex             = 11
lyricLabel.ClipsDescendants   = false

local subLabel = Instance.new("TextLabel", lyricOuter)
subLabel.Size               = UDim2.new(1,-24,0,30)
subLabel.Position           = UDim2.new(0,12,0,56)
subLabel.BackgroundTransparency = 1
subLabel.TextColor3         = Color3.fromRGB(220, 185, 255)
subLabel.TextStrokeTransparency = 0.4
subLabel.Font               = Enum.Font.Gotham
subLabel.TextSize            = 17
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

pcall(function()
    for _, t in ipairs({
        Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Health,
        Enum.CoreGuiType.Backpack,   Enum.CoreGuiType.Chat,
        Enum.CoreGuiType.EmotesMenu
    }) do StarterGui:SetCoreGuiEnabled(t, false) end
end)

-- ── CÂMERA STATE ──────────────────────────────────────────────────────────
Camera.CameraType  = Enum.CameraType.Scriptable
Camera.FieldOfView = 70

local camAngle  = math.pi
local camDist   = 22
local camHeight = 10
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

local function getTargetCamCF()
    local target   = getTargetPos()
    local headOff  = Vector3.new(0, camHeight, 0)

    if camMode == "orbit" then
        return CFrame.lookAt(
            target + headOff + Vector3.new(math.cos(camAngle)*camDist, camHeight*0.1, math.sin(camAngle)*camDist),
            target + headOff
        )
    elseif camMode == "close" then
        local hp = (singerHead and singerHead.Position or target) + Vector3.new(0, 2, 0)
        return CFrame.lookAt(
            hp + Vector3.new(math.cos(camAngle)*camDist, 1, math.sin(camAngle)*camDist),
            hp
        )
    elseif camMode == "face" then
        local hp = (singerHead and singerHead.Position or target) + Vector3.new(0, 2, 0)
        return CFrame.lookAt(
            hp + Vector3.new(math.cos(camAngle)*4, 0.5, math.sin(camAngle)*4),
            hp
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
        local hp = (singerHead and singerHead.Position or target) + Vector3.new(0, 2, 0)
        return CFrame.lookAt(
            hp + Vector3.new(math.cos(camAngle)*camDist, -3, math.sin(camAngle)*camDist),
            hp + Vector3.new(0, 6, 0)
        )
    elseif camMode == "worm" then
        return CFrame.lookAt(
            target + Vector3.new(math.cos(camAngle)*camDist, -5, math.sin(camAngle)*camDist),
            target + Vector3.new(0, 8, 0)
        )
    end
    return Camera.CFrame
end

-- ── EFEITOS ───────────────────────────────────────────────────────────────
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

local function skyColor(r, g, b)
    TweenService:Create(Lighting, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {
        Ambient  = Color3.fromRGB(r//3, g//3, b//3),
        FogColor = Color3.fromRGB(r//2, g//2, b//2),
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

local function floatSinger(height, duration)
    if not singerHRP then return end
    singerHRP.Anchored = false
    local bv = Instance.new("BodyVelocity", singerHRP)
    bv.Velocity = Vector3.new(0, height/duration, 0)
    bv.MaxForce = Vector3.new(0, 9e9, 0)
    task.delay(duration, function()
        pcall(function() bv:Destroy() end)
        if singerHRP and singerHRP.Parent then singerHRP.Anchored = true end
    end)
end

local function slamDown()
    if not singerHRP then return end
    singerHRP.Anchored = false
    local bv = Instance.new("BodyVelocity", singerHRP)
    bv.Velocity = Vector3.new(0, -80, 0)
    bv.MaxForce = Vector3.new(0, 9e9, 0)
    task.delay(0.35, function()
        pcall(function() bv:Destroy() end)
        if singerHRP and singerHRP.Parent then singerHRP.Anchored = true end
        flash(255,180,80, 0.3)
        glitch(8, 2)
        shockwave(Color3.fromRGB(255,200,80))
        spawnExplosiveCubes(8, singerHRP and singerHRP.Position)
        burstParticles(singerParticles, 30)
        punchCam(1.5)
    end)
end

local function doSuperBurst()
    local pos = singerHRP and singerHRP.Position or Vector3.new(0,10,0)
    spawnExplosiveCubes(20, pos)
    shockwave(Color3.fromRGB(255,80,220))
    task.delay(0.15, function() shockwave(Color3.fromRGB(80,200,255)) end)
    burstParticles(singerParticles, 60)
    burstParticles(playerParticles, 30)
    lightningFlash()
    punchCam(2)
end

-- ── LYRIC DISPLAY MELHORADO ───────────────────────────────────────────────
local function showLyric(entry)
    lyricLabel.Text = entry.jp
    subLabel.Text   = entry.en

    if singerHead and singerHead.Parent and entry.jp ~= "" then
        pcall(function() ChatService:Chat(singerHead, entry.jp) end)
    end

    lyricLabel.TextSize  = 34
    lyricLabel.TextColor3 = Color3.fromHSV(math.random(), 1, 1)

    TweenService:Create(lyricLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        TextSize   = 28,
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

-- ── IDLE SEM LEGENDA ─────────────────────────────────────────────────────
local lastLyricTime  = 0
local idleAnimPlaying = false

local function checkIdleAnim(elapsed)
    if elapsed - lastLyricTime > 4 and not idleAnimPlaying then
        idleAnimPlaying = true
        local rng = math.random(1, 5)
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
        else
            singerWave()
            shockwave(Color3.fromRGB(255,200,80))
        end
        task.delay(3.8, function() idleAnimPlaying = false end)
    end
end

-- ── COREOGRAPHY ───────────────────────────────────────────────────────────
local choreo = {
    {0, function()
        singerDance()
        tweenFOV(65, 1.5)
        colorShift(200,150,255)
    end},
    {9.22, function()
        zoomToFace("singer", 38, 0.6, 2.5)
        colorShift(255,150,255)
        skyColor(60,0,80)
        singerDance()
        punchCam()
    end},
    {13.15, function()
        floatSinger(20, 2)
        camMode = "dramatic"; camDist = 18
        tweenFOV(60, 0.5)
        lightningFlash()
        singerCheer()
        shockwave(Color3.fromRGB(200,80,255))
        burstParticles(singerParticles, 25)
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
    end},
    {21.07, function()
        zoomToFace("singer", 34, 0.5, 3)
        colorShift(200,255,150)
        skyColor(0,60,20)
        singerPoint()
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
        camMode = "face"; camDist = 6
        tweenFOV(55, 0.4)
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
    end},
    {58.45, function()
        floatSinger(40, 3)
        camMode = "orbit"; camDist = 45
        tweenFOV(88, 0.6)
        colorShift(255,255,255)
        skyColor(60,60,80)
        spawnExplosiveCubes(20, singerHRP and singerHRP.Position)
        shockwave(Color3.fromRGB(255,255,255))
    end},
    {1*60+5.73, function()
        zoomToFace("singer", 32, 0.5, 3)
        colorShift(255,150,200)
        skyColor(60,0,40)
        singerCheer()
    end},
    {1*60+14.07, function()
        glitch(6, 1.5)
        floatSinger(30, 2.5)
        camMode = "top"
        tweenFOV(92, 0.5)
        colorShift(80,255,200)
        skyColor(0,60,40)
        spawnExplosiveCubes(15, singerHRP and singerHRP.Position)
    end},
    {1*60+18.16, function()
        camMode = "orbit"; camDist = 24
        tweenFOV(70, 0.4)
        flash(200,255,80, 0.2)
        colorShift(200,255,150)
        skyColor(20,60,0)
        punchCam(1.5)
        singerPoint()
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
    end},
    {2*60+11.68, function()
        camMode = "orbit"; camDist = 18
        tweenFOV(68, 0.4)
        flash(255,80,200, 0.3)
        colorShift(255,100,255)
        skyColor(60,0,60)
        singerDance()
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
    end},
    {2*60+42.70, function()
        zoomToFace("singer", 30, 0.5, 3)
        colorShift(200,100,255)
        skyColor(40,0,60)
    end},
    {2*60+48.36, function()
        camMode = "orbit"; camDist = 50
        tweenFOV(90, 0.5)
        glitch(8, 2)
        colorShift(80,80,255)
        skyColor(0,0,80)
        doSuperBurst()
        spawnExplosiveCubes(30, singerHRP and singerHRP.Position)
    end},
}

local choreoIdx = 1
local lyricIdx  = 1

-- ── AUDIO ─────────────────────────────────────────────────────────────────
local sound     = PlayGitSound(AUDIO_URL, "ArigatoTokyo", 2, singerHRP or workspace)
local startTick = tick()
local started   = sound ~= nil

if not started then
    warn("[ArigatoShow] Falha ao carregar audio, continuando sem som")
    started = true
end

-- ── MAIN RENDER LOOP ──────────────────────────────────────────────────────
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

    camAngle = camAngle + dt * 0.15
    Camera.CFrame = Camera.CFrame:Lerp(getTargetCamCF(), 0.09)

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

    if singerHRP and singerHRP.Parent then
        local bob = CFrame.new(0, math.sin(elapsed*2)*0.02, 0)
            * CFrame.Angles(0, math.sin(elapsed*0.5)*0.01, math.sin(elapsed*2.5)*0.008)
        singerHRP.CFrame = singerHRP.CFrame * bob
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

        TweenService:Create(cinemaTop, TweenInfo.new(1.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0,0,0,-100)}):Play()
        TweenService:Create(cinemaBot, TweenInfo.new(1.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0,0,1,0)}):Play()
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
        pcall(function() sky:Destroy() end)
        pcall(function() bloom:Destroy() end)
        pcall(function() colorCorrection:Destroy() end)
        pcall(function() depthOfField:Destroy() end)

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
