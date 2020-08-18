package.path = package.path .. ";../?.lua"
local Utils = require("scripts.utils")
local lu = require("luaunit")

function TestUniqueName()
    lu.assertTrue(Utils.uniqueName({}, "name"), "any name is unique in empty list")
    lu.assertTrue(Utils.uniqueName({{name = "other"}}, "name"), "any name is unique if list only contains 'other'")
    lu.assertFalse(Utils.uniqueName({{name = "name"}}, "name"), "any name is not unique if list also contains 'name'")
end
