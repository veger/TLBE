local Config = {}

local Tracker = require("scripts.tracker")

local ticks_per_second = 60

--- (re)loads the mod settings
function Config.reload(event)
    local player = game.players[event.player_index]
    local guiSettings = settings.get_player_settings(player)

    local playerSettings = global.playerSettings[event.player_index]
    if playerSettings == nil then
        playerSettings = Config.newPlayerSettings(player)
        global.playerSettings[event.player_index] = playerSettings
    end

    local mainCamera = playerSettings.cameras[1]
    local needRescale = false
    playerSettings.saveFolder = guiSettings["tlbe-save-folder"].value
    mainCamera.screenshotInterval =
        math.floor((ticks_per_second * guiSettings["tlbe-speed-increase"].value) / guiSettings["tlbe-frame-rate"].value)
    mainCamera.zoomTicks =
        math.floor(ticks_per_second * guiSettings["tlbe-zoom-period"].value * guiSettings["tlbe-speed-increase"].value)

    mainCamera.realtimeInterval = math.floor(ticks_per_second / guiSettings["tlbe-frame-rate"].value)
    mainCamera.zoomTicksRealtime = math.floor(ticks_per_second * guiSettings["tlbe-zoom-period"].value)

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
        mainCamera.enabled = false

        player.print({"err_interval"}, {r = 1})
        player.print({"tlbe-disabled"})
    end

    if needRescale then
        mainCamera.lastChange = game.tick
    end
end

function Config.newPlayerSettings(player)
    -- Setup some default trackers
    local trackers = {
        Tracker.newTracker "player",
        Tracker.newTracker "rocket",
        Tracker.newTracker "base"
    }

    local camera = Config.newCamera(player)
    camera.trackers = {trackers[1], trackers[2], trackers[3]}

    return {
        -- Setup a default camera and attach trackers to it
        cameras = {camera},
        trackers = trackers
    }
end

function Config.newCamera(player)
    return {
        name = "main",
        enabled = true,
        trackers = {},
        centerPos = player.position,
        zoom = 1
    }
end

return Config
