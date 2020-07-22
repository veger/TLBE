package.path = package.path .. ";../?.lua"
local TLBE = {Main = require("scripts.main")}

local lu = require("luaunit")

function TestSimple()
    local player = {position = {x = 12, y = 21}}
    local camera = {}

    TLBE.Main.camera_follow_player(camera, player)

    lu.assertEquals(camera.centerPos, player.position)
    lu.assertNotIsNil(camera.zoom)
end
