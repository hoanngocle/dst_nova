local assets =
{
    Asset("ANIM", "anim/lava_pool.zip"),
}

local prefabs =
{
    "ash",
    "rocks",
    "charcoal",
}

local function OnExtinguish(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local radius = 1
    local things = {"rocks", "ash", "charcoal"}
    for i = 1, #things, 1 do
        local thing = SpawnPrefab(things[i])
        thing.Transform:SetPosition(x + radius * UnitRand(), y, z + radius * UnitRand())
    end

    inst.AnimState:ClearBloomEffectHandle()
    inst:Remove()
end

local function OnUpdateFueled(inst)
    if inst.components.burnable then
        inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
    end
end

local function OnFuelChange(newsection, oldsection, inst)
    if newsection == 0 then
        inst.components.burnable:Extinguish()
    else
        if not inst.components.burnable:IsBurning() then
            inst.components.burnable:Ignite(nil, inst)
        end

        inst.components.burnable:SetFXLevel(newsection, inst.components.fueled:GetSectionPercent())
        local ranges = {1, 1, 1, 1}
        local output = {2, 5, 5, 10}
        inst.components.propagator.propagaterange = ranges[newsection]
        inst.components.propagator.heatoutput = output[newsection]
    end
end

local function OnCollide(inst, other)
    if other and
            other:IsValid() and
            inst:IsValid() and
            other.components.burnable and
            other.components.fueled == nil then
        other.components.burnable:Ignite(true, inst)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    MakeObstaclePhysics(inst, 1)

    inst:AddTag("fire")
    inst:AddTag("lavapool")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("birdblocker")

    inst.AnimState:SetBank("lava_pool")
    inst.AnimState:SetBuild("lava_pool")
    inst.AnimState:PlayAnimation("dump")
    inst.AnimState:PushAnimation("idle_loop")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.no_wet_prefix = true

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("cooker")
    inst:AddComponent("burnable")
    inst.components.burnable:Ignite()
    inst:ListenForEvent("onextinguish", OnExtinguish)

    inst:AddComponent("propagator")
    inst.components.propagator.damagerange = 3
    inst.components.propagator.propagaterange = 3
    inst.components.propagator.damages = true
    inst.components.propagator:StartSpreading()

    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = 1
    inst.components.fueled:InitializeFuelLevel(90)
    inst.components.fueled:SetSections(4)
    inst.components.fueled.rate = 1
    inst.components.fueled:SetUpdateFn(OnUpdateFueled)
    inst.components.fueled:SetSectionCallback(OnFuelChange)

    inst:AddComponent("heater")
    inst.components.heater.heat = 150

    inst.Physics:SetCollisionCallback(OnCollide)

    return inst
end

return Prefab("chasni_ancientherald_lavapool", fn, assets, prefabs)
