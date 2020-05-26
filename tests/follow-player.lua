local lu = require("luaunit")

TestFollowPlayer = {}

function TestFollowPlayer:TestSimple()
    local player = {position = {x = 12, y = 21}}
    local playerSettings = {}

    tlbe.follow_player(playerSettings, player)

    lu.assertEquals(playerSettings.centerPos, player.position)
    lu.assertNotIsNil(playerSettings.zoom)
end
