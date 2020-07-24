-- luacheck: globals data
data:extend(
    {
        {
            type = "sprite",
            name = "tlbe-logo",
            filename = "__TLBE__/graphics/logo.png",
            priority = "extra-high-no-scale",
            width = 64,
            height = 50,
            position = {0, 0},
            scale = 0.5,
            flags = {"gui-icon"}
        },
        {
            type = "sprite",
            name = "tlbe-logo-white",
            filename = "__TLBE__/graphics/logo.png",
            priority = "extra-high-no-scale",
            width = 64,
            height = 50,
            position = {65, 0},
            scale = 0.5,
            flags = {"gui-icon"}
        }
    }
)
