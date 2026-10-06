package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path
function Class(ctor)
    local cls={}; cls.__index=cls
    return setmetatable(cls,{__call=function(_,inst)
        local self=setmetatable({},cls); ctor(self,inst); return self
    end})
end
local events, spawned = {}, {}
local player={entity={},components={},prefab='nyx',dead=false}
function player:ListenForEvent(event,fn) events[event]=fn end
function player:HasTag(tag) return tag=='playerghost' and self.dead end
function player:IsValid() return true end
player.components.health={IsDead=function() return player.dead end}
local function box()
    local b={entity={},Transform={},Network={},components={},valid=true}
    function b:IsValid() return self.valid end
    function b.entity:SetParent(parent) b.parent=parent end
    function b.Transform:SetPosition(x,y,z) b.pos={x,y,z} end
    function b.Network:SetClassifiedTarget(target) b.target=target end
    function b:Remove() self.valid=false end
    function b:PushEvent(event) self.last_event=event end
    local c={slots={}}
    function c:Open(who) self.opener=who end
    function c:Close() self.opener=nil end
    function c:IsOpenedBy(who) return self.opener==who end
    function c:DropEverything() self.dropped=self.slots; self.slots={} end
    b.components.container=c
    function b:GetSaveRecord() return {prefab='nyx_gem_storage',items=c.slots},{123} end
    spawned[#spawned+1]=b
    return b
end
function SpawnPrefab(id) assert(id=='nyx_gem_storage'); return box() end
function SpawnSaveRecord(record,newents)
    assert(newents.marker)
    local b=box(); b.components.container.slots=record.items; return b
end
local ok,Storage=pcall(require,'components/nyx_gem_storage')
assert(ok,'persistent gem storage component must exist')
local store=Storage(player)
assert(store.box==nil,'do not spawn until used or loaded')
local auto_container=store:GetContainer()
assert(auto_container~=nil and auto_container.opener==nil,
    'auto pickup creates persistent private box without opening UI')
assert(store:Toggle())
local b=store.box
assert(b.parent==player.entity and b.target==player and b.nyx_owner==player)
assert(b.persists==false,'save with character only; never duplicate in world save')
local stone={prefab='hh_effect_stone',data={code='LK_IV',value=17}}
b.components.container.slots[36]=stone
store:Toggle()
assert(b.components.container.opener==nil and b.components.container.slots[36]==stone,
    'closing must keep the same item and its attributes')
store:Toggle()
assert(store.box==b and #spawned==1,'reopening must reuse the same box')
local saved,refs=store:OnSave()
assert(refs[1]==123,'forward save references')
local restored=Storage(player)
restored:OnLoad(saved,{marker=true})
assert(restored.box.components.container.slots[36].data.value==17,
    'save/load must preserve attributes and slot 36')
assert(restored.box.target==player and restored.box.persists==false)
player.dead=true
assert(store:GetContainer()==nil,'auto pickup must not create/use storage while dead')
assert(not store:Toggle(),'ghost/dead owner cannot open storage')
events.ms_becameghost()
assert(restored.box.components.container.opener==nil)
assert(type(events.ms_playerreroll)=='function','reroll must preserve contents before character deletion')
events.ms_playerreroll()
assert(restored.box.components.container.dropped[36]==stone,'reroll drops the stored items intact')
assert(next(restored.box.components.container.slots)==nil)
store:OnRemoveFromEntity()
assert(not b.valid,'remove transient child when owner leaves; save already holds contents')
print('gem_storage_component_test: ok')
