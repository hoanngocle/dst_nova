
local assets =
{
    Asset("ANIM", "anim/watchcase.zip"),
    Asset("ATLAS", "images/inventoryimages/watchcase.xml"),
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.2)

    inst.AnimState:SetBank("watchcase")
    inst.AnimState:SetBuild("watchcase")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/watchcase.xml"

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("watchcase")

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("watchcase", fn, assets)
