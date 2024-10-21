local Camera = require("scripts.camera")
local Main = require("scripts.main")
local Tracker = require("scripts.tracker")

local ticks_per_second = 60

if storage.playerSettings == nil then
    goto SkipMigration
end

for player_index, player in pairs(game.players) do
    local playerSettings = storage.playerSettings[player_index]
    if playerSettings == nil or playerSettings.cameras == nil then
        goto NextPlayer
    end

    if playerSettings.trackers ~= nil then
        -- Probably a new game, as previous version did not include trackers
        goto NextPlayer
    end

    player.print { "migrated-camera" }

    local mainCamera = playerSettings.cameras[1]

    if mainCamera.zoomTicksRocket ~= nil then
        mainCamera.zoomTicksRealtime = mainCamera.zoomTicksRocket
    else
        player.print({ "migration-issue-zoomperiod" }, { r = 1, g = 0.5, b = 0 })
        mainCamera.zoomPeriod = 1.5
        mainCamera.zoomTicksRealtime = math.floor(ticks_per_second * mainCamera.zoomPeriod)
    end

    if mainCamera.rocketInterval ~= nil then
        mainCamera.realtimeInterval = mainCamera.rocketInterval
    else
        mainCamera.frameRate = 25
        mainCamera.realtimeInterval = math.floor(ticks_per_second / mainCamera.frameRate)
        player.print({ "migration-issue-framerate" }, { r = 1, g = 0.5, b = 0 })
    end

    Camera.refreshConfig(mainCamera)

    mainCamera.trackers = {
        Tracker.newTracker "player",
        Tracker.newTracker "rocket",
        Tracker.newTracker "base"
    }
    mainCamera.enabled = playerSettings.enabled

    -- Prepare base tracker
    local baseBBox = Main.getBaseBBox(game.surfaces[1].name) -- only v1.4.0 added support for surfaces
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

    playerSettings.trackers = { table.unpack(mainCamera.trackers) }

    -- Remove obsolete entries
    storage.rocketLaunching = nil
    playerSettings.enabled = nil
    playerSettings.noticesEnabled = nil
    playerSettings.followPlayer = nil
    mainCamera.baseCenterPos = nil
    mainCamera.factorySize = nil
    mainCamera.zoomTicksRocket = nil
    mainCamera.rocketInterval = nil

    ::NextPlayer::
end

::SkipMigration::
