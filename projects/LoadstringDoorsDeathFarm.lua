local MsdoorsNotify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc-Rhyan57/Notification-doorsAPI/refs/heads/main/Msdoors/MsdoorsApi.lua"))()


local PlaceId = game.PlaceId

if PlaceId == 6516141723 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc-Rhyan57/DoorsDeathFarm/refs/heads/main/Modifiers/mods.lua"))()
end

if PlaceId == 2440500124 then
MsdoorsNotify(
    "Wrong place, wrong time...", 
    "Run the script in the Lobby, not in the game!, 
    "", 
    "rbxassetid://6023426923", 
    Color3.new(0, 1, 0), 
    10
    )
task.wait(5)
game:GetService("Players").LocalPlayer:Kick("Only run in lobby, not in game!\n https://dsc.gg/betterstar Only run in lobby, not in game! \n Found a Bug? https://dsc.gg/betterstar")

end

print("PlaceId não reconhecido:", PlaceId)
