local assets =
{
    Asset("ANIM", "anim/water_spear.zip"),
    Asset("ANIM", "anim/swap_water_spear.zip"),
    Asset("ATLAS", "images/inventoryimages/water_spear.xml"),
}

local prefabs =
{
    "crab_king_waterspout",
}

local DAMAGE = chasni_getitemconfig("water_spear", "DMG") or 42.5
local USES = chasni_getitemconfig("water_spear", "USE") or 3000
local WATER_DAMAGE = chasni_getitemconfig("water_spear", "SDMG") or 80
local WETNESS = chasni_getitemconfig("water_spear", "WET") or 25
local WET_DURATION = chasni_getitemconfig("water_spear", "WDUR") or 20
local WETNESS_HIT = chasni_getitemconfig("water_spear", "HWET") or 2.5
local WET_DURATION_HIT = chasni_getitemconfig("water_spear", "HDUR") or 5
local COOLDOWN = chasni_getitemconfig("water_spear", "CD") or 60
local SPELL_USES = chasni_getitemconfig("water_spear", "SUSE") or 30
local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object","swap_water_spear","swap_water_spear")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function reticule_target_function(inst)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0.001, 0))
end

local function do_water_damage(inst, affected_entity, owner)
    if affected_entity.components.health then
        if affected_entity.components.combat then
            affected_entity.components.combat:GetAttacked(owner, WATER_DAMAGE, inst)
        else
            affected_entity.components.health:DoDelta(-WATER_DAMAGE, nil, inst.prefab, nil, owner)
        end
    end
end

local function do_water_wetting(target, duration)
    if target.waterspearwet_endtime and target.waterspearwet_endtime - GetTime() > duration then
        return
    end
    if target._waterspearwet_task then
        target._waterspearwet_task:Cancel()
        target._waterspearwet_task = nil
    end
    target.waterspearwet_endtime = GetTime() + duration
    target:Chasni_AddTag("wet")
    target._waterspearwet_task = target:DoTaskInTime(duration, function(_target)
        _target._waterspearwet_task = nil
        _target:Chasni_RemoveTag("wet")
    end)
end

local function create_water_explosion(inst, target, position)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner == nil then
        return
    end
    local px, py, pz = chasni_getPos(position, target)
    local ox, oy, oz = owner.Transform:GetWorldPosition()

    local delay = 0
    local xdistance = px - ox
    local zdistance = pz - oz
    local amount = math.max(math.ceil(math.abs(xdistance)/3), math.ceil(math.abs(zdistance)/3))
    if not owner or not chasni_hastag(inst, owner) then
        amount = 1
    end

    for i = 1, amount, 1 do
        inst:DoTaskInTime(delay ,function ()
            local fx = SpawnPrefab("crab_king_waterspout")
            if fx then
                fx.Transform:SetPosition(ox + (xdistance * (i/amount)), py,oz + (zdistance * (i/amount)))
                local nx,ny,nz = fx.Transform:GetWorldPosition()
                inst.components.wateryprotection.addwetness = WETNESS
                inst.components.wateryprotection:SpreadProtectionAtPoint(nx,ny,nz)
                inst.components.wateryprotection.addwetness = WETNESS_HIT
                local ents = TheSim:FindEntities(nx, ny, nz, TUNING.TRIDENT.SPELL.RADIUS * 0.7, nil, chasni_TAG_NOTARGET)
                for _, v in ipairs(ents) do
                    if v ~= owner then
                        if not v:HasTag("player") or TheNet:GetPVPEnabled() then
                            if v:HasTag("merm_npc") then
                                if v.components.health then
                                    v.components.health:DoDelta(WATER_DAMAGE) -- >>>> healing
                                end
                            elseif not v:HasTag("companion") then
                                if (TheNet:GetPVPEnabled() and chasni_ownpet(v, owner)) or (not TheNet:GetPVPEnabled() and chasni_friendpet(v)) then
                                else
                                    do_water_damage(inst, v, owner)
                                end
                            end
                        end

                        do_water_wetting(v, WET_DURATION)
                    end
                end
            end
        end)
    end
    inst.components.rechargeable:Discharge(COOLDOWN)
    inst.components.finiteuses:Use(SPELL_USES)
end

local function onattack(inst, attacker, target, projectile)
    if chasni_hastag(inst, attacker) then
        local fx, scale = SpawnPrefab("crab_king_waterspout"), 0.5;
        fx.Transform:SetScale(scale, scale, scale);
        fx.Transform:SetPosition(target.Transform:GetWorldPosition());
        local nx,ny,nz = fx.Transform:GetWorldPosition()
        inst.components.wateryprotection:SpreadProtectionAtPoint(nx,ny,nz)
        do_water_wetting(target, WET_DURATION_HIT)
    end
end

local function OnCharged(inst)
    inst.components.spellcaster:SetSpellFn(create_water_explosion)
end

local function OnDischarged(inst)
    inst.components.spellcaster:SetSpellFn(nil)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("water_spear")
    inst.AnimState:SetBuild("water_spear")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("sharp")
    inst:AddTag("pointy")
    inst:AddTag("weapon")
    inst:AddTag("rechargeable")

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = reticule_target_function
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true

    inst._restrictedtag = "expertwurt1"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "water_spear"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/water_spear.xml"

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster:SetSpellFn(create_water_explosion)

    inst:AddComponent("wateryprotection")
    inst.components.wateryprotection.addwetness = WETNESS_HIT
    inst.components.wateryprotection.protection_dist = TUNING.TRIDENT.SPELL.RADIUS * 0.7

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("water_spear", fn, assets, prefabs)
