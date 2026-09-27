local assets =
{
	Asset("ANIM", "anim/chasni_gemportal.zip"),
	Asset("ATLAS", "images/inventoryimages/chasni_gemportal.xml"),
}

local prefabs =
{
	"collapse_small",
}

local defaulteatencount = { redmooneye = 0, greenmooneye = 0, bluemooneye = 0, yellowmooneye = 0, orangemooneye = 0, purplemooneye = 0, }
local function getdesc(inst, viewer)
	if inst.gemactive and inst.gemcount then
		return subfmt(STRINGS.CHASNI_GEMPORTAL_DESC, {red = inst.gemcount.redmooneye or 0, blue = inst.gemcount.bluemooneye or 0, purple = inst.gemcount.purplemooneye or 0, green = inst.gemcount.greenmooneye or 0, yellow = inst.gemcount.yellowmooneye or 0, orange = inst.gemcount.orangemooneye or 0 })
	else
		return STRINGS.CHASNI_GEMPORTAL_DEF
	end
end

local function onhammered(inst)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal", nil, 0.3)
	inst:Remove()
end

local function onhit(inst)
	if inst.gemactive then
		inst.AnimState:PlayAnimation("hit_on")
		inst.AnimState:PushAnimation("idle_on_loop")
	else
		inst.AnimState:PlayAnimation("hit_off")
		inst.AnimState:PushAnimation("idle_off")
	end
end

local function onbuilt(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/craft")
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle_off")
end

local function RefreshLook(inst, activate)
	if activate then
		inst.AnimState:PlayAnimation("turn_on")
		inst.AnimState:PushAnimation("idle_on_loop", true)
	else
		inst.AnimState:PlayAnimation("turn_off")
		inst.AnimState:PushAnimation("idle_off", true)
	end
end

local function onsave(inst, data)
	data.players = next(inst._savedata) and inst._savedata or nil
	data.gemcount = inst.gemcount or defaulteatencount
	data.gemactive = inst.gemactive or false
end

local function onload(inst, data)
	if data then
		inst._savedata = data and data.players or inst._savedata
		inst.gemcount = data.gemcount or defaulteatencount
		inst.gemactive = data.gemactive or false

		RefreshLook(inst, inst.gemactive)
	end
end

local function abletoaccepttest(inst, item, giver)
	if item.prefab == "opalpreciousgem" and giver and giver.components.allachivcoin and giver.components.allachivcoin.expertwilson1 and giver.components.mooneyeeater then
		return true
	end
	if item:HasTag("moonportalkey") then
		return true
	end
end

local function ongivenitem(inst, giver, item)
	if item.prefab == "opalpreciousgem" and giver and giver.components.allachivcoin and giver.components.allachivcoin.expertwilson1 and giver.components.mooneyeeater then
		inst.gemactive = not inst.gemactive
		RefreshLook(inst, inst.gemactive)
		if inst.gemactive == true then
			inst.gemcount = shallowcopy(giver.components.mooneyeeater.eatencount)
			giver.components.mooneyeeater:RemoveStats()
		else
			giver.components.mooneyeeater:AddStats(shallowcopy(inst.gemcount))
		end
	end

	if item:HasTag("moonportalkey") then
		giver:PushEvent("ms_playerreroll")
		if giver.components.inventory then
			giver.components.inventory:DropEverything()
		end

		if giver.components.leader then
			local followers = giver.components.leader.followers
			for k, v in pairs(followers) do
				if k.components.inventory then
					k.components.inventory:DropEverything()
				elseif k.components.container then
					k.components.container:DropEverything()
				end
			end
		end

		inst._savedata[giver.userid] = giver.SaveForReroll and giver:SaveForReroll() or nil
		local userId = giver.userid or nil
		if userId then
			local x, y, z = giver.Transform:GetWorldPosition()
			local location = { x = x, y = y, z = z }
			DespawnData[userId] = location
		end

		TheWorld:PushEvent("ms_playerdespawnanddelete", giver)
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .5)

	inst.AnimState:SetBank("chasni_gemportal")
	inst.AnimState:SetBuild("chasni_gemportal")
	inst.AnimState:PlayAnimation("idle_off", true)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

	inst:AddTag("structure")
	inst:AddTag("moontrader")
	inst:AddTag("trader")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("lootdropper")

	inst:AddComponent("inspectable")
	inst.components.inspectable.getspecialdescription = getdesc

	inst:AddComponent("trader")
	inst.components.trader:SetAbleToAcceptTest(abletoaccepttest)
	inst.components.trader.acceptnontradable = true
	inst.components.trader.onaccept = ongivenitem
	inst.components.trader.deleteitemonaccept = true

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst.OnSave = onsave
	inst.OnLoad = onload
	inst._savedata = {}

	inst:ListenForEvent("ms_newplayerspawned", function(world, player)
		if inst._savedata[player.userid] then
			if player.LoadForReroll then
				player:LoadForReroll(inst._savedata[player.userid])
			end
			inst._savedata[player.userid] = nil
		end
	end, TheWorld)

	inst:ListenForEvent("ms_playerjoined", function(world, player)
		inst._savedata[player.userid] = nil
	end, TheWorld)

	inst:ListenForEvent("onbuilt", onbuilt)

	return inst
end

return Prefab("chasni_gemportal", fn, assets, prefabs),
MakePlacer("chasni_gemportal_placer", "chasni_gemportal", "chasni_gemportal", "idle")