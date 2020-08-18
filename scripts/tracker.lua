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
    end

    return newTracker
end

return Tracker
