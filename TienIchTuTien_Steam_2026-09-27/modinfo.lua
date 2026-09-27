name = "Tiện Ích Tu Tiên"
description = [[
Phiên bản 1.3 - Một cuốn bí lục tập hợp những kỹ năng hỗ trợ hữu dụng.

★ Mở rộng túi đồ lên 45 ô
★ Xếp chồng vật phẩm tối đa 120
★ Sắp xếp kho đồ bằng phím G
★ Cải tiến Máy Phóng Băng thông minh hơn
★ Cho phép mở quà ở bất cứ đâu
★ Ngăn Grass Gekko xuất hiện
★ Mở rộng các cách trồng cây và nấm (từ More Plantables - DST)
★ Biển nhỏ tự hiện biểu tượng món đồ trong rương
★ Tooltip khi bật Thần Khí Tu Tiên: trang bị cường hóa và từng viên Đá Thuộc Tính

Yêu cầu mod: [Tu Tiên]
]]
author = "Nyx"
version = "1.3.11"

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

configuration_options = {
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
