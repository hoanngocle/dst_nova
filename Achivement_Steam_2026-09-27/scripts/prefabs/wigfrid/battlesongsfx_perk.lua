local assets =
{
    Asset("ANIM", "anim/chasni_alterguardian_meteor.zip")
}

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

    inst:DoTaskInTime(FRAMES, function(_inst)
        local pos = Vector3(_inst.Transform:GetWorldPosition())
        chasni_spawnprefab("lucent_beamfx", pos.x, pos.y, pos.z)
    end)

    inst:DoTaskInTime(1, function(_inst)
        _inst.SoundEmitter:PlaySound("chasni_song/chasni_song/lucentbeam", "lucentbeam")
        local pos = Vector3(_inst.Transform:GetWorldPosition())
        chasni_spawnprefab("chasni_halloween_moonpuff", pos.x, pos.y, pos.z)
        local nottargettags = { "playerghost", "INLIMBO", "notarget", "noattack", "invisible", "lunar_aligned" }
        if not TheNet:GetPVPEnabled() then
            table.insert(nottargettags, "player")
            table.insert(nottargettags, "companion")
            table.insert(nottargettags, "ally")
        end
        local targets = TheSim:FindEntities(pos.x, pos.y, pos.z, 2.5, nil, nottargettags)
        for i, v in ipairs(targets) do
            if _inst._singer and _inst._singer.components.combat and v:IsValid() and _inst._singer ~= v then
                if v.components.combat and v.components.health and not v.components.health:IsDead() then
                    if v.components.combat:CanBeAttacked() and not _inst._singer.components.combat:IsAlly(v) then
                        local spdmg = {}
                        spdmg["planar"] = 25
                        v.components.combat:GetAttacked(_inst._singer, 0, nil, nil, spdmg)
                    end
                end
            end
        end
    end)
    inst:DoTaskInTime(3, inst.Remove)

    inst.persists = false
    inst._singer = nil

    return inst
end

return Prefab("lucentbeam", fn, assets)
