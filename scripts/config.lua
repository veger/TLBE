local Config = {}

local ticks_per_second = 60

--- (re)loads the mod settings
-- @return true when player just (re)enabled TLBE
function Config.reload(event)
    local player = game.players[event.player_index]
    local guiSettings = settings.get_player_settings(player)

    local playerSettings = global.playerSettings[event.player_index] or {}
    playerSettings.enabled = guiSettings["tlbe-enabled"].value

    if playerSettings.enabled then
        local needRescale = false
        playerSettings.noticesEnabled = guiSettings["tlbe-notices-enabled"].value
        playerSettings.saveFolder = guiSettings["tlbe-save-folder"].value
        playerSettings.followPlayer = guiSettings["tlbe-follow-player"].value
        playerSettings.screenshotInterval =
            math.floor(
            (ticks_per_second * guiSettings["tlbe-speed-increase"].value) / guiSettings["tlbe-frame-rate"].value
        )
        playerSettings.zoomTicks =
            math.floor(
            ticks_per_second * guiSettings["tlbe-zoom-period"].value * guiSettings["tlbe-speed-increase"].value
        )

        local width = guiSettings["tlbe-resolution-x"].value
        if width ~= playerSettings.width and playerSettings.width ~= nil then
            needRescale = true
        end
        playerSettings.width = width

        local height = guiSettings["tlbe-resolution-y"].value
        if height ~= playerSettings.heigth and playerSettings.heigth ~= nil then
            needRescale = true
        end
        playerSettings.height = height

        if playerSettings.screenshotInterval < 1 then
            playerSettings.enabled = false
            guiSettings["tlbe-enabled"] = {value = false}

            player.print({"err_interval"}, {r = 1})
            player.print({"tlbe-disabled"})
        end

        if needRescale then
            global.lastChange = game.tick
        end
    end

    global.playerSettings[event.player_index] = playerSettings

    return playerSettings.enabled and playerSettings.centerPos == nil
end

return Config
