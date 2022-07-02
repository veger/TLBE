package.path = package.path .. ";../?.lua"
local TLBE = {
    Config = require("scripts.config"),
    Tracker = require("scripts.tracker")
}

local lu = require("luaunit")

TestTrackerPlayer = {}

function TestTrackerPlayer:SetUp()
    -- mock Factorio provided globals
    global = {}
    -- luacheck: globals game
    game = {
        tick = 0,
        surfaces = { { name = "nauvis" }, { name = "other-surface" } }
    }

    -- mock TLBE tables
    global.playerSettings = {
        TLBE.Config.newPlayerSettings({ position = { x = 0, y = 0 } })
    }

    self.playerTracker = global.playerSettings[1].trackers[1]
end

-- luacheck: globals game
function TestTrackerPlayer:TestTrackerPlayer()
    game.tick = 10
    TLBE.Tracker.tick(self.playerTracker, { surface = game.surfaces[1], position = { x = 10, y = 20 } })

    lu.assertEquals(self.playerTracker.lastChange, 10, "expected to be updated to game.tick")
    lu.assertEquals(self.playerTracker.centerPos.x, 10, "expected to center to player")
    lu.assertEquals(self.playerTracker.centerPos.y, 20, "expected to center to player")

    game.tick = 20
    TLBE.Tracker.tick(self.playerTracker, { surface = game.surfaces[1], position = { x = 10, y = 20 } })

    lu.assertEquals(self.playerTracker.lastChange, 10, "expected to be the same as the player did not move")
end

-- luacheck: globals game
function TestTrackerPlayer:TestTrackerPlayerOnOtherSurface()
    game.tick = 10
    TLBE.Tracker.tick(self.playerTracker, { surface = game.surfaces[2], position = { x = 10, y = 20 } })

    lu.assertEquals(self.playerTracker.lastChange, 0, "expected to be at old value")
    lu.assertEquals(self.playerTracker.centerPos, nil, "expected to be at old value")
end
