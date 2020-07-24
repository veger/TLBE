package.path = package.path .. ";../?.lua"
local TLBE = {
    Main = require("scripts.main"),
    Config = require("scripts.config")
}

local lu = require("luaunit")

TestTrackerRocket = {}

function TestTrackerRocket:SetUp()
    -- mock Factorio provided globals
    global = {}
    game = {tick = 0}

    -- mock TLBE tables
    global.playerSettings = {
        TLBE.Config.newPlayerSettings({position = {x = 0, y = 0}})
    }

    -- Update rocket tracker with our test settings
    self.rocketTracker = global.playerSettings[1].trackers[2]
    for k, v in pairs(
        {
            centerPos = {x = 0, y = 0},
            lastChange = 1
        }
    ) do
        self.rocketTracker[k] = v
    end
end

function TestTrackerRocket:TestRocketLaunch()
    game.tick = 10
    TLBE.Main.rocket_launch({rocket_silo = {position = {x = 10, y = 10}}})

    lu.assertIsTrue(self.rocketTracker.enabled, "expected be enabled after rocket launch")
    lu.assertEquals(self.rocketTracker.lastChange, 10, "expected to be updated to game.tick")
    lu.assertEquals(self.rocketTracker.centerPos.x, 10, "expected to center in middle of rocket_silo")
    lu.assertEquals(self.rocketTracker.centerPos.y, 10, "expected to center in middle of rocket_silo")
end

function TestTrackerRocket:TestRocketLaunchAlreadyActive()
    self.rocketTracker.enabled = true
    TLBE.Main.rocket_launch({rocket_silo = {position = {x = 10, y = 10}}})

    lu.assertIsTrue(self.rocketTracker.enabled, "expected be still enabled after rocket launch")
    lu.assertEquals(self.rocketTracker.lastChange, 1, "expected to be at old value")
    lu.assertEquals(self.rocketTracker.centerPos.x, 0, "expected to be at old value")
    lu.assertEquals(self.rocketTracker.centerPos.y, 0, "expected to be at old value")
end

function TestTrackerRocket:TestRocketLaunched()
    game.tick = 15
    self.rocketTracker.enabled = true
    TLBE.Main.rocket_launched()

    lu.assertIsFalse(self.rocketTracker.enabled, "expected be disabled after rocket launched")
    lu.assertEquals(self.rocketTracker.lastChange, 15, "expected to be updated to game.tick")
end

function TestTrackerRocket:TestRocketLaunched()
    game.tick = 15
    self.rocketTracker.enabled = false
    TLBE.Main.rocket_launched()

    lu.assertIsFalse(self.rocketTracker.enabled, "expected be still disabled after rocket launched")
    lu.assertEquals(self.rocketTracker.lastChange, 1, "expected to be at old value")
end
