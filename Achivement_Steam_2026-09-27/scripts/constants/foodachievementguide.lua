local definitions = require "constants/novaachievements"
local foodrecipes = require "constants/seasonalfoodrecipes"

local by_id = {}
for _, achievement in ipairs(definitions) do
    if achievement.group == "food" and achievement.tracker == "eat_prefabs" then
        by_id[achievement.id] = achievement
    end
end

local fallback_names = {
    icecream = "Kem", hotchili = "Ớt Hầm Cay", powcake = "Bánh Bột Ngô (Powcake)",
    xd_danyao_bg = "Tịch Cốc Đan",
    xd_danyao_jq = "Tụ Khí Hoàn", xd_danyao_dt = "Đoán Thể Hoàn",
    xd_danyao_zj = "Trúc Cơ Đan", xd_danyao_xs = "Tẩy Tủy Hoàn",
    xd_danyao_hj = "Hóa Tinh Đan", xd_danyao_yz = "Vân Trung Đan",
    xd_danyao_sm = "Sơ Mạch Hoàn", xd_danyao_rl = "Dung Linh Hoàn",
    xd_danyao_jy = "Kết Anh Đan", xd_danyao_yx = "Uẩn Huyết Hoàn",
    xd_danyao_ns = "Ngưng Thần Hoàn", xd_danyao_hs = "Hóa Thần Đan",
    xd_danyao_hy = "Hồi Nguyên Hoàn", xd_danyao_hl = "Hợp Linh Hoàn",
    xd_danyao_kx = "Khấu Hư Đan",
}

local function FoodName(achievement, prefab, names)
    if prefab == "powcake" then return "Bánh Bột Ngô (Powcake)" end
    local localized = names and names[string.upper(prefab)]
    if localized and localized ~= "" then return localized end
    if prefab:match("^xd_dy_.+_1$") then
        return "Nhất Phẩm " .. achievement.strings.vi.name
    end
    return fallback_names[prefab] or achievement.strings.vi.name
end

local function Description(achievement, names)
    if achievement == nil or by_id[achievement.id] == nil then return nil end
    local prefabs = achievement.params.prefabs
    if #prefabs > 1 then
        return "Ăn " .. achievement.current .. " viên đan tu luyện trong danh sách, được trùng loại."
    end
    return "Ăn " .. FoodName(achievement, prefabs[1], names) .. " " .. achievement.current .. " lần."
end

local function CraftingRecipeTooltip(prefab, names, recipes)
    local recipe = recipes and recipes[prefab]
    if recipe == nil or type(recipe.ingredients) ~= "table" then return nil end
    local parts = {}
    for _, ingredient in ipairs(recipe.ingredients) do
        local name = names and names[string.upper(ingredient.type)] or ingredient.type
        local amount = ingredient.amount or 1
        parts[#parts + 1] = (amount > 1 and amount .. "× " or "") .. name
    end
    return #parts > 0 and "Công thức chế tạo: " .. table.concat(parts, " + ") or nil
end

local function RecipeTooltip(achievement, names, recipes)
    if achievement == nil or by_id[achievement.id] == nil then return nil end
    local prefabs = achievement.params.prefabs
    if #prefabs > 1 then
        local lines = { "Đan được tính (được trùng loại):" }
        local row = {}
        for _, prefab in ipairs(prefabs) do
            row[#row + 1] = FoodName(achievement, prefab, names)
            if #row == 3 then
                lines[#lines + 1] = table.concat(row, ", ")
                row = {}
            end
        end
        if #row > 0 then lines[#lines + 1] = table.concat(row, ", ") end
        return table.concat(lines, "\n")
    end

    local prefab = prefabs[1]
    return foodrecipes.GetTooltip(prefab, names)
        or CraftingRecipeTooltip(prefab, names, recipes)
        or "Vật phẩm cần ăn: " .. FoodName(achievement, prefab, names)
end

return { ById = function(id) return by_id[id] end, Description = Description, RecipeTooltip = RecipeTooltip }
