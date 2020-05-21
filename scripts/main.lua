if not tlbe then tlbe = {} end

tileSize = 32
boundarySize = 3

function tlbe.tick(event)
    for index, player in pairs(game.players) do
        local playerSettings = global.playerSettings[player.index];

        if playerSettings.enabled and game.tick %
            playerSettings.screenshotInterval == 0 then
            -- Calculate zoom
            local zoom;
            local zoomX = playerSettings.width /
                              (tileSize * global.factorySize.x)
            local zoomY = playerSettings.height /
                              (tileSize * global.factorySize.y)

            if (zoomX < zoomY) then
                zoom = zoomX;
            else
                zoom = zoomY
            end

            game.take_screenshot {
                by_player = player,
                surface = game.surfaces[1],
                position = {global.centerPos.x, global.centerPos.y},
                resolution = {playerSettings.width, playerSettings.height},
                zoom = zoom,
                path = playerSettings.saveFolder .. "/" ..
                    string.format("%08d", game.tick) .. ".png",
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

    -- Calculate factory size
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
