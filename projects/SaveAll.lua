local guifolder = Instance.new("Folder", game:GetService("ReplicatedStorage"))
guifolder.Name = "Guiee"
for i, v in game.Players.LocalPlayer.PlayerGui:GetChildren() do
    local clone = v:Clone()
    clone.Parent = game.ReplicatedStorage.Guiee
end

local pf = Instance.new("Folder", game:GetService("ReplicatedStorage"))
pf.Name = "pf"
for i, v in game.Players.LocalPlayer.PlayerScripts:GetChildren() do
    local clone = v:Clone()
    clone.Parent = game.ReplicatedStorage.pf
end

task.wait(3)

local Params = {
 RepoURL = "https://raw.githubusercontent.com/luau/SynSaveInstance/main/",
 SSI = "saveinstance",
}
local synsaveinstance = loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)()
local Options = {}
synsaveinstance(Options)
