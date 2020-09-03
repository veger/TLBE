local Main = {}

local Camera = require("scripts.camera")
local Tracker = require("scripts.tracker")
local Utils = require("scripts.utils")

function Main.tick()
    for _, player in pairs(game.players) do
        local playerSettings = global.playerSettings[player.index]
        for _, camera in pairs(playerSettings.cameras) do
            if not camera.enabled then
                goto nextCamera
            end

            local previousTracker, activeTracker = Tracker.findActiveTracker(camera.trackers)
            if activeTracker == nil then
                -- If there are no active trackers, skip camera as it has nothing to do
                goto nextCamera
            end

            if previousTracker ~= nil then
                -- Need a transition to activeTracker
                -- TODO Only if smooth camera following is enabled
                activeTracker.lastChange = game.tick
            end

            -- Check if a screenshot needs to be taken
            if activeTracker.realtimeCamera then
                if game.tick % camera.realtimeInterval ~= 0 then
                    goto nextCamera
                end
            elseif game.tick % camera.screenshotInterval ~= 0 then
                goto nextCamera
            end

            Tracker.tick(activeTracker, player)

            -- Move to tracker
            Camera.followTracker(playerSettings, player, camera, activeTracker)

            game.take_screenshot {
                by_player = player,
                surface = game.surfaces[1],
                position = camera.centerPos,
                resolution = {camera.width, camera.height},
                zoom = camera.zoom,
                path = string.format("%s/%08d-%s.png", playerSettings.saveFolder, game.tick, camera.name),
                show_entity_info = false,
                allow_in_replay = true,
                daytime = 0 -- take screenshot at full light
            }

            ::nextCamera::
        end

        -- Done moving to next trackers
        Tracker.MoveToNextTrackerFinished(playerSettings.trackers)
    end
end

function Main.entity_built(event)
    local newEntityBBox = Utils.entityBBox(event.created_entity)

    for _, playerSettings in pairs(global.playerSettings) do
        for _, tracker in pairs(playerSettings.trackers) do
            if not tracker.enabled then
                goto nextTracker
            end

            if tracker.type == "player" then
                -- TODO only when tracker has setting set
                Tracker.moveToNextTracker(tracker)
            elseif tracker.type == "base" then
                if tracker.size == nil then
                    -- Set start point of base
                    tracker.minPos = {x = newEntityBBox.left, y = newEntityBBox.bottom}
                    tracker.maxPos = {x = newEntityBBox.right, y = newEntityBBox.top}
                else
                    -- Recalculate base boundary
                    if (newEntityBBox.left < tracker.minPos.x) then
                        tracker.minPos.x = newEntityBBox.left
                    end
                    if (newEntityBBox.bottom < tracker.minPos.y) then
                        tracker.minPos.y = newEntityBBox.bottom
                    end
                    if (newEntityBBox.right > tracker.maxPos.x) then
                        tracker.maxPos.x = newEntityBBox.right
                    end
                    if (newEntityBBox.top > tracker.maxPos.y) then
                        tracker.maxPos.y = newEntityBBox.top
                    end
                end

                Tracker.updateCenterAndSize(tracker)
            end

            ::nextTracker::
        end
    end
end

function Main.rocket_launch(event)
    for _, playerSettings in pairs(global.playerSettings) do
        for _, tracker in pairs(playerSettings.trackers) do
            if tracker.type ~= "rocket" then
                goto nextTracker
            end

            if tracker.enabled == false then
                tracker.enabled = true
                tracker.centerPos = event.rocket_silo.position
                tracker.size = {x = 1, y = 1} -- don't care about size, it will fit with maxZoom

                tracker.lastChange = game.tick
            end

            ::nextTracker::
        end
    end
end

function Main.rocket_launched()
    for _, playerSettings in pairs(global.playerSettings) do
        for _, tracker in pairs(playerSettings.trackers) do
            if tracker.type ~= "rocket" then
                goto nextTracker
            end

            if tracker.enabled then
                -- recenter on next tracker from list (disable rocket tracker)
                Tracker.moveToNextTracker(tracker)
            end

            ::nextTracker::
        end
    end
end

function Main.get_base_bbox()
    local entities = game.surfaces[1].find_entities_filtered {force = "player"}

    if #entities == 0 then
        return nil
    end

    -- Find an initial bbox within the base
    local entityBBox = Utils.entityBBox(entities[1])
    local minPos = {x = entityBBox.left, y = entityBBox.bottom}
    local maxPos = {x = entityBBox.right, y = entityBBox.top}

    for _, entity in ipairs(entities) do
        if entity.type == "character" then
            -- Skip player character
            goto NextEntity
        end

        entityBBox = Utils.entityBBox(entity)

        if (entityBBox.left < minPos.x) then
            minPos.x = entityBBox.left
        end
        if (entityBBox.bottom < minPos.y) then
            minPos.y = entityBBox.bottom
        end
        if (entityBBox.right > maxPos.x) then
            maxPos.x = entityBBox.right
        end
        if (entityBBox.top > maxPos.y) then
            maxPos.y = entityBBox.top
        end

        ::NextEntity::
    end

    return {
        minPos = minPos,
        maxPos = maxPos
    }
end

return Main
