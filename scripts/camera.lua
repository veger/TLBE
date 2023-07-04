local Utils = require("scripts.utils")
local Tracker = require("scripts.tracker")

local captureBox = {
    ne = { name = "signal-capture-north-east", type = "virtual" },
    se = { name = "signal-capture-south-east", type = "virtual" },
    sw = { name = "signal-capture-south-west", type = "virtual" },
    nw = { name = "signal-capture-north-west", type = "virtual" },
}

local targetBox = {
    ne = { name = "signal-target-north-east", type = "virtual" },
    se = { name = "signal-target-south-east", type = "virtual" },
    sw = { name = "signal-target-south-west", type = "virtual" },
    nw = { name = "signal-target-north-west", type = "virtual" },
}

--- @class Camera.camera
--- @field centerPos table
--- @field enabled boolean
--- @field entityInfo boolean Show entity info in the screenshots
--- @field showGUI boolean Show GUI in the screenshots
--- @field alwaysDay boolean Render screenshot in daylight
--- @field frameRate number
--- @field height number
--- @field lastKnownActiveTracker Tracker.tracker
--- @field changeId integer Last known change ID of the tracker
--- @field name string
--- @field saveFolder string
--- @field saveName string
--- @field screenshotNumber integer Number for the next screenshot (when sequentialNames is set in player settings)
--- @field screenshotInterval number Interval (game ticks) between two screenshots  (calculated from speedGain and frameRate)
--- @field screenshotIntervalRealtime number Interval (game ticks) between two screenshots for realtime transitions (calculated from frameRate)
--- @field speedGain number
--- @field surfaceName string
--- @field trackers Tracker.tracker[]
--- @field chartTags table Chart tags used to render viewfinder boxes on the map
--- @field width number
--- @field zoom number
--- @field transitionPeriod number Time (in seconds) a transition should take
--- @field transitionTicks number Time (in ticks) a transition should take (calculated from transitionPeriod)
--- @field transitionData Camera.cameraTransition|nil When set, a transition is active

local Camera = {}

--- @class Camera.cameraTransition
--- @field ticks integer Number of ticks (screenshots) the transitions takes
--- @field transitionTicksLeft integer Number of ticks (screenshots) left of the transition
--- @field startPosition MapPosition.0 (Center) position of the camera when the current transition started
--- @field startZoom number Zoom factor of the camera when the current transition started
--- @field endPosition MapPosition.0 (Center) position of the tracker when the current transition started
--- @field endZoom number Zoom factor of the tracker when the current transition started
Camera.CameraTransition = {}

local maxZoom = 1
local minZoom = 0.031250
local ticks_per_second = 60
local tileSize = 32

--- @return Camera.camera
function Camera.newCamera(player, cameraList)
    local nameIndex = 1
    local cameraName = "new camera"
    while cameraList ~= nil and not Utils.uniqueName(cameraList, cameraName) do
        nameIndex = nameIndex + 1
        cameraName = "new camera-" .. nameIndex
    end

    --- @type Camera.camera
    local camera = {
        enabled = false,
        surfaceName = game.surfaces[1].name,
        entityInfo = false,
        showGUI = false,
        alwaysDay = true,
        trackers = {},
        centerPos = player.position,
        zoom = 1,
        screenshotNumber = 1,
        chartTags = {},
        -- settings/defaults
        width = 1920,
        height = 1080,
        frameRate = 25,
        speedGain = 60,
        transitionPeriod = 1.5
    }

    Camera.updateConfig(camera)
    Camera.setName(camera, cameraName);

    return camera
end

---@param camera Camera.camera
function Camera.updateConfig(camera)
    camera.screenshotInterval = math.max(math.floor((ticks_per_second * camera.speedGain) / camera.frameRate), 1)
    camera.screenshotIntervalRealtime = math.max(math.floor(ticks_per_second / camera.frameRate), 1)
    camera.transitionTicks = math.max(math.floor(camera.frameRate * camera.transitionPeriod), 1)
end

---Update the name of the Camera and its save folder and name.
---@param camera Camera.camera
---@param newName string
function Camera.setName(camera, newName)
    local path, name = string.match(newName, "(.-)([^\\/]-)$")
    camera.name = newName
    camera.saveFolder = path
    camera.saveName = name
end

---@param camera Camera.camera
function Camera.refreshConfig(camera)
    local transitionPeriod, frameRate, speedGain
    if camera.speedGain == nil then
        -- Try to recover as good as possible...
        ---@diagnostic disable-next-line: undefined-field camera.zoomTicks is the old field (old migrations use this function as well)
        transitionPeriod = (camera.transitionTicks or camera.zoomTicks) / ticks_per_second
        ---@diagnostic disable-next-line: undefined-field camera.realtimeInterval is the old field (old migrations use this function as well)
        frameRate = ticks_per_second / (camera.screenshotIntervalRealtime or camera.realtimeInterval)

        local speedGain1 = 1 -- camera.transitionTicks / (ticks_per_second * transitionPeriod)
        local speedGain2 = (camera.screenshotInterval * frameRate) / ticks_per_second
        speedGain = (speedGain1 + speedGain2) / 2
    else
        transitionPeriod = camera.transitionTicks / (camera.speedGain * ticks_per_second)
        frameRate = math.floor((ticks_per_second * camera.speedGain) / camera.screenshotInterval)

        -- Two ways to calculate speedGain, so take average
        local speedGain1 = camera.transitionTicks / (ticks_per_second * camera.transitionPeriod)
        local speedGain2 = (camera.screenshotInterval * camera.frameRate) / ticks_per_second
        speedGain = (speedGain1 + speedGain2) / 2
    end

    camera.transitionPeriod = math.floor(transitionPeriod * 100) / 100
    camera.frameRate = math.floor(frameRate + 0.5)
    camera.speedGain = math.floor(speedGain * 100) / 100
end

--- @param camera Camera.camera
--- @param tracker Tracker.tracker
function Camera.SetActiveTracker(camera, tracker)
    camera.lastKnownActiveTracker = tracker
    camera.changeId = nil
end

--- @param playerSettings playerSettings
--- @param player LuaPlayer
--- @param camera Camera.camera
--- @param tracker Tracker.tracker
--- @param disableSmooth boolean|nil Override the smooth (transition) option of the tracker
function Camera.followTracker(playerSettings, player, camera, tracker, disableSmooth)
    if tracker.centerPos == nil then
        return
    end

    if tracker.smooth and not disableSmooth then
        Camera.followTrackerSmooth(playerSettings, player, camera, tracker)
    else
        camera.centerPos = tracker.centerPos
        camera.zoom = Camera.zoom(camera, tracker)
    end

    Camera.refreshChartTags(player, camera, captureBox, camera.centerPos, camera.zoom)
end

--- @param playerSettings playerSettings
--- @param player LuaPlayer
--- @param camera Camera.camera
--- @param tracker Tracker.tracker
function Camera.followTrackerSmooth(playerSettings, player, camera, tracker)
    if camera.changeId ~= tracker.changeId then
        camera.transitionData = {
            startPosition = camera.centerPos,
            startZoom = camera.zoom,
            endPosition = tracker.centerPos,
            endZoom = Camera.zoom(camera, tracker),
            ticks = camera.transitionTicks,
            transitionTicksLeft = camera.transitionTicks
        }
        camera.changeId = tracker.changeId
        -- new transition target, so new tags
        Camera.refreshChartTags(player, camera, targetBox, camera.transitionData.endPosition,
            camera.transitionData.endZoom)
    end

    local transitionData = camera.transitionData
    if transitionData ~= nil then
        transitionData.transitionTicksLeft = transitionData.transitionTicksLeft - 1

        camera.centerPos, camera.zoom = Camera.CameraTransition.lerp(transitionData)

        if camera.zoom < minZoom then
            if playerSettings.noticeMaxZoom == nil then
                player.print({ "max-zoom" }, { r = 1 })
                player.print({ "msg-once" })
                playerSettings.noticeMaxZoom = true
            end

            camera.zoom = minZoom
        else
            -- Max (min actually) zoom is not reached (anymore)
            playerSettings.noticeMaxZoom = nil
        end

        if transitionData.transitionTicksLeft <= 0 then
            -- Transition finished
            camera.transitionData = nil
            -- delete target tags
            Camera.refreshChartTags(player, camera, targetBox, nil, nil)
        end
    end
end

--- Linear interpolation for the Camera transition.
--- @param transitionData Camera.cameraTransition
--- @return MapPosition.0 centerPos Current center position for the camera
--- @return number zoom Current zoom (factor) for the camera
function Camera.CameraTransition.lerp(transitionData)
    local t = Utils.clamp(0, 1, (transitionData.ticks - transitionData.transitionTicksLeft) / transitionData.ticks)
    return {
            x = transitionData.startPosition.x + (transitionData.endPosition.x - transitionData.startPosition.x) * t,
            y = transitionData.startPosition.y + (transitionData.endPosition.y - transitionData.startPosition.y) * t
        },
        transitionData.startZoom + (transitionData.endZoom - transitionData.startZoom) * t
end

-- Calculate desired zoom
--- @param camera Camera.camera
--- @param tracker Tracker.tracker
function Camera.zoom(camera, tracker)
    local zoomX = camera.width / (tileSize * tracker.size.x)
    local zoomY = camera.height / (tileSize * tracker.size.y)
    return math.min(zoomX, zoomY, maxZoom)
end

function Camera.setWidth(camera, width)
    width = tonumber(width)

    if width == nil or width < 320 then
        -- keep minimum width
        width = 320
    end

    local requireUpdate = width ~= camera.width
    camera.width = width
    if requireUpdate then
        local _, activeTracker = Tracker.findActiveTracker(camera.trackers, camera.surfaceName)
        if activeTracker ~= nil then
            -- Force update zoom level to make sure the tracked area stays the same
            ---@diagnostic disable-next-line: param-type-mismatch player(Data) can be nil when disableSmooth is true
            Camera.followTracker(nil, nil, camera, activeTracker, true)
        end
    end
end

function Camera.setHeight(camera, height)
    height = tonumber(height)

    if height == nil or height < 240 then
        -- keep minimum height
        height = 240
    end

    local requireUpdate = height ~= camera.height
    camera.height = height
    if requireUpdate then
        local _, activeTracker = Tracker.findActiveTracker(camera.trackers, camera.surfaceName)
        if activeTracker ~= nil then
            -- Force update zoom level to make sure the tracked area stays the same
            ---@diagnostic disable-next-line: param-type-mismatch player(Data) can be nil when disableSmooth is true
            Camera.followTracker(nil, nil, camera, activeTracker, true)
        end
    end
end

function Camera.setFrameRate(camera, framerate)
    framerate = tonumber(framerate)

    if framerate == nil or framerate < 1 then
        -- keep minimum frame rate
        framerate = 1
    end

    camera.frameRate = framerate
    Camera.updateConfig(camera)
end

function Camera.setSpeedGain(camera, speedGain)
    speedGain = tonumber(speedGain)

    if speedGain == nil or speedGain < 1 then
        -- keep minimum speed gain
        speedGain = 1
    end

    camera.speedGain = speedGain
    Camera.updateConfig(camera)
end

--- @param camera Camera.camera
--- @param transitionPeriod any
function Camera.setTransitionPeriod(camera, transitionPeriod)
    transitionPeriod = tonumber(transitionPeriod)

    if transitionPeriod == nil or transitionPeriod < 0 then
        -- keep minimum zoom period (0 = disabled)
        transitionPeriod = 0
    end

    camera.transitionPeriod = transitionPeriod
    Camera.updateConfig(camera)
end

--- @param player       LuaPlayer
--- @param camera       Camera.camera   the camera this box is for
--- @param iconSet      table           corner icons
--- @param centerPos    table?          x,y pair giving the center of the box, nil if deleting tags
--- @param zoom         number?         zoom factor for the box, ignored if deleting tags
function Camera.refreshChartTags(player, camera, iconSet, centerPos, zoom)
    -- we can't do this without a player or force
    if not player or not player.force then
        return
    end

    local chartTags = camera.chartTags
    local function createTag(icon, pos)
        camera.chartTags[icon.name] = player.force.add_chart_tag(
            camera.surfaceName,
            { position = pos, icon = icon })
    end

    -- remove all the old tags
    for _, icon in pairs(iconSet) do
        if chartTags[icon.name] then
            chartTags[icon.name].destroy()
            chartTags[icon.name] = nil
        end
    end

    -- add new ones if we are given data
    if centerPos then
        local x = centerPos.x
        local y = centerPos.y
        local width = camera.width / (tileSize * zoom)
        local height = camera.height / (tileSize * zoom)
        local half_width = width / 2
        local half_height = height / 2

        createTag(iconSet.ne, { x + half_width, y - half_height })
        createTag(iconSet.se, { x + half_width, y + half_height })
        createTag(iconSet.sw, { x - half_width, y + half_height })
        createTag(iconSet.nw, { x - half_width, y - half_height })
    end
end

--- @param player LuaPlayer
function Camera.recordingSensor(player)
    local playerSettings = global.playerSettings[player.index]

    if not playerSettings.showCameraStatus then
        return nil
    end

    if playerSettings.pauseCameras == true then
        return {
            "stats.all-paused"
        }
    end

    local cameraStatuses = {}
    for _, camera in pairs(playerSettings.cameras) do
        table.insert(cameraStatuses, ", ")
        table.insert(cameraStatuses, camera.name .. ": ")
        if not camera.enabled then
            table.insert(cameraStatuses, { "stats.disabled" })
        elseif camera.transitionData ~= nil then
            table.insert(cameraStatuses, { "stats.transition" })
        else
            table.insert(cameraStatuses, { "stats.recording" })
        end
    end

    if #cameraStatuses == 0 then
        return nil
    end

    -- Get rid of first ',' and let Factorio localization concatenate the table
    cameraStatuses[1] = ""

    return cameraStatuses
end

--- @param camera Camera.camera
function Camera.destroy(camera)
    for _, tag in pairs(camera.chartTags) do
        tag.destroy()
    end
end

return Camera
