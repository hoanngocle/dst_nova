local assets =
{
    Asset("ANIM", "anim/chasni_fan.zip"),
    Asset("ATLAS", "images/inventoryimages/poofan.xml")
}

local USES = chasni_getitemconfig("poofan", "USE") or 10
local function OnUse(inst, target)
    local x, y, z = target.Transform:GetWorldPosition()
    local owner = inst.components.inventoryitem:GetGrandOwner()
    local nearestdungpile = TheWorld.components.dungpileregistry and TheWorld.components.dungpileregistry:GetNearestDungpiles(x, y, z)
    if nearestdungpile then
        local targetpos = Vector3(nearestdungpile.Transform:GetWorldPosition())
        local tornado = SpawnPrefab("tornado")
        tornado:SetDuration(45)
        tornado.WINDSTAFF_CASTER = owner
        tornado.WINDSTAFF_CASTER_ISPLAYER = true
        tornado.Transform:SetPosition(x, y, z)
        tornado.components.knownlocations:RememberLocation("target", targetpos)
        tornado.components.locomotor.walkspeed = 3
        tornado.components.locomotor.runspeed = 8

        if tornado.WINDSTAFF_CASTER_ISPLAYER then
            tornado.overridepkname = tornado.WINDSTAFF_CASTER:GetDisplayName()
            tornado.overridepkpet = true
        end
    elseif owner and owner.components.talker then
        owner.components.talker:Say(GetString(inst, "POOFAN_NO_DUNGPILE"))
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("fan")
    inst.AnimState:SetBuild("chasni_fan")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:OverrideSymbol("swap_fan", "chasni_fan", "swap_fan_perd")

    inst:AddTag("fan")
    inst:AddTag("donotautopick")

    local swap_data = {sym_build = "chasni_fan", sym_name = "swap_fan_perd", bank = "fan"}
    MakeInventoryFloatable(inst, nil, nil, nil, nil, nil, swap_data)
    inst.components.floater:SetBankSwapOnFloat(true, -15, swap_data)
    inst.components.floater:SetSize("large")
    inst.components.floater:SetVerticalOffset(0.15)
    inst.components.floater:SetScale({0.55, 0.5, 0.55})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "poofan"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/poofan.xml"

    inst:AddComponent("fan")
    inst.components.fan:SetOnUseFn(OnUse)
    inst.components.fan:SetOverrideSymbol("swap_fan_perd")
 
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.FAN, 1)
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)

    MakeHauntableLaunch(inst)

    inst.fanbuild = "chasni_fan"
    inst.fansymbol = "swap_fan_perd"

    return inst
end

return Prefab("poofan", fn, assets)
