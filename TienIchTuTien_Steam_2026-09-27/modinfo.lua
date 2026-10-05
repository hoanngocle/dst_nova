name = "Tiện Ích Tu Tiên"
description = [[
Phiên bản 1.5.16 - Một cuốn bí lục tập hợp những kỹ năng hỗ trợ hữu dụng.

★ Mở rộng túi đồ lên 45 ô
★ Xếp chồng vật phẩm tối đa 120
★ Sắp xếp kho đồ bằng phím J
★ Nhấn Esc để đóng Hòm Kho Báu đang mở
★ Cải tiến Máy Phóng Băng thông minh hơn
★ Cho phép mở quà ở bất cứ đâu
★ Ngăn Grass Gekko xuất hiện
★ Mở rộng các cách trồng cây và nấm
★ Biển nhỏ tự hiện biểu tượng món đồ trong rương
★ Tooltip khi bật Thần Khí Tu Tiên: trang bị cường hóa, từng viên Đá Thuộc Tính và toàn bộ chỉ số Vạn Linh Phiên
★ Bảng Thông tin nhân vật: chỉ số hiện tại, trang bị và nguồn buff trực tiếp từ server

Yêu cầu mod: [Tu Tiên]
]]
author = "Nyx"
version = "1.5.16"
-- Read final server stats after Tu Tien, Achievement and Than Khi load.
priority = -1200
mod_dependencies = { { workshop = "workshop-3721846643" } }

api_version = 10
dst_compatible = true
client_only_mod = false
all_clients_require_mod = true
server_only_mod = false

icon_atlas = "modicon.xml"
icon = "modicon.tex"

local yes_no = {
    {description = "Bật", data = true},
    {description = "Tắt", data = false},
}
local header_options = {{description = "", data = 0}}
local backpack_categories = {
    {description = "Nguyên liệu", data = "resources"},
    {description = "Nguồn sáng", data = "light"},
    {description = "Công cụ", data = "tools"},
    {description = "Vũ khí", data = "weapons"},
    {description = "Thức ăn", data = "food"},
    {description = "Giáp", data = "armour"},
    {description = "Đồ khác", data = "misc"},
    {description = "Không ưu tiên", data = "none"},
}

configuration_options = {
    {name = "ttk_backpack_category", label = "Auto Sort: ưu tiên vào túi",
        options = backpack_categories, default = "resources"},
    {name = "happyflowers", label = "Hoa tăng tinh thần", options = yes_no, default = true},
    {name = "happybutterflys", label = "Bướm tăng tinh thần", options = yes_no, default = true},
    {name = "digreeds", label = "Đào cây sậy", options = yes_no, default = true},
    {name = "mp_plantseeds", label = "Trồng hạt thành hoa", options = yes_no, default = true},
    {name = "mp_plantnightmarefuel", label = "Trồng hoa ác", options = yes_no, default = true},
    {name = "mp_plantdurianseeds", label = "Trồng mandrake", options = yes_no, default = true},
    {name = "mp_plantpomegranateseeds", label = "Trồng bụi quả mọng", options = yes_no, default = true},
    {name = "mp_plantcutreeds", label = "Trồng cây sậy", options = yes_no, default = true},
    {name = "mp_plantlightbulb", label = "Trồng hoa phát sáng", options = yes_no, default = true},
    {name = "mp_plantbeefalowool", label = "Trồng tổ chim cao", options = yes_no, default = true},
    {name = "mp_mushroots", label = "Nấm rơi rễ", options = yes_no, default = true},
    {name = "mp_asporen", label = "Cây nấm rơi bào tử", options = yes_no, default = true},

    {name = "", label = "Biển nhỏ thông minh", options = header_options, default = 0},
    {name = "Icebox", label = "Gắn biển lên tủ lạnh", options = yes_no, default = false},
    {name = "ChangeSkin", label = "Biển đổi skin theo vật phẩm", options = yes_no, default = true},
    {name = "DragonflyChest", label = "Gắn biển lên rương vảy rồng", options = yes_no, default = false},
    {name = "SaltBox", label = "Gắn biển lên Salt Box", options = yes_no, default = false},
    {name = "BundleItems", label = "Hiện vật phẩm trong gói", options = yes_no, default = false},
    {name = "Digornot", label = "Cho phép đào biển", options = yes_no, default = false},
    {name = "OnlyPlayer", label = "Cho sinh vật khác đào biển", options = yes_no, default = false},
}
