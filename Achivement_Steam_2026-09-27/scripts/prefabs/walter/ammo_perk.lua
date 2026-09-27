local LUNAR_PERCENTAGE = chasni_getitemconfig("ammo", "LPCT") or 0.17
local SHADOW_PERCENTAGE = chasni_getitemconfig("ammo", "SPCT") or 0.17
local SHADOW_DAMAGE = chasni_getitemconfig("ammo", "SDMG") or 51
local PILLS_HEAL = chasni_getitemconfig("ammo", "PHL") or 0.05
local PILLS_PLAYER_HEAL = chasni_getitemconfig("ammo", "PPHL") or 0.17
local BOMB_DAMAGE = chasni_getitemconfig("ammo", "BDMG") or 34
local EGG_DAMAGE = chasni_getitemconfig("ammo", "EDMG") or 10

-- temp aggro system for the slingshots
local function no_aggro(attacker, target)
    local targets_target = target.components.combat and target.components.combat.target or nil
    return targets_target and targets_target:IsValid() and targets_target ~= attacker and attacker and attacker:IsValid()
            and (GetTime() - target.components.combat.lastwasattackedbytargettime) < 4
            and (targets_target.components.health and not targets_target.components.health:IsDead())
end

local function ImpactFx(inst, attacker, target)
    if target and target:IsValid() then
        local impactfx = SpawnPrefab(inst.ammo_def.impactfx)
        impactfx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
end

local function OnAttack(inst, attacker, target)
    if target and target:IsValid() and attacker and attacker:IsValid() then
        if inst.ammo_def and inst.ammo_def.onhit then
            inst.ammo_def.onhit(inst, attacker, target)
        end
        ImpactFx(inst, attacker, target)
    end
end

local function OnPreHit(inst, attacker, target)
    if target and target:IsValid() and target.components.combat and no_aggro(attacker, target) then
        target.components.combat:SetShouldAvoidAggro(attacker)
    end
end

local function OnHit(inst, attacker, target)
    if target and target:IsValid() and target.components.combat then
        target.components.combat:RemoveShouldAvoidAggro(attacker)
    end
    inst:Remove()
end

-- START CODE
local function GetDamage_Pills(inst, attacker, target)
    return 0
end

local function GetDamage_Lunar(inst, attacker, target)
    if attacker and attacker:IsValid() then
        if target and target:IsValid() and target.components.health and target.components.health.maxhealth and target.components.health.currenthealth and target.components.health.maxhealth == target.components.health.currenthealth then
            return target.components.health.maxhealth * LUNAR_PERCENTAGE
        end
        return 0
    end
    return 0
end

local function GetDamage_Shadow(inst, attacker, target)
    if attacker and attacker:IsValid() then
        if target and target:IsValid() and target.components.health and target.components.health.maxhealth and target.components.health.currenthealth and target.components.health.maxhealth * SHADOW_PERCENTAGE > target.components.health.currenthealth then
            target._shadow_ammo = true
            return target.components.health.currenthealth
        end
        return SHADOW_DAMAGE
    end
    return SHADOW_DAMAGE
end

local function cancelLunarAmmoLightTask(target)
    if target._lunar_ammo_lighttask then
        target._lunar_ammo_lighttask:Cancel()
        target._lunar_ammo_lighttask = nil
    end
end

local function setLunarAmmoLightTask(target)
    cancelLunarAmmoLightTask(target)
    target:AddTag("slingshotammo_lunar")

    target._lunar_ammo_lighttask = target:DoTaskInTime(60, function()
        local bufffx = target._lunar_ammo_light
        bufffx:Remove()
        target._lunar_ammo_light = nil
        target:RemoveTag("slingshotammo_lunar")
        cancelLunarAmmoLightTask(target)
    end)
end

local function OnHit_Pills(inst, attacker, target)
    ImpactFx(inst, attacker, target)
    if attacker and attacker:IsValid() then
        if target and target:IsValid() and target.components.health and target.components.health.maxhealth then
            local multiplier = target:HasTag("player") and PILLS_PLAYER_HEAL or PILLS_HEAL
            target.components.health:DoDelta(target.components.health.maxhealth * multiplier)
            if target.components.combat and target.components.combat:TargetIs(attacker) then
                target.components.combat:SetTarget(nil)
            end
            if attacker.components.leader and target.components.follower and not attacker:HasTag("playerghost") then
                attacker:PushEvent("makefriend")
                attacker.components.leader:AddFollower(target)
                target.components.follower:AddLoyaltyTime(1440)
                target.components.follower.maxfollowtime = 1440
            end
        end
    end
    inst:Remove()
end

local function OnHit_Lunar(inst, attacker, target)
    ImpactFx(inst, attacker, target)
    if attacker and attacker:IsValid() then
        if target and target:IsValid() then
            if target._lunar_ammo_light == nil then
                inst.lighdebuff = SpawnPrefab("groundlight_fx")
                inst.lighdebuff.entity:SetParent(target.entity)
                inst.lighdebuff.Transform:SetPosition(0,0,0)
                inst.lighdebuff.Transform:SetScale(1.1, 1.1, 1.1)
                inst.lighdebuff.AnimState:PlayAnimation("meteorground_loop")
                inst.lighdebuff.AnimState:SetMultColour(1, 1, 1, 0.3)
                inst.lighdebuff.Light:SetFalloff(0.7)
                inst.lighdebuff.Light:SetIntensity(.7)
                inst.lighdebuff.Light:SetRadius(4)
                inst.lighdebuff.Light:SetColour(1,1,1)
                target._lunar_ammo_light = inst.lighdebuff
                setLunarAmmoLightTask(target)
            else
                setLunarAmmoLightTask(target)
            end
        end
    end
    inst:Remove()
end

local function OnHit_Shadow(inst, attacker, target)
    ImpactFx(inst, attacker, target)
    if attacker and attacker:IsValid() then
        if target and target:IsValid() and target._shadow_ammo then
            attacker.components.hunger:DoDelta(33)
            attacker.components.sanity:DoDelta(33)
            attacker.components.health:DoDelta(33)
        end
    end
    inst:Remove()
end

local function SpawnTallbird(inst, target)
    local pos = inst:GetPosition()
    if math.random() < .5 then
        local tallbird = chasni_spawnprefab("tallbird", pos.x, 0, pos.z)
        if tallbird and tallbird.components.combat and not tallbird.components.combat:TargetIs(target) then
            tallbird.components.combat:SetTarget(target)
        end
    end
end

local function OnHit_Egg(inst, attacker, target)
    ImpactFx(inst, attacker, target)
    if attacker and attacker:IsValid() then
        if target and target:IsValid() then
            SpawnTallbird(inst, target)
        end
    end
    inst:Remove()
end

local AREAATTACK_EXCLUDETAGS = { "INLIMBO", "notarget", "noattack", "invisible", "playerghost", "player" }
local function OnHit_Bomb(inst, attacker, target)
    ImpactFx(inst, attacker, target)
    if attacker and attacker:IsValid() then
        if target and target:IsValid() then
            attacker.components.combat:DoAreaAttack(inst, 5, inst, nil, nil, AREAATTACK_EXCLUDETAGS)
            local pos = Vector3(inst.Transform:GetWorldPosition())
            chasni_spawnprefab("explosivehit", pos.x, 0, pos.z, 1.5, 1.5, 1.5)
        end
    end
    inst:Remove()
end

local function OnMiss(inst, owner, target)
    inst:Remove()
end

local function projectile_fn(ammo_def)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    MakeProjectilePhysics(inst)

    inst.AnimState:SetBank("slingshotammo")
    inst.AnimState:SetBuild("chasni_slingshotammo")
    inst.AnimState:PlayAnimation("spin_loop", true)
    if ammo_def.name then
        inst.AnimState:OverrideSymbol("rock", "chasni_slingshotammo", ammo_def.name)
    end

    inst:AddTag("projectile")

    if ammo_def.tags then
        for _, tag in pairs(ammo_def.tags) do
            inst:AddTag(tag)
        end
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst.ammo_def = ammo_def

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(ammo_def.damage)
    inst.components.weapon:SetOnAttack(OnAttack)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(25)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(1.5)
    inst.components.projectile:SetOnPreHitFn(OnPreHit)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile.range = 30
    inst.components.projectile.has_damage_set = true

    return inst
end

local function inv_fn(ammo_def)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetBank("slingshotammo")
    inst.AnimState:SetBuild("chasni_slingshotammo")
    inst.AnimState:PlayAnimation("idle")
    if ammo_def.name then
        inst.AnimState:OverrideSymbol("rock", "chasni_slingshotammo", ammo_def.name)
    end

    inst:AddTag("molebait")
    inst:AddTag("slingshotammo")
    inst:AddTag("reloaditem_ammo")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("reloaditem")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.ELEMENTAL
    inst.components.edible.hungervalue = 1
    inst:AddComponent("tradable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_TINYITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(true)
    inst.components.inventoryitem.imagename = "chasni_ammo_"..ammo_def.name
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_ammo_"..ammo_def.name..".xml"

    inst:AddComponent("bait")
    MakeHauntableLaunch(inst)

    if ammo_def.onloadammo and ammo_def.onunloadammo then
        inst:ListenForEvent("ammoloaded", ammo_def.onloadammo)
        inst:ListenForEvent("ammounloaded", ammo_def.onunloadammo)
        inst:ListenForEvent("onremove", ammo_def.onunloadammo)
    end

    return inst
end

local ammo =
{
    {
        name = "bomb",
        onhit = OnHit_Bomb,
        damage = BOMB_DAMAGE,
    },
    {
        name = "egg",
        onhit = OnHit_Egg,
        damage = EGG_DAMAGE,
    },
    {
        name = "lunar",
        onhit = OnHit_Lunar,
        damage = GetDamage_Lunar,
    },
    {
        name = "pills",
        onhit = OnHit_Pills,
        damage = GetDamage_Pills,
    },
    {
        name = "shadow",
        onhit = OnHit_Shadow,
        damage = GetDamage_Shadow,
    },
}

local ammo_prefabs = {}
for _, v in ipairs(ammo) do
    local assets = { Asset("ANIM", "anim/chasni_slingshotammo.zip"), }
    table.insert(assets, Asset("ATLAS", "images/inventoryimages/chasni_ammo_"..v.name..".xml"))
    table.insert(assets, Asset("IMAGE", "images/inventoryimages/chasni_ammo_"..v.name..".tex"))
    table.insert(ammo_prefabs, Prefab("chasni_slingshotammo_"..v.name, function() return inv_fn(v) end, assets))

	local prefabs = { "shatter", }
    v.impactfx = "chasni_slingshotammo_hitfx_" .. v.name
    table.insert(prefabs, v.impactfx)
    table.insert(ammo_prefabs, Prefab("chasni_slingshotammo_"..v.name.."_proj", function() return projectile_fn(v) end, assets, prefabs))
end

return unpack(ammo_prefabs)