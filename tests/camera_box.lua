---@diagnostic disable: missing-fields, inject-field When mocking we don't care about unused/missing fields
package.path = package.path .. ";../?.lua"
local TLBE = { Camera = require("scripts.camera") }

local lu = require("luaunit")

local tileSize = 32

-- Minimal mock of Factorio's `rendering` global. Each draw_* returns a fake render object
-- recording the parameters and supporting the reads/writes refreshBox uses: valid,
-- surface.name, from/to/color/dash_length/gap_length/target/text and destroy().
local drawCount
local function installRenderingMock()
    drawCount = { line = 0, text = 0 }
    local function newObject(params)
        local object = { valid = true, surface = { name = params.surface } }
        function object.destroy() object.valid = false end
        return object
    end
    -- Wrap a line so dash_length/gap_length writes are validated the way Factorio does:
    -- it errors if gap_length > 0 while dash_length is 0, on every write and in any order.
    -- This catches bad update ordering (which a plain table would silently accept).
    local function validatedLine(raw)
        local store = { dash_length = raw.dash_length or 0, gap_length = raw.gap_length or 0 }
        local function check(dash, gap)
            if gap > 0 and dash <= 0 then
                error("dash_length must be greater than 0 if gap_length is greater than 0")
            end
        end
        check(store.dash_length, store.gap_length)
        return setmetatable({}, {
            __index = function(_, k)
                if store[k] ~= nil then return store[k] end
                return raw[k]
            end,
            __newindex = function(_, k, v)
                if k == "dash_length" then
                    check(v, store.gap_length); store.dash_length = v
                elseif k == "gap_length" then
                    check(store.dash_length, v); store.gap_length = v
                else
                    raw[k] = v
                end
            end,
        })
    end
    ---@diagnostic disable-next-line: assign-type-mismatch, missing-fields
    rendering = {
        draw_line = function(params)
            drawCount.line = drawCount.line + 1
            local object = newObject(params)
            object.color = params.color
            object.from = params.from
            object.to = params.to
            object.dash_length = params.dash_length
            object.gap_length = params.gap_length
            return validatedLine(object)
        end,
        draw_text = function(params)
            drawCount.text = drawCount.text + 1
            local object = newObject(params)
            object.color = params.color
            object.text = params.text
            object.target = params.target
            return object
        end,
    }
end

-- refreshBox takes a box descriptor; the real captureBox is a module local, but any
-- table with `key` and `color` works.
local captureBox = { key = "capture", color = { r = 1, g = 1, b = 1 } }
local sides = { "top", "right", "bottom", "left" }

local function sideLine(camera, side) return camera.renderBoxes[captureBox.key .. ":" .. side] end
-- Representative side used for existence/colour/dash checks (all four are drawn alike).
local function box(camera) return sideLine(camera, "top") end
local function label(camera) return camera.renderBoxes[captureBox.key .. ":name"] end

-- The box corners recovered from its lines: top.from is left_top, bottom.to is right_bottom.
local function corners(camera)
    local top, bottom = sideLine(camera, "top"), sideLine(camera, "bottom")
    if top == nil then return nil end
    return { left_top = top.from, right_bottom = bottom.to }
end

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

    local c = corners(self.camera)
    lu.assertNotIsNil(c, "expected the box lines to be drawn")
    lu.assertEquals(c.left_top, { -10, -7.5 })
    lu.assertEquals(c.right_bottom, { 10, 7.5 })
    lu.assertEquals(box(self.camera).surface.name, "nauvis")
end

function TestCameraBox:TestZoomHalvesTheBox()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 0.5, false)

    -- half the zoom captures twice the area
    local c = corners(self.camera)
    lu.assertEquals(c.left_top, { -20, -15 })
    lu.assertEquals(c.right_bottom, { 20, 15 })
end

function TestCameraBox:TestReuseMovesInsteadOfRecreating()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, false)
    local first = box(self.camera)

    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 5, y = 5 }, 1, false)

    lu.assertIs(box(self.camera), first, "expected the same line objects to be reused")
    lu.assertEquals(drawCount.line, 4, "expected no second set of draw_line (only 4 sides)")
    lu.assertEquals(first.from, { -5, -2.5 }, "expected the box to be moved")
end

function TestCameraBox:TestSurfaceChangeRecreatesBox()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, false)
    local old = box(self.camera)

    self.camera.surfaceName = "vulcanus"
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, false)

    lu.assertIsFalse(old.valid, "the line on the previous surface should be destroyed")
    lu.assertNotIs(box(self.camera), old, "a new line should be created")
    lu.assertEquals(box(self.camera).surface.name, "vulcanus")
    lu.assertEquals(drawCount.line, 8, "expected the box (4 lines) recreated on the new surface")
end

function TestCameraBox:TestRemoveDestroysBoxAndLabel()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, true)
    local removed = { label = label(self.camera) }
    for _, side in ipairs(sides) do removed[side] = sideLine(self.camera, side) end

    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, nil, nil, true)

    lu.assertIsFalse(removed.label.valid)
    lu.assertIsNil(label(self.camera))
    for _, side in ipairs(sides) do
        lu.assertIsFalse(removed[side].valid, side .. " line should be destroyed")
        lu.assertIsNil(sideLine(self.camera, side), side .. " line should be forgotten")
    end
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

function TestCameraBox:TestDisabledDashesBox()
    -- Toggling enable/disable repeatedly must not error (regression: mutating dash/gap on a
    -- live line crashed on the solid->dashed transition; the box is recreated instead). The
    -- validating line mock reproduces Factorio's dash/gap rule, so a bad transition throws.
    self.camera.enabled = true
    TLBE.Camera.refreshCameraBox(self.player, self.camera, false, false)
    lu.assertEquals(box(self.camera).gap_length, 0, "an enabled box is solid")

    self.camera.enabled = false
    TLBE.Camera.refreshCameraBox(self.player, self.camera, true, false)
    lu.assertIsTrue(box(self.camera).gap_length > 0, "a disabled box is dashed")

    self.camera.enabled = true
    TLBE.Camera.refreshCameraBox(self.player, self.camera, true, false)
    lu.assertEquals(box(self.camera).gap_length, 0, "a re-enabled box is solid again")
end

function TestCameraBox:TestUpdateBoxColorWithoutBoxIsSafe()
    -- a camera that never recorded has no box; restyling must not error
    self.camera.enabled = false
    TLBE.Camera.updateBoxColor(self.camera)
    lu.assertIsNil(box(self.camera))
end

function TestCameraBox:TestRenderDisabledDrawsDashedBox()
    self.camera.enabled = false
    TLBE.Camera.refreshCameraBox(self.player, self.camera, true, false)

    lu.assertNotIsNil(box(self.camera), "a disabled camera should get a box when rendering is on")
    lu.assertIsTrue(box(self.camera).gap_length > 0, "a disabled camera's box is dashed")

    self.camera.enabled = true
    TLBE.Camera.refreshCameraBox(self.player, self.camera, true, false)
    lu.assertEquals(box(self.camera).gap_length, 0, "an enabled camera's box is solid")
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

function TestCameraBox:TestCustomColorAppliedToBox()
    self.camera.boxColor = { r = 0.2, g = 0.4, b = 0.8 }
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, true)

    -- every side and the name label follow the camera's custom colour
    local objects = { label(self.camera) }
    for _, side in ipairs(sides) do table.insert(objects, sideLine(self.camera, side)) end
    for _, object in pairs(objects) do
        lu.assertEquals(object.color.r, 0.2)
        lu.assertEquals(object.color.g, 0.4)
        lu.assertEquals(object.color.b, 0.8)
    end
end

function TestCameraBox:TestSetBoxColorRecoloursAndResets()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, false)

    TLBE.Camera.setBoxColor(self.camera, { r = 1, g = 0, b = 0 })
    lu.assertEquals(self.camera.boxColor, { r = 1, g = 0, b = 0 })
    lu.assertEquals(box(self.camera).color.r, 1)

    -- nil resets to the default colour
    TLBE.Camera.setBoxColor(self.camera, nil)
    lu.assertIsNil(self.camera.boxColor)
    lu.assertEquals(box(self.camera).color.r, TLBE.Camera.defaultBoxColor.r)
end

function TestCameraBox:TestDisabledDashedRegardlessOfColour()
    -- Dashing (not colour) signals disabled, so even a black box is clearly disabled.
    self.camera.boxColor = { r = 0, g = 0, b = 0 }
    self.camera.enabled = false
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, false)

    lu.assertIsTrue(box(self.camera).gap_length > 0, "a disabled box is dashed for any colour")
    -- the colour is left untouched (still black); the dash carries the meaning
    lu.assertEquals(box(self.camera).color, { r = 0, g = 0, b = 0 })
end

function TestCameraBox:TestLabelHiddenWhenNotShown()
    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, true)
    local shownLabel = label(self.camera)

    TLBE.Camera.refreshBox(self.player, self.camera, captureBox, { x = 0, y = 0 }, 1, false)

    lu.assertIsFalse(shownLabel.valid, "label should be destroyed when no longer shown")
    lu.assertIsNil(label(self.camera))
    lu.assertNotIsNil(box(self.camera), "the box itself should still be there")
    lu.assertEquals(drawCount.line, 4, "the box lines were reused across both calls, not recreated")
end
