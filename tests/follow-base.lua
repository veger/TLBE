local lu = require("luaunit")

MAX_TICKS = 100

--- @return number @ticks
function ConvergenceTester(playerSettings, player)
    local ticks = 0
    local currentX = playerSettings.centerPos.x
    local currentY = playerSettings.centerPos.y
    local currentZoom = playerSettings.zoom

    repeat
        ticks = ticks + 1
        local lastX = currentX
        local lastY = currentY
        local lastZoom = currentZoom

        tlbe.follow_base(playerSettings, player)

        currentX = playerSettings.centerPos.x
        currentY = playerSettings.centerPos.y
        currentZoom = playerSettings.zoom
    until ticks == MAX_TICKS or
        (math.abs(lastX - currentX) < 0.0001 and math.abs(lastY - currentY) < 0.0001 and
            math.abs(lastZoom - currentZoom) < 0.0001)

    return ticks
end

TestFollowBaseSingleEntity = {}

function TestFollowBaseSingleEntity:SetUp()
    -- mock Factorio provided globals
    global = {}

    -- mock TLBE tables
    self.player = {
        print = function()
        end
    }
    self.playerSettings = {
        width = 640,
        height = 480,
        centerPos = {x = 0, y = 0},
        zoom = 1
    }
end

function TestFollowBaseSingleEntity:TestInitialUpRight()
    tlbe.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 1, y = 1},
                    right_bottom = {x = 2, y = 2}
                }
            }
        }
    )

    tlbe.follow_base(self.playerSettings, self.player)

    lu.assertIsTrue(self.playerSettings.centerPos.x > 0, "expected that centerPos.x moved right")
    lu.assertIsTrue(self.playerSettings.centerPos.y > 0, "expected that centerPos.y moved up")
    lu.assertIsTrue(
        self.playerSettings.zoom == 1,
        "expected that zoom did not change, as a 1x1 entity should fit the resolutin"
    )
end

function TestFollowBaseSingleEntity:TestInitialBottomLeft()
    tlbe.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = -2, y = -2},
                    right_bottom = {x = -1, y = -1}
                }
            }
        }
    )

    tlbe.follow_base(self.playerSettings, self.player)

    lu.assertIsTrue(self.playerSettings.centerPos.x < 0, "expected that centerPos.x moved left")
    lu.assertIsTrue(self.playerSettings.centerPos.y < 0, "expected that centerPos.y moved down")
    lu.assertIsTrue(
        self.playerSettings.zoom == 1,
        "expected that zoom did not change, as a 1x1 entity should fit the resolutin"
    )
end

function TestFollowBaseSingleEntity:TestConvergence()
    tlbe.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 1, y = 1},
                    right_bottom = {x = 2, y = 2}
                }
            }
        }
    )
    tlbe.follow_base(self.playerSettings, self.player)

    local ticks = ConvergenceTester(self.playerSettings, self.player)

    lu.assertIsTrue(ticks < MAX_TICKS, "couldn't converge in 100 ticks")

    lu.assertIsTrue(self.playerSettings.centerPos.x == 1, "expected to center in middle of entity")
    lu.assertIsTrue(self.playerSettings.centerPos.y == 1, "expected to center in middle of entity")
end

TestFollowBase = {}

function TestFollowBase:SetUp()
    -- mock Factorio provided globals
    global = {}

    -- mock TLBE tables
    self.player = {
        print = function()
        end
    }
    self.playerSettings = {
        width = 640,
        height = 480,
        centerPos = {x = 1.5, y = 1.5}, -- center of existing entity
        zoom = 1
    }

    tlbe.entity_built(
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
    tlbe.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 10, y = 6},
                    right_bottom = {x = 11, y = 7}
                }
            }
        }
    )

    local ticks = ConvergenceTester(self.playerSettings, self.player)

    lu.assertIsTrue(ticks < 100, "couldn't converge in 100 ticks")

    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.x - 6) < 0.01,
        "expected to center in middle of both entities"
    )
    lu.assertIsTrue(math.abs(self.playerSettings.centerPos.y - 4) < 0.01, "expected to center in middle of entity")
end

function TestFollowBase:TestConvergenceHorizontal()
    tlbe.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 10, y = 1},
                    right_bottom = {x = 11, y = 2}
                }
            }
        }
    )

    local ticks = ConvergenceTester(self.playerSettings, self.player)

    lu.assertIsTrue(ticks < 100, "couldn't converge in 100 ticks")

    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.x - 6) < 0.01,
        "expected to center in middle of both entities"
    )
    lu.assertIsTrue(math.abs(self.playerSettings.centerPos.y - 1) < 0.01, "expected to center in middle of entity")
end

function TestFollowBase:TestConvergenceHorizontal()
    tlbe.entity_built(
        {
            created_entity = {
                bounding_box = {
                    left_top = {x = 1, y = 6},
                    right_bottom = {x = 2, y = 7}
                }
            }
        }
    )

    local ticks = ConvergenceTester(self.playerSettings, self.player)

    lu.assertIsTrue(ticks < 100, "couldn't converge in 100 ticks")

    lu.assertIsTrue(
        math.abs(self.playerSettings.centerPos.x - 1) < 0.01,
        "expected to center in middle of both entities"
    )
    lu.assertIsTrue(math.abs(self.playerSettings.centerPos.y - 4) < 0.01, "expected to center in middle of entity")
end
