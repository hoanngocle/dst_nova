local G=GLOBAL or _G;G.setfenv(1,G)
TheWorld:DoTaskInTime(3,function()
 local m=assert(TheWorld.components.hn_dungeon_manager)
 assert(m.state=='COOLDOWN' and m.cooldown_end-GetTime()>470,'active run resumed after restart')
 local bags=0
 for _,e in pairs(Ents) do
  if e.components.hn_recovery and e.components.hn_recovery.recovery_id=='hn-qa-persist' then
   bags=bags+1;assert(e.components.hn_recovery.owner=='hn-qa');assert(e.components.container:Has('bluegem',1))
  end
  if e.prefab=='hn_dungeon_pig' and e.components.hn_owned and e.components.hn_owned.run_id then error('old run monster survived restart') end
 end
 assert(bags==1,'recovery bag lost or duplicated after restart')
 print('HN_QA_PASS','restart aborts run and preserves recovery contents exactly once')
 print('HN_QA_DONE')
end)
