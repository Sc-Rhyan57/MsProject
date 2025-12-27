if not game.PlaceId = 6516141723 then
return
else
local pl = game:GetService("Players").LocalPlayer
local gui = pl.PlayerGui:FindFirstChild("NameUI" .. pl.Name)

local function Msg(message)
if require then require(pl.PlayerGui.MainUI.Initiator.Main_Lobby).caption(message, true)
else
print(message)
end
end


gui.Stuff.Frame.CompletionistCrazy.Visible = true
gui.Stuff.Frame.Completionist.Visible = false
Msg("Made By Rhyan57 & NotPolar")
end
