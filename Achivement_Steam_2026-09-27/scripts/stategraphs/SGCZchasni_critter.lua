require("stategraphs/commonstates")

local events =
{
	EventHandler("oneat", function(inst) inst.sg:GoToState("eat") end),
	EventHandler("critter_avoidcombat", function(inst, data) inst.sg.mem.avoidingcombat = (data ~= nil and data.avoid or false) end),

    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    CommonHandlers.OnLocomote(false,true),
    CommonHandlers.OnHop(),
	CommonHandlers.OnSink(),
    CommonHandlers.OnFallInVoid(),
	EventHandler("doattack", function(inst, data)
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("attack", data.target)
		end
	end),
}

local states =
{
	State {
		name = "idle",
		tags = {"idle", "canrotate"},
		onenter = function(inst, playanim)
			inst.Physics:Stop()
			local idleanim = inst.anim and (inst._alternateform and inst.anim.idle2 or inst.anim.idle) or "idle_loop"
			if playanim then
				inst.AnimState:PlayAnimation(playanim)
				inst.AnimState:PushAnimation(idleanim, true)
			else
				inst.AnimState:PlayAnimation(idleanim, true)
			end
		end,
	},
	State {
		name = "pre_idle",
		tags = {"canrotate", "busy"},
		onenter = function(inst, playanim)
			inst.Physics:Stop()
			if playanim then
				inst.AnimState:PlayAnimation(playanim)
			end
		end,
		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},
	State {
		name = "death",
		tags = {"busy"},
		onenter = function(inst)
			inst.AnimState:PlayAnimation(inst.anim and inst.anim.death or "death")
			inst.Physics:Stop()
			RemovePhysicsColliders(inst)
		end,
	},
	State {
		name = "attack",
		tags = {"attack", "busy"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.Physics:Stop()
			inst.components.combat:StartAttack()
			if inst.anim and inst.anim.atkpre then
				inst.AnimState:PlayAnimation(inst.anim and inst.anim.atkpre or "atk_pre")
				inst.AnimState:PushAnimation(inst.anim and inst.anim.atk or "atk", false)
			else
				inst.AnimState:PlayAnimation(inst.anim and inst.anim.atk or "atk")
			end
		end,
		timeline =
		{
			TimeEvent(1 * FRAMES, function(inst)
				if inst.DoAttack then
					inst:DoAttack(inst.sg.statemem.target)
				end
			end),
		},
		events =
		{
			EventHandler("animqueueover", function(inst)
				if inst.anim and inst.anim.atkpst then
					inst.sg:GoToState("pre_idle", inst.anim.atkpst)
				else
					inst.sg:GoToState("idle")
				end
			end),
		},
	},
	State {
		name = "cast",
		tags = { "busy" },
		onenter = function(inst, data)
			inst.Physics:Stop()
			local castpreanim = inst.anim and (inst._alternateform and inst.anim.castpre2 or (not inst._alternateform and inst.anim.castpre))
			local castanim = inst.anim and (inst._alternateform and inst.anim.cast2 or (not inst._alternateform and inst.anim.cast))
			if castpreanim then
				inst.AnimState:PlayAnimation(castpreanim)
				inst.AnimState:PushAnimation(castanim or "cast", false)
			else
				inst.AnimState:PlayAnimation(castanim or "cast")
			end
		end,
		timeline =
		{
			TimeEvent(1 * FRAMES, function(inst)
				if inst.CastSpell then
					inst:CastSpell()
				end
			end),
		},
		events =
		{
			EventHandler("animqueueover", function(inst)
				local castpstanim = inst.anim and (inst._alternateform and inst.anim.castpst2 or (not inst._alternateform and inst.anim.castpst))
				if castpstanim then
					inst.sg:GoToState("pre_idle", castpstanim)
				else
					inst.sg:GoToState("idle")
				end
			end),
		},
	},
	State {
		name = "cast_loop",
		tags = { "busy" },
		onenter = function(inst, data)
			inst.Physics:Stop()
			local castpreanim = inst.anim and (inst._alternateform and inst.anim.castpre2 or (not inst._alternateform and inst.anim.castpre))
			local castanim = inst.anim and (inst._alternateform and inst.anim.cast2 or (not inst._alternateform and inst.anim.cast))
			if castpreanim then
				inst.AnimState:PlayAnimation(castpreanim)
				inst.AnimState:PushAnimation(castanim or "cast", true)
			else
				inst.AnimState:PlayAnimation(castanim or "cast")
			end
		end,
		timeline =
		{
			TimeEvent(1 * FRAMES, function(inst)
				inst._castloop = true
				if inst.CastSpell then
					inst:CastSpell()
					if inst._maxcastlooptime then
						inst.castloopcounter = inst:DoTaskInTime(inst._maxcastlooptime, function()
							inst._castloop = nil
							if inst.stopCast then
								inst:stopCast()
							end
						end)
					end
				end
			end),
		},
		onexit = function(inst)
			if inst.castloopcounter then
				inst.castloopcounter:Cancel()
				inst.castloopcounter = nil
			end
			if inst._castloop and inst.stopCast then
				inst:stopCast()
			end
			inst._castloop = nil
		end,
	},
}

CommonStates.AddWalkStates(states,
		{
			starttimeline = {
				TimeEvent(0*FRAMES, PlayFootstep),
				TimeEvent(0*FRAMES, function(inst)
					inst.SoundEmitter:PlaySound(inst.sound and inst.sound.walkbank or inst:getSound("walk_pre", "walk"), nil, inst.critterdata and inst.critterdata.walkvolume or nil)
				end),
			},
			walktimeline = {
				TimeEvent(0*FRAMES, PlayFootstep),
				TimeEvent(0*FRAMES, function(inst)
					inst.SoundEmitter:PlaySound(inst.sound and inst.sound.walkbank or inst:getSound("walk", "walk"), nil, inst.critterdata and inst.critterdata.walkvolume or nil)
				end),
			},
			endtimeline = {
				TimeEvent(0*FRAMES, PlayFootstep),
				TimeEvent(0*FRAMES, function(inst)
					inst.SoundEmitter:PlaySound(inst.sound and inst.sound.walkbank or inst:getSound("walk_pst", "walk"), nil, inst.critterdata and inst.critterdata.walkvolume or nil)
				end),
			},
		},
		{
			startwalk = function(inst)
				return inst.anim and (inst._alternateform and (inst.anim.walkpre2 or inst.anim.walk2) or (inst.anim.walkpre or inst.anim.walk or inst.anim.walkloop)) or "floor_floor_1_0_pre"
			end,
			walk = function(inst)
				return inst.anim and (inst._alternateform and (inst.anim.walkloop2 or inst.anim.walk2) or (inst.anim.walkloop or inst.anim.walk)) or "floor_floor_1_0_loop"
			end,
			stopwalk = function(inst)
				return inst.anim and (inst._alternateform and (inst.anim.walkpst2 or inst.anim.walk2) or (inst.anim.walkpst or inst.anim.walk or inst.anim.walkloop)) or "floor_floor_1_0_pst"
			end,
		})

CommonStates.AddHopStates(states,
		true,{
			pre = function(inst)
				if inst.anim then
					return inst.anim.hoppre or inst.anim.hop or "fall"
				end
				return "hop_pre"
			end,
			loop = function(inst)
				if inst.anim then
					return inst.anim.hoploop or inst.anim.hop or "fall"
				end
				return "hop_loop"
			end,
			pst = function(inst)
				if inst.anim then
					return inst.anim.hoppst or inst.anim.hop or "fall"
				end
				return "hop_pst"
			end,
		})
CommonStates.AddSinkAndWashAshoreStates(states,
		{
			washashore = function(inst)
				if inst.anim then
					return inst.anim.sink or "fall"
				end
				return "sink"
			end,
		})
CommonStates.AddVoidFallStates(states,
		{
			voiddrop = function(inst)
				if inst.anim then
					return inst.anim.fall or "fall"
				end
				return "fall"
			end,
		})

local function sleepexonanimover(inst)
	if inst.AnimState:AnimDone() then
		inst.sg.statemem.continuesleeping = true
		inst.sg:GoToState(inst.sg.mem.sleeping and "sleeping" or "wake")
	end
end
table.insert(states, State{
	name = "sleep",
	tags = { "busy", "sleeping", "nowake" },

	onenter = function(inst)
		if inst.components.locomotor ~= nil then
			inst.components.locomotor:StopMoving()
		end
		inst.AnimState:PlayAnimation(inst.anim and inst.anim.sleeppre or "sleep_pre")
	end,

	events =
	{
		EventHandler("animqueueover", sleepexonanimover),
	},

	onexit = function(inst)
		if not inst.sg.statemem.continuesleeping and inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
			inst.components.sleeper:WakeUp()
		end
	end,
})

local function sleepingexonanimover(inst)
	if inst.AnimState:AnimDone() then
		inst.sg.statemem.continuesleeping = true
		inst.sg:GoToState("sleeping")
	end
end
table.insert(states, State{
	name = "sleeping",
	tags = { "busy", "sleeping" },

	onenter = function(inst)
		inst.AnimState:PlayAnimation(inst.anim and inst.anim.sleeploop or "sleep_loop")
	end,

	events =
	{
		EventHandler("animqueueover", sleepingexonanimover),
	},

	onexit = function(inst)
		if not inst.sg.statemem.continuesleeping and inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
			inst.components.sleeper:WakeUp()
		end
	end,
})

local function wakeexonanimover(inst)
	if inst.AnimState:AnimDone() then
		inst.sg:GoToState(inst.sg.mem.sleeping and "sleep" or "idle")
	end
end
table.insert(states, State{
	name = "wake",
	tags = { "busy", "waking", "nosleep" },

	onenter = function(inst)
		if inst.components.locomotor ~= nil then
			inst.components.locomotor:StopMoving()
		end
		inst.AnimState:PlayAnimation(inst.anim and inst.anim.sleeppst or "sleep_pst")
		if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
			inst.components.sleeper:WakeUp()
		end
	end,

	events =
	{
		EventHandler("animqueueover", wakeexonanimover),
	},
})

return StateGraph("SGCZchasni_critter", states, events, "idle", {})
