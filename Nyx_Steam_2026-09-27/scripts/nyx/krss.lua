-- Lạc Thần weapon dispatch from local Tu Tiên 18.1. Character passives are not imported.
local M={}
local function SpawnLuoshenBlinkFx(target)
    local x, y, z = target.Transform:GetWorldPosition()
    local back = SpawnPrefab("xd_luoshen_sand_puff_back")
    if back ~= nil then
        back.Transform:SetPosition(x, y - .1, z)
    end
    local front = SpawnPrefab("xd_luoshen_sand_puff_front")
    if front ~= nil then
        front.Transform:SetPosition(x, y, z)
    end
end

local function DoLuoshenBlink(inst, pos)
    if pos == nil or inst == nil or not inst:IsValid() then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    if not IsTeleportingPermittedFromPointToPoint(x, y, z, pos.x, pos.y, pos.z) then
        return
    end
    if not TheWorld.Map:IsPassableAtPoint(pos.x, pos.y, pos.z) or TheWorld.Map:IsGroundTargetBlocked(pos) then
        return
    end

    SpawnLuoshenBlinkFx(inst)
    if inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
    end

    inst:DoTaskInTime(.25, function(inst_)
        if not inst_:IsValid() or inst_:HasTag('playerghost') or inst_.components.health:IsDead() then
            return
        end
        local plant = SpawnAt("xd_luoshenzhu", inst)
        if plant ~= nil and plant.OnSpawnedBy ~= nil then
            plant:OnSpawnedBy(inst)
        end

        local sx, sy, sz = inst_.Transform:GetWorldPosition()
        if IsTeleportingPermittedFromPointToPoint(sx, sy, sz, pos.x, pos.y, pos.z)
            and TheWorld.Map:IsPassableAtPoint(pos.x, pos.y, pos.z)
            and not TheWorld.Map:IsGroundTargetBlocked(pos) then
            if inst_.Physics ~= nil then
                inst_.Physics:Teleport(pos.x, pos.y, pos.z)
            else
                inst_.Transform:SetPosition(pos.x, pos.y, pos.z)
            end
        end

        SpawnLuoshenBlinkFx(inst_)
        if inst_.SoundEmitter ~= nil then
            inst_.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
        end
    end)
end

function M.Install(inst)
        
        if not TheWorld.ismastersim then
            return inst
        end
        local oldredirect=inst.components.health.redirect
        inst.components.health.redirect=function(owner,amount,...)
            if oldredirect and oldredirect(owner,amount,...) then return true end
            local shield=owner.xd_luoshen_forcefieldfx
            if amount and amount<0 and shield and shield:IsValid() then
                shield:TakeDamage(amount)
                return true
            end
        end
        inst.dolingjiskill = function(inst,weapon,pos,target)
            if not weapon or weapon.prefab~='xd_luoshen_krss' then return end
            if pos and inst then
                DoLuoshenBlink(inst,pos)
            end
            inst.components.xd_skillcd:Start("灵技",15)
        end
        inst.doshentongskill = function(inst,weapon)
            if not weapon or weapon.prefab~='xd_luoshen_krss' then return end
            if inst._xd_luoshen_shentong_buff ~= nil and inst._xd_luoshen_shentong_buff:IsValid() then
                inst._xd_luoshen_shentong_buff:Remove()
            end
            local buffprefab = inst.IsDeathFlower ~= nil and inst:IsDeathFlower()
                and "xd_luoshen_shentong_death_buff"
                or "xd_luoshen_shentong_life_buff"
            local circleprefab = inst.IsDeathFlower ~= nil and inst:IsDeathFlower()
                and "xd_luoshen_shentong_death_circle"
                or "xd_luoshen_shentong_life_circle"
            local buff = SpawnPrefab(buffprefab)
            if buff ~= nil and buff.SetOwner ~= nil then
                buff:SetOwner(inst)
            end
            local circle = SpawnPrefab(circleprefab)
            if circle ~= nil and circle.SetOwner ~= nil then
                circle:SetOwner(inst)
            end
            inst.components.xd_skillcd:Start("神通",60)
            inst:PushEvent("xd_done_shentong",{weapon = weapon})
        end  
    end
return M
