name = "Công Trình Tu Tiên"
description = [[
󰀘󰀘 Phiên Bản 1.4 - Công Trình Tu Tiên 󰀘󰀘

󰀄 Máy Tái Luyện: biến vật phẩm dư thành Linh Thạch Hạ Phẩm.

󰀏 Truyền Tống Trận: dịch chuyển giữa các cổng đã đặt.

󰀧 Tàng Bảo Đồ: lần theo dấu trên bản đồ và đào kho báu.

󰀄 Vĩnh Hằng Thần Hỏa: bốn công trình lửa cho mùa đông và mùa hè.

󰀄 Tường Siêu Cấp: tường, cửa tự động, hàng rào và dụng cụ xây nhanh.

󰀄 Thảm: 15 kiểu sàn trang trí.

Yêu cầu mod: [Tu Tiên]
]]
author = "Nyx"
version = "1.4.0"

api_version = 10
dst_compatible = true
client_only_mod = false
server_only_mod = false
all_clients_require_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = { "tu tien", "linh thach", "truyen tong", "tam bao", "than hoa" }
mod_dependencies = {
    { workshop = "workshop-3721846643" },
}
local yes_no = {
    {description = "Bật", data = true},
    {description = "Tắt", data = false},
}

configuration_options = {
    {name = "dist", label = "Khoảng cách cửa tự mở", options = {
        {description = "2", data = 2}, {description = "2,5", data = 2.5},
        {description = "3", data = 3}, {description = "4", data = 4},
        {description = "5", data = 5}, {description = "6", data = 6},
        {description = "7", data = 7}, {description = "8", data = 8},
        {description = "9", data = 9}, {description = "10", data = 10},
        {description = "15", data = 15}, {description = "20", data = 20},
    }, default = 2.5},
    {name = "rebounddmg", label = "Sát thương phản lại", options = {
        {description = "0", data = 0}, {description = "1", data = 1},
        {description = "5", data = 5}, {description = "10", data = 10},
        {description = "20", data = 20}, {description = "50", data = 50},
        {description = "100", data = 100}, {description = "200", data = 200},
        {description = "500", data = 500},
    }, default = 0},
    {name = "healthmul", label = "Máu tường", options = {
        {description = "×0,5", data = 0.5}, {description = "×1", data = 1},
        {description = "×1,5", data = 1.5}, {description = "×2", data = 2},
        {description = "×3", data = 3}, {description = "×4", data = 4},
        {description = "Vô hạn", data = -1},
    }, default = -1},
    {name = "bossres", label = "Chống boss, thiên thạch và nổ", options = yes_no, default = true},
    {name = "companion", label = "Cửa mở cho thú đồng hành", options = yes_no, default = true},
    {name = "ownership", label = "Quyền dùng và phá tường", options = {
        {description = "Mọi người", data = 0},
        {description = "Người được phép", data = 1},
    }, default = 0},
    {name = "minimapicon", label = "Hiện trên bản đồ nhỏ", options = yes_no, default = false},
    {name = "recipe", label = "Độ khó công thức", options = {
        {description = "Bình thường", data = "normal"},
        {description = "Khó", data = "hard"},
    }, default = "normal"},
    {name = "recipe_vanilla", label = "Công thức tường gốc", options = yes_no, default = false},
    {name = "recipe_wall", label = "Chế tạo tường siêu cấp", options = yes_no, default = true},
    {name = "recipe_door", label = "Chế tạo cửa siêu cấp", options = yes_no, default = true},
    {name = "recipe_fence", label = "Chế tạo hàng rào siêu cấp", options = yes_no, default = true},
    {name = "recipe_tool", label = "Chế tạo dụng cụ xây nhanh", options = yes_no, default = true},
}
