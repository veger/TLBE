if global.playerSettings == nil then
    goto SkipMigration
end

local Camera = require("scripts.camera")

-- Update camera save folder and name
for player_index, _ in pairs(game.players) do
    local playerSettings = global.playerSettings[player_index]
    if playerSettings == nil then
        goto NextPlayer
    end

    for _, camera in pairs(playerSettings.cameras) do
       Camera.setName(camera, camera.name)
    end

    ::NextPlayer::
end

::SkipMigration::
