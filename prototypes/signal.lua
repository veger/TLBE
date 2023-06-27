data:extend({
    {
        type = "item-subgroup",
        name = "virtual-signal-TLBE",
        group = "signals",
        order = "z",
    },
    {
        type = "virtual-signal",
        name = "signal-box-north-west",
        icons = {
            {
                icon = "__TLBE__/graphics/box-north-west.png",
                tint = {1,1,1}
            }
        },
        icon_size = 32,
        icon_mipmaps = 1,
        subgroup = "virtual-signal-TLBE",
        order = "a"
    },
    {
        type = "virtual-signal",
        name = "signal-box-south-west",
        icons = {
            {
                icon = "__TLBE__/graphics/box-south-west.png",
                tint = {0, 0, 1},
            }
        },
        icon_size = 32,
        icon_mipmaps = 1,
        subgroup = "virtual-signal-TLBE",
        order = "b"
    },
    {
        type = "virtual-signal",
        name = "signal-box-south-east",
        icons = {
            {
                icon = "__TLBE__/graphics/box-south-east.png",
                tint = {1,0,0}
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
        name = "signal-box-north-east",
        icons = {
            {
                icon = "__TLBE__/graphics/box-north-east.png",
                tint = {0, 1, 0},
            }
        },
        icon_size = 32,
        icon_mipmaps = 1,
        subgroup = "virtual-signal-TLBE",
        order = "d"
    }
})