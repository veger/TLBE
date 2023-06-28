package.path = package.path .. ";../?.lua"
local TLBE = {
    Camera = require("scripts.camera"),
    Main = require("scripts.main"),
    Config = require("scripts.config")
}

local lu = require("luaunit")

local tileSize = 32

TestNewCamera = {}

function TestNewCamera:SetUp()
    game = {
        surfaces = { { name = "nauvis" } },
    }
end

function TestNewCamera.TestUniqueName()
    local camera1 = TLBE.Camera.newCamera({ postion = { 0, 0 } }, {})
    lu.assertEquals(camera1.name, "new camera", "with empty list no index is needed")

    local camera2 = TLBE.Camera.newCamera({ postion = { 0, 0 } }, { camera1 })
    lu.assertEquals(camera2.name, "new camera-2", "with camera 'new camera' already in the list, add '-2' to the name")

    local camera3 = TLBE.Camera.newCamera({ postion = { 0, 0 } }, { camera1, camera2 })
    lu.assertEquals(
        camera3.name,
        "new camera-3",
        "with camera 'new camera' and 'new camera-2' already in the list, add '-3' to the name"
    )
end

function TestNewCamera.TestConfig()
    local camera = TLBE.Camera.newCamera({ position = { 0, 0 } }, {})

    camera.frameRate = 10       -- 10 frames / second
    camera.transitionPeriod = 2 -- 2 seconds
    camera.speedGain = 5        -- 5 times speed up
    TLBE.Camera.updateConfig(camera)

    lu.assertEquals(camera.transitionTicks, 10 * 2,
        "Expected transitionTicks to be 10 fps * 2 seconds of transition = 20 frames (ticks)")
    lu.assertEquals(camera.screenshotInterval, 60 * 5 / 10,
        "Expected screenshotInterval to be 60 ticks/second * 5 (speed gain) / 10 fps = 30 ticks / frame")
    lu.assertEquals(camera.screenshotIntervalRealtime, 60 / 10,
        "Expected screenshotIntervalRealtime (no speedGain) to be 60 ticks/second / 10 fps = 30 ticks / frame")
end

TestCamera = {}

local function nextTick()
    TLBE.Main.tick()
    game.tick = game.tick + 1
end

function TestCamera:SetUp()
    -- mock Factorio provided globals
    global = {}
    game = {
        tick = 0,
        surfaces = { { name = "nauvis" } },
        take_screenshot = function()
        end
    }

    -- mock TLBE tables
    global.playerSettings = {
        TLBE.Config.newPlayerSettings({ position = { x = 0, y = 0 } }),
        TLBE.Config.newPlayerSettings({ position = { x = 0, y = 0 } })
    }

    game.players = {
        { index = 1, surface = game.surfaces[1] },
        { index = 2, surface = game.surfaces[1] }
    }

    -- Enable player1 camera
    global.playerSettings[1].cameras[1].enabled = true

    -- Make cameras easier to test
    self.testCameraPlayer1 = global.playerSettings[1].cameras[1]
    self.testCameraPlayer2 = global.playerSettings[2].cameras[1]
    for _, playerSettings in pairs(global.playerSettings) do
        for _, camera in pairs(playerSettings.cameras) do
            for k, v in pairs(
                {
                    width = 20 * tileSize,
                    height = 15 * tileSize,
                    screenshotInterval = 1,         -- do not skip any ticks for these tests
                    screenshotIntervalRealtime = 1, -- do not skip any ticks for these tests
                    transitionTicks = 1,            -- zoom immediately for these tests
                    changeId = -1,                  -- Make sure it is different than tracker.changeId
                }
            ) do
                camera[k] = v
            end
        end
    end
end

function TestCamera:TestTransitionFromPlayerToBaseTracker()
    game.players[1].position = { x = 5, y = 4 }

    nextTick()

    lu.assertEquals(self.testCameraPlayer1.centerPos.x, 5, "expected to be at player position")
    lu.assertEquals(self.testCameraPlayer1.centerPos.y, 4, "expected to be at player position")
    lu.assertEquals(self.testCameraPlayer1.zoom, 1, "expected that zoom at max_zoom")

    -- Move player and build entity
    game.players[1].position = { x = 2, y = 2 }
    TLBE.Main.entity_built(
        {
            created_entity = {
                surface = game.surfaces[1],
                bounding_box = {
                    left_top = { x = 1, y = 3 },
                    right_bottom = { x = 3, y = 4 }
                }
            }
        }
    )

    nextTick()

    lu.assertEquals(self.testCameraPlayer1.centerPos.x, 2, "expected to be at entity center")
    lu.assertEquals(self.testCameraPlayer1.centerPos.y, 3.5, "expected to be at entity center")
    lu.assertEquals(self.testCameraPlayer1.zoom, 1, "expected that zoom at max_zoom")

    lu.assertEquals(self.testCameraPlayer2.centerPos.x, 0, "expected disabled camera to be unchanged")
    lu.assertEquals(self.testCameraPlayer2.centerPos.y, 0, "expected disabled camera to be unchanged")
end

function TestCamera:TestRocketLaunch1()
    -- center camera at 0,0
    self.testCameraPlayer1.centerPos = { x = 0, y = 0 }
    self.testCameraPlayer1.zoom = 1

    -- Initialize base tracker
    TLBE.Main.entity_built(
        {
            created_entity = {
                surface = game.surfaces[1],
                bounding_box = {
                    left_top = { x = -1, y = -1 },
                    right_bottom = { x = 1, y = 1 }
                }
            }
        }
    )
    nextTick()
    lu.assertEquals(self.testCameraPlayer1.centerPos.x, 0, "expected to be at entity center")
    lu.assertEquals(self.testCameraPlayer1.centerPos.y, 0, "expected to be at entity center")
    lu.assertEquals(self.testCameraPlayer1.zoom, 1, "expected that zoom at max_zoom")

    -- Launch rocket
    TLBE.Main.rocket_launch({ rocket_silo = { surface = game.surfaces[1], position = { x = 10, y = 10 } } })
    nextTick()

    lu.assertEquals(self.testCameraPlayer1.centerPos.x, 10, "expected to be at rocket_silo position")
    lu.assertEquals(self.testCameraPlayer1.centerPos.y, 10, "expected to be at rocket_silo position")
    lu.assertEquals(self.testCameraPlayer1.zoom, 1, "expected that zoom at max_zoom")

    -- Rocket launched (return back to base)
    TLBE.Main.rocket_launched({ rocket_silo = { surface = game.surfaces[1] } })
    nextTick()

    lu.assertEquals(self.testCameraPlayer1.centerPos.x, 0, "expected to be back at entity center")
    lu.assertEquals(self.testCameraPlayer1.centerPos.y, 0, "expected to be back at entity center")
    lu.assertEquals(self.testCameraPlayer1.zoom, 1, "expected that zoom at max_zoom")
end

function TestCamera:TestResolutionChange()
    -- Only keep base tracker (so it is the active tacker)
    self.testCameraPlayer1.trackers = { self.testCameraPlayer1.trackers[3] }
    local baseTracker = self.testCameraPlayer1.trackers[1];

    TLBE.Main.entity_built(
        {
            created_entity = {
                surface = game.surfaces[1],
                bounding_box = {
                    left_top = { x = -20, y = -20 },
                    right_bottom = { x = 20, y = 20 }
                }
            }
        }
    )

    -- force set camera position and zoom
    ---@diagnostic disable-next-line: param-type-mismatch player(Data) can be nil when disableSmooth is true
    TLBE.Camera.followTracker(nil, nil, self.testCameraPlayer1, baseTracker, true)
    local oldZoom = self.testCameraPlayer1.zoom;
    local oldCenterPos = self.testCameraPlayer1.centerPos;

    TLBE.Camera.setWidth(self.testCameraPlayer1, self.testCameraPlayer1.width * 2)
    TLBE.Camera.setHeight(self.testCameraPlayer1, self.testCameraPlayer1.height * 2)

    lu.assertEquals(self.testCameraPlayer1.centerPos.x, oldCenterPos.x, "expected centerpos to be the same")
    lu.assertEquals(self.testCameraPlayer1.centerPos.y, oldCenterPos.y, "expected centerpos to be the same")
    lu.assertNotEquals(self.testCameraPlayer1.zoom, oldZoom, "expected that zoom has been changed")
    lu.assertEquals(self.testCameraPlayer1.zoom, oldZoom * 2,
        "expected that zoom has doubled as resolution has been doubled")
end
