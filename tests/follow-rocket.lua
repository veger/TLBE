package.path = package.path .. ";../?.lua"
local TLBE = {Main = require("scripts.main")}
local Util = require("util")

local lu = require("luaunit")

TestFollowRocket = {}

function TestFollowRocket:SetUp()
    -- mock Factorio provided globals
    global = {}
    game = {tick = 0}

    -- mock TLBE tables
    self.player = {
        print = function()
        end
    }
    global.playerSettings = {
        {
            cameras = {
                {
                    width = 640,
                    height = 480,
                    centerPos = {x = 1.5, y = 1.5}, -- center of existing entity
                    screenshotInterval = 1,
                    rocketInterval = 1,
                    zoom = 1,
                    zoomTicks = 10,
                    zoomTicksRocket = 10,
                    lastChange = 1
                }
            }
        }
    }

    TLBE.Main.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 1, y = 1},
                    right_bottom = {x = 2, y = 2}
                }
            }
        }
    )
    TLBE.Main.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 50, y = 50},
                    right_bottom = {x = 51, y = 51}
                }
            }
        }
    )

    -- Stablize on current base
    local mainCamera = global.playerSettings[1].cameras[1]
    Util.ConvergenceTester(global.playerSettings[1], self.player, mainCamera.centerPos, mainCamera.factorySize)
end

function TestFollowRocket:TestRocketLaunch()
    TLBE.Main.rocket_launch({rocket_silo = {position = {x = 10, y = 10}}})

    local mainCamera = global.playerSettings[1].cameras[1]
    local ticks =
        Util.ConvergenceTester(
        global.playerSettings[1],
        self.player,
        global.rocketLaunching.centerPos,
        global.rocketLaunching.size
    )

    lu.assertEquals(ticks, 10, "couldn't converge in expected 10 ticks")

    lu.assertIsTrue(math.abs(mainCamera.centerPos.x - 10) < 0.01, "expected to center in middle of both entities")
    lu.assertIsTrue(math.abs(mainCamera.centerPos.y - 10) < 0.01, "expected to center in middle of both entities")
    lu.assertIsTrue(math.abs(mainCamera.zoom - 1) < 0.01, "expected to zoomed in maximally")
end
