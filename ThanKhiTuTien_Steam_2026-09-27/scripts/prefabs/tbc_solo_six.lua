local definitions = require("tbc_solo_weapons/defs")
local ordered = {"hh_daogam", "hh_daogam2", "hh_daogam3", "hh_daogam4", "hh_daogam5", "hh_daogam6"}
local MAX_USES = 360
local exclude = {"INLIMBO", "NOCLICK", "notarget", "playerghost", "companion", "wall", "structure"}
local morph_modes = {"sword", "axe", "pickaxe", "shovel", "hoe"}
local morph_damage = {sword = 80, axe = 50, pickaxe = 50, shovel = 50, hoe = 50}
local morph_action = {axe = ACTIONS.CHOP, pickaxe = ACTIONS.MINE, shovel = ACTIONS.DIG}

local function Alive(ent)
    return ent ~= nil and ent.IsValid ~= nil and ent:IsValid()
        and ent.components ~= nil and ent.components.health ~= nil
        and not ent.components.health:IsDead()
end

local function CanHit(owner, target)
    return Alive(owner) and Alive(target) and owner ~= target
        and owner.components.combat ~= nil
        and owner.components.combat:IsValidTarget(target)
        and not target:HasTag("player")
        and not target:HasTag("companion")
end

local function HitArea(weapon, owner, x, z, radius, damage, burn, skip, seen)
    if not Alive(owner) then return end
    for _, target in ipairs(TheSim:FindEntities(x, 0, z, radius, {"_combat"}, exclude)) do
        if target ~= skip and CanHit(owner, target)
            and (seen == nil or not seen[target.GUID]) then
            target.components.combat:GetAttacked(owner, damage, weapon)
            if seen ~= nil then seen[target.GUID] = true end
            if burn and target.components.burnable ~= nil then
                target.components.burnable:Ignite(true)
            end
        end
    end
end

local function Effect(name, x, z, height)
    local fx = SpawnPrefab(name)
    if fx ~= nil then fx.Transform:SetPosition(x, height or 0, z) end
    return fx
end

local function KnifeEffect(target)
    local point = Vector3(target.Transform:GetWorldPosition())
        + Vector3(math.random() * 2 - 1, math.random() * 2, 0.5)
    Effect("hh_daogam_knife_ef", point.x, point.z, point.y)
end

local function SpendUses(inst, count)
    local uses = inst.components.finiteuses
    if uses ~= nil and uses:GetUses() > 0 then
        uses:Use(math.min(count, uses:GetUses()))
    end
end

local function ShadowHit(inst, owner, target)
    inst._tbc_shadow_hits = (inst._tbc_shadow_hits or 0) + 1
    if inst._tbc_shadow_hits < 3 then return end
    inst._tbc_shadow_hits = 0
    if not Alive(owner) then return end
    local pos = Alive(target) and target:GetPosition() or owner:GetPosition()
    local tentacle = SpawnPrefab("lunarplanttentacle")
    if tentacle ~= nil then
        tentacle.owner = owner
        tentacle.Transform:SetPosition(pos.x, 0, pos.z)
        if tentacle.components.combat ~= nil then
            tentacle.components.combat:SetDefaultDamage(85)
            if Alive(target) then tentacle.components.combat:SetTarget(target) end
        end
    end
end

local function OnFinished(inst)
    local invitem = inst.components.inventoryitem
    local owner = invitem ~= nil and invitem.owner or nil
    if owner ~= nil and owner.components.inventory ~= nil
        and inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
        local item = owner.components.inventory:Unequip(inst.components.equippable.equipslot)
        if item ~= nil then owner.components.inventory:GiveItem(item) end
    end
end

local function SetMorphMode(inst, mode)
    if morph_damage[mode] == nil then return false end
    inst._tbc_morph_mode = mode
    if inst.components.tool ~= nil then inst:RemoveComponent("tool") end
    if inst.components.farmtiller ~= nil then inst:RemoveComponent("farmtiller") end
    if morph_action[mode] ~= nil then
        inst:AddComponent("tool")
        inst.components.tool:SetAction(morph_action[mode], 1)
        if mode == "pickaxe" and inst.components.tool.EnableToughWork ~= nil then
            inst.components.tool:EnableToughWork(true)
        end
    elseif mode == "hoe" then
        inst:AddComponent("farmtiller")
    end
    local upgrade = inst.components.tbc_upgrade
    if upgrade ~= nil then
        upgrade.base_damage = morph_damage[mode]
        upgrade:ApplyStats()
    elseif inst.components.weapon ~= nil then
        inst.components.weapon:SetDamage(morph_damage[mode])
    end
    if inst.components.named ~= nil then
        inst.components.named:SetName(mode == "sword" and "Tà Thuật Đen"
            or ("Tà Thuật Đen - " .. ({axe = "Rìu", pickaxe = "Cúp", shovel = "Xẻng", hoe = "Cuốc"})[mode]))
    end
    if inst.components.inventoryitem ~= nil then
        inst.components.inventoryitem:ChangeImageName("hh_daogam6_" .. mode)
    end
    local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
    if owner ~= nil and inst.components.equippable:IsEquipped() then
        owner.AnimState:OverrideSymbol("swap_object", "hh_daogam6", mode)
    end
    return true
end

local function OnAttack(inst, attacker, target)
    if not CanHit(attacker, target) then return end
    SpendUses(inst, 1)
    local id = inst.prefab
    if id == "hh_daogam" then
        KnifeEffect(target)
        for n = 1, 3 do
            inst:DoTaskInTime(n * 0.2, function(item)
                if CanHit(attacker, target) then
                    KnifeEffect(target)
                    target.components.combat:GetAttacked(attacker, 10, item)
                end
            end)
        end
        if math.random() <= 0.7 then
            local seen = {[target.GUID] = true}
            local angle = attacker:GetAngleToPoint(target.Transform:GetWorldPosition()) * DEGREES
            for step = 1, 8 do
                inst:DoTaskInTime(step * 0.05, function(item)
                    if Alive(attacker) then
                        local ax, _, az = attacker.Transform:GetWorldPosition()
                        for lane = -1, 1 do
                            local theta = angle + lane * 30 * DEGREES
                            local cx = ax + step * 1.5 * math.cos(theta)
                            local cz = az - step * 1.5 * math.sin(theta)
                            Effect("hh_daogam_firepuff_" .. math.random(1, 3), cx, cz)
                            HitArea(item, attacker, cx, cz, 1.5, 50, false, target, seen)
                        end
                    end
                end)
            end
        end
    elseif id == "hh_daogam2" then
        ShadowHit(inst, attacker, target)
    elseif id == "hh_daogam4" then
        if target._tbc_inferno_task ~= nil then target._tbc_inferno_task:Cancel() end
        target._tbc_inferno_ticks = 0
        target._tbc_inferno_task = target:DoPeriodicTask(1, function(victim)
            if not Alive(victim) then
                victim._tbc_inferno_task:Cancel()
                victim._tbc_inferno_task = nil
                return
            end
            victim.components.health:DoDelta(-30, nil, "tbc_inferno", true, attacker, true)
            local x, _, z = victim.Transform:GetWorldPosition()
            Effect("firehit", x, z)
            victim._tbc_inferno_ticks = victim._tbc_inferno_ticks + 1
            if victim._tbc_inferno_ticks >= 10 then
                victim._tbc_inferno_task:Cancel()
                victim._tbc_inferno_task = nil
            end
        end)
    elseif id == "hh_daogam6" and inst._tbc_morph_mode == "sword" then
        local x, _, z = target.Transform:GetWorldPosition()
        Effect("hh_daogam6fx", x, z, 1.5)
        HitArea(inst, attacker, x, z, 4, inst.components.weapon.damage * 0.3, false, target)
    end
end

local function Cast(inst, doer, pos)
    if not Alive(doer) or pos == nil then return end
    if inst.components.inventoryitem.owner ~= doer then return end
    if inst.components.finiteuses:GetUses() <= 0 then return end
    local id = inst.prefab
    if id == "hh_daogam" then
        SpendUses(inst, 8)
        local meteor = SpawnPrefab("hh_daogam_fire_meteor")
        if meteor ~= nil then
            meteor.author = doer
            meteor.weapon = inst
            meteor.Transform:SetPosition(pos.x, 0, pos.z)
        end
    elseif id == "hh_daogam2" then
        SpendUses(inst, 5)
        inst.components.parryweapon:EnterParryState(doer, doer:GetAngleToPoint(pos), 2.1)
    elseif id == "hh_daogam3" then
        SpendUses(inst, 3)
        local indicator = SpawnPrefab("hh_indicator_fx")
        if indicator ~= nil then
            indicator.AnimState:SetScale(1.8, 1.8)
            indicator.Transform:SetPosition(pos.x, 0, pos.z)
            indicator:DoTaskInTime(1.5, indicator.Remove)
        end
        for n = 1, 10 do
            inst:DoTaskInTime(n * 0.1, function(item)
                if not Alive(doer) then return end
                local projectile = SpawnPrefab("hh_bow_project")
                if projectile == nil or projectile.components.projectile == nil then return end
                local start = doer:GetPosition()
                local angle = math.random() * 2 * PI
                local radius = math.random() * 3
                local target = Vector3(pos.x + radius * math.sin(angle), 0,
                    pos.z + radius * math.cos(angle))
                projectile.Transform:SetPosition(start.x, start.y, start.z)
                projectile.components.projectile:SetSpeed(55)
                projectile.components.projectile:SetBezier3(
                    start + Vector3(-5, 9, 0),
                    (start + target) / 2 + Vector3(0, 5, 0))
                projectile.components.projectile.onhit = function(bolt)
                    local impact = SpawnPrefab("hh_common_fx")
                    if impact ~= nil then
                        impact.AnimState:SetBank("explode")
                        impact.AnimState:SetBuild("explode")
                        impact.AnimState:PlayAnimation("small")
                        impact.Transform:SetPosition(bolt.Transform:GetWorldPosition())
                    end
                    local x, _, z = bolt.Transform:GetWorldPosition()
                    HitArea(item, doer, x, z, 4, 30, false)
                    bolt:Remove()
                end
                projectile.components.projectile:Throw(doer, target, doer)
                projectile:SpawnChild("hh_ball_fx_purple")
                projectile:SpawnChild("hh_sparkle_fx")
            end)
        end
    elseif id == "hh_daogam4" then
        SpendUses(inst, 5)
        for n = 1, 6 do
            inst:DoTaskInTime(n * 0.15, function()
                Effect("explode_small", pos.x + math.random() * 6 - 3,
                    pos.z + math.random() * 6 - 3)
            end)
        end
        HitArea(inst, doer, pos.x, pos.z, 5, 120, true)
    elseif id == "hh_daogam5" then
        SpendUses(inst, 11)
        doer.AnimState:PlayAnimation("lunge_lag")
        doer.sg:GoToState("combat_lunge", {targetpos = pos, weapon = inst})
        inst._tbc_combo = (inst._tbc_combo or 0) + 1
        if inst._tbc_combo < 3 then
            if inst._tbc_combo_task ~= nil then inst._tbc_combo_task:Cancel() end
            inst._tbc_combo_task = inst:DoTaskInTime(5, function(item)
                item._tbc_combo = 0
                item.components.rechargeable:Discharge(15)
            end)
            inst.components.rechargeable:Discharge(0.1)
            return
        end
        inst._tbc_combo = 0
        if inst._tbc_combo_task ~= nil then inst._tbc_combo_task:Cancel() end
    end
    if inst.components.rechargeable ~= nil then
        inst.components.rechargeable:Discharge(definitions[id].cooldown)
    end
end

local function MakeWeapon(id)
    local def = definitions[id]
    local image = "images/inventoryimages/" .. id
    if id == "hh_daogam4" or id == "hh_daogam6" then image = "images/" .. id end
    local assets = {
        Asset("ATLAS", def.icon), Asset("IMAGE", image .. (id == "hh_daogam6" and "_inventory" or "") .. ".tex"),
    }
    if id ~= "hh_daogam4" then
        assets[#assets + 1] = Asset("ANIM", "anim/" .. id .. ".zip")
    end
    if id == "hh_daogam2" or id == "hh_daogam3" then
        assets[#assets + 1] = Asset("ANIM", "anim/hh_daogam.zip")
    end
    if id == "hh_daogam" then
        assets[#assets + 1] = Asset("ANIM", "anim/hh_daogam_swap.zip")
    elseif id == "hh_daogam4" then
        assets[#assets + 1] = Asset("ANIM", "anim/nn_staff_fire.zip")
        assets[#assets + 1] = Asset("ANIM", "anim/swap_nn_staff_fire.zip")
    elseif id == "hh_daogam6" then
        assets[#assets + 1] = Asset("ANIM", "anim/hh_daogam6_ground.zip")
        assets[#assets + 1] = Asset("ANIM", "anim/hh_daogam6fx.zip")
    end
    if id ~= "hh_daogam4" then
        assets[#assets + 1] = Asset("ANIM", "anim/hh_purple_electric_fx.zip")
        assets[#assets + 1] = Asset("ANIM", "anim/hh_purple_mosling_spin_fx.zip")
        if id ~= "hh_daogam6" then
            assets[#assets + 1] = Asset("ANIM", "anim/hh_purple_deer_ice_charge.zip")
        end
    end
    if id == "hh_daogam2" then
        assets[#assets + 1] = Asset("ANIM", "anim/hh_purple_warg_mutated_breath_fx.zip")
    end

    local function OnEquip(inst, owner)
        if inst.components.finiteuses:GetUses() <= 0 then
            inst:DoTaskInTime(0, OnFinished)
            return
        end
        owner.AnimState:OverrideSymbol("swap_object", def.swap_build,
            id == "hh_daogam6" and (inst._tbc_morph_mode or "sword") or def.swap)
        if id == "hh_daogam2" then
            -- The original sword equip uses hh_daogam2/swap on swap_object.
            -- Its shield overlay belongs to a separate shield mode.
            owner.AnimState:ShowSymbol("swap_object")
            inst._tbc_onblocked = function(_, data)
                SpendUses(inst, 1)
                ShadowHit(inst, owner, data ~= nil and data.attacker or nil)
            end
            inst:ListenForEvent("blocked", inst._tbc_onblocked, owner)
            inst:ListenForEvent("attacked", inst._tbc_onblocked, owner)
        end
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
        if id ~= "hh_daogam4" then
            for _, field in ipairs({"fx00", "fx0", "_tbc_sparks2", "_tbc_sparks1"}) do
                if inst[field] ~= nil then inst[field]:Remove() inst[field] = nil end
            end
            if id ~= "hh_daogam6" then
                inst.fx00 = SpawnPrefab("deer_ice_charge")
                if inst.fx00 ~= nil then
                    if id ~= "hh_daogam2" then
                        inst.fx00.AnimState:SetBuild("hh_purple_deer_ice_charge")
                    end
                    inst.fx00.entity:AddFollower()
                    inst.fx00.entity:SetParent(owner.entity)
                    inst.fx00.Follower:FollowSymbol(owner.GUID, "swap_object", 10, -100, 0)
                end
            end
            inst.fx0 = SpawnPrefab(id == "hh_daogam2" and "cane_victorian_fx"
                or "hh_daogam_sparkle_fx")
            if inst.fx0 ~= nil then
                inst.fx0.entity:AddFollower()
                inst.fx0.entity:SetParent(owner.entity)
                inst.fx0.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -60, 0)
            end
            inst._tbc_sparks2 = owner:SpawnChild("sparks2_fx")
            if inst._tbc_sparks2 ~= nil then
                inst._tbc_sparks2.AnimState:SetBuild("hh_purple_mosling_spin_fx")
                inst._tbc_sparks2.Transform:SetPosition(0, 0, 0)
            end
            inst._tbc_sparks1 = owner:SpawnChild("sparks1_fx")
            if inst._tbc_sparks1 ~= nil then
                inst._tbc_sparks1.AnimState:SetBuild("hh_purple_electric_fx")
                inst._tbc_sparks1.Transform:SetPosition(0, -1, 0)
            end
        end
    end

    local function OnUnequip(inst, owner)
        if inst._tbc_normal_task ~= nil then
            inst._tbc_normal_task:Cancel()
            inst._tbc_normal_task = nil
        end
        for _, field in ipairs({"fx00", "fx0", "_tbc_sparks2", "_tbc_sparks1"}) do
            if inst[field] ~= nil then
                inst[field]:Remove()
                inst[field] = nil
            end
        end
        if id == "hh_daogam2" and inst._tbc_onblocked ~= nil then
            inst:RemoveEventCallback("blocked", inst._tbc_onblocked, owner)
            inst:RemoveEventCallback("attacked", inst._tbc_onblocked, owner)
            inst._tbc_onblocked = nil
        end
        owner.AnimState:ClearOverrideSymbol("swap_object")
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")
    end

    local function OnSave(inst, data)
        if id == "hh_daogam6" then data.tbc_morph_mode = inst._tbc_morph_mode end
        if id == "hh_daogam2" then data.tbc_shadow_hits = inst._tbc_shadow_hits end
    end

    local function OnLoad(inst, data)
        if type(data) ~= "table" then return end
        if id == "hh_daogam6" and data.tbc_morph_mode ~= nil then
            inst:DoTaskInTime(0, function(item) SetMorphMode(item, data.tbc_morph_mode) end)
        elseif id == "hh_daogam2" then
            inst._tbc_shadow_hits = math.max(0, math.min(2, tonumber(data.tbc_shadow_hits) or 0))
        end
    end

    local function Fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.entity:AddSoundEmitter()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank(def.bank)
        inst.AnimState:SetBuild(def.build)
        inst.AnimState:PlayAnimation("idle", true)
        inst:AddTag("weapon")
        inst:AddTag("sharp")
        inst:AddTag("hh_equip")
        inst:AddTag("hh_daogam_item")
        if id == "hh_daogam6" then inst:AddTag("nosteal") end
        if id ~= "hh_daogam6" then
            inst:AddTag("rechargeable")
        end
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = def.icon
        inst.components.inventoryitem.imagename = id == "hh_daogam6" and "hh_daogam6_sword" or id
        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(OnEquip)
        inst.components.equippable:SetOnUnequip(OnUnequip)
        if id == "hh_daogam4" then inst.components.equippable.walkspeedmult = 1.15 end
        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(def.damage)
        inst.components.weapon:SetRange(def.range, def.range + 1)
        inst.components.weapon:SetOnAttack(OnAttack)
        if id == "hh_daogam3" then
            inst.components.weapon:SetProjectile("hh_bow_project")
            local launch = inst.components.weapon.LaunchProjectile
            inst.components.weapon.LaunchProjectile = function(weapon, attacker, target, ...)
                if attacker == nil or target == nil then
                    return launch(weapon, attacker, target, ...)
                end
                if inst._tbc_normal_task ~= nil then return true end
                local count = 0
                inst._tbc_normal_task = inst:DoPeriodicTask(0.1, function(item)
                    if not CanHit(attacker, target) then
                        item._tbc_normal_task:Cancel()
                        item._tbc_normal_task = nil
                        return
                    end
                    local projectile = SpawnPrefab("hh_bow_project")
                    if projectile ~= nil and projectile.components.projectile ~= nil then
                        projectile.Transform:SetPosition(attacker.Transform:GetWorldPosition())
                        projectile.components.projectile:SetBezier(1.5, 90 + count * 45)
                        projectile.components.projectile:Throw(item, target, attacker)
                        projectile:SpawnChild("hh_ball_fx_purple")
                        projectile:SpawnChild("hh_sparkle_fx")
                    end
                    count = count + 1
                    if count >= 2 then
                        item._tbc_normal_task:Cancel()
                        item._tbc_normal_task = nil
                    end
                end, 0)
                return true
            end
        end
        if id == "hh_daogam4" then
            inst.components.weapon:SetProjectile("fire_projectile")
        end
        inst:AddComponent("damagetypebonus")
        inst.components.damagetypebonus:AddBonus("shadow_aligned", inst,
            TUNING.WEAPONS_LUNARPLANT_VS_SHADOW_BONUS or 0)
        inst.components.damagetypebonus:AddBonus("lunar_aligned", inst,
            TUNING.WEAPONS_VOIDCLOTH_VS_LUNAR_BONUS or 0)
        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(MAX_USES)
        inst.components.finiteuses:SetUses(MAX_USES)
        inst.components.finiteuses:SetOnFinished(OnFinished)
        inst.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)
        inst:AddComponent("trader")
        inst.components.trader:SetAcceptTest(function(item, gift)
            return gift.prefab == "nightmarefuel" and item.components.finiteuses:GetPercent() < 1
        end)
        inst.components.trader.onaccept = function(item)
            item.components.finiteuses:Repair(36)
        end
        if id == "hh_daogam2" then
            inst:AddTag("heavyarmor")
            inst:AddComponent("armor")
            inst.components.armor:InitIndestructible(0.9)
            inst.components.armor.GetPercent = function(armor)
                return armor.inst.components.finiteuses:GetPercent()
            end
            inst:AddComponent("parryweapon")
            inst:RemoveTag("parryweapon")
            inst.components.parryweapon:SetParryArc(178)
            inst.components.parryweapon:SetOnParryFn(function(item, doer)
                if item.components.rechargeable ~= nil
                    and item.components.rechargeable:GetPercent() < 0.8 then
                    item.components.rechargeable:SetPercent(0.8)
                end
                local flame = SpawnPrefab("flamethrower_fx")
                if flame ~= nil then
                    flame._hh_daogam2_purple_build = true
                    flame.entity:SetParent(doer.entity)
                    flame:SetFlamethrowerAttacker(doer)
                    flame:DoTaskInTime(0.3, flame.KillFX)
                end
            end)
            inst:AddComponent("planardefense")
            inst.components.planardefense:SetBaseDefense((TUNING.ARMOR_LUNARPLANT_PLANAR_DEF or 0) * 2)
        end
        if id == "hh_daogam2" or id == "hh_daogam3" or id == "hh_daogam4" or id == "hh_daogam5" then
            inst:AddComponent("planardamage")
            inst.components.planardamage:SetBaseDamage(id == "hh_daogam2" and 30
                or id == "hh_daogam5" and (TUNING.SWORD_LUNARPLANT_PLANAR_DAMAGE or 0)
                or (TUNING.SWORD_LUNARPLANT_PLANAR_DAMAGE or 0) / 3)
        end
        if id == "hh_daogam3" or id == "hh_daogam5" then
            inst:AddComponent("lunarplant_tentacle_weapon")
        end
        if id == "hh_daogam6" then
            inst._tbc_morph_mode = "sword"
            inst:AddComponent("named")
            inst.components.named:SetName(def.name)
            inst.TBCMorphNext = function(item)
                local index = 1
                for n, mode in ipairs(morph_modes) do
                    if mode == item._tbc_morph_mode then index = n break end
                end
                return SetMorphMode(item, morph_modes[index % #morph_modes + 1])
            end
            inst.TBCMorphMode = function(item, mode)
                return SetMorphMode(item, mode)
            end
        else
            inst.TBCCast = Cast
            inst:AddComponent("rechargeable")
        end
        if id == "hh_daogam5" then
            inst:AddComponent("aoeweapon_lunge")
            inst:RemoveTag("aoeweapon_lunge")
            inst.components.aoeweapon_lunge:SetDamage(100)
            inst.components.aoeweapon_lunge:SetSound("meta3/wigfrid/spear_lighting_lunge")
            inst.components.aoeweapon_lunge:SetSideRange(1)
            inst.components.aoeweapon_lunge:SetTags("_combat")
        end
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        return inst
    end
    local deps = {"weaponsparks", "firehit", "explode_small"}
    if id ~= "hh_daogam4" then
        deps[#deps + 1] = "sparks1_fx"
        deps[#deps + 1] = "sparks2_fx"
        if id ~= "hh_daogam6" then deps[#deps + 1] = "deer_ice_charge" end
        if id == "hh_daogam2" then deps[#deps + 1] = "cane_victorian_fx" end
    end
    if id == "hh_daogam" then
        deps[#deps + 1] = "hh_daogam_fire_meteor"
        deps[#deps + 1] = "hh_daogam_knife_ef"
        deps[#deps + 1] = "hh_daogam_sparkle_fx"
        for n = 1, 3 do deps[#deps + 1] = "hh_daogam_firepuff_" .. n end
    end
    if id == "hh_daogam2" then
        deps[#deps + 1] = "lunarplanttentacle"
        deps[#deps + 1] = "flamethrower_fx"
    end
    if id == "hh_daogam3" then
        deps[#deps + 1] = "hh_bow_project"
        deps[#deps + 1] = "hh_indicator_fx"
        deps[#deps + 1] = "hh_ball_fx_purple"
        deps[#deps + 1] = "hh_sparkle_fx"
    end
    if id == "hh_daogam3" or id == "hh_daogam5" or id == "hh_daogam6" then
        deps[#deps + 1] = "hh_daogam_sparkle_fx"
    end
    if id == "hh_daogam4" then deps[#deps + 1] = "fire_projectile" end
    if id == "hh_daogam6" then deps[#deps + 1] = "hh_daogam6fx" end
    return Prefab(id, Fn, assets, deps)
end

local function MorphFX()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.AnimState:SetBank("hh_daogam6fx")
    inst.AnimState:SetBuild("hh_daogam6fx")
    inst.AnimState:PlayAnimation("idle_000")
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end
    inst.persists = false
    inst:DoTaskInTime(2, inst.Remove)
    return inst
end

local function FireMeteor()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    inst.AnimState:SetBank("lavaarena_firestaff_meteor")
    inst.AnimState:SetBuild("hh_purple_lavaarena_firestaff_meteor")
    inst.AnimState:PlayAnimation("crash")
    inst.AnimState:PushAnimation("crash_pst", false)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end
    inst.persists = false
    inst:ListenForEvent("animover", function(meteor)
        local x, _, z = meteor.Transform:GetWorldPosition()
        local splash = Effect("hh_daogam_fire_splash", x, z)
        if splash ~= nil then
            splash.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/meteor_strike")
        end
        Effect("hh_daogam_fire_base", x, z)
        Effect("burntground", x, z)
        ShakeAllCameras(CAMERASHAKE.VERTICAL, .7, .015, .8, meteor, 20)
        HitArea(meteor.weapon, meteor.author, x, z, 4, 1000, true)
        meteor:Remove()
    end)
    inst:DoTaskInTime(3, inst.Remove)
    return inst
end

local prefabs = {}
for _, id in ipairs(ordered) do prefabs[#prefabs + 1] = MakeWeapon(id) end
prefabs[#prefabs + 1] = Prefab("hh_daogam6fx", MorphFX,
    {Asset("ANIM", "anim/hh_daogam6fx.zip")})
prefabs[#prefabs + 1] = Prefab("hh_daogam_fire_meteor", FireMeteor,
    {Asset("ANIM", "anim/hh_purple_lavaarena_firestaff_meteor.zip")},
    {"hh_daogam_fire_splash", "hh_daogam_fire_base", "burntground"})
return unpack(prefabs)
