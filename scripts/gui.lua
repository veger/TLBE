local GUI = {
    allTrackers = {"base", "player", "rocket"}
}

local ModGui = require("mod-gui")
local Tracker = require("tracker")

local ticks_per_half_second = 30

local function findActiveTracker(trackers)
    for _, tracker in pairs(trackers) do
        if tracker.enabled == true then
            return tracker
        end
    end
end

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
    if game.tick % ticks_per_half_second ~= 0 then
        return
    end

    -- TODO performance: Use some kind of event system to update the GUI for
    for _, player in pairs(game.players) do
        local playerSettings = global.playerSettings[player.index]
        if playerSettings.gui ~= nil then
            if playerSettings.gui.cameraInfo.valid then
                local camera = playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
                GUI.updateCameraInfo(playerSettings.gui.cameraInfo, camera)

                GUI.updateTrackerInfo(
                    playerSettings.gui.cameraTrackerInfo,
                    camera.trackers[playerSettings.guiPersist.selectedCameraTracker]
                )
            end

            if playerSettings.gui.cameraTrackerList.valid then
                GUI.createTrackerList(
                    playerSettings.gui.cameraTrackerList,
                    playerSettings.guiPersist.selectedCameraTracker,
                    playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
                    "camera_tracker_",
                    GUI.addCameraTrackerButtons
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
    local playerSettings = global.playerSettings[event.player_index]

    if event.element.name == "tlbe-main-icon" then
        GUI.toggleMainWindow(player)
    elseif event.element.name == "tlbe-main-window-close" then
        GUI.closeMainWindow(event)
    else
        local _, index
        _, _, index = event.element.name:find("^camera_tracker_(%d+)$")
        if index ~= nil then
            index = tonumber(index)
            playerSettings.guiPersist.selectedCameraTracker = index
            GUI.fancyListBoxSelectItem(playerSettings.gui.cameraTrackerList, index)
            GUI.updateTrackerInfo(
                playerSettings.gui.cameraTrackerInfo,
                playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers[
                    playerSettings.guiPersist.selectedCameraTracker
                ]
            )
            return
        end

        _, _, index = event.element.name:find("^tracker_(%d+)$")
        if index ~= nil then
            index = tonumber(index)
            playerSettings.guiPersist.selectedTracker = index
            GUI.fancyListBoxSelectItem(playerSettings.gui.trackerList, index)
            GUI.updateTrackerInfo(
                playerSettings.gui.trackerInfo,
                playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
            )
            return
        end

        _, _, index = event.element.name:find("^tracker_(%d+)_enable$")
        if index ~= nil then
            index = tonumber(index)
            playerSettings.trackers[index].enabled = playerSettings.trackers[index].enabled == false

            GUI.createTrackerList(
                playerSettings.gui.trackerList,
                playerSettings.guiPersist.selectedTracker,
                playerSettings.trackers,
                "tracker_",
                GUI.addTrackerButtons
            )

            GUI.createTrackerList(
                playerSettings.gui.cameraTrackerList,
                playerSettings.guiPersist.selectedCameraTracker,
                playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
                "camera_tracker_",
                GUI.addCameraTrackerButtons
            )
            return
        end
    end
end

function GUI.onSelected(event)
    -- local player = game.players[event.player_index]
    local playerSettings = global.playerSettings[event.player_index]

    if event.element.name == "tlbe-cameras-list" then
        playerSettings.guiPersist.selectedCamera = event.element.selected_index
        playerSettings.guiPersist.selectedCameraTracker = 1
        GUI.createTrackerList(
            playerSettings.gui.cameraTrackerList,
            1,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
            "camera_tracker_",
            GUI.addCameraTrackerButtons
        )
    elseif event.element.name == "tlbe-tracker-add" then
        local trackerIndex = event.element.selected_index - 1
        if trackerIndex < 1 then
            -- Ignore first item (placeholder) in the list
            return
        end

        local newTracker = Tracker.newTracker(GUI.allTrackers[trackerIndex], playerSettings.trackers)
        table.insert(playerSettings.trackers, newTracker)
        playerSettings.guiPersist.selectedTracker = #playerSettings.trackers

        GUI.createTrackerList(
            playerSettings.gui.trackerList,
            playerSettings.guiPersist.selectedTracker,
            playerSettings.trackers,
            "tracker_",
            GUI.addTrackerButtons
        )
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
    playerGUI.cameraTrackerList =
        trackerBox.add {
        type = "scroll-pane",
        name = "tlbe-tracker-list",
        horizontal_scroll_policy = "never",
        style = "tlbe_tracker_list"
    }
    GUI.createTrackerList(
        playerGUI.cameraTrackerList,
        guiPersist.selectedCameraTracker,
        cameras[guiPersist.selectedCamera].trackers,
        "camera_tracker_",
        GUI.addCameraTrackerButtons
    )

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
    local flow = parent.add {type = "flow", direction = "horizontal"}
    local trackersFlow =
        flow.add {
        type = "flow",
        direction = "vertical"
    }

    -- New tracker GUI
    trackersFlow.add {
        type = "drop-down",
        selected_index = 1,
        name = "tlbe-tracker-add",
        items = {"<new tracker>", table.unpack(GUI.allTrackers)},
        style = "tble_tracker_add_dropdown"
    }

    -- Trackers
    playerGUI.trackerList =
        trackersFlow.add {
        type = "scroll-pane",
        name = "tlbe-tracker-list",
        horizontal_scroll_policy = "never",
        style = "tlbe_tracker_list"
    }
    GUI.createTrackerList(
        playerGUI.trackerList,
        guiPersist.selectedTracker,
        trackers,
        "tracker_",
        GUI.addTrackerButtons
    )

    -- Tracker info
    playerGUI.trackerInfo = flow.add {type = "flow", direction = "vertical"}
    playerGUI.trackerInfo.add {type = "label", name = "tracker-position"}
    playerGUI.trackerInfo.add {type = "label", name = "tracker-size"}
    GUI.updateTrackerInfo(playerGUI.trackerInfo, trackers[guiPersist.selectedTracker])

    return flow
end

function GUI.createTrackerList(trackerList, selectedIndex, trackers, namePrefix, addTrackerButtons)
    trackerList.clear()

    for index, tracker in pairs(trackers) do
        local style = "tlbe_fancy_list_box_item"
        if index == selectedIndex then
            style = "tlbe_fancy_list_box_item_selected"
        end

        local trackerRow =
            trackerList.add {
            type = "frame",
            name = namePrefix .. index,
            style = style
        }

        addTrackerButtons(index, trackers, trackerRow)

        trackerRow.add {
            type = "label",
            name = namePrefix .. index,
            caption = tracker.name,
            style = "tlbe_fancy_list_box_label"
        }
    end
end

function GUI.addCameraTrackerButtons(index, trackers, trackerRow)
    local tracker = trackers[index]
    if findActiveTracker(trackers) == tracker then
        trackerRow.add {
            type = "sprite",
            sprite = "utility/play",
            style = "tlbe_fancy_list_box_image"
        }
    else
        trackerRow.add {
            type = "empty-widget",
            style = "tlbe_fancy_list_box_button_hidden"
        }
    end
end

function GUI.addTrackerButtons(index, trackers, trackerRow)
    local sprite = "utility/pause"
    local tracker = trackers[index]
    if tracker.enabled then
        sprite = "utility/play"
    end
    if tracker.userCanEnable then
        local style = "tlbe_tracker_disabled_button"
        if tracker.enabled then
            style = "tlbe_tracker_enabled_button"
        end

        trackerRow.add {
            type = "sprite-button",
            name = "tracker_" .. index .. "_enable",
            sprite = sprite,
            style = style
        }
    else
        trackerRow.add {
            type = "sprite",
            sprite = sprite,
            style = "tlbe_fancy_list_box_button_disabled"
        }
    end
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

function GUI.fancyListBoxSelectItem(fancyList, selectedIndex)
    for index, element in pairs(fancyList.children) do
        local style = "tlbe_fancy_list_box_item"
        if index == selectedIndex then
            style = "tlbe_fancy_list_box_item_selected"
        end
        element.style = style
    end
end

return GUI
