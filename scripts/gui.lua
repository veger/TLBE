local GUI = {}

local ModGui = require("mod-gui")

local ticks_per_half_second = 30

function GUI.init(player)
    -- Add main button if if does not exist yet
    local buttonFlow = ModGui.get_button_flow(player)
    if buttonFlow["tlbe-main-icon"] == nil then
        buttonFlow.add {
            type = "sprite-button",
            style = ModGui.button_style,
            sprite = "tlbe-logo",
            name = "tlbe-main-icon"
        }
    end
end

function GUI.tick()
    -- update once per second
    if game.tick % ticks_per_half_second ~= 0 then
        return
    end

    for _, player in pairs(game.players) do
        local playerSettings = global.playerSettings[player.index]
        if playerSettings.gui ~= nil then
            if playerSettings.gui.cameraInfo.valid then
                local cameraIndex = playerSettings.gui.cameraSelector.selected_index
                local camera = playerSettings.cameras[cameraIndex]
                GUI.updateCameraInfo(playerSettings.gui.cameraInfo, camera)

                GUI.updateTrackerInfo(
                    playerSettings.gui.cameraTrackerInfo,
                    camera.trackers[playerSettings.guiPersist.selectedCameraTracker]
                )
            end

            if playerSettings.gui.trackerInfo.valid then
                GUI.updateTrackerInfo(
                    playerSettings.gui.trackerInfo,
                    playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
                )
            end
        end
    end
end

function GUI.onClick(event)
    local player = game.players[event.player_index]

    if event.element.name == "tlbe-main-icon" then
        GUI.toggleMainWindow(player)
    elseif event.element.name == "tlbe-main-window-close" then
        GUI.closeMainWindow(event)
    end
end

function GUI.closeMainWindow(event)
    local player = game.players[event.player_index]
    if player.gui.screen["tlbe-main-window"] ~= nil then
        player.gui.screen["tlbe-main-window"].destroy()
    end
end

function GUI.toggleMainWindow(player)
    local playerSettings = global.playerSettings[player.index]
    if player.gui.screen["tlbe-main-window"] ~= nil then
        player.gui.screen["tlbe-main-window"].destroy()
        playerSettings.gui = nil
    else
        -- Create frame without caption (we have our own title_bar)
        local mainWindow = player.gui.screen.add {type = "frame", name = "tlbe-main-window", direction = "vertical"}
        playerSettings.gui = {}
        if playerSettings.guiPersist == nil then
            playerSettings.guiPersist = {
                -- initialize persisting gui configurations
                selectedCamera = 1,
                selectedCameraTracker = 1,
                selectedTracker = 1
            }
        end

        -- Add title bar
        local title_bar = mainWindow.add {type = "flow"}
        local title = title_bar.add {type = "label", caption = "TLBE Settings", style = "frame_title"}
        title.drag_target = mainWindow

        -- Add 'dragger' (filler) between title and (close) buttons
        local dragger = title_bar.add {type = "empty-widget", style = "draggable_space_header"}
        dragger.style.vertically_stretchable = true
        dragger.style.horizontally_stretchable = true
        dragger.drag_target = mainWindow

        title_bar.add {
            type = "sprite-button",
            style = "frame_action_button",
            sprite = "utility/close_white",
            name = "tlbe-main-window-close"
        }

        local tabPane = mainWindow.add {type = "tabbed-pane"}

        local cameraTab = tabPane.add {type = "tab", caption = "Camera"}
        tabPane.add_tab(
            cameraTab,
            GUI.createCameraSettings(tabPane, playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
        )

        local trackerTab = tabPane.add {type = "tab", caption = "Tracker"}
        tabPane.add_tab(
            trackerTab,
            GUI.createTrackerSettings(tabPane, playerSettings.gui, playerSettings.guiPersist, playerSettings.trackers)
        )

        mainWindow.force_auto_center()
    end
end

function GUI.createCameraSettings(parent, playerGUI, guiPersist, cameras)
    local flow = parent.add {type = "flow", direction = "vertical"}

    -- Cameras
    local cameraBox = flow.add {type = "flow"}
    local cameraItems = {}
    for index, camera in pairs(cameras) do
        cameraItems[index] = camera.name
    end

    playerGUI.cameraSelector =
        cameraBox.add {
        type = "drop-down",
        name = "tlbe-cameras-list",
        caption = "cameras",
        items = cameraItems,
        selected_index = guiPersist.selectedCamera,
        style = "tlbe_camera_dropdown"
    }

    -- Tracker info
    playerGUI.cameraInfo = cameraBox.add {type = "flow", direction = "vertical"}
    playerGUI.cameraInfo.add {type = "label", name = "camera-position"}
    playerGUI.cameraInfo.add {type = "label", name = "camera-zoom"}
    GUI.updateCameraInfo(playerGUI.cameraInfo, cameras[guiPersist.selectedCamera])

    -- Trackers
    flow.add {type = "label", caption = "Trackers"}
    local trackerBox = flow.add {type = "flow"}
    local trackerList =
        trackerBox.add {
        type = "scroll-pane",
        name = "tlbe-tracker-list",
        horizontal_scroll_policy = "never",
        style = "tlbe_tracker_list"
    }
    for index, tracker in pairs(cameras[guiPersist.selectedCamera].trackers) do
        local style = "tlbe_fancy_list_box_item"
        if index == guiPersist.selectedCameraTracker then
            style = "tlbe_fancy_list_box_item_selected"
        end
        trackerList.add {type = "button", caption = tracker.type, style = style}
    end

    -- Tracker info
    playerGUI.cameraTrackerInfo = trackerBox.add {type = "flow", direction = "vertical"}
    playerGUI.cameraTrackerInfo.add {type = "label", name = "tracker-position"}
    playerGUI.cameraTrackerInfo.add {type = "label", name = "tracker-size"}
    GUI.updateTrackerInfo(
        playerGUI.cameraTrackerInfo,
        cameras[guiPersist.selectedCamera].trackers[guiPersist.selectedCameraTracker]
    )

    return flow
end

function GUI.createTrackerSettings(parent, playerGUI, guiPersist, trackers)
    local flow = parent.add {type = "flow"}

    -- Trackers
    local trackerList =
        flow.add {
        type = "scroll-pane",
        name = "tlbe-tracker-list",
        horizontal_scroll_policy = "never",
        style = "tlbe_tracker_list"
    }
    for index, tracker in pairs(trackers) do
        local style = "tlbe_fancy_list_box_item"
        if index == guiPersist.selectedTracker then
            style = "tlbe_fancy_list_box_item_selected"
        end
        trackerList.add {type = "button", caption = tracker.type, style = style}
    end

    -- Tracker info
    playerGUI.trackerInfo = flow.add {type = "flow", direction = "vertical"}
    playerGUI.trackerInfo.add {type = "label", name = "tracker-position"}
    playerGUI.trackerInfo.add {type = "label", name = "tracker-size"}
    GUI.updateTrackerInfo(playerGUI.trackerInfo, trackers[guiPersist.selectedTracker])

    return flow
end

function GUI.updateCameraInfo(cameraInfo, camera)
    if camera.centerPos == nil then
        cameraInfo["camera-position"].caption = "position: unset"
    else
        cameraInfo["camera-position"].caption =
            string.format("position: %d, %d", camera.centerPos.x, camera.centerPos.y)
    end

    cameraInfo["camera-zoom"].caption = string.format("zoom: %2.2f", camera.zoom)
end

function GUI.updateTrackerInfo(trackerInfo, tracker)
    if tracker.centerPos == nil then
        trackerInfo["tracker-position"].caption = "position: unset"
    else
        trackerInfo["tracker-position"].caption =
            string.format("position: %d, %d", tracker.centerPos.x, tracker.centerPos.y)
    end

    if tracker.size == nil then
        trackerInfo["tracker-size"].caption = "size: unset"
    else
        trackerInfo["tracker-size"].caption = string.format("size: %d, %d", tracker.size.x, tracker.size.y)
    end
end

return GUI
