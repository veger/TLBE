package.path = package.path .. ";../?.lua"
local TLBE = {
    Main = require("scripts.main"),
    Config = require("scripts.config")
}

local lu = require("luaunit")

local boundarySize = 2

TestTrackerBase = {}

function TestTrackerBase:SetUp()
    -- mock Factorio provided globals
    global = {}
    game = {
        surfaces = { { name = "nauvis" }, { name = "other-surface" } }
    }

    -- mock TLBE tables
    global.playerSettings = {
        TLBE.Config.newPlayerSettings({ position = { x = 0, y = 0 } })
    }

    -- Update base tracker with our test settings
    self.baseTracker = global.playerSettings[1].trackers[3]
    for k, v in pairs(
        {
            changeId = 1
        }
    ) do
        self.baseTracker[k] = v
    end
end

function TestTrackerBase:TestDisabledTracker()
    game.tick = 10
    self.baseTracker.enabled = false
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

    lu.assertEquals(self.baseTracker.changeId, 1, "expected to be at old value")
    lu.assertIsNil(self.baseTracker.centerPos, "expected to be at old value")
    lu.assertIsNil(self.baseTracker.size, "expected to be at old value")
end

function TestTrackerBase:TestBuildOnOtherSurface()
    TLBE.Main.entity_built(
        {
            created_entity = {
                surface = game.surfaces[2],
                bounding_box = {
                    left_top = { x = 1, y = 3 },
                    right_bottom = { x = 3, y = 4 }
                }
            }
        }
    )

    lu.assertEquals(self.baseTracker.changeId, 1, "expected to be at old value")
    lu.assertIsNil(self.baseTracker.centerPos, "expected to be at old value")
    lu.assertIsNil(self.baseTracker.size, "expected to be at old value")
end

function TestTrackerBase:TestSingleEntityBuilt()
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

    lu.assertEquals(self.baseTracker.changeId, 2, "expected to be incremented")
    lu.assertEquals(self.baseTracker.centerPos.x, 1 + (3 - 1) / 2, "expected to center in middle of entity")
    lu.assertEquals(self.baseTracker.centerPos.y, 3 + (4 - 3) / 2, "expected to center in middle of entity")
    lu.assertEquals(
        self.baseTracker.size.x,
        3 - 1 + 2 * boundarySize,
        "expected to have width of entity surrounded by global boundary"
    )
    lu.assertEquals(
        self.baseTracker.size.y,
        4 - 3 + 2 * boundarySize,
        "expected to have height of of entity surrounded by global boundary"
    )
end

function TestTrackerBase:TestMultipleEntitiesBuilt()
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

    lu.assertEquals(self.baseTracker.changeId, 2, "expected to be incremented")

    TLBE.Main.entity_built(
        {
            created_entity = {
                surface = game.surfaces[1],
                bounding_box = {
                    left_top = { x = -2, y = 5 },
                    right_bottom = { x = 0, y = 8 }
                }
            }
        }
    )

    lu.assertEquals(self.baseTracker.changeId, 3, "expected to be incremented")
    lu.assertEquals(self.baseTracker.centerPos.x, -2 + (3 - -2) / 2, "expected to center in middle of entity")
    lu.assertEquals(self.baseTracker.centerPos.y, 3 + (8 - 3) / 2, "expected to center in middle of entity")
    lu.assertEquals(
        self.baseTracker.size.x,
        3 - -2 + 2 * boundarySize,
        "expected to have width of entity surrounded by global boundary"
    )
    lu.assertEquals(
        self.baseTracker.size.y,
        8 - 3 + 2 * boundarySize,
        "expected to have height of of entity surrounded by global boundary"
    )
end
