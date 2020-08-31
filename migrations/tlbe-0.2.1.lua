local Camera = require("scripts.camera")
local Main = require("scripts.main")
local Tracker = require("scripts.tracker")

local ticks_per_second = 60

for player_index, player in pairs(game.players) do
    if global.playerSettings == nil then
        goto NextPlayer
    end

    local playerSettings = global.playerSettings[player_index]
    if playerSettings == nil or playerSettings.cameras == nil then
        goto NextPlayer
    end

    player.print("Migrated TLBE player settings to new camera settings.")

    local mainCamera = playerSettings.cameras[1]

    if mainCamera.zoomTicksRocket ~= nil then
        mainCamera.zoomTicksRealtime = mainCamera.zoomTicksRocket
    else
        player.print(
            "Could not recover 'zoom period', please set manually as soon as possible. (only rocket tracker won't work as before)",
            {r = 1, g = 0.5, b = 0}
        )
        mainCamera.zoomPeriod = 1.5
        mainCamera.zoomTicksRealtime = math.floor(ticks_per_second * mainCamera.zoomPeriod)
    end

    if mainCamera.rocketInterval ~= nil then
        mainCamera.realtimeInterval = mainCamera.rocketInterval
    else
        mainCamera.frameRate = 25
        mainCamera.realtimeInterval = math.floor(ticks_per_second / mainCamera.frameRate)
        player.print(
            "Could not recover 'frame rate', please set manually as soon as possible. (only rocket tracker won't work as before)",
            {r = 1, g = 0.5, b = 0}
        )
    end

    Camera.refreshConfig(mainCamera)

    mainCamera.trackers = {
        Tracker.newTracker "player",
        Tracker.newTracker "rocket",
        Tracker.newTracker "base"
    }
    mainCamera.enabled = playerSettings.enabled

    -- Prepare base tracker
    local baseBBox = Main.get_base_bbox()
    if baseBBox ~= nil then
        local baseTracker = mainCamera.trackers[3]
        baseTracker.minPos = baseBBox.minPos
        baseTracker.maxPos = baseBBox.maxPos
        Tracker.updateCenterAndSize(baseTracker)

        -- Base has been build, so disable player tracker
        mainCamera.trackers[1].enabled = false
    end

    -- Get rid of player tracker if player should not be followed
    if not playerSettings.followPlayer then
        table.remove(mainCamera.trackers, 1)
    end

    playerSettings.trackers = mainCamera.trackers

    -- Remove obsolete entries
    global.rocketLaunching = nil
    playerSettings.enabled = nil
    playerSettings.noticesEnabled = nil
    playerSettings.followPlayer = nil
    mainCamera.baseCenterPos = nil
    mainCamera.factorySize = nil
    mainCamera.zoomTicksRocket = nil
    mainCamera.rocketInterval = nil

    ::NextPlayer::
end
