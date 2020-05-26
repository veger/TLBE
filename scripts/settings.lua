if not tlbe then tlbe = {} end

function tlbe.reload_settings(event)
    local player = game.players[event.player_index]
    local guiSettings = settings.get_player_settings(player)

    local playerSettings = global.playerSettings[event.player_index] or {}
    playerSettings.enabled = guiSettings["tlbe-enabled"].value;

    if playerSettings.enabled then
        playerSettings.noticesEnabled = guiSettings["tlbe-notices-enabled"]
                                            .value;
        playerSettings.saveFolder = guiSettings["tlbe-save-folder"].value
        playerSettings.followPlayer = guiSettings["tlbe-follow-player"].value
        playerSettings.screenshotInterval =
            (60 * guiSettings["tlbe-speed-increase"].value) /
                guiSettings["tlbe-frame-rate"].value
        playerSettings.width = guiSettings["tlbe-resolution-x"].value;
        playerSettings.height = guiSettings["tlbe-resolution-y"].value;

        if playerSettings.screenshotInterval < 1 then
            playerSettings.enabled = false
            guiSettings["tlbe-enabled"] = {value = false}

            tlbe.log({"tlbe-disabled"});
            tlbe.log({"err_interval"});
        end
    end

    global.playerSettings[event.player_index] = playerSettings

    if playerSettings.enabled and playerSettings.centerPos == nil then
        -- initialize player settings if not yet done to prevent issues later
        tlbe.follow_player(playerSettings, player)
    end

    tlbe.log({"err_generic", "reload_settings", "Settings loaded"});
end
