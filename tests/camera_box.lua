---@diagnostic disable: missing-fields, inject-field When mocking we don't care about unused/missing fields
package.path = package.path .. ";../?.lua"
local TLBE = { Camera = require("scripts.camera") }

local lu = require("luaunit")

local tileSize = 32

-- Minimal mock of Factorio's `rendering` global. Each draw_* returns a fake render
-- object recording the parameters and supporting the reads/writes refreshBox uses:
-- valid, surface.name, left_top/right_bottom/target/text and destroy().
local drawCount
local function installRenderingMock()
    drawCount = { rectangle = 0, text = 0 }
    local function newObject(params)
        local object = { valid = true, surface = { name = params.surface } }
        function object.destroy() object.valid = false end
        return object
    end
    ---@diagnostic disable-next-line: assign-type-mismatch, missing-fields
    rendering = {
        draw_rectangle = function(params)
            drawCount.rectangle = drawCount.rectangle + 1
            local object = newObject(params)
            object.color = params.color
            object.left_top = params.left_top
            object.right_bottom = params.right_bottom
            return object
        end,
        draw_text = function(params)
            drawCount.text = drawCount.text + 1
            local object = newObject(params)
            object.text = params.text
            object.target = params.target
            return object
        end,
    }
end

-- refreshBox takes a box descriptor; the real captureBox is a module local, but any
-- table with `key` and `color` works.
local captureBox = { key = "capture", color = { r = 1, g = 1, b = 1 } }

local function box(camera) return camera.renderBoxes[captureBox.key] end
local function label(camera) return camera.renderBoxes[captureBox.key .. ":name"] end

TestCameraBox = {}

function TestCameraBox:SetUp()
    installRenderingMock()
    self.player = { force = {} }
    self.camera = {
        name = "cam1",
        enabled = true,
        surfaceName = "nauvis",
        renderBoxes = {},
        centerPos = { x = 0, y = 0 },
        zoom = 1,
        width = 20 * tileSize,  -- 640px -> 20 tiles wide
        height = 15 * tileSize, -- 480px -> 15 tiles tall
    }
end

function TestCameraBox:TestBoxGeometry()
    -- 20x15 tile camera centered at origin, zoom 1 -> box spans [-10,10] x [-7.5,7.5]
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, false)

    local drawn = box(self.camera)
    lu.assertNotIsNil(drawn, "expected a rectangle to be drawn")
    lu.assertEquals(drawn.left_top, { -10, -7.5 })
    lu.assertEquals(drawn.right_bottom, { 10, 7.5 })
    lu.assertEquals(drawn.surface.name, "nauvis")
end

function TestCameraBox:TestZoomHalvesTheBox()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 0.5, false)

    -- half the zoom captures twice the area
    lu.assertEquals(box(self.camera).left_top, { -20, -15 })
    lu.assertEquals(box(self.camera).right_bottom, { 20, 15 })
end

function TestCameraBox:TestReuseMovesInsteadOfRecreating()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, false)
    local first = box(self.camera)

    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 5, y = 5 }, 1, false)

    lu.assertIs(box(self.camera), first, "expected the same render object to be reused")
    lu.assertEquals(drawCount.rectangle, 1, "expected no second draw_rectangle")
    lu.assertEquals(first.left_top, { -5, -2.5 }, "expected the box to be moved")
end

function TestCameraBox:TestSurfaceChangeRecreatesBox()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, false)
    local old = box(self.camera)

    self.camera.surfaceName = "vulcanus"
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, false)

    lu.assertIsFalse(old.valid, "the box on the previous surface should be destroyed")
    lu.assertNotIs(box(self.camera), old, "a new box should be created")
    lu.assertEquals(box(self.camera).surface.name, "vulcanus")
    lu.assertEquals(drawCount.rectangle, 2, "expected the box to be recreated on the new surface")
end

function TestCameraBox:TestRemoveDestroysBoxAndLabel()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, true)
    local removedBox, removedLabel = box(self.camera), label(self.camera)

    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, nil, nil, true)

    lu.assertIsFalse(removedBox.valid)
    lu.assertIsFalse(removedLabel.valid)
    lu.assertIsNil(box(self.camera))
    lu.assertIsNil(label(self.camera))
end

function TestCameraBox:TestLabelShownWithCameraName()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, true)

    lu.assertNotIsNil(label(self.camera), "expected a label when showName is true")
    lu.assertEquals(label(self.camera).text, "cam1")
end

function TestCameraBox:TestLabelFollowsRename()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, true)
    self.camera.name = "renamed"

    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, true)

    lu.assertEquals(label(self.camera).text, "renamed", "label should reflect the current camera name")
    lu.assertEquals(drawCount.text, 1, "label should be reused, not recreated")
end

function TestCameraBox:TestDisabledRecoloursBox()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, false)
    TLBE.Camera.updateBoxColor(self.camera) -- enabled
    local enabledColor = box(self.camera).color

    self.camera.enabled = false
    TLBE.Camera.updateBoxColor(self.camera)
    lu.assertNotEquals(box(self.camera).color, enabledColor, "disabled box should change colour")

    self.camera.enabled = true
    TLBE.Camera.updateBoxColor(self.camera)
    lu.assertEquals(box(self.camera).color, enabledColor, "re-enabled box should restore colour")
end

function TestCameraBox:TestUpdateBoxColorWithoutBoxIsSafe()
    -- a camera that never recorded has no box; recolouring must not error
    self.camera.enabled = false
    TLBE.Camera.updateBoxColor(self.camera)
    lu.assertIsNil(box(self.camera))
end

function TestCameraBox:TestRenderDisabledDrawsDimmedBox()
    self.camera.enabled = false
    TLBE.Camera.refreshCameraBox(self.player, self.camera, true, false)

    lu.assertNotIsNil(box(self.camera), "a disabled camera should get a box when rendering is on")
    local dimmed = box(self.camera).color

    self.camera.enabled = true
    TLBE.Camera.refreshCameraBox(self.player, self.camera, true, false)
    lu.assertNotEquals(box(self.camera).color, dimmed, "an enabled camera's box should not use the disabled colour")
end

function TestCameraBox:TestRenderDisabledOffRemovesBox()
    self.camera.enabled = false
    TLBE.Camera.refreshCameraBox(self.player, self.camera, true, false) -- shown
    lu.assertNotIsNil(box(self.camera))

    TLBE.Camera.refreshCameraBox(self.player, self.camera, false, false) -- setting off
    lu.assertIsNil(box(self.camera), "a disabled camera's box should be removed when rendering is off")
end

function TestCameraBox:TestEnabledCameraGetsBoxImmediately()
    -- enabling a camera should draw its box right away, even when disabled cameras are hidden
    self.camera.enabled = true
    TLBE.Camera.refreshCameraBox(self.player, self.camera, false, false)
    lu.assertNotIsNil(box(self.camera), "an enabled camera should get its box immediately")
end

function TestCameraBox:TestLabelHiddenWhenNotShown()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, true)
    local shownLabel = label(self.camera)

    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, false)

    lu.assertIsFalse(shownLabel.valid, "label should be destroyed when no longer shown")
    lu.assertIsNil(label(self.camera))
    lu.assertNotIsNil(box(self.camera), "the box itself should still be there")
    lu.assertEquals(drawCount.rectangle, 1, "the box was reused across both calls, not recreated")
end
