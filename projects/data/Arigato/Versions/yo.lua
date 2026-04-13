Text) end
    if math.random(1, 3) == 1 then spawnConfetti(12, singerHRP and singerHRP.Position) end

    local hue = math.random()

    lyricLabel.TextColor3 = Color3.new(1, 1, 1)
    lyricLabel.TextSize   = 36
    lyricLabel.Rotation   = math.random(-4, 4)

    TweenService:Create(lyricLabel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextSize = 28,
        TextColor3 = Color3.new(1, 1, 1),
        Rotation = 0,
    }):Play()

    subLabel.TextColor3 = Color3.fromRGB(215, 175, 255)
    subLabel.TextSize   = 20
    TweenService:Create(subLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
        TextSize   = 16,
        TextColor3 = Color3.fromRGB(215, 175, 255),
    }):Play()

    TweenService:Create(lyricOuter, TweenInfo.new(0.06), {
        BackgroundTransparency = 0.04,
        Size = UDim2.new(0.68, 0, 0, 80),
    }):Play()
    task.delay(0.4, function()
        TweenService:Create(lyricOuter, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
            BackgroundTransparency = 0.4,
            Size = UDim2.new(0.65, 0, 0, 72),
        }):Play()
    end)

    TweenService:Create(lyricStroke, TweenInfo.new(0.05), {
        Color = Color3.fromHSV(hue, 1, 1), Thickness = 4,
    }):Play()
    task.delay(0.45, function()
        TweenService:Create(lyricStroke, TweenInfo.new(0.35), {
            Color = Color3.fromRGB(210, 80, 255), Thickness = 2.8,
        }):Play()
    end)

    TweenService:Create(blur, TweenInfo.new(0.05), {Size = 5}):Play()
    task.delay(0.12, function()
        TweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = 0}):Play()
    end)
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
local lastBarBeat = 0

RunService.RenderStepped:Connect(function(dt)
    if shared.G.finished then return end
    local t = shared.G.elapsed or 0
    local beatInterval = 60 / shared.G.BPM

    if tick() - lastBarBeat >= beatInterval then
        lastBarBeat = tick()

        if shared.G.beatCount % 2 == 0 then
            local roll = math.random(1, 3)

            if roll == 1 then
                TweenService:Create(cinemaTop, TweenInfo.new(0.07, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                    Position = UDim2.new(-0.002, 0, 0, -(BAR_H + 4))
                }):Play()
                TweenService:Create(cinemaBot, TweenInfo.new(0.07, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                    Position = UDim2.new(-0.002, 0, 1, 0)
                }):Play()
                task.delay(0.13, function()
                    TweenService:Create(cinemaTop, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Position = UDim2.new(-0.002, 0, 0, -2)
                    }):Play()
                    TweenService:Create(cinemaBot, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Position = UDim2.new(-0.002, 0, 1, -(BAR_H + 2))
                    }):Play()
                end)

            elseif roll == 2 then
                TweenService:Create(cinemaTop, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                    Position = UDim2.new(-0.002, 0, 0, -(BAR_H + 4))
                }):Play()
                TweenService:Create(cinemaBot, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                    Position = UDim2.new(-0.002, 0, 1, 0)
                }):Play()
                task.delay(beatInterval * 1.8, function()
                    TweenService:Create(cinemaTop, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Position = UDim2.new(-0.002, 0, 0, -2)
                    }):Play()
                    TweenService:Create(cinemaBot, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Position = UDim2.new(-0.002, 0, 1, -(BAR_H + 2))
                    }):Play()
                end)

            else
                TweenService:Create(cinemaTop, TweenInfo.new(0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                    Position = UDim2.new(-0.002, 0, 0, -(BAR_H + 4))
                }):Play()
                TweenService:Create(cinemaBot, TweenInfo.new(0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                    Position = UDim2.new(-0.002, 0, 1, 0)
                }):Play()
                task.delay(0.06, function()
                    TweenService:Create(cinemaTop, TweenInfo.new(0.06, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(-0.002, 0, 0, -2)
                    }):Play()
                    TweenService:Create(cinemaBot, TweenInfo.new(0.06, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(-0.002, 0, 1, -(BAR_H + 2))
                    }):Play()
                end)
                task.delay(0.18, function()
                    TweenService:Create(cinemaTop, TweenInfo.new(0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                        Position = UDim2.new(-0.002, 0, 0, -(BAR_H + 4))
                    }):Play()
                    TweenService:Create(cinemaBot, TweenInfo.new(0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                        Position = UDim2.new(-0.002, 0, 1, 0)
                    }):Play()
                    task.delay(0.06, function()
                        TweenService:Create(cinemaTop, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                            Position = UDim2.new(-0.002, 0, 0, -2)
                        }):Play()
                        TweenService:Create(cinemaBot, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                            Position = UDim2.new(-0.002, 0, 1, -(BAR_H + 2))
                        }):Play()
                    end)
                end)
            end
        end
    end
end)

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
    checkIdleAnim(shared.G.elapsed)
    updateLyricBoards(shared.G.elapsed)
        
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
