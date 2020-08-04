local Main = {}

local tileSize = 32
local boundarySize = 2
local maxZoom = 1
local minZoom = 0.031250

local function findActiveTracker(trackers)
    local previous
    for _, tracker in pairs(trackers) do
        if tracker.enabled == true then
            if tracker.moveToNextTracker ~= true then
                return previous, tracker
            end
            previous = tracker
        end
    end
    return previous, nil
end

function Main.tick()
    for _, player in pairs(game.players) do
        local playerSettings = global.playerSettings[player.index]
        if playerSettings.enabled == false then
            goto nextPlayer
        end

        for _, camera in pairs(playerSettings.cameras) do
            local previousTracker, activeTracker = findActiveTracker(camera.trackers)
            if activeTracker == nil then
                -- If there are no active trackers, skip camera as it has nothing to do
                goto nextCamera
            end

            if previousTracker ~= nil then
                -- Need a transition to activeTracker
                activeTracker.lastChange = game.tick
            end

            local realtimeCamera = activeTracker.type == "rocket"

            if
                (realtimeCamera == false and game.tick % camera.screenshotInterval ~= 0) or
                    (realtimeCamera and game.tick % camera.realtimeInterval ~= 0)
             then
                -- No time for a screenshot yet
                goto nextCamera
            end

            if activeTracker.type == "player" then
                Main.camera_follow_player(camera, player)
            else
                -- Move to tracker
                Main.camera_follow_tracker(playerSettings, player, realtimeCamera, camera, activeTracker)
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

        for _, tracker in pairs(playerSettings.trackers) do
            if tracker.moveToNextTracker then
                -- Moved to next tracker, so disable this one
                tracker.enabled = false
                tracker.moveToNextTracker = nil
            end
        end

        ::nextPlayer::
    end
end

function Main.entity_built(event)
    -- top/bottom seems to be swapped, so use this table to reduce confusion of rest of the code
    local newEntityBBox = {
        left = event.created_entity.bounding_box.left_top.x - boundarySize,
        bottom = event.created_entity.bounding_box.left_top.y - boundarySize,
        right = event.created_entity.bounding_box.right_bottom.x + boundarySize,
        top = event.created_entity.bounding_box.right_bottom.y + boundarySize
    }

    for _, playerSettings in pairs(global.playerSettings) do
        for _, tracker in pairs(playerSettings.trackers) do
            if tracker.enabled == false then
                goto nextTracker
            end

            if tracker.type == "player" then
                tracker.enabled = false
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

                tracker.lastChange = game.tick
                tracker.size = {
                    x = tracker.maxPos.x - tracker.minPos.x,
                    y = tracker.maxPos.y - tracker.minPos.y
                }

                -- Update center position
                tracker.centerPos = {
                    x = tracker.minPos.x + tracker.size.x / 2,
                    y = tracker.minPos.y + tracker.size.y / 2
                }
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
                tracker.moveToNextTracker = true
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

return Main
