require("scripts.main")
require("scripts.utils")
require("scripts.settings")

script.on_init(function(event)
    global.resolution = {w = 1980, h = 1080} -- your target resolution
    global.zoom = 4
    global.minPos = {x = 0, y = 0}
    global.maxPos = {x = 0, y = 0}
    global.centerPos = {x = 0, y = 0}
    global.playerSettings = {}
end)

script.on_event(defines.events.on_runtime_mod_setting_changed,
                tlbe.reload_settings)

script.on_event(defines.events.on_player_created, tlbe.reload_settings)

script.on_event(defines.events.on_built_entity, tlbe.entity_built);

script.on_event(defines.events.on_tick, tlbe.tick)

