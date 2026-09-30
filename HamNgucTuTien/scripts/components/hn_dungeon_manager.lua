local Authority=require('hn_dungeon/authority')
local Gates=require('hn_dungeon/gates')
local Waves=require('hn_dungeon/waves')
local function valid(e) return e~=nil and e:IsValid() end
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function teleport(p,x,z)
    if not valid(p) or x==nil or z==nil then return false end
    if p.Physics then p.Physics:Teleport(x,0,z) else p.Transform:SetPosition(x,0,z) end
    if p.SnapCamera then p:SnapCamera() end
    return true
end
local Manager=Class(function(self,inst)
    self.inst=inst;self.state='COOLDOWN';self.current_wave=0;self.max_waves=3;self.run_epoch=1
    self.monsters={};self.players_in_dungeon={};self.run_entities={};self.tasks={};self.pending_spawns=0
    self.dungeon_center_x=0;self.dungeon_center_z=0
    if not self:IsSurfaceAuthority() then return end
    self.initialization_task=inst:DoTaskInTime(.2,function() self:Initialize() end)
    self.position_task=inst:DoPeriodicTask(.5,function() self:CheckPlayerPositions() end)
    inst:ListenForEvent('ms_playerleft',function(_,p) if self.players_in_dungeon[p] then self:Leave(p,'disconnect') end end)
    inst:ListenForEvent('ms_playerjoined',function(_,p)
        p:DoTaskInTime(.1,function()
            if valid(p) and self.state~='IN_PROGRESS' then
                local x,_,z=p.Transform:GetWorldPosition()
                if self:IsPointInsideDungeon(x,z) then self:TeleportPlayerToRunGate(p) end
                p:RemoveTag('in_hn_dungeon')
            end
        end)
    end)
end)
for name,fn in pairs(Gates) do Manager[name]=fn end
function Manager:IsSurfaceAuthority() return Authority.IsAuthority(self.inst) end
function Manager:HasRewards()
    return Prefabs~=nil and Prefabs.xd_lingshi1~=nil and Prefabs.xd_lingshi2~=nil and Prefabs.xd_lingshi3~=nil
end
function Manager:FindArena()
    local e=TheSim:FindFirstEntityWithTag('hn_dungeon_exit')
    if not valid(e) then return false end
    local x,_,z=e.Transform:GetWorldPosition()
    self.exit=e;self.dungeon_center_x=x;self.dungeon_center_z=z
    return true
end
function Manager:Initialize()
    if self.loaded or not self:IsSurfaceAuthority() then return end
    self.max_waves=math.random(2,10)
    self:TrySpawnGate(false)
end
function Manager:IsPointInsideDungeon(x,z)
    if not valid(self.exit) and not self:FindArena() then return false end
    return x~=nil and z~=nil and (x-self.dungeon_center_x)^2+(z-self.dungeon_center_z)^2<=45*45
end
function Manager:Schedule(delay,fn)
    local epoch=self.run_epoch
    local task=self.inst:DoTaskInTime(delay,function() if self.run_epoch==epoch then fn() end end)
    self.tasks[#self.tasks+1]=task;return task
end
function Manager:CancelRunTasks()
    for _,t in ipairs(self.tasks) do t:Cancel() end
    self.tasks={};self.pending_spawns=0
end
function Manager:Publish()
    self.inst:PushEvent('hn_dungeon_state_changed',{state=self.is_cleared and 'COOLDOWN' or self.state,stages=self.max_waves,run_id=self.run_epoch})
end
function Manager:IsActiveGate(gate) return valid(gate) and gate==self.active_gate and gate.prefab=='hn_dungeon_gate' end
function Manager:TrySpawnGate(prefer_saved)
    if not self:IsSurfaceAuthority() or not self:FindArena() or not self:HasRewards() then
        self.unavailable_reason='Thiếu đấu trường hoặc Linh Thạch Tu Tiên. Cần bật Tu Tiên và tạo thế giới mới.'
        return false
    end
    if valid(self.active_gate) then return true end
    local x,z
    if prefer_saved and self.run_gate_x and self:IsValidGatePoint(self.run_gate_x,self.run_gate_z,true) then
        x,z=self.run_gate_x,self.run_gate_z
    else x,z=self:FindMainlandGatePoint(false);if not x then x,z=self:FindMainlandGatePoint(true) end end
    if not x then
        if not self.gate_retry then self.gate_retry=self.inst:DoTaskInTime(5,function() self.gate_retry=nil;self:TrySpawnGate(prefer_saved) end) end
        return false
    end
    local gate=SpawnPrefab('hn_dungeon_gate')
    if not valid(gate) then return false end
    self.run_gate_x=x;self.run_gate_z=z;gate.Transform:SetPosition(x,0,z);self.active_gate=gate
    if self.state=='COOLDOWN' then self.state='READY' end
    self:Publish()
    if self.state=='READY' then
        self.unentered_end=GetTime()+(self.unentered_remaining or 480);self.unentered_remaining=nil
        if self.unentered_task then self.unentered_task:Cancel() end
        self.unentered_task=self:Schedule(math.max(0,self.unentered_end-GetTime()),function()
            if self.state=='READY' then
                local gx,gz=self.run_gate_x,self.run_gate_z;local total=self.max_waves
                self:Fail('unentered_timeout')
                require('hn_dungeon/spawner').SpawnDetached(self,gx,gz,total)
            end
        end)
    end
    return true
end
function Manager:OnGateRemoved(gate)
    if gate~=self.active_gate then return end
    self.active_gate=nil
    if not self.removing_gate then self:Schedule(5,function() self:TrySpawnGate(true) end) end
end
function Manager:RemoveGate()
    self.removing_gate=true
    if valid(self.active_gate) then self.active_gate:Remove() end
    self.active_gate=nil;self.removing_gate=false
end
function Manager:CanEnter(player)
    if not self:IsSurfaceAuthority() or not valid(player) or player:HasTag('playerghost')
        or not player.components.health or player.components.health:IsDead() then return false,'Không thể vào lúc này.' end
    if not self:HasRewards() or not self:FindArena() then return false,'Thiếu đấu trường hoặc vật phẩm Tu Tiên.' end
    if self.players_in_dungeon[player] or not self:IsActiveGate(self.active_gate) or self.state=='COOLDOWN' or self.is_cleared then return false,'Hầm Ngục chưa sẵn sàng.' end
    if self.current_wave>=2 then return false,'Đã quá trễ để nhập cuộc.' end
    if player.components.hn_dungeon_cooldown and player.components.hn_dungeon_cooldown:GetTime()>0 then return false,'Bạn đang hồi chiêu Hầm Ngục.' end
    if require('hn_dungeon/companions').HasToken(player.components.inventory) then
        return false,'Hãy cất vật phẩm gọi đồng hành trước khi vào Hầm Ngục.'
    end
    if player.components.leader then
        for follower in pairs(player.components.leader.followers) do
            if valid(follower) and follower.prefab~='abigail' and follower.prefab~='wobybig' and follower.prefab~='wobysmall' then
                return false,'Hãy để đồng hành ở ngoài trước khi vào Hầm Ngục.'
            end
        end
    end
    return true
end
function Manager:Enter(player)
    local ok,reason=self:CanEnter(player)
    if not ok then if valid(player) and player.components.talker then player.components.talker:Say(reason) end;return false end
    if player.components.rider and player.components.rider:IsRiding() then player.components.rider:Dismount() end
    if not teleport(player,self.dungeon_center_x,self.dungeon_center_z+4) then return false end
    self.players_in_dungeon[player]=true;player:AddTag('in_hn_dungeon')
    if self.unentered_task then self.unentered_task:Cancel();self.unentered_task=nil end
    if self.state=='READY' then
        self.state='IN_PROGRESS';self:Publish()
        self:Schedule(5,function() if self.state=='IN_PROGRESS' then self:StartWave(1) end end)
    end
    return true
end
function Manager:TeleportPlayerToRunGate(player)
    local x,z=self.run_gate_x,self.run_gate_z
    if x==nil then
        local portal=TheSim:FindFirstEntityWithTag('multiplayer_portal') or TheSim:FindFirstEntityWithTag('spawnpoint_multiplayer')
        if valid(portal) then local px,_,pz=portal.Transform:GetWorldPosition();x,z=px,pz end
    end
    return teleport(player,x,z)
end
function Manager:Leave(player,reason)
    if not self.players_in_dungeon[player] then return false end
    if reason=='dungeon_exit' and self.boss_active then return false end
    self.players_in_dungeon[player]=nil
    if valid(player) then
        player:RemoveTag('in_hn_dungeon');self:TeleportPlayerToRunGate(player)
        local cd=player.components.hn_dungeon_cooldown
        if cd then cd:StartTimer(reason=='death' and 960 or 480) end
    end
    if count(self.players_in_dungeon)==0 and self.state=='IN_PROGRESS' then self:Reset(self.is_cleared and 'cleared' or 'last_player_left') end
    return true
end
function Manager:Track(entity,epoch)
    if not valid(entity) then return entity end
    if not entity.components.hn_owned then entity:AddComponent('hn_owned') end
    entity.components.hn_owned.run_id=epoch or self.run_epoch
    self.run_entities[entity]=true;entity.hn_dungeon_manager=self;entity.hn_dungeon_run_epoch=epoch or self.run_epoch
    return entity
end
function Manager:StartWave(n)
    if self.state~='IN_PROGRESS' or self.is_cleared then return end
    self.current_wave=n;self.wave_finishing=false
    local spec=Waves.Get(n,self.max_waves);self.boss_active=spec.is_boss
    if valid(self.exit) and self.boss_active then self.exit:AddTag('hn_locked_by_boss') end
    TheNet:Announce('Hầm Ngục: '..(spec.is_boss and 'BOSS ĐÃ XUẤT HIỆN!' or ('Làn sóng '..n)))
    require('hn_dungeon/spawner').Start(self,spec,self.run_epoch)
end
function Manager:OnMonsterDeath(monster)
    if self.state~='IN_PROGRESS' or self.is_cleared or not self.monsters[monster] or monster.hn_dungeon_run_epoch~=self.run_epoch then return end
    self.monsters[monster]=nil
    require('hn_dungeon/rewards').Monster(self,monster)
    self:CheckWaveComplete(monster)
end
function Manager:CheckWaveComplete(last)
    if self.state~='IN_PROGRESS' or self.wave_finishing or self.pending_spawns>0 or next(self.monsters) then return end
    self.wave_finishing=true
    if self.current_wave<self.max_waves then
        self:Schedule(10,function() self:StartWave(self.current_wave+1) end)
    else
        self.is_cleared=true;self.boss_active=false;self.cleared_end=GetTime()+180
        if valid(self.exit) then self.exit:RemoveTag('hn_locked_by_boss') end
        require('hn_dungeon/rewards').GrantClear(self,self.run_epoch,last and last:GetPosition() or {x=self.dungeon_center_x,z=self.dungeon_center_z})
        self:Publish()
        self:Schedule(180,function() self:Reset('success_timeout') end)
    end
end
function Manager:Reset(reason)
    self.state='COOLDOWN';self.run_epoch=self.run_epoch+1;self:CancelRunTasks();self:RemoveGate()
    for p in pairs(self.players_in_dungeon) do
        if valid(p) then
            p:RemoveTag('in_hn_dungeon');self:TeleportPlayerToRunGate(p)
            if p.components.hn_dungeon_cooldown then p.components.hn_dungeon_cooldown:StartTimer(480) end
        end
    end
    self.players_in_dungeon={}
    require('hn_dungeon/cleanup').Run(self)
    self.state='COOLDOWN';self.current_wave=0;self.is_cleared=false;self.boss_active=false
    if valid(self.exit) then self.exit:RemoveTag('hn_locked_by_boss') end
    self:Publish();self:StartCooldown(480)
end
function Manager:Fail(reason) if self.state~='COOLDOWN' then self:Reset(reason) end end
function Manager:StartCooldown(seconds)
    if self.cooldown_task then self.cooldown_task:Cancel() end
    self.cooldown_end=GetTime()+seconds
    self.cooldown_task=self.inst:DoTaskInTime(seconds,function()
        self.previous_gate_x=self.run_gate_x;self.previous_gate_z=self.run_gate_z
        self.max_waves=math.random(2,10);self:TrySpawnGate(false)
    end)
end
function Manager:CheckPlayerPositions()
    if not self:FindArena() then return end
    for _,p in ipairs(AllPlayers) do
        if valid(p) then
            local x,_,z=p.Transform:GetWorldPosition();local inside=self:IsPointInsideDungeon(x,z)
            if self.players_in_dungeon[p] then
                if p:HasTag('playerghost') then self:Leave(p,'death')
                elseif not inside then teleport(p,self.dungeon_center_x,self.dungeon_center_z+4) end
            elseif inside then self:TeleportPlayerToRunGate(p);p:RemoveTag('in_hn_dungeon') end
        end
    end
end
function Manager:OnSave()
    return {version=1,state=self.state,is_cleared=self.is_cleared,max_waves=self.max_waves,run_epoch=self.run_epoch,
        run_gate_x=self.run_gate_x,run_gate_z=self.run_gate_z,previous_gate_x=self.previous_gate_x,previous_gate_z=self.previous_gate_z,
        cooldown_remaining=math.max(0,(self.cooldown_end or 0)-GetTime()),
        unentered_remaining=math.max(0,(self.unentered_end or GetTime()+480)-GetTime())}
end
function Manager:OnLoad(data)
    if not self:IsSurfaceAuthority() or not data then return end
    self.loaded=true;self:CancelRunTasks();if self.initialization_task then self.initialization_task:Cancel() end
    self.run_epoch=(data.run_epoch or 0)+1;self.max_waves=data.max_waves or 3
    self.run_gate_x=data.run_gate_x;self.run_gate_z=data.run_gate_z;self.previous_gate_x=data.previous_gate_x;self.previous_gate_z=data.previous_gate_z
    self.state='COOLDOWN';self.is_cleared=false
    self.inst:DoTaskInTime(.5,function()
        self:FindArena();self:RemoveGate();require('hn_dungeon/cleanup').Run(self)
        if data.state=='READY' then self.unentered_remaining=data.unentered_remaining;self:TrySpawnGate(true)
        else self:StartCooldown(data.state=='IN_PROGRESS' and 480 or (data.cooldown_remaining or 480)) end
    end)
end
function Manager:OnRemoveFromEntity()
    self:CancelRunTasks()
    for _,name in ipairs({'initialization_task','position_task','cooldown_task','gate_retry'}) do if self[name] then self[name]:Cancel() end end
end
Manager.EnterDungeon=Manager.Enter;Manager.LeaveDungeon=Manager.Leave;Manager.CanEnterDungeon=Manager.CanEnter
Manager.TrackRunEntity=Manager.Track
return Manager
