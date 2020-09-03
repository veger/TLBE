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
        userCanEnable = true,
        enabled = true,
        smooth = true
    }

    -- Add tracker specific details
    if trackerType == "player" then
        newTracker.untilBuild = true
        newTracker.smooth = false
    elseif trackerType == "rocket" then
        newTracker.userCanEnable = false
        newTracker.enabled = false
        newTracker.realtimeCamera = true
    end

    return newTracker
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

function Tracker.findActiveTracker(trackers)
    local previous
    for _, tracker in pairs(trackers) do
        if tracker.enabled == true then
            if tracker.moveToNextTracker ~= true then
                return previous, tracker
            end
            previous = tracker
        end
    end
    return previous, nil
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
