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

return Camera
