data:extend(
    {
        {
            type = "bool-setting",
            name = "tlbe-show-stats",
            setting_type = "runtime-per-user",
            default_value = true,
            order = "1"
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
            name = "tlbe-sequential-names",
            setting_type = "runtime-per-user",
            default_value = true,
            order = "6"
        },
        {
            type = "bool-setting",
            name = "tlbe-save-name-first",
            setting_type = "runtime-per-user",
            default_value = false,
            order = "7"
        },
        {
            type = "bool-setting",
            name = "tlbe-use-interval",
            setting_type = "runtime-per-user",
            default_value = false,
            order = "9"
        },
        {
            type = "bool-setting",
            name = "tlbe-auto-record",
            setting_type = "runtime-per-user",
            default_value = false,
            order = "13"
        },
        {
            type = "bool-setting",
            name = "tlbe-seed-subfolder",
            setting_type = "runtime-per-user",
            default_value = false,
            order = "4"
        },
        {
            type = "string-setting",
            name = "tlbe-save-format",
            setting_type = "runtime-per-user",
            default_value = "png",
            allowed_values = { "png", "jpg" },
            order = "2"
        }
    }
)
