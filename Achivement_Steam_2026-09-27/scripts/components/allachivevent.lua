require "functions/helperfunctions"
require "functions/deconstructionhelperfunctions"
local novaachievementtracker = require "functions/novaachievementtracker"
local achievfuncs = require "functions/achievfunctions"
local removed_achievements = require "constants/removedachievements"
local SeasonalCatalog = require "constants/seasonaltaskcatalog"
local SeasonalTaskRuntime = require "functions/seasonaltaskruntime"
local SeasonalCycle = require "achievement/seasonalcycle"
local SeasonalRewards = require "constants/seasonalrewarddata"
local SeasonalRewardRuntime = require "functions/seasonalrewardruntime"

local function CopyTable(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = CopyTable(child) end
	return result
end

local allachivevent = Class(
		function(self, inst)
			self.inst = inst
			self.gotinitial = false
			self.savefilename = "unknown"
			self.seasonalcycle = nil
			self._loaded_seasonalcycle = nil
			self._seasonal_listeners = {}
			self.isready = false
			for achname, ach in pairs(ach_lists) do
				self[achname] = false
				if ach.current then
					self[achname.."amount"] = 0
				end
				if ach.list then
					self[achname.."list"] = chasni_copylist(ach_list_lists[achname])
				end
			end

			self.oldageamount = 1

			self.agereset = 0
			self.starreset = 0
			self.completeamount = 0
		end,
		nil,
		achievfuncs.getachievfunction()
)

--Save
function allachivevent:OnSave()
	local data = {
		agereset = self.agereset,
		starreset = self.starreset,
		completeamount = self.completeamount,
		gotinitial = self.gotinitial,

		seasonalcycle = CopyTable(self.seasonalcycle),
	}
	for achname, ach in pairs(ach_lists) do
		if string.sub(achname, 1, 4) ~= "task" then
			data[achname] = self[achname]
			if ach.current then
				data[achname.."amount"] = self[achname.."amount"]
			end
			if ach.list then
				data[achname.."list"] = self[achname.."list"]
			end
		end
	end
	return data
end

--Load
function allachivevent:OnLoad(data)
	for achname, ach in pairs(ach_lists) do
		if string.sub(achname, 1, 4) ~= "task" then
			self[achname] = data[achname] or false
			if ach.current then
				self[achname.."amount"] = data[achname] and ach_lists[achname].current or data[achname.."amount"] or 0
			end
			if ach.list then
				self[achname.."list"] = data[achname.."list"] or chasni_copylist(ach_list_lists[achname])
			end
		end
	end

	self.gotinitial = data.gotinitial or false
	self.agereset = data.agereset or 0
	self.starreset = data.starreset or 0
	self.completeamount = data.completeamount or 0
	self._loaded_seasonalcycle = CopyTable(data.seasonalcycle)
	self.isready = true
end

--Counter Reward
function allachivevent:CountAchievement(inst, tag, isseasonaltask, amount)
	if removed_achievements[tag] then return end
	if not self.isready then
		inst:DoTaskInTime(3.01, function()
			self:CountAchievement(inst, tag, isseasonaltask, amount)
		end)
		return
	end

	if self[tag] ~= true then
		local increment = inst.components.timer and inst.components.timer:TimerExists("accomplishrinebuff") and 2 or 1
		-- achievementchip multiplier (2x)
		if inst._achiev_chips and inst._achiev_chips > 1 then
			increment = increment + inst._achiev_chips
		end
		-- shadowtottem multiplier multiplier (3x)
		if inst:HasDebuff("shadowtottem_buff") and inst.components.sanity and inst.components.sanity:IsInsane() then
			increment = increment + 3
		end
		-- duppercritter chasni_critter_slug_star, (2x)
		local debuff = inst:GetDebuff("chasni_critter_slug_star_aura_buff")
		local chance = debuff and debuff.chance
		if chance and chance > 0 and math.random() * 100 < chance  then
			increment = increment + 2
		end
		self[tag.."amount"] = self[tag.."amount"] + increment * (amount or 1)
		if self[tag.."amount"] >= ach_lists[tag].current then
			self[tag] = true
			if isseasonaltask then
				self:CountAchievement(inst, "didtask")
				inst:PushEvent("nova_season_mission_completed")
			else
				self:seffc(inst, tag)
			end
		end
	end
end

--Check Reward
function allachivevent:CheckAchievement(inst, tag, isseasonaltask)
	if removed_achievements[tag] then return end
	if not self.isready then
		inst:DoTaskInTime(3.01, function()
			self:CheckAchievement(inst, tag, isseasonaltask)
		end)
		return
	end

	if self[tag] ~= true then
		self[tag] = true
		if isseasonaltask then
			self:CountAchievement(inst, "didtask")
			inst:PushEvent("nova_season_mission_completed")
		else
			self:seffc(inst, tag)
		end
	end
end

-- Slay
function allachivevent:SlayAchievement(inst, tag, victim, isCheck, fn)
	if removed_achievements[tag] then return end
	local players = chasni_getassistplayers(victim)
	for k,v in pairs(players) do
		if fn == nil or fn(v) then
			if isCheck then
				v.components.allachivevent:CheckAchievement(v, tag)
			else
				v.components.allachivevent:CountAchievement(v, tag)
			end
		end
	end
end

-- Solo Kill
function allachivevent:SoloKillAchievement(inst, tag, victim, isCheck)
	if removed_achievements[tag] then return end
	local pos = Vector3(victim.Transform:GetWorldPosition())
	local ents = FindPlayersInRange(pos.x,pos.y,pos.z, 30)
	if #ents <= 1 then
		if isCheck then
			self:CheckAchievement(inst, tag)
		else
			self:CountAchievement(inst, tag)
		end
	end
end

--Remove List Reward
function allachivevent:RemoveListAchievement(inst, tag, item)
	if removed_achievements[tag] then return end
	if self[tag] ~= true and chasni_findprefab(self[tag.."list"], item) then
		self[tag.."amount"] = self[tag.."amount"] + 1
		table.remove(self[tag.."list"], chasni_findindex(self[tag.."list"], item))
		achievfuncs["current"..tag.."list"](self,self[tag.."list"])
		if next(self[tag.."list"]) == nil then
			self[tag.."amount"] = ach_lists[tag].current
			self[tag] = true
			self:seffc(inst, tag)
		end
	end
end
--Add List Reward
function allachivevent:AddListAchievement(inst, tag, item)
	if removed_achievements[tag] then return end
	if self[tag] ~= true and not chasni_findprefab(self[tag.."list"], item) then
		self[tag.."amount"] = self[tag.."amount"] + 1
		table.insert(self[tag.."list"], item)
		achievfuncs["current"..tag.."list"](self,self[tag.."list"])
		if #self[tag.."list"] >= ach_lists[tag].current then
			self[tag.."amount"] = ach_lists[tag].current
			self[tag] = true
			self:seffc(inst, tag)
		end
	end
end

--Grant Reward
function allachivevent:seffc(inst, tag)
	if removed_achievements[tag] then return end
	SpawnPrefab("seffc").entity:SetParent(inst.entity)
	local strname = STRINGS.ACHIEVEMENTS[tag].name
	local strinfo = STRINGS.ACHIEVEMENTS[tag].info
	if _G.NOTIFICATION then
		TheNet:Announce(inst:GetDisplayName().."   "..strinfo..STRINGS.GUI["space"]..STRINGS.GUI["complA"]..strname..STRINGS.GUI["br2"])
	end

	if _G.NOAWARDS ~= true then
		inst.components.allachivcoin:coinDoDelta(ach_lists[tag].coinget)
		if ach_lists[tag].coinget >= 10 then
			inst._feelaccomplished = true
			if inst._feelaccomplishedtask then
				inst._feelaccomplishedtask:Cancel()
				inst._feelaccomplishedtask = nil
			end
			inst._feelaccomplishedtask = inst:DoTaskInTime(60, function()
				inst._feelaccomplished = nil
			end)
		end
		inst.components.talker:Say(STRINGS.GUI["br1"]..strname..STRINGS.GUI["br2"].."\n"..STRINGS.GUI["obt"]..ach_lists[tag].coinget..STRINGS.GUI["points"])
	else
		inst.components.talker:Say(STRINGS.GUI["br1"]..strname..STRINGS.GUI["br2"])
	end
end

--Enter Game
function allachivevent:intogamefn(inst)
	local _name = TheNet and TheNet:GetUserID() or inst:GetDisplayName()
	self.savefilename = _name
	inst:DoTaskInTime(3, function()
		self.isready = true
		if self.intogame ~= true then
			if self.savefilename == nil or AchievementData[self.savefilename] == nil then
				self.savefilename = "unknown"
			end
			if self.savefilename and AchievementData[self.savefilename] then
				local achievements = AchievementData[self.savefilename]
				for achname, ach in pairs(ach_lists) do
					if string.sub(achname, 1, 4) ~= "task" then
						self[achname] = achievements[achname] or false
						if ach.current then
							self[achname.."amount"] = achievements[achname.."amount"] or 0
						end
						if ach.list then
							self[achname.."list"] = achievements[achname.."list"]
						end
					end
				end

				self.intogame = true
				self.agereset = achievements["agereset"]
				self.starreset = achievements["starreset"]
				self.completeamount = achievements["completeamount"]
				self.gotinitial = achievements["gotinitial"]
				self._loaded_seasonalcycle = CopyTable(achievements["seasonalcycle"])
				inst.components.allachivcoin.coinamount  = achievements["totalstar"]

				AchievementData[self.savefilename] = nil
			else
				self:CheckAchievement(inst, "intogame")
			end
		end
		self:EnsureSeasonalCycle(inst)
		self:AttachSeasonalListeners(inst)

		if TUNING.CHASNI_CONFIG and TUNING.CHASNI_CONFIG.AUTOACHIEVE then
			for achname, ach in pairs(ach_lists) do
				if TUNING.CHASNI_CONFIG.AUTOACHIEVE[string.upper(achname)] then
					self[achname] = true
					if ach.current then
						self[achname.."amount"] = ach_lists[achname].current
					end
					if ach.list then
						self[achname.."list"] = {}
					end
				end
			end
		end

		if not self.gotinitial then
			inst.components.allachivcoin:coinDoDelta(cz_initial_stars)
			if _G.NOTIFICATION then
				TheNet:Announce(inst:GetDisplayName().." nhận được "..cz_initial_stars.." Sao Thành Tựu ban đầu")
			end
			self.gotinitial = true
		end
	end)

	inst:DoTaskInTime(5, function()
		-- VILE : PlayWes
		if inst.prefab == "wes" then
			self:CheckAchievement(inst, "playwes")
		end
	end)

end

--Eat Achievement
function allachivevent:oneatlistener(inst)
	inst:ListenForEvent("oneat", function(inst, data)
		local food = data.food
		local feederach = data.feeder and data.feeder.components.allachivevent
		-- feedplayer
		if feederach and feederach.feedplayer ~= true and inst:GetDisplayName() ~= data.feeder:GetDisplayName() then
			feederach:CountAchievement(data.feeder, "feedplayer")
		end
		--Eat 100
		self:CountAchievement(inst, "supereat")
		--Warm Up
		if  self.eathot ~= true and inst.components.temperature.current <= 0 and chasni_findprefab(heatfood, food.prefab) then
			self:CheckAchievement(inst,"eathot")
		end
		--Cool Down
		if self.eatcold ~= true and inst.components.temperature.current >= 70 and chasni_findprefab(coldfood, food.prefab) then
			self:CheckAchievement(inst,"eatcold")
		end
		--Eat Mandrake
		if self.eatmandrake ~= true and food.prefab == "cookedmandrake" then
			self:CheckAchievement(inst, "eatmandrake")
		end
		--Eat Guardian's Horn
		if self.eatguardianhorn ~= true and food.prefab == "minotaurhorn" then
			self:CheckAchievement(inst, "eatguardianhorn")
		end
		--Eat Cooked Nightberry
		if self.eatnightberry ~= true and food.prefab == "ancientfruit_nightvision_cooked" then
			self:CheckAchievement(inst, "eatnightberry")
		end
		--Eat Lasagna
		if self.eatmonsterlasagna ~= true and food.prefab == "monsterlasagna" then
			self.eatmonsterlasagnaamount = self.eatmonsterlasagnaamount + 1
			inst:DoTaskInTime(60, function()
				if self.eatmonsterlasagnaamount < ach_lists.eatmonsterlasagna.current then
					self.eatmonsterlasagnaamount = self.eatmonsterlasagnaamount - 1
				end
			end)
			if self.eatmonsterlasagnaamount >= ach_lists.eatmonsterlasagna.current then
				self:CheckAchievement(inst, "eatmonsterlasagna")
			end
		end
		--Eat Fav
		if self.eatfavourite ~= true and inst.components.foodaffinity and inst.components.foodaffinity:HasAffinity(food) and inst.components.foodaffinity:GetAffinity(food) then
			self:CountAchievement(inst, "eatfavourite")
		end
		--Eat Gear
		if self.eatgear ~= true and food.prefab == "gears" then
			self:CountAchievement(inst, "eatgear")
		end
		--All Woody Idol
		self:RemoveListAchievement(inst, "eatkitschyidol", food.prefab)
	end)
end

--Death
function allachivevent:onkilled(inst)
	inst:ListenForEvent("death", function(inst, data)
		local attacker = inst.components.combat.lastattacker
		--Die 10 times
		self:CountAchievement(inst, "death")
		if data and data.cause then
			--Charlie
			if self.diecharlie ~= true and data.cause == "NIL" then
				inst:DoTaskInTime(2, function()
					self:CheckAchievement(inst, "diecharlie")
				end)
			end
			--Meteor
			if self.diemeteor ~= true and data.cause == "shadowmeteor" then
				inst:DoTaskInTime(2, function()
					self:CheckAchievement(inst, "diemeteor")
				end)
			end
			--Rose
			if self.dierose ~= true and data.cause == "flower" then
				inst:DoTaskInTime(2, function()
					self:CheckAchievement(inst, "dierose")
				end)
			end
			--Spore Cloud
			if self.diepoison ~= true and data.cause == "sporecloud" then
				inst:DoTaskInTime(2, function()
					self:CheckAchievement(inst, "diepoison")
				end)
			end
		end

		--VILE : Die with trinket
		if self.passtrinket ~= true and inst.components.inventory then
			local item = inst.components.inventory:FindItem(function(item) return item.prefab == "cursed_monkey_token" end)
			if item then
				local pos = Vector3(inst.Transform:GetWorldPosition())
				local ents = FindPlayersInRange(pos.x,pos.y,pos.z, 3.5, true)
				if #ents > 1 then
					self:CheckAchievement(inst, "passtrinket")
				end
			end
		end
	end)
end

--Revive
function allachivevent:respawn(inst)
	inst:ListenForEvent("respawnfromghost", function(inst, data)
		if data and data.user and data.user.components.allachivevent then
			data.user.components.allachivevent:CountAchievement(data.user, "revive")
		end
		if self.reviveeffigy ~= true and data and data.source and data.source.prefab == "resurrectionstatue" then
			inst:DoTaskInTime(2, function()
				self:CheckAchievement(inst, "reviveeffigy")
			end)
		end
		if self.revivewanda ~= true and data and data.source and data.source.prefab == "pocketwatch_revive" then
			inst:DoTaskInTime(2.5, function()
				self:CheckAchievement(inst, "revivewanda")
			end)
		end
		if self.reviveamulet ~= true and data and data.source and data.source.prefab == "amulet" then
			inst:DoTaskInTime(2, function()
				self:CountAchievement(inst, "reviveamulet")
			end)
		end
	end)
end

--Health Change
function allachivevent:healthchange(inst)
	inst:ListenForEvent("healthdelta", function(inst, data)
		if self.healtillweed ~= true and data and data.cause and data.cause == "tillweedsalve" and data.amount and data.amount > 0 then
			self:CheckAchievement(inst,"healtillweed")
		end
		if self.healwortox ~= true and data and data.cause and data.cause == "wortox_soul" and data.amount and data.amount > 0 then
			self:CountAchievement(inst,"healwortox")
		end
	end)
end

-- Fish Pick Chop Mine
function allachivevent:onworklistener(inst)
	inst:ListenForEvent("fishingcatch", function()
		self:CountAchievement(inst, "fishmaster")
	end)
	inst:ListenForEvent("fishcaught", function()
		self:CountAchievement(inst, "fishmaster")
	end)
	inst:ListenForEvent("picksomething", function(inst, data)
		if data.object and data.object.components.pickable and not data.object.components.trader then
			if data.object.prefab == "flower_withered" and self.wither ~= true then
				self:CountAchievement(inst, "wither")
			end
			self:CountAchievement(inst, "pickmaster")
		end
	end)
	inst:ListenForEvent("finishedwork", function(inst, data)
		-- this is counted as killing
		if self.birchnut ~= true and data.target and data.target.prefab == "deciduoustree" and data.target.monster and data.action and data.action == ACTIONS.CHOP then
			self:CountAchievement(inst, "birchnut")
			local players = chasni_getassistplayers(data.target)
			for k,v in pairs(players) do
				if v.components.allachivevent then
					v.components.allachivevent:CountAchievement(v, "birchnut")
				end
			end
		end
		if self.chopmaster ~= true and (data.action == ACTIONS.CHOP or (data.action == ACTIONS.DIG and data.target:HasTag("stump"))) then
			self:CountAchievement(inst, "chopmaster")
		end
		if self.minemaster ~= true and data.action == ACTIONS.MINE then
			self:CountAchievement(inst, "minemaster")
		end
		-- MISC : opentreasure and piratechest
		if self.opentreasure ~= true and data.action == ACTIONS.HAMMER and data.target.prefab == "sunkenchest" then
			self:CheckAchievement(inst, "opentreasure")
		end
		if self.piratechest ~= true and data.action == ACTIONS.DIG and data.target.prefab == "pirate_stash" then
			self:CheckAchievement(inst, "piratechest")
		end
	end)
	inst:ListenForEvent("haunt", function(inst, data)
		-- VILE : hauntpig
		if self.hauntpig ~= true and data.target.prefab == "pigman" then
			self:CountAchievement(inst, "hauntpig")
		end
	end)
	inst:ListenForEvent("deployitem", function(inst,data)
		if self.plantmaster ~= true and chasni_findprefab(plantables, data.prefab) then
			self:CountAchievement(inst, "plantmaster")
		end
	end)
end

--Movement
function allachivevent:onmovetask(inst)
	inst:DoPeriodicTask(1, function()
		if inst:HasTag("playerghost") then return end
		if inst.components.locomotor.wantstomoveforward then
			--Ride
			if inst.components.rider and inst.components.rider:IsRiding() and inst.components.rider.mount then
				if self.rider ~= true and inst.components.rider.mount.prefab == "beefalo" then
					self:CountAchievement(inst, "rider")
				elseif self.riderwoby ~= true and inst.components.rider.mount.prefab == "wobybig" then
					self:CountAchievement(inst, "riderwoby")
				end
			else
				--Walk
				self:CountAchievement(inst, "walkalot")
			end
		else
			--Stop
			self:CountAchievement(inst, "stopalot")
		end
	end)
end

--Check Fullness
function allachivevent:fullstatcheck(inst)
	inst:DoPeriodicTask(1, function()
		--Sanity
		if self.fullsanity ~= true and inst.components.sanity.current >= inst.components.sanity.max*0.95 and inst.components.health.currenthealth > 0 then
			self:CountAchievement(inst, "fullsanity")
		end
		--Hunger
		if self.fullhunger ~= true and inst.components.hunger.current >= inst.components.hunger.max*0.95 and inst.components.health.currenthealth > 0 then
			self:CountAchievement(inst, "fullhunger")
		end
		--Mighty
		if self.fullmighty ~= true and inst.GetMightiness and inst:GetMightiness() >= 0.95 and inst.components.health.currenthealth > 0 then
			self:CountAchievement(inst, "fullmighty")
		end
		--Inspiration
		if self.fullsinginsp ~= true and inst.GetInspiration and inst:GetInspiration() >= 0.95 and inst.components.health.currenthealth > 0 then
			self:CountAchievement(inst, "fullsinginsp")
		end
	end)
end

--BeFriend
function allachivevent:onmakefriend(inst)
	local oldAddFollower = inst.components.leader.AddFollower
	function inst.components.leader:AddFollower(follower)
		if self.followers[follower] == nil and follower.components.follower then
			local achiv = inst.components.allachivevent
			--Bunnyman
			if achiv.friendbunny ~= true and follower.prefab == "bunnyman" then
				achiv:CountAchievement(inst, "friendbunny")
			end
			--Merm
			if achiv.friendmerm ~= true and follower.prefab == "merm" then
				achiv:CountAchievement(inst, "friendmerm")
			end
			--Catcoon
			if achiv.friendcat ~= true and follower.prefab == "catcoon" then
				achiv:CountAchievement(inst, "friendcat")
			end
			--RockLobster
			if achiv.friendrocky ~= true and follower.prefab == "rocky" then
				achiv:CountAchievement(inst, "friendrocky")
			end
			--ClockWork
			if achiv.friendclockwork ~= true and follower.prefab == "rook_nightmare" then
				achiv:CountAchievement(inst, "friendclockwork")
			end
			--Mandrake
			if achiv.mandrake ~= true and follower.prefab == "mandrake_active" and not TheWorld.components.worldstate.data.isday then
				achiv:CountAchievement(inst, "mandrake")
			end
			--TallBirb
			if achiv.smallbird ~= true and follower.prefab == "smallbird" then
				achiv:CheckAchievement(inst, "smallbird")
			end
		end
		oldAddFollower(inst.components.leader, follower)
	end
end

--Starving Insane Wet Freeze Overheat
function allachivevent:onpaintask(inst)
	inst:DoPeriodicTask(1, function()
		if self.sanitymaxwell ~= true and inst.components.sanity:GetPenaltyPercent() >= 0.5 and inst.components.health.currenthealth > 0 then
			self:CountAchievement(inst, "sanitymaxwell")
		end
		if self.nosanity ~= true and inst.components.sanity:IsInsanityMode() and inst.components.sanity.current < 1 and inst.components.health.currenthealth > 0 then
			self:CountAchievement(inst, "nosanity")
		end
		if self.lunacy ~= true and inst.components.sanity:IsLunacyMode() and inst.components.sanity.current >= inst.components.sanity.max and inst.components.health.currenthealth > 0 then
			self:CountAchievement(inst, "lunacy")
		end
		if self.starve ~= true and inst.components.hunger.current <= 0 and inst.components.health.currenthealth > 0 then
			self:CountAchievement(inst, "starve")
		end
		if self.icebody ~= true and inst.components.temperature.current <= 0 and inst.components.health.currenthealth > 0 then
			self:CountAchievement(inst, "icebody")
		end
		if self.firebody ~= true and inst.components.temperature.current >= 70 and inst.components.health.currenthealth > 0 then
			self:CountAchievement(inst, "firebody")
		end
		if self.moistbody ~= true and inst.components.moisture.moisture == 100 then
			self:CountAchievement(inst, "moistbody")
		end
	end)
end

--Burn Freeze Drown Lightning
function allachivevent:onpainlistener(inst)
	inst:ListenForEvent("onignite", function(inst)
		self:CheckAchievement(inst, "burn")
	end)
	inst:ListenForEvent("freeze", function(inst)
		self:CheckAchievement(inst, "freeze")
	end)
	inst:ListenForEvent("on_washed_ashore", function(inst, data)
		self:CheckAchievement(inst, "drown")
	end)
end

--Killing
function allachivevent:onkilledother(inst)
	inst:ListenForEvent("killed", function(inst, data)
		local victim = data.victim
		if victim then
			-- VILE
			--Butterfly
			if self.killbutterfly ~= true and victim.prefab == "butterfly" then
				self:CountAchievement(inst, "killbutterfly")
			end
			--Bird
			if self.killbird ~= true and (victim.prefab == "crow" or victim.prefab == "robin" or victim.prefab == "robin_winter" or victim.prefab == "canary" or victim.prefab == "puffin") then
				self:CountAchievement(inst, "killbird")
			end
			--Glommer
			if self.killgloomer ~= true and victim.prefab == "glommer" then
				self:CheckAchievement(inst, "killgloomer")
			end
			--Chester
			if self.killchester ~= true and victim.prefab == "chester" then
				self:CheckAchievement(inst, "killchester")
			end
			--Fugu Hutch
			if self.killhutch ~= true and victim.prefab == "hutch" and victim.components.amorphous:GetCurrentForm() == "FUGU" and inst.components.health.currenthealth <= 10  then
				self:CheckAchievement(inst, "killhutch")
			end
			--Chester
			if self.killfriendlyfruitfly ~= true and victim.prefab == "friendlyfruitfly" then
				self:CheckAchievement(inst, "killfriendlyfruitfly")
			end
			--Marotter Den
			if self.killotterhouse ~= true and victim.prefab == "otterden" then
				self:CheckAchievement(inst, "killotterhouse")
			end

			chasni_checkslayachievement(inst, victim)

			-- SOLO
			--Lavae
			if victim.prefab == "lavae" and self.lavae ~= true then
				self:SoloKillAchievement(inst, "lavae", victim)
			end
			--spiderqueen
			if victim.prefab == "spiderqueen" and self.spiderqueen ~= true then
				self:SoloKillAchievement(inst, "spiderqueen", victim)
			end
			--Pengul
			if victim.prefab == "mutated_penguin" and self.pengul ~= true then
				self:SoloKillAchievement(inst, "pengul", victim)
			end
			--Tentapillar
			if victim.prefab == "tentacle_pillar" and self.tentapillar ~= true then
				self:SoloKillAchievement(inst, "tentapillar", victim)
			end
			--Sea Weed
			if victim.prefab == "waterplant" and self.seaweed ~= true then
				self:SoloKillAchievement(inst, "seaweed", victim)
			end
			--Grass Gator
			if victim.prefab == "grassgator" and self.grassgator ~= true then
				self:SoloKillAchievement(inst, "grassgator", victim)
			end
			--Ewecus
			if victim.prefab == "spat" and self.ewecus ~= true then
				self:SoloKillAchievement(inst, "ewecus", victim, true)
			end
			--Ghost
			if victim.prefab == "ghost" and self.ghost ~= true then
				self:SoloKillAchievement(inst, "ghost", victim, true)
			end
			--Gnarwail
			if victim.prefab == "gnarwail" and self.gnarwail ~= true then
				self:SoloKillAchievement(inst, "gnarwail", victim, true)
			end
			--Rockjaw
			if victim.prefab == "shark" and self.rockjaw ~= true then
				self:SoloKillAchievement(inst, "rockjaw", victim, true)
			end
			--Great Depths Worm
			if victim.prefab == "worm_boss" and self.bigworm ~= true then
				self:SoloKillAchievement(inst, "bigworm", victim, true)
			end
			--Deadelgänger
			if victim.prefab == "player_hosted" and self.soloyourself ~= true and victim.hosted_userid and victim.hosted_userid:value() == self.inst.userid then
				self:SoloKillAchievement(inst, "soloyourself", victim, true)
			end
		end
	end)
end

-- On tick
function allachivevent:ontimepass(inst)
	inst:DoPeriodicTask(5, function(inst)
		--Age
		if self.oldage ~= true then
			self.oldageamount = math.ceil(inst.components.age:GetAge() / TUNING.TOTAL_DAY_TIME) - self.agereset + 1
			if self.oldageamount >= ach_lists.oldage.current and self.oldage ~= true then
				self:CheckAchievement(inst,"oldage")
			end
		end
		--LavaeFriend
		if self.friendlylavae ~= true then
			local tooth = inst.components.inventory:FindItem(function(item) return item.prefab == "lavae_tooth" end)
			if tooth and tooth.components.leader:IsBeingFollowedBy("lavae_pet") then
				self:CheckAchievement(inst, "friendlylavae")
			end
		end
		--Snow Chester
		if self.snowchester ~= true then
			local eyebone = inst.components.inventory:FindItem(function(item) return item.prefab == "chester_eyebone" end)
			if eyebone and eyebone.EyeboneState == "SNOW" then
				self:CheckAchievement(inst, "snowchester")
			end
		end
		--Super Star
		if self.starspent ~= true then
			self.starspentamount = inst.components.allachivcoin.starsspent - self.starreset
			if self.starspentamount >= ach_lists.starspent.current then
				self.starspentamount = ach_lists.starspent.current
				self:CheckAchievement(inst,"starspent")
			end
		end
	end)
end

--Craft
function allachivevent:onbuild(inst)
	inst:ListenForEvent("consumeingredients", function(inst)
		self:CountAchievement(inst, "buildmaster")
	end)
	inst:ListenForEvent("builditem", function(inst, data)
		if self.craftnet ~= true and data and ((data.recipe and data.recipe.product == "thulecitebugnet") or (data.item and data.item.prefab == "thulecitebugnet")) then
			self:CheckAchievement(inst, "craftnet")
		end
		if self.iridescentgems ~= true and data and data.recipe and data.recipe.name == "transmute_opalpreciousgem" then
			self:CheckAchievement(inst, "iridescentgems")
		end
		if self.buygears ~= true and data and data.recipe and data.recipe.name == "wanderingtradershop_gears" then
			self:CheckAchievement(inst, "buygears")
		end
		if self.wickerbook ~= true and data and data.recipe then
			self:RemoveListAchievement(inst, "wickerbook", data.recipe.name)
		end
	end)
end

--Tick
function allachivevent:ontick(inst)
	inst:DoPeriodicTask(1, function()
		if not inst:HasTag("playerghost") then
			self:CountAchievement(inst, "pacifist")
		end
	end)
end

--Tank
function allachivevent:onattacked(inst)
	inst:ListenForEvent("attacked", function(inst, data)
		if self.dmgnodmg ~= true then
			self.dmgnodmgamount = 0
		end
		local damage = data and data.damageresolved or 0
		if self.tank ~= true and damage > 0 then
			self.tankamount = math.ceil(self.tankamount + damage)
			if self.tankamount >= ach_lists.tank.current then
				self.tankamount = ach_lists.tank.current
				self:CheckAchievement(inst, "tank")
			end
		end
	end)
end

--Damage
function allachivevent:hitother(inst)
	inst:ListenForEvent("onhitother", function(inst, data)
		-- >>>> use damage instead damageresolved to makesure player did not even try to deal damage
		if self.pacifist ~= true and data.damage and data.damage >= 0 then
			self.pacifistamount = 0
		end

		if chasni_isValidVictim(data.target) then
			local damage = data.damageresolved or 0
			if self.dmgnodmg ~= true and damage >= 0 then
				self.dmgnodmgamount = math.ceil(self.dmgnodmgamount + damage)
				if self.dmgnodmgamount >= ach_lists.dmgnodmg.current then
					self.dmgnodmgamount = ach_lists.dmgnodmg.current
					self:CheckAchievement(inst, "dmgnodmg")
				end
			end
			if self.damagedeal ~= true then
				if damage >= 0 then
					self.damagedealamount = math.ceil(self.damagedealamount + damage)
					if self.damagedealamount >= ach_lists.damagedeal.current then
						self.damagedealamount = ach_lists.damagedeal.current
						self:CheckAchievement(inst, "damagedeal")
					end
				end
			end
		end
	end)
end

function allachivevent:alive(inst)
	inst:DoPeriodicTask(1, function()
		--Live in Cave
		if TheWorld:HasTag("cave") and inst:HasTag("playerghost") ~= true and self.caveage ~= true then
			self:CountAchievement(inst, "caveage")
		end
		--Live in Boat
		if not TheWorld:HasTag("cave") and not inst:HasTag("playerghost") and not inst:IsOnValidGround() and self.waterage ~= true then
			self:CountAchievement(inst, "waterage")
		end
		--Mile Walk in turf
		if inst:HasTag("playerghost") ~= true and self.walkturf ~= true then
			local turf = tostring(TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition()))
			self:AddListAchievement(inst, "walkturf", turf)
		end
	end)
end

--Do Emotes
function allachivevent:doemote(inst)
	inst:ListenForEvent("emote", function()
		if self.dance ~= true then
			local single = true
			local pos = Vector3(inst.Transform:GetWorldPosition())
			local ents = FindPlayersInRange(pos.x,pos.y,pos.z, 15, true)
			for k,v in pairs(ents) do
				if v ~= inst and v.sg and v.sg:HasStateTag("dancing") and inst.sg and inst.sg:HasStateTag("dancing") and v.components.allachivevent then
					single = false
					v.components.allachivevent:CountAchievement(v, "dance")
				end
			end
			if single == false then
				self:CountAchievement(inst, "dance")
			end
		end
	end)
end

function allachivevent:onequip(inst)
	inst:ListenForEvent("equip", function(inst, data)
		local itemprefab = data.item.prefab
		local giantplantitemprefab = string.sub(itemprefab, -6) == "_waxed" and string.sub(itemprefab, 1, -7) or itemprefab
		self:RemoveListAchievement(inst, "giantplant", giantplantitemprefab)
		self:RemoveListAchievement(inst, "glassmaker", itemprefab)
	end)
	inst:ListenForEvent("equipskinneditem", function(inst, data)
		self:CheckAchievement(inst, "equipingskin")
	end)
end

function allachivevent:onreroll(inst)
	inst:ListenForEvent("ms_playerreroll", function(rolled_inst)
		local _name = self.savefilename
		if _name == nil then
			_name = "unknown"
		end

		local SaveAchieve = {}
		for achname, ach in pairs(ach_lists) do
			if string.sub(achname, 1, 4) ~= "task" then
				SaveAchieve[achname] = self[achname] or false
				if ach.current then
					SaveAchieve[achname.."amount"] = self[achname.."amount"] or 0
				end
				if ach.list then
					SaveAchieve[achname.."list"] = self[achname.."list"] or chasni_copylist(ach_list_lists[achname])
				end
			end
		end
		self.isready = false

		SaveAchieve["starreset"] = self.starreset or 0
		SaveAchieve["completeamount"] = self.completeamount or 0
		SaveAchieve["gotinitial"] = self.gotinitial or true
		SaveAchieve["agereset"] = self.agereset or 0
		SaveAchieve["seasonalcycle"] = CopyTable(self.seasonalcycle)
		SaveAchieve["totalstar"] = inst.components.allachivcoin.coinamount + math.ceil(inst.components.allachivcoin.starsspent)

		if inst.components.petleash then
			inst.components.petleash:Chasni_DespawnPetsWithTag("chasni_critter")
		end
		AchievementData[_name] = SaveAchieve
	end)
end

local function CurrentSeason()
	local state = TheWorld and TheWorld.state or {}
	local season = state.season
	if SeasonalCatalog.IsSeason(season) then return season end
	if state.isspring then return "spring" end
	if state.issummer then return "summer" end
	if state.iswinter then return "winter" end
	return "autumn"
end

local function CurrentSeasonKey()
	local state = TheWorld and TheWorld.state or {}
	local cycles = math.floor(tonumber(state.cycles) or 0)
	local elapsed = math.floor(tonumber(state.elapseddaysinseason) or 0)
	return CurrentSeason() .. ":" .. tostring(cycles - elapsed)
end

local function PrefabExists(prefab)
	local prefabs = rawget(_G, "Prefabs")
	return type(prefabs) ~= "table" or prefabs[prefab] ~= nil
end

function allachivevent:RollSeasonalReward(season, milestone)
	return SeasonalRewards.Roll(season, milestone, math.random, PrefabExists)
end

function allachivevent:EnsureSeasonalRewards()
	if not self.seasonalcycle then return false end
	return SeasonalCycle.EnsureRewardRolls(self.seasonalcycle, function(season, milestone)
		return self:RollSeasonalReward(season, milestone)
	end)
end

function allachivevent:EnsureSeasonalCycle(inst)
	inst = inst or self.inst
	local season = CurrentSeason()
	local key = CurrentSeasonKey()
	local source = self._loaded_seasonalcycle or self.seasonalcycle
	if self._loaded_seasonalcycle == nil and self.seasonalcycle and self.seasonalcycle.season == season and self.seasonalcycle.season_key == key then
		self:EnsureSeasonalRewards()
		self:SyncSeasonalNetvars(inst)
		return false
	end
	local was_listening = self._seasonal_started == true
	if was_listening then self:DetachSeasonalListeners(inst) end
	self.seasonalcycle = SeasonalCycle.Load(source, season, key, math.random)
	self._loaded_seasonalcycle = nil
	self:EnsureSeasonalRewards()
	if was_listening then self:AttachSeasonalListeners(inst) end
	self:SyncSeasonalNetvars(inst)
	return true
end

function allachivevent:DetachSeasonalListeners(inst)
	inst = inst or self.inst
	for event, callback in pairs(self._seasonal_listeners or {}) do
		if type(inst.RemoveEventCallback) == "function" then
			inst:RemoveEventCallback(event, callback)
		end
	end
	self._seasonal_listeners = {}
	self._seasonal_started = false
end

function allachivevent:AttachSeasonalListeners(inst)
	inst = inst or self.inst
	self:DetachSeasonalListeners(inst)
	if type(inst.ListenForEvent) ~= "function" or not self.seasonalcycle or self.seasonalcycle.status ~= "active" then return end
	local events = {}
	for _, slot in ipairs(self.seasonalcycle.slots) do
		local definition = SeasonalCatalog.ById(slot.id)
		local event = SeasonalTaskRuntime.EventName(definition)
		if event then events[event] = true end
	end
	for event in pairs(events) do
		local callback = function(player, data)
			for _, slot in ipairs(self.seasonalcycle and self.seasonalcycle.slots or {}) do
				if not slot.complete then
					local definition = SeasonalCatalog.ById(slot.id)
					if definition and SeasonalTaskRuntime.EventName(definition) == event and SeasonalTaskRuntime.Match(definition, player, data) then
						self:AdvanceSeasonalTask(slot.id, SeasonalTaskRuntime.Amount(definition, player, data))
					end
				end
			end
		end
		self._seasonal_listeners[event] = callback
		inst:ListenForEvent(event, callback)
	end
	self._seasonal_started = true
end

function allachivevent:AdvanceSeasonalTask(task_id, amount)
	if not self.seasonalcycle or self.seasonalcycle.status ~= "active" then return false end
	local completed_now = SeasonalCycle.Advance(self.seasonalcycle, task_id, amount)
	if completed_now then
		self:CountAchievement(self.inst, "didtask")
		self.inst:PushEvent("nova_season_mission_completed")
	end
	self:EnsureSeasonalRewards()
	self:SyncSeasonalNetvars(self.inst)
	return completed_now
end

function allachivevent:checkseasonaltask()
	return SeasonalCycle.CompletedCount(self.seasonalcycle)
end

function allachivevent:ClaimSeasonalReward(inst, milestone, receipt)
	inst = inst or self.inst
	self:EnsureSeasonalCycle(inst)
	milestone = tonumber(milestone)
	if milestone ~= 1 and milestone ~= 2 and milestone ~= 4 and milestone ~= 6 then return false end
	if not SeasonalCycle.CanClaim(self.seasonalcycle, milestone) then return false end
	local reward = self.seasonalcycle.rewards[milestone]
	local bundle = SeasonalRewards.Get(reward.id, self.seasonalcycle.season)
	local prepared = bundle and SeasonalRewardRuntime.Prepare(inst, bundle) or nil
	if prepared == nil then
		local fallback_id = SeasonalRewards.FallbackId(milestone)
		if fallback_id ~= nil and reward.id ~= fallback_id then
			reward.id = fallback_id
			bundle = SeasonalRewards.Get(fallback_id, self.seasonalcycle.season)
			prepared = bundle and SeasonalRewardRuntime.Prepare(inst, bundle) or nil
			self:SyncSeasonalNetvars(inst)
		end
	end
	if prepared == nil then return false end
	local granted = SeasonalRewardRuntime.Grant(inst, prepared)
	if not granted or not SeasonalCycle.MarkClaimed(self.seasonalcycle, milestone, receipt) then return false end
	inst:PushEvent("nova_season_mission_claimed")
	self:SyncSeasonalNetvars(inst)
	self:TryAdvanceSeasonalRound(inst)
	return true
end

function allachivevent:ClaimAllSeasonalRewards(inst, receipt_prefix)
	local claimed = false
	for _, milestone in ipairs(SeasonalRewards.MILESTONES) do
		local receipt = tostring(receipt_prefix or "all") .. ":" .. tostring(milestone)
		if self:ClaimSeasonalReward(inst, milestone, receipt) then claimed = true end
	end
	return claimed
end

function allachivevent:TryAdvanceSeasonalRound(inst)
	inst = inst or self.inst
	if not SeasonalCycle.CanAdvanceRound(self.seasonalcycle) then return false end
	self:DetachSeasonalListeners(inst)
	if not SeasonalCycle.NextRound(self.seasonalcycle, math.random) then return false end
	if self.seasonalcycle.status == "active" then
		self:AttachSeasonalListeners(inst)
		inst:PushEvent("nova_season_mission_assigned")
	else
		inst:PushEvent("nova_season_mission_season_finished")
	end
	self:SyncSeasonalNetvars(inst)
	return true
end

function allachivevent:SyncSeasonalNetvars(inst)
	inst = inst or self.inst
	local state = self.seasonalcycle
	if type(state) ~= "table" then return end
	local function Set(name, value)
		local variable = inst[name]
		if variable and type(variable.set) == "function" then variable:set(value) end
	end
	for index = 1, 6 do
		local slot = state.slots[index]
		local definition = slot and SeasonalCatalog.ById(slot.id) or nil
		Set("seasonaltaskid" .. index, slot and slot.id or "")
		Set("seasonaltaskprogress" .. index, slot and slot.progress or 0)
		Set("seasonaltasktarget" .. index, definition and definition.target or 0)
		Set("seasonaltaskdone" .. index, slot and slot.complete == true or false)
	end
	local milestones = SeasonalRewards.MILESTONES
	for index = 1, 4 do
		local reward = state.rewards[milestones[index]]
		Set("seasonalreward" .. index, reward and reward.id or "")
		Set("taskprize" .. index, reward and reward.claimed == true or false)
	end
	Set("seasonalround", state.round or 1)
	Set("seasonalfinished", state.status == "finished")
end

-- Compatibility entrypoints used by old saves and UI code during migration.
function allachivevent:populateseasonaltasks(inst)
	self:EnsureSeasonalCycle(inst)
end

function allachivevent:claimtaskprizes(inst, receipt_prefix)
	return self:ClaimAllSeasonalRewards(inst, receipt_prefix)
end

function allachivevent:claimtaskprize(inst, milestone, receipt)
	return self:ClaimSeasonalReward(inst, milestone, receipt)
end

--Init
function allachivevent:Init(inst)
	inst:DoTaskInTime(.1, function()
		self:intogamefn(inst)
		self:oneatlistener(inst)
		self:ontick(inst)
		self:onmovetask(inst)
		self:onkilled(inst)
		self:onkilledother(inst)
		self:onpainlistener(inst)
		self:onmakefriend(inst)
		self:onworklistener(inst)
		self:alive(inst)
		self:respawn(inst)
		self:healthchange(inst)
		self:ontimepass(inst)
		self:onbuild(inst)
		self:onattacked(inst)
		self:hitother(inst)
		self:fullstatcheck(inst)
		self:onpaintask(inst)
		self:allget(inst)
		self:doemote(inst)
		self:onreroll(inst)
		self:onequip(inst)
		novaachievementtracker.attach(inst, self)
		self:EnsureSeasonalCycle(inst)
		self:AttachSeasonalListeners(inst)
		if type(inst.WatchWorldState) == "function" then
			inst:WatchWorldState("season", function()
				if self:EnsureSeasonalCycle(inst) then
					inst:PushEvent("nova_season_mission_assigned")
				end
			end)
		end
		inst:DoTaskInTime(3.2, function()
			inst:PushEvent("nova_season_mission_assigned")
		end)
	end)
end

function allachivevent:checkAll()
	for i, v in ipairs(AllPlayers) do
		czdb("checking", v.prefab)
		for achname, ach in pairs(ach_lists) do
			if not removed_achievements[achname] and v.components.allachivevent[achname] ~= true and achname ~= "complete" and string.sub(achname, 1, 4) ~= "task" then
				czdb(v.prefab.." missing achievement", achname)
				break
			end
		end
	end
end

function allachivevent:grantAll()
	for achname, ach in pairs(ach_lists) do
		if ach and not removed_achievements[achname] and string.sub(achname, 1, 4) ~= "task" then
			self[achname] = true
			if ach.current then
				self[achname.."amount"] = ach_lists[achname].current
			end
			if ach.list then
				self[achname.."list"] = {}
			end
		end
	end
	self.complete = false
end

function allachivevent:iswhatnotcomplete()
	for achname, ach in pairs(ach_lists) do
		if not removed_achievements[achname] and self[achname] ~= true and achname ~= "complete" and string.sub(achname, 1, 4) ~= "task" then
			return achname
		end
	end
	return "TADA"
end

function allachivevent:iscomplete()
	for achname, ach in pairs(ach_lists) do
		if not removed_achievements[achname] and self[achname] ~= true and achname ~= "complete" and string.sub(achname, 1, 4) ~= "task" then
			return false
		end
	end
	return true
end

--All Star
function allachivevent:allget(inst)
	if self.complete ~= true then
		inst:DoPeriodicTask(1, function()
			if self.complete ~= true and self:iscomplete() then
				self.complete = true
				inst:DoTaskInTime(2.5, function()
					self:seffc(inst, "complete")
					inst:DoTaskInTime(.3, function()
						inst.sg:GoToState("mime")
						if not inst.components.locomotor.wantstomoveforward then inst.sg:AddStateTag("busy") end
						for i=1, 25 do
							inst:DoTaskInTime(i/25*3, function()
								local pos = Vector3(inst.Transform:GetWorldPosition())
								SpawnPrefab("explode_firecrackers").Transform:SetPosition(pos.x+math.random(-3,3), pos.y, pos.z+math.random(-3,3))
							end)
						end
					end)
					if self.completeamount < _G.PLAYS_CONFIG then
						for achname, ach in pairs(ach_lists) do
							if not ach.persistent then
								self[achname] = false

								if ach.current and achname ~= "complete" and string.sub(achname, 1, 4) ~= "task" then
									self[achname.."amount"] = 0
								end
								if ach.list then
									self[achname.."list"] = chasni_copylist(ach_list_lists[achname])
								end
							end
						end

						self.oldageamount = 1
						self.completeamount = self.completeamount + 1

						self.starreset = inst.components.allachivcoin.starsspent
						self.agereset = math.ceil(inst.components.age:GetAge() / TUNING.TOTAL_DAY_TIME)
						self:intogamefn(inst)
					end
				end)
			end
		end)
	end
end

return allachivevent
