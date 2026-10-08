local G=GLOBAL
AddPrefabPostInit('xd_choujiangji',function(inst)
    if not G.TheWorld.ismastersim then return end
    local trader=inst.components.trader
    if not trader then return end
    -- Keep the native stategraph/animations. Only replace the public payout callback.
    local donekey
    for key,value in G.pairs(inst) do
        if G.type(key)=='string' and G.string.lower(key)=='donespinning' and G.type(value)=='function' then donekey=key;break end
    end
    if not donekey then
        trader:SetAcceptTest(function()return false end)
        G.print('[Nova slot] unsupported Tu Tien machine; trading disabled to prevent old payouts')
        return
    end
    inst:AddComponent('nova_slotmachine')
    local slot=inst.components.nova_slotmachine
    trader:SetAcceptTest(function(_,item,giver)return slot:CanAccept(item,giver)end)
    trader.onaccept=function(_,giver,item,count)slot:Begin(giver,item,count)end
    local accept=trader.AcceptGift
    trader.AcceptGift=function(self,giver,item,count)
        if not slot:CanAccept(item,giver) then return false end
        slot.prepared=slot:Prepare(giver)
        if not slot.prepared then return false end
        local result=accept(self,giver,item,item.prefab=='xd_lingshi1' and 60 or 1)
        slot.prepared=nil
        return result
    end
    inst[donekey]=function()slot:Complete()end
    inst:ListenForEvent('onremove',function()slot:Refund()end)
end)
