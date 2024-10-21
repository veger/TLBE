data:extend(
    {
        {
            type = "custom-input",
            name = "tlbe-main-window-toggle",
            key_sequence = "CONTROL + T",
            consuming = "none"
        },
        {
            type = "custom-input",
            name = "tlbe-pause-cameras",
            key_sequence = "CONTROL + SHIFT + P",
            consuming = "none"
        },
        {
            type = "custom-input",
            name = "tlbe-take-screenshot",
            key_sequence = "PRINTSCREEN",
            consuming = "none"
        },
        {
            type = "shortcut",
            name = "tlbe-shortcut",
            toggleable = true,
            order = "a[mod]-tlbe",
            action = "lua",
            localised_name = { "shortcut.tlbe" },
            associated_control_input = "tlbe-main-window-toggle",
            icon = "__TLBE__/graphics/logo-32.png",
            icon_size = 32,
            small_icon = "__TLBE__/graphics/logo-24.png",
            small_icon_size = 24
        },
        {
            type = "shortcut",
            name = "tlbe-pause-shortcut",
            toggleable = true,
            order = "a[mod]-tlbe",
            action = "lua",
            localised_name = { "shortcut.tlbe-pause" },
            associated_control_input = "tlbe-pause-cameras",
            icon = "__TLBE__/graphics/pause-camera-32.png",
            icon_size = 32,
            small_icon = "__TLBE__/graphics/pause-camera-24.png",
            small_icon_size = 24
        },
        {
            type = "shortcut",
            name = "tlbe-screenshot-shortcut",
            toggleable = false,
            order = "a[mod]-tlbe",
            action = "lua",
            localised_name = { "shortcut.tlbe-screenshot" },
            associated_control_input = "tlbe-take-screenshot",
            icon = "__TLBE__/graphics/take-screenshot-32.png",
            icon_size = 32,
            small_icon = "__TLBE__/graphics/take-screenshot-24.png",
            small_icon_size = 24,
        }
    }
)
