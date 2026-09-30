-- QA only: requires the explicit QA reward fixture, never production modmain.
local G=GLOBAL or _G;G.setfenv(1,G)
TheWorld:DoTaskInTime(3,function()
 local m=assert(TheWorld.components.hn_dungeon_manager);assert(m:FindArena())
 if m.cooldown_task then m.cooldown_task:Cancel() end
 m:RemoveGate();m.state='COOLDOWN';assert(m:TrySpawnGate(true));assert(m.state=='READY')
 local p=assert(SpawnPrefab('wilson'));p.userid='HN_QA';p.components.health:SetInvincible(true)
 p.Transform:SetPosition(m.run_gate_x,0,m.run_gate_z)
 assert(m:Enter(p));print('HN_QA_PASS','real player entry')
 -- Inventory/container transfer uses actual DST entities and components.
 local pack=SpawnPrefab('backpack');local gem=SpawnPrefab('redgem')
 pack.components.container:GiveItem(gem);p.components.inventory:Equip(pack)
 local tool=SpawnPrefab('axe');p.components.inventory:GiveItem(tool)
 p.components.inventory:DropEverything(true)
 local found=0
 for _,e in pairs(Ents) do if e.prefab=='hn_recovery_bag' then
  for _,item in pairs(e.components.container.slots) do if item==pack or item==tool then found=found+1 end end
 end end
 local px,_,pz=pack.Transform:GetWorldPosition()
 assert(found==1 and px==m.run_gate_x and pz==m.run_gate_z and gem.components.inventoryitem:GetGrandOwner()~=p,'recovery lost inventory')
 assert(pack.components.container:Has('redgem',1),'nested gem lost')
 print('HN_QA_PASS','death recovery original inventory and nested container')
 m:CancelRunTasks();m.current_wave=m.max_waves;m.is_cleared=true
 local r=require('hn_dungeon/rewards');assert(r.GrantClear(m,m.run_epoch,p:GetPosition()))
 assert(not r.GrantClear(m,m.run_epoch,p:GetPosition()))
 local chest
 for _,e in pairs(Ents) do if e.prefab=='minotaurchest' and e.components.hn_owned.run_id==m.run_epoch then chest=e end end
 assert(chest and next(chest.components.container.slots),'missing rewards')
 local personal=SpawnPrefab('spear');chest.components.container:GiveItem(personal)
 m:Reset('qa');assert(pack:IsValid() and tool:IsValid() and gem:IsValid() and personal:IsValid())
 assert(not chest:IsValid() and p.components.hn_dungeon_cooldown:GetTime()>479)
 print('HN_QA_PASS','single reward chest cleanup preserves personal items')
 p:Remove();print('HN_QA_DONE')
end)


