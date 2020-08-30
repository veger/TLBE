local Main = {}

local Tracker = require("scripts.tracker")
local Utils = require("scripts.utils")

local tileSize = 32
local maxZoom = 1
local minZoom = 0.031250

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

            if
                (activeTracker.realtimeCamera == false and game.tick % camera.screenshotInterval ~= 0) or
                    (activeTracker.realtimeCamera and game.tick % camera.realtimeInterval ~= 0)
             then
                -- No time for a screenshot yet
                goto nextCamera
            end

            -- TODO Get rid of this exception when camera smooth follow is optional
            if activeTracker.type == "player" then
                Main.camera_follow_player(camera, player)
            else
                -- Move to tracker
                Main.camera_follow_tracker(playerSettings, player, activeTracker.realtimeCamera, camera, activeTracker)
            end

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

function Main.camera_follow_player(camera, player)
    camera.centerPos = player.position
    camera.zoom = maxZoom
end

function Main.camera_follow_tracker(playerSettings, player, realtimeCamera, camera, tracker)
    local ticksLeft = tracker.lastChange - game.tick
    if realtimeCamera then
        ticksLeft = ticksLeft + camera.zoomTicksRealtime
    else
        ticksLeft = ticksLeft + camera.zoomTicks
    end

    if ticksLeft > 0 then
        local stepsLeft
        if realtimeCamera then
            stepsLeft = ticksLeft / camera.realtimeInterval
        else
            stepsLeft = ticksLeft / camera.screenshotInterval
        end

        -- Gradually move to new center of the base
        local xDiff = tracker.centerPos.x - camera.centerPos.x
        local yDiff = tracker.centerPos.y - camera.centerPos.y
        camera.centerPos.x = camera.centerPos.x + xDiff / stepsLeft
        camera.centerPos.y = camera.centerPos.y + yDiff / stepsLeft

        -- Calculate desired zoom
        local zoomX = camera.width / (tileSize * tracker.size.x)
        local zoomY = camera.height / (tileSize * tracker.size.y)
        local zoom = math.min(zoomX, zoomY, maxZoom)

        -- Gradually zoom out with same duration as centering
        camera.zoom = camera.zoom - (camera.zoom - zoom) / stepsLeft

        if camera.zoom < minZoom then
            if playerSettings.noticeMaxZoom == nil then
                player.print({"max-zoom"}, {r = 1})
                player.print({"msg-once"})
                playerSettings.noticeMaxZoom = true
            end

            camera.zoom = minZoom
        else
            -- Max (min atually) zoom is not reached (anymore)
            playerSettings.noticeMaxZoom = nil
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
