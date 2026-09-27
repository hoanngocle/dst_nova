local function ImpactFx(inst, attacker, target)
    if target and target:IsValid() and inst.data.impactfx then
        local impactfx = SpawnPrefab(inst.data.impactfx)

        if inst.data.scale then
            impactfx.Transform:SetScale(inst.data.scale, inst.data.scale, inst.data.scale)
        end
        impactfx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
end

local function OnHit(inst, attacker, target)
    if target and target:IsValid() and attacker and attacker:IsValid() then
        ImpactFx(inst, attacker, target)
    end
    inst:Remove()
end

local function OnHit_Bug(inst, attacker, target)
    if attacker and attacker:IsValid() and target and target:IsValid() and target.components.lootdropper then
        if target.components.lootdropper then
            local generatedloot = target.components.lootdropper:GenerateLoot()
            if #generatedloot > 0 then
                local lootprefab = generatedloot[math.random(#generatedloot)]
                if lootprefab then
                    local loot = SpawnPrefab(lootprefab)
                    if loot then
                        target.components.lootdropper:FlingItem(loot)
                    end
                end
            end
        end
    end
    OnHit(inst, attacker, target)
end

local function OnHit_Wool(inst, attacker, target)
    if attacker and attacker:IsValid() and target then
        if attacker.components.combat then
            local x, y, z = target.Transform:GetWorldPosition()
            chasni_spawnprefab("smallfx_ring", x, y, z)
            attacker.components.combat:DoAreaAttack(target, 5.5, nil, function(_target, _attacker)
                local leader = _attacker.components.follower and _attacker.components.follower:GetLeader()
                if leader == nil or _target == _attacker or leader.components.combat:IsAlly(_target) then
                    return false
                end
                return true
            end)
        end
    end
    OnHit(inst, attacker, target)
end

local function projectile_fn(data)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeProjectilePhysics(inst)

    inst.AnimState:SetBank(data.bank)
    inst.AnimState:SetBuild(data.build)
    inst.AnimState:PlayAnimation(data.anim, true)

    if data.cola then
        inst.AnimState:SetMultColour(data.colr, data.colg, data.colb, data.cola)
    end
    if data.scale then
        inst.Transform:SetScale(data.scale, data.scale, data.scale)
    end

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("projectile")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    if data.damage then
        inst.components.weapon:SetDamage(data.damage)
    end

    inst:AddComponent("projectile")
    inst.components.projectile:SetHoming(data.homing or false)
    inst.components.projectile:SetHitDist(1)
    inst.components.projectile:SetOnHitFn(data and data.onhit or OnHit)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetSpeed(data.spd or 6)
    if data.offsety then
        inst.components.projectile:SetLaunchOffset(Vector3(0, data.offsety, 0))
    end
    inst.components.projectile.range = 30
    inst.components.projectile.has_damage_set = data.damageset or false

    if data.taskdelay and data.taskfn then
        inst:DoTaskInTime(data.taskdelay, function()
            data.taskfn(inst)
        end)
    end
    inst.persists = false
    inst.data = data

    return inst
end

local projectiles =
{
    {
        name = "bug",
        onhit = OnHit_Bug,
        damage = 0,
        damageset = true,
        bank = "spider_spit",
        build = "spider_spit",
        anim = "idle",
        impactfx = "cckproj_water",
        homing = true,
        scale = 1,
        colr = 0,
        colg = 1,
        colb = 0.6,
        cola = 1,
        spd = 5,
    },
    {
        name = "crab",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "bubble",
        impactfx = "cckproj_water",
        homing = true,
    },
    {
        name = "dog",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "leafy",
        impactfx = "cckproj_water",
        homing = true,
    },
    {
        name = "dog_pink",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "leafy_pink",
        impactfx = "cckproj_water",
        homing = true,
    },
    {
        name = "slug_star",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "fur_yellow",
        impactfx = "cckproj_water",
        homing = true,
    },
    {
        name = "slug_xp",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "fur_blue",
        impactfx = "cckproj_water",
        homing = true,
    },
    {
        name = "wool",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "wool",
        impactfx = "cckproj_water",
        homing = true,
        spd = 15,
    },
    {
        name = "wool_big",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "wool",
        onhit = OnHit_Wool,
        impactfx = "cckproj_water",
        homing = true,
        scale = 3,
        spd = 8,
    },
    {
        name = "driller",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "goo",
        scale = 3,
        impactfx = "cckproj_water",
        homing = true,
    },
    {
        name = "fish_wet",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "fish_blue",
        impactfx = "cckproj_water",
        spd = 15,
        homing = true,
    },
    {
        name = "fish_burn",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "fish_pink",
        impactfx = "cckproj_water",
        spd = 15,
        homing = true,
    },
    {
        name = "grass",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "grass",
        impactfx = "cckproj_water",
        homing = true,
    },
    {
        name = "rock",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "rock",
        impactfx = "cckproj_water",
        homing = true,
    },
    {
        name = "raptor",
        bank = "chasni_projectile_galaxy",
        build = "chasni_projectile_galaxy",
        anim = "open_loop",
        scale = 0.6,
        impactfx = "cckproj_water",
        offsety = 1,
        homing = false,
        spd = 9,
    },
    --{
    --    name = "slug_xp",
    --    bank = "chasni_projectile_neuron",
    --    build = "chasni_projectile_neuron",
    --    anim = "travel_loop",
    --    impactfx = "chasni_projectile_neuron_impact",
    --},
    {
        name = "worm",
        bank = "chasni_projectile_laser",
        build = "chasni_projectile_laser",
        anim = "glow_comp",
        offsety = 0.5,
        impactfx = "chasni_projectile_laser_impact2",
    },
    {
        name = "elecfish",
        bank = "chasni_projectile_neuron_yellow",
        build = "chasni_projectile_neuron_yellow",
        anim = "travel_loop",
        offsety = 1.5,
        impactfx = "chasni_projectile_neuron_yellow_impact",
    },
    {
        name = "fugu",
        bank = "barnacle_burr",
        build = "barnacle_burr",
        anim = "spin_loop",
        scale = 0.6,
        spd = 12,
        offsety = 1,
        impactfx = "waterplant_burr_burst",
    },
    {
        name = "seahorse",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "scale",
        impactfx = "cckproj_water",
        homing = true,
    },
    {
        name = "snail",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "airpuff",
        impactfx = "cckproj_water",
        spd = 4,
        homing = true,
    },
    {
        name = "snail_black",
        bank = "chasni_projectile",
        build = "chasni_projectile",
        anim = "airpuff",
        impactfx = "cckproj_water",
        spd = 4,
        colr = 0.1,
        colg = 0.1,
        colb = 0.1,
        cola = 1,
        homing = true,
    },
}
local proj_prefab = {}
for _, v in ipairs(projectiles) do
    local assets = { Asset("ANIM", "anim/"..v.build..".zip"), }
    local prefabs = { "shatter", v.impactfx }
    table.insert(proj_prefab, Prefab("chasni_critter_"..v.name.."_proj", function() return projectile_fn(v) end, assets, prefabs))
end

return unpack(proj_prefab)