-- Pass the extracted scripts/widgets/containerwidget.lua from DST as arg[1].
-- Native Open/Close run here; rendering and the simulation scheduler are doubles.
package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path
local Rules = require('nyx/gem_storage')
function Class() return {} end
package.preload.class = function() return Class end
for _, name in ipairs({'widget', 'text', 'uianim', 'imagebutton', 'itemtile'}) do
    package.preload['widgets/'..name] = function() return {} end
end
package.preload['widgets/invslot'] = function()
    return function()
        return {SetPosition=function() end, Kill=function(self) self.killed=true end}
    end
end
local Native = dofile(assert(arg[1], 'provide native containerwidget.lua path'))
local containers = {params={}, MAXITEMSLOTS=0}
package.preload.containers = function() return containers end
function Vector3(x,y,z) return {x=x,y=y,z=z} end
TheNet = {IsDedicated=function() return false end}
local hook
Rules.Install({
    AddPrefabPostInit=function() end, AddComponentPostInit=function() end,
    AddModRPCHandler=function() end,
    AddClassPostConstruct=function(path, fn)
        if path == 'widgets/containerwidget' then hook=fn end
    end,
})
local function make(prefab)
    local tasks, removed = {}, {}
    local anim = {SetBank=function() end, SetBuild=function() end,
        PlayAnimation=function(self, name) self.animation=name end}
    local widget = setmetatable({isopen=false, inv={}, shown=false,
        owner={components={}}, bgimage={},
        bganim={GetAnimState=function() return anim end},
        inst={ListenForEvent=function() end,
            RemoveEventCallback=function(_, event) removed[event]=true end,
            DoSimTaskInTime=function(_, delay, fn) tasks[#tasks+1]=fn end},
        Show=function(self) self.shown=true end,
        Hide=function(self) self.shown=false end,
        SetPosition=function() end,
        AddChild=function(_, child) return child end,
        Refresh=function() end,
    }, {__index=Native})
    if hook then hook(widget) end
    local box = {prefab=prefab, replica={container={
        GetWidget=function() return containers.params.nyx_gem_storage.widget end,
        IsInfiniteStackSize=function() return false end,
        IsReadOnlyContainer=function() return false end,
        IsSideWidget=function() return false end,
    }}}
    return widget, box, tasks, removed, anim
end
local widget, box, tasks, removed = make('nyx_gem_storage')
for cycle=1,3 do
    widget:Open(box, widget.owner)
    assert(widget.shown and widget.isopen and #widget.inv==36, 'reopen shows all slots')
    local slots=widget.inv
    widget:Close()
    -- Do not advance simulation: the UI must disappear even while paused.
    assert(not widget.shown, 'closed gem storage must not leave its background visible')
    assert(not widget.isopen and widget.container==nil and #widget.inv==0)
    assert(removed.itemlose and removed.itemget and removed.refresh, 'native event cleanup retained')
    for _, slot in ipairs(slots) do assert(slot.killed, 'native slot cleanup retained') end
    widget:Close()
end
assert(#tasks==3, 'repeat close does not duplicate native cleanup')
tasks[1]()
assert(widget.should_close_widget, 'native delayed disposal retained')
local other, otherbox, _, _, anim = make('treasurechest')
other:Open(otherbox, other.owner)
other:Close()
assert(other.shown and anim.animation=='close', 'other containers retain closing animation')
print('gem_storage_close_test: ok (native Lua methods, mocked rendering/scheduler)')
