local TLBE = {
    Main = require("scripts.main"),
    Camera = require("scripts.camera"),
    Config = require("scripts.config"),
    GUI = require("scripts.gui"),
    Tracker = require("scripts.tracker")
}

local function register_sensor()
    if script.active_mods["StatsGui"] and remote.call("StatsGui", "version") == 1 then
        remote.call("StatsGui", "add_sensor", "TLBE", "recording_sensor")
    end
end

--- @param index string|integer Index of player in game.players dictionary
--- @param player LuaPlayer
local function init_new_player(index, player)
    -- initialize player(s) when mod is loaded into existing game
    TLBE.Config.reload({ player_index = index })
    TLBE.GUI.initialize(player, storage.playerSettings[index])

    player.print({ "mod-loaded" }, { r = 1, g = 0.5, b = 0 })

    local playerSettings = storage.playerSettings[index]
    if not playerSettings.autoRecord then
        player.print({ "mod-loaded2" })
    end
end

local function on_init()
    storage.playerSettings = {}

    for index, player in pairs(game.players) do
        -- initialize player(s) when mod is loaded into existing game
        init_new_player(index, player)
    end

    local baseBBox = TLBE.Main.getBaseBBox(game.surfaces[1].name)
    if baseBBox ~= nil then
        -- Update base trackers of each player
        for index, _ in pairs(game.players) do
            local baseTracker = storage.playerSettings[index].trackers[3]
            baseTracker.minPos = baseBBox.minPos
            baseTracker.maxPos = baseBBox.maxPos
            TLBE.Tracker.updateCenterAndSize(baseTracker)
        end
    end

    register_sensor()
end

local function on_load()
    register_sensor()
end

-- The game configuration got changed (e.g. a mod like ourselves is added)
--- @param event ConfigurationChangedData
local function on_configuration_changed(event)
    -- Sometimes playerSettings does not seem to be present when upgrading
    -- from older versions. We can just fix this issue here.
    for index, player in pairs(game.players) do
        if storage.playerSettings[index] == nil then
            player.print({ "migration-fix-missing-player-data" })
            init_new_player(index, player)
        end
    end
end

-- A player got created (or joined the game)
--- @param event EventData.on_player_created
local function on_player_created(event)
    -- Initialize playerSettings
    TLBE.Config.reload(event)

    local player = game.players[event.player_index]
    local playerSettings = storage.playerSettings[event.player_index]
    if not playerSettings.autoRecord then
        player.print({ "mod-loaded2" }, { r = 1, g = 0.5, b = 0 })
    end

    TLBE.GUI.initialize(player, storage.playerSettings[event.player_index])
end


local function on_tick()
    TLBE.Main.tick()
    TLBE.GUI.tick()
end

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)

script.on_event(defines.events.on_gui_click, TLBE.GUI.onClick)
script.on_event(defines.events.on_gui_selection_state_changed, TLBE.GUI.onSelected)
script.on_event(defines.events.on_gui_text_changed, TLBE.GUI.onTextChanged)
script.on_event(defines.events.on_gui_checked_state_changed, TLBE.GUI.onStateChanged)
script.on_event(defines.events.on_gui_confirmed, TLBE.GUI.onGuiConfirmed)
script.on_event(defines.events.on_runtime_mod_setting_changed, TLBE.Config.reload)
script.on_event(defines.events.on_player_created, on_player_created)
script.on_event(defines.events.on_player_joined_game, on_player_created)
script.on_event(defines.events.on_pre_surface_deleted, TLBE.GUI.onSurfaceChanged)
script.on_event(defines.events.on_surface_deleted, TLBE.GUI.onSurfacesUpdated)
script.on_event(defines.events.on_surface_created, TLBE.GUI.onSurfacesUpdated)
script.on_event(defines.events.on_surface_imported, TLBE.GUI.onSurfacesUpdated)
script.on_event(defines.events.on_surface_renamed, TLBE.GUI.onSurfaceChanged)
script.on_event(defines.events.on_built_entity, TLBE.Main.entity_built,
    { { filter = "vehicle", invert = true } --[[@as LuaPlayerBuiltEntityEventFilter]] })
script.on_event(defines.events.on_rocket_launch_ordered, TLBE.Main.rocket_launch)
script.on_event(defines.events.on_rocket_launched, TLBE.Main.rocket_launched)

script.on_event("tlbe-main-window-toggle", TLBE.GUI.toggleMainWindow)
script.on_event("tlbe-pause-cameras", TLBE.GUI.togglePauseCameras)
script.on_event("tlbe-take-screenshot", TLBE.GUI.takeScreenshot)
script.on_event(defines.events.on_lua_shortcut, TLBE.GUI.onShortcut)

script.on_event(defines.events.on_tick, on_tick)


remote.add_interface("TLBE", {
    recording_sensor = TLBE.Camera.recordingSensor
})
