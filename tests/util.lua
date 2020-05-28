local TLBE = {Main = require("scripts.main")}
local Util = {}

local MAX_TICKS = 100

--- @return number @ticks
function Util.ConvergenceTester(playerSettings, player, targetCenterPos, targetSize)
    local ticks = 0
    local currentX = playerSettings.centerPos.x
    local currentY = playerSettings.centerPos.y
    local currentZoom = playerSettings.zoom

    repeat
        ticks = ticks + 1
        game.tick = game.tick + 1
        local lastX = currentX
        local lastY = currentY
        local lastZoom = currentZoom

        TLBE.Main.follow_center_pos(playerSettings, player, targetCenterPos, targetSize)

        currentX = playerSettings.centerPos.x
        currentY = playerSettings.centerPos.y
        currentZoom = playerSettings.zoom
    until ticks == MAX_TICKS or
        (math.abs(lastX - currentX) < 0.0001 and math.abs(lastY - currentY) < 0.0001 and
            math.abs(lastZoom - currentZoom) < 0.0001)

    return ticks
end

return Util
