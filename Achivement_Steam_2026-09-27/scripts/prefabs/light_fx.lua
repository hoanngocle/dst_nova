local assets_ground =
{
    Asset("ANIM", "anim/circle_light_fx.zip"),
}
local assets_blob =
{
    Asset("ANIM", "anim/lightblob_fx.zip"),
    Asset("ANIM", "anim/splash_weregoose_fx.zip"),
    Asset("ANIM", "anim/splash_water_drop.zip"),
}

local function Ground_KillFX(inst)
    inst.AnimState:PlayAnimation("meteorground_pst")
    inst:ListenForEvent("animover", inst.Remove)
end

local function groundfx_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("DECOR")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("alterguardian_meteor")
    inst.AnimState:SetBuild("circle_light_fx")
    inst.AnimState:PlayAnimation("meteorground_pre")

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.Light:SetIntensity(.7)
    inst.Light:SetRadius(.1)
    inst.Light:SetFalloff(0.6)
    inst.Light:SetColour(1, 1, 1)
    inst.Light:Enable(true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.KillFX = Ground_KillFX
    inst.persists = false

    return inst
end

local function CreateRipples()
    local inst = CreateEntity()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("splash_weregoose_fx")
    inst.AnimState:SetBuild("splash_water_drop")
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)

    return inst
end

local function DoRipple(inst, ripples, map, x, z)
    if inst.AnimState:IsCurrentAnimation("idle") and map:GetPlatformAtPoint(x, z) == nil then
        ripples.AnimState:PlayAnimation(math.random() < .5 and "no_splash" or "no_splash2")
    end
end

local function TryRipples(inst)
    local parent = inst.entity:GetParent()
    if parent and parent:HasTag("ignorewalkableplatforms") then
        local x, y, z = inst.Transform:GetWorldPosition()
        local map = TheWorld.Map
        if map:IsOceanAtPoint(x, y, z, true) then
            local ripples = CreateRipples()
            ripples.entity:SetParent(inst.entity)
            inst:DoPeriodicTask(1, DoRipple, 0, ripples, map, x, z)
        end
    end
end

local function Blob_KillFX(inst)
    inst.AnimState:PlayAnimation("pst")
    inst:ListenForEvent("animover", inst.Remove)
end

local function blobfx_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("shadow_pillar_fx")
    inst.AnimState:SetBuild("lightblob_fx")
    inst.AnimState:PlayAnimation("pre")
    inst.AnimState:SetMultColour(1, 1, 1, .6)
    inst.AnimState:UsePointFiltering(true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(1, TryRipples)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:PushAnimation("idle")

    inst.KillFX = Blob_KillFX
    inst.persists = false

    return inst
end

return
Prefab("groundlight_fx", groundfx_fn, assets_ground),
Prefab("bloblight_fx", blobfx_fn, assets_blob)
