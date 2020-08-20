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
        enabled = true
    }

    -- Add tracker specific details
    if trackerType == "player" then
        newTracker.untilBuild = true
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

return Tracker
