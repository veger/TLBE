local Utils = require("scripts.utils")

local Tracker = {}

--- @class Tracker.tracker
--- @field enabled boolean True when the tracker is enabled/active
--- @field name string
--- @field realtimeCamera boolean
--- @field smooth boolean When true, smooth transitions are enabled/required for this tracker
--- @field surfaceName string
--- @field type string
--- @field untilBuild boolean
--- @field userCanEnable boolean When true, the user can enabled/disable the tracker, otherwise the tracker is controlled by TBLE
--- @field moveToNextTracker boolean Disables the tracker after the cameras are processed (end of game tick)
--- @field changeId integer Incremented on each position/size change of the tracker
--- @field centerPos MapPosition.0 Center position of the tracker area (Calculated from minPos and maxPos)
--- @field size MapPosition.0 Size of the tracker area (Calculated from minPos and maxPos)
--- @field minPos MapPosition.0 Bottom/Left of tracker area
--- @field maxPos MapPosition.0 TopRight of tracker area
--- @field cityBlock Tracker.cityBlock? City block vital statistics, used when type="cityblock"

--- @class Tracker.cityBlock
--- @field blockSize TilePosition The size of a single city block
--- @field blockOffset TilePosition The offset where the "first" city block begins
--- @field currentBlock TilePosition An abuse of the TilePosition type to number the blocks (1,4 is one block over and 4 blocks up)
--- @field blockScale number How many blocks to hold in view (1=1 block, 1.5=1.5 blocks etc.)
Tracker.cityBlock = {}

---@return Tracker.cityBlock
function Tracker.cityBlock:new()
    local cityBlock = {}

    cityBlock.blockSize    = { x=32, y=32 }
    cityBlock.blockOffset  = { x=0,  y=0 }
    cityBlock.currentBlock = { x=0,  y=0 }
    cityBlock.blockScale   = 1.1
    return cityBlock
end

--- Create and setup a new tracker
--- @param trackerType string Type of the new tracker
--- @param trackerList Tracker.tracker[]|nil When provided the generated name will be unique
--- @return Tracker.tracker
function Tracker.newTracker(trackerType, trackerList)
    local nameIndex = 1
    local trackerName = trackerType
    while trackerList ~= nil and not Utils.uniqueName(trackerList, trackerName) do
        nameIndex = nameIndex + 1
        trackerName = trackerType .. "-" .. nameIndex
    end

    --- @type Tracker.tracker
    local newTracker = {
        name = trackerName,
        type = trackerType,
        surfaceName = game.surfaces[1].name,
        userCanEnable = true,
        enabled = true,
        smooth = true,
        untilBuild = false,
        changeId = 0
    }

    -- Add tracker specific details
    if trackerType == "area" then
        newTracker.minPos = { x = -5, y = -5 }
        newTracker.maxPos = { x = 5, y = 5 }
        Tracker.updateCenterAndSize(newTracker)
    elseif trackerType == "player" then
        newTracker.size = { x = 1, y = 1 }
        newTracker.untilBuild = true
        newTracker.smooth = false
    elseif trackerType == "rocket" then
        newTracker.userCanEnable = false
        newTracker.enabled = false
        newTracker.realtimeCamera = true
    elseif trackerType == "cityblock" then
        -- cityblock-specific data
        newTracker.cityBlock = Tracker.cityBlock:new()
        Tracker.recalculateCityBlock(newTracker)
    end

    return newTracker
end

---comment recalculates the tracker vital stats from the city block vital stats
---@param tracker Tracker.tracker
function Tracker.recalculateCityBlock(tracker)
    if tracker.type ~= "cityblock" then
        return
    end
    
    local cityBlock = tracker.cityBlock
    if cityBlock == nil then
        return
    end


    local width = cityBlock.blockSize.x
    local height = cityBlock.blockSize.y
    local widthDiam = width * cityBlock.blockScale
    local heightDiam = height * cityBlock.blockScale
    local widthRad = widthDiam / 2
    local heightRad = heightDiam / 2

    tracker.centerPos = {
        x = cityBlock.blockOffset.x + cityBlock.currentBlock.x * width + width / 2,
        y = cityBlock.blockOffset.y + cityBlock.currentBlock.y * height + height / 2
    }

    tracker.size = { x = widthDiam, y = heightDiam }

    tracker.minPos = {
        x = tracker.centerPos.x - widthRad,
        y = tracker.centerPos.y - heightRad
    }

    tracker.maxPos = {
        x = tracker.centerPos.x + widthRad,
        y = tracker.centerPos.y + heightRad
    }

    Tracker.changed(tracker)
end


-- Update tracker state (if needed)
--- @param tracker Tracker.tracker
--- @param player LuaPlayer
function Tracker.tick(tracker, player)
    if tracker.type == "player" and tracker.surfaceName == player.surface.name then
        if tracker.centerPos == nil or tracker.centerPos.x ~= player.position.x or
            tracker.centerPos.y ~= player.position.y
        then
            Tracker.changed(tracker)
        end

        tracker.centerPos = {
            x = player.position.x,
            y = player.position.y
        }
    end
end

-- Allows for a smooth recenter for the next/unknown tracker
function Tracker.moveToNextTracker(tracker)
    tracker.moveToNextTracker = true
end

--- @param trackers Tracker.tracker[]
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

--- @param tracker Tracker.tracker
function Tracker.updateCenterAndSize(tracker)
    local size = {
        x = tracker.maxPos.x - tracker.minPos.x,
        y = tracker.maxPos.y - tracker.minPos.y
    }

    local centerPos = {
        x = tracker.minPos.x + size.x / 2,
        y = tracker.minPos.y + size.y / 2
    }

    if tracker.centerPos == nil or tracker.size == nil or centerPos.x ~= tracker.centerPos.x or
        centerPos.y ~= tracker.centerPos.y or
        size.x ~= tracker.size.x or
        size.y ~= tracker.size.y
    then
        Tracker.changed(tracker)
    end

    tracker.size = size
    tracker.centerPos = centerPos
end

--- @param tracker Tracker.tracker
function Tracker.changed(tracker)
    tracker.changeId = tracker.changeId + 1
end

return Tracker
