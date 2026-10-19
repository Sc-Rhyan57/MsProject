Made with AI, if you don't like it, that's your problem.

original code to detect UniversalSaveIstance
```lua
if game:GetService("RunService"):IsStudio() then return end

local UGCValidationService = "UGCValidationService"
local knownServices = {}

if game:FindService(UGCValidationService) then
	knownServices[UGCValidationService] = true
end

-- Crash instead of kick, because you can actually still save the game even if kicked. Crashing stops this.
local function Crash()
	for i = 1, 3000 do
		print("a")
		warn("b")
		task.spawn(function()
			error("\n")
		end)
	end
end

local function checkForNewServices()
	if not knownServices[UGCValidationService] and game:FindService(UGCValidationService) then
		Crash()
		while true do end
	end
end

task.spawn(function()
	while true do
		checkForNewServices()
		task.wait(2)
	end
end)
```


code to bypass:
```lua
-- Bloqueia o gatilho na raiz
local oldFindService
oldFindService = hookfunction(game.FindService, newcclosure(function(self, name)
    if name == "UGCValidationService" then
        return nil
    end
    return oldFindService(self, name)
end))
```


now you need bypass Hook detection by yourself ;)


"I know how to detect every single thing you did here."
- I created a separate, closed-source UniversalSaveInstance, which of course bypasses even the kick detection (why Bro is tryning crash the client? LOL!).
