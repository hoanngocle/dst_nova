local PROTECTOR_RESPAWN_TIME = chasni_getmobconfig("mermprotector", "CD") or TUNING.TOTAL_DAY_TIME * 1
local SPAWN_DIST = 30

local MermProtectorSpawner = Class(function(self, inst)
    self.inst = inst
    self.protectorRespawnTime = 0
end)

function MermProtectorSpawner:OnSave()
    local data = {}
    if self.protectorRespawnTime then
        local time = GetTime()
        if self.protectorRespawnTime > time then
            data.protectorRespawnTime = self.protectorRespawnTime - time
        end
    end
    return data
end

function MermProtectorSpawner:OnLoad(data)
    if data then
        self.protectorRespawnTime = data.protectorRespawnTime and data.protectorRespawnTime + GetTime() or nil
    end
end

function MermProtectorSpawner:SpawnProtector()
    if self.inst.components.allachivcoin and self.inst.components.allachivcoin.expertwurt2 and not self.inst.components.leader:IsBeingFollowedBy("mermprotector") then
        local pt = self.inst:GetPosition()
        local spawn_pt = chasni_getspawnpoint(pt, SPAWN_DIST)
        if spawn_pt then
            local mermprotector = SpawnPrefab("mermprotector")
            if mermprotector then
                mermprotector.Physics:Teleport(spawn_pt:Get())
                mermprotector:FacePoint(pt:Get())
                if mermprotector.components.follower.leader ~= self.inst then
                    mermprotector.components.follower:SetLeader(self.inst)
                    mermprotector._wurt = self.inst
                end
                return mermprotector
            end
        end
        self.inst:DoTaskInTime(10, function() self:SpawnProtector() end)
    end
    return nil
end

function MermProtectorSpawner:ReSpawnProtector()
    if self.inst then
        self.inst:DoTaskInTime(PROTECTOR_RESPAWN_TIME, function()
            self:SpawnProtector()
        end)
        self.protectorRespawnTime = GetTime() + PROTECTOR_RESPAWN_TIME
    end
end

return MermProtectorSpawner