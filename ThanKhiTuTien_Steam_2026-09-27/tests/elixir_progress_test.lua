package.path = 'ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;' .. package.path
dofile(assert(os.getenv('DST_TEST_SCRIPTS')) .. '/class.lua')
local Progress = require('components/tbc_elixir_progress')
local Resources = require('tbc_elixir/resources')
local Effects = require('components/tbc_player_effects')
local Combat = require('tbc_combat')
local Immunity = require('tbc_affix/immunity')
local Passives = require('tbc_affix/passives')
local NativeHealth
if os.getenv('DST_HEALTH_SOURCE') then
    package.preload['util/sourcemodifierlist']=function() return {} end
    NativeHealth=assert(loadfile(os.getenv('DST_HEALTH_SOURCE')))()
end
local function eq(a,b,label) assert(math.abs(a-b)<1e-8,label..': '..tostring(a)..' ~= '..b) end
local function player()
    local p = {components={}, tasks={}, events={}, tags={player=true}}
    function p:HasTag(tag) return self.tags[tag] or false end
    function p:IsValid() return true end
    function p:DoTaskInTime(_, fn) self.tasks[#self.tasks+1]=fn end
    function p:PushEvent(name,data) self.events[#self.events+1]={name,data} end
    function p:Flush() local tasks=self.tasks; self.tasks={}; for _,fn in ipairs(tasks) do fn(self) end end
    local h = {inst=p,maxhealth=125,currenthealth=80}
    function h:SetMaxHealth(v) self.maxhealth=v; self.currenthealth=v end
    function h:GetMaxWithPenalty() return self.maxhealth*(1-(self.penalty or 0)) end
    function h:GetPercent() return self.currenthealth/self.maxhealth end
    function h:SetPercent(v) self:SetCurrentHealth(v*self.maxhealth) end
    function h:TransferComponent(newinst) newinst.components.health:SetPercent(self:GetPercent()) end
    if NativeHealth then h.TransferComponent=NativeHealth.TransferComponent end
    function h:SetCurrentHealth(v) self.currenthealth=math.min(v,self:GetMaxWithPenalty()) end
    function h:DoDelta(v) self:SetCurrentHealth(self.currenthealth+v) end
    function h:IsDead() return self.currenthealth<=0 end
    function h:OnLoad(data) if data.maxhealth then self.maxhealth=data.maxhealth end; self:SetCurrentHealth(data.health) end
    function h:OnSave() return {health=self.currenthealth,maxhealth=self.maxhealth} end
    local mana = {inst=p,max=60,current=30,native_max=60}
    function mana:SetMax(v) self.max=v; self.current=v end
    function mana:CheckLevel() self.max=self.native_max; self:DoDelta(0) end
    function mana:DoDelta(v) self.current=math.max(0,math.min(self.max,self.current+v)) end
    function mana:OnSave() return {max=self.max,current=self.current} end
    function mana:OnLoad(data) self.max=data.max; self.current=data.current; self:DoDelta(0) end
    p.components.health=h; p.components.xd_htz_lq=mana
    p.components.locomotor={SetExternalSpeedMultiplier=function(self,_,key,value) self[key]=value end}
    p.components.tbc_player_effects=Effects(p)
    p.components.tbc_elixir_progress=Progress(p)
    Resources.Install(h,'health'); Resources.Install(mana,'mana')
    return p
end
local p=player(); local progress=p.components.tbc_elixir_progress
local health,mana=p.components.health,p.components.xd_htz_lq
for n=1,10 do
    assert(progress:Consume('health')); assert(progress:Consume('mana'))
    eq(progress:GetCount('health'),n,'health counter')
    eq(health.maxhealth,125+50*n,'health maximum')
    eq(health.currenthealth,80,'increase does not refill health')
    eq(mana.max,60+10*n,'mana maximum'); eq(mana.current,30,'increase does not refill mana')
end
eq(health.maxhealth,625,'health cap'); eq(mana.max,160,'mana cap')
eq(progress:GetBonus('mana'),100,'ten elixirs grant at most 100 mana')
assert(progress:Consume('health')); assert(progress:Consume('mana'))
eq(health.currenthealth,180,'health recovery after cap'); eq(mana.current,130,'mana recovery after cap')
eq(progress:GetCount('health'),10,'recovery does not increment count')
for _,key in ipairs({'power','guard','speed','crit'}) do
    for _=1,10 do assert(progress:Consume(key)) end
    assert(not progress:CanConsume(key) and not progress:Consume(key),'blocked after10: '..key)
end
eq(Combat.SoloArmorPierce(p),500,'true damage')
eq(Combat.StatsForOwner(p).crit_effect,150,'crit damage from both milestones')
eq(Combat.StatsForOwner(p).crit_rate,10,'crit chance unchanged')
eq(Combat.SoloDefense(p,700),200,'flat defense')
eq(p.components.locomotor.tbc_elixir,1.2,'move speed')
for _,status in ipairs({'hot','cold','sleep','poison','freeze'}) do assert(Immunity.Has(p,status),status) end
progress:Refresh(); progress:Refresh()
eq(health.maxhealth,625,'refresh idempotent'); eq(mana.max,160,'mana refresh idempotent')
health:SetMaxHealth(200); eq(health.maxhealth,700,'new native base')
mana.native_max=90; mana:CheckLevel(); eq(mana.max,190,'native mana level change')
eq(mana.current,130,'level change preserves augmented current')
p._tbc_affix_mana={component=mana,max_bonus=100}; mana.max=mana.max+100
mana:CheckLevel(); eq(mana.max,290,'level change preserves equipment mana')
local saved={progress=progress:OnSave(),health=health:OnSave(),mana=mana:OnSave()}
eq(saved.health.maxhealth,200,'save excludes permanent health from base')
eq(saved.mana.max,90,'save excludes potion/equipment mana')
for _=1,3 do
    local copy=player()
    copy.components.health:OnLoad(saved.health)
    copy.components.xd_htz_lq:OnLoad(saved.mana)
    copy.components.tbc_elixir_progress:OnLoad(saved.progress)
    copy:Flush()
    eq(copy.components.health.maxhealth,700,'load health maximum')
    eq(copy.components.health.currenthealth,saved.health.health,'load current health')
    eq(copy.components.xd_htz_lq.max,190,'load mana maximum')
    eq(copy.components.xd_htz_lq.current,saved.mana.current,'load mana current')
    saved={progress=copy.components.tbc_elixir_progress:OnSave(),health=copy.components.health:OnSave(),mana=copy.components.xd_htz_lq:OnSave()}
end
local other=player(); progress:TransferComponent(other)
eq(other.components.tbc_elixir_progress:GetCount('crit'),10,'transfer count')
eq(other.components.health.maxhealth,625,'transfer uses new character base')
p.tags.playerghost=true; health.currenthealth=0
progress:Refresh(); eq(health.currenthealth,0,'ghost stays dead'); assert(not progress:CanConsume('health'))
p.tags.playerghost=nil; health.currenthealth=50; progress:Refresh()
eq(Combat.SoloArmorPierce(p),500,'bonuses survive revival')
assert(not progress:Consume('invalid'),'reject unknown elixir')
local plain=player(); plain.components.xd_htz_lq=nil
assert(not plain.components.tbc_elixir_progress:CanConsume('mana'),'no invented mana resource')
plain.components.tbc_elixir_progress:OnLoad({counts={power=0/0,crit=math.huge,health=100,mana=-1,speed='garbage'}})
plain:Flush()
eq(plain.components.tbc_elixir_progress:GetCount('health'),10,'clamp old save'); eq(plain.components.tbc_elixir_progress:GetCount('crit'),0,'reject nonfinite counts')
local gear={{code='equip_max_health_iii',value=20}}
for _,order in ipairs({'equip_before_refresh','equip_after_refresh','equip_before_load'}) do
    local copy=player(); local h=copy.components.health; local cp=copy.components.tbc_elixir_progress
    if order=='equip_before_load' then Passives.Reconcile(copy,gear) end
    cp:OnLoad({counts={health=10}})
    h:OnLoad({maxhealth=125,health=500})
    if order=='equip_after_refresh' then copy:Flush() end
    Passives.Reconcile(copy,gear)
    copy:Flush()
    eq(h.maxhealth,650,'health equipment/load composition: '..order)
    eq(h:OnSave().maxhealth,125,'save excludes equipment and potions')
    h:SetMaxHealth(200)
    eq(h.maxhealth,740,'native health recalculation retains equipment')
    Passives.Remove(copy)
    eq(h.maxhealth,700,'unequip after native recalculation')
    Passives.Reconcile(copy,gear)
    eq(h.maxhealth,740,'reequip after native recalculation')
end
for _,health_first in ipairs({true,false}) do
    local source,target=player(),player()
    source.components.tbc_elixir_progress:OnLoad({counts={health=10}}); source:Flush()
    source.components.health:SetCurrentHealth(500)
    if health_first then source.components.health:TransferComponent(target) end
    source.components.tbc_elixir_progress:TransferComponent(target)
    if not health_first then source.components.health:TransferComponent(target) end
    eq(target.components.health.maxhealth,625,'transfer maximum independent of component order')
    eq(target.components.health.currenthealth,500,'transfer health independent of component order')
end
print('elixir_progress_test: counts, permanent stats, recovery, save/load, transfer and immunity passed')
