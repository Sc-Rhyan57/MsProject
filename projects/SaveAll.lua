--[[ MOVE 1 ]]--
local guifolder = Instance.new("Folder", game:GetService("ReplicatedStorage"))
guifolder.Name = "Guiee"
for i, v in game.Players.LocalPlayer.PlayerGui:GetChildren() do
v.Parent = game.ReplicatedStorage.Guiee
end

--[[ MOVE 2 ]]--
local pf = Instance.new("Folder", game:GetService("ReplicatedStorage"))
pf.Name = "pf"
for i, v in game.Players.LocalPlayer.PlayerScripts:GetChildren() do
v.Parent = game.ReplicatedStorage.pf
end

--[[ AGUARDA ]]--
task.wait(3)

--[[ COMEÇA CLONAR ]]--
local Params = {
 RepoURL = "https://raw.githubusercontent.com/luau/SynSaveInstance/main/",
 SSI = "saveinstance",
}
local synsaveinstance = loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)()
local Options = {} -- Documentation here https://luau.github.io/UniversalSynSaveInstance/api/SynSaveInstance
synsaveinstance(Options)
