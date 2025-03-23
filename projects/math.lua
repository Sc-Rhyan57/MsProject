local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/Giangplay/Script/main/Orion_Library_PE_V2.lua')))()

local Window = OrionLib:MakeWindow({
    Name = "MsProject : Calculadora",
    HidePremium = true,
    SaveConfig = true,
    ConfigFolder = "AutoMath"
})

local Tab = Window:MakeTab({
    Name = "Principal",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local autoSolveEnabled = false
local difficultyText = "N/A"
local winnerText = "N/A"
local currentEquation = "N/A"

Tab:AddToggle({
    Name = "Resolver Automaticamente",
    Default = false,
    Callback = function(Value)
        autoSolveEnabled = Value
    end
})

local difficultyLabel = Tab:AddLabel("Dificuldade: N/A")
local winnerLabel = Tab:AddLabel("Vencedor: N/A")
local equationLabel = Tab:AddLabel("Equação: N/A")
local resultLabel = Tab:AddLabel("Resultado: N/A")

local function solveExpression(expression)
    local originalExpression = expression
    
    expression = expression:gsub("%s*=%s*$", "")
    
    local cleanExpression = expression

    cleanExpression = cleanExpression:gsub("×", "*")
    cleanExpression = cleanExpression:gsub("x", "*") -- Converter "x" minúsculo para "*"
    cleanExpression = cleanExpression:gsub("X", "*") -- Converter "X" maiúsculo para "*"
    cleanExpression = cleanExpression:gsub("÷", "/")
    cleanExpression = cleanExpression:gsub("\\", "/")
    
    cleanExpression = cleanExpression:gsub("[^%d%+%-%*%/%(%)\\.%s]", "")
    
    cleanExpression = cleanExpression:match("^%s*(.-)%s*$")
    
    print("[ Msproject ] » Expressão original: " .. originalExpression)
    print("[ Msproject ] » Expressão limpa para cálculo: " .. cleanExpression)
    
    local func, err = loadstring("return " .. cleanExpression)
    
    if func then
        local success, result = pcall(func)
        if success then
            if type(result) == "number" then
                if result == math.floor(result) then
                    return tostring(math.floor(result))
                else
                    return string.format("%.6f", result):gsub("0+$", ""):gsub("%.$", "")
                end
            else
                return tostring(result)
            end
        else
            print("Erro no pcall: " .. tostring(result))
        end
    else
        print("Erro no loadstring: " .. tostring(err))
    end
    
    local mathExpression = cleanExpression:gsub("%s+", "")
    
    local nums = {}
    for num in mathExpression:gmatch("%d+%.?%d*") do
        table.insert(nums, tonumber(num))
    end
    
    local ops = {}
    for op in mathExpression:gmatch("[%+%-%*%/]") do
        table.insert(ops, op)
    end
    
    print("Números encontrados: " .. table.concat(nums, ", "))
    print("Operadores encontrados: " .. table.concat(ops, ", "))
    
    if #nums == 2 and #ops == 1 then
        if ops[1] == "+" then return tostring(nums[1] + nums[2])
        elseif ops[1] == "-" then return tostring(nums[1] - nums[2])
        elseif ops[1] == "*" then return tostring(nums[1] * nums[2])
        elseif ops[1] == "/" then return tostring(nums[1] / nums[2])
        end
    end
    
    if mathExpression:match("^%d+%*%d+$") then
        local num1, num2 = mathExpression:match("(%d+)%*(%d+)")
        return tostring(tonumber(num1) * tonumber(num2))
    elseif mathExpression:match("^%d+%+%d+$") then
        local num1, num2 = mathExpression:match("(%d+)%+(%d+)")
        return tostring(tonumber(num1) + tonumber(num2))
    elseif mathExpression:match("^%d+%-%d+$") then
        local num1, num2 = mathExpression:match("(%d+)%-(%d+)")
        return tostring(tonumber(num1) - tonumber(num2))
    elseif mathExpression:match("^%d+%/%d+$") then
        local num1, num2 = mathExpression:match("(%d+)%/(%d+)")
        return tostring(tonumber(num1) / tonumber(num2))
    end
    
    -- Ainda mais direto - extrai os números diretamente da expressão original
    -- Útil para casos como "10 x 7 ="
    local num1, op, num2 = originalExpression:match("(%d+)%s*([x×%+%-%*/÷\\])%s*(%d+)")
    if num1 and op and num2 then
        num1, num2 = tonumber(num1), tonumber(num2)
        if op == "+" then return tostring(num1 + num2)
        elseif op == "-" then return tostring(num1 - num2)
        elseif op == "*" or op == "×" or op:lower() == "x" then return tostring(num1 * num2)
        elseif op == "/" or op == "÷" or op == "\\" then return tostring(num1 / num2)
        end
    end
    
    return "Expressão não reconhecida"
end

local function sendAnswer(answer)
    local args = {
        [1] = "updateAnswer",
        [2] = answer
    }
    game:GetService("ReplicatedStorage").Events.GameEvent:FireServer(unpack(args))
end

local function monitorQuestion()
    local questionChanged = game:GetService("RunService").RenderStepped:Connect(function()
        if not autoSolveEnabled then return end
        
        local questionObj = workspace.Map.Functional.Screen.SurfaceGui.MainFrame.MainGameContainer.MainTxtContainer:FindFirstChild("QuestionText")
        
        if questionObj and questionObj:IsA("TextLabel") then
            local questionText = questionObj.Text
            
            if questionText ~= currentEquation then
                currentEquation = questionText
                equationLabel:Set("Equação: " .. questionText)
                
                if questionText:match("[%d%+%-%*%/×÷\\xX%(%)]") then
                    local answer = solveExpression(questionText)
                    resultLabel:Set("Resultado: " .. answer)
                    
                    if answer and tonumber(answer) then
                        sendAnswer(answer)
                        OrionLib:MakeNotification({
                            Name = "Resposta Enviada",
                            Content = "Equação: " .. questionText .. "\nResposta: " .. answer,
                            Image = "rbxassetid://4483345998",
                            Time = 3
                        })
                    end
                end
            end
        end
    end)
    
    return questionChanged
end

local function monitorDifficulty()
    local difficultyChanged = game:GetService("RunService").RenderStepped:Connect(function()
        local difficultyObj = workspace.Map.Functional.Screen.SurfaceGui.MainFrame.MainGameContainer:FindFirstChild("DifficultyText")
        
        if difficultyObj and difficultyObj:IsA("TextLabel") and difficultyObj.Text ~= difficultyText then
            difficultyText = difficultyObj.Text
            difficultyLabel:Set("Dificuldade: " .. difficultyText)
            
            OrionLib:MakeNotification({
                Name = "Dificuldade Atualizada",
                Content = "Nova dificuldade: " .. difficultyText,
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    end)
    
    return difficultyChanged
end

local function monitorWinner()
    local winnerChanged = game:GetService("RunService").RenderStepped:Connect(function()
        local winnerObj = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.GameFrame.WinnerContainer:FindFirstChild("WinnerText")
        
        if winnerObj and winnerObj:IsA("TextLabel") and winnerObj.Text ~= winnerText then
            winnerText = winnerObj.Text
            winnerLabel:Set("Vencedor: " .. winnerText)
            
            OrionLib:MakeNotification({
                Name = "Vencedor Atualizado",
                Content = "Novo vencedor: " .. winnerText,
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    end)
    
    return winnerChanged
end

local questionMonitor = monitorQuestion()
local difficultyMonitor = monitorDifficulty()
local winnerMonitor = monitorWinner()

local function cleanup()
    if questionMonitor then questionMonitor:Disconnect() end
    if difficultyMonitor then difficultyMonitor:Disconnect() end
    if winnerMonitor then winnerMonitor:Disconnect() end
    OrionLib:Destroy()
end

Tab:AddButton({
    Name = "Fechar Interface",
    Callback = function()
        cleanup()
    end
})

game:GetService("Players").LocalPlayer.OnTeleport:Connect(cleanup)
