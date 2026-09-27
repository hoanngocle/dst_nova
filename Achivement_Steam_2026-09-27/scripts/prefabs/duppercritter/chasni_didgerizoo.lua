local assets =
{
    Asset("ANIM", "anim/chasni_didgerizoo.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_didgerizoo.xml"),
}

local USES = chasni_getitemconfig("didgerizoo", "USES") or 50
local RANGE = chasni_getitemconfig("didgerizoo", "RNGE") or 18
local DAMAGE_MULTIPLIER = chasni_getitemconfig("didgerizoo", "DMULT") or 2
local DURATION = chasni_getitemconfig("didgerizoo", "DUR") or 120

local function HeardHorn(inst, musician, instrument)
    if inst:HasTag("chasni_critter") then
        inst:AddDebuff("chasni_didgerizoo_buff", "chasni_didgerizoo_buff")
        inst.components.combat.externaldamagemultipliers:SetModifier("didgerizoo", DAMAGE_MULTIPLIER)

        chasni_addtimedbuff(inst, "chasni_didgerizoo_buff", DURATION, function(target)
            if target.components.combat then
                target.components.combat.externaldamagemultipliers:RemoveModifier("didgerizoo")
            end
        end)
    end
end

local function PlayedHorn(inst, owner)
    if owner then
        local pos = Vector3(owner.Transform:GetWorldPosition())
        chasni_spawnprefab("chasni_snore_fx", pos.x,pos.y,pos.z)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("chasni_didgerizoo")
    inst.AnimState:SetBuild("chasni_didgerizoo")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("tool")
    inst:AddTag("horn")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", 0.25)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("instrument")
    inst.components.instrument:SetRange(RANGE)
    inst.components.instrument:SetOnHeardFn(HeardHorn)
    inst.components.instrument:SetOnPlayedFn(PlayedHorn)
    inst.components.instrument.override_sound = "chasni_critter/chasni_critter/didgerizoo/play"

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.PLAY)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.PLAY, 1)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_didgerizoo"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_didgerizoo.xml"

    MakeHauntableLaunch(inst)

    inst.hornbuild = "chasni_didgerizoo"
    inst.hornsymbol = "horn01"

    return inst
end

return Prefab("chasni_didgerizoo", fn, assets)
