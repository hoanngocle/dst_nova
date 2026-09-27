local assets =
{
    Asset("ANIM", "anim/bearger_ring_fx.zip"),
}

local function MakeFX(name, r, g, b, a, scale)
    local function PlayRingAnim(proxy)
        local inst = CreateEntity()
        inst:AddTag("FX")
        inst.entity:SetCanSleep(false)
        inst.persists = false

        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        inst.Transform:SetFromProxy(proxy.GUID)

        inst.AnimState:SetBank("bearger_ring_fx")
        inst.AnimState:SetBuild("bearger_ring_fx")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetFinalOffset(3)

        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
        inst.AnimState:SetMultColour(r, g, b, a)

        inst:ListenForEvent("animover", inst.Remove)
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst:AddTag("FX")
        if scale then
            inst.Transform:SetScale(scale, scale, scale)
        end

        if not TheNet:IsDedicated() then
            inst:DoTaskInTime(0, PlayRingAnim)
        end
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false
        inst:DoTaskInTime(2, inst.Remove)
        return inst
    end

    return Prefab(name, fn, assets)
end

return
MakeFX("blackfx_ring", 0, 0, 0, 1),
MakeFX("redfx_ring", 1, 0, 0.6, 1),
MakeFX("orangefx_ring", 1, 0.85, 0.1, 1),
MakeFX("yellowfx_ring", 1, 0.8, 0.2, 1),
MakeFX("pinkfx_ring", 1, 0.5, 0.7, 1),
MakeFX("purplefx_ring", 1, 0.6, 1, 1),
MakeFX("whitefx_ring", 1, 1, 1, 1),
MakeFX("bluefx_ring", 0.1, 0.7, 1, 1),
MakeFX("cyanfx_ring", 0, 1, 1, 1),
MakeFX("smallfx_ring", 1, 1, 1, 1, 0.7),
MakeFX("smallbluefx_ring", 0.1, 0.7, 1, 1, 0.7)