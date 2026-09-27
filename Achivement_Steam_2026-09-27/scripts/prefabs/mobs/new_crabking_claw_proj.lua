local ELECTRIC_DAMAGE = chasni_getmobconfig("ckc", "EDMG") or 17
local WATER_DAMAGE = chasni_getmobconfig("ckc", "WDMG") or 85
local FIRE_DAMAGE = chasni_getmobconfig("ckc", "FDMG") or 51
local ICE_DAMAGE = chasni_getmobconfig("ckc", "IDMG") or 34
local LUNAR_DAMAGE = chasni_getmobconfig("ckc", "LDMG") or 68
local SHADOW_DAMAGE = chasni_getmobconfig("ckc", "SDMG") or 68

local function ImpactFx(inst, attacker, target)
    if target and target:IsValid() and inst.data.impactfx then
        local impactfx = SpawnPrefab(inst.data.impactfx)

        if inst.data.scale then
            impactfx.Transform:SetScale(inst.data.scale, inst.data.scale, inst.data.scale)
        end
        impactfx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
end

local function OnAttack(inst, attacker, target)
    if target and target:IsValid() and attacker and attacker:IsValid() then
        if inst.data and inst.data.onhit then
            inst.data.onhit(inst, attacker, target)
        end
        ImpactFx(inst, attacker, target)
    end
end

local function OnHit(inst, attacker, target)
    if target and target:IsValid() and target.components.combat then
        target.components.combat:RemoveShouldAvoidAggro(attacker)
    end
    if inst.data.name ~= "electric" then
        inst:Remove()
    end
end

local function OnHit_Fire(inst, attacker, target)
    if attacker and attacker:IsValid() and target and target:IsValid() then
        if target.components.burnable and not target.components.burnable:IsBurning() then
            if target.components.fueled == nil or (target.components.fueled.fueltype ~= FUELTYPE.BURNABLE and target.components.fueled.secondaryfueltype ~= FUELTYPE.BURNABLE) then
                if target.components.burnable.canlight or target.components.combat then
                    target.components.burnable:Ignite(true, attacker)
                end
            elseif target.components.fueled.accepting then
                local fuel = SpawnPrefab("cutgrass")
                if fuel then
                    if fuel.components.fuel and fuel.components.fuel.fueltype == FUELTYPE.BURNABLE then
                        target.components.fueled:TakeFuelItem(fuel)
                    else
                        fuel:Remove()
                    end
                end
            end
        end
    end
end

local function OnHit_Ice(inst, attacker, target)
    if attacker and attacker:IsValid() and target and target:IsValid() then
        if target.components.freezable then
            target.components.freezable:AddColdness(1)
            target.components.freezable:SpawnShatterFX()
        end
    end
end

local function OnHit_Water(inst, attacker, target)
    if attacker and attacker:IsValid() and target and target:IsValid() then
        local x, y, z = target.Transform:GetWorldPosition()
        chasni_spawnprefab("crab_king_waterspout", x, y, z, 0.5, 0.5, 0.5);
        inst.components.wateryprotection:SpreadProtectionAtPoint(x, y, z)
    end
end

local BOUNCE_RANGE = 12
local BOUNCE_SPEED = 5
local BOUNCE_MUST_TAGS = { "_combat" }
local BOUNCE_NO_TAGS = { "INLIMBO", "wall", "notarget", "crabking_claw", "crabking", "invisible", "noattack", "hiding" }
local function TryBounce(inst, x, z, attacker, target)
    if attacker.components.combat == nil or not attacker:IsValid() then
        inst:Remove()
        return
    end
    local newtarget, newrecentindex, newhostile
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, BOUNCE_RANGE, BOUNCE_MUST_TAGS, BOUNCE_NO_TAGS)) do
        if v ~= target and v.entity:IsVisible() and not (v.components.health and v.components.health:IsDead()) and attacker.components.combat:CanTarget(v) and not attacker.components.combat:IsAlly(v) and v:GetDistanceSqToPoint(Vector3(x, 0, z)) > 36 then
            local vhostile = v:HasTag("hostile")
            local vrecentindex
            if inst.recenttargets then
                for i1, v1 in ipairs(inst.recenttargets) do
                    if v == v1 then
                        vrecentindex = i1
                        break
                    end
                end
            end
            if newtarget == nil then
                newtarget = v
                newrecentindex = vrecentindex
                newhostile = vhostile
            elseif vhostile and not newhostile then
                newtarget = v
                newrecentindex = vrecentindex
                newhostile = vhostile
            elseif vhostile or not newhostile then
                if vrecentindex == nil then
                    if newrecentindex or (newtarget.prefab ~= target.prefab and v.prefab == target.prefab) then
                        newtarget = v
                        newrecentindex = vrecentindex
                        newhostile = vhostile
                    end
                elseif newrecentindex and vrecentindex < newrecentindex then
                    newtarget = v
                    newrecentindex = vrecentindex
                    newhostile = vhostile
                end
            end
        end
    end

    if newtarget then
        inst.Physics:Teleport(x, 0, z)
        inst:Show()
        inst.components.projectile:SetSpeed(BOUNCE_SPEED)
        if inst.recenttargets then
            if newrecentindex then
                table.remove(inst.recenttargets, newrecentindex)
            end
            table.insert(inst.recenttargets, target)
        else
            inst.recenttargets = { target }
        end
        inst.components.projectile:SetBounced(true)
        inst.components.projectile.overridestartpos = Vector3(x, 0, z)
        inst.components.projectile:Throw(attacker, newtarget, attacker)
    else
        inst:Remove()
    end
end

local function OnHit_Electic(inst, attacker, target)
    if attacker and attacker:IsValid() and target and target:IsValid() then
        inst.Physics:Stop()
        inst:Hide()
        local x, _, z = target.Transform:GetWorldPosition()
        inst:DoTaskInTime(.1, TryBounce, x, z, attacker, target)
    end
end

local function OnHit_Shadow(inst, attacker, target)
    if attacker and attacker:IsValid() and target and target:IsValid() then
        if inst:IsOnOcean() then
            SpawnPrefab("ink_puddle_water").Transform:SetPosition(inst.Transform:GetWorldPosition())
        else
            SpawnPrefab("ink_puddle_land").Transform:SetPosition(inst.Transform:GetWorldPosition())
        end

        if target.components.inkable then
            target.components.inkable:Ink()
        end
    end
end

local function OnHit_Lunar(inst, attacker, target)
    if attacker and attacker:IsValid() and target and target:IsValid() and target.components.health then
        target.components.health:DoDelta(LUNAR_DAMAGE)
    end
end

local function OnMiss(inst, owner, target)
    inst:Remove()
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

    inst:AddTag("projectile")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst.data = data

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(data.damage)
    inst.components.weapon:SetOnAttack(OnAttack)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(15)
    inst.components.projectile:SetHoming(data.name == "electric")
    if data.name == "electric" then
        inst.components.projectile:SetStimuli("electric")
    end
    inst.components.projectile:SetHitDist(1.5)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile.range = 30
    inst.components.projectile.has_damage_set = true

    if data.name == "water" then
        inst:AddComponent("wateryprotection")
        inst.components.wateryprotection.addwetness = 30
        inst.components.wateryprotection.protection_dist = TUNING.TRIDENT.SPELL.RADIUS * 0.7
    end
    return inst
end

local projectiles =
{
    {
        name = "fire",
        onhit = OnHit_Fire,
        damage = FIRE_DAMAGE,
        bank = "fireball_fx",
        build = "fireball_2_fx",
        anim = "idle_loop",
        impactfx = "fireball_hit_fx",
        scale = 0.6,
    },
    {
        name = "water",
        onhit = OnHit_Water,
        damage = WATER_DAMAGE,
        bank = "gooball_fx",
        build = "gooball_fx",
        anim = "idle_loop",
        impactfx = "cckproj_water",
        scale = 0.8,
        colr = 0.2,
        colg = 0.4,
        colb = 1,
        cola = 1,
    },
    {
        name = "ice",
        onhit = OnHit_Ice,
        damage = ICE_DAMAGE,
        bank = "projectile",
        build = "staff_projectile",
        anim = "ice_spin_loop",
        scale = 1.3,
    },
    {
        name = "electric",
        onhit = OnHit_Electic,
        damage = ELECTRIC_DAMAGE,
        bank = "lavaarena_arcane_orb",
        build = "lavaarena_arcane_orb",
        anim = "idle",
        impactfx = "cckproj_electric",
    },
    {
        name = "lunar",
        onhit = OnHit_Lunar,
        damage = LUNAR_DAMAGE,
        bank = "brilliance_projectile_fx",
        build = "brilliance_projectile_fx",
        anim = "idle_loop",
        impactfx = "cckproj_lunar",
        scale = 0.85,
        colr = 0.6,
        colg = 1,
        colb = 0.8,
        cola = 1,
    },
    {
        name = "shadow",
        onhit = OnHit_Shadow,
        damage = SHADOW_DAMAGE,
        bank = "brilliance_projectile_fx",
        build = "brilliance_projectile_fx",
        anim = "idle_loop",
        impactfx = "cckproj_shadow",
        scale = 0.85,
        colr = 0,
        colg = 0,
        colb = 0,
        cola = 1,
    },
}

local proj_prefab = {}
for _, v in ipairs(projectiles) do
    local assets = { Asset("ANIM", "anim/"..v.build..".zip"), }
    local prefabs = { "shatter", v.impactfx }
    table.insert(proj_prefab, Prefab("chasni_crabking_claw_"..v.name.."_proj", function() return projectile_fn(v) end, assets, prefabs))
end

return unpack(proj_prefab)