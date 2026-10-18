local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

print("[HttpSpyV4] === INICIANDO ===")

local function notify(msg)
    print("[HttpSpyV4] " .. tostring(msg))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Http Spy V4",
            Text = tostring(msg),
            Duration = 4,
        })
    end)
end

local function safeStr(v, depth)
    depth = depth or 0
    if depth > 2 then return "..." end
    local t = typeof(v)
    if t == "nil" then return "nil"
    elseif t == "string" then return v
    elseif t == "number" or t == "boolean" then return tostring(v)
    elseif t == "table" then
        local ok, s = pcall(function() return HttpService:JSONEncode(v) end)
        return ok and s or "<table>"
    elseif t == "Instance" then return (v.Name or "?") end
    else return tostring(v) end
end

local capturedLogs = {}
local maxLogs = 200
local spoofEntries = {}
local spoofEnabled = false
local interceptActive = false
local loopActive = false
local loopConn = nil
local originals = {}
local wrappers = {}
local scanCount = 0
local hooksRemoved = 0
local scanResults = {}
local selectedHook = nil
local blockedRestores = 0

local function addLog(method, url, argsTable, response, isErr, isSpoofed, extra)
    local entry = {
        timestamp = os.time(),
        method = method,
        url = url or "?",
        args = argsTable,
        response = response,
        isError = isErr or false,
        spoofed = isSpoofed or false,
        extra = extra or {},
    }
    table.insert(capturedLogs, entry)
    while #capturedLogs > maxLogs do table.remove(capturedLogs, 1) end
    print(string.format("[HttpSpyV4] #%d %s %s -> %s",
        #capturedLogs, method, (url or "?"):sub(1, 80), tostring(response):sub(1, 100)))
    if _G.HttpSpy4_RefreshLogs then task.spawn(_G.HttpSpy4_RefreshLogs) end
end

local function findSpoof(method, url)
    if not spoofEnabled then return nil end
    for _, e in ipairs(spoofEntries) do
        if e.enabled and (e.method == "*" or e.method == method) and url and url:find(e.urlPattern, 1, true) then
            return e.response
        end
    end
    return nil
end

local function extractFromArgs(args)
    local url, body, method, headers
    if typeof(args[1]) == "table" and args[1].Url then
        url = args[1].Url
        method = args[1].Method or "GET"
        body = args[1].Body
        if type(args[1].Headers) == "table" then
            headers = {}
            for k, v in pairs(args[1].Headers) do
                headers[tostring(k)] = tostring(v)
            end
        end
    elseif type(args[1]) == "string" then
        url = args[1]
        if type(args[2]) == "string" then body = args[2] end
    end
    return url, body, method, headers
end

local function getStack()
    local stack = {}
    local ok, trace = pcall(debug.traceback, "", 3)
    if ok and trace then
        for line in trace:gmatch("[^\n]+") do
            if #stack >= 6 then break end
            local t = line:gsub("^%s+", ""):gsub("%s+$", "")
            if t ~= "" and not t:find("stack traceback:") then
                table.insert(stack, t)
            end
        end
    end
    return stack
end

local function makeWrapper(originalFn, fnName)
    return function(...)
        local args = {...}
        local url, body, method, headers = extractFromArgs(args)
        local argStrings = {}
        for i, v in ipairs(args) do
            argStrings[i] = safeStr(v)
        end
        local stack = getStack()
        local spoofedResp = findSpoof(fnName, url)
        if spoofedResp then
            addLog(fnName, url, argStrings, spoofedResp, false, true, { body = body, httpMethod = method, headers = headers, stack = stack })
            return spoofedResp
        end
        local ok, result = pcall(originalFn, ...)
        if ok then
            addLog(fnName, url, argStrings, safeStr(result), false, false, { body = body, httpMethod = method, headers = headers, stack = stack })
            return result
        else
            addLog(fnName, url, argStrings, "[ERR] " .. tostring(result), true, false, { body = body, httpMethod = method, headers = headers, stack = stack })
            error(result, 0)
        end
    end
end

local function getTargetSpecs()
    return {
        { kind = "global", name = "request", getValue = function() return request end, setValue = function(v) request = v end },
        { kind = "global", name = "http_request", getValue = function() return http_request end, setValue = function(v) http_request = v end },
        { kind = "syn", name = "syn.request", getValue = function() return syn and syn.request end, setValue = function(v) if syn then syn.request = v end end },
        { kind = "http", name = "http.request", getValue = function() return http and http.request end, setValue = function(v) if http then http.request = v end end },
        { kind = "genv", name = "genv.request", getValue = function() return getgenv and getgenv().request end, setValue = function(v) if getgenv then getgenv().request = v end end },
        { kind = "genv", name = "genv.http", getValue = function() return getgenv and getgenv().http end, setValue = function(v) if getgenv then getgenv().http = v end end },
        { kind = "genv", name = "genv.syn", getValue = function() return getgenv and getgenv().syn end, setValue = function(v) if getgenv then getgenv().syn = v end end },
        { kind = "service", name = "HttpService.GetAsync", getValue = function() return HttpService.GetAsync end, setValue = function(v) pcall(function() setreadonly(HttpService, false) HttpService.GetAsync = v setreadonly(HttpService, true) end) end },
        { kind = "service", name = "HttpService.PostAsync", getValue = function() return HttpService.PostAsync end, setValue = function(v) pcall(function() setreadonly(HttpService, false) HttpService.PostAsync = v setreadonly(HttpService, true) end) end },
        { kind = "service", name = "HttpService.RequestAsync", getValue = function() return HttpService.RequestAsync end, setValue = function(v) pcall(function() setreadonly(HttpService, false) HttpService.RequestAsync = v setreadonly(HttpService, true) end) end },
        { kind = "instance", name = "game.HttpGet", getValue = function() return game.HttpGet end, setValue = function(v) game.HttpGet = v end },
        { kind = "instance", name = "game.GetAsync(metatable)", getValue = function() return getrawmetatable(game).__index and getrawmetatable(game).__index(game, "HttpGet") end, setValue = function() end },
    }
end

local function isHooked(fn)
    if not fn then return false, "nil" end
    if isfunctionhooked then
        local ok, hooked = pcall(isfunctionhooked, fn)
        if ok then return hooked, "isfunctionhooked" end
    end
    local ok, info = pcall(debug.getinfo, fn, "Su")
    if ok and info then
        if info.what and info.what ~= "C" then return true, "what=" .. info.what end
        if info.source and info.source ~= "" and info.source ~= "=[C]" and info.source ~= "[C]" then
            return true, "src=" .. tostring(info.source):sub(1, 40)
        end
    end
    return false, "native"
end

local function extractInfo(fn)
    local info = {
        source = "?", short_src = "?", what = "?", name = "",
        currentline = -1, linedefined = -1, lastlinedefined = -1,
        nups = 0, nparams = 0, isvararg = false,
        upvalues = {}, constants = {}, protos = {},
        address = "?",
    }
    if not fn then return info end
    pcall(function()
        local di = debug.getinfo(fn, "flnStu")
        if di then
            info.source = tostring(di.source or "?")
            info.short_src = tostring(di.short_src or "?")
            info.what = tostring(di.what or "?")
            info.name = tostring(di.name or "")
            info.currentline = di.currentline or -1
            info.linedefined = di.linedefined or -1
            info.lastlinedefined = di.lastlinedefined or -1
            info.nups = di.nups or 0
            info.nparams = di.nparams or 0
            info.isvararg = di.isvararg == true
        end
    end)
    for i = 1, math.min(info.nups, 20) do
        pcall(function()
            local n, v = debug.getupvalue(fn, i)
            table.insert(info.upvalues, { idx = i, name = tostring(n or "?"), value = safeStr(v, 1), type = typeof(v) })
        end)
    end
    if debug.getconstants then
        pcall(function()
            local consts = debug.getconstants(fn)
            if consts then
                for i, c in ipairs(consts) do
                    if #info.constants >= 50 then break end
                    table.insert(info.constants, { idx = i, value = safeStr(c, 1), type = typeof(c) })
                end
            end
        end)
    end
    pcall(function()
        info.address = tostring(fn):match("0x[%x]+") or "?"
    end)
    return info
end

local function restoreFn(fn)
    if not fn then return false, "nil" end
    if restorefunction then
        local ok = pcall(restorefunction, fn)
        if ok then return true, "restorefunction" end
    end
    if unhookfunction then
        local ok = pcall(unhookfunction, fn)
        if ok then return true, "unhookfunction" end
    end
    return false, "no API"
end

local function installOne(spec)
    if wrappers[spec.name] then return true end
    local ok, original = pcall(spec.getValue)
    if not ok or not original or type(original) ~= "function" then
        return false, "unavailable"
    end
    originals[spec.name] = original
    local wrapper = makeWrapper(original, spec.name)
    local okHook = false
    if hookfunction then
        okHook = pcall(hookfunction, original, wrapper)
    end
    if not okHook and replaceclosure then
        okHook = pcall(replaceclosure, original, wrapper)
    end
    if not okHook then
        pcall(spec.setValue, wrapper)
        okHook = true
    end
    if okHook then
        wrappers[spec.name] = { wrapper = wrapper, original = original, spec = spec }
        print("[HttpSpyV4] ✓ Hook instalado: " .. spec.name)
        return true
    end
    warn("[HttpSpyV4] ✗ Falhou: " .. spec.name)
    return false
end

local function installAll()
    local count = 0
    for _, spec in ipairs(getTargetSpecs()) do
        if installOne(spec) then count = count + 1 end
    end
    print("[HttpSpyV4] Total hooks: " .. count)
    if restorefunction and hookfunction then
        local realRestore = restorefunction
        local function guarded(fn)
            for name, data in pairs(wrappers) do
                if fn == data.wrapper or fn == data.original then
                    blockedRestores = blockedRestores + 1
                    print("[HttpSpyV4] 🛡 Bloqueei restore em: " .. name .. " (total: " .. blockedRestores .. ")")
                    return false
                end
            end
            return realRestore(fn)
        end
        pcall(hookfunction, restorefunction, guarded)
    end
    interceptActive = true
    notify("Interceptação ativa: " .. count .. " funções")
    return count
end

local function restoreAll()
    for name, data in pairs(wrappers) do
        pcall(restoreFn, data.original)
        pcall(function() data.spec.setValue(data.original) end)
    end
    wrappers = {}
    interceptActive = false
    print("[HttpSpyV4] Todos hooks removidos")
end

local function performScan()
    scanCount = scanCount + 1
    local results = {}
    local found, removed = 0, 0
    for _, spec in ipairs(getTargetSpecs()) do
        local ok, fn = pcall(spec.getValue)
        fn = (ok and fn) or nil
        local hooked, via = isHooked(fn)
        local info = extractInfo(fn)
        local entry = { name = spec.name, fn = fn, hooked = hooked, via = via, info = info, scannedAt = os.time(), scanId = scanCount }
        table.insert(results, entry)
        if hooked then
            found = found + 1
            if loopActive and fn then
                local ok2, m = restoreFn(fn)
                if ok2 then
                    removed = removed + 1
                    hooksRemoved = hooksRemoved + 1
                    entry.restored = true
                    entry.restoreMethod = m
                end
            end
        end
    end
    scanResults = results
    return results, found, removed
end

local existing = CoreGui:FindFirstChild("HttpSpyV4Gui")
if existing then existing:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "HttpSpyV4Gui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 820, 0, 540)
main.Position = UDim2.new(0.5, -410, 0.5, -270)
main.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 10)
mc.Parent = main

local ms = Instance.new("UIStroke")
ms.Color = Color3.fromRGB(180, 80, 255)
ms.Thickness = 1.5
ms.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 350, 0, 30)
title.Position = UDim2.new(0, 14, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Text = "🌐 HttpService Spy V4 (Anti-Bypass)"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 12, 0, 12)
statusDot.Position = UDim2.new(0, 380, 0, 18)
statusDot.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
statusDot.BorderSizePixel = 0
statusDot.Parent = main
local sdc = Instance.new("UICorner")
sdc.CornerRadius = UDim.new(1, 0)
sdc.Parent = statusDot

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(0, 220, 0, 14)
statusText.Position = UDim2.new(0, 398, 0, 18)
statusText.BackgroundTransparency = 1
statusText.Font = Enum.Font.Gotham
statusText.TextColor3 = Color3.fromRGB(180, 180, 190)
statusText.TextSize = 12
statusText.Text = "Inativo"
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = main

local statsText = Instance.new("TextLabel")
statsText.Size = UDim2.new(0, 400, 0, 14)
statsText.Position = UDim2.new(0, 14, 0, 42)
statsText.BackgroundTransparency = 1
statsText.Font = Enum.Font.Code
statsText.TextColor3 = Color3.fromRGB(150, 220, 150)
statsText.TextSize = 11
statsText.Text = "Scans: 0 | Hooks: 0 | Logs: 0 | Blocks: 0"
statsText.TextXAlignment = Enum.TextXAlignment.Left
statsText.Parent = main

local function makeBtn(text, w, x, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 28)
    b.Position = UDim2.new(1, x, 0, 12)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Text = text
    b.Parent = main
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = b
    return b
end

local autoBtn = makeBtn("⚡ Auto-Injetar", 130, -630, Color3.fromRGB(255, 100, 50))
local loopBtn = makeBtn("🛑 Loop: OFF", 130, -490, Color3.fromRGB(200, 80, 80))
local scanBtn = makeBtn("🔍 Escanear", 110, -350, Color3.fromRGB(80, 120, 255))
local interceptBtn = makeBtn("▶ Intercept: OFF", 140, -230, Color3.fromRGB(60, 140, 100))
local closeBtn = makeBtn("✕", 30, -32, Color3.fromRGB(80, 30, 40))

local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -28, 0, 30)
tabsFrame.Position = UDim2.new(0, 14, 0, 64)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = main

local tabDefs = {
    { name = "log", label = "📡 Logs" },
    { name = "scan", label = "🔍 Detecção" },
    { name = "details", label = "🔬 Detalhes" },
    { name = "spoof", label = "🎭 Spoof" },
}
local tabBtns = {}
local pages = {}
local xOffset = 0
for _, tab in ipairs(tabDefs) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 130, 0, 30)
    b.Position = UDim2.new(0, xOffset, 0, 0)
    b.BackgroundColor3 = (tab.name == "log") and Color3.fromRGB(80, 120, 255) or Color3.fromRGB(45, 48, 60)
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Text = tab.label
    b.Parent = tabsFrame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = b
    tabBtns[tab.name] = b
    xOffset = xOffset + 140
end

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -28, 1, -110)
content.Position = UDim2.new(0, 14, 0, 100)
content.BackgroundTransparency = 1
content.Parent = main

for _, tab in ipairs(tabDefs) do
    local p = Instance.new("Frame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = (tab.name == "log")
    p.Parent = content
    pages[tab.name] = p
end

local function switchTab(name)
    for n, p in pairs(pages) do
        p.Visible = (n == name)
        tabBtns[n].BackgroundColor3 = (n == name) and Color3.fromRGB(80, 120, 255) or Color3.fromRGB(45, 48, 60)
    end
end
for n, b in pairs(tabBtns) do
    b.MouseButton1Click:Connect(function() switchTab(n) end)
end

local logList = Instance.new("ScrollingFrame")
logList.Size = UDim2.new(1, 0, 1, -40)
logList.BackgroundTransparency = 1
logList.CanvasSize = UDim2.new(0, 0, 0, 0)
logList.ScrollBarThickness = 6
logList.AutomaticCanvasSize = Enum.AutomaticSize.Y
logList.Parent = pages["log"]

local logLayout = Instance.new("UIListLayout")
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Padding = UDim.new(0, 4)
logLayout.Parent = logList

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 110, 0, 28)
clearBtn.Position = UDim2.new(0, 0, 1, -28)
clearBtn.BackgroundColor3 = Color3.fromRGB(60, 65, 80)
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 12
clearBtn.Text = "🗑 Limpar"
clearBtn.Parent = pages["log"]
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 6)
cc.Parent = clearBtn

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0, 160, 0, 28)
saveBtn.Position = UDim2.new(0, 120, 1, -28)
saveBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 100)
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 12
saveBtn.Text = "💾 Salvar Tudo"
saveBtn.Parent = pages["log"]
local sc = Instance.new("UICorner")
sc.CornerRadius = UDim.new(0, 6)
sc.Parent = saveBtn

local function makeLogRow(entry, idx)
    pcall(function()
        local row = Instance.new("Frame")
        local h = 130
        if entry.extra and entry.extra.headers then h = h + 30 end
        if entry.extra and entry.extra.stack and #entry.extra.stack > 0 then h = h + 28 end
        row.Size = UDim2.new(1, 0, 0, h)
        row.BackgroundColor3 = entry.isError and Color3.fromRGB(45, 25, 30) or (entry.spoofed and Color3.fromRGB(50, 35, 25) or Color3.fromRGB(28, 30, 40))
        row.BorderSizePixel = 0
        row.Parent = logList

        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 6)
        rc.Parent = row

        local hdr = Instance.new("TextLabel")
        hdr.Size = UDim2.new(1, -120, 0, 18)
        hdr.Position = UDim2.new(0, 10, 0, 4)
        hdr.BackgroundTransparency = 1
        hdr.Font = Enum.Font.GothamBold
        hdr.TextColor3 = entry.isError and Color3.fromRGB(255, 140, 140) or (entry.spoofed and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(120, 200, 255))
        hdr.TextSize = 12
        hdr.Text = "#" .. tostring(idx) .. "  " .. entry.method .. (entry.spoofed and "  [SPOOFED]" or "")
        hdr.TextXAlignment = Enum.TextXAlignment.Left
        hdr.Parent = row

        local timeL = Instance.new("TextLabel")
        timeL.Size = UDim2.new(0, 100, 0, 14)
        timeL.Position = UDim2.new(1, -110, 0, 6)
        timeL.BackgroundTransparency = 1
        timeL.Font = Enum.Font.Code
        timeL.TextColor3 = Color3.fromRGB(150, 150, 160)
        timeL.TextSize = 10
        timeL.Text = os.date("%H:%M:%S", entry.timestamp)
        timeL.TextXAlignment = Enum.TextXAlignment.Right
        timeL.Parent = row

        local urlL = Instance.new("TextLabel")
        urlL.Size = UDim2.new(1, -20, 0, 16)
        urlL.Position = UDim2.new(0, 10, 0, 24)
        urlL.BackgroundTransparency = 1
        urlL.Font = Enum.Font.Code
        urlL.TextColor3 = Color3.fromRGB(180, 220, 180)
        urlL.TextSize = 11
        urlL.Text = "URL: " .. (entry.url or "?")
        urlL.TextXAlignment = Enum.TextXAlignment.Left
        urlL.Parent = row

        local yPos = 42
        if entry.extra and (entry.extra.httpMethod or entry.extra.body) then
            local m = Instance.new("TextLabel")
            m.Size = UDim2.new(1, -20, 0, 14)
            m.Position = UDim2.new(0, 10, 0, yPos)
            m.BackgroundTransparency = 1
            m.Font = Enum.Font.Code
            m.TextColor3 = Color3.fromRGB(200, 180, 255)
            m.TextSize = 10
            m.Text = "HTTP: " .. (entry.extra.httpMethod or "?") .. (entry.extra.body and (" | BODY: " .. tostring(entry.extra.body):sub(1, 80)) or "")
            m.TextXAlignment = Enum.TextXAlignment.Left
            m.Parent = row
            yPos = yPos + 16
        end

        if entry.extra and entry.extra.headers then
            local hL = Instance.new("TextLabel")
            hL.Size = UDim2.new(1, -20, 0, 14)
            hL.Position = UDim2.new(0, 10, 0, yPos)
            hL.BackgroundTransparency = 1
            hL.Font = Enum.Font.GothamBold
            hL.TextColor3 = Color3.fromRGB(255, 180, 100)
            hL.TextSize = 10
            hL.Text = "HEADERS:"
            hL.TextXAlignment = Enum.TextXAlignment.Left
            hL.Parent = row
            yPos = yPos + 14

            local hT = Instance.new("TextLabel")
            hT.Size = UDim2.new(1, -20, 0, 16)
            hT.Position = UDim2.new(0, 10, 0, yPos)
            hT.BackgroundTransparency = 1
            hT.Font = Enum.Font.Code
            hT.TextColor3 = Color3.fromRGB(220, 220, 230)
            hT.TextSize = 10
            local parts = {}
            for k, v in pairs(entry.extra.headers) do
                table.insert(parts, k .. ": " .. v)
            end
            hT.Text = table.concat(parts, " | "):sub(1, 300)
            hT.TextXAlignment = Enum.TextXAlignment.Left
            hT.TextYAlignment = Enum.TextYAlignment.Top
            hT.TextWrapped = true
            hT.Parent = row
            yPos = yPos + 16
        end

        if entry.extra and entry.extra.stack and #entry.extra.stack > 0 then
            local sL = Instance.new("TextLabel")
            sL.Size = UDim2.new(1, -20, 0, 14)
            sL.Position = UDim2.new(0, 10, 0, yPos)
            sL.BackgroundTransparency = 1
            sL.Font = Enum.Font.GothamBold
            sL.TextColor3 = Color3.fromRGB(255, 180, 100)
            sL.TextSize = 10
            sL.Text = "STACK:"
            sL.TextXAlignment = Enum.TextXAlignment.Left
            sL.Parent = row
            yPos = yPos + 14

            local sT = Instance.new("TextLabel")
            sT.Size = UDim2.new(1, -20, 0, 14)
            sT.Position = UDim2.new(0, 10, 0, yPos)
            sT.BackgroundTransparency = 1
            sT.Font = Enum.Font.Code
            sT.TextColor3 = Color3.fromRGB(180, 180, 220)
            sT.TextSize = 10
            sT.Text = table.concat(entry.extra.stack, " <- "):sub(1, 250)
            sT.TextXAlignment = Enum.TextXAlignment.Left
            sT.Parent = row
            yPos = yPos + 14
        end

        local respL = Instance.new("TextLabel")
        respL.Size = UDim2.new(1, -20, 0, 14)
        respL.Position = UDim2.new(0, 10, 0, yPos)
        respL.BackgroundTransparency = 1
        respL.Font = Enum.Font.GothamBold
        respL.TextColor3 = Color3.fromRGB(150, 200, 255)
        respL.TextSize = 10
        respL.Text = "RESP:"
        respL.TextXAlignment = Enum.TextXAlignment.Left
        respL.Parent = row
        yPos = yPos + 14

        local respT = Instance.new("TextLabel")
        respT.Size = UDim2.new(1, -110, 0, 20)
        respT.Position = UDim2.new(0, 10, 0, yPos)
        respT.BackgroundTransparency = 1
        respT.Font = Enum.Font.Code
        respT.TextColor3 = Color3.fromRGB(220, 220, 230)
        respT.TextSize = 10
        respT.Text = (entry.response or "?"):sub(1, 200)
        respT.TextXAlignment = Enum.TextXAlignment.Left
        respT.TextYAlignment = Enum.TextYAlignment.Top
        respT.TextWrapped = true
        respT.Parent = row

        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.new(0, 90, 0, 22)
        copyBtn.Position = UDim2.new(1, -98, 0, yPos)
        copyBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
        copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextSize = 10
        copyBtn.Text = "📋 Copiar"
        copyBtn.Parent = row
        local cC = Instance.new("UICorner")
        cC.CornerRadius = UDim.new(0, 5)
        cC.Parent = copyBtn

        local spf = Instance.new("TextButton")
        spf.Size = UDim2.new(0, 90, 0, 22)
        spf.Position = UDim2.new(1, -98, 0, yPos - 24)
        spf.BackgroundColor3 = Color3.fromRGB(150, 80, 180)
        spf.TextColor3 = Color3.fromRGB(255, 255, 255)
        spf.Font = Enum.Font.GothamBold
        spf.TextSize = 10
        spf.Text = "🎭 Spoof"
        spf.Parent = row
        local sC = Instance.new("UICorner")
        sC.CornerRadius = UDim.new(0, 5)
        sC.Parent = spf

        local thisResp = entry.response or ""
        local thisUrl = entry.url or ""
        local thisMethod = entry.method or ""
        copyBtn.MouseButton1Click:Connect(function()
            if setclipboard then pcall(setclipboard, thisResp) end
        end)
        spf.MouseButton1Click:Connect(function()
            if _G.HttpSpy4_SetSpoofFields then _G.HttpSpy4_SetSpoofFields(thisUrl, thisMethod, thisResp) end
            switchTab("spoof")
        end)
    end)
end

local function refreshLogs()
    pcall(function()
        for _, c in ipairs(logList:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for i, e in ipairs(capturedLogs) do
            makeLogRow(e, i)
        end
        statsText.Text = "Scans: " .. scanCount .. " | Hooks: " .. hooksRemoved .. " | Logs: " .. #capturedLogs .. " | Blocks: " .. blockedRestores
    end)
end
_G.HttpSpy4_RefreshLogs = refreshLogs

local scanList = Instance.new("ScrollingFrame")
scanList.Size = UDim2.new(1, 0, 1, -40)
scanList.BackgroundTransparency = 1
scanList.CanvasSize = UDim2.new(0, 0, 0, 0)
scanList.ScrollBarThickness = 6
scanList.AutomaticCanvasSize = Enum.AutomaticSize.Y
scanList.Parent = pages["scan"]

local scanLayout = Instance.new("UIListLayout")
scanLayout.SortOrder = Enum.SortOrder.LayoutOrder
scanLayout.Padding = UDim.new(0, 4)
scanLayout.Parent = scanList

local rescanBtn = Instance.new("TextButton")
rescanBtn.Size = UDim2.new(0, 130, 0, 28)
rescanBtn.Position = UDim2.new(0, 0, 1, -28)
rescanBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
rescanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rescanBtn.Font = Enum.Font.GothamBold
rescanBtn.TextSize = 12
rescanBtn.Text = "🔄 Re-escanear"
rescanBtn.Parent = pages["scan"]
local rc = Instance.new("UICorner")
rc.CornerRadius = UDim.new(0, 6)
rc.Parent = rescanBtn

local restoreAllBtn = Instance.new("TextButton")
restoreAllBtn.Size = UDim2.new(0, 160, 0, 28)
restoreAllBtn.Position = UDim2.new(0, 140, 1, -28)
restoreAllBtn.BackgroundColor3 = Color3.fromRGB(200, 90, 80)
restoreAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
restoreAllBtn.Font = Enum.Font.GothamBold
restoreAllBtn.TextSize = 12
restoreAllBtn.Text = "↺ Restaurar Tudo"
restoreAllBtn.Parent = pages["scan"]
local rac = Instance.new("UICorner")
rac.CornerRadius = UDim.new(0, 6)
rac.Parent = restoreAllBtn

local function makeScanRow(info, idx)
    pcall(function()
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 76)
        row.BackgroundColor3 = info.hooked and Color3.fromRGB(50, 30, 40) or Color3.fromRGB(25, 35, 30)
        row.BorderSizePixel = 0
        row.Parent = scanList

        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 6)
        rc.Parent = row

        local n = Instance.new("TextLabel")
        n.Size = UDim2.new(0, 280, 0, 20)
        n.Position = UDim2.new(0, 10, 0, 6)
        n.BackgroundTransparency = 1
        n.Font = Enum.Font.GothamBold
        n.TextColor3 = Color3.fromRGB(255, 255, 255)
        n.TextSize = 13
        n.Text = tostring(idx) .. ". " .. info.name
        n.TextXAlignment = Enum.TextXAlignment.Left
        n.Parent = row

        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(0, 200, 0, 18)
        s.Position = UDim2.new(0, 10, 0, 28)
        s.BackgroundTransparency = 1
        s.Font = Enum.Font.GothamBold
        s.TextColor3 = info.hooked and Color3.fromRGB(255, 120, 130) or Color3.fromRGB(120, 220, 150)
        s.TextSize = 12
        s.Text = info.hooked and "⚠ HOOKED" or "✓ Nativo"
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.Parent = row

        local v = Instance.new("TextLabel")
        v.Size = UDim2.new(1, -340, 0, 14)
        v.Position = UDim2.new(0, 300, 0, 30)
        v.BackgroundTransparency = 1
        v.Font = Enum.Font.Code
        v.TextColor3 = Color3.fromRGB(160, 160, 170)
        v.TextSize = 10
        v.Text = "via: " .. (info.via or "?") .. (info.restored and (" | restaurado: " .. (info.restoreMethod or "?")) or "")
        v.TextXAlignment = Enum.TextXAlignment.Left
        v.Parent = row

        local src = Instance.new("TextLabel")
        src.Size = UDim2.new(1, -340, 0, 14)
        src.Position = UDim2.new(0, 10, 0, 50)
        src.BackgroundTransparency = 1
        src.Font = Enum.Font.Code
        src.TextColor3 = Color3.fromRGB(200, 200, 220)
        src.TextSize = 10
        src.Text = "src: " .. tostring(info.info.short_src):sub(1, 70) .. ":" .. tostring(info.info.currentline)
        src.TextXAlignment = Enum.TextXAlignment.Left
        src.Parent = row

        local rBtn = Instance.new("TextButton")
        rBtn.Size = UDim2.new(0, 90, 0, 24)
        rBtn.Position = UDim2.new(1, -200, 0, 26)
        rBtn.BackgroundColor3 = Color3.fromRGB(200, 90, 80)
        rBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        rBtn.Font = Enum.Font.GothamBold
        rBtn.TextSize = 11
        rBtn.Text = "↺ Restaurar"
        rBtn.Parent = row
        local rbC = Instance.new("UICorner")
        rbC.CornerRadius = UDim.new(0, 5)
        rbC.Parent = rBtn

        local dBtn = Instance.new("TextButton")
        dBtn.Size = UDim2.new(0, 90, 0, 24)
        dBtn.Position = UDim2.new(1, -100, 0, 26)
        dBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
        dBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        dBtn.Font = Enum.Font.GothamBold
        dBtn.TextSize = 11
        dBtn.Text = "🔬 Detalhes"
        dBtn.Parent = row
        local dbC = Instance.new("UICorner")
        dbC.CornerRadius = UDim.new(0, 5)
        dbC.Parent = dBtn

        local thisFn = info.fn
        local thisInfo = info
        rBtn.MouseButton1Click:Connect(function()
            local ok2, m = restoreFn(thisFn)
            if ok2 then
                rBtn.Text = "✓ OK"
                rBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 100)
                thisInfo.hooked = false
                thisInfo.restored = true
                thisInfo.restoreMethod = m
                s.Text = "✓ Nativo"
                s.TextColor3 = Color3.fromRGB(120, 220, 150)
                row.BackgroundColor3 = Color3.fromRGB(25, 35, 30)
                hooksRemoved = hooksRemoved + 1
            else
                rBtn.Text = "✗ Falhou"
            end
        end)
        dBtn.MouseButton1Click:Connect(function()
            selectedHook = thisInfo
            switchTab("details")
            if _G.HttpSpy4_RefreshDetails then _G.HttpSpy4_RefreshDetails() end
        end)
    end)
end

local function refreshScan()
    pcall(function()
        for _, c in ipairs(scanList:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for i, info in ipairs(scanResults) do
            makeScanRow(info, i)
        end
    end)
end

local detailsScroll = Instance.new("ScrollingFrame")
detailsScroll.Size = UDim2.new(1, 0, 1, 0)
detailsScroll.BackgroundTransparency = 1
detailsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
detailsScroll.ScrollBarThickness = 6
detailsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
detailsScroll.Parent = pages["details"]

local detailsLayout = Instance.new("UIListLayout")
detailsLayout.SortOrder = Enum.SortOrder.LayoutOrder
detailsLayout.Padding = UDim.new(0, 4)
detailsLayout.Parent = detailsScroll

local function refreshDetails()
    pcall(function()
        for _, c in ipairs(detailsScroll:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then c:Destroy() end
        end
        if not selectedHook then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 40)
            empty.BackgroundTransparency = 1
            empty.Font = Enum.Font.Gotham
            empty.TextColor3 = Color3.fromRGB(180, 180, 190)
            empty.TextSize = 13
            empty.Text = "Clique em 🔬 Detalhes em um hook na aba Detecção."
            empty.Parent = detailsScroll
            return
        end
        local info = selectedHook
        local fields = {
            { "Nome", info.name },
            { "Status", info.hooked and "HOOKED" or "Nativo" },
            { "Detectado por", info.via or "?" },
            { "Source", tostring(info.info.source) },
            { "Source curto", tostring(info.info.short_src) },
            { "Linha atual", tostring(info.info.currentline) },
            { "Linha definida", tostring(info.info.linedefined) },
            { "Tipo (what)", tostring(info.info.what) },
            { "Nome debug", tostring(info.info.name) },
            { "Num upvalues", tostring(info.info.nups) },
            { "Num constantes", tostring(#info.info.constants) },
            { "Endereço", info.info.address or "?" },
        }
        for _, f in ipairs(fields) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 24)
            row.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
            row.BorderSizePixel = 0
            row.Parent = detailsScroll
            local rc = Instance.new("UICorner")
            rc.CornerRadius = UDim.new(0, 5)
            rc.Parent = row
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(0, 180, 0, 24)
            l.Position = UDim2.new(0, 8, 0, 0)
            l.BackgroundTransparency = 1
            l.Font = Enum.Font.GothamBold
            l.TextColor3 = Color3.fromRGB(180, 220, 180)
            l.TextSize = 11
            l.Text = f[1]
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Parent = row
            local v = Instance.new("TextLabel")
            v.Size = UDim2.new(1, -200, 0, 24)
            v.Position = UDim2.new(0, 190, 0, 0)
            v.BackgroundTransparency = 1
            v.Font = Enum.Font.Code
            v.TextColor3 = Color3.fromRGB(220, 220, 230)
            v.TextSize = 11
            v.Text = f[2]
            v.TextXAlignment = Enum.TextXAlignment.Left
            v.Parent = row
        end

        if #info.info.upvalues > 0 then
            local h = Instance.new("TextLabel")
            h.Size = UDim2.new(1, 0, 0, 22)
            h.BackgroundTransparency = 1
            h.Font = Enum.Font.GothamBold
            h.TextColor3 = Color3.fromRGB(255, 200, 120)
            h.TextSize = 12
            h.Text = "📦 Upvalues (" .. #info.info.upvalues .. "):"
            h.TextXAlignment = Enum.TextXAlignment.Left
            h.Parent = detailsScroll
            for _, u in ipairs(info.info.upvalues) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 24)
                row.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
                row.BorderSizePixel = 0
                row.Parent = detailsScroll
                local rc = Instance.new("UICorner")
                rc.CornerRadius = UDim.new(0, 5)
                rc.Parent = row
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(0, 200, 0, 24)
                l.Position = UDim2.new(0, 8, 0, 0)
                l.BackgroundTransparency = 1
                l.Font = Enum.Font.Code
                l.TextColor3 = Color3.fromRGB(150, 200, 255)
                l.TextSize = 11
                l.Text = "[" .. u.idx .. "] " .. u.name .. " (" .. u.type .. ")"
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.Parent = row
                local v = Instance.new("TextLabel")
                v.Size = UDim2.new(1, -310, 0, 24)
                v.Position = UDim2.new(0, 210, 0, 0)
                v.BackgroundTransparency = 1
                v.Font = Enum.Font.Code
                v.TextColor3 = Color3.fromRGB(220, 220, 230)
                v.TextSize = 11
                v.Text = u.value:sub(1, 200)
                v.TextXAlignment = Enum.TextXAlignment.Left
                v.Parent = row
            end
        end

        if #info.info.constants > 0 then
            local h = Instance.new("TextLabel")
            h.Size = UDim2.new(1, 0, 0, 22)
            h.BackgroundTransparency = 1
            h.Font = Enum.Font.GothamBold
            h.TextColor3 = Color3.fromRGB(255, 200, 120)
            h.TextSize = 12
            h.Text = "🔢 Constantes (" .. #info.info.constants .. "):"
            h.TextXAlignment = Enum.TextXAlignment.Left
            h.Parent = detailsScroll
            for _, c in ipairs(info.info.constants) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 22)
                row.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
                row.BorderSizePixel = 0
                row.Parent = detailsScroll
                local rc = Instance.new("UICorner")
                rc.CornerRadius = UDim.new(0, 5)
                rc.Parent = row
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(0, 80, 0, 22)
                l.Position = UDim2.new(0, 8, 0, 0)
                l.BackgroundTransparency = 1
                l.Font = Enum.Font.Code
                l.TextColor3 = Color3.fromRGB(150, 200, 255)
                l.TextSize = 11
                l.Text = "[" .. c.idx .. "] " .. c.type
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.Parent = row
                local v = Instance.new("TextLabel")
                v.Size = UDim2.new(1, -190, 0, 22)
                v.Position = UDim2.new(0, 90, 0, 0)
                v.BackgroundTransparency = 1
                v.Font = Enum.Font.Code
                v.TextColor3 = Color3.fromRGB(220, 220, 230)
                v.TextSize = 11
                v.Text = c.value:sub(1, 200)
                v.TextXAlignment = Enum.TextXAlignment.Left
                v.Parent = row
                local cp = Instance.new("TextButton")
                cp.Size = UDim2.new(0, 80, 0, 18)
                cp.Position = UDim2.new(1, -90, 0, 2)
                cp.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
                cp.TextColor3 = Color3.fromRGB(255, 255, 255)
                cp.Font = Enum.Font.GothamBold
                cp.TextSize = 10
                cp.Text = "📋 Copiar"
                cp.Parent = row
                local cpC = Instance.new("UICorner")
                cpC.CornerRadius = UDim.new(0, 5)
                cpC.Parent = cp
                local thisV = c.value
                cp.MouseButton1Click:Connect(function()
                    if setclipboard then pcall(setclipboard, thisV) end
                end)
            end
        end

        local exportBtn = Instance.new("TextButton")
        exportBtn.Size = UDim2.new(1, 0, 0, 32)
        exportBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 100)
        exportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        exportBtn.Font = Enum.Font.GothamBold
        exportBtn.TextSize = 12
        exportBtn.Text = "💾 Exportar JSON"
        exportBtn.Parent = detailsScroll
        local exC = Instance.new("UICorner")
        exC.CornerRadius = UDim.new(0, 6)
        exC.Parent = exportBtn
        exportBtn.MouseButton1Click:Connect(function()
            if not writefile then notify("writefile indisponivel") return end
            pcall(function()
                writefile("hook_details_" .. os.time() .. ".json", HttpService:JSONEncode({ name = info.name, hooked = info.hooked, info = info.info }))
                notify("Detalhes salvos!")
            end)
        end)
    end)
end
_G.HttpSpy4_RefreshDetails = refreshDetails

local spoofPage = pages["spoof"]
local urlBox = Instance.new("TextBox")
urlBox.Name = "UrlBox"
urlBox.Size = UDim2.new(1, 0, 0, 30)
urlBox.Position = UDim2.new(0, 0, 0, 22)
urlBox.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
urlBox.TextColor3 = Color3.fromRGB(255, 255, 255)
urlBox.Font = Enum.Font.Code
urlBox.TextSize = 12
urlBox.PlaceholderText = "URL pattern"
urlBox.Text = ""
urlBox.ClearTextOnFocus = false
urlBox.Parent = spoofPage
local ubC = Instance.new("UICorner")
ubC.CornerRadius = UDim.new(0, 6)
ubC.Parent = urlBox

local methodBox = Instance.new("TextBox")
methodBox.Name = "MethodBox"
methodBox.Size = UDim2.new(0.5, -4, 0, 30)
methodBox.Position = UDim2.new(0, 0, 0, 60)
methodBox.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
methodBox.TextColor3 = Color3.fromRGB(255, 255, 255)
methodBox.Font = Enum.Font.Code
methodBox.TextSize = 12
methodBox.Text = "*"
methodBox.ClearTextOnFocus = false
methodBox.Parent = spoofPage
local mbC = Instance.new("UICorner")
mbC.CornerRadius = UDim.new(0, 6)
mbC.Parent = methodBox

local respBox = Instance.new("TextBox")
respBox.Name = "RespBox"
respBox.Size = UDim2.new(1, 0, 0, 90)
respBox.Position = UDim2.new(0, 0, 0, 100)
respBox.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
respBox.TextColor3 = Color3.fromRGB(255, 255, 255)
respBox.Font = Enum.Font.Code
respBox.TextSize = 12
respBox.PlaceholderText = '{"valid":true}'
respBox.Text = ""
respBox.ClearTextOnFocus = false
respBox.MultiLine = true
respBox.TextWrapped = true
respBox.Parent = spoofPage
local rbC = Instance.new("UICorner")
rbC.CornerRadius = UDim.new(0, 6)
rbC.Parent = respBox

local addSpoofBtn = Instance.new("TextButton")
addSpoofBtn.Size = UDim2.new(0, 140, 0, 32)
addSpoofBtn.Position = UDim2.new(0, 0, 0, 200)
addSpoofBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
addSpoofBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addSpoofBtn.Font = Enum.Font.GothamBold
addSpoofBtn.TextSize = 12
addSpoofBtn.Text = "➕ Adicionar"
addSpoofBtn.Parent = spoofPage
local asC = Instance.new("UICorner")
asC.CornerRadius = UDim.new(0, 6)
asC.Parent = addSpoofBtn

local togSpoofBtn = Instance.new("TextButton")
togSpoofBtn.Size = UDim2.new(0, 180, 0, 32)
togSpoofBtn.Position = UDim2.new(0, 150, 0, 200)
togSpoofBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 100)
togSpoofBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
togSpoofBtn.Font = Enum.Font.GothamBold
togSpoofBtn.TextSize = 12
togSpoofBtn.Text = "🎭 Spoof: OFF"
togSpoofBtn.Parent = spoofPage
local tsC = Instance.new("UICorner")
tsC.CornerRadius = UDim.new(0, 6)
tsC.Parent = togSpoofBtn

local spoofList = Instance.new("ScrollingFrame")
spoofList.Size = UDim2.new(1, 0, 1, -244)
spoofList.Position = UDim2.new(0, 0, 0, 240)
spoofList.BackgroundTransparency = 1
spoofList.CanvasSize = UDim2.new(0, 0, 0, 0)
spoofList.ScrollBarThickness = 6
spoofList.AutomaticCanvasSize = Enum.AutomaticSize.Y
spoofList.Parent = spoofPage
local spoofLayout = Instance.new("UIListLayout")
spoofLayout.SortOrder = Enum.SortOrder.LayoutOrder
spoofLayout.Padding = UDim.new(0, 4)
spoofLayout.Parent = spoofList

_G.HttpSpy4_SetSpoofFields = function(url, method, resp)
    urlBox.Text = url or ""
    methodBox.Text = method or "*"
    respBox.Text = resp or ""
end

local function refreshSpoofs()
    pcall(function()
        for _, c in ipairs(spoofList:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for i, e in ipairs(spoofEntries) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 60)
            row.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
            row.BorderSizePixel = 0
            row.Parent = spoofList
            local rc = Instance.new("UICorner")
            rc.CornerRadius = UDim.new(0, 6)
            rc.Parent = row
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, -200, 0, 20)
            l.Position = UDim2.new(0, 10, 0, 6)
            l.BackgroundTransparency = 1
            l.Font = Enum.Font.GothamBold
            l.TextColor3 = Color3.fromRGB(220, 220, 230)
            l.TextSize = 11
            l.Text = "[" .. e.method .. "] " .. e.urlPattern
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Parent = row
            local p = Instance.new("TextLabel")
            p.Size = UDim2.new(1, -200, 0, 20)
            p.Position = UDim2.new(0, 10, 0, 30)
            p.BackgroundTransparency = 1
            p.Font = Enum.Font.Code
            p.TextColor3 = Color3.fromRGB(180, 220, 180)
            p.TextSize = 10
            p.Text = "resp: " .. e.response:sub(1, 80)
            p.TextXAlignment = Enum.TextXAlignment.Left
            p.Parent = row
            local tg = Instance.new("TextButton")
            tg.Size = UDim2.new(0, 80, 0, 24)
            tg.Position = UDim2.new(1, -180, 0, 18)
            tg.BackgroundColor3 = e.enabled and Color3.fromRGB(60, 140, 100) or Color3.fromRGB(60, 65, 80)
            tg.TextColor3 = Color3.fromRGB(255, 255, 255)
            tg.Font = Enum.Font.GothamBold
            tg.TextSize = 11
            tg.Text = e.enabled and "ON" or "OFF"
            tg.Parent = row
            local tc = Instance.new("UICorner")
            tc.CornerRadius = UDim.new(0, 5)
            tc.Parent = tg
            local dl = Instance.new("TextButton")
            dl.Size = UDim2.new(0, 80, 0, 24)
            dl.Position = UDim2.new(1, -90, 0, 18)
            dl.BackgroundColor3 = Color3.fromRGB(120, 50, 60)
            dl.TextColor3 = Color3.fromRGB(255, 255, 255)
            dl.Font = Enum.Font.GothamBold
            dl.TextSize = 11
            dl.Text = "🗑 Remover"
            dl.Parent = row
            local dc = Instance.new("UICorner")
            dc.CornerRadius = UDim.new(0, 5)
            dc.Parent = dl
            local thisIdx = i
            tg.MouseButton1Click:Connect(function()
                spoofEntries[thisIdx].enabled = not spoofEntries[thisIdx].enabled
                refreshSpoofs()
            end)
            dl.MouseButton1Click:Connect(function()
                table.remove(spoofEntries, thisIdx)
                refreshSpoofs()
            end)
        end
    end)
end

local function startLoop()
    if loopActive then return end
    loopActive = true
    loopBtn.Text = "🟢 Loop: ON"
    loopBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
    statusDot.BackgroundColor3 = Color3.fromRGB(80, 220, 100)
    statusText.Text = "Loop ativo"
    loopConn = RunService.RenderStepped:Connect(function()
        if not loopActive then return end
        pcall(performScan)
        refreshScan()
        statsText.Text = "Scans: " .. scanCount .. " | Hooks: " .. hooksRemoved .. " | Logs: " .. #capturedLogs .. " | Blocks: " .. blockedRestores
    end)
end

local function stopLoop()
    loopActive = false
    if loopConn then loopConn:Disconnect() loopConn = nil end
    loopBtn.Text = "🛑 Loop: OFF"
    loopBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    statusDot.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    statusText.Text = "Inativo"
end

loopBtn.MouseButton1Click:Connect(function()
    if loopActive then stopLoop() else startLoop() end
end)

scanBtn.MouseButton1Click:Connect(function()
    performScan()
    refreshScan()
    switchTab("scan")
end)

rescanBtn.MouseButton1Click:Connect(function()
    performScan()
    refreshScan()
end)

restoreAllBtn.MouseButton1Click:Connect(function()
    restoreAll()
    performScan()
    refreshScan()
end)

interceptBtn.MouseButton1Click:Connect(function()
    if interceptActive then
        restoreAll()
        interceptBtn.Text = "▶ Intercept: OFF"
        interceptBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 100)
        statusDot.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        statusText.Text = "Inativo"
    else
        installAll()
        interceptBtn.Text = "■ Intercept: ON"
        interceptBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
        statusDot.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
        statusText.Text = "Interceptando"
    end
end)

local autoMode = false
local autoConn = nil
autoBtn.MouseButton1Click:Connect(function()
    if autoMode then
        autoMode = false
        if autoConn then autoConn:Disconnect() autoConn = nil end
        autoBtn.Text = "⚡ Auto-Injetar"
        autoBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
        notify("Auto-injeção desativada")
    else
        autoMode = true
        autoBtn.Text = "🟢 Auto: ON"
        autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
        notify("Auto-injeção ATIVADA - vai rehookar a cada 0.5s")
        autoConn = RunService.Heartbeat:Connect(function()
            if not autoMode then return end
            for _, spec in ipairs(getTargetSpecs()) do
                local ok, fn = pcall(spec.getValue)
                fn = (ok and fn) or nil
                if fn and not wrappers[spec.name] then
                    installOne(spec)
                end
            end
        end)
        if not interceptActive then
            installAll()
            interceptBtn.Text = "■ Intercept: ON"
            interceptBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
            statusDot.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
            statusText.Text = "Interceptando (auto)"
        end
    end
end)

clearBtn.MouseButton1Click:Connect(function()
    capturedLogs = {}
    refreshLogs()
end)

saveBtn.MouseButton1Click:Connect(function()
    if not writefile then return end
    pcall(function()
        writefile("http_spy_logs_" .. os.time() .. ".json", HttpService:JSONEncode(capturedLogs))
        notify("Logs salvos!")
    end)
end)

togSpoofBtn.MouseButton1Click:Connect(function()
    spoofEnabled = not spoofEnabled
    if spoofEnabled then
        togSpoofBtn.Text = "🎭 Spoof: ON"
        togSpoofBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    else
        togSpoofBtn.Text = "🎭 Spoof: OFF"
        togSpoofBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 100)
    end
end)

addSpoofBtn.MouseButton1Click:Connect(function()
    if urlBox.Text == "" or respBox.Text == "" then return end
    table.insert(spoofEntries, {
        urlPattern = urlBox.Text,
        method = methodBox.Text == "*" and "*" or methodBox.Text,
        response = respBox.Text,
        enabled = true
    })
    refreshSpoofs()
    urlBox.Text = ""
    respBox.Text = ""
end)

local dragging, dragInput, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    stopLoop()
    if autoMode then
        autoMode = false
        if autoConn then autoConn:Disconnect() autoConn = nil end
    end
    restoreAll()
    gui:Destroy()
    _G.HttpSpy4_RefreshLogs = nil
    _G.HttpSpy4_RefreshDetails = nil
    _G.HttpSpy4_SetSpoofFields = nil
    print("[HttpSpyV4] Encerrado.")
end)

print("[HttpSpyV4] Inicializando scan...")
performScan()
refreshScan()
refreshLogs()
refreshSpoofs()
refreshDetails()
notify("Spy V4 carregado! Use Auto-Injetar para bypass")
print("[HttpSpyV4] === PRONTO ===")
print("[HttpSpyV4] Use 'Auto-Injetar' para bypass de scripts que salvam referências antes do hook")
