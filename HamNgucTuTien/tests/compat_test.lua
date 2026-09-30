test('Nyx and travel integrations reject before invoking resource-consuming callbacks',function()
 local a=require('support/dst_mock').Install();local hooks,prefabs={},{}
 AddComponentPostInit=function(n,fn) hooks[n]=fn end;AddPrefabPostInit=function(n,fn) prefabs[n]=fn end
 dofile('HamNgucTuTien/main/hn_tutien_compat.lua')
 local p=a.player();p:AddTag('in_hn_dungeon');p.x=105;p.z=105
 a.world.components.hn_dungeon_manager={IsPointInsideDungeon=function(_,x,z) return x>=100 and z>=100 end}
 a.world.Pathfinder={IsClear=function() return true end}
 local calls=0;local blink={inst=p,CastAt=function() calls=calls+1;return true end};hooks.nyx_blink(blink)
 assert(not blink:CastAt(0,0) and calls==0);assert(blink:CastAt(110,110) and calls==1)
 local travel={BeginTravel=function() calls=calls+1 end,Travel=function() calls=calls+1 end};hooks.ttt_travelable(travel)
 assert(travel:BeginTravel(p)==false and travel:Travel(p)==false and calls==1)
 local item=a.entity('xd_wmz_tnz');item.components.xd_use_inventory={onusefn=function() calls=calls+1 end}
 prefabs.xd_wmz_tnz(item);a.advance(.1);item.components.xd_use_inventory.onusefn(item,p);assert(calls==1)
 p:RemoveTag('in_hn_dungeon');item.components.xd_use_inventory.onusefn(item,p);assert(calls==2)
end)
