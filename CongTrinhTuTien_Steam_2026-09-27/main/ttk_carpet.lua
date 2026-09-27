-- Carpet (workshop-2898491859) by 朋也, integrated into Công Trình Tu Tiên.
-- Keep the original turf and tile IDs so placed floors survive the merge.
GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end})

Assets = {
    Asset("ANIM", "anim/py_turf.zip"),
}

local lng = "vi"
TUNING.PY_TURFS = true
TUNING.PY_TURFS_LNG = lng

local turf_names = {
    "Thảm Lộng Lẫy",
    "Thảm Trang Nhã",
    "Thảm Rực Rỡ",
    "Thảm Sặc Sỡ",
    "Thảm Xanh Ngọc",
    "Thảm Cổ Điển",
    "Thảm Bươm Bướm",
    "Thảm Đỏ Tươi",
    "Thảm Ma Thuật",
    "Thảm Kẻ Ô",
    "Thảm Hoạt Hình",
    "Thảm Hình Vuông",
    "Thảm Gợn Sóng",
    "Thảm Mắt Quỷ",
    "Thảm Da Báo",
}

local function turf_postinitfn(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    if inst.components.inventoryitem then
        inst.components.inventoryitem.atlasname = "images/" .. inst.prefab .. ".xml"
        inst.components.inventoryitem.imagename = inst.prefab
    end
end

for i = 1, 15 do
    local prefab = "turf_py_carpet" .. tostring(i)
    local key = "TURF_PY_CARPET" .. tostring(i)
    local atlas = "images/" .. prefab .. ".xml"
    table.insert(Assets, Asset("ATLAS", atlas))
    table.insert(Assets, Asset("IMAGE", "images/" .. prefab .. ".tex"))

    AddRecipe2(
        prefab,
        {Ingredient("boards", 1), Ingredient("beefalowool", 1)},
        TECH.SCIENCE_TWO,
        {numtogive = 4, atlas = atlas, image = prefab .. ".tex"},
        {"DECOR"}
    )
    AddPrefabPostInit(prefab, turf_postinitfn)

    STRINGS.NAMES[key] = turf_names[i]
    STRINGS.RECIPE_DESC[key] = "Trang trí mái ấm"
    STRINGS.CHARACTERS.GENERIC.DESCRIBE[key] = "Đổi phong cách cho căn cứ"
end
