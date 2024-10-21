if storage.playerSettings == nil then
    goto SkipMigration
end

local Camera = require("scripts.camera")
local GUI = require("scripts.gui")

-- Convert to new Camera transitionData
for player_index, player in pairs(game.players) do
    ---@type playerSettings
    local playerSettings = storage.playerSettings[player_index]
    if playerSettings == nil then
        goto NextPlayer
    end

    -- Just make sure it is here
    if playerSettings.guiPersist == nil then
        playerSettings.guiPersist = {
            selectedCamera = 1,
            selectedTracker = 1,
            selectedCameraTracker = 1
        }
    end
    GUI.updateTakeScreenshotButton(player, playerSettings)

    local warned = false
    for _, camera in pairs(playerSettings.cameras) do
        local activeTracker = camera.lastKnownActiveTracker
        ---@diagnostic disable-next-line: undefined-field -- Removed in v1.5.0
        if warned == false and activeTracker ~= nil then
            ---@diagnostic disable-next-line: undefined-field
            if activeTracker.lastChange ~= nil then
                -- Check if there is a transition going on
                ---@diagnostic disable-next-line: undefined-field old transition code to determine ticksLeft
                local ticksLeft = activeTracker.lastChange - game.tick
                if activeTracker.realtimeCamera then
                    ---@diagnostic disable-next-line: undefined-field -- Renamed in v1.5.0
                    ticksLeft = ticksLeft + (camera.zoomTicksRealtime or 0)
                else
                    ---@diagnostic disable-next-line: undefined-field -- Renamed in v1.5.0
                    ticksLeft = ticksLeft + (camera.zoomTicks or 0)
                end

                if ticksLeft > 0 then
                    -- warn player about side effects
                    player.print({ "migration-issue-transitiondata1" }, { r = 1, g = 0.5, b = 0 })
                    player.print({ "migration-issue-transitiondata2" }, { r = 1, g = 0.5, b = 0 })
                    warned = true
                end
            end
        end

        if camera.zoomPeriod ~= nil then
            -- Old camera, migrate to new format

            ---@diagnostic disable-next-line: undefined-field -- Renamed in v1.5.0
            camera.transitionPeriod = camera.zoomPeriod
            camera.changeId = 0 -- prevent initializing an 'empty' transition
            camera.transitionSpeedGain = camera.speedGain
            Camera.updateConfig(camera)

            ---@diagnostic disable: inject-field Clear old fields
            camera.zoomPeriod = nil
            camera.zoomTicks = nil
            camera.zoomTicksRealtime = nil
            ---@diagnostic enable: inject-field
            camera.chartTags = {}
            camera.showGUI = false
        end
    end

    for _, tracker in pairs(playerSettings.trackers) do
        tracker.changeId = 0
        ---@diagnostic disable-next-line: inject-field
        tracker.lastChange = nil
    end


    if warned == false and #playerSettings.cameras > 0 then
        player.print { "migrated-transitiondata" }
    end

    ::NextPlayer::
end

::SkipMigration::
