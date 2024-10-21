if storage.playerSettings == nil then
    goto SkipMigration
end

local Camera = require("scripts.camera")
local Tracker = require("scripts.tracker")

-- Update camera with current active tracker to prevent possible (zooming) issues
for player_index, _ in pairs(game.players) do
    local playerSettings = storage.playerSettings[player_index]
    if playerSettings == nil then
        goto NextPlayer
    end

    for _, camera in pairs(playerSettings.cameras) do
        local _, activeTracker = Tracker.findActiveTracker(camera.trackers, camera.surfaceName)
        Camera.SetActiveTracker(camera, activeTracker)
    end

    ::NextPlayer::
end

::SkipMigration::
