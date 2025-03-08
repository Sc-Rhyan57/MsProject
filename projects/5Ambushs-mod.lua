-- Configuração global
_G["msproject-ambushInf"] = {
    ambushs = 3, -- quantidade de vezes que o Ambush deve aparecer
    modAtivo = true, -- para evitar múltiplas execuções
    cooldown = 1, -- tempo entre execuções (em segundos)
    debug = true -- para mostrar mensagens de debug
}

local function invocarAmbush()
    local argumentos = {
        [1] = "Ambush",
        [2] = {}
    }
    game:GetService("ReplicatedStorage").RemotesFolder.AdminPanelRunCommand:FireServer(unpack(argumentos))
    
    if _G["msproject-ambushInf"].debug then
        print("[Msproject] » Ambush invocado!")
    end
end

local function processarAmbush()
    if not _G["msproject-ambushInf"].modAtivo then
        return
    end
    
    _G["msproject-ambushInf"].modAtivo = false
    
    for i = 1, _G["msproject-ambushInf"].ambushs do
        invocarAmbush()
        task.wait(_G["msproject-ambushInf"].cooldown)
    end
    
    task.wait(2)
    _G["msproject-ambushInf"].modAtivo = true
    
    if _G["msproject-ambushInf"].debug then
        print("Ciclo de invocação de Ambush concluído")
    end
end

local function verificarWorkspace(objeto)
    if objeto.Name == "AmbushMoving" then
        if _G["msproject-ambushInf"].debug then
            print("AmbushMoving detectado no Workspace")
        end
        processarAmbush()
    end
end

game.Workspace.ChildAdded:Connect(function(child)
    verificarWorkspace(child)
end)

for _, child in pairs(game.Workspace:GetChildren()) do
    verificarWorkspace(child)
end

if _G["msproject-ambushInf"].debug then
    print("==========[ 5 AMBUSHS INSPIRADO POR REGINALDOO ]==========")
    print("[Msproject] » Configurado para invocar " .. _G["msproject-ambushInf"].ambushs .. " Ambushs quando detectado")
end
