-- TMIR uses a Wilson as a DPS text anchor. Keep its replica tags and stop its
-- component ticks as soon as TMIR marks it; the private helper can otherwise
-- run sanity:OnUpdate without replica.sanity.
local M={}
local replica_tags={_health=true,_hunger=true,_sanity=true,_combat=true,_moisture=true,_rider=true}
local speaker_tag='TMIR_DPS_FEEDBACK_SPEAKER'

local function StopSpeakerUpdates(inst)
    if inst._nyx_dps_updates_stopped or inst.components==nil or inst.StopUpdatingComponent==nil then return end
    inst._nyx_dps_updates_stopped=true
    for _,component in pairs(inst.components) do
        inst:StopUpdatingComponent(component)
    end
end

function M.Protect(inst)
    local remove=inst.RemoveTag
    inst.RemoveTag=function(self,tag,...)
        if replica_tags[tag] and (self._tmir_feedback_speaker or self:HasTag(speaker_tag)) then return end
        return remove(self,tag,...)
    end
    local add=inst.AddTag
    inst.AddTag=function(self,tag,...)
        local result=add(self,tag,...)
        if tag==speaker_tag then StopSpeakerUpdates(self) end
        return result
    end
end
return M
