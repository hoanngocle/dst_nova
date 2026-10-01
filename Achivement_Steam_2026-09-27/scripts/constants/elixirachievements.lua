-- Permanent potion progress belongs to Than Khi's server component.
-- These achievements only display that progress and grant ordinary achievement coins.
local potions = {
    {key="power", name="Sức Mạnh", benefit="Mỗi bình tăng vĩnh viễn 50 sát thương chuẩn; đủ 10 bình tăng thêm 50 điểm phần trăm sát thương bạo kích."},
    {key="health", name="Sinh Mệnh", benefit="Mỗi bình tăng vĩnh viễn 50 máu tối đa; đủ 10 bình miễn nhiễm nóng. Sau giới hạn, chỉ hồi 100 máu."},
    {key="mana", name="Ma Lực", benefit="Mỗi bình tăng vĩnh viễn 50 linh lực tối đa; đủ 10 bình miễn nhiễm lạnh. Sau giới hạn, chỉ hồi 100 linh lực."},
    {key="guard", name="Hộ Thể", benefit="Mỗi bình tăng vĩnh viễn 50 giảm sát thương cố định; đủ 10 bình miễn nhiễm ngủ."},
    {key="speed", name="Phong Tốc", benefit="Mỗi bình tăng vĩnh viễn 2% tốc độ di chuyển; đủ 10 bình miễn nhiễm độc."},
    {key="crit", name="Bạo Kích", benefit="Mỗi bình tăng vĩnh viễn 10 điểm phần trăm sát thương bạo kích; đủ 10 bình miễn nhiễm đóng băng."},
}

local definitions = {}
for _, potion in ipairs(potions) do
    definitions[#definitions + 1] = {
        id = "tbc_elixir_" .. potion.key,
        group = "food",
        tracker = "tbc_elixir_progress",
        params = { key = potion.key, prefab = "tbc_elixir_" .. potion.key },
        current = 10,
        coinget = 2,
        persistent = true,
        requires_tutien = false,
        strings = { vi = {
            name = potion.name,
            description = "Uống đủ 10 bình " .. potion.name .. ". " .. potion.benefit,
            info = "đã uống đủ 10 bình " .. potion.name,
        } },
    }
end
return definitions
