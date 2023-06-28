if global.playerSettings == nil then
    goto SkipMigration
end

local Camera = require("scripts.camera")
local GUI = require("scripts.gui")

-- Convert to new Camera transitionData
for player_index, player in pairs(game.players) do
    ---@type playerSettings
    local playerSettings = global.playerSettings[player_index]
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
                -- old transition code to determine ticksLeft
                ---@diagnostic disable-next-line: undefined-field
                local ticksLeft = activeTracker.lastChange - game.tick
                if activeTracker.realtimeCamera then
                    ---@diagnostic disable-next-line: undefined-field -- Renamed in v1.5.0
                    ticksLeft = ticksLeft + (camera.zoomTicksRealtime or 0)
                else
                    ---@diagnostic disable-next-line: undefined-field -- Renamed in v1.5.0
                    ticksLeft = ticksLeft + (camera.zoomTicks or 0)
                end

                if ticksLeft > 0 then
                    player.print({ "migration-issue-transitiondata1" }, { r = 1, g = 0.5, b = 0 })
                    player.print({ "migration-issue-transitiondata2" }, { r = 1, g = 0.5, b = 0 })
                    warned = true
                end
            end

            ---@diagnostic disable-next-line: undefined-field -- Renamed in v1.5.0
            camera.transitionPeriod = camera.zoomPeriod
            camera.changeId = 0 -- prevent initializing an 'empty' transition
            Camera.updateConfig(camera)

            camera.zoomPeriod = nil
            camera.zoomTicks = nil
            camera.zoomTicksRealtime = nil
        end
    end

    for _, tracker in pairs(playerSettings.trackers) do
        tracker.changeId = 0
        tracker.lastChange = nil
    end


    if warned == false and #playerSettings.cameras > 0 then
        player.print { "migrated-transitiondata" }
    end

    ::NextPlayer::
end

::SkipMigration::
