local brain = require "brains/chasni_moonbutterflyfxbrain"

local assets =
{
    Asset("ANIM", "anim/butterfly_basic.zip"),
    Asset("ANIM", "anim/butterfly_moon.zip"),
    Asset("ANIM", "anim/baby_moon_tree.zip"),
    Asset("INV_IMAGE", "moonbutterfly"),
}

local LIGHT_RADIUS = .5
local LIGHT_INTENSITY = .5
local LIGHT_FALLOFF = .8
local function OnUpdateFlicker(inst, starttime)
    local time = starttime and (GetTime() - starttime) * 15 or 0
    local flicker = math.sin(time * 0.7 + math.sin(time * 6.28))
    flicker = (1 + flicker) * .5
    inst.Light:SetIntensity(LIGHT_INTENSITY + .05 * flicker)
end

local function onremove(inst)
    inst.Light:Enable(false)
    inst.AnimState:SetLightOverride(0)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeTinyFlyingCharacterPhysics(inst, 1, .5)
    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBuild("butterfly_moon")
    inst.AnimState:SetBank("butterfly")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetLightOverride(0.15)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.Light:SetFalloff(LIGHT_FALLOFF)
    inst.Light:SetIntensity(LIGHT_INTENSITY)
    inst.Light:SetRadius(LIGHT_RADIUS)
    inst.Light:SetColour(0.3, 0.55, 0.45)
    inst.Light:Enable(true)
    inst.Light:EnableClientModulation(true)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst:DoPeriodicTask(.1, OnUpdateFlicker, nil, GetTime())
    OnUpdateFlicker(inst)

    MakeInventoryFloatable(inst)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("knownlocations")
    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = 8

    --inst:DoPeriodicTask(5, function()
    --    if inst._moonbanner and inst._moonbanner:IsValid() then
    --        inst.sg:GoToState("idle")
    --    end
    --end)

    inst:SetStateGraph("SGbutterfly")
    inst:SetBrain(brain)
    inst:ListenForEvent("onremove", onremove)

    inst._moonbanner = nil
    inst._circlingradius = nil
    inst.persists = false

    return inst
end

return Prefab("moonbutterfly_fx", fn, assets)