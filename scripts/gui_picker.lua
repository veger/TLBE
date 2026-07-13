local Camera = require("scripts.camera")

--- Viewfinder box-colour picker: a small popup window for choosing a camera's
--- viewfinder colour. Kept in its own module so it does not further inflate the (large)
--- main GUI module; it only depends on Camera and is driven from scripts/gui.lua.
local Picker = {}

-- Preset colours, shown as colour chips (see below).
local boxColorPresets = require("scripts.box_color_presets")

--- @param playerSettings playerSettings
--- @return Camera.camera
local function selectedCamera(playerSettings)
    return playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
end

-- Paint a colour chip (a value=1 progressbar) with the given colour. The progressbar fill
-- is the only GUI colour that can be set at runtime, so it is how the camera-tab chip, the
-- popup preview and the presets all show a colour without any per-colour image.
--- @param swatch LuaGuiElement progressbar element styled tlbe_color_chip / tlbe_color_preview_chip
--- @param color Color
local function paintSwatch(swatch, color)
    swatch.value = 1
    swatch.style.color = color
end

-- Paint the small colour chip shown next to the eyedropper button in the camera tab.
--- @param cameraInfo LuaGuiElement the camera settings table (playerSettings.gui.cameraInfo)
--- @param color Color
function Picker.paintCameraSwatch(cameraInfo, color)
    local cell = cameraInfo ~= nil and cameraInfo.valid and cameraInfo["camera-box-color-cell"]
    local swatch = cell and cell["camera-box-color-swatch"]
    if swatch then
        paintSwatch(swatch, color)
    end
end

-- (Re)fill the popup's preview, sliders and value labels from the selected camera.
-- Safe to call whether or not the popup is open.
--- @param playerSettings playerSettings
function Picker.refreshWindow(playerSettings)
    local boxColorGUI = playerSettings.gui.boxColor
    if boxColorGUI == nil or not boxColorGUI.window.valid then
        return
    end

    local color = selectedCamera(playerSettings).boxColor or Camera.defaultBoxColor
    paintSwatch(boxColorGUI.preview, color)
    for _, component in ipairs({ "r", "g", "b" }) do
        local value = math.floor(color[component] * 255 + 0.5)
        boxColorGUI.sliders[component].slider_value = value
        boxColorGUI.values[component].caption = tostring(value)
    end
end

-- Apply a viewfinder colour (nil resets to default) to the selected camera and update
-- the map, the popup and the camera-settings swatch to match.
--- @param playerSettings playerSettings
--- @param color Color|nil
function Picker.setCameraColor(playerSettings, color)
    local camera = selectedCamera(playerSettings)
    Camera.setBoxColor(camera, color)
    Picker.refreshWindow(playerSettings)
    Picker.paintCameraSwatch(playerSettings.gui.cameraInfo, camera.boxColor or Camera.defaultBoxColor)
end

-- Open the box-colour popup for a player, or bring it to the front if it is already
-- open (e.g. hidden behind the main window). Never closes it -- that is the X button.
--- @param player LuaPlayer
--- @param playerSettings playerSettings
function Picker.openWindow(player, playerSettings)
    local existing = player.gui.screen["tlbe-box-color-window"]
    if existing ~= nil then
        existing.bring_to_front()
        return
    end

    local window = player.gui.screen.add {
        type = "frame",
        name = "tlbe-box-color-window",
        direction = "vertical"
    }

    -- Title bar (with its own close button and drag handle)
    local titleBar = window.add { type = "flow" }
    local title = titleBar.add { type = "label", caption = { "gui.box-color-title" }, style = "frame_title" }
    title.drag_target = window
    local dragger = titleBar.add { type = "empty-widget", style = "draggable_space_header" }
    dragger.style.vertically_stretchable = true
    dragger.style.horizontally_stretchable = true
    dragger.drag_target = window
    titleBar.add {
        type = "sprite-button",
        style = "frame_action_button",
        sprite = "utility/close",
        name = "tlbe-box-color-close"
    }

    local content = window.add {
        type = "frame",
        style = "inside_shallow_frame_with_padding",
        direction = "vertical"
    }

    -- RGB sliders (0-255) on the left, a larger live-preview chip on the right
    local topRow = content.add { type = "flow", direction = "horizontal" }
    topRow.style.vertical_align = "center"

    local sliderTable = topRow.add { type = "table", column_count = 3 }
    local sliders = {}
    local values = {}
    for _, component in ipairs({ "r", "g", "b" }) do
        sliderTable.add {
            type = "label",
            caption = { "gui.box-color-" .. component },
            style = "bold_label"
        }
        local slider = sliderTable.add {
            type = "slider",
            name = "tlbe-box-color-" .. component,
            minimum_value = 0,
            maximum_value = 255,
            value_step = 1,
            discrete_slider = true
        }
        slider.style.width = 160
        sliders[component] = slider
        local value = sliderTable.add { type = "label", name = "tlbe-box-color-" .. component .. "-value" }
        value.style.width = 32
        value.style.horizontal_align = "right"
        values[component] = value
    end

    local preview = topRow.add { type = "progressbar", name = "tlbe-box-color-preview", style = "tlbe_color_preview_chip" }
    preview.style.left_margin = 12

    -- Presets at the bottom, under a divider (extra top margin to breathe after sliders).
    -- Each preset is a bare colour chip (matching the camera-tab chip) inside a borderless,
    -- click-through frame so it stays clickable.
    local divider = content.add { type = "line" }
    divider.style.top_margin = 8
    content.add { type = "label", caption = { "gui.box-color-presets" }, style = "bold_label" }
    local presetTable = content.add { type = "table", column_count = #boxColorPresets }
    presetTable.style.horizontal_spacing = 4
    for index, preset in ipairs(boxColorPresets) do
        local presetFrame = presetTable.add {
            type = "frame",
            name = "tlbe-box-color-preset_" .. index,
            style = "tlbe_color_preset_frame",
            tooltip = { "tooltip.box-color-preset" }
        }
        paintSwatch(presetFrame.add {
            type = "progressbar",
            style = "tlbe_color_chip",
            ignored_by_interaction = true
        }, preset)
    end

    playerSettings.gui.boxColor = { window = window, preview = preview, sliders = sliders, values = values }

    Picker.refreshWindow(playerSettings)
    window.force_auto_center()
end

-- Destroy the popup if it is open (used when the main window closes).
--- @param player LuaPlayer
function Picker.destroyWindow(player)
    if player.gui.screen["tlbe-box-color-window"] ~= nil then
        player.gui.screen["tlbe-box-color-window"].destroy()
    end
end

-- Handle a GUI click that may target the picker (open button, popup close/reset/preset).
--- @param event EventData.on_gui_click
--- @param player LuaPlayer
--- @param playerSettings playerSettings
--- @return boolean handled True when the click was a picker element and was handled.
function Picker.onClick(event, player, playerSettings)
    local name = event.element.name
    if name == "camera-box-color" then
        Picker.openWindow(player, playerSettings)
        return true
    elseif name == "tlbe-box-color-close" then
        Picker.destroyWindow(player)
        playerSettings.gui.boxColor = nil
        return true
    end

    local _, _, index = name:find("^tlbe%-box%-color%-preset_(%d+)$")
    if index ~= nil then
        Picker.setCameraColor(playerSettings, boxColorPresets[tonumber(index)])
        return true
    end

    return false
end

--- @param event EventData.on_gui_value_changed
function Picker.onValueChanged(event)
    ---@type playerSettings
    local playerSettings = storage.playerSettings[event.player_index]
    local name = event.element.name
    if name == "tlbe-box-color-r" or name == "tlbe-box-color-g" or name == "tlbe-box-color-b" then
        local sliders = playerSettings.gui.boxColor.sliders
        Picker.setCameraColor(playerSettings, {
            r = sliders.r.slider_value / 255,
            g = sliders.g.slider_value / 255,
            b = sliders.b.slider_value / 255,
        })
    end
end

return Picker
