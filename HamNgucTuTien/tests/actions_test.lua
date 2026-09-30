test('entry requests reject stale distant dead or transitioning players',function()
    local a=require('support/dst_mock').Install();local p=a.player();p.sg={}
    local gate=SpawnPrefab('hn_dungeon_gate')
    local manager={IsActiveGate=function(_,g) return g==gate end,CanEnter=function() return true end}
    local entry=require('hn_dungeon/entry')
    gate.Transform:SetPosition(6,0,0);assert(entry.CanRequest(p,gate,manager))
    gate.Transform:SetPosition(6.01,0,0);assert(not entry.CanRequest(p,gate,manager))
    gate.Transform:SetPosition(0,0,0);p:AddTag('playerghost');assert(not entry.CanRequest(p,gate,manager));p:RemoveTag('playerghost')
    p:AddTag('hn_dungeon_transition');assert(not entry.CanRequest(p,gate,manager));assert(entry.CanRequest(p,gate,manager,true))
    p:RemoveTag('hn_dungeon_transition');assert(not entry.CanRequest(p,SpawnPrefab('hn_dungeon_gate'),manager))
    manager.CanEnter=function() return false end;assert(not entry.CanRequest(p,gate,manager))
end)
