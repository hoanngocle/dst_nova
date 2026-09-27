local BuffAura = require "prefabs/buffaura_common"

local assets =
{
    Asset("ANIM", "anim/upgraded_whip.zip"),
    Asset("ANIM", "anim/swap_upgraded_whip.zip"),
    Asset("ATLAS", "images/inventoryimages/upgraded_whip.xml"),
}

local DAMAGE = chasni_getitemconfig("upgraded_whip", "DMG") or 51
local RANGE = 2.5
local USES = chasni_getitemconfig("upgraded_whip", "USES") or 1000
local CHANCE = chasni_getitemconfig("upgraded_whip", "CHC") or .5
local MAX_FOLLOWER = chasni_getitemconfig("upgraded_whip", "FLW") or 10
local AOE = 10
local AURA_RADIUS = chasni_getitemconfig("upgraded_whip", "RAD") or 10
local AURA_DAMAGE = chasni_getitemconfig("upgraded_whip", "ADMG") or 2
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_upgraded_whip", "swap_whip")
    owner.AnimState:OverrideSymbol("whipline", "swap_upgraded_whip", "whipline")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    owner:AddTag("upgraded_whip")
    if inst._buff_aura == nil then
        inst._buff_aura = chasni_spawnprefab("upgraded_whip_buffaura", 0, 0, 0, 1, 1, 1, owner.entity)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    owner:RemoveTag("upgraded_whip")
    if inst._buff_aura then
        inst._buff_aura:Remove()
        inst._buff_aura = nil
    end
end

local CRACK_MUST_TAGS = { "_combat" }
local CRACK_CANT_TAGS = { "player", "epic", "shadow", "shadowminion", "shadowchesspiece", "player", "companion",  }
local function supercrack(inst)
    local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner() or nil
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, AOE, CRACK_MUST_TAGS, CRACK_CANT_TAGS)
    for i,v in ipairs(ents) do
        if not chasni_friendpet(v) then
            if v ~= owner and v.components.combat:HasTarget() then
                v.components.combat:DropTarget()
            end
            if v.components.health and not v.components.health:IsDead()
                    and v.sg
                    and not v.sg:HasStateTag("transform")
                    and not v.sg:HasStateTag("nointerrupt")
                    and not v.sg:HasStateTag("frozen")
            then
                if v.components.sleeper then
                    v.components.sleeper:WakeUp()
                end
            end

            if owner.components.leader and owner.components.leader.numfollowers < MAX_FOLLOWER and v.components.follower and v.components.follower.leader == nil then
                owner.components.leader:AddFollower(v)
            elseif v.sg and v.sg:HasState("hit") then
                v.sg:GoToState("hit")
            end
        end
    end
end

local function onattack(inst, attacker, target)
    if target and target:IsValid() then
        local chance = CHANCE

        local snap = SpawnPrefab("impact")
        local x, y, z = inst.Transform:GetWorldPosition()
        local x1, y1, z1 = target.Transform:GetWorldPosition()
        local angle = -math.atan2(z1 - z, x1 - x)
        snap.Transform:SetPosition(x1, y1, z1)
        snap.Transform:SetRotation(angle * RADIANS)

        if math.random() < chance then
            snap.Transform:SetScale(5, 5, 5)
            if target.SoundEmitter then
                target.SoundEmitter:PlaySound(inst.skin_sound_large or "dontstarve/common/whip_large")
            end
            inst:DoTaskInTime(0, supercrack)
        elseif target.SoundEmitter then
            target.SoundEmitter:PlaySound(inst.skin_sound_small or "dontstarve/common/whip_small")
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("whip")
    inst.AnimState:SetBuild("upgraded_whip")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("whip")
    inst:AddTag("weapon")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", nil, 0.9)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DAMAGE)
    inst.components.weapon:SetRange(RANGE)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "upgraded_whip"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/upgraded_whip.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

local function buff_aura_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("buffaura")
    inst.components.buffaura:AddAura("chasni_upgraded_whip_aurabuff", "chasni_upgraded_whip_aurabuff", AURA_RADIUS, function(x, y, z, radius)
        return TheSim:FindEntities(x, y, z, radius, {"_combat"}, {"player", "INLIMBO"}, function(target)
            return target.components.combat and target.components.follower and target.components.follower.leader:HasTag("upgraded_whip")
        end)
    end)
    inst:DoTaskInTime(0, function()
        inst.components.buffaura:StartAura()
    end)

    inst.persists = false

    return inst
end

local function bufffn()
    local buffdata =
    {
        ONATTACH = function(inst, target)
            if target.components.combat then
                target.components.combat.externaldamagemultipliers:SetModifier(inst, AURA_DAMAGE)
            end
        end,
        ONDETACH = function(inst, target)
            if target.components.combat then
                target.components.combat.externaldamagemultipliers:RemoveModifier(inst)
            end
        end,
    }
    local inst = BuffAura.common_fn(buffdata)

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("upgraded_whip", fn, assets),
Prefab("upgraded_whip_buffaura", buff_aura_fn),
Prefab("chasni_upgraded_whip_aurabuff", bufffn)
