if not tlbe then tlbe = {} end

tileSize = 32
boundarySize = 3
maxZoom = 1
centerSpeed = 0.25 -- tiles / interval

function tlbe.tick(event)
    for index, player in pairs(game.players) do
        local playerSettings = global.playerSettings[player.index];

        if playerSettings.enabled and game.tick %
            playerSettings.screenshotInterval == 0 then
            if global.factorySize == nil then
                tlbe.follow_player(playerSettings, player)

                if playerSettings.followPlayer == false then
                    -- Do not take screenshots yet
                    return
                end
            else
                tlbe.follow_base(playerSettings)
            end

            game.take_screenshot {
                by_player = player,
                surface = game.surfaces[1],
                position = playerSettings.centerPos,
                resolution = {playerSettings.width, playerSettings.height},
                zoom = playerSettings.zoom,
                path = string.format("%s/%08d.png", playerSettings.saveFolder,
                                     game.tick),
                show_entity_info = false,
                allow_in_replay = true,
                daytime = 0 -- take screenshot at full light
            }

            if playerSettings.noticesEnabled then
                tlbe.log({"err_generic", "tick", "Screenshot taken!"});
            end
        end
    end
end

function tlbe.entity_built(event)
    local newEntityPos = event.created_entity.position
    if global.factorySize == nil then
        -- Set start point of base
        global.minPos = {
            x = newEntityPos.x - boundarySize,
            y = newEntityPos.y - boundarySize
        }
        global.maxPos = {
            x = newEntityPos.x + boundarySize,
            y = newEntityPos.y + boundarySize
        }
    else
        -- Recalculate base boundary
        if (newEntityPos.x - boundarySize < global.minPos.x) then
            global.minPos.x = newEntityPos.x - boundarySize
        end
        if (newEntityPos.y - boundarySize < global.minPos.y) then
            global.minPos.y = newEntityPos.y - boundarySize
        end
        if (newEntityPos.x + boundarySize > global.maxPos.x) then
            global.maxPos.x = newEntityPos.x + boundarySize
        end
        if (newEntityPos.y + boundarySize > global.maxPos.y) then
            global.maxPos.y = newEntityPos.y + boundarySize
        end
    end

    global.factorySize = {
        x = global.maxPos.x - global.minPos.x,
        y = global.maxPos.y - global.minPos.y
    }

    -- Update center position
    global.centerPos = {
        x = global.minPos.x + math.floor(global.factorySize.x / 2),
        y = global.minPos.y + math.floor(global.factorySize.y / 2)
    }
end

function tlbe.follow_player(playerSettings, player)
    -- Follow player (update begin position)
    playerSettings.centerPos = player.position
    playerSettings.zoom = maxZoom
end

function tlbe.follow_base(playerSettings)
    local xDiff = math.abs(global.centerPos.x - playerSettings.centerPos.x)
    local yDiff = math.abs(global.centerPos.y - playerSettings.centerPos.y)

    if xDiff ~= 0 or yDiff ~= 0 then
        local speedRatio, ticksToZoom;
        if xDiff == 0 then
            speedRatio = 1 / yDiff
            ticksToZoom = centerSpeed
        elseif yDiff == 0 then
            speedRatio = xDiff
            ticksToZoom = centerSpeed
        elseif xDiff < yDiff then
            speedRatio = (yDiff / xDiff)
            ticksToZoom = xDiff / (centerSpeed * speedRatio)
        else
            speedRatio = (xDiff / yDiff)
            ticksToZoom = xDiff / (centerSpeed * speedRatio)
        end

        -- Gradually move to new center of the base
        if global.centerPos.x < playerSettings.centerPos.x then
            playerSettings.centerPos.x =
                math.max(playerSettings.centerPos.x - centerSpeed * speedRatio,
                         global.centerPos.x)
        else
            playerSettings.centerPos.x =
                math.min(playerSettings.centerPos.x + centerSpeed * speedRatio,
                         global.centerPos.x)
        end
        if global.centerPos.y < playerSettings.centerPos.y then
            playerSettings.centerPos.y =
                math.max(playerSettings.centerPos.y - centerSpeed / speedRatio,
                         global.centerPos.y)
        else
            playerSettings.centerPos.y =
                math.min(playerSettings.centerPos.y + centerSpeed / speedRatio,
                         global.centerPos.y)
        end

        -- Calculate desired zoom
        local zoomX = playerSettings.width / (tileSize * global.factorySize.x)
        local zoomY = playerSettings.height / (tileSize * global.factorySize.y)

        local zoom = math.min(zoomX, zoomY, maxZoom)

        -- Gradually zoom out with same duration as centering
        playerSettings.zoom =
            playerSettings.zoom - (playerSettings.zoom - zoom) / ticksToZoom
    end
end
