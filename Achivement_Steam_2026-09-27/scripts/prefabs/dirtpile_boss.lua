local assets =
{
    Asset("ANIM", "anim/boss_koalefant_tracks.zip"),
    Asset("ANIM", "anim/smoke_puff_small.zip"),
}

local prefabs =
{
    "small_puff"
}

local function GetVerb()
    return "INVESTIGATE"
end

local function OnInvestigated(inst, doer)
    local pt = Vector3(inst.Transform:GetWorldPosition())

    local bosshunter = TheWorld.components.bosshunter
    if bosshunter then
        bosshunter:OnDirtInvestigated(pt, doer)
    end

    local spawnprefab
    if TheWorld.state.iswinter and TheWorld.state.issnowing and math.random() < TheWorld.state.precipitationrate then
        spawnprefab = "gronehog_snow"
    elseif TheWorld.state.isspring and TheWorld.state.israining and math.random() < TheWorld.state.precipitationrate then
        spawnprefab = "chasni_plasmablob"
    elseif TheWorld.components.sandstorms and TheWorld.components.sandstorms:IsInSandstorm(doer) and math.random() < 0.6 then
        spawnprefab = "gronehog_sand"
    end
    if spawnprefab then
        local ambush = SpawnPrefab(spawnprefab)
        if ambush then
            ambush.Transform:SetPosition(pt:Get())
            if ambush.sg:HasState("spawn") then ambush.sg:GoToState("spawn") end
        end
    end
    SpawnPrefab("small_puff").Transform:SetPosition(pt:Get())
    inst:Remove()
end

local function create()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("dirtpile")

    inst.AnimState:SetBank("boss_track")
    inst.AnimState:SetBuild("boss_koalefant_tracks")
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:PlayAnimation("idle_pile")

    inst.GetActivateVerb = GetVerb

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnInvestigated
    inst.components.activatable.inactive = true

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        OnInvestigated(inst, haunter)
        return true
    end)

    inst.persists = false
    return inst
end

return Prefab("dirtpile_boss", create, assets, prefabs)