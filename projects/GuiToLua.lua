--[=[
  .d888b.  db    db d888888b      d888888b  .d88b.       db      db    db  .d8b.  
  VP  `8D 88    88   `88'        `~~88~~' .8P  Y8.      88      88    88 d8' `8b 
     odD' 88    88    88            88    88    88       88      88    88 88ooo88 
   .88'   88    88    88            88    88    88       88      88    88 88~~~88 
  j88.    88b  d88   .88.           88    `8b  d8'       88booo. 88b  d88 88   88 
  888888D ~Y8888P' Y888888P         YP     `Y88P'        Y88888P ~Y8888P' YP   YP 
                                                          GUI TO LUA  —  CONVERTER
]=]

local Players        = game:GetService("Players")
local LocalPlayer    = Players.LocalPlayer
local PlayerGui      = LocalPlayer:WaitForChild("PlayerGui")

local FOLDER_BASE    = "Workspace/GuiSaver/"

local SKIP_PROPS = {
    Parent = true, archivable = true, Archivable = true,
}

local DEFAULT_VALUES = {
    AnchorPoint        = Vector2.new(0, 0),
    BackgroundTransparency = 0,
    BorderSizePixel    = 1,
    ClipsDescendants   = false,
    Rotation           = 0,
    Selectable         = false,
    SizeConstraint     = Enum.SizeConstraint.RelativeXY,
    Visible            = true,
    ZIndex             = 1,
    AutomaticSize      = Enum.AutomaticSize.None,
    TextTransparency   = 0,
    TextStrokeTransparency = 1,
    TextXAlignment     = Enum.TextXAlignment.Center,
    TextYAlignment     = Enum.TextYAlignment.Center,
    TextWrapped        = false,
    TextScaled         = false,
    RichText           = false,
    ClearTextOnFocus   = true,
    MultiLine          = false,
    ImageTransparency  = 0,
    ImageColor3        = Color3.fromRGB(255, 255, 255),
    ScaleType          = Enum.ScaleType.Stretch,
    SliceScale         = 1,
    TileSize           = UDim2.new(0, 100, 0, 100),
    BorderColor3       = Color3.fromRGB(27, 42, 53),
    BackgroundColor3   = Color3.fromRGB(255, 255, 255),
    TextColor3         = Color3.fromRGB(27, 42, 53),
    FontFace           = Font.new("rbxasset://fonts/families/LegacyArial.json"),
    TextSize           = 14,
    LineHeight         = 1,
    MaxVisibleGraphemes = -1,
    LayoutOrder        = 0,
    CornerRadius       = UDim.new(0, 0),
}

local GUI_PROPS = {
    GuiObject = {
        "AnchorPoint","BackgroundColor3","BackgroundTransparency","BorderColor3",
        "BorderMode","BorderSizePixel","ClipsDescendants","LayoutOrder","Position",
        "Rotation","Selectable","Size","SizeConstraint","Visible","ZIndex",
        "AutomaticSize","Active","Interactable",
    },
    Frame = { "Style" },
    TextLabel = {
        "Font","FontFace","LineHeight","MaxVisibleGraphemes","RichText","Text",
        "TextColor3","TextScaled","TextSize","TextStrokeColor3","TextStrokeTransparency",
        "TextTransparency","TextTruncate","TextWrapped","TextXAlignment","TextYAlignment",
    },
    TextButton = {
        "Font","FontFace","LineHeight","MaxVisibleGraphemes","RichText","Text",
        "TextColor3","TextScaled","TextSize","TextStrokeColor3","TextStrokeTransparency",
        "TextTransparency","TextTruncate","TextWrapped","TextXAlignment","TextYAlignment",
        "AutoButtonColor","Modal","Selected","Style",
    },
    TextBox = {
        "ClearTextOnFocus","Font","FontFace","LineHeight","MaxVisibleGraphemes",
        "MultiLine","PlaceholderColor3","PlaceholderText","RichText","Text",
        "TextColor3","TextEditable","TextScaled","TextSize","TextStrokeColor3",
        "TextStrokeTransparency","TextTransparency","TextTruncate","TextWrapped",
        "TextXAlignment","TextYAlignment",
    },
    ImageLabel = {
        "Image","ImageColor3","ImageRectOffset","ImageRectSize","ImageTransparency",
        "ResampleMode","ScaleType","SliceCenter","SliceScale","TileSize",
    },
    ImageButton = {
        "Image","ImageColor3","ImageRectOffset","ImageRectSize","ImageTransparency",
        "ResampleMode","ScaleType","SliceCenter","SliceScale","TileSize",
        "AutoButtonColor","HoverImage","Modal","PressedImage","Selected","Style",
    },
    ScrollingFrame = {
        "AutomaticCanvasSize","BottomImage","CanvasPosition","CanvasSize",
        "ElasticBehavior","HorizontalScrollBarInset","MidImage","ScrollBarImageColor3",
        "ScrollBarImageTransparency","ScrollBarThickness","ScrollingDirection",
        "ScrollingEnabled","TopImage","VerticalScrollBarInset","VerticalScrollBarPosition",
    },
    ViewportFrame = {
        "Ambient","CurrentCamera","ImageColor3","ImageTransparency","LightColor",
        "LightDirection",
    },
    VideoFrame = { "Looped","Playing","TimePosition","Video","Volume" },
    ScreenGui = {
        "DisplayOrder","Enabled","IgnoreGuiInset","OnTopOfCoreBlur","ResetOnSpawn",
        "SafeAreaCompatibility","ScreenInsets","ZIndexBehavior",
    },
    BillboardGui = {
        "Active","AlwaysOnTop","Brightness","ClipsDescendants","Enabled",
        "ExtentsOffset","ExtentsOffsetWorldSpace","LightInfluence","MaxDistance",
        "ResetOnSpawn","Size","SizeOffset","StudsOffset","StudsOffsetWorldSpace",
        "ZIndexBehavior",
    },
    SurfaceGui = {
        "Active","AlwaysOnTop","Brightness","ClipsDescendants","Enabled",
        "Face","LightInfluence","PixelsPerStud","ResetOnSpawn","SizingMode",
        "ToolPunchThroughDistance","ZIndexBehavior",
    },
    UICorner           = { "CornerRadius" },
    UIStroke           = { "ApplyStrokeMode","Color","LineJoinMode","Thickness","Transparency" },
    UIPadding          = { "PaddingBottom","PaddingLeft","PaddingRight","PaddingTop" },
    UIListLayout       = {
        "FillDirection","HorizontalAlignment","ItemLineAlignment","Padding",
        "SortOrder","VerticalAlignment","Wraps",
    },
    UIGridLayout       = {
        "CellPaddingHorizontal","CellPaddingVertical","CellSize","FillDirection",
        "FillDirectionMaxCells","HorizontalAlignment","SortOrder","StartCorner",
        "VerticalAlignment",
    },
    UITableLayout      = {
        "FillDirection","FillEmptySpaceColumns","FillEmptySpaceRows",
        "HorizontalAlignment","MajorAxis","Padding","SortOrder","VerticalAlignment",
    },
    UIPageLayout       = {
        "Animated","Circular","EasingDirection","EasingStyle","FillDirection",
        "GamepadInputEnabled","HorizontalAlignment","Padding","ScrollWheelInputEnabled",
        "SortOrder","TouchInputEnabled","TweenTime","VerticalAlignment",
    },
    UIFlexItem         = { "FlexMode","GrowRatio","ItemLineAlignment","ShrinkRatio" },
    UIScale            = { "Scale" },
    UIAspectRatioConstraint = { "AspectRatio","AspectType","DominantAxis" },
    UISizeConstraint   = { "MaxSize","MinSize" },
    UITextSizeConstraint = { "MaxTextSize","MinTextSize" },
    UIGradient         = { "Color","Enabled","Offset","Rotation","Transparency" },
    SelectionBox       = {
        "Color3","LineThickness","SurfaceColor3","SurfaceTransparency","Transparency",
    },
    SelectionSphere    = {
        "Color3","SurfaceColor3","SurfaceTransparency","Transparency",
    },
    Path2D             = { "Closed","SelectedKeypoint","Thickness","Visible" },
}

local SCRIPT_CLASSES = { LocalScript = true, ModuleScript = true, Script = true }

local function tryGetProperty(inst, prop)
    local ok, val = pcall(function() return inst[prop] end)
    return ok, val
end

local function serializeValue(v)
    local t = typeof(v)
    if t == "string" then
        return string.format("[[%s]]", v:gsub("%]%]", "]] .. \"]]\" .. [["))
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "number" then
        if v == math.floor(v) then return tostring(v) end
        return string.format("%.6g", v)
    elseif t == "Color3" then
        return string.format("Color3.fromRGB(%d, %d, %d)",
            math.round(v.R * 255), math.round(v.G * 255), math.round(v.B * 255))
    elseif t == "Vector2" then
        return string.format("Vector2.new(%s, %s)", serializeValue(v.X), serializeValue(v.Y))
    elseif t == "Vector3" then
        return string.format("Vector3.new(%s, %s, %s)",
            serializeValue(v.X), serializeValue(v.Y), serializeValue(v.Z))
    elseif t == "UDim" then
        return string.format("UDim.new(%s, %s)", serializeValue(v.Scale), serializeValue(v.Offset))
    elseif t == "UDim2" then
        return string.format("UDim2.new(%s, %s, %s, %s)",
            serializeValue(v.X.Scale), serializeValue(v.X.Offset),
            serializeValue(v.Y.Scale), serializeValue(v.Y.Offset))
    elseif t == "Rect" then
        return string.format("Rect.new(%s, %s, %s, %s)",
            serializeValue(v.Min.X), serializeValue(v.Min.Y),
            serializeValue(v.Max.X), serializeValue(v.Max.Y))
    elseif t == "EnumItem" then
        return tostring(v)
    elseif t == "Font" then
        local weight = tostring(v.Weight)
        local style  = tostring(v.Style)
        return string.format("Font.new([[%s]], %s, %s)", v.Family, weight, style)
    elseif t == "ColorSequence" then
        local kps = {}
        for _, kp in v.Keypoints do
            table.insert(kps, string.format("ColorSequenceKeypoint.new(%s, %s)",
                serializeValue(kp.Time), serializeValue(kp.Value)))
        end
        return string.format("ColorSequence.new({%s})", table.concat(kps, ", "))
    elseif t == "NumberSequence" then
        local kps = {}
        for _, kp in v.Keypoints do
            table.insert(kps, string.format("NumberSequenceKeypoint.new(%s, %s, %s)",
                serializeValue(kp.Time), serializeValue(kp.Value), serializeValue(kp.Envelope)))
        end
        return string.format("NumberSequence.new({%s})", table.concat(kps, ", "))
    elseif t == "NumberRange" then
        return string.format("NumberRange.new(%s, %s)", serializeValue(v.Min), serializeValue(v.Max))
    elseif t == "CFrame" then
        local c = {v:GetComponents()}
        local parts = {}
        for _, n in c do table.insert(parts, serializeValue(n)) end
        return string.format("CFrame.new(%s)", table.concat(parts, ", "))
    elseif t == "PhysicalProperties" then
        return string.format("PhysicalProperties.new(%s, %s, %s, %s, %s)",
            serializeValue(v.Density), serializeValue(v.Friction),
            serializeValue(v.Elasticity), serializeValue(v.FrictionWeight),
            serializeValue(v.ElasticityWeight))
    elseif t == "BrickColor" then
        return string.format("BrickColor.new([[%s]])", tostring(v))
    elseif t == "Ray" then
        return string.format("Ray.new(%s, %s)", serializeValue(v.Origin), serializeValue(v.Direction))
    elseif t == "Axes" then
        local parts = {}
        if v.X then table.insert(parts, "Enum.Axis.X") end
        if v.Y then table.insert(parts, "Enum.Axis.Y") end
        if v.Z then table.insert(parts, "Enum.Axis.Z") end
        return string.format("Axes.new(%s)", table.concat(parts, ", "))
    elseif t == "Faces" then
        local parts = {}
        for _, face in {"Top","Bottom","Left","Right","Front","Back"} do
            if v[face] then table.insert(parts, "Enum.NormalId."..face) end
        end
        return string.format("Faces.new(%s)", table.concat(parts, ", "))
    else
        return nil
    end
end

local function valuesEqual(a, b)
    if typeof(a) ~= typeof(b) then return false end
    local t = typeof(a)
    if t == "Color3" then
        return math.round(a.R*255)==math.round(b.R*255)
            and math.round(a.G*255)==math.round(b.G*255)
            and math.round(a.B*255)==math.round(b.B*255)
    elseif t == "UDim2" then
        return a.X.Scale==b.X.Scale and a.X.Offset==b.X.Offset
            and a.Y.Scale==b.Y.Scale and a.Y.Offset==b.Y.Offset
    elseif t == "UDim" then
        return a.Scale==b.Scale and a.Offset==b.Offset
    elseif t == "Vector2" then
        return a.X==b.X and a.Y==b.Y
    elseif t == "Vector3" then
        return a.X==b.X and a.Y==b.Y and a.Z==b.Z
    elseif t == "Font" then
        return a.Family==b.Family and a.Weight==b.Weight and a.Style==b.Style
    elseif t == "EnumItem" then
        return a==b
    else
        return a==b
    end
end

local function getPropsForClass(className)
    local props = {}
    local seen  = {}
    local base = GUI_PROPS["GuiObject"] or {}
    for _, p in base do
        if not seen[p] then seen[p]=true; table.insert(props, p) end
    end
    local specific = GUI_PROPS[className]
    if specific then
        for _, p in specific do
            if not seen[p] then seen[p]=true; table.insert(props, p) end
        end
    end
    return props
end

local function toHex(n)
    local hex = ""
    local chars = "0123456789abcdefghijklmnopqrstuvwxyz"
    while n > 0 do
        local r = n % 36
        hex = chars:sub(r+1,r+1) .. hex
        n = math.floor(n / 36)
    end
    return hex == "" and "0" or hex
end

local function resolvePathFrom(root, instance)
    local chain = {}
    local cur = instance
    while cur and cur ~= root do
        table.insert(chain, 1, cur.Name)
        cur = cur.Parent
    end
    if root == game then
        return "game." .. table.concat(chain, ".")
    end
    return root.Name .. (chain[1] and ("." .. table.concat(chain, ".")) or "")
end

local function convert(rootInstance)
    local lines       = {}
    local scriptLines = {}
    local idMap       = {}
    local counter     = 0
    local totalInst   = 0
    local totalScript = 0
    local totalModule = 0
    local totalTags   = 0

    local ordered = {}
    local function collectAll(inst)
        table.insert(ordered, inst)
        for _, child in inst:GetChildren() do
            collectAll(child)
        end
    end
    collectAll(rootInstance)

    for _, inst in ordered do
        counter += 1
        local id = toHex(counter)
        idMap[inst] = id
    end

    table.insert(lines, string.format("local G2L = {};"))
    table.insert(lines, "")

    local moduleIds    = {}
    local moduleLines  = {}

    for _, inst in ordered do
        local id        = idMap[inst]
        local className = inst.ClassName
        local parentId  = idMap[inst.Parent]
        local isRoot    = inst == rootInstance

        if SCRIPT_CLASSES[className] then
            totalScript += 1
            if className == "ModuleScript" then totalModule += 1 end
            local src = ""
            if decompile then
                local ok, result = pcall(decompile, inst)
                src = (ok and result) or ("--[[ Failed to decompile: " .. tostring(result) .. " ]]")
            elseif getscriptbytecode then
                local ok, bc = pcall(getscriptbytecode, inst)
                src = ok and bc and ("--[[ Bytecode extracted — run through a Luau decompiler ]]\n--[[ Length: " .. #bc .. " bytes ]]") or "--[[ No bytecode ]]"
            else
                src = "--[[ Decompiler not available ]]"
            end
            table.insert(scriptLines, {
                id     = id,
                inst   = inst,
                class  = className,
                source = src,
            })
        end

        local parentRef
        if isRoot then
            parentRef = "nil"
        elseif parentId then
            parentRef = string.format('G2L["%s"]', parentId)
        else
            parentRef = "nil"
        end

        local pathComment
        local ok2, pathStr = pcall(function() return inst:GetFullName() end)
        pathComment = ok2 and pathStr or inst.Name

        table.insert(lines, string.format("-- %s", pathComment))
        table.insert(lines, string.format('G2L["%s"] = Instance.new("%s", %s);', id, className, parentRef))

        local props = getPropsForClass(className)

        if className == "ScreenGui" or className == "BillboardGui" or className == "SurfaceGui" then
            local specific = GUI_PROPS[className] or {}
            props = {}
            local seen = {}
            for _, p in specific do
                if not seen[p] then seen[p]=true; table.insert(props, p) end
            end
        end

        props[#props+1] = "Name"

        for _, prop in props do
            if SKIP_PROPS[prop] then continue end
            local ok, val = tryGetProperty(inst, prop)
            if not ok then continue end
            local default = DEFAULT_VALUES[prop]
            if default ~= nil and valuesEqual(val, default) and prop ~= "Name" and prop ~= "Size" and prop ~= "Position" then
                continue
            end
            local serialized = serializeValue(val)
            if serialized then
                table.insert(lines, string.format('G2L["%s"]["%s"] = %s;', id, prop, serialized))
            else
                table.insert(lines, string.format('-- [WARN] Cannot serialize "%s" (type: %s)', prop, typeof(val)))
            end
        end

        local ok3, attrs = pcall(function() return inst:GetAttributes() end)
        if ok3 then
            for attrName, attrVal in attrs do
                local serialized = serializeValue(attrVal)
                if serialized then
                    table.insert(lines, string.format('G2L["%s"]:SetAttribute("%s", %s);', id, attrName, serialized))
                end
            end
        end

        local ok4, tags = pcall(function() return inst:GetTags() end)
        if ok4 and #tags > 0 then
            for _, tag in tags do
                totalTags += 1
                table.insert(lines, string.format('G2L["%s"]:AddTag([[%s]]);', id, tag))
            end
        end

        table.insert(lines, "")
        totalInst += 1
    end

    if #scriptLines > 0 then
        table.insert(lines, "-- Require G2L wrapper")
        table.insert(lines, "local G2L_REQUIRE = require;")
        table.insert(lines, "local G2L_MODULES = {};")
        table.insert(lines, "local function require(Module:ModuleScript)")
        table.insert(lines, "    local ModuleState = G2L_MODULES[Module];")
        table.insert(lines, "    if ModuleState then")
        table.insert(lines, "        if not ModuleState.Required then")
        table.insert(lines, "            ModuleState.Required = true;")
        table.insert(lines, "            ModuleState.Value = ModuleState.Closure();")
        table.insert(lines, "        end")
        table.insert(lines, "        return ModuleState.Value;")
        table.insert(lines, "    end;")
        table.insert(lines, "    return G2L_REQUIRE(Module);")
        table.insert(lines, "end")
        table.insert(lines, "")

        for _, s in scriptLines do
            if s.class == "ModuleScript" then
                table.insert(lines, string.format('G2L_MODULES[G2L["%s"]] = {', s.id))
                table.insert(lines, "Closure = function()")
                table.insert(lines, string.format('    local script = G2L["%s"];', s.id))
                for _, srcLine in s.source:split("\n") do
                    table.insert(lines, "    " .. srcLine)
                end
                table.insert(lines, "end;")
                table.insert(lines, "};")
                table.insert(lines, "")
            elseif s.class == "LocalScript" then
                table.insert(lines, string.format('-- LocalScript: %s', s.inst:GetFullName()))
                table.insert(lines, string.format('task.spawn(function()'))
                table.insert(lines, string.format('    local script = G2L["%s"];', s.id))
                for _, srcLine in s.source:split("\n") do
                    table.insert(lines, "    " .. srcLine)
                end
                table.insert(lines, "end)")
                table.insert(lines, "")
            end
        end
    end

    table.insert(lines, string.format('return G2L["%s"], require;', idMap[rootInstance]))

    local header = string.format(
        "-- Instances: %d | Scripts: %d | Modules: %d | Tags: %d",
        totalInst, totalScript, totalModule, totalTags
    )
    table.insert(lines, 1, "")
    table.insert(lines, 1, header)

    return table.concat(lines, "\n"), rootInstance.Name, scriptLines
end

local function ensureFolder(path)
    if isfolder and not isfolder(path) then
        makefolder(path)
    end
end

local function saveConversion(guiName, mainCode, scriptEntries)
    local base = FOLDER_BASE .. guiName .. "/"
    ensureFolder("Workspace")
    ensureFolder("Workspace/GuiSaver")
    ensureFolder(base)

    local mainPath = base .. guiName .. ".lua"
    writefile(mainPath, mainCode)

    if #scriptEntries > 0 then
        local scriptsFolder = base .. "Scripts/"
        ensureFolder(scriptsFolder)
        for _, s in scriptEntries do
            local safeName = s.inst.Name:gsub("[^%w_%-]", "_")
            local ext = s.class == "ModuleScript" and "module.lua" or "lua"
            local filePath = scriptsFolder .. safeName .. "." .. ext
            local content = string.format(
                "-- Class: %s\n-- Path: %s\n-- Extracted by GuiToLua Converter\n\n%s",
                s.class, s.inst:GetFullName(), s.source
            )
            writefile(filePath, content)
        end
    end

    return mainPath
end

local function resolveInstanceFromPath(path)
    path = path:match("^%s*(.-)%s*$")
    if path == "" then return nil, "Caminho vazio" end

    local env = setmetatable({
        game            = game,
        workspace       = workspace,
        gethui          = gethui or function() return game:GetService("CoreGui") end,
    }, {
        __index = function(_, k)
            local ok, svc = pcall(function() return game:GetService(k) end)
            if ok and svc then return svc end
            return nil
        end
    })

    local chunk, err = loadstring("return " .. path)
    if not chunk then
        return nil, "Syntax error: " .. tostring(err)
    end

    setfenv(chunk, env)
    local ok, result = pcall(chunk)
    if not ok then
        return nil, "Runtime error: " .. tostring(result)
    end
    if typeof(result) ~= "Instance" then
        return nil, "O caminho não retornou uma Instance (retornou " .. typeof(result) .. ")"
    end
    return result, nil
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "G2L_Converter"
ScreenGui.ResetOnSpawn     = false
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset   = true
ScreenGui.DisplayOrder     = 999
ScreenGui.Parent           = PlayerGui

local Main = Instance.new("Frame")
Main.Name                   = "Main"
Main.Size                   = UDim2.new(0, 500, 0, 210)
Main.Position               = UDim2.new(0.5, -250, 0.5, -105)
Main.BackgroundColor3       = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel        = 0
Main.Active                 = true
Main.Draggable              = true
Main.Parent                 = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent       = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color       = Color3.fromRGB(60, 60, 90)
Stroke.Thickness   = 1.5
Stroke.Parent      = Main

local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent       = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size             = UDim2.new(1, 0, 0, 10)
TitleFix.Position         = UDim2.new(0, 0, 1, -10)
TitleFix.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
TitleFix.BorderSizePixel  = 0
TitleFix.Parent           = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size                = UDim2.new(1, -60, 1, 0)
TitleLabel.Position            = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text                = "GUI → LUA  CONVERTER"
TitleLabel.TextColor3          = Color3.fromRGB(200, 200, 255)
TitleLabel.TextSize            = 14
TitleLabel.Font                = Enum.Font.GothamBold
TitleLabel.TextXAlignment      = Enum.TextXAlignment.Left
TitleLabel.Parent              = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size                   = UDim2.new(0, 36, 0, 26)
CloseBtn.Position               = UDim2.new(1, -42, 0, 6)
CloseBtn.BackgroundColor3       = Color3.fromRGB(200, 50, 50)
CloseBtn.Text                   = "✕"
CloseBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize               = 13
CloseBtn.Font                   = Enum.Font.GothamBold
CloseBtn.BorderSizePixel        = 0
CloseBtn.Parent                 = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent       = CloseBtn

local PathLabel = Instance.new("TextLabel")
PathLabel.Size                   = UDim2.new(1, -24, 0, 18)
PathLabel.Position               = UDim2.new(0, 12, 0, 46)
PathLabel.BackgroundTransparency = 1
PathLabel.Text                   = "Caminho da GUI"
PathLabel.TextColor3             = Color3.fromRGB(140, 140, 180)
PathLabel.TextSize               = 12
PathLabel.Font                   = Enum.Font.Gotham
PathLabel.TextXAlignment         = Enum.TextXAlignment.Left
PathLabel.Parent                 = Main

local PathBox = Instance.new("TextBox")
PathBox.Size                   = UDim2.new(1, -24, 0, 36)
PathBox.Position               = UDim2.new(0, 12, 0, 66)
PathBox.BackgroundColor3       = Color3.fromRGB(30, 30, 44)
PathBox.BorderSizePixel        = 0
PathBox.Text                   = ""
PathBox.PlaceholderText        = 'ex: game:GetService("CoreGui").MyGui'
PathBox.TextColor3             = Color3.fromRGB(220, 220, 255)
PathBox.PlaceholderColor3      = Color3.fromRGB(90, 90, 120)
PathBox.TextSize               = 12
PathBox.Font                   = Enum.Font.Code
PathBox.TextXAlignment         = Enum.TextXAlignment.Left
PathBox.ClearTextOnFocus       = false
PathBox.TextEditable           = true
PathBox.Parent                 = Main

local PBCorner = Instance.new("UICorner")
PBCorner.CornerRadius = UDim.new(0, 7)
PBCorner.Parent       = PathBox

local PBStroke = Instance.new("UIStroke")
PBStroke.Color       = Color3.fromRGB(70, 70, 110)
PBStroke.Thickness   = 1
PBStroke.Parent      = PathBox

local PBPad = Instance.new("UIPadding")
PBPad.PaddingLeft  = UDim.new(0, 10)
PBPad.PaddingRight = UDim.new(0, 10)
PBPad.Parent       = PathBox

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size                   = UDim2.new(1, -24, 0, 28)
StatusLabel.Position               = UDim2.new(0, 12, 0, 110)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text                   = "Aguardando..."
StatusLabel.TextColor3             = Color3.fromRGB(120, 120, 160)
StatusLabel.TextSize               = 12
StatusLabel.Font                   = Enum.Font.Gotham
StatusLabel.TextXAlignment         = Enum.TextXAlignment.Left
StatusLabel.TextWrapped            = true
StatusLabel.Parent                 = Main

local ReconstructBtn = Instance.new("TextButton")
ReconstructBtn.Size               = UDim2.new(1, -24, 0, 40)
ReconstructBtn.Position           = UDim2.new(0, 12, 0, 156)
ReconstructBtn.BackgroundColor3   = Color3.fromRGB(80, 60, 200)
ReconstructBtn.BorderSizePixel    = 0
ReconstructBtn.Text               = "⚡ Reconstruct"
ReconstructBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
ReconstructBtn.TextSize           = 15
ReconstructBtn.Font               = Enum.Font.GothamBold
ReconstructBtn.Parent             = Main

local RBCorner = Instance.new("UICorner")
RBCorner.CornerRadius = UDim.new(0, 8)
RBCorner.Parent       = ReconstructBtn

local function setStatus(msg, color)
    StatusLabel.Text       = msg
    StatusLabel.TextColor3 = color or Color3.fromRGB(120, 120, 160)
end

local busy = false

ReconstructBtn.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true
    ReconstructBtn.Text             = "⏳ Processando..."
    ReconstructBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)

    task.spawn(function()
        local path = PathBox.Text:match("^%s*(.-)%s*$")

        if path == "" then
            setStatus("❌ Insira um caminho válido.", Color3.fromRGB(255, 80, 80))
            ReconstructBtn.Text             = "⚡ Reconstruct"
            ReconstructBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
            busy = false
            return
        end

        setStatus("🔍 Resolvendo caminho...", Color3.fromRGB(180, 180, 60))
        task.wait(0.05)

        local inst, err = resolveInstanceFromPath(path)

        if not inst then
            setStatus("❌ " .. tostring(err), Color3.fromRGB(255, 80, 80))
            ReconstructBtn.Text             = "⚡ Reconstruct"
            ReconstructBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
            busy = false
            return
        end

        setStatus("⚙️ Convertendo GUI...", Color3.fromRGB(180, 180, 60))
        task.wait(0.05)

        local ok, result, name, scriptEntries = pcall(function()
            local code, guiName, scripts = convert(inst)
            return code, guiName, scripts
        end)

        if not ok then
            setStatus("❌ Erro na conversão: " .. tostring(result), Color3.fromRGB(255, 80, 80))
            ReconstructBtn.Text             = "⚡ Reconstruct"
            ReconstructBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
            busy = false
            return
        end

        if not writefile then
            setStatus("❌ writefile não disponível neste executor.", Color3.fromRGB(255, 80, 80))
            ReconstructBtn.Text             = "⚡ Reconstruct"
            ReconstructBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
            busy = false
            return
        end

        setStatus("💾 Salvando arquivos...", Color3.fromRGB(180, 180, 60))
        task.wait(0.05)

        local saveOk, savePath = pcall(saveConversion, name, result, scriptEntries)

        if saveOk then
            local scriptCount = #scriptEntries
            setStatus(
                string.format("✅ Salvo em: %s | %d script(s) extraído(s)", savePath, scriptCount),
                Color3.fromRGB(80, 255, 120)
            )
        else
            setStatus("⚠️ Conversão OK mas erro ao salvar: " .. tostring(savePath), Color3.fromRGB(255, 200, 60))
        end

        ReconstructBtn.Text             = "⚡ Reconstruct"
        ReconstructBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
        busy = false
    end)
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

setStatus("✅ Pronto. Insira o caminho e clique em Reconstruct.", Color3.fromRGB(100, 200, 140))
