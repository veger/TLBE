data:extend(
    {
        {
            type = "bool-setting",
            name = "tlbe-enabled",
            setting_type = "runtime-per-user",
            default_value = true,
            order = "1"
        },
        {
            type = "bool-setting",
            name = "tlbe-notices-enabled",
            setting_type = "runtime-per-user",
            default_value = true,
            order = "2"
        },
        {
            type = "string-setting",
            name = "tlbe-save-folder",
            setting_type = "runtime-per-user",
            default_value = "timelapse",
            order = "3"
        },
        {
            type = "bool-setting",
            name = "tlbe-follow-player",
            setting_type = "runtime-per-user",
            default_value = true,
            order = "10"
        },
        {
            type = "double-setting",
            name = "tlbe-frame-rate",
            setting_type = "runtime-per-user",
            minimum_value = 1,
            default_value = 25.0,
            order = "30"
        },
        {
            type = "double-setting",
            name = "tlbe-speed-increase",
            setting_type = "runtime-per-user",
            minimum_value = 1,
            default_value = 10.0,
            order = "31"
        },
        {
            type = "double-setting",
            name = "tlbe-zoom-period",
            setting_type = "runtime-per-user",
            minimum_value = 1,
            default_value = 1.5,
            order = "32"
        },
        {
            type = "int-setting",
            name = "tlbe-resolution-x",
            setting_type = "runtime-per-user",
            minimum_value = 320,
            default_value = 1920,
            order = "50"
        },
        {
            type = "int-setting",
            name = "tlbe-resolution-y",
            setting_type = "runtime-per-user",
            minimum_value = 240,
            default_value = 1080,
            order = "51"
        }
    }
)
