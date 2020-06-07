package.path = package.path .. ";../?.lua"
local TLBE = {Main = require("scripts.main")}

local lu = require("luaunit")

function TestSimple()
    local player = {position = {x = 12, y = 21}}
    local playerSettings = {cameras = {{}}}

    TLBE.Main.follow_player(playerSettings, player)

    lu.assertEquals(playerSettings.cameras[1].centerPos, player.position)
    lu.assertNotIsNil(playerSettings.cameras[1].zoom)
end
