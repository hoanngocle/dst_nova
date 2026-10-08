local M = {}
local function alive(player)
    return player and player:IsValid() and not player:HasTag('playerghost')
end
function M.Points(inst, bundle, living)
    local count = 0
    for _, item in ipairs(bundle.items) do count = count + item.count end
    if bundle.adapter == 'twins' then count = 1 end
    local x, _, z = inst.Transform:GetWorldPosition()
    local points = {}
    for i=1,count do
        local found
        for attempt=1,72 do
            local angle = (i * 2.399963 + attempt * .53)
            local radius = living and (7 + math.floor(attempt / 12) * 3) or (2 + attempt % 3)
            local px, pz = x + math.cos(angle)*radius, z + math.sin(angle)*radius
            local pt = Vector3(px,0,pz)
            local map = TheWorld.Map
            local valid = map:IsPassableAtPoint(px,0,pz)
                and not map:IsOceanAtPoint(px,0,pz)
                and not map:IsPointNearHole(pt)
                and not map:IsGroundTargetBlocked(pt)
                and #TheSim:FindEntities(px,0,pz,living and 3 or .5,nil,{'INLIMBO','FX'},{'structure','wall'}) == 0
            if valid and living then
                for _, prior in ipairs(points) do
                    if (prior.x-px)^2+(prior.z-pz)^2 < 16 then valid=false; break end
                end
            end
            if valid then found=pt;break end
        end
        if not found then return nil end
        points[i]=found
    end
    return points
end
function M.Configure(entity, item, point, giver, track)
    entity.Transform:SetPosition(point.x,0,point.z)
    local components=entity.components
    if components.knownlocations then
        components.knownlocations:RememberLocation('spawnpoint',point)
        components.knownlocations:RememberLocation('home',point)
    end
    if item.treasure then
        assert(components.hh_monster, 'Solo treasure component missing')
        components.hh_monster:SetTreasureId(item.treasure)
    end
    if entity.prefab == 'twinmanager' then
        assert(alive(giver), 'Twins require a live summoner')
        -- Track children even if an event listener raises midway through creation.
        local tracker=components.entitytracker
        local original=tracker.TrackEntity
        tracker.TrackEntity=function(self,key,child,...)
            track(child)
            return original(self,key,child,...)
        end
        local ok,err=pcall(entity.PushEvent,entity,'arrive',giver)
        tracker.TrackEntity=original
        assert(ok,err)
        for _, key in ipairs({'twin1','twin2'}) do
            local child=assert(tracker:GetEntity(key),'missing twin')
            local p=child:GetPosition()
            assert(TheWorld.Map:IsPassableAtPoint(p:Get()) and not TheWorld.Map:IsOceanAtPoint(p:Get()),'twin landed off shore')
            if child.components.health and not child.components.xd_choujiang_creature then
                child:AddComponent('xd_choujiang_creature')
            end
        end
        entity:PushEvent('set_spawn_target',giver)
        return
    elseif entity.prefab == 'antlion' then
        entity:StartCombat(alive(giver) and giver or nil)
    elseif entity.prefab == 'daywalker' then
        entity:MakeHostile()
    elseif entity.prefab == 'daywalker2' and entity.buried then
        entity:MakeFreed()
    elseif entity.prefab == 'klaus' then
        local commander=components.commander
        local original=commander.AddSoldier
        commander.AddSoldier=function(self,child,...)
            track(child)
            return original(self,child,...)
        end
        local ok,err=pcall(entity.SpawnDeer,entity)
        commander.AddSoldier=original
        assert(ok,err)
    end
    if components.health and not components.xd_choujiang_creature then
        entity:AddComponent('xd_choujiang_creature')
    end
    if components.combat and alive(giver) then components.combat:SetTarget(giver) end
end
return M
