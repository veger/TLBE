local TLBE = {Main = require("scripts.main")}
local Util = {}

local MAX_TICKS = 100

--- @return number @ticks
function Util.ConvergenceTester(playerSettings, player, targetCenterPos, targetSize)
    local mainCamera = playerSettings.cameras[1]
    local ticks = 0
    local currentX = mainCamera.centerPos.x
    local currentY = mainCamera.centerPos.y
    local currentZoom = mainCamera.zoom

    repeat
        ticks = ticks + 1
        game.tick = game.tick + 1
        local lastX = currentX
        local lastY = currentY
        local lastZoom = currentZoom

        TLBE.Main.follow_center_pos(playerSettings, player, mainCamera, targetCenterPos, targetSize)

        currentX = mainCamera.centerPos.x
        currentY = mainCamera.centerPos.y
        currentZoom = mainCamera.zoom
    until ticks == MAX_TICKS or
        (math.abs(lastX - currentX) < 0.0001 and math.abs(lastY - currentY) < 0.0001 and
            math.abs(lastZoom - currentZoom) < 0.0001)

    return ticks
end

return Util
