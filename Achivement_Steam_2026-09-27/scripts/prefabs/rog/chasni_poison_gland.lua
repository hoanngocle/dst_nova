local assets_gland =
{
    Asset("ANIM", "anim/venom_gland.zip"),
    Asset("ATLAS", "images/inventoryimages/venom_gland.xml"),

}

local assets_antidote =
{
    Asset("ANIM", "anim/poison_antidote.zip"),
    Asset("ATLAS", "images/inventoryimages/poison_antidote.xml"),
}

local function fn_gland()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("venom_gland")
    inst.AnimState:SetBuild("venom_gland")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("stackable")
    inst:AddComponent("tradable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "venom_gland"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/venom_gland.xml"

    inst:AddComponent("cookable")
    inst.components.cookable.product = "chasni_poison_antidote"

    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end

local function OnHealFn(inst, target)
    if target.SoundEmitter then
        target.SoundEmitter:PlaySound("webber1/creatures/spider_cannonfodder/heal_fartcloud")
    end
    if target.components.playerpoisonable then
        target.components.playerpoisonable:WearOff()
    end
end

local function fn_antidote()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("poison_antidote")
    inst.AnimState:SetBuild("poison_antidote")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("stackable")
    inst:AddComponent("tradable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "poison_antidote"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/poison_antidote.xml"

    inst:AddComponent("healer")
    inst.components.healer:SetHealthAmount(5)
    inst.components.healer.onhealfn = OnHealFn

    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("chasni_poison_gland", fn_gland, assets_gland),
Prefab("chasni_poison_antidote", fn_antidote, assets_antidote)
