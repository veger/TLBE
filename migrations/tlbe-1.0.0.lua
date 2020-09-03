if global.playerSettings == nil then
    goto SkipMigration
end

for player_index, _ in pairs(game.players) do
    local playerSettings = global.playerSettings[player_index]
    if playerSettings == nil then
        goto NextPlayer
    end

    for _, tracker in pairs(playerSettings.trackers) do
        if tracker.type == "player" then
            tracker.smooth = false
        else
            tracker.smooth = true
        end
    end

    ::NextPlayer::
end

::SkipMigration::
