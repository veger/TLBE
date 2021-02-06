package.path = package.path .. ";../?.lua"
local TLBE = {
    Config = require("scripts.config"),
    Tracker = require("scripts.tracker")
}

local lu = require("luaunit")

function TestTrackerPlayer()
    -- mock Factorio provided globals
    global = {}
    game = {
        tick = 0,
        surfaces = {{}}
    }

    -- mock TLBE tables
    global.playerSettings = {
        TLBE.Config.newPlayerSettings({position = {x = 0, y = 0}})
    }

    local playerTracker = global.playerSettings[1].trackers[1]

    game.tick = 10
    TLBE.Tracker.tick(playerTracker, {position = {x = 10, y = 20}})

    lu.assertEquals(playerTracker.lastChange, 10, "expected to be updated to game.tick")
    lu.assertEquals(playerTracker.centerPos.x, 10, "expected to center to player")
    lu.assertEquals(playerTracker.centerPos.y, 20, "expected to center to player")

    game.tick = 20
    TLBE.Tracker.tick(playerTracker, {position = {x = 10, y = 20}})

    lu.assertEquals(playerTracker.lastChange, 10, "expected to be the same as the player did not move")
end
