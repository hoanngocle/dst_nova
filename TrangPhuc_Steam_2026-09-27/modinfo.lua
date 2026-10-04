name = "Trang Phục Tu Tiên"
description = "Cuộc trình diễn thời trang của Nyx.\n\nVersion: 1.0.1"
author = "Nyx"
version = "1.0.1"

server_filter_tags = { "TuTien", "Nyx", "skin"}

api_version = 10
dst_compatible = true
all_clients_require_mod = true
client_only_mod = false
server_only_mod = false

icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- Tu Tien (-10) and Nyx (-20) register their characters before skin extensions.
priority = -30
mod_dependencies = { { workshop = "workshop-3721846643" } }
