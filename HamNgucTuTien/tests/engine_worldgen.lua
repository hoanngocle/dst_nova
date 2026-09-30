-- QA-only structural validation in a freshly generated Forest/Caves world.
local G=GLOBAL or _G;G.setfenv(1,G)
TheWorld:DoTaskInTime(3,function()
 local exits=0;for _,e in pairs(Ents) do if e:HasTag('hn_dungeon_exit') then exits=exits+1 end end
 local m=TheWorld.components.hn_dungeon_manager
 if TheWorld:HasTag('forest') then
  assert(m and exits==1 and m:FindArena());local x,z=m.dungeon_center_x,m.dungeon_center_z
  assert(TheWorld.Map:IsPassableAtPoint(x,0,z+4))
  local gx,gz=m:FindMainlandGatePoint(true);assert(gx and m:IsValidGatePoint(gx,gz,true))
  assert(TheWorld.Pathfinder:IsClear(x,0,z+3,x,0,z+4))
  print('HN_QA_PASS','Forest arena/exit/mainland gate/navigation',x,z)
 else assert(not m and exits==0);print('HN_QA_PASS','Caves has no dungeon manager or arena') end
 print('HN_QA_DONE')
end)
