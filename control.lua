local TLBE = {
    Main = require("scripts.main"),
    Config = require("scripts.config")
}

script.on_init(
    function()
        global.playerSettings = {}
    end
)

script.on_event(
    defines.events.on_runtime_mod_setting_changed,
    function(event)
        local justEnabled = TLBE.Config.reload(event)
        if justEnabled then
            -- initialize player settings if not yet done to prevent issues later
            local player = game.players[event.player_index]
            local playerSettings = global.playerSettings[event.player_index] or {}

            TLBE.Main.follow_player(playerSettings, player)
        end
    end
)

script.on_event(defines.events.on_player_created, TLBE.Config.reload)

script.on_event(defines.events.on_built_entity, TLBE.Main.entity_built)
script.on_event(defines.events.on_rocket_launch_ordered, TLBE.Main.rocket_launch)
script.on_event(defines.events.on_rocket_launched, TLBE.Main.rocket_launched)

script.on_event(defines.events.on_tick, TLBE.Main.tick)
