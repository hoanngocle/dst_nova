local function doaoe(inst,damage,range,aoepos,fn)
    if inst and inst:IsValid() then
        local x,y,z = inst.Transform:GetWorldPosition()
        if aoepos then
            x,y,z = aoepos:Get()
        end
        local ents = XD_GetDamageTargets(x, 0, z,range or 3)
        for i,v in pairs(ents) do
            if v and v:IsValid() and v ~= inst and XD_CanAttackTrget(inst,v)
                and (not fn or fn(inst,v,inst)) then
                local damage = Xd_CalcDamage(inst,damage or 10,v)
                damage = require('util/nyx_skill_damage').Scale(inst,'spirit_sword',damage)
                v.components.combat:GetAttacked(inst,damage)
            end
        end
    end
end

local assets =
{
	Asset("ANIM", "anim/wagdrone_laserwire_fx.zip"),
	Asset("ANIM", "anim/nyx_htz_bigxtj.zip"),
}

local function CreateSegFxBase()
	local fx = CreateEntity()

	fx:AddTag("FX")
	fx:AddTag("NOCLICK")
	fx.entity:SetCanSleep(false)
	fx.persists = false

	fx.entity:AddTransform()
	fx.entity:AddAnimState()
	fx.entity:AddFollower()

	fx.AnimState:SetBuild("wagdrone_laserwire_fx")
	fx.AnimState:SetBank("wagdrone_laserwire_fx")
	fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

	return fx
end

local function CreateSegFxShadow(seg, rot, scale, isend)
	local fx = CreateSegFxBase()

	fx.Transform:SetRotation(rot)
	fx.AnimState:SetScale(scale, 1)
	fx.AnimState:SetMultColour(1, 1, 1, isend and 0.03 or 0.04)
	fx.AnimState:SetLightOverride(1)
	fx.AnimState:SetLayer(LAYER_BACKGROUND)
	fx.AnimState:SetSortOrder(3)

	fx.entity:SetParent(seg.entity)

	return fx
end

local variations = { 1, 1, 1, 2, 3, 4, 4, 4 }

local function RandomizeAnim(fx)
	local variation = tostring(variations[math.random(#variations)])
	fx.AnimState:PlayAnimation("beam_"..variation)
	fx.shadow.AnimState:PlayAnimation("shadow_"..variation)
end

local function CreateSegFx(seg, rot, scale, isend)
	local fx = CreateSegFxBase()

	fx.Transform:SetRotation(rot)
	fx.AnimState:SetScale(scale, 1)
	fx.AnimState:SetLightOverride(1)

	fx.entity:SetParent(seg.entity)
	fx.Follower:FollowSymbol(seg.GUID, "marker")

	fx.shadow = CreateSegFxShadow(seg, rot, scale, isend)

	fx:ListenForEvent("animover", RandomizeAnim)
	RandomizeAnim(fx)

	local frame = math.random(fx.AnimState:GetCurrentAnimationNumFrames()) - 1
	fx.AnimState:SetFrame(frame)
	fx.shadow.AnimState:SetFrame(frame)

	return fx
end

local function CreateSegAt(inst, x, z, rot, scale, isend, animoverride)
	local seg = CreateEntity()

	seg:AddTag("FX")
	seg:AddTag("NOCLICK")
	seg.entity:SetCanSleep(false)
	seg.persists = false

	seg.entity:AddTransform()
	seg.entity:AddAnimState()

	seg.entity:SetParent(inst.entity)
	seg.Transform:SetPosition(x, 0, z)

	seg.AnimState:SetBuild("wagdrone_laserwire_fx")
	seg.AnimState:SetBank("wagdrone_laserwire_fx")
	seg.AnimState:PlayAnimation(animoverride or "follow_marker")

	CreateSegFx(seg, rot, scale, isend)

	return seg
end

local function ClearSegs(inst)
	if inst.segs then
		for i, v in ipairs(inst.segs) do
			v:Remove()
		end
		inst.segs = nil
	end
end

local MAX_LEN = 15
local SEG_LEN = 2

local function RefreshSegs(inst, animoverride)
	local len = inst.len:value() / 255 * MAX_LEN
	local rot = inst.rot:value() / 255 * 360
	local theta = rot * DEGREES
	local costheta = math.cos(theta)
	local sintheta = math.sin(theta)

	if inst.segs == nil and not TheNet:IsDedicated() then
		inst.segs = {}
		local num = math.max(1, math.floor(len / SEG_LEN + 0.5))
		local scale = len / (num * SEG_LEN)
		local spacing = len / num
		local dx = spacing * costheta
		local dz = -spacing * sintheta
		local dstart = (1 - num) / 2
		local x = dx * dstart
		local z = dz * dstart
		for i = 1, num do
			inst.segs[i] = CreateSegAt(inst, x, z, rot, scale, i == 1 or i == num, animoverride)
			x = x + dx
			z = z + dz
		end
	end
end

local function OnBeamDirty(inst)
	ClearSegs(inst)
	RefreshSegs(inst)
end

local function SetBeam(inst, len, rot)
	inst.len:set_local(0)
	inst.len:set(math.min(255, math.floor(len / MAX_LEN * 255 + 0.5)))
	inst.rot:set(math.floor((rot < 0 and rot + 360 or rot) / 360 * 255 + 0.5))

	if not inst:IsAsleep() then
		OnBeamDirty(inst)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	inst:AddTag("CLASSIFIED")
	inst:AddTag("notarget")

	inst.len = net_byte(inst.GUID, "nyx_htz_laserwire_fx.len", "beamdirty")
	inst.rot = net_byte(inst.GUID, "nyx_htz_laserwire_fx.rot", "beamdirty")

	inst:SetPrefabNameOverride("wagdrone_rolling")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("beamdirty", OnBeamDirty)
		return inst
	end

	inst.SetBeam = SetBeam
	inst.OnEntitySleep = ClearSegs
	inst.OnEntityWake = RefreshSegs

	inst.persists = false

	return inst
end

local function DoSpell(inst)
	if inst.owner and inst.owner:IsValid() and inst.vertexs then
		local pos = inst:GetPosition()
		local ents = XD_GetDamageTargets(pos.x, pos.y, pos.z, 6)
		for i, v in pairs(ents) do
			if v and  v:IsValid() and v.components.locomotor and v ~= inst.owner and XD_CanAttackTrget(inst.owner, v) then
				local x, y, z = v.Transform:GetWorldPosition()
				if  TheSim:WorldPointInPoly(x, z, {inst.vertexs[1],inst.vertexs[2],inst.vertexs[3],inst.vertexs[4],inst.vertexs[5] }) then 
					if v.components.rooted == nil then
						v:AddComponent("rooted")
					end
					if not v.components.rooted.sources[inst] then
						v.components.rooted:AddSource(inst)
					end
				end
			end
		end
	end
end

local function SpawnSword(inst)
	if inst.owner and inst.owner:IsValid() then
		local fx = SpawnAt("nyx_htz_bigxtj",inst)
		fx.owner = inst.owner
        require("nyx/ownedfx").Attach(fx,inst.owner)
	end
end

local function SpawnBeam(inst)
	if inst.owner and inst.owner:IsValid() then
		local fx = SpawnAt("nyx_htz_beam_fx",inst)
		fx.owner = inst.owner
        require("nyx/ownedfx").Attach(fx,inst.owner)
	end
end
local function spell_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	inst:AddTag("CLASSIFIED")
	inst:AddTag("NOCLICK")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	inst:DoPeriodicTask(0.3,DoSpell,1.3)

	inst:DoTaskInTime(7.9,inst.Remove)

	inst:DoTaskInTime(1.3,SpawnSword)
	inst:DoTaskInTime(1.8,SpawnBeam)

	inst.persists = false

	return inst
end

local function RegisterBeam(inst, other, fx)
	inst.beams[other] = fx
end

local function UnregisterBeam(inst, other)
	inst.beams[other] = nil
end

local function ConnectBeams(inst)
	inst:DisconnectBeams()

	local x, y, z = inst.Transform:GetWorldPosition()
	for i, v in ipairs(TheSim:FindEntities(x, y, z, 16, {"fx","nyx_htz_smallxtj"})) do
		if v ~= inst and inst.othersword and inst.othersword[v] then
			local x1, y1, z1 = v.Transform:GetWorldPosition()
			local dx = x1 - x
			local dz = z1 - z
			local dsq = dx * dx + dz * dz
			if dsq >= 16 then
				local fx = SpawnPrefab("nyx_htz_laserwire_fx")
				fx.Transform:SetPosition((x + x1) / 2, 0, (z + z1) / 2)
				fx:SetBeam(math.sqrt(dsq), math.atan2(-dz, dx) * RADIANS)
				RegisterBeam(inst, v, fx)
				RegisterBeam(v, inst, fx)
			end
		end
	end
end

local function DisconnectBeams(inst)
	for other, fx in pairs(inst.beams) do
		assert(other.beams[inst] == fx)
		fx:Remove()
		UnregisterBeam(inst, other)
		UnregisterBeam(other, inst)
	end
end
local function smallxtjfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("xd_sword_green_skillfx")
	inst.AnimState:SetBuild("xd_htz_swordfx")
	inst.AnimState:PlayAnimation("meteor_pre")

	local s  = 1.257
	inst.AnimState:SetScale(s, s, s)

	inst:AddTag("fx")
	inst:AddTag("nyx_htz_smallxtj")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.othersword = nil
	inst.persists = false
	inst.beams = {}
	inst.DisconnectBeams = DisconnectBeams
	inst.ConnectBeams = ConnectBeams
	inst.OnRemoveEntity = DisconnectBeams
	inst.RegisterBeam = function(inst, other, fx) RegisterBeam(inst, other, fx) end
	inst.UnregisterBeam = function(inst, other) UnregisterBeam(inst, other) end

	inst:DoTaskInTime(1,function()
		inst.SoundEmitter:PlaySound("xd_pog_sound/xd_pog_sound/green_skill2",nil,0.75)
	end)
	inst:DoTaskInTime(1.3,function()
		inst:ConnectBeams()
	end)
	inst:DoTaskInTime(7.9 + math.random() * 0.5,function()
		local fx = SpawnAt("xd_sword_green_explodefx",inst)
		fx.AnimState:SetBuild("xd_htz_sword_explodefx")
		doaoe(inst.owner,60,3,inst:GetPosition())
		fx.SoundEmitter:PlaySound("xd_pog_sound/xd_pog_sound/green_skill2",nil,0.75)
		inst:Remove()
	end)
	inst:DoTaskInTime(10, inst.Remove)

	return inst
end

local easing = require("easing")

local beamassets =
{
	Asset("ANIM", "anim/wagboss_beam.zip"),
}

local function CreateRing()
	local ring = CreateEntity()

	ring.persists = false

	ring.entity:AddTransform()
	ring.entity:AddAnimState()

	ring:AddTag("FX")
	ring:AddTag("NOCLICK")

	ring.AnimState:SetBank("wagboss_beam")
	ring.AnimState:SetBuild("wagboss_beam")
	ring.AnimState:PlayAnimation("ground_marker_pre")
	ring.AnimState:PushAnimation("ground_marker_loop")
	ring.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	ring.AnimState:SetLightOverride(0.3)
	ring.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	ring.AnimState:SetLayer(LAYER_BACKGROUND)
	ring.AnimState:SetSortOrder(3)

	return ring
end

local function DoAnimSync_Client(inst)
	if inst.AnimState:IsCurrentAnimation("beam_pre") then
		local t = inst.AnimState:GetCurrentAnimationTime()
		local len = inst.ring.AnimState:GetCurrentAnimationLength()
		if t < len then
			inst.ring.AnimState:SetTime(t)
		else
			inst.ring.AnimState:PlayAnimation("ground_marker_loop", true)
			inst.ring.AnimState:SetTime(t - len)
		end
	elseif inst.AnimState:IsCurrentAnimation("beam_pst") then
		inst.ring.AnimState:PlayAnimation("ground_marker_pst")
		inst.ring.AnimState:SetTime(inst.AnimState:GetCurrentAnimationTime())
	else
		inst.ring.AnimState:PlayAnimation("ground_marker_loop", true)
		inst.ring.AnimState:SetTime(inst.AnimState:GetCurrentAnimationTime())
	end
end

local function CancelPostUpdate_Client(inst, PostUpdate_Client)
	inst._cancelpostupdatetask = nil
	inst._postupdating = nil
	inst.components.updatelooper:RemovePostUpdateFn(PostUpdate_Client)
end

local function PostUpdate_Client(inst)
	if inst._cancelpostupdatetask then
		return
	end
	inst._cancelpostupdatetask = inst:DoStaticTaskInTime(0, CancelPostUpdate_Client, PostUpdate_Client)
	DoAnimSync_Client(inst)
end

local function OnAnimSync_Client(inst)
	if not inst._postupdating then
		inst._postupdating = true
		inst.components.updatelooper:AddPostUpdateFn(PostUpdate_Client)
	elseif inst._cancelpostupdatetask then
		inst._cancelpostupdatetask:Cancel()
		inst._cancelpostupdatetask = nil
	end
end

local function StartPreSound(inst)
	inst._initsoundtask = nil
	inst.SoundEmitter:PlaySound("rifts5/wagstaff_boss/beam_up")
end

local function StartBeamAOE(inst)
	inst.damagetask = inst:DoPeriodicTask(0.5,function()
		doaoe(inst.owner,300,6,inst:GetPosition())
	end,0)
	inst.SoundEmitter:PlaySound("rifts5/wagstaff_boss/beam_down_LP", "loop")
end

local function UpdateBeamLightPre(inst)
	if inst.AnimState:IsCurrentAnimation("beam_pre") then
		local frame = inst.AnimState:GetCurrentAnimationFrame()
		if frame > 28 then
			local len = inst.AnimState:GetCurrentAnimationNumFrames()
			local r = easing.outQuad(frame - 28, 0, 3, len - 28)
			inst.Light:SetRadius(r)
			inst.Light:Enable(true)
		end
	else
		inst.Light:SetRadius(3)
		inst.Light:Enable(true)
		inst.components.updatelooper:RemoveOnUpdateFn(UpdateBeamLightPre)
	end
end

local function UpdateBeamLightPst(inst)
	if inst.AnimState:IsCurrentAnimation("beam_pst") then
		local frame = inst.AnimState:GetCurrentAnimationFrame()
		if frame < 5 then
			inst.Light:SetRadius(3)
			inst.Light:Enable(true)
		elseif frame < 10 then
			local r = easing.inQuad(frame - 4, 3, -3, 10 - 4)
			inst.Light:SetRadius(r)
			inst.Light:Enable(true)
		else
			inst.Light:Enable(false)
			inst.components.updatelooper:RemoveOnUpdateFn(UpdateBeamLightPst)
		end
	else
		inst.Light:Enable(false)
		inst.components.updatelooper:RemoveOnUpdateFn(UpdateBeamLightPst)
	end
end

local function KillFx(inst)
	if inst:IsAsleep() then
		inst:Remove()
		return
	elseif inst.ring then
		inst.ring.AnimState:PlayAnimation("ground_marker_pst")
	end
	inst.AnimState:PlayAnimation("beam_pst")
	inst:ListenForEvent("animover", inst.Remove)
	inst.OnEntitySleep = inst.Remove
	inst.animsync:set_local(true)
	inst.animsync:set(true)
	if inst.damagetask then
		inst.damagetask:Cancel()
		inst.damagetask = nil
	end
	
	inst.components.updatelooper:AddOnUpdateFn(UpdateBeamLightPst)
	inst.SoundEmitter:KillSound("loop")
	inst.SoundEmitter:PlaySound("rifts5/wagstaff_boss/beam_down_pst")
end

local function beamfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.Light:SetIntensity(0.5)
	inst.Light:SetFalloff(0.95)
	inst.Light:SetColour(0.01, 0.35, 1)
	inst.Light:Enable(false)

	inst.AnimState:SetBank("wagboss_beam")
	inst.AnimState:SetBuild("wagboss_beam")
	inst.AnimState:PlayAnimation("beam_pre")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetLightOverride(0.3)

	inst.animsync = net_bool(inst.GUID, "nyx_htz_beam_fx.animsync", "animsyncdirty")
	inst.animsync:set(true)

	inst:AddTag("fx")

	inst:AddComponent("updatelooper")

	if not TheNet:IsDedicated() then
		inst.ring = CreateRing()
		inst.ring.entity:SetParent(inst.entity)
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("animsyncdirty", OnAnimSync_Client)
		OnAnimSync_Client(inst)

		return inst
	end

	inst.components.updatelooper:AddOnUpdateFn(UpdateBeamLightPre)

	inst.AnimState:PushAnimation("beam_loop")

	inst._initsoundtask = inst:DoTaskInTime(0, StartPreSound)
	inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), StartBeamAOE)
	inst:DoTaskInTime(6.11, KillFx)

	inst.persists = false

	return inst
end

local function xtjfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("xd_htz_bigxtj")
	inst.AnimState:SetBuild("xd_htz_bigxtj")
	inst.AnimState:PlayAnimation("drop")
	inst.AnimState:PushAnimation("idle")

	local s  = 1.257
	inst.AnimState:SetScale(s, s, s)

	inst:AddTag("fx")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:DoTaskInTime(0.48,function()
		inst.SoundEmitter:PlaySound("xd_pog_sound/xd_pog_sound/green_skill2",nil,0.75)
	end)
	inst:DoTaskInTime(0.5,function()
		doaoe(inst.owner,1101,6,inst:GetPosition())
	end)
	inst:AddComponent("colourtweener")
	inst:DoTaskInTime(6.6,function()
		inst.components.colourtweener:StartTween({1, 1, 1, 0},0.5, function()
			inst:Remove()
		end)
	end)
	inst.persists = false

	inst:DoTaskInTime(10, inst.Remove)

	return inst
end

return Prefab("nyx_htz_laserwire_fx", fn, assets),
	Prefab("nyx_htz_trap_spell", spell_fn),
	Prefab("nyx_htz_smallxtj", smallxtjfn),
	Prefab("nyx_htz_beam_fx", beamfn,beamassets),
	Prefab("nyx_htz_bigxtj", xtjfn,assets)
