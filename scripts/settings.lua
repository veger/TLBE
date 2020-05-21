if not tlbe then tlbe = {} end

function tlbe.reload_settings(event)
    local player = game.players[event.player_index]
    local playerSettings = settings.get_player_settings(player)

    local settings = {}
    settings.enabled = playerSettings["tlbe-enabled"].value;

    if settings.enabled then
        settings.noticesEnabled = playerSettings["tlbe-notices-enabled"].value;
        settings.saveFolder = playerSettings["tlbe-save-folder"].value
        settings.followPlayer = playerSettings["tlbe-follow-player"].value
        settings.screenshotInterval = (60 *
                                          playerSettings["tlbe-speed-increase"]
                                              .value) /
                                          playerSettings["tlbe-frame-rate"]
                                              .value
        settings.width = playerSettings["tlbe-resolution-x"].value;
        settings.height = playerSettings["tlbe-resolution-y"].value;

        if settings.screenshotInterval < 1 then
            settings = {enabled = false}
            playerSettings["tlbe-enabled"] = {value = false}

            tlbe.log({"tlbe-disabled"});
            tlbe.log({"err_interval"});
        end
    end

    global.playerSettings[event.player_index] = settings
    tlbe.log({"err_generic", "reload_settings", "Settings loaded"});
end
