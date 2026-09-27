local assets =
{
    Asset("ANIM", "anim/spider_poison.zip"),
    Asset("ATLAS", "images/inventoryimages/poison_spider.xml"),
}

local prefabs =
{
    "spider_warrior",
    "chasni_mutator_poison",
}

local function OnAttackOther(inst, data)
    if data.target then
        if data.target.components.playerpoisonable then
            data.target.components.playerpoisonable:Poison()
        end
    end
end

local function fn()
    local inst = Prefabs["spider_warrior"].fn()
    inst.AnimState:SetBuild("spider_poison")

    if not TheWorld.ismastersim then
        return inst
    end
    inst.recipe = "chasni_mutator_poison"

    inst:ListenForEvent("onhitother", OnAttackOther)
    if inst.components.lootdropper then
        inst.components.lootdropper:AddChanceLoot("chasni_poison_gland", 0.2)
    end

    if inst.components.inventoryitem then
        inst.components.inventoryitem.imagename = "poison_spider"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/poison_spider.xml"
    end

    return inst
end
return Prefab("chasni_spider_poison", fn, assets, prefabs)
