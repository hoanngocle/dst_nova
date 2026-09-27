local function MakeFX(name, bank, build, anim, loop, removeFX, sound, finaloffset, ground, scale)
    local assets =
    {
        Asset("ANIM", "anim/"..bank..".zip"),
    }

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddFollower()

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)
        inst.AnimState:PushAnimation(loop, true)
        if ground then
            inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        end
        if scale then
            inst.Transform:SetScale(scale, scale, scale)
        end

        inst:AddTag("FX")
        inst:AddTag("NOCLICK")
        inst:AddTag("CLASSIFIED")
        inst.persists = false

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        if sound then
            inst.SoundEmitter:PlaySound(sound, "sound")
        end
        inst.RemoveFX = removeFX
        if finaloffset then
            inst.AnimState:SetFinalOffset(finaloffset)
        end

        return inst
    end

    return Prefab(name, fn, assets)
end

local function RemovePoisonFX(inst)
    inst:RemoveEventCallback("animqueueover", RemovePoisonFX)
    inst.SoundEmitter:KillSound("sound")
    inst.AnimState:PushAnimation("level1_pst", false)
    inst:ListenForEvent("animover", inst.Remove)
end

local function RemovePaintFX(inst)
    inst:Remove()
end

local function RemoveOrbitFX(inst)
    inst.AnimState:PushAnimation("orbit_pst", false)
    inst:ListenForEvent("animqueueover", inst.Remove)
end

return
MakeFX("poisonfx", "poison", "poison", "level1_pre", "level1_loop", RemovePoisonFX, "DLChasni/DLChasni/chasni_fx/poisoned", 2),
MakeFX("paintfx", "paintfx", "paintfx", "loop", "loop", RemovePaintFX),
MakeFX("orbit_sing_greenfx", "chasni_orbit_sing_fx", "chasni_orbit_sing_fx", "orbit_pre", "orbit", RemoveOrbitFX, nil, nil, true, 1.5),
MakeFX("orbit_sing_blackfx", "chasni_orbit_sing_black_fx", "chasni_orbit_sing_black_fx", "orbit_pre", "orbit", RemoveOrbitFX, nil, nil, true, 1.5)
