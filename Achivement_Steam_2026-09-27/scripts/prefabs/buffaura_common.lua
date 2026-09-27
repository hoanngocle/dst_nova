local TICK = 1
local function SpawnFx(name, target, scale, xOffset, yOffset, zOffset)
	local fx = SpawnPrefab(name)
	fx.Transform:SetNoFaced()
	if fx then
		xOffset = xOffset or 0
		yOffset = yOffset or 0
		zOffset = zOffset or 0
		if target.components.rider ~= nil and target.components.rider:IsRiding() then
			yOffset = yOffset + 2.3
			xOffset = xOffset + 0.5
			zOffset = zOffset + 0.5
		end

		target:AddChild(fx)
		fx.Transform:SetPosition(xOffset, yOffset, zOffset)

		scale = scale or 1
		fx.Transform:SetScale(scale, scale, scale)
	end

	return fx
end

local function buff_OnTick(inst, target)
	if inst.expire_time - GetTime() <= 0 then
		inst.components.debuff:Stop()
		return
	end

	if target.components.health ~= nil and not target.components.health:IsDead() then
		if inst.buffdata.TICK_FN ~= nil then
			inst.buffdata.TICK_FN(inst, target)
		end
	else
		inst.components.debuff:Stop()
	end
end

local function buff_OnPeriod(inst, target)
	if target.components.health ~= nil and not target.components.health:IsDead() then
		if inst.buffdata.PERIOD_FN ~= nil then
			inst.buffdata.PERIOD_FN(inst, target)
		end

		if inst.buffdata.PERIOD_FX then
			SpawnFx(inst.buffdata.PERIOD_FX, target, inst.buffdata.fxscale, inst.buffdata.xoffset, inst.buffdata.yoffset, inst.buffdata.zoffset)
		end
	else
		inst.components.debuff:Stop()
	end
end

local function buff_OnAttached(inst, target, followsymbol, followoffset, data, buffer)
	inst.entity:SetParent(target.entity)
	inst.Transform:SetPosition(0, 0, 0)

	inst.ontick_task = inst:DoPeriodicTask(TICK, buff_OnTick, TICK + math.random(), target)
	if inst.buffdata.PERIOD and inst.buffdata.PERIOD_FN then
		inst.onperiod_task = inst:DoPeriodicTask(inst.buffdata.PERIOD, buff_OnPeriod, inst.buffdata.PERIOD + math.random(), target)
	end

	if inst.buffdata.ONATTACH ~= nil then
		inst.buffdata.ONATTACH(inst, target, data)
	end

	if inst.buffdata.ATTACH_FX then
		inst:DoTaskInTime(math.random(), function() SpawnFx(inst.buffdata.ATTACH_FX, target, inst.buffdata.fxscale, inst.buffdata.xoffset, inst.buffdata.yoffset, inst.buffdata.zoffset) end)
	end

	inst.expire_time = GetTime() + TICK
	inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
end

local function buff_OnExtended(inst, target, followsymbol, followoffset, data, buffer)
	inst.expire_time = GetTime() + TICK

	if inst.buffdata.ONEXTENDED ~= nil then
		inst.buffdata.ONEXTENDED(inst, target, data)
	end
end

local function buff_OnDetached(inst, target)
	if inst.ontick_task ~= nil then
		inst.ontick_task:Cancel()
		inst.ontick_task = nil
	end
	if inst.onperiod_task ~= nil then
		inst.onperiod_task:Cancel()
		inst.onperiod_task = nil
	end

	if inst.buffdata.ONDETACH ~= nil then
		inst.buffdata.ONDETACH(inst, target)
	end

	if inst.buffdata.DETACH_FX then
		SpawnFx(inst.buffdata.DETACH_FX, target, inst.buffdata.fxscale, inst.buffdata.xoffset, inst.buffdata.yoffset, inst.buffdata.zoffset)
	end

	inst:DoTaskInTime(10*FRAMES, inst.Remove)
end

local function common_fn(buffdata)
	local inst = CreateEntity()

	inst:AddTag("CLASSIFIED")

	if not TheWorld.ismastersim then
		inst:DoTaskInTime(0, inst.Remove)
		return inst
	end

	inst.entity:AddTransform()

	inst.entity:Hide()
	inst.persists = false

	inst.buffdata = buffdata

	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(buff_OnAttached)
	inst.components.debuff:SetDetachedFn(buff_OnDetached)
	inst.components.debuff:SetExtendedFn(buff_OnExtended)

	return inst
end

local function persist_fn(buffdata)
	local inst = CreateEntity()
	inst.entity:AddNetwork()
	inst:AddTag("CLASSIFIED")

	if not TheWorld.ismastersim then
		return inst
	end

	inst.entity:AddTransform()

	inst.entity:Hide()
	inst.persists = false

	inst.buffdata = buffdata

	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(buff_OnAttached)
	inst.components.debuff:SetDetachedFn(buff_OnDetached)
	inst.components.debuff:SetExtendedFn(buff_OnExtended)

	return inst
end

return {
	common_fn = common_fn,
	persist_fn = persist_fn,
}
