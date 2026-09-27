local GREEN_COLOUR = { 30/255, 255/255, 100/255 }
local ORANGE_COLOUR = { 255/255, 165/255, 0/255 }
local YELLOW_COLOUR = { 255/255, 255/255, 5/255 }

local function OnUpdateFade(inst)
    local k
    if inst._fade:value() <= inst._fadeframes then
        inst._fade:set_local(math.min(inst._fade:value() + inst._fadeinspeed, inst._fadeframes))
        k = inst._fade:value() / inst._fadeframes
    else
        inst._fade:set_local(math.min(inst._fade:value() + inst._fadeoutspeed, inst._fadeframes * 2 + 1))
        k = (inst._fadeframes * 2 + 1 - inst._fade:value()) / inst._fadeframes
    end

    inst.Light:SetIntensity(inst._fadeintensity * k)
    inst.Light:SetRadius(inst._faderadius * k)
    inst.Light:SetFalloff(1 - (1 - inst._fadefalloff) * k)

    if TheWorld.ismastersim then
        inst.Light:Enable(inst._fade:value() > 0 and inst._fade:value() <= inst._fadeframes * 2)
    end

    if inst._fade:value() == inst._fadeframes or inst._fade:value() > inst._fadeframes * 2 then
        inst._fadetask:Cancel()
        inst._fadetask = nil
    end
end

local function OnFadeDirty(inst)
    if inst._fadetask == nil then
        inst._fadetask = inst:DoPeriodicTask(FRAMES, OnUpdateFade)
    end
    OnUpdateFade(inst)
end

local function FadeOut(inst)
    inst._fade:set(inst._fadeframes + 1)
    if inst._fadetask == nil then
        inst._fadetask = inst:DoPeriodicTask(FRAMES, OnUpdateFade)
    end
end

local function OnFXKilled(inst)
    if inst.fxcount > 0 then
        inst.fxcount = inst.fxcount - 1
    else
        inst:Remove()
    end
end

local function TriggerFX(inst)
    if not inst.killed and inst.fx then
        return
    end
    inst.fx = {}
    inst.fxcount = 0
    local function onremovefx(fx)
        OnFXKilled(inst)
    end
    for i, v in ipairs(inst.fxprefabs) do
        local fx = SpawnPrefab(v)
        fx.entity:SetParent(inst.entity)
        inst.fxcount = inst.fxcount + 1
        inst:ListenForEvent("onremove", onremovefx, fx)
        table.insert(inst.fx, fx)
    end
end

local function KillFX(inst, anim)
    if not inst.killed then
        if inst.OnKillFX then
            inst:OnKillFX(anim)
        end
        inst.killed = true
        inst.AnimState:PlayAnimation(anim or "pst")
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + .25, inst.fx and OnFXKilled or inst.Remove)
        if inst.task then
            inst.task:Cancel()
            inst.task = nil
        end
        if inst._fade then
            FadeOut(inst)
        end
        if inst.fx then
            for i, v in ipairs(inst.fx) do
                v:KillFX()
            end
        end
    end
end

--------------------------------------------------------------------------

local function deer_charge_common_postinit(inst)
    inst.SoundEmitter:SetParameter("loop", "intensity", 1)
end

local function deer_charge_master_postinit(inst, init)
    if not init then
        inst:DoTaskInTime(0, deer_charge_master_postinit, true)
    elseif not inst.killed then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_gemstaff")
        inst.SoundEmitter:PlaySound("dontstarve/common/together/moonbase/beam_stop_fail")
    end
end

local function deer_charge_onkillfx(inst, anim)
    inst.SoundEmitter:KillSound("loop")
    if anim then
        inst.SoundEmitter:PlaySound("dontstarve/common/together/moonbase/beam_stop")
    end
end

--------------------------------------------------------------------------

local function MakeFX(name, data)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }

    local prefabs = {}
    if data.burstprefab then
        table.insert(prefabs, data.burstprefab)
    end
    if data.fxprefabs then
        for i, v in ipairs(data.fxprefabs) do
            table.insert(prefabs, v)
        end
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        if data.sound or data.soundloop then
            inst.entity:AddSoundEmitter()
        end
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation(data.oneshotanim or "pre")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetFinalOffset(1)

        if data.bloom then
            inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        end

        if data.onground then
            inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.AnimState:SetLayer(LAYER_BACKGROUND)
            inst.AnimState:SetSortOrder(3)
        end

        if data.soundloop then
            inst.SoundEmitter:PlaySound(data.soundloop, "loop")
        end

        if data.light then
            if data.onground then
                inst._fadeframes = 30
                inst._fadeintensity = .8
                inst._faderadius = 3
                inst._fadefalloff = .9
                inst._fadeinspeed = 1
                inst._fadeoutspeed = 2
            else
                inst._fadeframes = 15
                inst._fadeintensity = .8
                inst._faderadius = 2
                inst._fadefalloff = .7
                inst._fadeinspeed = 3
                inst._fadeoutspeed = 1
            end

            inst.entity:AddLight()
            inst.Light:SetColour(unpack(data.light))
            inst.Light:SetRadius(inst._faderadius)
            inst.Light:SetFalloff(inst._fadefalloff)
            inst.Light:SetIntensity(inst._fadeintensity)
            inst.Light:Enable(false)
            inst.Light:EnableClientModulation(true)

            inst._fade = net_smallbyte(inst.GUID, "deer_fx._fade", "fadedirty")

            inst._fadetask = inst:DoPeriodicTask(FRAMES, OnUpdateFade)
        end

        inst:AddTag("FX")

        if data.common_postinit then
            data.common_postinit(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            if data.light then
                inst:ListenForEvent("fadedirty", OnFadeDirty)
            end

            return inst
        end

        inst.persists = false

        if data.sound then
            inst.SoundEmitter:PlaySound(data.sound)
        end

        if data.oneshotanim then
            inst.killed = true
            inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + .25, inst.Remove)
        else
            inst.burstprefab = data.burstprefab

            if data.fxprefabs then
                inst.fxprefabs = data.fxprefabs
                inst.TriggerFX = TriggerFX
            end

            if data.looping then
                inst.AnimState:PushAnimation("loop")
            end
        end

        inst.KillFX = KillFX
        inst.OnKillFX = data.onkillfx

        if data.master_postinit then
            data.master_postinit(inst)
        end

        return inst
    end

    return Prefab(name, fn, assets, #prefabs > 0 and prefabs or nil)
end

return 
MakeFX("deer_green_charge", {
    light = GREEN_COLOUR,
    bloom = true,
    looping = true,
    soundloop = "dontstarve/creatures/together/deer/fx/charge_LP",
    common_postinit = deer_charge_common_postinit,
    master_postinit = deer_charge_master_postinit,
    onkillfx = deer_charge_onkillfx,
}),
--
MakeFX("deer_orange_charge", {
    light = ORANGE_COLOUR,
    bloom = true,
    looping = true,
    soundloop = "dontstarve/creatures/together/deer/fx/charge_LP",
    common_postinit = deer_charge_common_postinit,
    master_postinit = deer_charge_master_postinit,
    onkillfx = deer_charge_onkillfx,
}),
--
MakeFX("deer_yellow_charge", {
    light = YELLOW_COLOUR,
    bloom = true,
    looping = true,
    soundloop = "dontstarve/creatures/together/deer/fx/charge_LP",
    common_postinit = deer_charge_common_postinit,
    master_postinit = deer_charge_master_postinit,
    onkillfx = deer_charge_onkillfx,
})
