-- PERK
local removedperks = require "constants/removedperks"
for perkname, perk in pairs(perk_lists) do
	if not removedperks.isRemoved(perkname) then
		AddModRPCHandler("DSTAchievement", perkname, function(player)
			local coin = player.components.allachivcoin
			if perk.custom then
				coin[perk.custom](coin, player)
			elseif perk.multi then
				coin:pickperk1(player, perkname)
			elseif perk.expert then
				coin:pickperk4(player, perkname, perk.expert)
			elseif perk.global then
				coin:pickperk5(player, perkname)
			else
				coin:pickperk3(player, perkname)
			end
		end)
	end
end

-- Reset perk
AddModRPCHandler("AchievementUI", "removecoin", function(player)
	player.components.allachivcoin:removecoin(player, false)
end)

AddClientModRPCHandler("AchievementUI", "change_perk_cost", function(perk, cost)
	if perk_lists and perk_lists[perk] and perk_lists[perk].cost then
		perk_lists[perk].cost = cost
	end
end)

-- LEVEL
for lvlname, lvl in pairs(level_lists) do
	AddModRPCHandler("ChasniLevelRPC", lvlname, function(player)
		local level = player.components.levelsystem
		if lvl.custom then
			level[lvl.custom](level, player)
		else
			level:pickattribute(player, lvlname)
		end
		player:PushEvent("chasni_attributechange")
	end)
	AddModRPCHandler("ChasniLevelRPC", lvlname.."10", function(player)
		local level = player.components.levelsystem
		for i=1, 10 do
			local picked = false
			if lvl.custom then
				picked = level[lvl.custom](level, player)
			else
				picked = level:pickattribute(player, lvlname)
			end
			if not picked then break end
		end
		player:PushEvent("chasni_attributechange")
	end)
	AddModRPCHandler("ChasniLevelRPC", lvlname.."max", function(player)
		local level = player.components.levelsystem
		local picked = true
		while(picked) do
			if lvl.custom then
				picked = level[lvl.custom](level, player)
			else
				picked = level:pickattribute(player, lvlname)
			end
		end
		player:PushEvent("chasni_attributechange")
	end)
end
for lvlname, lvl in pairs(level_lists) do
	AddModRPCHandler("ChasniPetLevelRPC", lvlname, function(player)
		player.components.levelsystem:petpickattribute(player, lvlname)
		player:PushEvent("chasni_attributechange")
	end)
	AddModRPCHandler("ChasniPetLevelRPC", lvlname.."10", function(player)
		for i=1, 10 do
			local picked = player.components.levelsystem:petpickattribute(player, lvlname)
			if not picked then break end
		end
		player:PushEvent("chasni_attributechange")
	end)
	AddModRPCHandler("ChasniPetLevelRPC", lvlname.."max", function(player)
		local picked = true
		while(picked) do
			picked = player.components.levelsystem:petpickattribute(player, lvlname)
		end
		player:PushEvent("chasni_attributechange")
	end)
end

-- Reset level
AddModRPCHandler("AchievementUI", "removeattribute", function(player)
	player.components.levelsystem:removeattributepoints(player, false)
	player:PushEvent("chasni_attributechange")
end)

-- Pet
AddModRPCHandler("AchievementUI", "evolvePet", function(player)
	local pet = player.components.petleash and player.components.petleash:GetChasniCritter()
	if pet and pet.evolve then
		pet:evolve()
	end
end)

-- Taskclaimtaskprizes
AddModRPCHandler("AchievementUI", "claimtaskprizes", function(player, receipt_prefix)
	local component = player and player.components and player.components.allachivevent
	if component and type(receipt_prefix) == "string" and #receipt_prefix > 0 and #receipt_prefix <= 128 then
		component:ClaimAllSeasonalRewards(player, receipt_prefix)
	end
end)

AddModRPCHandler("AchievementUI", "claimtaskprize", function(player, milestone, receipt)
	local component = player and player.components and player.components.allachivevent
	local valid = milestone == 1 or milestone == 2 or milestone == 4 or milestone == 6
	if component and valid and type(receipt) == "string" and #receipt > 0 and #receipt <= 128 then
		component:ClaimSeasonalReward(player, milestone, receipt)
	end
end)

-- UI ZOOM and Placement
AddModRPCHandler("AchievementUI", "saveZoomlevel", function(player, zoomlevel)
	player.components.levelsystem:saveZoomLevel(player, zoomlevel)
end)
AddModRPCHandler("AchievementUI", "saveMainHudType", function(player)
	player.components.levelsystem:saveMainHudType(player)
end)

AddModRPCHandler("AchievementUI", "requestSeasonalSync", function(player)
	local component = player and player.components and player.components.allachivevent
	if component then component:SyncSeasonalNetvars(player) end
end)

AddModRPCHandler("AchievementUI", "saveWidgetXPos", function(player, xpos)
	player.components.levelsystem:savewidgetXPos(player, xpos)
end)

AddModRPCHandler("AchievementUI", "movetrinketslot", function(player)
	local trinketslot = player and player.components.trinketowner and player.components.trinketowner:GetTrinketSlot()
	if trinketslot and trinketslot.components.container then
		trinketslot.components.container:Close(player)
		trinketslot.components.container:Open(player)
	end
end)

-- After Force refresh ui (eating white jellybeans)
AddModRPCHandler("AchievementUI", "donerefreshui", function(player)
	player:RemoveTag("chasni_forcerefreshui")
end)
