package.path = "ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;"
    .. "TienIchTuTien_Steam_2026-09-27/scripts/?.lua;" .. package.path

local Banner = require("tbc_soul_banner")
local Detail = require("ttk_item_detail")
local Hover = require("ttk_xd_hover")
local source = {max_affixes = 5,
    soul_banner_damage = Banner.Damage, soul_banner_crit = Banner.CritBonus}

local function BannerItem(level)
    return {
        prefab = "xd_wmz_zhf", components = {},
        IsValid = function() return true end,
        HasTag = function(_, tag) return tag == "tbc_upgradeable" or tag == "weapon" end,
        GetDisplayName = function() return "Vạn Linh Phiên" end,
        _tbc_detail = {value = function() return level .. ";" end},
        _tbc_strengthen_stat = {value = function()
            return "Sát thương Hồn Linh: " .. string.format("%.2f", Banner.Damage(level))
        end},
    }
end

local function Text(rows)
    local lines = {}
    for _, row in ipairs(rows) do lines[#lines + 1] = row[1] end
    return table.concat(lines, "\n")
end

local base_item = BannerItem(0)
local base = assert(Detail.Read(base_item, source))
local base_lines = Detail.Lines(base)
assert(base_lines:find("Sát thương gốc: 50", 1, true))
assert(base_lines:find("Sát thương Hồn Linh: 50.00", 1, true))
assert(base_lines:find("Cấp kế tiếp +1: 60.00", 1, true))
assert(not base_lines:find("Chưa gắn Đá Thuộc Tính", 1, true))

local live_item = BannerItem(0)
live_item.prefab = "vanhonphien"
assert(Detail.Read(live_item, source).kind == "soul_banner",
    "the item shown in game receives the banner detail")

local third = assert(Detail.Read(BannerItem(3), source))
local third_lines = Detail.Lines(third)
assert(third_lines:find("Sát thương Hồn Linh: 86.40", 1, true))
assert(third_lines:find("Cấp kế tiếp +4: 103.68", 1, true))
assert(third_lines:find("Tỷ lệ bạo kích: 10%", 1, true))
assert(third_lines:find("Sát thương bạo kích: 190.08 (+20%)", 1, true))

local item = BannerItem(16)
local detail = assert(Detail.Read(item, source))
local lines = Detail.Lines(detail)
assert(lines:find("Sát thương Hồn Linh: 924.42", 1, true))
assert(lines:find("Tỷ lệ bạo kích: 70%", 1, true))
assert(lines:find("Sát thương bạo kích: 3143.03", 1, true))
assert(lines:find("+140%", 1, true))
for _, level in ipairs({3, 5, 7, 9, 11, 13, 16}) do
    assert(lines:find("(+" .. level .. ")", 1, true), "detail lists milestone +" .. level)
end
assert(lines:find("Cường hóa tối đa +16", 1, true))
assert(not lines:find("Chưa gắn Đá Thuộc Tính", 1, true))

local augmented = Hover.Augment({str = {{"Vạn Linh Phiên"}}}, item, detail, Detail)
local hover_text = Text(augmented.str)
assert(hover_text:find("924.42", 1, true), "in-game hover shows current damage")
assert(hover_text:find("3143.03", 1, true), "in-game hover shows critical damage")
assert(hover_text:find("(+16)", 1, true), "in-game hover shows final milestone")
local appended = Hover.Augment({str = {
    {"Vạn Linh Phiên"},
    {"Trang bị" .. Detail.Lines(detail, "")},
}}, item, detail, Detail)
local appended_text = Text(appended.str)
local _, headings = appended_text:gsub("CƯỜNG HÓA", "")
assert(headings == 1, "Tu Tien detail panel must contain one strengthen section")
assert(appended_text:find("Trang bị", 1, true), "native item description remains")
print("soul_banner_detail_test: ok")
