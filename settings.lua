data:extend({
    {
        type = "bool-setting",
        name = "tlbe-enabled",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "1"
    }, {
        type = "bool-setting",
        name = "tlbe-notices-enabled",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "2"
    }, {
        type = "string-setting",
        name = "tlbe-save-folder",
        setting_type = "runtime-per-user",
        default_value = "timelapse",
        order = "3"
    }, {
        type = "double-setting",
        name = "tlbe-frame-rate",
        setting_type = "runtime-per-user",
        minimum_value = 1,
        default_value = 25.0,
        order = "4"
    }, {
        type = "double-setting",
        name = "tlbe-speed-increase",
        setting_type = "runtime-per-user",
        minimum_value = 1,
        default_value = 10.0,
        order = "5"
    }
})
