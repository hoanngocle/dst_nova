local assets =
{
    Asset("ANIM", "anim/chasni_abigail_vial_fx.zip"),
    Asset("ANIM", "anim/abigail_buff_drip.zip"),
}

local function MakeFX(name, bank, build, anim, drip)
    local function startfx(proxy)
        local inst = CreateEntity(name)
        inst:AddTag("FX")
        inst.entity:SetCanSleep(false)
        inst.persists = false

        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        inst.Transform:SetFromProxy(proxy.GUID)

        local parent = proxy.entity:GetParent()
        if parent then
            inst.entity:SetParent(parent.entity)
        end

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)
        inst.AnimState:SetFinalOffset(3)

        if drip then
            inst.AnimState:OverrideSymbol("fx_swap", build, drip)
        end
        inst:ListenForEvent("animover", inst.Remove)

        if TheWorld then
            TheWorld:PushEvent("fx_spawned", inst)
        end
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst:AddTag("FX")

        if not TheNet:IsDedicated() then
            inst:DoTaskInTime(0, startfx, inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false
        inst:DoTaskInTime(1, inst.Remove)

        return inst
    end

    return Prefab(name, fn, assets)
end

return
MakeFX("ghostlyelixir_chasnilunar_fx", "abigail_vial_fx", "chasni_abigail_vial_fx", "buff_shield", nil),
MakeFX("ghostlyelixir_chasnilunar_dripfx", "abigail_buff_drip", "chasni_abigail_vial_fx", "abigail_buff_drip", "fx_shield_02"),
MakeFX("ghostlyelixir_chasnishadow_fx", "abigail_vial_fx", "chasni_abigail_vial_fx", "buff_retaliation", nil),
MakeFX("ghostlyelixir_chasnishadow_dripfx", "abigail_buff_drip", "chasni_abigail_vial_fx", "abigail_buff_drip", "fx_retaliation_02"),
MakeFX("ghostlyelixir_temperature_fx", "abigail_vial_fx", "chasni_abigail_vial_fx", "buff_speed", nil),
MakeFX("ghostlyelixir_temperature_dripfx", "abigail_buff_drip", "chasni_abigail_vial_fx", "abigail_buff_drip", "fx_speed_02"),
MakeFX("ghostlyelixir_slow_fx", "abigail_vial_fx", "chasni_abigail_vial_fx", "buff_heal", nil),
MakeFX("ghostlyelixir_slow_dripfx", "abigail_buff_drip", "chasni_abigail_vial_fx", "abigail_buff_drip", "fx_heal_02")
