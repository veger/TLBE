if global.playerSettings == nil then
    goto SkipMigration
end

-- Set new camera setting to its previous (default) value
for player_index, _ in pairs(game.players) do
    local playerSettings = global.playerSettings[player_index]
    if playerSettings == nil then
        goto NextPlayer
    end

    for _, camera in pairs(playerSettings.cameras) do
        camera.entityInfo = false
    end

    ::NextPlayer::
end

::SkipMigration::
