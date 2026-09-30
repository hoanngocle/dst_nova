local function fn()
    local inst=Prefabs.treasurechest.fn()
    inst:AddTag('hn_recovery_bag')
    if not TheWorld.ismastersim then return inst end
    inst:AddComponent('hn_recovery');inst:AddComponent('named')
    inst.components.named:SetName('Túi thu hồi Hầm Ngục')
    if inst.components.workable then inst:RemoveComponent('workable') end
    if inst.components.burnable then inst:RemoveComponent('burnable') end
    if inst.components.propagator then inst:RemoveComponent('propagator') end
    return inst
end
return Prefab('hn_recovery_bag',fn,nil,{'treasurechest'})
