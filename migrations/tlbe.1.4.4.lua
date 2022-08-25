if global.playerSettings == nil then
    goto SkipMigration
end

-- Set camera alwaysDay to true for backwards compability
for player_index, _ in pairs(game.players) do
    local playerSettings = global.playerSettings[player_index]
    if playerSettings == nil then
        goto NextPlayer
    end

    for _, camera in pairs(playerSettings.cameras) do
        camera.alwaysDay = true
    end

    ::NextPlayer::
end

::SkipMigration::
