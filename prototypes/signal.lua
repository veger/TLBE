local capture_tint = { 0.9, 0.9, 0.9 }
local target_tint = { 0.1, 0.6, 0.2 }

data:extend({
    {
        type = "item-subgroup",
        name = "tlbe-virtual-signal",
        group = "signals",
        order = "z",
    },
    {
        type = "virtual-signal",
        name = "signal-capture-north-west",
        icons = {
            {
                icon = "__TLBE__/graphics/box-north-west.png",
                icon_size = 32,
                tint = capture_tint
            }
        },
        scale = 0.5,
        subgroup = "tlbe-virtual-signal",
        order = "a",
        hidden_in_factoriopedia = true
    },
    {
        type = "virtual-signal",
        name = "signal-capture-south-west",
        icons = {
            {
                icon = "__TLBE__/graphics/box-south-west.png",
                icon_size = 32,
                tint = capture_tint,
            }
        },
        scale = 0.5,
        subgroup = "tlbe-virtual-signal",
        order = "b",
        hidden_in_factoriopedia = true
    },
    {
        type = "virtual-signal",
        name = "signal-capture-south-east",
        icons = {
            {
                icon = "__TLBE__/graphics/box-south-east.png",
                icon_size = 32,
                tint = capture_tint
            }
        },
        scale = 0.5,
        tint = { 0, 1, 0 },
        subgroup = "tlbe-virtual-signal",
        order = "c",
        hidden_in_factoriopedia = true
    },
    {
        type = "virtual-signal",
        name = "signal-capture-north-east",
        icons = {
            {
                icon = "__TLBE__/graphics/box-north-east.png",
                icon_size = 32,
                tint = capture_tint,
            }
        },
        scale = 0.5,
        subgroup = "tlbe-virtual-signal",
        order = "d",
        hidden_in_factoriopedia = true
    },
    {
        type = "virtual-signal",
        name = "signal-target-north-west",
        icons = {
            {
                icon = "__TLBE__/graphics/box-north-west.png",
                icon_size = 32,
                tint = target_tint
            }
        },
        scale = 0.5,
        subgroup = "tlbe-virtual-signal",
        order = "e",
        hidden_in_factoriopedia = true
    },
    {
        type = "virtual-signal",
        name = "signal-target-south-west",
        icons = {
            {
                icon = "__TLBE__/graphics/box-south-west.png",
                icon_size = 32,
                tint = target_tint
            }
        },
        scale = 0.5,
        subgroup = "tlbe-virtual-signal",
        order = "f",
        hidden_in_factoriopedia = true
    },
    {
        type = "virtual-signal",
        name = "signal-target-south-east",
        icons = {
            {
                icon = "__TLBE__/graphics/box-south-east.png",
                icon_size = 32,
                tint = target_tint
            }
        },
        scale = 0.5,
        subgroup = "tlbe-virtual-signal",
        order = "g",
        hidden_in_factoriopedia = true
    },
    {
        type = "virtual-signal",
        name = "signal-target-north-east",
        icons = {
            {
                icon = "__TLBE__/graphics/box-north-east.png",
                icon_size = 32,
                tint = target_tint,
            }
        },
        scale = 0.5,
        subgroup = "tlbe-virtual-signal",
        order = "h",
        hidden_in_factoriopedia = true
    }
})
