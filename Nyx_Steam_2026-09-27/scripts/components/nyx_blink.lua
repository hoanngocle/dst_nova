local Common = require "util/nyx_blink_common"
local SkillDamage = require "util/nyx_skill_damage"
local Source = require "nyx/source18"

local LIGHTNING_FX = "spear_wathgrithr_lightning_lunge_fx"
local LIGHTNING_SOUND = "meta3/wigfrid/spear_lighting_lunge"
local LIGHTNING_COLOUR = {216 / 255, 239 / 255, 1, 1}

local NyxBlink = Class(function(self, inst)
    self.inst = inst
    self.active = false
    self.cooldown_end = 0
    self.cast_task = nil
    self.cast_state = nil

    self._ondeath = function() self:Stop("death") end
    self._onghost = function() self:Stop("ghost") end
    self._onremove = function() self:Stop("remove") end
    self._onnewstate = function()
        if self.active and ((self.cast_state ~= nil
                and self.inst.sg ~= nil
                and self.inst.sg.currentstate ~= self.cast_state)
            or not Common.CanContinueCast(self.inst)) then
            self:Stop("interrupted")
        end
    end
    inst:ListenForEvent("death", self._ondeath)
    inst:ListenForEvent("ms_becameghost", self._onghost)
    inst:ListenForEvent("onremove", self._onremove)
    inst:ListenForEvent("newstate", self._onnewstate)
end)

function NyxBlink:GetCooldownRemaining()
    return math.max(0, self.cooldown_end - GetTime())
end

function NyxBlink:IsActive()
    return self.active
end

function NyxBlink:_Say(message)
    local talker = self.inst.components ~= nil and self.inst.components.talker or nil
    if talker ~= nil then talker:Say(message) end
end

function NyxBlink:_SpawnLightningFx(x, z, rotation)
    local fx = SpawnPrefab(LIGHTNING_FX)
    if fx == nil then return end
    fx.Transform:SetPosition(x, 0, z)
    fx.Transform:SetRotation(rotation)
    if fx.AnimState ~= nil then
        fx.AnimState:SetMultColour(unpack(LIGHTNING_COLOUR))
    end
end

function NyxBlink:_FinishCast(reason)
    if self.cast_task ~= nil then
        self.cast_task:Cancel()
        self.cast_task = nil
    end
    local was_active = self.active
    self.active = false
    self.inst:RemoveTag("nyx_blink_casting")
    local cast_state = self.cast_state
    self.cast_state = nil
    if (reason == "finished" or reason == "destination_invalid"
            or reason == "cast_error" or reason == "no_resource")
        and self.inst.sg ~= nil and self.inst.sg.currentstate == cast_state
        and self.inst.sg.GoToState ~= nil then
        self.inst.sg:GoToState("idle")
    end
    return was_active, reason
end

function NyxBlink:_DamagePath(targets)
    local combat = self.inst.components ~= nil and self.inst.components.combat or nil
    local level = self.inst.components ~= nil and self.inst.components.levelsystem or nil
    local damage = Common.LungeDamage(level ~= nil and level.level or nil)
    local previous_ignore
    if combat ~= nil then
        previous_ignore = combat.ignorehitrange
        combat.ignorehitrange = true
    end
    local ok, problem = pcall(function()
        for _, target in ipairs(targets) do
            if Common.IsValidLungeTarget(self.inst, target) then
                SkillDamage.Apply(
                    self.inst, target, damage, "nyx_blink")
                if self.inst:IsValid() then
                    self.inst:PushEvent("onareaattackother", {target = target})
                end
            end
        end
    end)
    if combat ~= nil then combat.ignorehitrange = previous_ignore end
    if not ok then
        print("[Nyx] Thuấn Ảnh path damage failed: " .. tostring(problem))
    end
end

function NyxBlink:_ResolveCast(x, z)
    self.cast_task = nil
    if not self.active or not Common.CanContinueCast(self.inst) then
        self:_FinishCast("interrupted")
        return
    end
    local origin_x, _, origin_z = self.inst.Transform:GetWorldPosition()
    local valid = Common.ValidateDestination(self.inst, x, z, origin_x, origin_z)
    if not valid then
        self:_FinishCast("destination_invalid")
        return
    end

    local targets = Common.FindTargetsAlongPath(
        self.inst, origin_x, origin_z, x, z)
    local paid, reason = Source.Spend(self.inst, Common.COST)
    if not paid then
        self:_Say(reason)
        self:_FinishCast("no_resource")
        return
    end
    local ok, problem = pcall(self.inst.Physics.Teleport, self.inst.Physics, x, 0, z)
    if not ok then
        Source.Refund(self.inst, Common.COST)
        print("[Nyx] Thuấn Ảnh teleport failed: " .. tostring(problem))
        self:_FinishCast("cast_error")
        return
    end

    self.cooldown_end = GetTime() + Common.COOLDOWN
    local rotation = math.atan2(origin_z - z, x - origin_x) * RADIANS
    self:_SpawnLightningFx((origin_x + x) * 0.5, (origin_z + z) * 0.5, rotation)
    self:_SpawnLightningFx(x, z, rotation)
    if self.inst.SoundEmitter ~= nil then
        self.inst.SoundEmitter:PlaySound(LIGHTNING_SOUND)
    end
    self:_DamagePath(targets)
    self:_FinishCast("finished")
end

function NyxBlink:CastAt(x, z)
    if TheWorld == nil or not TheWorld.ismastersim then
        return false, "not_master"
    end
    if self.active then return false, "active" end
    local remaining = self:GetCooldownRemaining()
    if remaining > 0 then
        self:_Say("Thuấn Ảnh hồi sau " .. tostring(math.ceil(remaining)) .. " giây.")
        return false, "cooldown"
    end
    if not Common.CanActivate(self.inst) then return false, "invalid_state" end
    local origin_x, _, origin_z = self.inst.Transform:GetWorldPosition()
    local valid, reason = Common.ValidateDestination(
        self.inst, x, z, origin_x, origin_z)
    if not valid then return false, reason end

    local resource = self.inst.components.xd_htz_lq
    if resource == nil or resource.current < Common.COST then
        self:_Say("Thuấn Ảnh cần " .. Common.COST .. " Linh Lực.")
        return false, "no_resource"
    end
    self.active = true
    self.cast_state = self.inst.sg ~= nil and self.inst.sg.currentstate or nil
    self.inst:AddTag("nyx_blink_casting")
    self.cast_task = self.inst:DoTaskInTime(Common.BLINK_DELAY, function()
        self:_ResolveCast(x, z)
    end)
    self:_Say("Thuấn Ảnh!")
    return true, "cast"
end

function NyxBlink:Stop(reason)
    return self:_FinishCast(reason)
end

function NyxBlink:OnSave()
    local remaining = self:GetCooldownRemaining()
    return remaining > 0 and {cooldown = remaining} or nil
end

function NyxBlink:OnLoad(data)
    self:Stop("load")
    local remaining = data ~= nil and tonumber(data.cooldown) or 0
    if not Common.IsFiniteNumber(remaining) then remaining = 0 end
    self.cooldown_end = GetTime()
        + math.max(0, math.min(Common.COOLDOWN, remaining or 0))
end

function NyxBlink:OnRemoveFromEntity()
    self:Stop("component_removed")
    self.inst:RemoveEventCallback("death", self._ondeath)
    self.inst:RemoveEventCallback("ms_becameghost", self._onghost)
    self.inst:RemoveEventCallback("onremove", self._onremove)
    self.inst:RemoveEventCallback("newstate", self._onnewstate)
end

return NyxBlink
