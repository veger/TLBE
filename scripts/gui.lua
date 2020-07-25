local GUI = {}

local ModGui = require("mod-gui")

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
    else
        -- Create frame without caption (we have our own title_bar)
        local mainWindow = player.gui.screen.add {type = "frame", name = "tlbe-main-window", direction = "vertical"}

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
        tabPane.add_tab(cameraTab, GUI.createCameraSettings(tabPane, playerSettings.cameras))

        local trackerTab = tabPane.add {type = "tab", caption = "Tracker"}
        tabPane.add_tab(trackerTab, GUI.createTrackerSettings(tabPane, playerSettings.trackers))

        mainWindow.force_auto_center()
    end
end

function GUI.createCameraSettings(parent, cameras)
    local selectedCamera = 1
    local selectedTracker = 1
    local flow = parent.add {type = "flow", direction = "vertical"}

    -- Cameras
    local cameraBox = flow.add {type = "flow"}
    local cameraItems = {}
    for index, camera in pairs(cameras) do
        cameraItems[index] = camera.name
    end

    cameraBox.add {
        type = "drop-down",
        name = "tlbe-cameras-list",
        caption = "cameras",
        items = cameraItems,
        selected_index = selectedCamera,
        style = "tlbe_camera_dropdown"
    }

    -- Tracker info
    local cameraInfo = cameraBox.add {type = "flow", direction = "vertical"}
    cameraInfo.add {type = "label", caption = "position: 0, 0"}
    cameraInfo.add {type = "label", caption = "zoom: 1"}

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
    for index, tracker in pairs(cameras[selectedCamera].trackers) do
        local style = "tlbe_fancy_list_box_item"
        if index == selectedTracker then
            style = "tlbe_fancy_list_box_item_selected"
        end
        trackerList.add {type = "button", caption = tracker.type, style = style}
    end

    -- Tracker info
    local trackerInfo = trackerBox.add {type = "flow", direction = "vertical"}
    trackerInfo.add {type = "label", caption = "position: 0, 0 - 0,0"}

    return flow
end

function GUI.createTrackerSettings(parent, trackers)
    local selectedTracker = 1
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
        if index == selectedTracker then
            style = "tlbe_fancy_list_box_item_selected"
        end
        trackerList.add {type = "button", caption = tracker.type, style = style}
    end

    -- Tracker info
    local trackerInfo = flow.add {type = "flow", direction = "vertical"}
    trackerInfo.add {type = "label", caption = "position: 0, 0 - 0,0"}

    return flow
end

return GUI
