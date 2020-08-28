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

    return {
        name = cameraName,
        enabled = false,
        trackers = {},
        centerPos = player.position,
        zoom = 1,
        -- settings/defaults
        width = 1920,
        height = 1080,
        screenshotInterval = math.floor((ticks_per_second * 60) / 25),
        zoomTicks = math.floor(ticks_per_second * 1.5 * 60),
        realtimeInterval = math.floor(ticks_per_second / 25),
        zoomTicksRealtime = math.floor(ticks_per_second * 1.5)
    }
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

return Camera
