name = "Thành Tựu Tu Tiên"
author = "Nyx"
description = [[
Phiên bản 1.3.4 - Thành Tựu Tu Tiên

★ Thành tựu: hoàn thành thử thách sinh tồn, chiến đấu, chế tạo và lao động để nhận Sao.
★ Nhiệm vụ mùa: mỗi lượt có 6 nhiệm vụ và 4 rương thưởng; quà gồm Sao, EXP hoặc vật phẩm.
★ Cấp độ: tích lũy EXP từ các hoạt động, lên cấp để nhận điểm thuộc tính và 1 Sao.
★ Đặc quyền: dùng Sao mở các nâng cấp và tiện ích hỗ trợ hành trình tu tiên.
★ Linh dược: theo dõi riêng 6 bộ đếm 0/10, giữ tiến độ qua chết và hồi sinh.
★ Gió lạnh vi vu: Linh Thạch, hạt linh thảo và vật liệu Solo/Thần Khí; bỏ trinket và đồ đặc thù.

★ Khởi đầu với 10 Sao.
Yêu cầu mod: [Tu Tiên]
]]

server_filter_tags = {"chasni", "achievement"}
version = "1.3.4"
priority = -1000
mod_dependencies = { { workshop = "workshop-3721846643" } }
forumthread = ""
api_version = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = true
icon_atlas = "modicon.xml"
icon = "modicon.tex"

local function heading(label)
    return { name = "", label = label, options = { { description = "", data = 0 } }, default = 0 }
end

local function values(numbers, format)
    local result = {}
    for index = 1, #numbers do
        local value = numbers[index]
        result[#result + 1] = { description = format and format(value) or ("" .. value), data = value }
    end
    return result
end

local function option(key, label, choices, default, hover)
    return { name = key, label = label, options = choices, default = default, hover = hover }
end

local function toggle(key, label, default, hover)
    return option(key, label, {
        { description = "Bật", data = true },
        { description = "Tắt", data = false },
    }, default, hover)
end

local small_gains = { 1, 2, 3, 4, 5, 7 }
local percent_gains = { 0.0005, 0.001, 0.0025, 0.005, 0.01, 0.02 }
local function percent(value) return ("%g%%"):format(value * 100) end

configuration_options = {
    heading("Thiết lập chung"),
    toggle("SHORTCUT", "Phím tắt", true, "Bật phím tắt mở giao diện thành tựu."),
    option("REFUND", "Hoàn điểm khi đặt lại", values({ 0.75, 0.85, 0.95, 1 }, percent), 0.85,
        "Tỷ lệ điểm thuộc tính được hoàn lại khi đặt lại."),
    toggle("HPPENALTY", "Phạt Máu khi đặt lại", true, "Áp dụng hình phạt Máu có thể hồi phục khi đặt lại."),

    heading("Cấp độ và kinh nghiệm"),
    option("EXP_MULT", "Hệ số kinh nghiệm", values({ 0.25, 0.5, 0.75, 1, 1.25, 1.5, 2, 3 },
        function(value) return ("%gx"):format(value) end), 1, "Điều chỉnh lượng kinh nghiệm nhận được."),
    option("LEVELPOINTS", "Điểm thuộc tính mỗi cấp", values({ 0, 1, 2, 3, 4, 5, 10 }), 1,
        "Số điểm thuộc tính nhận được mỗi lần lên cấp. Sao nhận theo cấp luôn cố định là 1."),
    option("HEALTHGAIN", "Máu mỗi điểm", values(small_gains), 3, "Lượng Máu tối đa tăng khi dùng 1 điểm thuộc tính."),
    option("SANITYGAIN", "Tỉnh táo mỗi điểm", values(small_gains), 3, "Lượng Tỉnh táo tối đa tăng khi dùng 1 điểm thuộc tính."),
    option("HUNGERGAIN", "Độ no mỗi điểm", values(small_gains), 3, "Lượng Độ no tối đa tăng khi dùng 1 điểm thuộc tính."),
    option("SPEEDGAIN", "Tốc độ mỗi điểm", values(percent_gains, percent), 0.001,
        "Tỷ lệ tốc độ di chuyển tăng khi dùng 1 điểm thuộc tính."),
    option("ABSORBGAIN", "Giảm sát thương mỗi điểm", values(percent_gains, percent), 0.0025,
        "Tỷ lệ giảm sát thương tăng khi dùng 1 điểm thuộc tính."),
    option("MAX_ABSORBGAIN", "Giới hạn giảm sát thương", values({ 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1 }, percent), 0.5,
        "Giới hạn giảm sát thương từ điểm thuộc tính."),
    option("DAMAGEGAIN", "Sát thương mỗi điểm", values(percent_gains, percent), 0.0005,
        "Tỷ lệ sát thương tăng khi dùng 1 điểm thuộc tính."),
    toggle("FOODXP", "Kinh nghiệm khi ăn", true, "Nhận kinh nghiệm khi ăn món ăn."),
    toggle("BUILDXP", "Kinh nghiệm khi chế tạo", true, "Nhận kinh nghiệm khi chế tạo vật phẩm hoặc công trình."),
    toggle("KILLXP", "Kinh nghiệm khi tiêu diệt", true, "Nhận kinh nghiệm khi tiêu diệt sinh vật."),
    toggle("WORKXP", "Kinh nghiệm khi lao động", true, "Nhận kinh nghiệm khi chặt cây, đào và khai thác."),
    toggle("COOKXP", "Kinh nghiệm khi nấu", true, "Nhận kinh nghiệm khi nấu ăn."),
    toggle("PLANTXP", "Kinh nghiệm khi trồng", true, "Nhận kinh nghiệm khi trồng và chăm sóc cây."),
    toggle("FISHXP", "Kinh nghiệm khi câu cá", true, "Nhận kinh nghiệm khi câu cá."),
    toggle("PICKXP", "Kinh nghiệm khi thu hoạch", true, "Nhận kinh nghiệm khi hái và thu hoạch."),
    option("LEVEL_LIMIT", "Giới hạn cấp độ", {
        { description = "50", data = 50 }, { description = "100", data = 100 },
        { description = "200", data = 200 },
    }, 200, "Cấp độ tối đa của nhân vật và thú nuôi. Ở cấp 200, 100 EXP dư đổi thành 1 Linh Thạch Hạ Phẩm."),

    heading("Thành tựu"),
    option("PLAYS", "Số vòng thành tựu", values({ 0, 1, 2, 3, 999 }), 2,
        "Số lần bộ thành tựu được làm lại sau khi hoàn thành toàn bộ."),
    toggle("NOTIFICATION", "Thông báo toàn thế giới", true, "Thông báo khi người chơi hoàn thành thành tựu."),
    option("ASSISTRANGE", "Phạm vi tính hỗ trợ", {
        { description = "Toàn bản đồ", data = 0 },
        { description = "45 đơn vị", data = 45 },
        { description = "30 đơn vị", data = 30 },
        { description = "15 đơn vị", data = 15 },
    }, 30, "Khoảng cách để người chơi khác được tính hỗ trợ thành tựu."),
}
