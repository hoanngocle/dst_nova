local assets = {
    Asset("ANIM", "anim/goldenklauskey.zip"),
    Asset("ATLAS", "images/inventoryimages/goldenklauskey.xml"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("goldenklauskey")
    inst.AnimState:SetBuild("goldenklauskey")
    inst.AnimState:PlayAnimation("idle4")

    inst:AddTag("klaussackkey")

    MakeInventoryFloatable(inst, "med", nil, 0.88)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "goldenklauskey"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/goldenklauskey.xml"
    inst:AddComponent("klaussackkey")
    inst.components.klaussackkey:SetTrueKey(false)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("chasni_klaussackkey", fn, assets)
