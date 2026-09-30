test('teleport allows clear arena paths and blocks crossing walls or boundary',function()
    local a=require('support/dst_mock').Install();local p=a.player();p:AddTag('in_hn_dungeon')
    a.world.components.hn_dungeon_manager={IsPointInsideDungeon=function(_,x,z) return x>=100 and x<=120 and z>=100 and z<=120 end}
    a.world.Pathfinder={IsClear=function() return true end}
    local r=require('hn_dungeon/restrictions')
    assert(r.CanTeleport(p,105,105,110,110));assert(not r.CanTeleport(p,105,105,0,0))
    assert(not r.CanTeleport(nil,0,0,105,105));assert(r.CanTeleport(nil,0,0,10,10))
    a.world.Pathfinder.IsClear=function() return false end
    assert(not r.CanTeleport(p,105,105,110,110));assert(r.CanTeleport(nil,0,0,10,10))
end)
test('restriction bootstrap patches the global BufferedAction class',function()
    require('support/dst_mock').Install()
    GLOBAL=_G;ACTIONS={JUMPIN={},REVIVE={},RESURRECT={},HAUNT={}}
    BufferedAction={IsValid=function() return true end}
    AddClassPostConstruct=function() error('bufferedaction.lua does not return a class') end
    dofile('HamNgucTuTien/main/hn_restrictions.lua')
    local a=require('support/dst_mock').Install();local p=a.player();p:AddTag('in_hn_dungeon')
    assert(not BufferedAction.IsValid({doer=p,action=ACTIONS.JUMPIN}))
    p:RemoveTag('in_hn_dungeon');assert(BufferedAction.IsValid({doer=p,action=ACTIONS.JUMPIN}))
end)
