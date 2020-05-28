package.path = package.path .. ";../?.lua"
local TLBE = {Main = require("scripts.main")}
local Util = require("util")

local lu = require("luaunit")

TestFollowBaseSingleEntity = {}

function TestFollowBaseSingleEntity:SetUp()
    -- mock Factorio provided globals
    global = {}
    game = {tick = 0}

    -- mock TLBE tables
    self.player = {
        print = function()
        end
    }
    self.playerSettings = {
        width = 640,
        height = 480,
        centerPos = {x = 0, y = 0},
        screenshotInterval = 1,
        zoom = 1,
        zoomTicks = 15
    }
end

function TestFollowBaseSingleEntity:TestInitialUpRight()
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

    TLBE.Main.follow_center_pos(self.playerSettings, self.player, global.centerPos, global.factorySize)

    lu.assertIsTrue(self.playerSettings.centerPos.x > 0, "expected that centerPos.x moved right")
    lu.assertIsTrue(self.playerSettings.centerPos.y > 0, "expected that centerPos.y moved up")
    lu.assertIsTrue(
        self.playerSettings.zoom == 1,
        "expected that zoom did not change, as a 1x1 entity should fit the resolutin"
    )
end

function TestFollowBaseSingleEntity:TestInitialBottomLeft()
    TLBE.Main.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = -2, y = -2},
                    right_bottom = {x = -1, y = -1}
                }
            }
        }
    )

    TLBE.Main.follow_center_pos(self.playerSettings, self.player, global.centerPos, global.factorySize)

    lu.assertIsTrue(self.playerSettings.centerPos.x < 0, "expected that centerPos.x moved left")
    lu.assertIsTrue(self.playerSettings.centerPos.y < 0, "expected that centerPos.y moved down")
    lu.assertIsTrue(
        self.playerSettings.zoom == 1,
        "expected that zoom did not change, as a 1x1 entity should fit the resolutin"
    )
end

function TestFollowBaseSingleEntity:TestConvergence()
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
    TLBE.Main.follow_center_pos(self.playerSettings, self.player, global.centerPos, global.factorySize)

    local ticks = Util.ConvergenceTester(self.playerSettings, self.player, global.centerPos, global.factorySize)

    lu.assertEquals(ticks, 15, "couldn't converge in expected 15 ticks")

    lu.assertIsTrue(self.playerSettings.centerPos.x == 1.5, "expected to center in middle of entity")
    lu.assertIsTrue(self.playerSettings.centerPos.y == 1.5, "expected to center in middle of entity")
end

TestFollowBase = {}

function TestFollowBase:SetUp()
    -- mock Factorio provided globals
    global = {}
    game = {tick = 0}

    -- mock TLBE tables
    self.player = {
        print = function()
        end
    }
    self.playerSettings = {
        width = 640,
        height = 480,
        centerPos = {x = 1.5, y = 1.5}, -- center of existing entity
        screenshotInterval = 1,
        zoom = 1,
        zoomTicks = 10
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
end

function TestFollowBase:TestConvergenceDiagonal()
    TLBE.Main.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 10, y = 6},
                    right_bottom = {x = 11, y = 7}
                }
            }
        }
    )

    local ticks = Util.ConvergenceTester(self.playerSettings, self.player, global.centerPos, global.factorySize)

    lu.assertEquals(ticks, 10, "couldn't converge in expected 10 ticks")

    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.x - 6) < 0.01,
        "expected to center in middle of both entities"
    )
    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.y - 4) < 0.01,
        "expected to center in middle of both entities"
    )
end

function TestFollowBase:TestConvergenceHorizontal()
    TLBE.Main.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 10, y = 1},
                    right_bottom = {x = 11, y = 2}
                }
            }
        }
    )

    local ticks = Util.ConvergenceTester(self.playerSettings, self.player, global.centerPos, global.factorySize)

    lu.assertEquals(ticks, 10, "couldn't converge in expected 10 ticks")

    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.x - 6) < 0.01,
        "expected to center in middle of both entities"
    )
    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.y - 1.5) < 0.01,
        "expected to center in middle of both entities"
    )
end

function TestFollowBase:TestConvergenceHorizontalBigJump()
    TLBE.Main.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 50, y = 6},
                    right_bottom = {x = 51, y = 7}
                }
            }
        }
    )

    local ticks = Util.ConvergenceTester(self.playerSettings, self.player, global.centerPos, global.factorySize)

    lu.assertEquals(ticks, 10, "couldn't converge in expected 10 ticks")

    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.x - 26) < 0.01,
        "expected to center in middle of both entities"
    )
    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.y - 4) < 0.01,
        "expected to center in middle of both entities"
    )
end

function TestFollowBase:TestConvergenceVertical()
    TLBE.Main.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 1, y = 6},
                    right_bottom = {x = 2, y = 7}
                }
            }
        }
    )

    local ticks = Util.ConvergenceTester(self.playerSettings, self.player, global.centerPos, global.factorySize)

    lu.assertEquals(ticks, 10, "couldn't converge in expected 10 ticks")

    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.x - 1.5) < 0.01,
        "expected to center in middle of both entities"
    )
    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.y - 4) < 0.01,
        "expected to center in middle of both entities"
    )
end

function TestFollowBase:TestConvergenceVerticalBigJump()
    TLBE.Main.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 1, y = 50},
                    right_bottom = {x = 2, y = 51}
                }
            }
        }
    )

    local ticks = Util.ConvergenceTester(self.playerSettings, self.player, global.centerPos, global.factorySize)

    lu.assertEquals(ticks, 10, "couldn't converge in expected 10 ticks")

    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.x - 1.5) < 0.01,
        "expected to center in middle of both entities"
    )
    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.y - 26) < 0.01,
        "expected to center in middle of both entities"
    )
end
