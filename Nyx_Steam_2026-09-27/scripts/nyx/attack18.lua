-- Cast sequences read from the local 18.1 xd_longzhu / xd_wmz_spell / xd_htz_spell.
local SkillDamage=require('util/nyx_skill_damage')
local THUNDER_DAMAGE=100
local A={}
local function handle(owner)
    local h={entities={},tasks={},done=false}
    function h:Track(fx) if fx then self.entities[fx]=true; require("nyx/ownedfx").Attach(fx,owner) end; return fx end
    function h:Later(t,fn)
        local task=owner:DoTaskInTime(t,function()
            if not self.done and owner:IsValid() and not owner.components.health:IsDead() and not owner:HasTag('playerghost') then fn() end
        end)
        self.tasks[#self.tasks+1]=task
    end
    function h:Cancel()
        if self.done then return end
        self.done=true
        if self.skill then SkillDamage.End(owner,self.skill) end
        for _,task in ipairs(self.tasks) do task:Cancel() end
        for fx in pairs(self.entities) do if fx:IsValid() then fx:Remove() end end
    end
    function h:IsDone() return self.done end
    return h
end
function A.Prepare(owner,id,p)
    local target
    if id=='eternal_night' or id=='divine_chariot' then
        local nearest
        for _,candidate in pairs(XD_GetDamageTargets(p.x,0,p.z,8)) do
            if candidate and candidate:IsValid() and candidate~=owner and XD_CanAttackTrget(owner,candidate) then
                local x,_,z=candidate.Transform:GetWorldPosition()
                local distance=(x-p.x)^2+(z-p.z)^2
                if not nearest or distance<nearest then target,nearest=candidate,distance end
            end
        end
        if not target then return nil,'Không có kẻ địch ở điểm chọn.' end
    end
    local h=handle(owner)
    function h:Start()
        if id=='triflame_fan' or id=='eternal_night' or id=='spirit_sword' then
            self.skill=id
            SkillDamage.Begin(owner,id)
        end
        if id=='triflame_fan' then
            if not Prefabs.xd_htz_firefx then return false end
            local x,_,z=owner.Transform:GetWorldPosition()
            local angle=(x==p.x and z==p.z) and owner.Transform:GetRotation() or math.atan2(z-p.z,p.x-x)*RADIANS
            local targets={}
            for k=-45,45,22.5 do
                local fx=self:Track(SpawnPrefab('xd_htz_firefx'))
                if not fx then return false end
                fx.Transform:SetPosition(x,0,z); fx.targets=targets
                if k==-45 or k==45 then fx.build='xd_htz_firefx' end
                fx:SetFlamethrowerAttacker(owner); fx.baseangle=angle; fx.addangle=k
                self:Later(8.1,function() if fx:IsValid() then fx:KillFX() end end)
            end
            for i=0,4 do
                local theta=angle*DEGREES+i*2*PI/5
                self:Later(math.random()*.2,function()
                    self:Track(require('nyx/fan_shadowfire')(owner,x+2*math.cos(theta),z-2*math.sin(theta),theta*RADIANS))
                end)
            end
            self:Later(15,function() self:Cancel() end)
        elseif id=='divine_chariot' then
            if not target:IsValid() or not XD_CanAttackTrget(owner,target) then return false end
            for i=1,3 do if not Prefabs['xd_wmz_butterfly'..i] then return false end end
            local pt=owner:GetPosition()
            local function spawn()
                local offset=FindWalkableOffset(pt,math.random()*2*PI,2,6,true) or Vector3(0,0,0)
                local fx=self:Track(SpawnPrefab('xd_wmz_butterfly'..math.random(3)))
                if not fx then return false end
                fx.Transform:SetPosition((pt+offset):Get()); fx:SetOwner(owner,target)
                return true
            end
            if not spawn() then return false end
            self:Later(.2,spawn); self:Later(.4,spawn)
            self:Later(14,function() self:Cancel() end)
        elseif id=='ice_array' then
            local fx=self:Track(SpawnPrefab('nyx_ice_circle'))
            if not fx then return false end
            fx.owner=owner; fx.Transform:SetPosition(p.x,0,p.z)
            self:Later(.4,function() if fx:IsValid() then fx:TriggerFX() end end)
            self:Later(6,function() if fx:IsValid() then fx:KillFX() end end)
            self:Later(8,function() self:Cancel() end)
        elseif id=='falling_thunder' then
            local x,_,z=owner.Transform:GetWorldPosition()
            local elapsed=0
            for k=0,16 do
                local angle=k*4*PI/16; local r=math.random(3,15)
                local tx,tz=x+r*math.cos(angle),z+r*math.sin(angle)
                self:Later(elapsed,function()
                    local fx=self:Track(SpawnPrefab('lightning'))
                    if fx then fx.Transform:SetPosition(tx,0,tz) end
                    for _,enemy in pairs(XD_GetDamageTargets(tx,0,tz,TUNING.LIGHTNING_STRIKE_RADIUS)) do
                        if enemy and enemy:IsValid() and enemy~=owner and XD_CanAttackTrget(owner,enemy) then
                            local damage=Xd_CalcDamage(owner,THUNDER_DAMAGE,enemy)
                            SkillDamage.Apply(owner,enemy,damage,'electric')
                        end
                    end
                end)
                elapsed=elapsed+.3+math.random()*.2
            end
            self:Later(elapsed+2,function() self:Cancel() end)
        elseif id=='eternal_night' then
            if not target:IsValid() or not XD_CanAttackTrget(owner,target) then return false end
            local fx=self:Track(SpawnPrefab('nyx_wmz_profire'))
            if not fx then return false end
            fx.Transform:SetPosition(owner.Transform:GetWorldPosition()); fx.owner=owner
            fx:SetLevel(nil,nil,nil); fx.Transform:SetScale(1.5,1.5,1.5)
            fx.components.projectile:Throw(owner,target,owner)
            self:Later(20,function() self:Cancel() end)
        elseif id=='spirit_sword' then
            local drones,vertices={},{}
            -- Validate prefab availability before the first side effect.
            if not Prefabs.nyx_htz_smallxtj or not Prefabs.nyx_htz_trap_spell then return false end
            for i=1,5 do
                local angle=(i-1)*2*PI/5
                local x,z=p.x+5*math.cos(angle),p.z+5*math.sin(angle)
                local fx=self:Track(SpawnPrefab('nyx_htz_smallxtj'))
                if not fx then return false end
                fx.Transform:SetPosition(x,0,z); fx.owner=owner; fx.othersword=drones
                drones[fx]=true; vertices[#vertices+1]={x,z}
            end
            local spell=self:Track(SpawnPrefab('nyx_htz_trap_spell'))
            if not spell then return false end
            spell.Transform:SetPosition(p.x,0,p.z); spell.owner=owner; spell.vertexs=vertices
            self:Later(12,function() self:Cancel() end)
        else return false end
        return true
    end
    return h
end
return A
