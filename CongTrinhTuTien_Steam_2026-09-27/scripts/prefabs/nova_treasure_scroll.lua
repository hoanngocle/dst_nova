local logic = require("nova_treasure_logic")

local assets = {
    Asset("ANIM", "anim/hh_vat_pham_ground_so_1.zip"),
    Asset("ATLAS", "images/vat_pham_inventory_so_1.xml"),
    Asset("IMAGE", "images/vat_pham_inventory_so_1.tex"),
}

local function OpenTreasure(inst, player)
    local success = logic.OpenScroll(inst, player, TheWorld, TheSim, SpawnPrefab)
    if player.components.talker ~= nil then
        player.components.talker:Say(success
            and "Đi tìm kho báu nào!"
            or "Bản đồ chưa hoàn chỉnh, mở lại xem sao.")
    end
    return success
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("hh_vat_pham_ground_so_1")
    inst.AnimState:SetBuild("hh_vat_pham_ground_so_1")
    inst.AnimState:PlayAnimation("idle_tam_bao_quyen_truc")
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", 0.3, 0.8)
    inst:AddTag("nova_treasure_scroll")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "tam_bao_quyen_truc_inventory"
    inst.components.inventoryitem.atlasname = "images/vat_pham_inventory_so_1.xml"
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    inst.OpenTreasure = OpenTreasure
    return inst
end

return Prefab("nova_treasure_scroll", fn, assets)
