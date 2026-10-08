local function Run()
    local data=require('nova_slot_rewards')
    local missing,seen={},{}
    for _,group in ipairs(data.groups) do
        for _,bundle in ipairs(group.bundles) do
            for _,item in ipairs(bundle.items) do
                if not seen[item.prefab] then
                    seen[item.prefab]=true
                    if not GLOBAL.Prefabs[item.prefab] then
                        missing[#missing+1]=item.prefab
                        print('SLOT_MISSING',item.prefab,group.key,bundle.name)
                    end
                end
            end
        end
    end
    print('SLOT_REGISTRY',#missing)
    for _,id in ipairs({'nhatvuphuonghoa','thanhiquangtruong','xd_sudaji_ywfh','xd_yunxiao_fysz'}) do
        print('SLOT_LEGACY',id,GLOBAL.Prefabs[id]~=nil)
    end
    local machine=assert(SpawnPrefab('xd_choujiangji'))
    machine.entity:SetCanSleep(false)
    assert(machine.components.nova_slotmachine,'missing slot component/native callback')
    local pool=assert(machine.components.nova_slotmachine:Pool())
    for _,group in ipairs(pool) do print('SLOT_POOL',group.key,#group.bundles) end
    local core=require('nova_slot_core')
    local adapter=require('nova_slot_spawn')
    local player=assert(SpawnPrefab('nyx'))
    player.components.health:SetInvincible(true)
    local point
    for x=-800,800,16 do
        for z=-800,800,16 do
            if TheWorld.Map:IsPassableAtPoint(x,0,z) and not TheWorld.Map:IsOceanAtPoint(x,0,z) then
                machine.Transform:SetPosition(x,0,z)
                if adapter.Points(machine,{items={{count=10}}},true) then point=Vector3(x,0,z);break end
            end
        end
        if point then break end
    end
    assert(point,'QA needs open land')
    player.Transform:SetPosition(point:Get())
    local batches={}
    for _,group in ipairs(pool) do
        for _,bundle in ipairs(group.bundles) do batches[#batches+1]={group=group,bundle=bundle} end
    end
    local index=0
    local function Next()
        index=index+1
        local entry=batches[index]
        if not entry then
            print('SLOT_SPAWN_DONE',index-1)
            local slot=machine.components.nova_slotmachine
            local timeout=machine.sg.SetTimeout
            machine.sg.SetTimeout=function(self,time,...)
                print('SLOT_SG_TIMEOUT',self.currentstate.name,time)
                return timeout(self,time,...)
            end
            local money=SpawnPrefab('xd_lingshi1');money.components.stackable:SetStackSize(59)
            assert(not machine.components.trader:AcceptGift(player,money),'59 stones must be refused')
            money.components.stackable:SetStackSize(61)
            assert(machine.components.trader:AcceptGift(player,money),'60 stones accepted')
            assert(slot.pending and slot.pending.cost==60 and money.components.stackable.stacksize==1,'consume exactly 60')
            assert(not machine.components.trader:AcceptGift(player,money),'busy refused')
            local save=machine:GetSaveRecord();assert(save.data.nova_slotmachine.pending.cost==60)
            local events=0
            machine:ListenForEvent('nova_slot_reward',function()events=events+1 end)
            machine:DoTaskInTime(12,function()
                local ok,err=pcall(function()
                    print('SLOT_SG_FINAL',machine.sg.currentstate.name,events,slot.pending~=nil)
                    assert(events==1 and not slot.pending,'native stategraph must pay once')
                    slot:Complete();assert(events==1,'duplicate callback ignored')
                    local function Stones()
                        local total=0
                        for _,e in ipairs(TheSim:FindEntities(point.x,0,point.z,5)) do
                            if e.prefab=='xd_lingshi1' then total=total+(e.components.stackable and e.components.stackable.stacksize or 1) end
                        end
                        return total
                    end
                    local before=Stones()
                    local copy=assert(SpawnSaveRecord(save))
                    copy:DoTaskInTime(0.2,function()
                        local good=copy.components.nova_slotmachine.pending==nil and Stones()==before+60
                        print('SLOT_LOAD_REFUND',good)
                        print('SLOT_QA_DONE',good and 'PASS' or 'FAIL')
                        TheSim:Quit()
                    end)
                end)
                if not ok then print('SLOT_QA_DONE','FAIL',err);TheSim:Quit() end
            end)
            return
        end
        local ok,err=pcall(function()
            local points=assert(adapter.Points(machine,entry.bundle,entry.group.key=='bad' or entry.group.key=='bad2'))
            local success,entities=core.SpawnBundle(entry.bundle,SpawnPrefab,function(e,item,i,track)
                adapter.Configure(e,item,points[i],player,track)
            end)
            assert(success,entities)
            print('SLOT_SPAWN',entry.bundle.id,'PASS')
            machine:DoTaskInTime(.1,function()
                for i=#entities,1,-1 do if entities[i]:IsValid() then entities[i]:Remove() end end
                Next()
            end)
        end)
        if not ok then print('SLOT_QA_DONE','FAIL',entry.bundle.id,err);TheSim:Quit() end
    end
    Next()
end
AddSimPostInit(function()
    local ok,err=pcall(Run)
    if not ok then print('SLOT_QA_DONE','FAIL',err);TheSim:Quit() end
end)
