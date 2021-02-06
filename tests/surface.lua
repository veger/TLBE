package.path = package.path .. ";../?.lua"
local TLBE = {
    GUI = require("scripts.gui"),
    Config = require("scripts.config")
}

local lu = require("luaunit")

TestSurfaceEvents = {}

function TestSurfaceEvents:SetUp()
    -- mock Factorio provided globals
    global = {}
    game = {
        tick = 0,
        surfaces = {{name = "nauvis"},{name = "active-surface"},{name = "inactive-surface"}},
    }

    -- mock TLBE tables
    global.playerSettings = {
        TLBE.Config.newPlayerSettings({position = {x = 0, y = 0}}),
    }

    game.players = {
        {index = 1},
    }

    -- Make camera easier to test
    self.testCamera = global.playerSettings[1].cameras[1]
    self.testCamera.surfaceName = "active-surface"
end

function TestSurfaceEvents:TestDeleteUnusedSurface()
    -- send event that inactive-surface will be deleted
    TLBE.GUI.onSurfaceChanged({surface_index = 3})

    lu.assertEquals(self.testCamera.surfaceName, "active-surface", "expected surface to be unchanged")
end

function TestSurfaceEvents:TestDeleteUsedSurface()
    local playerNotified = false
    self.testCamera.enabled = true

    game.players[1].print = function()
        playerNotified = true
    end

    -- send event that active-surface will be deleted
    TLBE.GUI.onSurfaceChanged({surface_index = 2})

    lu.assertEquals(self.testCamera.surfaceName, "nauvis", "expected surface to be changed")
    lu.assertFalse(self.testCamera.enabled, "expected for the camera to be disabled")
    lu.assertTrue(playerNotified, "expected that the player is notified about the camera change/issue")
end

function TestSurfaceEvents:TestRenameUnusedSurface()
    TLBE.GUI.onSurfaceChanged({old_name = "inactive-surface", new_name="changed-surface"})

    lu.assertEquals(self.testCamera.surfaceName, "active-surface", "expected surface to be unchanged")
end

function TestSurfaceEvents:TestRenameUsedSurface()
    TLBE.GUI.onSurfaceChanged({old_name = "active-surface", new_name="changed-surface"})

    lu.assertEquals(self.testCamera.surfaceName, "changed-surface", "expected surface to be changed")
end
