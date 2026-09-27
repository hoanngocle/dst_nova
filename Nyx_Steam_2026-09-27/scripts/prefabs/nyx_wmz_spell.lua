local CLOSERANGE = 1

local TARGETS_MUST = { "_health", "_combat" }
local TARGETS_CANT = { "INLIMBO", "invisible", "noattack", "notarget", "flight" }

local function TargetIsHostile(isplayer, source, target)
	if source.HostileTest then
		return source:HostileTest(target)
	elseif isplayer and target.HostileToPlayerTest then
		return target:HostileToPlayerTest(source)
	else
		return target:HasTag("hostile")
	end
end
local function settarget(inst,target,life,source)
    require("nyx/ownedfx").Attach(inst,source)
    local maxdeflect = 30

    if life > 0 then

        inst.shadowfire_task = inst:DoTaskInTime(0.1,function()

            local theta = inst.Transform:GetRotation() * DEGREES
            local radius = CLOSERANGE

			if not (source and source:IsValid() and source.components.combat and not source.components.health:IsDead()) then
                inst:Remove(); return
			elseif target == nil or not XD_CanAttackTrget(source,target) then
				target = nil

				local isplayer = source:HasTag("player")

				local x, y, z = inst.Transform:GetWorldPosition()
				local ents = TheSim:FindEntities(x, y, z, 20, TARGETS_MUST, TARGETS_CANT)

                if #ents > 0 then
					
                    for i=#ents, 1, -1 do
                        local ent = ents[i]
						if not XD_CanAttackTrget(source,ent) or
							source.components.combat:IsAlly(ent)
						then
							table.remove(ents, i)
						elseif isplayer and ent.HostileToPlayerTest and ent.components.shadowsubmissive and not ent:HostileToPlayerTest(source) then

							table.remove(ents, i)
						elseif not ent.components.combat:TargetIs(source) then
							if not TargetIsHostile(isplayer, source, ent) then
								table.remove(ents, i)
							elseif ent.components.follower then
								local leader = ent.components.follower:GetLeader()
								if leader and leader:HasTag("player") and not leader.components.combat:TargetIs(source) then
									table.remove(ents, i)
								end
							end
						end
                    end
				end

                if #ents > 0 then

                    local anglediffs = {}

                    local lowestdiff = nil
                    local lowestent = nil

					for i, ent in ipairs(ents) do

                        local ex,ey,ez = ent.Transform:GetWorldPosition()
                        local diff = math.abs(inst:GetAngleToPoint(ex,ey,ez) - inst.Transform:GetRotation())
                        if diff > 180 then diff = math.abs(diff - 360) end

                        if not lowestdiff or lowestdiff > diff then
                            lowestdiff = diff
                            lowestent = ent
                        end                        
                    end

                    target = lowestent
                end
            end

			if target then
                local dist = inst:GetDistanceSqToInst(target)

                if dist<CLOSERANGE*CLOSERANGE then

                    local blast = SpawnPrefab("willow_shadow_fire_explode")
                    local pos = Vector3(target.Transform:GetWorldPosition())
                    blast.Transform:SetPosition(pos.x,pos.y,pos.z)

                    local weapon = inst
					local damage = Xd_CalcDamage(source,220,target)
					damage = require('util/nyx_skill_damage').Scale(source,'eternal_night',damage)
					if target.components.combat then
						target.components.combat:GetAttacked(source,damage)
					end

                    theta = nil
                else
                    local pt = Vector3(target.Transform:GetWorldPosition())
                    local angle = inst:GetAngleToPoint(pt.x,pt.y,pt.z)
                    local anglediff = angle - inst.Transform:GetRotation()
                    if anglediff > 180 then
                        anglediff = anglediff - 360
                    elseif anglediff < -180 then
                        anglediff = anglediff + 360
                    end
                    if math.abs(anglediff) > maxdeflect then
                        anglediff = math.clamp(anglediff, -maxdeflect, maxdeflect)
                    end

                    theta = (inst.Transform:GetRotation() + anglediff) * DEGREES
                end
            else
                if not inst.currentdeflection then
                    inst.currentdeflection = {time = math.random(1,10), deflection = maxdeflect * ((math.random() *2)-1) }
                end
                inst.currentdeflection.time = inst.currentdeflection.time -1
                if inst.currentdeflection.time then
                    inst.currentdeflection = {time = math.random(1,10), deflection = maxdeflect * ((math.random() *2)-1) }
                end

                theta =  (inst.Transform:GetRotation() + inst.currentdeflection.deflection) * DEGREES
            end

            if theta  then
                local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
                local newpos = Vector3(inst.Transform:GetWorldPosition()) + offset
                local newangle = inst:GetAngleToPoint(newpos.x,newpos.y,newpos.z)

                local fire = SpawnPrefab("willow_shadow_flame")
                fire.Transform:SetRotation(newangle)
                fire.Transform:SetPosition(newpos.x,newpos.y,newpos.z)
                settarget(fire,target,life-1,source)
            end
        end)

    end
end
local function DoShadowFire(doer, x, z, rot)
	local fire = SpawnPrefab("willow_shadow_flame")
	fire.Transform:SetRotation(rot)
	fire.Transform:SetPosition(x, 0, z)
	
	settarget(fire,nil,40,doer)
end

local rotatefireassets =
{
	Asset( "ANIM", "anim/nyx_sudaji_rotatefire.zip" ),
    Asset( "ANIM", "anim/nyx_pog_fire.zip" ),
}

local function OnHit(inst, attacker, target)
    if target and target:IsValid() then
		local fx = SpawnAt("nyx_wmz_beam_fx",target)
		fx.owner = attacker
        require("nyx/ownedfx").Attach(fx,attacker)
		if XD_CanAttackTrget(attacker,target) then
			fx:Target_SetTarget(target,attacker)
			local task = attacker:DoPeriodicTask(2,function()
				local pos = attacker:GetPosition()
				local burst = 5
				local radius = 2
				local x, y, z = attacker.Transform:GetWorldPosition()
				local theta = x == pos.x and z == pos.z and attacker.Transform:GetRotation() * DEGREES or math.atan2(z - pos.z, pos.x - x)
				local delta = PI2 / burst
				for i=1,burst do
					local x1 = x + radius * math.cos(theta)
					local z1 = z - radius * math.sin(theta)
					local rotation = theta * RADIANS
					attacker:DoTaskInTime(math.random() * 0.2,function()
                        DoShadowFire(attacker,x1,z1,rotation)
                    end)
					theta = theta + delta
				end
			end,0)
			task.limit = 5
		end
    end
    inst:Remove()
end

local function OnMiss(inst, attacker, target)
    inst:Remove()
end
local TWEEN_TARGET = {0, 0, 0, 0.9}
local TWEEN_TIME = 0.3
local function SetProLevel(inst,damage,scale,owner,firebuild)
    inst.components.colourtweener:StartTween(TWEEN_TARGET, TWEEN_TIME, function() end)
end
local function Projectile_Hit(self,target)
    local attacker = self.owner
    local weapon = self.inst
    self:Stop()
    self.inst.Physics:Stop()
    if self.onhit ~= nil then
        self.onhit(self.inst, attacker, target)
    end
end
local function profn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
	RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("xd_sudaji_rotatefire")
    inst.AnimState:SetBuild("xd_sudaji_rotatefire")
    inst.AnimState:PlayAnimation("idle",true)

    inst.AnimState:SetMultColour(0, 0, 0, 0)

    inst:AddTag("FX")
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.targets = {}

    inst:AddComponent("colourtweener")

	inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(15)
	inst.components.projectile:SetRange(30)
	inst.components.projectile:SetOnHitFn(OnHit)
	inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile.Hit = Projectile_Hit

    inst.SetLevel = SetProLevel
    inst.persists = false

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
	ring.AnimState:SetMultColour(0, 0, 0, 0.9)

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
                damage = require('util/nyx_skill_damage').Scale(inst,'eternal_night',damage)
                v.components.combat:GetAttacked(inst,damage)
            end
        end
    end
end

local function StartPreSound(inst)
	inst._initsoundtask = nil
	inst.SoundEmitter:PlaySound("rifts5/wagstaff_boss/beam_up")
end

local function StartBeamAOE(inst)
	inst.damagetask = inst:DoPeriodicTask(1,function()
		doaoe(inst.owner,100,6,inst:GetPosition())
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

local function Target_OnSetTarget(inst, target)
	if target.components.rooted == nil then
		target:AddComponent("rooted")
	end
	target.components.rooted:AddSource(inst)

	if target.sg ~= nil then
		inst:ListenForEvent("newstate", function(target)
			if target.sg ~= nil and target.sg:HasStateTag("flight") then
				inst:Remove()
			end
		end, target)
	end
end
local function Target_SetTarget(inst, target, owner)
	if target ~= nil then
		inst.components.entitytracker:TrackEntity("target", target)
		Target_OnSetTarget(inst, target)
		inst:ListenForEvent("onattackother",function(_,data)
			local tar = data and data.target
			if tar == target then
				inst.attack_count = inst.attack_count%2+ 1
				if inst.attack_count == 2 and target:IsValid() then
					local x,y,z = target.Transform:GetWorldPosition()
					inst:StartThread(function()
						for k = -30,30,30 do
                            if not owner:IsValid() or owner.components.health:IsDead() then return end
							local gestalt = SpawnPrefab("nyx_wmz_gestalt")
							local r = -8
							local angle = (owner.Transform:GetRotation() + k) * DEGREES
							gestalt.Transform:SetPosition(x + r * math.cos(angle), y, z + r * -math.sin(angle))
							gestalt:ForceFacePoint(x, y, z)
							gestalt:SetTargetPosition(Vector3(x, y, z),owner)
							Sleep(0.2)
						end
					end)
				end
			end
		end,owner)
	end
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

	inst.AnimState:SetMultColour(0, 0, 0, 0.9)

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
	inst.attack_count = 0
	inst.components.updatelooper:AddOnUpdateFn(UpdateBeamLightPre)

	inst:AddComponent("entitytracker")
	inst.AnimState:PushAnimation("beam_loop")
	inst.Target_SetTarget = Target_SetTarget

	inst._initsoundtask = inst:DoTaskInTime(0, StartPreSound)
	inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), StartBeamAOE)
	inst:DoTaskInTime(10.11, KillFx)

	inst.persists = false

	return inst
end

local function stop_motion(inst)
    if inst._attack_task ~= nil then
        inst._attack_task:Cancel()
        inst._attack_task = nil
    end

    inst.AnimState:PlayAnimation("mutate")
    inst.Physics:SetMotorVelOverride(2, 0, 0)
end

local function start_motion(inst)
    inst.Physics:SetMotorVelOverride(inst.attack_speed, 0, 0)
    
end

local function on_anim_over(inst)
    if inst.AnimState:IsCurrentAnimation("emerge") then
        if inst._target_pos ~= nil then
            inst:ForceFacePoint(inst._target_pos:Get())
        else
            inst.Transform:SetRotation(math.random() * 360)
        end
        inst.AnimState:PlayAnimation("attack")
        inst:DoTaskInTime(15*FRAMES, start_motion)
        inst._stop_task = inst:DoTaskInTime(25*FRAMES, stop_motion)
    elseif inst.AnimState:IsCurrentAnimation("mutate") then
        inst:Remove()
    end
end
local function SetTargetPosition(inst, target_pos,owner)
    inst._target_pos = target_pos
	inst.owner = owner
    require("nyx/ownedfx").Attach(inst,owner)
end

local function gestaltfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    local phys = inst.entity:AddPhysics()
    phys:SetMass(1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.FLYERS)
	phys:SetCollisionMask(COLLISION.GROUND)
    phys:SetCapsule(0.5, 1)

    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBuild("brightmare_gestalt_evolved")
    inst.AnimState:SetBank("brightmare_gestalt_evolved")
    inst.AnimState:PlayAnimation("emerge")
	inst.AnimState:Hide("mouseover")
	inst.AnimState:Hide("angry")

	inst.AnimState:SetMultColour(0, 0, 0, 0.9)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    if not TheNet:IsDedicated() then
        inst.blobhead = SpawnPrefab("gestalt_head")
        inst.blobhead.entity:SetParent(inst.entity) 
        inst.blobhead.Follower:FollowSymbol(inst.GUID, "head_fx", 0, 0, 0)
		inst.blobhead.AnimState:SetMultColour(0, 0, 0, 0.9)
        inst.blobhead.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

        inst.highlightchildren = { inst.blobhead }

    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst.SetTargetPosition = SetTargetPosition

    inst.attack_speed = 40

    inst:ListenForEvent("animover", on_anim_over)

    return inst
end

return Prefab("nyx_wmz_profire", profn, rotatefireassets),
    Prefab("nyx_wmz_beam_fx", beamfn,beamassets),
    Prefab("nyx_wmz_gestalt", gestaltfn)
