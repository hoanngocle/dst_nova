local brain = require("brains/chasni_sealbrain")

local assets =
{
    Asset("ANIM", "anim/twister_seal.zip"),
}

SetSharedLootTable("chasni_seal", {
    {"smallmeat",       1.00},
    {"chasni_seal_fur", 1.00},
    {"chasni_seal_fur", 0.10},
})

local HEALTH = chasni_getmobconfig("chasni_sealnado", "HP") or 5
local function SummonKrampus(inst, attacker)
    TheWorld:PushEvent("ms_forcenaughtiness", { player = attacker, numspawns = #AllPlayers * 10})
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1000, 1)
    inst.Transform:SetTwoFaced()
    inst.DynamicShadow:SetSize(2.5, 1.5)

    inst.AnimState:SetBank("twister")
    inst.AnimState:SetBuild("twister_build")
    inst.AnimState:PlayAnimation("seal_idle", true)

    inst:AddTag("seal")
    inst:AddTag("prey")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_seal")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 0
    inst.components.locomotor.runspeed = 0

    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(SummonKrampus)

    inst:SetStateGraph("SGCZseal")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_seal", fn, assets)
