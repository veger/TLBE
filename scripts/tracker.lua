local Tracker = {}

local Utils = require("scripts.utils")

function Tracker.newTracker(trackerType, trackerList)
    local nameIndex = 1
    local trackerName = trackerType
    while trackerList ~= nil and not Utils.uniqueName(trackerList, trackerName) do
        nameIndex = nameIndex + 1
        trackerName = trackerType .. "-" .. nameIndex
    end

    local newTracker = {
        name = trackerName,
        type = trackerType,
        surfaceName = game.surfaces[1].name,
        userCanEnable = true,
        enabled = true,
        smooth = true,
        lastChange = 0
    }

    -- Add tracker specific details
    if trackerType == "area" then
        newTracker.minPos = {x = -5, y = -5}
        newTracker.maxPos = {x = 5, y = 5}
        Tracker.updateCenterAndSize(newTracker)
    elseif trackerType == "player" then
        newTracker.size = {x = 1, y = 1}
        newTracker.untilBuild = true
        newTracker.smooth = false
    elseif trackerType == "rocket" then
        newTracker.userCanEnable = false
        newTracker.enabled = false
        newTracker.realtimeCamera = true
    end

    return newTracker
end

-- Update tracker state (if needed)
function Tracker.tick(tracker, player)
    if tracker.type == "player" and tracker.surfaceName == player.surface.name then
        if
            tracker.centerPos == nil or tracker.centerPos.x ~= player.position.x or
                tracker.centerPos.y ~= player.position.y
         then
            tracker.lastChange = game.tick
        end

        tracker.centerPos = player.position
    end
end

-- Allows for a smooth recenter for the next/unknown tracker
function Tracker.moveToNextTracker(tracker)
    tracker.moveToNextTracker = true
end

function Tracker.MoveToNextTrackerFinished(trackers)
    for _, tracker in pairs(trackers) do
        if tracker.moveToNextTracker then
            -- Moved to next tracker, so disable this one
            tracker.enabled = false
            tracker.moveToNextTracker = nil
        end
    end
end

function Tracker.findActiveTracker(trackers, surfaceName)
    local previous
    for _, tracker in pairs(trackers) do
        if tracker.enabled == true and tracker.surfaceName == surfaceName then
            if tracker.moveToNextTracker ~= true then
                return previous, tracker
            end
            previous = tracker
        end
    end
    return previous, nil
end

function Tracker.inUse(tracker, cameras)
    for _, camera in ipairs(cameras) do
        for _, cameraTracker in ipairs(camera.trackers) do
            if cameraTracker == tracker then
                return true
            end
        end
    end

    return false
end

function Tracker.areaUpdateCenterAndSize(tracker)
    if tracker.minPos.x < tracker.maxPos.x and tracker.minPos.y < tracker.maxPos.y then
        -- Only update when area is valid
        Tracker.updateCenterAndSize(tracker)
    end
end

function Tracker.updateCenterAndSize(tracker)
    local size = {
        x = tracker.maxPos.x - tracker.minPos.x,
        y = tracker.maxPos.y - tracker.minPos.y
    }

    local centerPos = {
        x = tracker.minPos.x + size.x / 2,
        y = tracker.minPos.y + size.y / 2
    }

    if
        tracker.centerPos == nil or tracker.size == nil or centerPos.x ~= tracker.centerPos.x or
            centerPos.y ~= tracker.centerPos.y or
            size.x ~= tracker.size.x or
            size.y ~= tracker.size.y
     then
        -- Tracker dimensions changed, so need to recenter camera
        tracker.lastChange = game.tick
    end

    tracker.size = size
    tracker.centerPos = centerPos
end

return Tracker
