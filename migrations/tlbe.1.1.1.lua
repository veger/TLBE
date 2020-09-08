if global.playerSettings == nil then
    goto SkipMigration
end

-- Set to old default value for smooth experience
for player_index, player in pairs(game.players) do
    local guiSettings = settings.get_player_settings(player)
    local playerSettings = global.playerSettings[player_index]
    guiSettings["tlbe-sequential-names"] = {value = false}

    if playerSettings ~= nil then
        playerSettings.screenshotNumber = game.tick + 1
    end
end

::SkipMigration::
