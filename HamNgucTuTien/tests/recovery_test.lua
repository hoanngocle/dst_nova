test('cleanup preserves player items and claimed loot but removes unclaimed run items',function()
    local a=require('support/dst_mock').Install()
    local loose=a.entity('axe');local owned=a.entity('xd_lingshi1');owned:AddComponent('hn_owned');owned.components.hn_owned.run_id=1
    local claimed=a.entity('spear');claimed:AddComponent('hn_owned');claimed.components.hn_owned.run_id=1;claimed.components.hn_owned.claimed=true
    local held=a.entity('goldnugget');held:AddComponent('hn_owned');held.components.hn_owned.run_id=1;held.components.inventoryitem={IsHeld=function() return true end}
    require('hn_dungeon/cleanup').Run({run_entities={},monsters={}})
    assert(loose:IsValid() and claimed:IsValid() and held:IsValid() and not owned:IsValid())
end)
test('ownership survives save/load and player pickup permanently claims reward',function()
    local a=require('support/dst_mock').Install();local p=a.player();local item=a.entity('spear')
    item.components.inventoryitem={GetGrandOwner=function() return p end}
    item:AddComponent('hn_owned');item.components.hn_owned.run_id=9
    item:PushEvent('onputininventory');local data=item.components.hn_owned:OnSave()
    local other=a.entity('spear');other:AddComponent('hn_owned');other.components.hn_owned:OnLoad(data)
    assert(other.components.hn_owned.claimed==true and other.components.hn_owned.run_id==9)
end)
test('death wrapper recovers only actual dropped roots, preserving nested contents',function()
    local a=require('support/dst_mock').Install();local p=a.player();p:AddTag('in_hn_dungeon')
    local backpack=a.entity('backpack');local gem=a.entity('redgem');local kept=a.entity('amulet');local outside=a.entity('goldnugget')
    local held=true
    backpack.components.inventoryitem={IsHeld=function() return held end};gem.components.inventoryitem={IsHeld=function() return true end}
    kept.components.inventoryitem={IsHeld=function() return true end}
    backpack.components.container={slots={gem}}
    local inv={inst=p,itemslots={backpack,kept},equipslots={},DropEverything=function() held=false end}
    local m={run_gate_x=10,run_gate_z=20};a.world.components.hn_dungeon_manager=m
    local received={};local spawn=SpawnPrefab
    SpawnPrefab=function(n)
        local bag=spawn(n);bag.components.hn_recovery={};bag.components.container={GiveItem=function(_,item) received[#received+1]=item;held=true;return true end}
        return bag
    end
    require('hn_dungeon/recovery').WrapInventory(inv)
    inv:DropEverything(true)
    assert(#received==1 and received[1]==backpack and backpack.components.container.slots[1]==gem)
    assert(kept:IsValid() and outside:IsValid())
end)
test('breakout monster persists its tier and combat setup across reload',function()
    local a=require('support/dst_mock').Install();local e=a.entity('hound');e:AddComponent('hn_owned')
    e.hn_detached=true;e.hn_detached_total=6
    e.components.health={GetPercent=function() return .4 end}
    local data=e.components.hn_owned:OnSave()
    assert(data and data.detached and data.detached_total==6 and data.health_percent==.4)
    local other=a.entity('hound');other:AddComponent('hn_owned')
    other.components.health={maxhealth=100,SetMaxHealth=function(self,v) self.maxhealth=v end,SetPercent=function(self,v) self.percent=v end}
    other.components.combat={SetKeepTargetFunction=function() end,SetRetargetFunction=function() end}
    other.components.lootdropper={GenerateLoot=function() return {} end}
    other.components.hn_owned:OnLoad(data);a.advance(.1)
    assert(other.hn_detached and other.components.health.maxhealth==300 and other.components.health.percent==.4)
    require('hn_dungeon/cleanup').Run({});assert(other:IsValid())
end)
test('mixed personal and unclaimed reward stacks retain ownership through merge and split',function()
 local a=require('support/dst_mock').Install();local stack=require('hn_dungeon/stack_ownership')
 local function item(size)
  local e=a.entity('xd_lingshi1');e:AddComponent('hn_owned')
  local c={inst=e,stacksize=size};e.components.stackable=c
  c.Put=function(self,other) self.stacksize=self.stacksize+other.components.stackable.stacksize;other:Remove() end
  c.Get=function(self,n) self.stacksize=self.stacksize-n;return item(n) end
  c.StackSize=function(self)return self.stacksize end
  stack.Wrap(c);return e
 end
 local reward=item(5);reward.components.hn_owned.run_id=4
 local personal=item(7);reward.components.stackable:Put(personal)
 assert(reward.components.hn_owned.claimed and reward.components.stackable:StackSize()==12)
 local split=reward.components.stackable:Get(3)
 assert(split.components.hn_owned.claimed and split.components.hn_owned.run_id==4)
 local unclaimed=item(6);unclaimed.components.hn_owned.run_id=4
 local piece=unclaimed.components.stackable:Get(2)
 assert(piece.components.hn_owned.run_id==4 and not piece.components.hn_owned.claimed)
 require('hn_dungeon/cleanup').Run({})
 assert(reward:IsValid() and split:IsValid() and not unclaimed:IsValid() and not piece:IsValid())
end)
