package.path = package.path .. ";../?.lua"
local TLBE = { Camera = require("scripts.camera") }

local lu = require("luaunit")

local tileSize = 32
local MAX_TICKS = 100

-- luacheck: globals game
local function ConvergenceTester(playerSettings, player, camera, tracker)
    local tick = 0
    local currentX = camera.centerPos.x
    local currentY = camera.centerPos.y
    local currentZoom = camera.zoom

    repeat
        tick = tick + 1
        local lastX = currentX
        local lastY = currentY
        local lastZoom = currentZoom

        TLBE.Camera.followTracker(playerSettings, player, camera, tracker)

        currentX = camera.centerPos.x
        currentY = camera.centerPos.y
        currentZoom = camera.zoom
    until tick == MAX_TICKS or (math.abs(lastX - currentX) < 0.0001 and math.abs(lastY - currentY) < 0.0001 and
            math.abs(lastZoom - currentZoom) < 0.0001)

    -- Last tick validated the camera reached convergence so it does not count
    return tick - 1
end

TestCameraFollowTracker = {}

function TestCameraFollowTracker:SetUp()
    self.testCamera = {
        width = 20 * tileSize,
        height = 15 * tileSize,
        changeId = 0,
        centerPos = { x = 0, y = 0 },
        screenshotInterval = 1,
        zoom = 1,
        zoomTicks = 15
    }

    self.testTracker = {
        centerPos = { x = 0, y = 0 },
        size = { x = 1, y = 1 },
        changeId = 1,
        smooth = true,
    }
end

function TestCameraFollowTracker:TestInitialUpRight()
    self.testTracker.centerPos = { x = 1, y = 1 }

    TLBE.Camera.followTracker({}, {}, self.testCamera, self.testTracker)

    lu.assertIsTrue(self.testCamera.centerPos.x > 0, "expected that centerPos.x moved right")
    lu.assertIsTrue(self.testCamera.centerPos.y > 0, "expected that centerPos.y moved up")
    lu.assertEquals(self.testCamera.zoom, 1, "expected that zoom did not change, as size stayed the same")
end

function TestCameraFollowTracker:TestInitialBottomLeft()
    self.testTracker.centerPos = { x = -1, y = -1 }

    TLBE.Camera.followTracker({}, {}, self.testCamera, self.testTracker)

    lu.assertIsTrue(self.testCamera.centerPos.x < 0, "expected that centerPos.x moved left")
    lu.assertIsTrue(self.testCamera.centerPos.y < 0, "expected that centerPos.y moved down")
    lu.assertEquals(self.testCamera.zoom, 1, "expected that zoom did not change, as size stayed the same")
end

function TestCameraFollowTracker:TestNotSmooth()
    self.testTracker.smooth = false
    self.testTracker.centerPos = { x = 10, y = 6 }

    local ticks = ConvergenceTester({}, {}, self.testCamera, self.testTracker)

    lu.assertEquals(ticks, 1, "couldn't converge immediately")

    lu.assertIsTrue(self.testCamera.centerPos.x == 10, "expected move to new center")
    lu.assertIsTrue(self.testCamera.centerPos.y == 6, "expected move to new center")
end

function TestCameraFollowTracker:TestZoom()
    self.testTracker.size = { x = self.testCamera.width / tileSize * 2, y = self.testCamera.height / tileSize * 2 }

    local ticks = ConvergenceTester({}, {}, self.testCamera, self.testTracker)

    lu.assertEquals(ticks, self.testCamera.zoomTicks, "couldn't converge in expected 14 ticks")

    lu.assertEquals(self.testCamera.centerPos.x, 0, "expected to stay in same place")
    lu.assertEquals(self.testCamera.centerPos.y, 0, "expected to stay in same place")
    lu.assertEquals(self.testCamera.zoom, 0.5, "expected that zoom halved")
end

function TestCameraFollowTracker:TestConvergenceDiagonal()
    self.testTracker.centerPos = { x = 10, y = 6 }

    local ticks = ConvergenceTester({}, {}, self.testCamera, self.testTracker)

    lu.assertEquals(ticks, self.testCamera.zoomTicks, "couldn't converge in expected 14 ticks")

    lu.assertIsTrue(self.testCamera.centerPos.x == 10, "expected move to new center")
    lu.assertIsTrue(self.testCamera.centerPos.y == 6, "expected move to new center")
end

function TestCameraFollowTracker:TestConvergenceHorizontal()
    self.testTracker.centerPos.x = 10
    self.testTracker.size.x = 14

    local ticks = ConvergenceTester({}, {}, self.testCamera, self.testTracker)

    lu.assertEquals(ticks, self.testCamera.zoomTicks, "couldn't converge in expected 14 ticks")

    lu.assertIsTrue(self.testCamera.centerPos.x == 10, "expected move to new center")
    lu.assertIsTrue(self.testCamera.centerPos.y == 0, "expected move to new center")
    lu.assertEquals(self.testCamera.zoom, 1, "expected to have same zoom")
end

function TestCameraFollowTracker:TestConvergenceHorizontalBigJump()
    self.testTracker.centerPos.x = 123
    self.testTracker.size.x = 127

    local ticks = ConvergenceTester({}, {}, self.testCamera, self.testTracker)

    lu.assertEquals(ticks, self.testCamera.zoomTicks, "couldn't converge in expected 14 ticks")

    lu.assertIsTrue(self.testCamera.centerPos.x == 123, "expected move to new center")
    lu.assertIsTrue(self.testCamera.centerPos.y == 0, "expected move to new center")
    lu.assertNotEquals(self.testCamera.zoom, 1, "expected to be zoomed out")
end

function TestCameraFollowTracker:TestConvergenceVertical()
    self.testTracker.centerPos.y = 10
    self.testTracker.size.y = 14

    local ticks = ConvergenceTester({}, {}, self.testCamera, self.testTracker)

    lu.assertEquals(ticks, self.testCamera.zoomTicks, "couldn't converge in expected 14 ticks")

    lu.assertIsTrue(self.testCamera.centerPos.x == 0, "expected move to new center")
    lu.assertIsTrue(self.testCamera.centerPos.y == 10, "expected move to new center")
    lu.assertEquals(self.testCamera.zoom, 1, "expected to have same zoom")
end

function TestCameraFollowTracker:TestConvergenceVerticalBigJump()
    self.testTracker.centerPos.y = 142
    self.testTracker.size.y = 146

    local ticks = ConvergenceTester({}, {}, self.testCamera, self.testTracker)

    lu.assertEquals(ticks, self.testCamera.zoomTicks, "couldn't converge in expected 14 ticks")

    lu.assertIsTrue(self.testCamera.centerPos.x == 0, "expected move to new center")
    lu.assertIsTrue(self.testCamera.centerPos.y == 142, "expected move to new center")
    lu.assertNotEquals(self.testCamera.zoom, 1, "expected to be zoomed out")
end
