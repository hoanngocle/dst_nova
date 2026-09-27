local BuffAura = require "prefabs/buffaura_common"

local function GetPassiveValue(data)
    return data and data.source and data.source.calculatePassiveValue and data.source:calculatePassiveValue() or nil
end

local function MakeBuff(buffdata)
    local function fn()
        local inst = BuffAura.common_fn(buffdata)

        if not TheWorld.ismastersim then
            return inst
        end

        return inst
    end

    return fn
end

--------------------------------------------------------------------------
-- Crab
--------------------------------------------------------------------------
local function apply_crab(inst, target, data)
    local modifier = GetPassiveValue(data)
    if modifier and modifier > 0 and target.components.combat then
        target.components.combat.externaldamagetakenmultipliers:RemoveModifier("chasni_critter_crab")
        target.components.combat.externaldamagetakenmultipliers:SetModifier("chasni_critter_crab", 1 - modifier / 100)
    end
end
local crab_buffdata =
{
    ONATTACH = apply_crab,
    ONEXTENDED = apply_crab,
    ONDETACH = function(inst, target)
        if target.components.combat then
            target.components.combat.externaldamagetakenmultipliers:RemoveModifier("chasni_critter_crab")
        end
    end,
}

--------------------------------------------------------------------------
-- Dog
--------------------------------------------------------------------------
local function apply_dog(inst, target, data)
    local modifier = GetPassiveValue(data)
    if modifier and modifier > 0 and target.components.combat then
        target.components.combat.externaldamagemultipliers:RemoveModifier("chasni_critter_dog")
        target.components.combat.externaldamagemultipliers:SetModifier("chasni_critter_dog", 1 - modifier / 100)
    end
end
local dog_buffdata =
{
    ONATTACH = apply_dog,
    ONEXTENDED = apply_dog,
    ONDETACH = function(inst, target)
        if target.components.combat then
            target.components.combat.externaldamagemultipliers:RemoveModifier("chasni_critter_dog")
        end
    end,
}
--------------------------------------------------------------------------
-- Pink Dog
--------------------------------------------------------------------------
local function apply_dogpink(inst, target, data)
    local modifier = GetPassiveValue(data)
    if modifier and modifier > 0 and target.components.combat then
        target.components.combat.externaldamagetakenmultipliers:RemoveModifier("chasni_critter_dog_pink")
        target.components.combat.externaldamagetakenmultipliers:SetModifier("chasni_critter_dog_pink", 1 + modifier / 100)
    end
end
local dog_pink_buffdata =
{
    ONATTACH = apply_dogpink,
    ONEXTENDED = apply_dogpink,
    ONDETACH = function(inst, target)
        if target.components.combat then
            target.components.combat.externaldamagetakenmultipliers:RemoveModifier("chasni_critter_dog_pink")
        end
    end,
}
--------------------------------------------------------------------------
-- Fish Burn
--------------------------------------------------------------------------
local function apply_fishburn(inst, target, data)
    local modifier = GetPassiveValue(data)
    if modifier and modifier > 0 and target.components.health then
        target.components.health.externalfiredamagemultipliers:RemoveModifier("chasni_critter_fish_burn")
        target.components.health.externalfiredamagemultipliers:SetModifier("chasni_critter_fish_burn", 1 + modifier / 100)
    end
end
local fish_burn_buffdata =
{
    ONATTACH = apply_fishburn,
    ONEXTENDED = apply_fishburn,
    ONDETACH = function(inst, target)
        if target.components.health then
            target.components.health.externalfiredamagemultipliers:RemoveModifier("chasni_critter_fish_burn")
        end
    end,
}
--------------------------------------------------------------------------
-- Fish Wet
--------------------------------------------------------------------------
local function apply_fishwet(inst, target, data)
    local wetmult = GetPassiveValue(data)
    if wetmult and wetmult > 0 then
        inst.wetmult = wetmult / 100
    end
end
local fish_wet_buffdata =
{
    ONATTACH = apply_fishwet,
    ONEXTENDED = apply_fishwet,
    ONDETACH = function(inst, target)
        inst.wetmult = nil
    end,
}
--------------------------------------------------------------------------
-- Light (off and on)
--------------------------------------------------------------------------
local function apply_light(inst, target, data)
    local luck = GetPassiveValue(data)
    if luck and luck > 0 then
        inst.luck = luck
    end
end
local light_buffdata =
{
    ONATTACH = apply_light,
    ONEXTENDED = apply_light,
    ONDETACH = function(inst, target)
        inst.luck = nil
    end,
}
--------------------------------------------------------------------------
-- Mamo
--------------------------------------------------------------------------
local function apply_mamo(inst, target, data)
    local chance = GetPassiveValue(data)
    if chance and chance > 0 then
        inst.chance = chance
    end
end
local mamo_buffdata =
{
    ONATTACH = apply_mamo,
    ONEXTENDED = apply_mamo,
    ONDETACH = function(inst, target)
        inst.chance = nil
    end,
}
--------------------------------------------------------------------------
-- Puff Health
--------------------------------------------------------------------------
local function apply_puffhealth(inst, target, data)
    local chance = GetPassiveValue(data)
    if chance and chance > 0 then
        inst.chance = chance
    end
end
local puffhealth_buffdata =
{
    ONATTACH = apply_puffhealth,
    ONEXTENDED = apply_puffhealth,
    ONDETACH = function(inst, target)
        inst.chance = nil
    end,
}
--------------------------------------------------------------------------
-- Puff Hunger
--------------------------------------------------------------------------
local function apply_puffhunger(inst, target, data)
    local modifier = GetPassiveValue(data)
    if modifier and modifier > 0 and target.components.hunger then
        target.components.hunger.burnratemodifiers:RemoveModifier("chasni_critter_puff_hunger")
        target.components.hunger.burnratemodifiers:SetModifier("chasni_critter_puff_hunger", 1 - modifier / 100)
    end
end
local puff_hunger_buffdata =
{
    ONATTACH = apply_puffhunger,
    ONEXTENDED = apply_puffhunger,
    ONDETACH = function(inst, target)
        if target.components.hunger then
            target.components.hunger.burnratemodifiers:RemoveModifier("chasni_critter_puff_hunger")
        end
    end,
}
--------------------------------------------------------------------------
-- Raptor
--------------------------------------------------------------------------
local function apply_raptor(inst, target, data)
    local critdamage = GetPassiveValue(data)
    if critdamage and critdamage > 0 then
        inst.critdamage = critdamage
    end
end
local raptor_buffdata =
{
    ONATTACH = apply_raptor,
    ONEXTENDED = apply_raptor,
    ONDETACH = function(inst, target)
        inst.critdamage = nil
    end,
}
--------------------------------------------------------------------------
-- Seal
--------------------------------------------------------------------------
local function OnDoDodge(target)
    local buff = target.components.debuffable ~= nil and target.components.debuffable:GetDebuff("chasni_critter_seal_aura_buff") or nil
    if buff and buff.dodgedamage then
        local x, y, z = target.Transform:GetWorldPosition()
        chasni_spawnprefab("chasni_diseasefx1", x,y,z)
        chasni_spawnprefab("whitefx_ring", x, y, z, 0.5,0.5,0.5)
        chasni_doaoedamage(x, y, z, 5, nil, nil, target, buff.dodgedamage, nil, true, "chasni_diseasefx2")
    end
end
local function apply_seal(inst, target, data)
    local damage = GetPassiveValue(data)
    if damage and damage > 0 then
        inst.dodgedamage = damage
        target:RemoveEventCallback("chasni_dododge", OnDoDodge)
        target:ListenForEvent("chasni_dododge", OnDoDodge)
    end
end
local seal_buffdata =
{
    ONATTACH = apply_seal,
    ONEXTENDED = apply_seal,
    ONDETACH = function(inst, target)
        target:RemoveEventCallback("chasni_dododge", OnDoDodge)
    end,
}
--------------------------------------------------------------------------
-- Slug Star
--------------------------------------------------------------------------
local function apply_slugstar(inst, target, data)
    local chance = GetPassiveValue(data)
    if chance and chance > 0 then
        inst.chance = chance
    end
end
local slugstar_buffdata =
{
    ONATTACH = apply_slugstar,
    ONEXTENDED = apply_slugstar,
    ONDETACH = function(inst, target)
        inst.chance = nil
    end,
}
--------------------------------------------------------------------------
-- Slug XP
--------------------------------------------------------------------------
local function apply_slugxp(inst, target, data)
    local mult = GetPassiveValue(data)
    if mult and mult > 0 then
        inst.mult = mult
    end
end
local slugxp_buffdata =
{
    ONATTACH = apply_slugxp,
    ONEXTENDED = apply_slugxp,
    ONDETACH = function(inst, target)
        inst.mult = nil
    end,
}
--------------------------------------------------------------------------
-- Wool
--------------------------------------------------------------------------
local function apply_wool(inst, target, data)
    local modifier = GetPassiveValue(data)
    if modifier and modifier > 0 and target.components.planardefense then
        target.components.planardefense:RemoveBonus(target, "chasni_critter_wool")
        target.components.planardefense:AddBonus(target, modifier, "chasni_critter_wool")
    end
end
local wool_buffdata =
{
    ONATTACH = apply_wool,
    ONEXTENDED = apply_wool,
    ONDETACH = function(inst, target)
        if target.components.planardefense then
            target.components.planardefense:RemoveBonus(target, "chasni_critter_wool")
        end
    end,
}
--------------------------------------------------------------------------
-- Worm
--------------------------------------------------------------------------
local function apply_worm(inst, target, data)
    local modifier = GetPassiveValue(data)
    if modifier and modifier > 0 and target.components.locomotor then
        target.components.locomotor:RemoveExternalSpeedMultiplier(target, "chasni_critter_worm")
        target.components.locomotor:SetExternalSpeedMultiplier(target, "chasni_critter_worm", 1 + modifier / 100)
    end
end
local worm_buffdata =
{
    ONATTACH = apply_worm,
    ONEXTENDED = apply_worm,
    ONDETACH = function(inst, target)
        if target.components.locomotor then
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "chasni_critter_worm")
        end
    end,
}
--------------------------------------------------------------------------
-- Elec Fish
--------------------------------------------------------------------------
local function apply_elecfish(inst, target, data)
    local elecmult = GetPassiveValue(data)
    if elecmult and elecmult > 0 then
        inst.elecmult = elecmult
    end
end
local elecfish_buffdata =
{
    ONATTACH = apply_elecfish,
    ONEXTENDED = apply_elecfish,
    ONDETACH = function(inst, target)
        inst.elecmult = nil
    end,
}
--------------------------------------------------------------------------
-- Fugu
--------------------------------------------------------------------------
local fugu_buffdata =
{
    ONATTACH = function(inst, target)
        target:AddTag("cz_fugu_builder")
        target:DoTaskInTime(0.1, function()
            SendModRPCToClient(GetClientModRPC("CrafterChest", "RefreshCrafting"), target)
        end)
    end,
    ONDETACH = function(inst, target)
        target:RemoveTag("cz_fugu_builder")
        target:DoTaskInTime(0.1, function()
            SendModRPCToClient(GetClientModRPC("CrafterChest", "RefreshCrafting"), target)
        end)
    end,
}
--------------------------------------------------------------------------
-- Seahorse
--------------------------------------------------------------------------
local function ClearSeahorseBuff(target)
    target.components.combat.externaldamagemultipliers:RemoveModifier("chasni_critter_seahorse")
    target.components.combat.externaldamagetakenmultipliers:RemoveModifier("chasni_critter_seahorse")
    target.components.locomotor:RemoveExternalSpeedMultiplier(target, "chasni_critter_seahorse")
end

local function MakeSeahorseApply(damage_taken_mult)
    return function(inst, target, data)
        local modifier = GetPassiveValue(data)
        if modifier and modifier > 0 then
            ClearSeahorseBuff(target)
            if target.components.rideable and target.components.rideable:IsBeingRidden() then
                if target.components.combat then
                    target.components.combat.externaldamagemultipliers:SetModifier("chasni_critter_seahorse", 1 + modifier / 100)
                    target.components.combat.externaldamagetakenmultipliers:SetModifier("chasni_critter_seahorse", damage_taken_mult)
                end
            end
        end
    end
end

local function MakeSeahorseBuffData(damage_taken_mult)
    local apply = MakeSeahorseApply(damage_taken_mult)
    return
    {
        ONATTACH = apply,
        ONEXTENDED = apply,
        ONDETACH = function(inst, target)
            ClearSeahorseBuff(target)
        end,
    }
end
local seahorse_a_buffdata   = MakeSeahorseBuffData(0.9)
local seahorse_b_buffdata = MakeSeahorseBuffData(0.7)
--------------------------------------------------------------------------
-- Turtle
--------------------------------------------------------------------------
local function apply_turtle(inst, target, data)
    local modifier = GetPassiveValue(data)
    if modifier and modifier > 0 and target.components.locomotor then
        target.components.locomotor:RemoveExternalSpeedMultiplier(target, "chasni_critter_turtle")
        target.components.locomotor:SetExternalSpeedMultiplier(target, "chasni_critter_turtle", 1 - modifier / 100)
    end
end
local turtle_buffdata =
{
    ONATTACH = apply_turtle,
    ONEXTENDED = apply_turtle,
    ONDETACH = function(inst, target)
        if target.components.locomotor then
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "chasni_critter_turtle")
        end
    end,
}
local function apply_turtle_active(inst, target, data)
    local cdreduction = GetPassiveValue(data)
    if cdreduction and cdreduction > 0 then
        inst.cdreduction = cdreduction
        target:AddDebuff("critter_turtle_buff", "critter_turtle_buff")
    end
end
local turtle_active_buffdata =
{
    ONATTACH = apply_turtle_active,
    ONEXTENDED = apply_turtle_active,
    ONDETACH = function(inst, target)
        inst.cdreduction = nil
        target:RemoveDebuff("critter_turtle_buff")
    end,
}
--------------------------------------------------------------------------
-- Snail (a and b, white and black)
--------------------------------------------------------------------------
local function apply_snail(inst, target, data)
    local mult = GetPassiveValue(data)
    if mult and mult > 0 then
        inst.mult = mult
    end
end
local snail_buffdata =
{
    ONATTACH = apply_snail,
    ONEXTENDED = apply_snail,
    ONDETACH = function(inst, target)
        inst.mult = nil
    end,
}
--------------------------------------------------------------------------
-- Bot
--------------------------------------------------------------------------
local bot_buffdata =
{
    ONATTACH = function(inst, target)
        target:AddTag("cz_bot_builder")
        target:DoTaskInTime(0.1, function()
            SendModRPCToClient(GetClientModRPC("CrafterChest", "RefreshCrafting"), target)
        end)
    end,
    ONDETACH = function(inst, target)
        target:RemoveTag("cz_bot_builder")
        target:DoTaskInTime(0.1, function()
            SendModRPCToClient(GetClientModRPC("CrafterChest", "RefreshCrafting"), target)
        end)
    end,
}

return
Prefab("chasni_critter_crab_aura_buff", MakeBuff(crab_buffdata)),
Prefab("chasni_critter_dog_aura_buff", MakeBuff(dog_buffdata)),
Prefab("chasni_critter_dog_pink_aura_buff", MakeBuff(dog_pink_buffdata)),
Prefab("chasni_critter_fish_burn_aura_buff", MakeBuff(fish_burn_buffdata)),
Prefab("chasni_critter_fish_wet_aura_buff", MakeBuff(fish_wet_buffdata)),
Prefab("chasni_critter_light_off_aura_buff", MakeBuff(light_buffdata)),
Prefab("chasni_critter_light_on_aura_buff", MakeBuff(light_buffdata)),
Prefab("chasni_critter_mamo_aura_buff", MakeBuff(mamo_buffdata)),
Prefab("chasni_critter_puff_health_aura_buff", MakeBuff(puffhealth_buffdata)),
Prefab("chasni_critter_puff_hunger_aura_buff", MakeBuff(puff_hunger_buffdata)),
Prefab("chasni_critter_raptor_aura_buff", MakeBuff(raptor_buffdata)),
Prefab("chasni_critter_seal_aura_buff", MakeBuff(seal_buffdata)),
Prefab("chasni_critter_slug_star_aura_buff", MakeBuff(slugstar_buffdata)),
Prefab("chasni_critter_slug_xp_aura_buff", MakeBuff(slugxp_buffdata)),
Prefab("chasni_critter_wool_aura_buff", MakeBuff(wool_buffdata)),
Prefab("chasni_critter_worm_aura_buff", MakeBuff(worm_buffdata)),
Prefab("chasni_critter_elecfish_aura_buff", MakeBuff(elecfish_buffdata)),
Prefab("chasni_critter_fugu_aura_buff", MakeBuff(fugu_buffdata)),
Prefab("chasni_critter_seahorse_a_aura_buff", MakeBuff(seahorse_a_buffdata)),
Prefab("chasni_critter_seahorse_b_aura_buff", MakeBuff(seahorse_b_buffdata)),
Prefab("chasni_critter_turtle_aura_buff", MakeBuff(turtle_buffdata)),
Prefab("chasni_critter_turtle_aura_buff_active", MakeBuff(turtle_active_buffdata)),
Prefab("chasni_critter_snail_a_aura_buff", MakeBuff(snail_buffdata)),
Prefab("chasni_critter_snail_b_aura_buff", MakeBuff(snail_buffdata)),
Prefab("chasni_critter_snail_black_a_aura_buff", MakeBuff(snail_buffdata)),
Prefab("chasni_critter_snail_black_b_aura_buff", MakeBuff(snail_buffdata)),
Prefab("chasni_critter_bot_aura_buff", MakeBuff(bot_buffdata))
