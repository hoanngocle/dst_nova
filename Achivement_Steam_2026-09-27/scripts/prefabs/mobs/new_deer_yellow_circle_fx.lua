local assets =
{
    Asset("ANIM", "anim/explode.zip")
}

local prefabs =
{
    "deer_yellow_circle_explode",
    "chasni_laserexplosion",
}

local function TriggerFX(inst) end

-------------------------------------------------------------------------------

local function explodefn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:SetCanSleep(false)

    inst.AnimState:SetBank("explode")
    inst.AnimState:SetBuild("explode")
    inst.AnimState:PlayAnimation("small_firecrackers")

    inst.Transform:SetFourFaced()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/mound_explode")
    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

local EXCLUDE_TAGS = { "newklaus", "deer", "deergemresistance", "playerghost", "INLIMBO", "notarget", "noattack", "invisible" }
local VOKER_EXCLUDE_TAGS = { "injoker", "playerghost", "INLIMBO", "notarget", "noattack", "invisible" }
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:SetCanSleep(false)

    inst.Transform:SetFourFaced()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst.killed = false
    inst.voker = nil
    inst.burstprefab = "sinkhole_spawn_fx_1"
    inst.fxprefabs = { "sinkhole_spawn_fx_2" }
    inst.TriggerFX = TriggerFX

    inst:DoTaskInTime(.1, function(inst)
        local pos = Vector3(inst.Transform:GetWorldPosition())
        chasni_spawnprefab(inst.voker and "voker_light" or "fx_book_light_upgraded", pos.x, pos.y, pos.z, 0.25, 1, 0.25)
    end)

    inst:DoTaskInTime(2, function(inst)
        if inst.voker then
            inst:DoTaskInTime(0.5, function(inst)
                local pos = Vector3(inst.Transform:GetWorldPosition())
                local expl = chasni_spawnprefab("chasni_laserexplosion", pos.x, pos.y, pos.z)
                expl.Transform:SetScale(0.5,0.5,0.5)
                expl.SoundEmitter:PlaySound("chasjoker/chasni_invoker/sunstike2", nil, 0.3)
                local targets = TheSim:FindEntities(pos.x, pos.y, pos.z, 2, nil, VOKER_EXCLUDE_TAGS)
                for i, v in ipairs(targets) do
                    if v:IsValid() then
                        if v.components.combat and v.components.health and not v.components.health:IsDead() then
                            if v.components.combat:CanBeAttacked() then
                                v.components.combat:GetAttacked(inst.voker, inst.vokerdamage or 1)
                            end
                        end
                    end
                end
            end)
        else
            local pos = Vector3(inst.Transform:GetWorldPosition())
            chasni_spawnprefab("deer_yellow_circle_explode", pos.x -2, pos.y, pos.z)
            chasni_spawnprefab("deer_yellow_circle_explode", pos.x + 2, pos.y, pos.z)
            chasni_spawnprefab("deer_yellow_circle_explode", pos.x, pos.y, pos.z + 2)
            chasni_spawnprefab("deer_yellow_circle_explode", pos.x, pos.y, pos.z - 2)
            local targets = TheSim:FindEntities(pos.x, pos.y, pos.z, 4, nil, EXCLUDE_TAGS)
            for i, v in ipairs(targets) do
                if v:IsValid() then
                    if v.components.combat and v.components.health and not v.components.health:IsDead() then
                        if v.components.combat:CanBeAttacked() then
                            v.components.combat:GetAttacked(inst, 69)
                        end
                    end
                end
            end
        end
    end)
    inst:DoTaskInTime(3, inst.Remove)

    return inst
end

return Prefab("deer_yellow_circle_explode", explodefn, assets),
Prefab("deer_yellow_circle", fn, {}, prefabs)
