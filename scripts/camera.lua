local Utils = require("scripts.utils")
local Tracker = require("scripts.tracker")

--- @class Camera.camera
--- @field centerPos table
--- @field enabled boolean
--- @field entityInfo boolean Show entity info in the screenshots
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
--- @field screenshotIntervalRealtime number Interval (game ticks) between two screeenshots for realtime transitions (calculated from frameRate)
--- @field speedGain number
--- @field surfaceName string
--- @field trackers Tracker.tracker[]
--- @field width number
--- @field zoom number
--- @field transitionPeriod number Time (in seconds) a transition should take
--- @field transitionTicks number Time (in ticks) a transition should take (calculated from transitionPeriod)
--- @field transitionData Camera.cameraTransition|nil When set, a transtion is active

local Camera = {}

--- @class Camera.cameraTransition
--- @field ticks integer Number of ticks (screenshots) the transtions takes
--- @field transitionTicksLeft integer Number of ticks (screenshots) left of the transition
--- @field startPosition MapPosition.0 (Center) position of the camera when the current transition started
--- @field startZoom number Zoom factor of the camera when the current transition started
--- @field endPosition MapPosition.0 (Center) position of the tracker when the current transition started
--- @field endZoom number Zoom factor of the tracker when the current transition started
Camera.cameraTransition = {}
function Camera.cameraTransition:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

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
        alwaysDay = true,
        trackers = {},
        centerPos = player.position,
        zoom = 1,
        screenshotNumber = 1,
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
        transitionPeriod = camera.transitionTicks / ticks_per_second
        frameRate = ticks_per_second / camera.screenshotIntervalRealtime

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
end

--- @param playerSettings playerSettings
--- @param player LuaPlayer
--- @param camera Camera.camera
--- @param tracker Tracker.tracker
function Camera.followTrackerSmooth(playerSettings, player, camera, tracker)
    if camera.changeId ~= tracker.changeId then
        camera.transitionData = Camera.cameraTransition:new({
            startPosition = camera.centerPos,
            startZoom = camera.zoom,
            endPosition = tracker.centerPos,
            endZoom = Camera.zoom(camera, tracker),
            ticks = camera.transitionTicks,
            transitionTicksLeft = camera.transitionTicks
        })
        camera.changeId = tracker.changeId
    end

    local transtionData = camera.transitionData
    if transtionData ~= nil then
        transtionData.transitionTicksLeft = transtionData.transitionTicksLeft - 1

        camera.centerPos, camera.zoom = transtionData:lerp()

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

        if transtionData.transitionTicksLeft <= 0 then
            -- Transition finished
            camera.transitionData = nil
        end
    end
end

--- Linear interpolation for the Camera transition.
--- @return MapPosition.0 centerPos Current center position for the camera
--- @return number zoom Current zoom (factor) for the camera
function Camera.cameraTransition:lerp()
    local t = Utils.clamp(0, 1, (self.ticks - self.transitionTicksLeft) / self.ticks)
    return {
            x = self.startPosition.x + (self.endPosition.x - self.startPosition.x) * t,
            y = self.startPosition.y + (self.endPosition.y - self.startPosition.y) * t
        },
        self.startZoom + (self.endZoom - self.startZoom) * t
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

return Camera
