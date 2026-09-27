-- Vân Tiêu 18.1: native combat, healing, rocks and temporary terrain.
local M={}
local SkillDamage=require('util/nyx_skill_damage')
local prefabs={'groundpoundring_fx','xd_yunxiao_swamp_terraformer','xd_yunxiao_jjj_aoeent'}
local function remove(e) if e and e:IsValid() then e:Remove() end end
function M.Prepare(owner)
    for _,name in ipairs(prefabs) do
        if not Prefabs[name] then return nil,'Thiếu kỹ năng Vân Tiêu trong Tu Tiên 18.1.' end
    end
    local h={done=false,started=false}
    function h:Cancel()
        SkillDamage.End(owner,'yellow_river')
        if self.zone then
            for _,rock in ipairs(self.zone.rocks or {}) do remove(rock) end
        end
        remove(self.zone); remove(self.ring)
        -- Active terraformer must survive: its own timer restores the old tiles.
        -- Removing it cancels its pending restoration tasks and strands desert tiles.
        if not self.terrain_started then remove(self.terrain) end
        self.done=true
    end
    function h:Start()
        if self.started or self.done then return false end
        self.started=true
        self.ring=SpawnPrefab(prefabs[1])
        self.terrain=SpawnPrefab(prefabs[2])
        self.zone=SpawnPrefab(prefabs[3])
        if not self.ring or not self.terrain or not self.zone or not self.terrain.DoTerraform then
            self:Cancel(); return false
        end
        local x,_,z=owner.Transform:GetWorldPosition()
        for _,e in ipairs({self.ring,self.terrain,self.zone}) do e.Transform:SetPosition(x,0,z) end
        local width=(TUNING.WURT_TERRAFORMING_TILERANGE+.5)*TILE_SCALE
        local scale=math.sqrt(math.sqrt(2*width*width)/12)
        self.ring.Transform:SetScale(scale,scale,scale)
        self.zone.owner=owner
        SkillDamage.Begin(owner,'yellow_river')
        for _,event in ipairs({'death','ms_becameghost','onremove'}) do
            self.zone:ListenForEvent(event,function() self:Cancel() end,owner)
        end
        self.zone:ListenForEvent('onremove',function()
            SkillDamage.End(owner,'yellow_river')
            self.done=true
        end)
        self.terrain_started=true
        self.terrain:DoTerraform()
        return true
    end
    function h:IsDone() return self.done or (self.zone~=nil and not self.zone:IsValid()) end
    return h
end
return M
