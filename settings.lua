data:extend(
    {
        {
            type = "string-setting",
            name = "tlbe-save-folder",
            setting_type = "runtime-per-user",
            default_value = "timelapse",
            order = "3"
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
            default_value = 60.0,
            order = "31"
        },
        {
            type = "double-setting",
            name = "tlbe-zoom-period",
            setting_type = "runtime-per-user",
            minimum_value = 1,
            default_value = 1.5,
            order = "32"
        }
    }
)
