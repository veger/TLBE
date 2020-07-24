local GUI = {}

local ModGui = require("mod-gui")

function GUI.init(player)
    -- Add main button if if does not exist yet
    local buttonFlow = ModGui.get_button_flow(player)
    buttonFlow["tlbe-main-icon"].destroy()
    if buttonFlow["tlbe-main-icon"] == nil then
        buttonFlow.add {
            type = "sprite-button",
            -- style = "frame_action_button",
            sprite = "utility/missing_icon",
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
        tabPane.add_tab(cameraTab, GUI.createCameraSettings(tabPane))

        local trackerTab = tabPane.add {type = "tab", caption = "Tracker"}
        tabPane.add_tab(trackerTab, GUI.createTrackerSettings(tabPane))

        mainWindow.force_auto_center()
    end
end

function GUI.createCameraSettings(parent)
    local flow = parent.add {type = "flow"}
    flow.add {type = "label", caption = "Welcome to camera settings"}

    return flow
end

function GUI.createTrackerSettings(parent)
    local flow = parent.add {type = "flow"}
    flow.add {type = "label", caption = "Welcome to tracker settings"}

    return flow
end

return GUI
