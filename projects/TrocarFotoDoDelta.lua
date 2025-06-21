local function BAIXARIMAGEM(githubLink)
    local deltaimg = "new_logo.png"
    if isfile(deltaimg) then
        delfile(deltaimg)
        print("[ HM ] FOTO DO DELTA JÁ EXISTIA:(APAGADA) " .. deltaimg)
    end
    
    local success, imageData = pcall(function()
        return game:HttpGet(githubLink)
    end)
    
    if not success then
        warn("[HM] Falha ao baixar a imagem: " .. githubLink)
        return false
    end
    writefile(deltaimg, imageData)
    print("[ pronto ] IMAGEM SALVA! " .. deltaimg)
    return true
end

local linkDaImagem = _G.rhyanDeltaImg

if BAIXARIMAGEM(linkDaImagem) then
    print("[ HM ] Download concluído com sucesso!")
else
    warn("[ HM ] Falha no download da imagem, LLLLLL")
end