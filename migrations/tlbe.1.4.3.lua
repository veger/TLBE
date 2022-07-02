if global.playerSettings == nil then
    goto SkipMigration
end

local Camera = require("scripts.camera")

-- Update camera save folder and name
-- Move sequential screenshot number to camera(s)
for player_index, _ in pairs(game.players) do
    local playerSettings = global.playerSettings[player_index]
    if playerSettings == nil then
        goto NextPlayer
    end

    for _, camera in pairs(playerSettings.cameras) do
       Camera.setName(camera, camera.name)
       camera.screenshotNumber = playerSettings.screenshotNumber
    end

    playerSettings.screenshotNumber = nil

    ::NextPlayer::
end

::SkipMigration::
