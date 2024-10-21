package.path = package.path .. ";../?.lua"
local TLBE = {
    Main = require("scripts.main"),
    Tracker = require("scripts.tracker"),
    Config = require("scripts.config")
}

local lu = require("luaunit")

TestTrackerRocket = {}

function TestTrackerRocket:SetUp()
    -- mock Factorio provided globals
    storage = {}
    game = {
        surfaces = { { name = "nauvis" }, { name = "other-surface" } }
    }

    -- mock TLBE tables
    storage.playerSettings = {
        TLBE.Config.newPlayerSettings({ position = { x = 0, y = 0 } })
    }

    -- Update rocket tracker with our test settings
    self.rocketTracker = storage.playerSettings[1].trackers[2]
    for k, v in pairs(
        {
            centerPos = { x = 0, y = 0 },
            changeId = 1
        }
    ) do
        self.rocketTracker[k] = v
    end
end

function TestTrackerRocket:TestRocketLaunch()
    game.tick = 10
    TLBE.Main.rocket_launch({ rocket_silo = { surface = game.surfaces[1], position = { x = 10, y = 10 } } })

    lu.assertIsTrue(self.rocketTracker.enabled, "expected be enabled after rocket launch")
    lu.assertEquals(self.rocketTracker.changeId, 2, "expected to be incremented")
    lu.assertEquals(self.rocketTracker.centerPos.x, 10, "expected to center in middle of rocket_silo")
    lu.assertEquals(self.rocketTracker.centerPos.y, 10, "expected to center in middle of rocket_silo")
end

function TestTrackerRocket:TestRocketLaunchAlreadyActive()
    self.rocketTracker.enabled = true
    TLBE.Main.rocket_launch({ rocket_silo = { surface = game.surfaces[1], position = { x = 10, y = 10 } } })

    lu.assertIsTrue(self.rocketTracker.enabled, "expected be still enabled after rocket launch")
    lu.assertEquals(self.rocketTracker.changeId, 1, "expected to be unchanged")
    lu.assertEquals(self.rocketTracker.centerPos.x, 0, "expected to be unchanged")
    lu.assertEquals(self.rocketTracker.centerPos.y, 0, "expected to be unchanged")
end

function TestTrackerRocket:TestRocketLaunchOtherSurface()
    TLBE.Main.rocket_launch({ rocket_silo = { surface = game.surfaces[2], position = { x = 10, y = 10 } } })

    lu.assertIsFalse(self.rocketTracker.enabled, "expected be disabled after rocket launch on other surface")
end

function TestTrackerRocket:TestRocketLaunched()
    self.rocketTracker.enabled = true
    TLBE.Main.rocket_launched({ rocket_silo = { surface = game.surfaces[1] } })
    TLBE.Tracker.MoveToNextTrackerFinished(storage.playerSettings[1].trackers)

    lu.assertIsFalse(self.rocketTracker.enabled, "expected be disabled after rocket launched")
end

function TestTrackerRocket:TestRocketLaunchedAlreadyInactive()
    self.rocketTracker.enabled = false
    TLBE.Main.rocket_launched({ rocket_silo = { surface = game.surfaces[1] } })
    TLBE.Tracker.MoveToNextTrackerFinished(storage.playerSettings[1].trackers)

    lu.assertIsFalse(self.rocketTracker.enabled, "expected be still disabled after rocket launched")
end
