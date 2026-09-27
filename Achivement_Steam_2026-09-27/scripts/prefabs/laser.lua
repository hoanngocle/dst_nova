local assets =
{
    Asset("ANIM", "anim/laser_hit_sparks_fx.zip"),
}

local assets_scorch =
{
    Asset("ANIM", "anim/laser_burntground.zip"),
}

local assets_trail =
{
    Asset("ANIM", "anim/laser_smoke_fx.zip"),
}

local prefabs =
{
    "chasni_laserscorch",
    "chasni_lasertrail",
    "chasni_laserhit",
}

local LAUNCH_SPEED = .2
local RADIUS = 1.7
local LASER_DAMAGE = 20

local function SetLightRadius(inst, radius)
    inst.Light:SetRadius(radius)
end

local function DisableLight(inst)
    inst.Light:Enable(false)
end
local function DoDamage(inst, targets, skiptoss, player)
    inst.task = nil

    local x, y, z = inst.Transform:GetWorldPosition()
    if inst.AnimState then
        inst.AnimState:PlayAnimation("hit_"..tostring(math.random(5)))
        inst:Show()
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, inst.Remove)

        inst.Light:Enable(true)
        inst:DoTaskInTime(4 * FRAMES, SetLightRadius, .5)
        inst:DoTaskInTime(5 * FRAMES, DisableLight)

        SpawnPrefab("chasni_laserscorch").Transform:SetPosition(x, 0, z)
        local fx = SpawnPrefab("chasni_lasertrail")
        fx.Transform:SetPosition(x, 0, z)
        fx:FastForward(GetRandomMinMax(.3, .7))
    else
        inst:DoTaskInTime(2 * FRAMES, inst.Remove)
    end
    inst.components.combat.ignorehitrange = true
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, RADIUS + 3, nil, { "laser", "DECOR", "INLIMBO", "FX", "NOCLICK" })) do
        if not targets[v] and v:IsValid() and not v:IsInLimbo() and not (v.components.health and v.components.health:IsDead()) and not v:HasTag("laser_immune") and not (player == v) then
            player = player or inst
            local vradius = 0
            if v.Physics then
                vradius = v.Physics:GetRadius()
            end

            local range = RADIUS + vradius
            if v:GetDistanceSqToPoint(Vector3(x, y, z)) < range * range then
                if chasni_entWorkableIsCollapsible(v) then
                    targets[v] = true
                    v:DoTaskInTime(0.2, function() 
                        if v.components.workable then
                            v.components.workable:Destroy(player) 
                        end
                     end)
                    if v:IsValid() and v:HasTag("stump") then
                        v:Remove()
                    end
                elseif v.components.pickable and v.components.pickable:CanBePicked() and not v:HasTag("intense") then
                    targets[v] = true
                    local num = v.components.pickable.numtoharvest or 1
                    local product = v.components.pickable.product
                    local x1, y1, z1 = v.Transform:GetWorldPosition()
                    v.components.pickable:Pick(player)
                    if product and num > 0 then
                        for _ = 1, num do
                            local loot = SpawnPrefab(product)
                            loot.Transform:SetPosition(x1, 0, z1)
                            skiptoss[loot] = true
                            targets[loot] = true
                        end
                    end
                elseif v.components.health then
                    player.components.combat:DoAttack(v)                
                    if v:IsValid() then
                        if not v.components.health or not v.components.health:IsDead() then
                            if v.components.freezable then
                                if v.components.freezable:IsFrozen() then
                                    v.components.freezable:Unfreeze()
                                elseif v.components.freezable.coldness > 0 then
                                    v.components.freezable:AddColdness(-2)
                                end
                            end
                        end
                    end                   
                end
                if v:IsValid() and v.AnimState then
                    SpawnPrefab("chasni_laserhit"):SetTarget(v)
                end

            end
        end
    end
    inst.components.combat.ignorehitrange = false
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, RADIUS + 3, { "_inventoryitem" }, { "locomotor", "INLIMBO" })) do
        if not skiptoss[v] then
            local radius = 0
            if v.Physics then
                radius = v.Physics:GetRadius()
            end            
            local range = RADIUS + radius
            if v:GetDistanceSqToPoint(Vector3(x, y, z) ) < range * range then
                if v.components.mine then
                    targets[v] = true
                    skiptoss[v] = true
                    v.components.mine:Deactivate()
                end
                if not v.components.inventoryitem.nobounce and v.Physics and v.Physics:IsActive() then
                    targets[v] = true
                    skiptoss[v] = true
                    Launch(v, inst, LAUNCH_SPEED)
                end
            end
        end
    end
end

local function Trigger(inst, delay, targets, skiptoss)
    if inst.task then
        inst.task:Cancel()
        if (delay or 0) > 0 then
            inst.task = inst:DoTaskInTime(delay, DoDamage, targets or {}, skiptoss or {})
        else
            DoDamage(inst, targets or {}, skiptoss or {})
        end
    end
end

local function TriggerPlayer(inst, delay, targets, skiptoss, player)
    if inst.task then
        inst.task:Cancel()
        if (delay or 0) > 0 then
            inst.task = inst:DoTaskInTime(delay, DoDamage, targets or {}, skiptoss or {}, player)
        else
            DoDamage(inst, targets or {}, skiptoss or {}, player)
        end
    end
end

local function KeepTargetFn()
    return false
end

local function common_fn(isempty)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
	
    if not isempty then
        inst.entity:AddAnimState()
        inst.AnimState:SetBank("laser_hits_sparks")
        inst.AnimState:SetBuild("laser_hit_sparks_fx")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)

        inst.entity:AddLight()
        inst.Light:SetIntensity(.6)
        inst.Light:SetRadius(1)
        inst.Light:SetFalloff(.7)
        inst.Light:SetColour(1, .2, .3)
        inst.Light:Enable(false)
    end

    inst:Hide()

    inst:AddTag("notarget")
    inst:AddTag("hostile")
    inst:AddTag("laser")

    inst:SetPrefabNameOverride("deerclops")

    inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end	

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(LASER_DAMAGE)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst.task = inst:DoTaskInTime(0, inst.Remove)
    inst.Trigger = Trigger
    inst.persists = false

    return inst
end

local function fn()
    local inst = common_fn(false)
    inst.Light:Enable(false)
    return inst
end

local function playerlaserfn()
    local inst = common_fn(false)
    inst.Light:Enable(false)
    inst.Trigger = TriggerPlayer
    return inst
end

local function emptyfn()
    return common_fn(true)
end

local function playeremptyfn()
    local inst = common_fn(true)
    inst.Trigger = TriggerPlayer
    return inst
end

local SCORCH_RED_FRAMES = 20
local SCORCH_DELAY_FRAMES = 40
local SCORCH_FADE_FRAMES = 15

local function Scorch_OnFadeDirty(inst)
    if inst._fade:value() > SCORCH_FADE_FRAMES + SCORCH_DELAY_FRAMES then
        local k = (inst._fade:value() - SCORCH_FADE_FRAMES - SCORCH_DELAY_FRAMES) / SCORCH_RED_FRAMES
        inst.AnimState:OverrideMultColour(1, 1, 1, 1)
        inst.AnimState:SetHighlightColour(k, 0, 0, 0)
    elseif inst._fade:value() >= SCORCH_FADE_FRAMES then
        inst.AnimState:OverrideMultColour(1, 1, 1, 1)
        inst.AnimState:SetHighlightColour()
    else
        local k = inst._fade:value() / SCORCH_FADE_FRAMES
        k = k * k
        inst.AnimState:OverrideMultColour(k, k, k, k)
        inst.AnimState:SetHighlightColour()
    end
end

local function Scorch_OnUpdateFade(inst)
    if inst._fade:value() > 1 then
        inst._fade:set_local(inst._fade:value() - 1)
        Scorch_OnFadeDirty(inst)
    elseif TheWorld.ismastersim then
        inst:Remove()
    elseif inst._fade:value() > 0 then
        inst._fade:set_local(0)
        inst.AnimState:OverrideMultColour(0, 0, 0, 0)
    end
end

local function scorchfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("laser_burntground")
    inst.AnimState:SetBank("burntground")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst._fade = net_byte(inst.GUID, "deerclops_laserscorch._fade", "fadedirty")
    inst._fade:set(SCORCH_RED_FRAMES + SCORCH_DELAY_FRAMES + SCORCH_FADE_FRAMES)

    inst:DoPeriodicTask(0, Scorch_OnUpdateFade)
    Scorch_OnFadeDirty(inst)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst:ListenForEvent("fadedirty", Scorch_OnFadeDirty)

        return inst
    end

    inst.Transform:SetRotation(math.random() * 360)
    inst.persists = false

    return inst
end

local function FastForwardTrail(inst, pct)
    if inst._task then
        inst._task:Cancel()
    end
    local len = inst.AnimState:GetCurrentAnimationLength()
    pct = math.clamp(pct, 0, 1)
    inst.AnimState:SetTime(len * pct)
    inst._task = inst:DoTaskInTime(len * (1 - pct) + 2 * FRAMES, inst.Remove)
end

local function trailfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("laser_smoke_fx")
    inst.AnimState:SetBuild("laser_smoke_fx")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetAddColour(1, 0, 0, 0)
    inst.AnimState:SetMultColour(1, 0, 0, 1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst._task = inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, inst.Remove)

    inst.FastForward = FastForwardTrail

    return inst
end

local function OnRemoveHit(inst)
    if inst.target and inst.target:IsValid() then
        if inst.target.components.colouradder == nil then
            if inst.target.components.freezable then
                inst.target.components.freezable:UpdateTint()
            else
                inst.target.AnimState:SetAddColour(0, 0, 0, 0)
            end
        end
        if inst.target.components.bloomer == nil then
            inst.target.AnimState:ClearBloomEffectHandle()
        end
    end
end

local function UpdateHit(inst, target)
    if target:IsValid() then
        local oldflash = inst.flash
        inst.flash = math.max(0, inst.flash - .075)
        if inst.flash > 0 then
            local c = math.min(1, inst.flash)
            if target.components.colouradder then
                target.components.colouradder:PushColour(inst, c, 0, 0, 0)
            else
                target.AnimState:SetAddColour(c, 0, 0, 0)
            end
            if inst.flash < .3 and oldflash >= .3 then
                if target.components.bloomer then
                    target.components.bloomer:PopBloom(inst)
                else
                    target.AnimState:ClearBloomEffectHandle()
                end
            end
            return
        end
    end
    inst:Remove()
end

local function SetTarget(inst, target)
    if inst.inittask then
        inst.inittask:Cancel()
        inst.inittask = nil

        inst.target = target
        inst.OnRemoveEntity = OnRemoveHit

        if target.components.bloomer then
            target.components.bloomer:PushBloom(inst, "shaders/anim.ksh", -1)
        else
            target.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        end
        inst.flash = .8 + math.random() * .4
        inst:DoPeriodicTask(0, UpdateHit, nil, target)
        UpdateHit(inst, target)
    end
end

local function hitfn()
    local inst = CreateEntity()

    inst:AddTag("CLASSIFIED")
    inst.persists = false

    inst.SetTarget = SetTarget
    inst.inittask = inst:DoTaskInTime(0, inst.Remove)

    return inst
end

return
Prefab("chasni_laser", fn, assets, prefabs),
Prefab("chasni_playerlaser", playerlaserfn, assets, prefabs),
Prefab("chasni_laserempty", emptyfn, assets, prefabs),
Prefab("chasni_playerlaserempty", playeremptyfn, assets, prefabs),
Prefab("chasni_laserscorch", scorchfn, assets_scorch),
Prefab("chasni_lasertrail", trailfn, assets_trail),
Prefab("chasni_laserhit", hitfn)
