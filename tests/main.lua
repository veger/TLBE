package.path = package.path .. ";../?.lua"
local Camera = require("scripts.camera")
local Config = require("scripts.config")
local Main = require("scripts.main")
local Tracker = require("scripts.tracker")
local Utils = require("scripts.utils")
local lu = require("luaunit")

TestGetBaseBBox = {}

function TestGetBaseBBox.TestNoEntities()
    game = {
        surfaces = {
            test = {
                find_entities_filtered = function()
                    return {}
                end
            }
        }
    }

    local bbox = Main.getBaseBBox("test")

    lu.assertIsNil(bbox, "expected nil with empty base")
end

---@diagnostic disable: need-check-nil
function TestGetBaseBBox.TestSingleEntity()
    game = {
        surfaces = {
            test = {
                find_entities_filtered = function()
                    return {
                        {
                            bounding_box = {
                                left_top = { x = 1, y = 3 },
                                right_bottom = { x = 3, y = 4 }
                            }
                        }
                    }
                end
            }
        }
    }

    local bbox = Main.getBaseBBox("test")

    lu.assertNotIsNil(bbox, "expected to have bbox filled in")
    lu.assertEquals(bbox.minPos.x, 1 - Utils.boundarySize)
    lu.assertEquals(bbox.minPos.y, 3 - Utils.boundarySize)
    lu.assertEquals(bbox.maxPos.x, 3 + Utils.boundarySize)
    lu.assertEquals(bbox.maxPos.y, 4 + Utils.boundarySize)
end

---@diagnostic disable: need-check-nil
function TestGetBaseBBox.TestMultipleEntities()
    game = {
        surfaces = {
            test = {
                find_entities_filtered = function()
                    return {
                        {
                            bounding_box = {
                                left_top = { x = 1, y = 3 },
                                right_bottom = { x = 3, y = 4 } -- top most value
                            }
                        },
                        {
                            bounding_box = {
                                left_top = { x = -1, y = 0 }, -- left and bottom most values
                                right_bottom = { x = 2, y = 2 }
                            }
                        },
                        {
                            bounding_box = {
                                left_top = { x = 4, y = 2 },
                                right_bottom = { x = 6, y = 3 } -- right most value
                            }
                        },
                        {
                            type = "character",
                            bounding_box = {
                                left_top = { x = 4, y = 2 },
                                right_bottom = { x = 20, y = 3 } -- actual right most value (but skipped)
                            }
                        }
                    }
                end
            }
        }
    }

    local bbox = Main.getBaseBBox("test")

    lu.assertNotIsNil(bbox, "expected to have bbox filled in")
    lu.assertEquals(bbox.minPos.x, -1 - Utils.boundarySize)
    lu.assertEquals(bbox.minPos.y, 0 - Utils.boundarySize)
    lu.assertEquals(bbox.maxPos.x, 6 + Utils.boundarySize)
    lu.assertEquals(bbox.maxPos.y, 4 + Utils.boundarySize)
end

TestTick = {}


function TestTick:Setup()
    self.screenshotTaken = false
    game = {
        tick = 0,
        players = {
            {
                index = 1,
                position = {
                    x = 0,
                    y = 0
                },
                surface = {
                    name = "test-surface",
                }
            }
        },
        surfaces = {
            {
                name = "test-surface",
            }
        },
        take_screenshot = function()
            self.screenshotTaken = true
        end
    }
    global = {
        playerSettings = {
            Config.newPlayerSettings(game.players[1])
        }
    }

    self.areaTracker = Tracker.newTracker "area"
    self.camera = global.playerSettings[1].cameras[1]
    self.camera.enabled = true
    self.camera.screenshotInterval = 1 -- take screenshot every tick
    global.playerSettings[1].trackers = { self.areaTracker }
    self.camera.trackers = { self.areaTracker }
    global.playerSettings[1].sequentialNames = true

    Camera.SetActiveTracker(self.camera, self.areaTracker)
end

function TestTick.tick()
    Main.tick()
    game.tick = game.tick + 1
end

function TestTick:TestFollowTracker()
    self.camera.transitionTicks = 4   -- 4 ticks for a full transition
    self.areaTracker.centerPos.x = 10 -- move 10 tiles
    self.tick()
    self.tick()
    self.tick()
    self.tick()

    lu.assertTrue(self.screenshotTaken, "Expected a screenshot being taken")
    lu.assertEquals(self.camera.screenshotNumber, 4 + 1)

    lu.assertEquals(self.camera.centerPos.x, self.areaTracker.centerPos.x)
end

function TestTick:TestPause()
    self.camera.enabled = false
    self.camera.transitionTicks = 5  -- 10 ticks for a full transition
    self.areaTracker.centerPos.x = 5 -- move 10 tiles, so we'd expect one tile movement per tick

    -- Let some ticks pass, while cmaera is paused (should not influence the result)
    self.tick()
    self.tick()
    self.tick()
    self.tick()

    lu.assertFalse(self.screenshotTaken, "Expected a screenshot not being taken, camera is paused")
    lu.assertEquals(self.camera.screenshotNumber, 1) -- not updated

    self.camera.enabled = true

    self.tick()

    lu.assertEquals(self.camera.screenshotNumber, 2,
        "Expected a screenshot being taken, number should have been increased")

    -- We expect one tile per tick with linear movement
    lu.assertEquals(self.camera.centerPos.x, 1)

    self.tick()
    lu.assertEquals(self.camera.centerPos.x, 2)

    self.tick()
    self.tick()
    self.tick()
    lu.assertEquals(self.camera.centerPos.x, self.areaTracker.centerPos.x)
end
