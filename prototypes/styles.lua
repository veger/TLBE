-- luacheck: globals data
local default_gui = data.raw["gui-style"].default

-- constants
local camera_flow_left_side_width = 120
local camera_flow_left_side_margin = 8

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
    type = "button_style",
    parent = "list_box_item",
    padding = 0,
    horizontally_stretchable = "on"
}

default_gui["tlbe_fancy_list_box_item_selected"] = {
    type = "button_style",
    parent = "tlbe_fancy_list_box_item",
    default_graphical_set = {
        base = {position = {34, 17}, corner_size = 8}
    },
    default_font_color = {} -- button_hovered_font_color
}

-- specific styles
default_gui["tlbe_camera_dropdown"] = {
    type = "dropdown_style",
    width = camera_flow_left_side_width,
    right_margin = camera_flow_left_side_margin
}

default_gui["tlbe_tracker_list"] = {
    type = "scroll_pane_style",
    parent = "tlbe_fancy_list_box",
    width = camera_flow_left_side_width,
    right_margin = camera_flow_left_side_margin
}
