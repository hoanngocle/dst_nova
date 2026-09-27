-- Visual FX functions copied from Solo Leveling scripts/prefabs/hh_daogam_fire_skill.lua.
local FIRE_FX_ASSETS = {Asset("ANIM", "anim/hh_purple_lavaarena_fire_fx.zip")}
local FIREPUFF_ASSETS = {Asset("ANIM", "anim/hh_purple_halloween_embers.zip")}

local function FireSplashFn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lavaarena_fire_fx")
    inst.AnimState:SetBuild("hh_purple_lavaarena_fire_fx")
    inst.AnimState:PlayAnimation("firestaff_ult")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    return inst
end

local function FireBaseFn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lavaarena_fire_fx")
    inst.AnimState:SetBuild("hh_purple_lavaarena_fire_fx")
    inst.AnimState:PlayAnimation("firestaff_ult_projection")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    return inst
end

local function MakeFirePuffFn(anim)
    return function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("halloween_embers")
        inst.AnimState:SetBuild("hh_purple_halloween_embers")
        inst.AnimState:PlayAnimation(anim)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(3)
        inst:AddTag("FX")
        inst:AddTag("NOCLICK")
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false
        inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
        inst:ListenForEvent("animover", inst.Remove)
        return inst
    end
end


return Prefab("hh_daogam_fire_splash", FireSplashFn, FIRE_FX_ASSETS),
    Prefab("hh_daogam_fire_base", FireBaseFn, FIRE_FX_ASSETS),
    Prefab("hh_daogam_firepuff_1", MakeFirePuffFn("puff_1"), FIREPUFF_ASSETS),
    Prefab("hh_daogam_firepuff_2", MakeFirePuffFn("puff_2"), FIREPUFF_ASSETS),
    Prefab("hh_daogam_firepuff_3", MakeFirePuffFn("puff_3"), FIREPUFF_ASSETS)
