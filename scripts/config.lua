local Config = {}

local ticks_per_second = 60

--- (re)loads the mod settings
-- @return true when player just (re)enabled TLBE
function Config.reload(event)
    local player = game.players[event.player_index]
    local guiSettings = settings.get_player_settings(player)

    local playerSettings =
        global.playerSettings[event.player_index] or
        {
            -- Setup a default camera for the player
            cameras = {{name = "main"}}
        }
    local mainCamera = playerSettings.cameras[1]
    playerSettings.enabled = guiSettings["tlbe-enabled"].value

    if playerSettings.enabled then
        local needRescale = false
        playerSettings.noticesEnabled = guiSettings["tlbe-notices-enabled"].value
        playerSettings.saveFolder = guiSettings["tlbe-save-folder"].value
        playerSettings.followPlayer = guiSettings["tlbe-follow-player"].value
        mainCamera.screenshotInterval =
            math.floor(
            (ticks_per_second * guiSettings["tlbe-speed-increase"].value) / guiSettings["tlbe-frame-rate"].value
        )
        mainCamera.zoomTicks =
            math.floor(
            ticks_per_second * guiSettings["tlbe-zoom-period"].value * guiSettings["tlbe-speed-increase"].value
        )

        local width = guiSettings["tlbe-resolution-x"].value
        if width ~= mainCamera.width and mainCamera.width ~= nil then
            needRescale = true
        end
        mainCamera.width = width

        local height = guiSettings["tlbe-resolution-y"].value
        if height ~= mainCamera.heigth and mainCamera.heigth ~= nil then
            needRescale = true
        end
        mainCamera.height = height

        if mainCamera.screenshotInterval < 1 then
            playerSettings.enabled = false
            guiSettings["tlbe-enabled"] = {value = false}

            player.print({"err_interval"}, {r = 1})
            player.print({"tlbe-disabled"})
        end

        if needRescale then
            mainCamera.lastChange = game.tick
        end
    end

    playerSettings.cameras[1] = mainCamera
    global.playerSettings[event.player_index] = playerSettings

    return playerSettings.enabled and mainCamera.centerPos == nil
end

return Config
