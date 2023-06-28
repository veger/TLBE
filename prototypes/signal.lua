local capture_tint = {0.9,0.9,0.9}
local target_tint = {0.1,0.6,0.2}

data:extend({
    {
        type = "item-subgroup",
        name = "virtual-signal-TLBE",
        group = "signals",
        order = "z",
    },
    {
        type = "virtual-signal",
        name = "signal-capture-north-west",
        icons = {
            {
                icon = "__TLBE__/graphics/box-north-west.png",
                tint = capture_tint
            }
        },
        icon_size = 32,
        icon_mipmaps = 1,
        subgroup = "virtual-signal-TLBE",
        order = "a"
    },
    {
        type = "virtual-signal",
        name = "signal-capture-south-west",
        icons = {
            {
                icon = "__TLBE__/graphics/box-south-west.png",
                tint = capture_tint,
            }
        },
        icon_size = 32,
        icon_mipmaps = 1,
        subgroup = "virtual-signal-TLBE",
        order = "b"
    },
    {
        type = "virtual-signal",
        name = "signal-capture-south-east",
        icons = {
            {
                icon = "__TLBE__/graphics/box-south-east.png",
                tint = capture_tint
            }
        },
        icon_size = 32,
        tint = {0, 1, 0},
        icon_mipmaps = 1,
        subgroup = "virtual-signal-TLBE",
        order = "c"
    },
    {
        type = "virtual-signal",
        name = "signal-capture-north-east",
        icons = {
            {
                icon = "__TLBE__/graphics/box-north-east.png",
                tint = capture_tint,
            }
        },
        icon_size = 32,
        icon_mipmaps = 1,
        subgroup = "virtual-signal-TLBE",
        order = "d"
    },
    {
        type = "virtual-signal",
        name = "signal-target-north-west",
        icons = {
            {
                icon = "__TLBE__/graphics/box-north-west.png",
                tint = target_tint
            }
        },
        icon_size = 32,
        icon_mipmaps = 1,
        subgroup = "virtual-signal-TLBE",
        order = "a"
    },
    {
        type = "virtual-signal",
        name = "signal-target-south-west",
        icons = {
            {
                icon = "__TLBE__/graphics/box-south-west.png",
                tint = target_tint,
            }
        },
        icon_size = 32,
        icon_mipmaps = 1,
        subgroup = "virtual-signal-TLBE",
        order = "b"
    },
    {
        type = "virtual-signal",
        name = "signal-target-south-east",
        icons = {
            {
                icon = "__TLBE__/graphics/box-south-east.png",
                tint = target_tint
            }
        },
        icon_size = 32,
        tint = {0, 1, 0},
        icon_mipmaps = 1,
        subgroup = "virtual-signal-TLBE",
        order = "c"
    },
    {
        type = "virtual-signal",
        name = "signal-target-north-east",
        icons = {
            {
                icon = "__TLBE__/graphics/box-north-east.png",
                tint = target_tint,
            }
        },
        icon_size = 32,
        icon_mipmaps = 1,
        subgroup = "virtual-signal-TLBE",
        order = "d"
    }
})