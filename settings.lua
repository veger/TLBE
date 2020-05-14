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
        type = "int-setting",
        name = "tlbe-screenshot-interval",
        setting_type = "runtime-per-user",
        minimum_value = 10,
        default_value = 300,
        order = "4"
    }
})
