local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local guifolder = Instance.new("Folder")
guifolder.Name = "Guiee"
guifolder.Parent = ReplicatedStorage

local pf = Instance.new("Folder")
pf.Name = "pf"
pf.Parent = ReplicatedStorage

local function cloneWithDelay(parent, targetFolder)
    for _, v in ipairs(parent:GetChildren()) do
        pcall(function()
            local clone = v:Clone()
            clone.Parent = targetFolder
        end)
        RunService.Heartbeat:Wait()
    end
end

cloneWithDelay(LocalPlayer:WaitForChild("PlayerGui"), guifolder)
cloneWithDelay(LocalPlayer:WaitForChild("PlayerScripts"), pf)

task.wait(3)

local Params = {
    RepoURL = "https://raw.githubusercontent.com/luau/SynSaveInstance/main/",
    SSI = "saveinstance",
}

local synsaveinstance = loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)()

local Options = {
    mode = "optimized",
    Binary = true,
    CompressionMode = "zstd",
    CompressionLevel = 9,
    SafeMode = true,
    KillAllScripts = true,
    BoostFPS = true,
    IsolateLocalPlayer = true,
    IsolatePlayers = true,
    SavePlayerCharacters = true,
    Decompile = true,
    scriptcache = true,
    DecompileTimeout = 30,
    IgnoreSpecialProperties = true,
    AlternativeWritefile = true,
    IgnoreDefaultProperties = true,
    ShowStatus = true,
    AntiIdle = true
}

synsaveinstance(Options)
