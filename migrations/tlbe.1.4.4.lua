if storage.playerSettings == nil then
    goto SkipMigration
end

-- Set camera alwaysDay to true for backwards compatibility
-- Make tracker untilBuild available for all trackers
for player_index, _ in pairs(game.players) do
    local playerSettings = storage.playerSettings[player_index]
    if playerSettings == nil then
        goto NextPlayer
    end

    for _, camera in pairs(playerSettings.cameras) do
        camera.alwaysDay = true

        for _, tracker in pairs(camera.trackers) do
            tracker.untilBuild = tracker.type == "player"
        end
    end

    ::NextPlayer::
end

::SkipMigration::
