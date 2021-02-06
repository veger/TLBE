if global.playerSettings == nil then
    goto SkipMigration
end

-- Set set camera surface to the default surface
for player_index, _ in pairs(game.players) do
    local playerSettings = global.playerSettings[player_index]
    if playerSettings == nil then
        goto NextPlayer
    end

    for _, camera in pairs(playerSettings.cameras) do
        camera.surfaceName = game.surfaces[1].name
    end

    ::NextPlayer::
end

::SkipMigration::
