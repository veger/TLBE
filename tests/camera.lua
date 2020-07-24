package.path = package.path .. ";../?.lua"
local TLBE = {
    Main = require("scripts.main"),
    Config = require("scripts.config")
}

local lu = require("luaunit")

local tileSize = 32

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
        surfaces = {{}},
        take_screenshot = function()
        end
    }

    -- mock TLBE tables
    global.playerSettings = {
        TLBE.Config.newPlayerSettings({position = {x = 0, y = 0}}),
        TLBE.Config.newPlayerSettings({position = {x = 0, y = 0}})
    }

    game.players = {
        {index = 1},
        {index = 2}
    }

    -- Disable TLBE for player2
    global.playerSettings[2].enabled = false

    -- Make cameras easier to test
    self.testCameraPlayer1 = global.playerSettings[1].cameras[1]
    for _, playerSettings in pairs(global.playerSettings) do
        for _, camera in pairs(playerSettings.cameras) do
            for k, v in pairs(
                {
                    width = 20 * tileSize,
                    height = 15 * tileSize,
                    screenshotInterval = 1, -- do not skip any ticks for these tests
                    realtimeInterval = 1, -- do not skip any ticks for these tests
                    zoomTicks = 1, -- zoom immediately for these tests
                    zoomTicksRealtime = 1 -- zoom immediately for these tests
                }
            ) do
                camera[k] = v
            end
        end
    end
end

function TestCamera:TestTransitionFromPlayerToBaseTracker()
    game.players[1].position = {x = 5, y = 4}

    nextTick()

    lu.assertEquals(self.testCameraPlayer1.centerPos.x, 5, "expected to be at player position")
    lu.assertEquals(self.testCameraPlayer1.centerPos.y, 4, "expected to be at player position")
    lu.assertEquals(self.testCameraPlayer1.zoom, 1, "expected that zoom at max_zoom")

    -- Move player and build entity
    game.players[1].position = {x = 2, y = 2}
    TLBE.Main.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 1, y = 3},
                    right_bottom = {x = 3, y = 4}
                }
            }
        }
    )

    nextTick()

    lu.assertEquals(self.testCameraPlayer1.centerPos.x, 2, "expected to be at entity center")
    lu.assertEquals(self.testCameraPlayer1.centerPos.y, 3.5, "expected to be at entity center")
    lu.assertEquals(self.testCameraPlayer1.zoom, 1, "expected that zoom at max_zoom")

    lu.assertEquals(global.playerSettings[2].cameras[1].centerPos.x, 0, "expected disabled player to be unchanged")
    lu.assertEquals(global.playerSettings[2].cameras[1].centerPos.y, 0, "expected disabled player to be unchanged")
end

function TestCamera:TestRocketLaunch()
    -- center camera at 0,0
    self.testCameraPlayer1.centerPos = {x = 0, y = 0}
    self.testCameraPlayer1.zoom = 1

    -- Initialize base tracker
    TLBE.Main.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = -1, y = -1},
                    right_bottom = {x = 1, y = 1}
                }
            }
        }
    )
    nextTick()
    lu.assertEquals(self.testCameraPlayer1.centerPos.x, 0, "expected to be at entity center")
    lu.assertEquals(self.testCameraPlayer1.centerPos.y, 0, "expected to be at entity center")
    lu.assertEquals(self.testCameraPlayer1.zoom, 1, "expected that zoom at max_zoom")

    -- Launch rocket
    TLBE.Main.rocket_launch({rocket_silo = {position = {x = 10, y = 10}}})
    nextTick()

    lu.assertEquals(self.testCameraPlayer1.centerPos.x, 10, "expected to be at rocket_silo position")
    lu.assertEquals(self.testCameraPlayer1.centerPos.y, 10, "expected to be at rocket_silo position")
    lu.assertEquals(self.testCameraPlayer1.zoom, 1, "expected that zoom at max_zoom")

    -- Rocket launched (return back to base)
    TLBE.Main.rocket_launched()
    nextTick()

    lu.assertEquals(self.testCameraPlayer1.centerPos.x, 0, "expected to be back at entity center")
    lu.assertEquals(self.testCameraPlayer1.centerPos.y, 0, "expected to be back at entity center")
    lu.assertEquals(self.testCameraPlayer1.zoom, 1, "expected that zoom at max_zoom")
end
