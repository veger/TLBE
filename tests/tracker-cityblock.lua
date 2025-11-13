package.path = package.path .. ";../?.lua"
local TLBE = {
    Config = require("scripts.config"),
    Tracker = require("scripts.tracker")
}

local lu = require("luaunit")

TestTrackerCityBlock = {}

function TestTrackerCityBlock:Setup()
    -- mock Factorio provided globals
    storage = {}
    game = {
        surfaces = { { name = "nauvis" }, { name = "other-surface" } },
        players = {
            surface = {
                name = "other-surface",
            }
        }
    }

    -- mock TLBE tables
    storage.playerSettings = {
        TLBE.Config.newPlayerSettings({ position = { x = 0, y = 0 } })
    }

    -- Create city block tracker
    self.cityblockTracker = TLBE.Tracker.newTracker(game.players[1].surface, "cityblock",
        storage.playerSettings[1].trackers)
    for k, v in pairs(
        {
            changeId = 1
        }
    ) do
        self.cityblockTracker[k] = v
    end
end

function TestTrackerCityBlock:Focus()
    -- chunk-aligned city block is chunk-aligned
    self.cityblockTracker.cityBlock.blockSize.x = 32
    self.cityblockTracker.cityBlock.blockSize.y = 32


    TLBE.Tracker.focusCityBlock(self.cityblockTracker, { x = 0, y = 0 })
    lu.assertEquals(self.cityblockTracker.cityBlock.currentBlock, { x = 0, y = 0 },
        "focus on tile zero should be in the block zero")
    lu.assertEquals(self.cityblockTracker.centerPos, { x = 16, y = 16 },
        "focus on tile zero should center on the zero chunk")

    TLBE.Tracker.focusCityBlock(self.cityblockTracker, { x = 14, y = 19 })
    lu.assertEquals(self.cityblockTracker.cityBlock.currentBlock, { x = 0, y = 0 },
        "focus on a tile within zero chunk should be in the block zero")
    lu.assertEquals(self.cityblockTracker.centerPos, { x = 16, y = 16 },
        "focus on a tile within zero chunk should center on the zero chunk")

    TLBE.Tracker.focusCityBlock(self.cityblockTracker, { x = 32, y = 32 })
    lu.assertEquals(self.cityblockTracker.cityBlock.currentBlock, { x = 0, y = 0 },
        "focus on tile {32,32} should be in the block {1,1}")
    lu.assertEquals(self.cityblockTracker.centerPos, { x = 32 + 16, y = 32 + 16 },
        "focus on tile {32,32} should center on the {1,1} chunk")
end

function TestTrackerCityBlock:scale()
    -- zooming doesn't recenter, but does affect width and height
    self.cityblockTracker.cityBlock.blockSize.x = 32
    self.cityblockTracker.cityBlock.blockSize.y = 32
    self.cityblockTracker.cityBlock.currentBlock.x = 0
    self.cityblockTracker.cityBlock.currentBlock.y = 0
    TLBE.Tracker.recalculateCityBlock(self.cityblockTracker)
    local oldCenterPos = {
        x = self.cityblockTracker.centerPos.x,
        y = self.cityblockTracker.centerPos.y
    }


    self.cityblockTracker.cityBlock.blockScale = 1
    TLBE.Tracker.recalculateCityBlock(self.cityblockTracker)
    lu.assertEquals(self.cityblockTracker.size, { x = 32, y = 32 },
        "A blockScale of 1 should give a size matching the block size")
    lu.assertEquals(self.cityblockTracker.centerPos, oldCenterPos, "Rescaling doesn't recenter")

    self.cityblockTracker.cityBlock.blockScale = 2
    TLBE.Tracker.recalculateCityBlock(self.cityblockTracker)
    lu.assertEquals(self.cityblockTracker.size, { x = 64, y = 64 },
        "A blockScale of 2 should give a size twice the block size")
    lu.assertEquals(self.cityblockTracker.centerPos, oldCenterPos, "Rescaling doesn't recenter")
end
