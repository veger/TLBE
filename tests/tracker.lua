package.path = package.path .. ";../?.lua"
local Tracker = require("scripts.tracker")
local lu = require("luaunit")

TestNewTracker = {}

function TestNewTracker:SetUp()
    game = {
        surfaces = { { name = "nauvis" } },
    }
end

function TestNewTracker.TestUniqueName()
    local baseTracker = Tracker.newTracker("base")
    lu.assertEquals(baseTracker.name, "base", "with empty list use tracker type as name")

    local secondBaseTracker = Tracker.newTracker("base", { baseTracker })
    lu.assertEquals(secondBaseTracker.name, "base-2", "with tracker 'base' already in the list, add '-2' to the name")

    local thirdBaseTracker = Tracker.newTracker("base", { baseTracker, secondBaseTracker })
    lu.assertEquals(
        thirdBaseTracker.name,
        "base-3",
        "with tracker 'base' and 'base-2' already in the list, add '-3' to the name"
    )

    local playerTracker = Tracker.newTracker("player", { baseTracker })
    lu.assertEquals(playerTracker.name, "player", "with tracker 'base' in the list, tracker should be called 'player'")
end
