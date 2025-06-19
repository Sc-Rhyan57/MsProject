local LocalPlayer = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

_G.msrhyan_config_sprint = _G.msrhyan_config_sprint or {
    -- ⏱️ DURAÇÃO DA STAMINA
    timetospeedexpire = 25, -- Tempo em segundos que a stamina dura durante o sprint (0 = infinita)
    
    -- ⏳ TEMPO DE COOLDOWN
    cooldowntime = 5, -- Tempo em segundos que você deve aguardar após a stamina acabar antes de poder usar novamente
    
    -- 🏃 VELOCIDADE DO SPRINT
    sprintspeed = 50, -- Velocidade de movimento durante o sprint (padrão do jogo é geralmente 16-20)
    
    -- ⚡ TRANSIÇÕES DE VELOCIDADE
    speedapplytime = 0.3, -- Tempo em segundos para acelerar até a velocidade máxima do sprint
    speedremovetime = 0.5, -- Tempo em segundos para desacelerar de volta à velocidade normal
    
    -- 🔋 RECUPERAÇÃO DA STAMINA
    staminarecovertime = 10, -- Tempo em segundos para a stamina se recuperar completamente de 0% para 100%
    
    -- ✨ EFEITOS VISUAIS
    effectfadetime = 0.2, -- Tempo em segundos para os efeitos visuais aparecerem/desaparecerem
    
    -- 💬 MENSAGENS DE STAMINA
    showstaminamessages = true, -- true = mostra mensagens quando stamina acaba, false = sem mensagens
    customstaminamessage = "SUA STAMINA ACABOU, AGUARDE %ds!", -- Mensagem personalizada (%ds será substituído pelo tempo)
    
    -- 🎨 ATIVAÇÃO DOS EFEITOS
    enableeffects = true, -- true = ativa efeitos visuais na tela, false = sem efeitos
    
    -- 🌈 COR DOS EFEITOS VISUAIS
    effectcolor = {100, 200, 255}, -- Cor do efeito visual durante o sprint [R, G, B] (0-255 cada)
    
    -- 📊 COR DA BARRA DE STAMINA
    staminabarcolor = {0, 162, 255}, -- Cor da barra de stamina [R, G, B] (0-255 cada)
    
    -- 📷 CAMPO DE VISÃO (FOV)
    sprintfov = 120, -- Campo de visão durante o sprint (maior = mais amplo, sensação de velocidade)
    normalfov = 70, -- Campo de visão normal quando não está sprintando
    
    -- 🔄 USO DURANTE RECUPERAÇÃO
    usewhileloading = false, -- true = pode usar sprint com 10%+ de stamina mesmo recuperando, false = só após cooldown completo
}

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera
local Collision

local isSprinting = false
local sprintButton = nil
local sprintSpeedEffect = nil
local staminaBarGUI = nil
local staminaBarFrame = nil
local staminaBarFill = nil
local staminaLabel = nil
local originalSpeed = Humanoid.WalkSpeed
local originalFOV = Camera.FieldOfView
local sprintSpeed = _G.msrhyan_config_sprint.sprintspeed
local isOnCooldown = false
local cooldownTime = _G.msrhyan_config_sprint.cooldowntime
local staminaLeft = 1
local sprintKey = Enum.KeyCode.Q
local staminaUpdateConnection = nil
local fovUpdateConnection = nil
local isRecovering = false

local configFolder = "rhyan57/sprint/config"
local keyFile = configFolder .. "/keySprint"

local function msg(message, color)
    pcall(function()
        local mainGame = require(LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game)
        if color then
            mainGame.caption(string.format("<font color='%s'>%s</font>", color, message), true)
        else
            mainGame.caption(message, true)
        end
    end)
end

msg(" Made by Rhyan57")

local function SetupCollision()
    Collision = Character:FindFirstChild("Collision")
    if not Collision then
        for _, part in pairs(Character:GetChildren()) do
            if part:IsA("BasePart") and part.Name:lower():find("collision") then
                Collision = part
                break
            end
        end
    end
    
    if not Collision then
        Collision = RootPart
    end
    
    local CollisionClone = Collision:Clone()
    CollisionClone.CanCollide = false
    CollisionClone.Massless = true
    CollisionClone.CanQuery = false
    CollisionClone.Name = "CollisionClone"
    
    if CollisionClone:FindFirstChild("CollisionCrouch") then
        CollisionClone.CollisionCrouch:Destroy()
    end
    
    CollisionClone.Parent = Character
    
    task.spawn(function()
        while Character.Parent do
            if RootPart.Anchored then
                CollisionClone.Massless = true
                repeat task.wait() until not RootPart.Anchored
                task.wait(0.15)
            else
                CollisionClone.Massless = not CollisionClone.Massless
            end
            task.wait(0.24)
        end
    end)
end

local function CreateStaminaBar(isMobile)
    if staminaBarGUI then
        staminaBarGUI:Destroy()
    end
    
    if isMobile then
        -- Para mobile, criar dentro do MainFrame.MobileButtons
        local mainUI = LocalPlayer.PlayerGui:WaitForChild("MainUI")
        local mobileButtons = mainUI.MainFrame.MobileButtons
        
        staminaBarFrame = Instance.new("Frame")
        staminaBarFrame.Name = "StaminaBarFrame"
        staminaBarFrame.Size = UDim2.new(0, 200, 0, 15)
        staminaBarFrame.Position = UDim2.new(0.5, -100, 0, -25) -- Acima dos botões
        staminaBarFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        staminaBarFrame.BorderSizePixel = 0
        staminaBarFrame.Parent = mobileButtons
        
    else
        -- Para PC, manter como estava (ScreenGui separado)
        staminaBarGUI = Instance.new("ScreenGui")
        staminaBarGUI.Name = "SprintStaminaGUI"
        staminaBarGUI.Parent = LocalPlayer.PlayerGui
        
        staminaBarFrame = Instance.new("Frame")
        staminaBarFrame.Name = "StaminaBarFrame"
        staminaBarFrame.Size = UDim2.new(0, 200, 0, 20)
        staminaBarFrame.Position = UDim2.new(1, -220, 1, -80)
        staminaBarFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        staminaBarFrame.BorderSizePixel = 0
        staminaBarFrame.Parent = staminaBarGUI
    end
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = staminaBarFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 100, 100)
    stroke.Thickness = 1
    stroke.Parent = staminaBarFrame
    
    staminaBarFill = Instance.new("Frame")
    staminaBarFill.Name = "StaminaBarFill"
    staminaBarFill.Size = UDim2.new(1, 0, 1, 0)
    staminaBarFill.Position = UDim2.new(0, 0, 0, 0)
    staminaBarFill.BackgroundColor3 = Color3.fromRGB(_G.msrhyan_config_sprint.staminabarcolor[1], _G.msrhyan_config_sprint.staminabarcolor[2], _G.msrhyan_config_sprint.staminabarcolor[3])
    staminaBarFill.BorderSizePixel = 0
    staminaBarFill.Parent = staminaBarFrame
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = staminaBarFill
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(_G.msrhyan_config_sprint.staminabarcolor[1] + 50, _G.msrhyan_config_sprint.staminabarcolor[2] + 50, _G.msrhyan_config_sprint.staminabarcolor[3])),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(_G.msrhyan_config_sprint.staminabarcolor[1], _G.msrhyan_config_sprint.staminabarcolor[2], _G.msrhyan_config_sprint.staminabarcolor[3]))
    }
    gradient.Parent = staminaBarFill
    
    staminaLabel = Instance.new("TextLabel")
    staminaLabel.Name = "StaminaLabel"
    staminaLabel.Size = UDim2.new(1, 0, 1, 0)
    staminaLabel.Position = UDim2.new(0, 0, 0, 0)
    staminaLabel.BackgroundTransparency = 1
    staminaLabel.Text = "100%"
    staminaLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    staminaLabel.TextScaled = true
    staminaLabel.Font = Enum.Font.GothamBold
    staminaLabel.Parent = staminaBarFrame
    
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.fromRGB(0, 0, 0)
    textStroke.Thickness = 1
    textStroke.Parent = staminaLabel
    
    -- Adicionar título "STAMINA" para mobile
    if isMobile then
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "StaminaTitle"
        titleLabel.Size = UDim2.new(1, 0, 0, 12)
        titleLabel.Position = UDim2.new(0, 0, 0, -15)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "STAMINA"
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextScaled = true
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Parent = staminaBarFrame
        
        local titleStroke = Instance.new("UIStroke")
        titleStroke.Color = Color3.fromRGB(0, 0, 0)
        titleStroke.Thickness = 1
        titleStroke.Parent = titleLabel
    end
end

local function UpdateStaminaBar()
    if staminaBarFill and staminaLabel then
        staminaBarFill.Size = UDim2.new(staminaLeft, 0, 1, 0)
        staminaLabel.Text = math.floor(staminaLeft * 100) .. "%"
        
        -- Mudar cor da barra baseado no status
        if isRecovering then
            staminaBarFill.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Laranja quando recuperando
        elseif staminaLeft <= 0.2 then
            staminaBarFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Vermelho quando baixa
        else
            staminaBarFill.BackgroundColor3 = Color3.fromRGB(_G.msrhyan_config_sprint.staminabarcolor[1], _G.msrhyan_config_sprint.staminabarcolor[2], _G.msrhyan_config_sprint.staminabarcolor[3])
        end
    end
end

local function ApplySprintFOV()
    if fovUpdateConnection then
        fovUpdateConnection:Disconnect()
    end
    
    fovUpdateConnection = RunService.Heartbeat:Connect(function()
        if isSprinting then
            Camera.FieldOfView = _G.msrhyan_config_sprint.sprintfov
        end
    end)
end

local function RemoveSprintFOV()
    if fovUpdateConnection then
        fovUpdateConnection:Disconnect()
        fovUpdateConnection = nil
    end
    
    local fovTween = TweenService:Create(Camera,
        TweenInfo.new(_G.msrhyan_config_sprint.speedremovetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {FieldOfView = _G.msrhyan_config_sprint.normalfov}
    )
    fovTween:Play()
end

local function CanSprint()
    if _G.msrhyan_config_sprint.usewhileloading then
        -- Pode usar se não estiver no cooldown E tiver pelo menos 10% de stamina
        return not isOnCooldown and staminaLeft > 0.1
    else
        -- Modo original: só pode usar se não estiver no cooldown
        return not isOnCooldown
    end
end

local function StartSprint()
    if not CanSprint() then
        if isOnCooldown then
            if _G.msrhyan_config_sprint.showstaminamessages then
                msg(string.format(_G.msrhyan_config_sprint.customstaminamessage, math.ceil(cooldownTime)), "rgb(255,100,100)")
            end
        elseif _G.msrhyan_config_sprint.usewhileloading and staminaLeft <= 0.1 then
            if _G.msrhyan_config_sprint.showstaminamessages then
                msg("Stamina muito baixa! Aguarde recuperar um pouco.", "rgb(255,150,100)")
            end
        end
        return
    end
    
    if isSprinting then return end
    isSprinting = true
    
    local speedTween = TweenService:Create(Humanoid, 
        TweenInfo.new(_G.msrhyan_config_sprint.speedapplytime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {WalkSpeed = _G.msrhyan_config_sprint.sprintspeed}
    )
    speedTween:Play()
    
    ApplySprintFOV()
    
    if _G.msrhyan_config_sprint.enableeffects and 
       LocalPlayer.PlayerGui.MainUI.MainFrame.Healthbar:FindFirstChild("Effects") and 
       LocalPlayer.PlayerGui.MainUI.MainFrame.Healthbar.Effects:FindFirstChild("SpeedBoost") then
        
        if not sprintSpeedEffect then
            sprintSpeedEffect = LocalPlayer.PlayerGui.MainUI.MainFrame.Healthbar.Effects.SpeedBoost:Clone()
            sprintSpeedEffect.Name = "SprintSpeedEffect"
            sprintSpeedEffect.Parent = LocalPlayer.PlayerGui.MainUI.MainFrame.Healthbar.Effects
            
            local effectColor = _G.msrhyan_config_sprint.effectcolor
            sprintSpeedEffect.BackgroundColor3 = Color3.fromRGB(effectColor[1], effectColor[2], effectColor[3])
            
            local uiStroke = Instance.new("UIStroke")
            uiStroke.Color = Color3.fromRGB(effectColor[1], effectColor[2], effectColor[3])
            uiStroke.Thickness = 3
            uiStroke.Transparency = 0.3
            uiStroke.Parent = sprintSpeedEffect
            
            local uiGradient = Instance.new("UIGradient")
            uiGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(effectColor[1], effectColor[2], effectColor[3])),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(effectColor[1] * 0.7, effectColor[2] * 0.7, effectColor[3] * 0.7))
            }
            uiGradient.Parent = sprintSpeedEffect
        end
        
        sprintSpeedEffect.Visible = true
        sprintSpeedEffect.BackgroundTransparency = 1
        local fadeIn = TweenService:Create(sprintSpeedEffect,
            TweenInfo.new(_G.msrhyan_config_sprint.effectfadetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0}
        )
        fadeIn:Play()
    end
end

local function StopSprint()
    if not isSprinting then return end
    isSprinting = false
    
    if staminaUpdateConnection then
        staminaUpdateConnection:Disconnect()
        staminaUpdateConnection = nil
    end
    
    local speedTween = TweenService:Create(Humanoid,
        TweenInfo.new(_G.msrhyan_config_sprint.speedremovetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {WalkSpeed = originalSpeed}
    )
    speedTween:Play()
    
    RemoveSprintFOV()
    
    if sprintSpeedEffect and _G.msrhyan_config_sprint.enableeffects then
        local fadeOut = TweenService:Create(sprintSpeedEffect,
            TweenInfo.new(_G.msrhyan_config_sprint.effectfadetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            sprintSpeedEffect.Visible = false
        end)
    end
end

local function ManageStamina()
    if _G.msrhyan_config_sprint.timetospeedexpire <= 0 then return end
    
    local staminaDrain = 1 / _G.msrhyan_config_sprint.timetospeedexpire
    
    staminaUpdateConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if isSprinting and staminaLeft > 0 then
            staminaLeft = math.max(0, staminaLeft - (staminaDrain * deltaTime))
            UpdateStaminaBar()
            
            if staminaLeft <= 0 then
                StopSprint()
                isOnCooldown = true
                isRecovering = true
                staminaLeft = 0
                UpdateStaminaBar()
                
                if _G.msrhyan_config_sprint.showstaminamessages then
                    msg(string.format(_G.msrhyan_config_sprint.customstaminamessage, _G.msrhyan_config_sprint.cooldowntime), "rgb(255,100,100)")
                end
                
                task.spawn(function()
                    task.wait(_G.msrhyan_config_sprint.cooldowntime)
                    isOnCooldown = false
                    
                    local recoverTime = _G.msrhyan_config_sprint.staminarecovertime
                    local recoverRate = 1 / recoverTime
                    
                    local recoverConnection
                    recoverConnection = RunService.Heartbeat:Connect(function(dt)
                        staminaLeft = math.min(1, staminaLeft + (recoverRate * dt))
                        UpdateStaminaBar()
                        
                        if staminaLeft >= 1 then
                            staminaLeft = 1
                            isRecovering = false
                            UpdateStaminaBar()
                            recoverConnection:Disconnect()
                        end
                    end)
                end)
            end
        elseif not isSprinting and not isOnCooldown and staminaLeft < 1 then
            local recoverRate = 1 / _G.msrhyan_config_sprint.staminarecovertime
            staminaLeft = math.min(1, staminaLeft + (recoverRate * deltaTime))
            UpdateStaminaBar()
            
            if staminaLeft >= 1 then
                isRecovering = false
                UpdateStaminaBar()
            end
        end
    end)
end

local function SaveSprintKey(key)
    if not isfolder(configFolder) then
        makefolder(configFolder)
    end
    writefile(keyFile, tostring(key.KeyCode))
end

local function LoadSprintKey()
    if isfile(keyFile) then
        local keyData = readfile(keyFile)
        for _, key in pairs(Enum.KeyCode:GetEnumItems()) do
            if tostring(key) == keyData then
                return key
            end
        end
    end
    return Enum.KeyCode.Q
end

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function SetupMobile()
    local mainUI = LocalPlayer.PlayerGui:WaitForChild("MainUI")
    local interactButton = mainUI.MainFrame.MobileButtons.InteractButton
    
    sprintButton = Instance.new("ImageButton")
    sprintButton.Name = "SprintButton"
    sprintButton.Size = interactButton.Size
    sprintButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
    sprintButton.BackgroundTransparency = 0.2
    sprintButton.BorderSizePixel = 0
    sprintButton.Parent = interactButton.Parent
    
    sprintButton.Position = UDim2.new(
        interactButton.Position.X.Scale,
        interactButton.Position.X.Offset,
        interactButton.Position.Y.Scale - 0.15,
        interactButton.Position.Y.Offset
    )
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = sprintButton
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255))
    }
    gradient.Rotation = 45
    gradient.Parent = sprintButton
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(200, 230, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = sprintButton
    
    local sprintLabel = Instance.new("TextLabel")
    sprintLabel.Name = "SprintLabel"
    sprintLabel.Size = UDim2.new(1, 0, 0.3, 0)
    sprintLabel.Position = UDim2.new(0, 0, -0.4, 0)
    sprintLabel.BackgroundTransparency = 1
    sprintLabel.Text = "Sprint"
    sprintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sprintLabel.TextScaled = true
    sprintLabel.Font = Enum.Font.GothamBold
    sprintLabel.Parent = sprintButton
    
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.fromRGB(0, 0, 0)
    textStroke.Thickness = 2
    textStroke.Parent = sprintLabel
    
    sprintButton.MouseButton1Down:Connect(function()
        local clickTween = TweenService:Create(sprintButton,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.4, Size = UDim2.new(sprintButton.Size.X.Scale * 0.95, 0, sprintButton.Size.Y.Scale * 0.95, 0)}
        )
        clickTween:Play()
        
        StartSprint()
        ManageStamina()
    end)
    
    sprintButton.MouseButton1Up:Connect(function()
        local releaseTween = TweenService:Create(sprintButton,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.2, Size = interactButton.Size}
        )
        releaseTween:Play()
        
        StopSprint()
    end)
    
    sprintButton.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(sprintButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.1}
        )
        hoverTween:Play()
    end)
    
    sprintButton.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(sprintButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.2}
        )
        leaveTween:Play()
    end)
end

local function SetupPC()
    sprintKey = LoadSprintKey()
    
    msg(string.format("Tecla atual do SPRINT: %s. Digite /spkey para alterar", sprintKey.Name))
    
    LocalPlayer.Chatted:Connect(function(message)
        if message:lower() == "/spkey" then
            msg("Pressione qualquer tecla para configurar o SPRINT...")
            
            local connection
            connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    sprintKey = input.KeyCode
                    SaveSprintKey(input)
                    msg(string.format("Tecla %s configurada para SPRINT!", input.KeyCode.Name))
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not sprintKey then return end
        
        if input.KeyCode == sprintKey then
            StartSprint()
            ManageStamina()
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed or not sprintKey then return end
        
        if input.KeyCode == sprintKey then
            StopSprint()
        end
    end)
end

local function OnCharacterAdded(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    Camera = workspace.CurrentCamera
    originalSpeed = Humanoid.WalkSpeed
    originalFOV = Camera.FieldOfView
    sprintSpeed = _G.msrhyan_config_sprint.sprintspeed
    cooldownTime = _G.msrhyan_config_sprint.cooldowntime
    
    SetupCollision()
    
    isSprinting = false
    isOnCooldown = false
    isRecovering = false
    staminaLeft = 1
    
    if staminaUpdateConnection then
        staminaUpdateConnection:Disconnect()
        staminaUpdateConnection = nil
    end
    
    if fovUpdateConnection then
        fovUpdateConnection:Disconnect()
        fovUpdateConnection = nil
    end
    
    if sprintSpeedEffect then
        sprintSpeedEffect:Destroy()
        sprintSpeedEffect = nil
    end
    
    CreateStaminaBar(IsMobile())
    UpdateStaminaBar()
end

SetupCollision()
CreateStaminaBar(IsMobile())
UpdateStaminaBar()

if IsMobile() then
    SetupMobile()
else
    SetupPC()
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

ManageStamina()

print("SPRINT Script carregado com sucesso! Tecla padrão: Q")
print("Configurações atualizadas:")
print("- Stamina dura 30 segundos (antes 10s)")
print("- Cooldown reduzido para 3 segundos (antes 5s)")
print("- Recuperação em 5 segundos (antes 8s)")
print("- UseWhileLoading:", _G.msrhyan_config_sprint.usewhileloading and "ATIVO" or "INATIVO")