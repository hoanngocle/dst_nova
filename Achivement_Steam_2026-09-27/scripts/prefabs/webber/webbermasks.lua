local prefabs = {}

local ICON_SCALE = .6
local ICON_RADIUS = 50
local SPELL_RADIUS = 100
local SPELL_FOCUS_RADIUS = SPELL_RADIUS + 2
local function ChangeMask(inst, doer, mask_type)
    local mutatorname = mask_type == "poison" and  "chasni_mutator_poison" or "mutator_" .. mask_type
    if doer.components.builder and not doer.components.builder:KnowsRecipe(mutatorname) then
        return false, "NO_RECIPE"
    end
    if doer.components.inventory 
            and inst.components.fueled and not inst.components.fueled:IsEmpty()
            and inst.prefab ~= "webbermask_" .. mask_type
    then
        local fuelpercent = inst.components.fueled:GetPercent()
        inst:Remove()
        local newmask = SpawnPrefab("webbermask_" .. mask_type)
        newmask.components.fueled:SetPercent(fuelpercent)
        doer.components.inventory:Equip(newmask)
        return true
    end
    return false
end

local function ChangeMask_warrior(inst, doer) return ChangeMask(inst, doer, "warrior") end
local function ChangeMask_dropper(inst, doer) return ChangeMask(inst, doer, "dropper") end
local function ChangeMask_hider(inst, doer) return ChangeMask(inst, doer, "hider") end
local function ChangeMask_spitter(inst, doer) return ChangeMask(inst, doer, "spitter") end
local function ChangeMask_moon(inst, doer) return ChangeMask(inst, doer, "moon") end
local function ChangeMask_healer(inst, doer) return ChangeMask(inst, doer, "healer") end
local function ChangeMask_water(inst, doer) return ChangeMask(inst, doer, "water") end
local function ChangeMask_poison(inst, doer) return ChangeMask(inst, doer, "poison") end

local function OnOpenSpell(inst)
    local inventoryitem = inst.replica.inventoryitem
    if inventoryitem then
        inventoryitem:OverrideImage("waxwelljournal_open")
    end
end

local function OnCloseSpell(inst)
    local inventoryitem = inst.replica.inventoryitem
    if inventoryitem then
        inventoryitem:OverrideImage(nil)
    end
end

local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "webbermask_" .. inst.mask_type, "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    inst.components.fueled:StartConsuming()
    owner:AddTag("webbermasked")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    inst.components.fueled:StopConsuming()
    owner:RemoveTag("webbermasked")
end

local function onequiptomodel(inst)
    inst.components.fueled:StopConsuming()
end

local function onequip_warrior(inst, owner)
    onequip(inst, owner)
    if owner.components.combat then
        local level = owner.components.levelsystem and owner.components.levelsystem.level or 0
        owner.components.combat.externaldamagemultipliers:SetModifier("webbermask_warrior", 1 + (level * 0.003))
    end
end

local function onunequip_warrior(inst, owner)
    onunequip(inst, owner)
    if owner.components.combat then
        owner.components.combat.externaldamagemultipliers:RemoveModifier("webbermask_warrior")
    end
end

local function stopuse_hider(inst, data)
    local hat = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
    if hat and data.statename ~= "hide" then
        hat.components.useableitem:StopUsingItem()
        inst:RemoveEventCallback("newstate", stopuse_hider)
        if inst.components.health then
            inst.components.health.externalabsorbmodifiers:RemoveModifier("webbermask_hider")
        end
    end
    if data.statename == "unequipwebbermask_hider" then
        inst:RemoveEventCallback("newstate", stopuse_hider)
        if inst.components.health then
            inst.components.health.externalabsorbmodifiers:RemoveModifier("webbermask_hider")
        end
    end
end

local function onuse_hider(inst)
    if inst.components.fueled then
        inst.components.fueled:DoDelta(-30)
    end
    local owner = inst.components.inventoryitem.owner
    if owner then
        if owner.components.health then
            owner.components.health.externalabsorbmodifiers:SetModifier("webbermask_hider", 1)
        end
        owner.sg:GoToState("hide")
        owner:ListenForEvent("newstate", stopuse_hider)
    end
end

local function onequip_hider(inst, owner)
    inst:AddTag("hider_equipped")
    onequip(inst, owner)
end

local function onunequip_hider(inst, owner)
    inst:RemoveTag("hider_equipped")
    onunequip(inst, owner)
    stopuse_hider(owner,{statename = "unequipwebbermask_hider"})
end

local variations = {1, 2, 3, 4, 5}
local function DoSpikeAttack(inst, owner, target)
    local x, _, z = target.Transform:GetWorldPosition()
    local inital_r = 1
    x = GetRandomWithVariance(x, inital_r)
    z = GetRandomWithVariance(z, inital_r)
    shuffleArray(variations)

    local num = math.random(2, 4)
    local dtheta = PI * 2 / num

    for i = 1, num do
        local r = 1.1 + math.random() * 1.75
        local theta = i * dtheta + math.random() * dtheta * 0.8 + dtheta * 0.2
        local x1 = x + r * math.cos(theta)
        local z1 = z + r * math.sin(theta)
        if TheWorld.Map:IsVisualGroundAtPoint(x1, 0, z1) and not TheWorld.Map:IsPointNearHole(Vector3(x1, 0, z1)) then
            local spike = SpawnPrefab("webbermask_spike")
            spike.Transform:SetPosition(x1, 0, z1)
            spike:SetOwner(owner)
            if variations[i + 1] ~= 1 then
                spike.AnimState:OverrideSymbol("spike01", "spider_spike", "spike0"..tostring(variations[i + 1]))
            end
        end
    end
end

local HEALER_HEAL = chasni_getitemconfig("webbermask", "HEAL") or 15
local SPIDER_ONEOF_TAGS = chasni_getitemconfig("webbermask", "HEAL") and { "spider", "spiderwhisperer" } or { "spider" }
local function SpawnFx(inst, fx_prefab)
    local x,y,z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab(fx_prefab)
    fx.Transform:SetNoFaced()
    fx.Transform:SetPosition(x,y,z)
end

local function DoHeal(inst)
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("webber1/creatures/spider_cannonfodder/heal_fartcloud")
    end

    SpawnFx(inst, "spider_heal_ground_fx")
    SpawnFx(inst, "spider_heal_fx")
    local x,y,z = inst.Transform:GetWorldPosition()
    local other_spiders = TheSim:FindEntities(x, y, z, TUNING.SPIDER_HEALING_ITEM_RADIUS, nil, chasni_TAG_NOTARGET, SPIDER_ONEOF_TAGS)

    for i, spider in ipairs(other_spiders) do
        spider.components.health:DoDelta(HEALER_HEAL, false, inst.prefab)
        SpawnFx(spider, "spider_heal_target_fx")
    end
end

local function onequip_healer(inst, owner)
    onequip(inst, owner)
    if owner.healtask == nil then
        owner.healtask = owner:DoPeriodicTask(5, DoHeal)
    end
end

local function onunequip_healer(inst, owner)
    onunequip(inst, owner)
    if owner.healtask then
        owner.healtask:Cancel()
        owner.healtask = nil
    end
end

local function DoRipple(inst)
    if inst.components.drownable and inst.components.drownable:IsOverWater() and not inst:HasTag("playerghost") then
        SpawnPrefab("weregoose_ripple"..tostring(math.random(2))).entity:SetParent(inst.entity)
    end
end

local function DoSplash(inst)
    if inst.components.drownable and inst.components.drownable:IsOverWater() and inst.sg:HasStateTag("moving") and not inst:HasTag("playerghost") then
        SpawnPrefab("weregoose_splash_med"..tostring(math.random(2))).entity:SetParent(inst.entity)
    end
end

local function ShouldNotDrown(inst)
    if inst.components.drownable and inst.components.drownable.enabled ~= false then
        inst.components.drownable.enabled = false
        if not inst:HasTag("playerghost") then
            inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
        end
    end
end

local function ShouldDrown(inst)
    if inst._webbermask_notdrowntask then
        inst._webbermask_notdrowntask:Cancel()
        inst._webbermask_notdrowntask = nil
    end
    if inst.components.drownable and inst.components.drownable.enabled == false then
        inst.components.drownable.enabled = true
        if not inst:HasTag("playerghost") then
            inst.Physics:CollidesWith(COLLISION.LIMITS)
        end
    end
end

local function onequip_water(inst, owner)
    onequip(inst, owner)
    if owner.rippletask == nil then
        owner.rippletask = owner:DoPeriodicTask(.7, DoRipple, FRAMES)
    end
    if owner.splashtask == nil then
        owner.splashtask = owner:DoPeriodicTask(.3, DoSplash, FRAMES)
    end

    owner._webbermask_notdrowntask = owner:DoPeriodicTask(0, ShouldNotDrown)
end

local function onunequip_water(inst, owner)
    onunequip(inst, owner)
    if owner.rippletask then
        owner.rippletask:Cancel()
        owner.rippletask = nil
    end
    if owner.splashtask then
        owner.splashtask:Cancel()
        owner.splashtask = nil
    end

    ShouldDrown(owner)
end

local function onequip_poison(inst, owner)
    onequip(inst, owner)

    owner:AddTag("playerpoisonimmunity")
    if owner.components.playerpoisonable then
        owner.components.playerpoisonable:WearOff()
    end
end

local function onunequip_poison(inst, owner)
    onunequip(inst, owner)
    owner:RemoveTag("playerpoisonimmunity")
end

local mask_types =
{
    normal = { fuelsize = 100,},
    warrior = {
        name = STRINGS.NAMES.WEBBERMASK_WARRIOR,
        fuelsize = chasni_getitemconfig("webbermask", "W_DUR") or 1,
        spell = ChangeMask_warrior,
        onequip = onequip_warrior,
        onunequip = onunequip_warrior,
    },
    dropper = {
        name = STRINGS.NAMES.WEBBERMASK_DROPPER,
        fuelsize = chasni_getitemconfig("webbermask", "D_DUR") or 5,
        spell = ChangeMask_dropper,
        tag = "nightvision"
    },
    hider = {
        name = STRINGS.NAMES.WEBBERMASK_HIDER,
        fuelsize = chasni_getitemconfig("webbermask", "H_DUR") or 1,
        spell = ChangeMask_hider,
        onequip = onequip_hider,
        onunequip = onunequip_hider,
        tag = "hide"
    },
    spitter = {
        name = STRINGS.NAMES.WEBBERMASK_SPITTER,
        fuelsize = chasni_getitemconfig("webbermask", "S_DUR") or 0.5,
        spell = ChangeMask_spitter,
        tag = "headweapon"
    },
    moon = {
        name = STRINGS.NAMES.WEBBERMASK_MOON,
        fuelsize = chasni_getitemconfig("webbermask", "M_DUR") or 1,
        spell = ChangeMask_moon,
        tag = "headweapon"
    },
    healer = {
        name = STRINGS.NAMES.WEBBERMASK_HEALER,
        fuelsize = chasni_getitemconfig("webbermask", "L_DUR") or 3,
        spell = ChangeMask_healer,
        onequip = onequip_healer,
        onunequip = onunequip_healer,
    },
    water = {
        name = STRINGS.NAMES.WEBBERMASK_WATER,
        fuelsize = chasni_getitemconfig("webbermask", "T_DUR") or 3,
        spell = ChangeMask_water,
        onequip = onequip_water,
        onunequip = onunequip_water,
    },
    poison = {
        name = STRINGS.NAMES.WEBBERMASK_POISON,
        fuelsize = chasni_getitemconfig("webbermask", "P_DUR") or 3,
        spell = ChangeMask_poison,
        onequip = onequip_poison,
        onunequip = onunequip_poison,
    },
}

local SPELLS = {}
for mask_type, data in pairs(mask_types) do
    if mask_type ~= "normal" then
        table.insert(SPELLS, {
            label = data.name,
            onselect = function(inst)
                inst.components.spellbook:SetSpellName(data.name)
                if TheWorld.ismastersim then
                    inst.components.spellbook:SetSpellFn(data.spell)
                end
            end,
            execute = function(inst)
                if ThePlayer.replica.inventory then
                    ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
                end
            end,
            atlas = "images/inventoryimages/webbermask_" .. mask_type .. ".xml",
            normal = "webbermask_" .. mask_type .. ".tex",
            widget_scale = ICON_SCALE,
            hit_radius = ICON_RADIUS,
        })
    end
end

local SPITTER_DAMAGE = chasni_getitemconfig("webbermask", "DSPT") or 10
local SPITTER_RANGE = chasni_getitemconfig("webbermask", "RSPT") or 15
local MOON_DAMAGE = 1
local MOON_RANGE = chasni_getitemconfig("webbermask", "RMOON") or 4
local seg_time = 30
local total_day_time = seg_time * 16
local function fn(mask_type, data)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("webbermask_" .. mask_type)
    inst.AnimState:SetBuild("webbermask_" .. mask_type)
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("mask")
    inst:AddTag("goggles")
    inst:AddTag("webbermask")
    if data.tag then
        inst:AddTag(data.tag)
    end

    inst:AddComponent("spellbook")
    inst.components.spellbook:SetRequiredTag("webbermasked")
    inst.components.spellbook:SetRadius(SPELL_RADIUS)
    inst.components.spellbook:SetFocusRadius(SPELL_FOCUS_RADIUS)
    inst.components.spellbook:SetItems(SPELLS)
    inst.components.spellbook:SetOnOpenFn(OnOpenSpell)
    inst.components.spellbook:SetOnCloseFn(OnCloseSpell)
    inst.components.spellbook:SetCanUseFn(function() 
        return not inst:HasTag("hider_equipped")
    end)

    inst._restrictedtag = "expertwebber3"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(data.onequip or onequip)
    inst.components.equippable:SetOnUnequip(data.onunequip or onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(total_day_time * data.fuelsize)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "webbermask_" .. mask_type
    inst.components.inventoryitem.atlasname = "images/inventoryimages/webbermask_" .. mask_type .. ".xml"

    if mask_type == "hider" then
        inst:AddComponent("useableitem")
        inst.components.useableitem:SetOnUseFn(onuse_hider)
    end

    if mask_type == "spitter" then
        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(SPITTER_DAMAGE)
        inst.components.weapon:SetRange(SPITTER_RANGE, SPITTER_RANGE + 5)
        inst.components.weapon:SetProjectile("webbermask_spit")
        inst.components.weapon:SetProjectileOffset(-0.1)
    end

    if mask_type == "moon" then
        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(MOON_DAMAGE)
        inst.components.weapon:SetRange(MOON_RANGE, MOON_RANGE + 3)
        inst.components.weapon:SetOnAttack(DoSpikeAttack)
    end

    inst.mask_type = mask_type
    return inst
end

local mask_prefabs = {}
for mask_type, data in pairs(mask_types) do
    local assets = {
        Asset("ANIM", "anim/webbermask_" .. mask_type .. ".zip"),
        Asset("ATLAS", "images/inventoryimages/webbermask_" .. mask_type .. ".xml"),
    }

    table.insert(mask_prefabs, Prefab("webbermask_" .. mask_type, function() return fn(mask_type, data) end, assets, prefabs))
end

return unpack(mask_prefabs)