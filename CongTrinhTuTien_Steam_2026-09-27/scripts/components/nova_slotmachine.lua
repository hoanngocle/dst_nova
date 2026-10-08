local data=require('nova_slot_rewards')
local core=require('nova_slot_core')
local spawn=require('nova_slot_spawn')
local function valid(player)
    return player and player:IsValid() and not player:HasTag('playerghost')
end
local function say(player,message)
    if valid(player) and player.components and player.components.talker then player.components.talker:Say(message) end
end
local function cost(item)
    if not item then return nil end
    if item.prefab == 'xd_lingshi1' then
        return item.components.stackable and item.components.stackable.stacksize >= 60 and 60 or nil
    end
    return (item.prefab=='xd_lingshi2' or item.prefab=='xd_lingshi3' or item.prefab=='xd_lingshi4') and 1 or nil
end
local Slot=Class(function(self,inst) self.inst=inst end)
function Slot:Pool()
    return core.Eligible(data.groups,function(id)return Prefabs[id]~=nil end,
        TUNING.HH_TREASURE_BOSS_EXP~=nil and Prefabs.hh_igris_dungeon~=nil)
end
function Slot:CanAccept(item,giver)
    if self.pending or self.inst.busy or not valid(giver) or not cost(item) then return false end
    local pool=self:Pool()
    if not pool then say(giver,'Thiếu mod hoặc vật phẩm để mở đủ các nhóm thưởng.');return false end
    return true
end
function Slot:Prepare(giver)
    local pool=self:Pool()
    if not pool then return nil end
    local group=core.Choose(pool)
    local candidates={}
    for _,bundle in ipairs(group.bundles) do
        local points=spawn.Points(self.inst,bundle,group.key=='bad' or group.key=='bad2')
        if points then candidates[#candidates+1]={bundle=bundle,points=points,weight=bundle.weight} end
    end
    if #candidates==0 then say(giver,'Không đủ khoảng đất trống quanh máy quay.');return nil end
    local chosen=core.Choose(candidates)
    return {key=group.key,bundle=chosen.bundle,points=chosen.points}
end
function Slot:Begin(giver,item,count)
    -- Trader already consumed exactly this payment; receipt survives save/load.
    local chosen=self.prepared or self:Prepare(giver)
    self.prepared=nil
    self.pending={currency=item.prefab,cost=count,userid=giver and giver.userid,
        bundle=chosen and chosen.bundle,key=chosen and chosen.key,points=chosen and chosen.points}
    self.giver=giver
    self.inst.busy=true
    if not chosen then self:Refund();return end
    self.inst.giver=giver
    self.inst.givername=giver and giver.name
    self.inst.prizevalue=chosen.key
    self.inst.sg:GoToState('spinning')
end
function Slot:GetGiver()
    if valid(self.giver) then return self.giver end
    for _, player in ipairs(AllPlayers) do
        if self.pending and player.userid==self.pending.userid and valid(player) then return player end
    end
end
function Slot:Unlock()
    self.pending=nil
    self.giver=nil
    self.inst.busy=false
    self.inst.prizevalue=nil
    self.inst.giver=nil
end
function Slot:Refund()
    local receipt=self.pending
    if not receipt then return true end
    local point=self.inst:GetPosition()
    local ok,entities=core.SpawnBundle({items={{prefab=receipt.currency,count=receipt.cost}}},SpawnPrefab,
        function(entity) entity.Transform:SetPosition(point.x,0,point.z) end)
    if not ok then
        print('[Nova slot] refund pending:',entities)
        return false
    end
    local giver=self:GetGiver()
    self:Unlock()
    say(giver,'Lượt quay không hoàn tất; Linh Thạch đã được hoàn cạnh máy.')
    return true
end
function Slot:Complete()
    local pending=self.pending
    if not pending then return end
    local giver=self:GetGiver()
    local ok,result=false,'interrupted payment'
    if pending.bundle and pending.points then
        ok,result=core.SpawnBundle(pending.bundle,SpawnPrefab,function(entity,item,index,track)
            spawn.Configure(entity,item,pending.points[index],giver,track)
        end)
    end
    if not ok then
        print('[Nova slot] payout rolled back:',result)
        self:Refund()
        return
    end
    self:Unlock()
    self.inst:PushEvent('nova_slot_reward',{group=pending.key,bundle=pending.bundle.id,giver=giver})
    say(giver,'Máy quay: '..pending.bundle.name)
end
function Slot:OnSave()
    if self.pending then
        return {pending={currency=self.pending.currency,cost=self.pending.cost,userid=self.pending.userid}}
    end
end
function Slot:OnLoad(saved)
    local p=saved and saved.pending
    if p and ((p.currency=='xd_lingshi1' and p.cost==60) or
        ((p.currency=='xd_lingshi2' or p.currency=='xd_lingshi3' or p.currency=='xd_lingshi4') and p.cost==1)) then
        self.pending=p;self.inst.busy=true
        self.inst:DoTaskInTime(0,function()self:Refund()end)
    end
end
function Slot:OnRemoveFromEntity()
    self:Refund()
end
return Slot
