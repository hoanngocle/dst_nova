local assets =
{
    Asset("ANIM", "anim/chasni_botbomb.zip"),
}

local function OnIgniteFn(inst)
    inst._fx = SpawnPrefab("torchfire")
    inst._fx.entity:SetParent(inst.entity)
    inst._fx.entity:AddFollower()
    inst._fx.Follower:FollowSymbol(inst.GUID, "smallbomb", 0, 0, 0)
    inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_fuse_LP", "hiss")
end

local function OnExplodeFn(inst)
    if inst.components.explosive then
        local attacker = inst.components.explosive.attacker or inst.components.explosive.pvpattacker
        if attacker then
            attacker.components.combat:DoAreaAttack(inst, inst.components.explosive.explosiverange, nil, function(target, _attacker)
                if target == _attacker or _attacker.components.combat:IsAlly(target) then
                    return false
                end
                local leader = _attacker.components.follower and _attacker.components.follower:GetLeader()
                if leader and target and target.components.combat and not target.components.combat:TargetIs(leader) and target.components.combat:CanTarget(leader) then
                    target.components.combat:SetTarget(leader)
                end
                return true
            end)
        end
    end

    inst.SoundEmitter:KillSound("hiss")
    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = chasni_spawnprefab("explode_small_slurtlehole", x, y, z)
    if fx ~= nil and inst.explosionscale ~= nil then
        fx.Transform:SetScale(inst.explosionscale, inst.explosionscale, inst.explosionscale)
    end
end

local function Explode(inst)
    inst.components.explosive:OnBurnt()
end

local function MakeBomb(name, scale, explosion_scale, explosion_range, fuse_time)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("chasni_botbomb")
        inst.AnimState:SetBuild("chasni_botbomb")
        inst.AnimState:PlayAnimation("idle", true)

        inst.Transform:SetScale(scale, scale, scale)

        inst:AddTag("explosive")
        inst:AddTag("scarytoprey")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.explosionscale = explosion_scale

        inst:AddComponent("explosive")
        inst.components.explosive:SetOnExplodeFn(OnExplodeFn)
        inst.components.explosive.explosivedamage = 0
        inst.components.explosive.lightonexplode = false
        inst.components.explosive.explosiverange = explosion_range 

        inst:DoTaskInTime(0, OnIgniteFn)
        inst:DoTaskInTime(fuse_time, Explode)

        inst.persists = false

        return inst
    end

    return Prefab(name, fn, assets)
end

return
MakeBomb("chasni_botbomb",    0.80, 1.0, 3, 2.0),
MakeBomb("chasni_botbombbig", 1.25, 3.0, 5, 1)