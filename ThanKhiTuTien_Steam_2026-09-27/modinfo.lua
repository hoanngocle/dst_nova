name = "Thần Khí Tu Tiên"
description = [[
󰀘󰀘 Phiên Bản 1.0 - Thần Khí Tu Tiên 󰀘󰀘

󰀄 Trang bị, Kiếm, Ngọc thuộc tính và số sát thương

Yêu cầu mod: [Tu Tiên]
]]
author = "Nyx"
version = "1.0.1"
api_version = 10
dst_compatible = true
all_clients_require_mod = true
client_only_mod = false
server_only_mod = false
icon_atlas = "modicon.xml"
icon = "modicon.tex"
-- Load after Achievement (-1000): calculate pierce from pre-critical damage.
priority = -1100

configuration_options = {
    {
        name = "damagefx_duration",
        label = "Thời gian hiện số sát thương",
        options = {
            { description = "2 giây", data = 2 },
            { description = "2.6 giây", data = 2.6 },
            { description = "3.2 giây", data = 3.2 },
        },
        default = 2.6,
    },
    {
        name = "damagefx_spread",
        label = "Độ bay lên của số sát thương",
        options = {
            { description = "Ngắn", data = 1 },
            { description = "Vừa", data = 1.5 },
            { description = "Cao", data = 2 },
        },
        default = 1.5,
    },
}
