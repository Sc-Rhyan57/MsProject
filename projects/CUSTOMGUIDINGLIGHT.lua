local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local MainUI = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainUI")
local MainGame = require(MainUI:WaitForChild("Initiator"):WaitForChild("Main_Game"))
local HealthScript = MainUI.Initiator.Main_Game:WaitForChild("Health")
local Death = MainUI:WaitForChild("Death")

local function resetDeathUI()
    Death.Visible = false
    Death.ImageTransparency = 1
    Death.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Death.BackgroundTransparency = 1
    
    Death.Hodler.Visible = true
    Death.Hodler.Position = UDim2.new(0.5, 0, 0.5, 0)
    Death.Hodler.Rotation = 0
    
    Death.Hodler.Label.Visible = false
    Death.Hodler.Label.ImageTransparency = 1
    Death.Hodler.Label.Size = UDim2.new(0.5, 0, 0.5, 0)
    Death.Hodler.Label.Position = UDim2.new(0.5, 0, 0.5, 0)
    Death.Hodler.Label.Label.ImageTransparency = 1
    
    Death.Hodler.GlitchLabel.Visible = false
    Death.Hodler.GlitchLabel.ImageTransparency = 1
    Death.Hodler.GlitchLabel.ImageRectOffset = Vector2.new(0, 0)
    
    Death.Static.Visible = true
    Death.Static.BackgroundTransparency = 1
    Death.Static.ImageTransparency = 1
    Death.Static.Position = UDim2.new(0, 0, 0, 0)
    Death.Static.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Death.Static.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Death.Static.Static.Visible = true
    Death.Static.Static.ImageTransparency = 1
    
    Death.GlitchStatic.Visible = false
    Death.GlitchStatic.ImageTransparency = 1
    Death.GlitchStatic.BackgroundTransparency = 1
    Death.GlitchStatic.Position = UDim2.new(0, 0, 0, 0)
    Death.GlitchStatic.Rotation = 0
    Death.GlitchStatic.Static.Visible = false
    Death.GlitchStatic.Static.ImageTransparency = 1
    Death.GlitchStatic.Static.Position = UDim2.new(0, 0, 0, 0)
    Death.GlitchStatic.Static.Rotation = 0
    
    Death.HelpfulDialogue.Visible = false
    Death.HelpfulDialogue.TextTransparency = 1
    Death.HelpfulDialogue.Position = UDim2.new(0.5, 0, 0.42, 0)
    Death.HelpfulDialogue.Rotation = 0
    
    Death.GlitchDialogue.Visible = false
    Death.GlitchDialogue.TextTransparency = 1
    Death.GlitchDialogue.Position = UDim2.new(0.5, 0, 0.5, 0)
    Death.GlitchDialogue.Rotation = 0

    if HealthScript:FindFirstChild("Death") then HealthScript.Death:Stop() end
    if HealthScript:FindFirstChild("DeathGlitch") then HealthScript.DeathGlitch:Stop() end
    if HealthScript:FindFirstChild("Music") then
        for _, sound in ipairs(HealthScript.Music:GetChildren()) do
            sound:Stop()
        end
    end
end

local function playFakeGuidingLight()
    if shared.GUIDINGRUNNING then return end
    shared.GUIDINGRUNNING = true

    local success, err = pcall(function()
        local cfg = shared.config or {}
        local lightColor = cfg.color or "Blue"
        if string.lower(lightColor) == "red" then lightColor = "Rush" end

        local defaultTexts = {"Roblox", "Just", "Wanna", "Have", "Fun"}
        local finalTexts = {}
        if type(shared.texts) == "table" then
            local i = 1
            while shared.texts[i] do
                table.insert(finalTexts, shared.texts[i])
                i = i + 1
            end
        end
        if #finalTexts == 0 then finalTexts = defaultTexts end

        resetDeathUI()

        MainGame.stopcam = true
        Camera.CameraType = Enum.CameraType.Scriptable

        local oldLighting = {}
        for _, prop in ipairs({"Ambient", "Brightness", "ExposureCompensation", "FogEnd", "FogStart"}) do
            oldLighting[prop] = Lighting[prop]
        end

        if lightColor == "Glitch" then
            if HealthScript:FindFirstChild("DeathGlitch") then HealthScript.DeathGlitch:Play() end
            
            Death.Visible = true
            Death.ImageTransparency = 0
            Death.ImageColor3 = Color3.fromRGB(0, 0, 0)
            Death.BackgroundTransparency = 1
            Death.Hodler.Label.Visible = false
            
            Lighting.Ambient = Color3.fromRGB(0, 0, 0)
            Lighting.Brightness = 0
            Lighting.ExposureCompensation = 0.4

            local v15 = HealthScript.Music:FindFirstChild("Glitch")
            local StaticSound = v15 and v15:FindFirstChild("Static")
            local EndSound = v15 and v15:FindFirstChild("End")

            if v15 then
                v15 = v15:Clone()
                v15.Parent = SoundService
                v15.Volume = 1
                if EndSound then EndSound.Volume = 0 end
                v15:Play()
            end

            TweenService:Create(Death, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                ImageTransparency = 1,
                ImageColor3 = Color3.fromRGB(39, 0, 40)
            }):Play()
            TweenService:Create(Death.Static, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                ImageTransparency = 1,
                BackgroundTransparency = 1,
                ImageColor3 = Color3.fromRGB(255, 59, 235),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            }):Play()
            TweenService:Create(Death.Static.Static, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                ImageTransparency = 1,
                ImageColor3 = Color3.fromRGB(255, 0, 251)
            }):Play()

            Death.Hodler.GlitchLabel.Visible = true
            Death.GlitchStatic.Visible = true
            Death.GlitchStatic.ImageTransparency = 0
            Death.GlitchStatic.BackgroundTransparency = 0
            Death.GlitchStatic.Static.Visible = true
            Death.GlitchStatic.Static.ImageTransparency = 0

            local v4 = true
            task.spawn(function()
                while v4 do
                    task.wait()
                    Death.GlitchStatic.Position = UDim2.new(math.random(30, 70) / 100, 0, math.random(30, 70) / 100, 0)
                    Death.GlitchStatic.Rotation = math.random(0, 180)
                    Death.GlitchStatic.Static.Position = UDim2.new(math.random(30, 70) / 100, 0, math.random(30, 70) / 100, 0)
                    Death.GlitchStatic.Static.Rotation = math.random(0, 180)
                end
            end)

            Death.Hodler.GlitchLabel.ImageTransparency = 0
            task.wait(0.2)
            Death.Hodler.Label.Visible = false
            task.wait(0.3)

            for k = 1, 6 do
                Death.Hodler.GlitchLabel.ImageRectOffset = Vector2.new(k * 128, 0)
                task.wait(0.1)
            end

            Death.Hodler.Visible = false

            local v5 = Random.new()
            local clicked = false
            local inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
                if not gpe and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    clicked = true
                end
            end)

            for i, text in ipairs(finalTexts) do
                if text == ">" then
                    Death.GlitchDialogue.Visible = false
                    if v15 then v15:Pause() end
                    if StaticSound then
                        StaticSound = StaticSound:Clone()
                        StaticSound.Parent = SoundService
                        StaticSound.Volume = 1
                        StaticSound:Resume()
                        StaticSound.TimePosition = v5:NextNumber(0, 10)
                    end
                    Death.GlitchStatic.ImageTransparency = 1
                    Death.GlitchStatic.Static.Visible = false
                    Death.GlitchDialogue.TextSize = 38
                    task.wait(v5:NextNumber(1, 2))
                    clicked = false
                elseif text == "<" then
                    Death.GlitchDialogue.Visible = false
                    task.wait(v5:NextNumber(0.3, 0.6))
                    if v15 then v15:Resume() end
                    if StaticSound then StaticSound:Pause() end
                    Death.GlitchStatic.ImageTransparency = 0
                    Death.GlitchStatic.Static.Visible = true
                    Death.GlitchDialogue.TextSize = 30
                    clicked = false
                else
                    Death.GlitchDialogue.Text = text
                    Death.GlitchDialogue.TextTransparency = 0
                    Death.GlitchDialogue.Visible = true

                    local waitTime = 5 + utf8.len(text) / 30
                    if i == 1 or clicked then
                        task.wait(0.5)
                    else
                        task.wait(0.1)
                    end
                    
                    clicked = false
                    local startTick = tick()
                    while task.wait() do
                        if startTick + waitTime <= tick() or clicked then
                            break
                        end
                    end

                    local fadeTime = clicked and 0.25 or 0.4
                    Death.GlitchDialogue.TextTransparency = 1
                    task.wait(fadeTime + 0.01)
                end
            end

            inputConn:Disconnect()
            v4 = false

            if StaticSound and StaticSound.Playing then
                TweenService:Create(Death.GlitchStatic, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                    ImageTransparency = 1, BackgroundTransparency = 1, ImageColor3 = Color3.fromRGB(212, 0, 255)
                }):Play()
                TweenService:Create(Death, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                    ImageTransparency = 1, ImageColor3 = Color3.fromRGB(217, 0, 255)
                }):Play()
                if StaticSound then StaticSound:Stop() end
            else
                if v15 then
                    TweenService:Create(v15, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Volume = 0 }):Play()
                end
                if EndSound then
                    local endClone = EndSound:Clone()
                    endClone.Parent = SoundService
                    endClone.Volume = 1
                    endClone:Play()
                    endClone.TimePosition = 55
                end
                TweenService:Create(Death.GlitchStatic, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                    ImageTransparency = 1, BackgroundTransparency = 1, ImageColor3 = Color3.fromRGB(212, 0, 255)
                }):Play()
                TweenService:Create(Death, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                    ImageTransparency = 1, ImageColor3 = Color3.fromRGB(217, 0, 255)
                }):Play()
            end

            task.wait(1)
            if v15 then v15:Destroy() end
            if StaticSound then StaticSound:Destroy() end
        else
            if HealthScript:FindFirstChild("DeathGlitch") then HealthScript.DeathGlitch:Stop() end
            if HealthScript:FindFirstChild("Death") then HealthScript.Death:Play() end
            
            Death.Hodler.GlitchLabel.Visible = false
            Death.GlitchStatic.Visible = false
            Death.GlitchStatic.ImageTransparency = 1
            Death.GlitchStatic.BackgroundTransparency = 1
            Death.GlitchStatic.Static.Visible = false
            Death.GlitchStatic.Static.ImageTransparency = 1
            Death.GlitchDialogue.Visible = false
            Death.GlitchDialogue.TextTransparency = 1

            local disabledCCEs = {}
            for _, v in ipairs(Camera:GetChildren()) do
                if v:IsA("ColorCorrectionEffect") and v.Enabled then
                    v.Enabled = false
                    table.insert(disabledCCEs, v)
                end
            end
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("ColorCorrectionEffect") and v.Enabled and v.Name ~= "MainColorCorrection" and v.Name ~= "OxygenCC" and v.Name ~= "XBoxColor" then
                    v.Enabled = false
                    table.insert(disabledCCEs, v)
                end
            end
            
            Lighting.Ambient = Color3.fromRGB(0, 0, 0)
            Lighting.Brightness = 0
            Lighting.ExposureCompensation = 0.4
            Lighting.FogEnd = 1000
            Lighting.FogStart = 1000
            
            local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
            local oldDensity = Atmosphere and Atmosphere.Density or 0.5
            if Atmosphere then Atmosphere.Density = 0 end
            
            local ColorCorrectionEffect = Instance.new("ColorCorrectionEffect")
            ColorCorrectionEffect.Contrast = 0.1
            ColorCorrectionEffect.Parent = Camera
            
            local v15 = HealthScript.Music:FindFirstChild(lightColor)
            if v15 then
                v15 = v15:Clone()
                v15.Parent = SoundService
                v15.Volume = 1
                local EndSound = v15:FindFirstChild("End")
                if EndSound then EndSound.Volume = 0 end
                v15:Play()
            end
            
            local t2 = {
                Color3.fromRGB(19, 48, 57), Color3.fromRGB(55, 235, 255), Color3.fromRGB(42, 151, 175),
                Color3.fromRGB(4, 16, 30), Color3.fromRGB(201, 237, 255), Color3.fromRGB(124, 209, 255),
                Color3.fromRGB(0, 141, 206), Color3.fromRGB(158, 239, 255)
            }
            if lightColor == "Yellow" then
                t2 = {
                    Color3.fromRGB(57, 42, 17), Color3.fromRGB(255, 242, 53), Color3.fromRGB(175, 142, 44),
                    Color3.fromRGB(30, 17, 4), Color3.fromRGB(255, 253, 174), Color3.fromRGB(255, 239, 117),
                    Color3.fromRGB(206, 155, 0), Color3.fromRGB(255, 243, 152)
                }
            elseif lightColor == "Rush" then
                t2 = {
                    Color3.fromRGB(28, 19, 57), Color3.fromRGB(128, 116, 255), Color3.fromRGB(122, 98, 175),
                    Color3.fromRGB(21, 17, 30), Color3.fromRGB(215, 203, 255), Color3.fromRGB(200, 174, 255),
                    Color3.fromRGB(143, 119, 206), Color3.fromRGB(213, 196, 255)
                }
            end
            
            local v16 = ReplicatedStorage.Misc["DeathBackground" .. lightColor]:Clone()
            v16.Parent = Camera
            
            local v17 = ReplicatedStorage.PlayerRigs:FindFirstChild(LocalPlayer.Name)
            if v17 then
                local v18 = v17:Clone()
                local mainPart = v16:WaitForChild("MainPart")
                local charAttachBelow = mainPart:WaitForChild("CharAttachBelow")
                local charAttach = mainPart:WaitForChild("CharAttach")
                v18:PivotTo(charAttachBelow.WorldCFrame)
                v18.Parent = v16
                
                TweenService:Create(v18.PrimaryPart, TweenInfo.new(6, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                    CFrame = charAttach.WorldCFrame
                }):Play()
                
                pcall(function()
                    require(ReplicatedStorage.ModulesClient.ClientAccessories)(v18)
                end)
                
                local hum = v18:WaitForChild("Humanoid")
                local anim = hum:FindFirstChildOfClass("Animator") or hum
                local swimAnim = HealthScript:WaitForChild("SwimAnimation")
                if anim and swimAnim then
                    local track = anim:LoadAnimation(swimAnim)
                    track:Play(0, 1, 1)
                end
            end
            
            local camAttach = v16.MainPart:WaitForChild("CamAttach")
            local startPos = camAttach.WorldCFrame * CFrame.new(0, 0, 20)
            local endPos = camAttach.WorldCFrame
            
            local oldFOV = Camera.FieldOfView
            Camera.FieldOfView = 45
            Camera.CFrame = startPos
            
            TweenService:Create(Camera, TweenInfo.new(6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                FieldOfView = 45,
                CFrame = endPos
            }):Play()
            
            Death.HelpfulDialogue.TextColor3 = t2[8]
            TweenService:Create(Death.Static, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 1, ImageTransparency = 1,
                BackgroundColor3 = Color3.fromRGB(0, 0, 0), ImageColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
            TweenService:Create(Death.Static.Static, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                ImageTransparency = 1
            }):Play()
            
            TweenService:Create(Death, TweenInfo.new(4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                ImageTransparency = 1, ImageColor3 = Color3.fromRGB(0, 0, 0)
            }):Play()
            
            TweenService:Create(Death.Hodler.Label, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                ImageTransparency = 1, ImageColor3 = t2[5]
            }):Play()
            
            TweenService:Create(Death.Hodler.Label.Label, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                ImageTransparency = 0, ImageColor3 = t2[6]
            }):Play()
            
            task.wait(1)
            TweenService:Create(Camera, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = 45 }):Play()
            TweenService:Create(Death.Hodler.Label.Label, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                ImageTransparency = 1, ImageColor3 = t2[7]
            }):Play()
            
            task.wait(0.5)
            TweenService:Create(Death.Hodler.Label, TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                Size = UDim2.new(3, 0, 3, 0)
            }):Play()
            
            Death.HelpfulDialogue.TextTransparency = 1
            Death.HelpfulDialogue.Visible = true
            
            task.wait(1)
            TweenService:Create(Camera, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = 45 }):Play()
            
            local clicked = false
            local inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
                if not gpe and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    clicked = true
                end
            end)
            
            for i, text in ipairs(finalTexts) do
                Death.HelpfulDialogue.Text = text
                if clicked then
                    Death.HelpfulDialogue.TextTransparency = 0
                else
                    TweenService:Create(Death.HelpfulDialogue, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        TextTransparency = 0
                    }):Play()
                end
                
                local waitTime = 5 + utf8.len(text) / 30
                if i == 1 or clicked then
                    task.wait(0.5)
                else
                    task.wait(0.1)
                end
                
                clicked = false
                local startTick = tick()
                while task.wait() do
                    if startTick + waitTime <= tick() or clicked then
                        break
                    end
                end
                
                local fadeTime = clicked and 0.25 or 0.4
                TweenService:Create(Death.HelpfulDialogue, TweenInfo.new(fadeTime, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    TextTransparency = 1
                }):Play()
                task.wait(fadeTime + 0.01)
            end
            
            inputConn:Disconnect()
            
            if v15 then
                TweenService:Create(v15, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Volume = 0 }):Play()
                local EndSound = v15:FindFirstChild("End")
                if EndSound then
                    local endClone = EndSound:Clone()
                    endClone.Parent = SoundService
                    endClone.Volume = 1
                    endClone:Play()
                    endClone.TimePosition = 55
                end
            end
            
            TweenService:Create(Death, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, true), {
                ImageTransparency = 0, BackgroundTransparency = 0
            }):Play()
            
            task.wait(0.5)
            if v15 then v15:Destroy() end
            v16:Destroy()
            ColorCorrectionEffect:Destroy()
            
            for prop, val in pairs(oldLighting) do
                Lighting[prop] = val
            end
            
            if Atmosphere then
                Atmosphere.Density = oldDensity
            end
            
            for _, v in ipairs(disabledCCEs) do
                v.Enabled = true
            end
            
            Camera.CameraType = Enum.CameraType.Custom
            Camera.FieldOfView = oldFOV
        end

        MainGame.stopcam = false
        resetDeathUI()
    end)

    if not success then
        warn("Guiding Light Error: " .. tostring(err))
        MainGame.stopcam = false
        resetDeathUI()
    end

    shared.GUIDINGRUNNING = false
end

playFakeGuidingLight()
