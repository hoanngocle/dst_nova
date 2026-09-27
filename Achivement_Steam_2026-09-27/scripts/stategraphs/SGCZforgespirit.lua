require("stategraphs/commonstates")

local events =
{
	CommonHandlers.OnAttack(),
	CommonHandlers.OnAttacked(),
	CommonHandlers.OnDeath(),
}

local states =
{
	State {
		name = "idle",
		tags = {"idle", "canrotate"},
		onenter = function(inst, playanim)
			inst.Physics:Stop()
			if playanim then
				inst.AnimState:PlayAnimation(playanim)
				inst.AnimState:PushAnimation("idle", true)
			else
				inst.AnimState:PlayAnimation("idle", true)
			end
			inst.sg:SetTimeout(2 * math.random() + .5)
		end,
		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
		},
	},

	State {
		name = "attack",
		tags = {"attack", "busy"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.Physics:Stop()
			inst.components.combat:StartAttack()
			inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/turtillus/attack1a")
			inst.AnimState:PlayAnimation("attack", false)
		end,
		timeline=
		{
			TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
			TimeEvent(17*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
		},
		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
		},
	},

	State {
		name = "hit",
		tags = {"busy", "hit"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("hit")
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_hit")
		end,
		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State {
		name = "spawn",
		tags = {"busy"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("spawn")
			inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_create")
		end,
		events =
		{
			EventHandler("animover", function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/common/treefire", "ambsound")
				inst.sg:GoToState("idle")
			end),
		},
	},

	State {
		name = "death",
		tags = {"busy"},
		onenter = function(inst)
			inst.SoundEmitter:KillSound("ambsound")
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_break")
			inst.AnimState:PlayAnimation("death")
			inst.Physics:Stop()
			RemovePhysicsColliders(inst)
		end,
		events =
		{
			EventHandler("animover", function(inst) inst:Remove() end),
		},
	},
}

return StateGraph("chasni_forgespirit", states, events, "spawn")
