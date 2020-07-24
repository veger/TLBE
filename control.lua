local TLBE = {
    Main = require("scripts.main"),
    Config = require("scripts.config")
}

local function on_init()
    global.playerSettings = {}

    for index, player in pairs(game.players) do
        -- initialize player(s) when mod is loaded into existing game
        TLBE.Config.reload({player_index = index})
        player.print({"mod-loaded"}, {r = 1, g = 0.5, b = 0})
    end
end

-- A player got created (or joined the game)
local function on_player_created(event)
    -- Initialize playerSettings
    TLBE.Config.reload(event)
end

script.on_init(on_init)

script.on_event(defines.events.on_runtime_mod_setting_changed, TLBE.Config.reload)
script.on_event(defines.events.on_player_created, on_player_created)
script.on_event(defines.events.on_player_joined_game, on_player_created)
script.on_event(defines.events.on_built_entity, TLBE.Main.entity_built)
script.on_event(defines.events.on_rocket_launch_ordered, TLBE.Main.rocket_launch)
script.on_event(defines.events.on_rocket_launched, TLBE.Main.rocket_launched)

script.on_event(defines.events.on_tick, TLBE.Main.tick)
