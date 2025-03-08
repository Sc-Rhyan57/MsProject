AQUI TEM ALGUNS COMBOS DE MODIFIERS QUE O [REGINALDOO](https://youtube.com/@REIginaldoo) usa em seus videos.

[![Tema CORRIDA MALUCA no DOORS! 👁️](https://img.youtube.com/vi/tGmZlo4ulQI/maxresdefault.jpg)](https://youtu.be/tGmZlo4ulQI)
```lua
local msproject-args = {
    [1] = {
        ["Mods"] = {
            [1] = "PlayerFastest",
            [2] = "EntitiesMore",
            [3] = "BackdoorHaste",
            [4] = "SnareMoster",
            [5] = "Giggle"
        },
        ["Settings"] = {},
        ["Destination"] = "Hotel", --[[ FLOOR QUE FUNCIONARÁ ]]--
        ["FriendsOnly"] = false, --[[ APENAS AMIGOS | false = desativado | true = ativado ]]--
        ["MaxPlayers"] = "40" --[[ MÁXIMO DE JOGADORES ]]--
    }
}

game:GetService("ReplicatedStorage").RemotesFolder.CreateElevator:FireServer(unpack(msproject-args))
```
