-- luacheck: globals data
local default_gui = data.raw["gui-style"].default

-- constants
local fancy_list_box_width = 188
local camera_flow_left_side_width = 200
local camera_flow_left_side_margin = 8

-- 'borrowed' from core
local function default_glow(tint_value, scale_value)
    return {
        position = {200, 128},
        corner_size = 8,
        tint = tint_value,
        scale = scale_value,
        draw_type = "outer"
    }
end

local green_button_glow_color = {135, 216, 139, 128}
local red_button_glow_color = {254, 90, 90, 128}
local default_dirt_color = {15, 7, 3, 100}
local default_dirt = default_glow(default_dirt_color, 0.5)

-- general styles
default_gui["tlbe_fancy_list_box"] = {
    type = "scroll_pane_style",
    vertical_flow_style = {
        type = "vertical_flow_style",
        parent = "vertical_flow",
        vertical_spacing = 0
    }
}

default_gui["tlbe_fancy_list_box_item"] = {
    type = "frame_style",
    parent = "dark_frame",
    padding = 0,
    width = fancy_list_box_width
}

default_gui["tlbe_fancy_list_box_item_selected"] = {
    type = "frame_style",
    parent = "tlbe_fancy_list_box_item",
    graphical_set = {
        base = {position = {34, 17}, corner_size = 8}
    }
}

default_gui["tlbe_fancy_list_box_label"] = {
    type = "label_style",
    parent = "clickable_label",
    horizontally_stretchable = "on"
}

default_gui["tlbe_fancy_list_box_button"] = {
    type = "button_style",
    width = 22,
    height = 22,
    padding = 0
}

default_gui["tlbe_fancy_list_box_button_disabled"] = {
    type = "image_style",
    width = 22,
    height = 22,
    padding = 0,
    stretch_image_to_widget_size = true,
    -- from button.disabled_graphical_set
    graphical_set = {
        base = {position = {17, 17}, corner_size = 8},
        shadow = default_dirt
    }
}

default_gui["tlbe_fancy_list_box_image"] = {
    type = "image_style",
    width = 22,
    height = 22,
    padding = 0,
    stretch_image_to_widget_size = true
}

default_gui["tlbe_fancy_list_box_button_hidden"] = {
    type = "empty_widget_style",
    width = 22,
    height = 22
}

-- specific styles
default_gui["tlbe_camera_dropdown"] = {
    type = "dropdown_style",
    width = fancy_list_box_width,
    right_margin = camera_flow_left_side_margin
}

default_gui["tlbe_tracker_list"] = {
    type = "scroll_pane_style",
    parent = "tlbe_fancy_list_box",
    width = camera_flow_left_side_width,
    right_margin = camera_flow_left_side_margin
}

default_gui["tble_tracker_add_dropdown"] = {
    type = "dropdown_style",
    width = fancy_list_box_width,
    right_margin = camera_flow_left_side_margin
}

-- Default button that glows red on hover/select
default_gui["tlbe_tracker_remove_button"] = {
    type = "button_style",
    parent = "tlbe_fancy_list_box_button",
    -- from red_button
    hovered_graphical_set = {
        base = {position = {170, 17}, corner_size = 8},
        shadow = default_dirt,
        glow = default_glow(red_button_glow_color, 0.5)
    },
    clicked_graphical_set = {
        base = {position = {187, 17}, corner_size = 8},
        shadow = default_dirt
    }
}

default_gui["tlbe_tracker_enabled_button"] = {
    type = "button_style",
    parent = "tlbe_fancy_list_box_button",
    -- from green_button
    clicked_graphical_set = {
        base = {position = {68, 17}, corner_size = 8},
        shadow = default_dirt
    },
    hovered_graphical_set = {
        base = {position = {119, 17}, corner_size = 8},
        glow = default_glow(green_button_glow_color, 0.5)
    },
    default_graphical_set = {
        base = {position = {119, 17}, corner_size = 8},
        shadow = default_dirt
    }
}

default_gui["tlbe_tracker_disabled_button"] = {
    type = "button_style",
    parent = "tlbe_fancy_list_box_button",
    -- from red_button
    default_graphical_set = {
        base = {position = {136, 17}, corner_size = 8},
        shadow = default_dirt
    },
    hovered_graphical_set = {
        base = {position = {170, 17}, corner_size = 8},
        shadow = default_dirt,
        glow = default_glow(red_button_glow_color, 0.5)
    },
    clicked_graphical_set = {
        base = {position = {187, 17}, corner_size = 8},
        shadow = default_dirt
    }
}
