local function LightFn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.Light:SetIntensity(.7)
    inst.Light:SetRadius(5)
    inst.Light:SetFalloff(.4)
    inst.Light:SetColour(1, 1, 1)
    inst.Light:Enable(true)
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end
    inst.persists = false
    return inst
end

return Prefab("tbc_strengthen_light", LightFn)
