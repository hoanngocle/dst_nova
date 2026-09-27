local assets =
{
    Asset("ANIM", "anim/woodenpigstatue.zip"),
    Asset("ATLAS", "images/inventoryimages/woodenpigstatue.xml"),
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("woodenpigstatue")
    inst.AnimState:SetBuild("woodenpigstatue")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.2, 0.8)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "woodenpigstatue"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/woodenpigstatue.xml"

    inst:AddComponent("inspectable")
    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 2

    return inst
end

return Prefab("chasni_woodenpigstatue", fn, assets)
