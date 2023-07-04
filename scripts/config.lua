local Config = {}

local Camera = require("scripts.camera")
local Tracker = require("scripts.tracker")

--- @class playerSettings
--- @field cameras Camera.camera[]
--- @field trackers Tracker.tracker[]
--- @field pauseCameras boolean When true, pause all player cameras
--- @field showCameraStatus boolean When true, the Stats GUI is used to show status of each camera
--- @field saveFolder string
--- @field sequentialNames boolean
--- @field noticeMaxZoom boolean When true the warning about the max zoom is already raised
--- @field gui table Contains all (volatile) GUI elements
--- @field guiPersist persistedGUISettings Contains all persisted (between saves) GUI details

--- @class persistedGUISettings
--- @field selectedCamera integer Selected camera
--- @field selectedTracker integer Selected tracker
--- @field selectedCameraTracker integer Selected tracker of the selected camera

--- (re)loads the mod settings and initializes player settings if needed
function Config.reload(event)
    if event.player_index == nil then
        -- The reload was not caused by a player (but a script)
        return
    end

    local player = game.players[event.player_index]
    local guiSettings = settings.get_player_settings(player)

    local playerSettings = global.playerSettings[event.player_index]
    if playerSettings == nil then
        playerSettings = Config.newPlayerSettings(player)
        global.playerSettings[event.player_index] = playerSettings
    end

    ---@diagnostic disable: assign-type-mismatch
    playerSettings.saveFolder = guiSettings["tlbe-save-folder"].value
    ---@diagnostic disable: assign-type-mismatch
    playerSettings.sequentialNames = guiSettings["tlbe-sequential-names"].value
    ---@diagnostic disable: assign-type-mismatch
    playerSettings.showCameraStatus = guiSettings["tlbe-show-stats"].value
end

--- @return playerSettings
function Config.newPlayerSettings(player)
    -- Setup some default trackers
    local trackers = {
        Tracker.newTracker "player",
        Tracker.newTracker "rocket",
        Tracker.newTracker "base"
    }

    local camera = Camera.newCamera(player, {})
    camera.name = "main"
    camera.trackers = { trackers[1], trackers[2], trackers[3] }

    return {
        -- Setup a default camera and attach trackers to it
        cameras = { camera },
        trackers = trackers,
        guiPersist = {
            selectedCamera = 1,
            selectedTracker = 1,
            selectedCameraTracker = 1
        }

    }
end

return Config
