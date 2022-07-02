package.path = package.path .. ";../?.lua"
local Utils = require("scripts.utils")
local lu = require("luaunit")

function TestFindName()
    lu.assertIsNil(Utils.findName({ { name = "name" } }, "other"), "'other' is not in the list")
    lu.assertEquals(
        Utils.findName({ { name = "name" } }, "name"),
        { name = "name" },
        "'name' is in the list and should be returned"
    )
end

function TestUniqueName()
    lu.assertTrue(Utils.uniqueName({}, "name"), "any name is unique in empty list")
    lu.assertTrue(Utils.uniqueName({ { name = "other" } }, "name"), "any name is unique if list only contains 'other'")
    lu.assertFalse(Utils.uniqueName({ { name = "name" } }, "name"), "any name is not unique if list also contains 'name'")
end

function TestFilterOut()
    lu.assertEquals(Utils.filterOut({}, { "name" }), {}, "empty completeList should result in empty result")
    lu.assertEquals(
        Utils.filterOut({ "name" }, { "not name" }),
        { "name" },
        "name should be in resultList as it is not in filteredList"
    )
    lu.assertEquals(
        Utils.filterOut({ "name" }, { "name" }),
        {},
        "name not should be in resultList as it is in filteredList"
    )
end
