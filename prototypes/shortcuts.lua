-- luacheck: globals data
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
            type = "shortcut",
            name = "tlbe-shortcut",
            toggleable = true,
            order = "a[mod]-tlbe",
            action = "lua",
            localised_name = {"shortcut.tlbe"},
            associated_control_input = "tlbe-main-window-toggle",
            icon = {
                -- tlbe-logo
                filename = "__TLBE__/graphics/logo.png",
                priority = "extra-high-no-scale",
                width = 64,
                height = 50,
                position = {0, 0},
                scale = 1,
                flags = {"icon"}
            },
            small_icon = {
                -- tlbe-logo
                filename = "__TLBE__/graphics/logo.png",
                priority = "extra-high-no-scale",
                width = 64,
                height = 50,
                position = {0, 0},
                scale = 1,
                flags = {"icon"}
            },
            disabled_small_icon = {
                -- tlbe-logo-white
                filename = "__TLBE__/graphics/logo.png",
                priority = "extra-high-no-scale",
                width = 64,
                height = 50,
                position = {65, 0},
                scale = 1,
                flags = {"icon"}
            }
        },
        {
            type = "shortcut",
            name = "tlbe-pause-shortcut",
            toggleable = true,
            order = "a[mod]-tlbe",
            action = "lua",
            localised_name = {"shortcut.tlbe-pause"},
            associated_control_input = "tlbe-pause-cameras",
            icon = {
                -- tlbe-logo
                filename = "__TLBE__/graphics/pause-camera.png",
                priority = "extra-high-no-scale",
                width = 64,
                height = 64,
                position = {0, 0},
                scale = 1,
                flags = {"icon"}
            },
            small_icon = {
                -- tlbe-logo
                filename = "__TLBE__/graphics/pause-camera.png",
                priority = "extra-high-no-scale",
                width = 64,
                height = 64,
                position = {0, 0},
                scale = 1,
                flags = {"icon"}
            },
            disabled_small_icon = {
                -- tlbe-logo-white
                filename = "__TLBE__/graphics/pause-camera.png",
                priority = "extra-high-no-scale",
                width = 64,
                height = 50,
                position = {65, 0},
                scale = 1,
                flags = {"icon"}
            }
        }
    }
)
