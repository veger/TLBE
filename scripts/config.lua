local Config = {}

--- (re)loads the mod settings
-- @return true when player just (re)enabled TLBE
function Config.reload(event)
    local player = game.players[event.player_index]
    local guiSettings = settings.get_player_settings(player)

    local playerSettings = global.playerSettings[event.player_index] or {}
    playerSettings.enabled = guiSettings["tlbe-enabled"].value

    if playerSettings.enabled then
        playerSettings.noticesEnabled = guiSettings["tlbe-notices-enabled"].value
        playerSettings.saveFolder = guiSettings["tlbe-save-folder"].value
        playerSettings.followPlayer = guiSettings["tlbe-follow-player"].value
        playerSettings.screenshotInterval =
            math.floor((60 * guiSettings["tlbe-speed-increase"].value) / guiSettings["tlbe-frame-rate"].value)
        playerSettings.width = guiSettings["tlbe-resolution-x"].value
        playerSettings.height = guiSettings["tlbe-resolution-y"].value

        if playerSettings.screenshotInterval < 1 then
            playerSettings.enabled = false
            guiSettings["tlbe-enabled"] = {value = false}

            player.print({"err_interval"}, {r = 1})
            player.print({"tlbe-disabled"})
        end
    end

    global.playerSettings[event.player_index] = playerSettings

    return playerSettings.enabled and playerSettings.centerPos == nil
end

return Config
