local M={}
function M.Install()
    local now, tasks, ents = 0, {}, {}
    _G.Ents=ents; _G.AllPlayers={}; _G.Prefabs={xd_lingshi1=true,xd_lingshi2=true,xd_lingshi3=true}
    _G.Class=function(ctor)
        local c={}; c.__index=c
        return setmetatable(c,{__call=function(_,...) local o=setmetatable({},c);ctor(o,...);return o end})
    end
    _G.GetTime=function() return now end
    local function schedule(inst,delay,fn,period)
        local t={at=now+delay,fn=fn,inst=inst,period=period}
        function t:Cancel() self.cancelled=true end
        tasks[#tasks+1]=t; return t
    end
    local function entity(prefab)
        local e={prefab=prefab,GUID=#ents+1,components={},tags={},listeners={},valid=true,x=0,z=0}
        ents[e.GUID]=e
        function e:IsValid() return self.valid end
        function e:HasTag(t) return self.tags[t]==true end
        function e:AddTag(t) self.tags[t]=true end
        function e:RemoveTag(t) self.tags[t]=nil end
        function e:ListenForEvent(t,fn,src) src=src or self;src.listeners[t]=src.listeners[t] or {};table.insert(src.listeners[t],{fn=fn,owner=self}) end
        function e:PushEvent(t,data) for _,l in ipairs(self.listeners[t] or {}) do l.fn(l.owner,data) end end
        function e:Remove() self:PushEvent('onremove'); self.valid=false end
        function e:DoTaskInTime(d,fn) return schedule(self,d,fn) end
        function e:DoPeriodicTask(d,fn) return schedule(self,d,fn,d) end
        function e:AddComponent(name) self.components[name]=require('components/'..name)(self) end
        function e:GetPosition() return {x=self.x,y=0,z=self.z} end
        function e:GetDistanceSqToInst(other) return (self.x-other.x)^2+(self.z-other.z)^2 end
        function e:GetCurrentPlatform() return nil end
        function e:SnapCamera() end
        e.Transform={GetWorldPosition=function() return e.x,0,e.z end,SetPosition=function(_,x,y,z) e.x=x;e.z=z end}
        e.Physics={Teleport=e.Transform.SetPosition}
        return e
    end
    _G.Vector3=function(x,y,z) return {x=x,y=y,z=z} end
    _G.SpawnPrefab=function(name)
        local e=entity(name)
        if name=='hn_dungeon_gate' or name=='hn_dungeon_exit' then e:AddTag(name) end
        return e
    end
    local world=entity('world');world.ismastersim=true;world.ismastershard=true;world:AddTag('forest')
    _G.TheWorld=world
    _G.TheNet={Announce=function() end}
    _G.TheSim={FindFirstEntityWithTag=function(_,tag) for _,e in pairs(ents) do if e.valid and e:HasTag(tag) then return e end end end,
        FindEntities=function(_,x,y,z,r) local found={} for _,e in pairs(ents) do if e.valid and (e.x-x)^2+(e.z-z)^2<=r*r then found[#found+1]=e end end return found end}
    world.Map={IsPassableAtPoint=function() return true end,IsLandTileAtPoint=function() return true end,IsOceanAtPoint=function() return false end}
    local api={world=world,entity=entity}
    function api.advance(dt)
        local stop=now+dt
        while true do
            local nexttask
            for _,t in ipairs(tasks) do if not t.cancelled and not t.done and t.at<=stop and (not nexttask or t.at<nexttask.at) then nexttask=t end end
            if not nexttask then break end
            now=nexttask.at;nexttask.fn(nexttask.inst)
            if nexttask.period and not nexttask.cancelled then nexttask.at=now+nexttask.period else nexttask.done=true end
        end
        now=stop
    end
    function api.player()
        local p=entity('wilson');p:AddTag('player');p.userid='test'..p.GUID
        p.components.health={IsDead=function() return false end}
        p.components.talker={Say=function() end};p:AddComponent('hn_dungeon_cooldown')
        AllPlayers[#AllPlayers+1]=p; return p
    end
    return api
end
return M
