local Camera = {}

local Utils = require("scripts.utils")

local ticks_per_second = 60

function Camera.newCamera(player, cameraList)
    local nameIndex = 1
    local cameraName = "new camera"
    while cameraList ~= nil and not Utils.uniqueName(cameraList, cameraName) do
        nameIndex = nameIndex + 1
        cameraName = "new camera-" .. nameIndex
    end

    local camera = {
        name = cameraName,
        enabled = false,
        trackers = {},
        centerPos = player.position,
        zoom = 1,
        -- settings/defaults
        width = 1920,
        height = 1080,
        frameRate = 25,
        speedGain = 60,
        zoomPeriod = 1.5
    }

    Camera.updateConfig(camera)

    return camera
end

function Camera.updateConfig(camera)
    camera.screenshotInterval = math.max(math.floor((ticks_per_second * camera.speedGain) / camera.frameRate), 1)
    camera.zoomTicks = math.max(math.floor(ticks_per_second * camera.zoomPeriod * camera.speedGain), 1)
    camera.realtimeInterval = math.max(math.floor(ticks_per_second / camera.frameRate), 1)
    camera.zoomTicksRealtime = math.max(math.floor(ticks_per_second * camera.zoomPeriod), 1)
end

function Camera.setWidth(camera, width)
    width = tonumber(width)

    if width == nil or width < 320 then
        -- keep minimum width
        width = 320
    end

    if width ~= camera.width then
        -- Make sure to start (smooth) zooming to new width
        camera.lastChange = game.tick
    end
    camera.width = width
end

function Camera.setHeight(camera, height)
    height = tonumber(height)

    if height == nil or height < 240 then
        -- keep minimum height
        height = 240
    end

    if height ~= camera.height then
        -- Make sure to start (smooth) zooming to new height
        camera.lastChange = game.tick
    end
    camera.height = height
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

function Camera.setZoomPeriod(camera, zoomPeriod)
    zoomPeriod = tonumber(zoomPeriod)

    if zoomPeriod == nil or zoomPeriod < 0 then
        -- keep minimum zoom period (0 = disabled)
        zoomPeriod = 0
    end

    camera.zoomPeriod = zoomPeriod
    Camera.updateConfig(camera)
end

return Camera
