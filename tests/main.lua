package.path = package.path .. ";../?.lua"
local Main = require("scripts.main")
local Utils = require("scripts.utils")
local lu = require("luaunit")

TestGetBaseBBox = {}

function TestGetBaseBBox.TestNoEntities()
    -- luacheck: globals game
    game = {
        surfaces = {
            {
                find_entities_filtered = function()
                    return {}
                end
            }
        }
    }

    local bbox = Main.get_base_bbox()

    lu.assertIsNil(bbox, "expected nil with empty base")
end

---@diagnostic disable: need-check-nil
function TestGetBaseBBox.TestSingleEntity()
    -- luacheck: globals game
    game = {
        surfaces = {
            {
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

    local bbox = Main.get_base_bbox()

    lu.assertNotIsNil(bbox, "expected to have bbox filled in")
    lu.assertEquals(bbox.minPos.x, 1 - Utils.boundarySize)
    lu.assertEquals(bbox.minPos.y, 3 - Utils.boundarySize)
    lu.assertEquals(bbox.maxPos.x, 3 + Utils.boundarySize)
    lu.assertEquals(bbox.maxPos.y, 4 + Utils.boundarySize)
end

---@diagnostic disable: need-check-nil
function TestGetBaseBBox.TestMultipleEntities()
    -- luacheck: globals game
    game = {
        surfaces = {
            {
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

    local bbox = Main.get_base_bbox()

    lu.assertNotIsNil(bbox, "expected to have bbox filled in")
    lu.assertEquals(bbox.minPos.x, -1 - Utils.boundarySize)
    lu.assertEquals(bbox.minPos.y, 0 - Utils.boundarySize)
    lu.assertEquals(bbox.maxPos.x, 6 + Utils.boundarySize)
    lu.assertEquals(bbox.maxPos.y, 4 + Utils.boundarySize)
end
