require "functions/helperfunctions"
local levelfuncs = require "functions/levelfunctions"
local levelcaprewards = require "functions/levelcaprewards"

local MAX_LEVEL = 200

local function getLevelLimit()
	local configured = tonumber(_G.LEVEL_LIMIT)
	return configured and configured > 0 and math.min(configured, MAX_LEVEL) or MAX_LEVEL
end

local function capLevelXP(level, xp)
	return level >= getLevelLimit() and math.min(xp, chasni_getxpgoals(level) - 1) or xp
end

local levelsystem = Class(function(self, inst)
	self.inst = inst
	self.savefilename = "unknown"
	self.level = 1
	self.levelxp = 0
	self.overallxp = 0
	self.capxp = 0

	self.attributepoints = 0
	self.attributepointsspent = 0

	self.petlevel = 1
	self.petlevelxp = 0
	self.petoverallxp = 0
	self.petattributepoints = 0
	self.petattributepointsspent = 0
	self.petcanevolve = false

	self.zoomlevel = 1.2
	self.mainhudtype = false -- True = small / minimalist
	self.widgetXpos = -1

	for lvlname, lvl in pairs(level_lists) do
		self[lvlname.."amount"] = 0
		self[lvlname.."cost"] = 1
		self[lvlname.."max"] = -1
	end

	self.achievementhungerup = 0
	self.achievementsanityup = 0
	self.achievementhealthup = 0
	self.achievementspeedup = 0
	self.achievementabsorbup = 0
	self.achievementdamageup = 0

	self.levelhungerup = 0
	self.levelsanityup = 0
	self.levelhealthup = 0
	self.levelspeedup = 0
	self.levelabsorbup = 0
	self.leveldamageup = 0

	self.petlevelspeedup = 0
	self.petleveldamageup = 0
	self.petlevelattackspeedup = 0
	self.petlevelcooldownup = 0
	self.petlevelspellup = 0
	self.petlevelpassiveup = 0
end, nil, levelfuncs.getlevelfunction())

function levelsystem:OnSave()
	local maxreturn = (self.level-1)*attributepointsOnLevel - self.attributepoints
	local returnattributepoints = math.min(self.attributepointsspent, maxreturn)
	local petmaxreturn = (self.petlevel-1)*attributepointsOnLevel - self.petattributepoints
	local petreturnattributepoints = math.min(self.petattributepointsspent, petmaxreturn)
	local data = {
		level = self.level,
		levelxp = self.levelxp,
		overallxp = self.overallxp,
		capxp = self.capxp,
		attributepoints = self.attributepoints,
		attributepointsspent = returnattributepoints,

		petlevel = self.petlevel,
		petlevelxp = self.petlevelxp,
		petoverallxp = self.petoverallxp,
		petattributepoints = self.petattributepoints,
		petattributepointsspent = petreturnattributepoints,
		petcanevolve = self.petcanevolve,

		widgetXpos = self.widgetXpos,
		zoomlevel = self.zoomlevel,
		mainhudtype = self.mainhudtype,
	}
	for lvlname, lvl in pairs(level_lists) do
		data[lvlname.."amount"] = self[lvlname.."amount"]
		data[lvlname.."cost"] = self[lvlname.."cost"]
	end
	return data
end

function levelsystem:OnLoad(data)
	self.level = math.min(data.level or 1, getLevelLimit())
	self.levelxp = capLevelXP(self.level, data.levelxp or 0)
	self.overallxp = data.overallxp or 0
	self.capxp = data.capxp or 0
	self.attributepoints = data.attributepoints or 0
	self.attributepointsspent = data.attributepointsspent or 0

	self.petlevel = math.min(data.petlevel or 1, getLevelLimit())
	self.petlevelxp = capLevelXP(self.petlevel, data.petlevelxp or 0)
	self.petoverallxp = data.petoverallxp or 0
	self.petattributepoints = data.petattributepoints or 0
	self.petattributepointsspent = data.petattributepointsspent or 0
	self.petcanevolve = data.petcanevolve or false

	self.widgetXpos = data.widgetXpos or -1
	self.zoomlevel = data.zoomlevel or 1
	self.mainhudtype = data.mainhudtype or false

	for lvlname, lvl in pairs(level_lists) do
		self[lvlname.."amount"] = data[lvlname.."amount"] or 0
		self[lvlname.."cost"] = data[lvlname.."cost"] or 1
	end
end

function levelsystem:savewidgetXPos(inst, xpos)
	self.widgetXpos = xpos
end

function levelsystem:saveZoomLevel(inst, zoomlevel)
	self.zoomlevel = zoomlevel
end

function levelsystem:saveMainHudType(inst)
	self.mainhudtype = not self.mainhudtype
end

function levelsystem:onlevelup(inst)
	inst.SoundEmitter:PlaySound("dontstarve/HUD/get_gold")
	inst:PushEvent("chasni_levelup")
end

function levelsystem:attributepointDoDelta(value)
	if _G.NOAWARDS ~= true then
		self.attributepoints = self.attributepoints + value
	end
end

function levelsystem:petattributepointDoDelta(value)
	if _G.NOAWARDS ~= true then
		self.petattributepoints = self.petattributepoints + value
	end
end

function levelsystem:levelDoDelta(inst)
	self.level = self.level + 1
	self:attributepointDoDelta(attributepointsOnLevel)

	SpawnPrefab("seffc").entity:SetParent(inst.entity)
	inst.components.allachivcoin:coinDoDelta(1)
	if _G.NOTIFICATION then
		TheNet:Announce(inst:GetDisplayName().." nhận 1 điểm Thành Tựu khi lên cấp")
	end
end

function levelsystem:xpDoLevelUp(inst)
	if self.level >= getLevelLimit() then return end
	local currentXPGoal = chasni_getxpgoals(self.level)
	self:xpDoDelta(currentXPGoal - self.levelxp + 1, inst, true)
end

function levelsystem:addCapXP(value, inst)
	self.capxp = self.capxp + math.max(0, math.floor(value))
	local stones = math.floor(self.capxp / levelcaprewards.XP_PER_STONE)
	if stones > 0 then
		local delivered = levelcaprewards.GiveLowerSpiritStones(inst, stones)
		self.capxp = self.capxp - delivered * levelcaprewards.XP_PER_STONE
	end
end

local EXPCHIPXP = {1.25, 1.5, 2, 3}
function levelsystem:xpDoDelta(value, inst, fixed, sharable)
	local goal = chasni_getxpgoals(self.level)
	local levelLimit = getLevelLimit()
	if self.level >= levelLimit and (levelLimit < MAX_LEVEL or self.level > MAX_LEVEL) then
		self.levelxp = goal - 1
		return
	end
	if not fixed then
		-- [ XP Constant BONUS ]
		local trinket = chasni_getequippedtrinket(inst)
		-- Trinket bonus [Odd Radio] (1 - 40)
		if trinket and trinket.prefab == "trinket_45" and AllPlayers ~= nil and #AllPlayers == 1 then
			local stacksize = chasni_gettrinketpoint(trinket, 1, 10)
			value = value + stacksize
		end

		-- [ XP MULTIPLIER ]
		-- Setting multiplier
		if _G.EXP_MULT > 0 then
			value = value * _G.EXP_MULT
		end
		-- Wes multiplier (1.25 or 2)
		if inst.prefab == "wes" then
			local wesmult = 1.25
			if inst.components.allachivcoin and inst.components.allachivcoin.expertwes1 then
				wesmult = 2
			end
			value = value * wesmult
		end
		-- Wanda multiplier (-50 or 1.25)
		if inst.prefab == "wanda" then
			local wandamult = inst.age_state == "young" and 1.25 or inst.age_state == "old" and 0.5 or 1
			value = value * wandamult
		end
		-- WX chip multiplier ({1.25, 1.5, 2, 3})
		if inst._exp_chips and inst._exp_chips > 0 then
			value = value * EXPCHIPXP[math.min(4, inst._exp_chips)]
		end
		-- book multiplier multiplier (110%)
		if inst._bookxpmultiplier then
			value = value * 1.1
		end
		-- shadowtottem multiplier multiplier (200%)
		if inst:HasDebuff("shadowtottem_buff") and inst.components.sanity and inst.components.sanity:IsInsane() then
			value = value * 2
		end
		-- Trinket multiplier [Mini Arcade] (125% - 500%)
		if trinket and trinket.prefab == "trinket_chasni_1" then
			local stacksize = chasni_gettrinketpoint(trinket, 0.25, 4)
			value = value * (1 + stacksize)
		end
		-- Trinket multiplier [Broken AAC Device] (-50%)
		if trinket and trinket.prefab == "trinket_chasni_19" and inst:HasTag("mime") then
			value = value * 0.5
		end
		-- Perk Multiplier [xpmultup] (5% * xpmultupamount)
		local xpmultperk = inst.components.allachivcoin and inst.components.allachivcoin.xpmultupamount
		if xpmultperk > 0 then
			value = value * (1 + (allachiv_coindata["xpmultup"] * xpmultperk))
		end
		-- duppercritter chasni_critter_slug_xp, (?%)
		local debuff = inst:GetDebuff("chasni_critter_slug_xp_aura_buff")
		local slugmult = debuff and debuff.mult
		if slugmult and slugmult > 0 then
			value = value * (1 + (slugmult / 100))
		end

		-- xp capping
		if value > goal * 100 then
			value = goal * 100
		end
	end
	value = math.floor(value)
	if self.level == MAX_LEVEL then
		self.overallxp = self.overallxp + value
		self.levelxp = goal - 1
		self:addCapXP(value, inst)
		return
	end

	-- give sharable xp to pet
	if sharable and inst.components.allachivcoin and inst.components.allachivcoin.duppercritter then
		self:petxpDoDelta(value, inst)
	end

	-- share xp
	if sharable and inst:HasDebuff("chasni_banner_xp_buff") then
		for i, v in ipairs(AllPlayers) do
			if v and v:HasDebuff("chasni_banner_xp_buff") then
				local mult = v.components.allachivcoin and v.components.allachivcoin.expertwinona2 and 1 or 0.2
				v.components.levelsystem:xpDoDelta(value * mult, v, true)
			end
		end
	end

	self.overallxp = self.overallxp + value
	self.levelxp = self.levelxp + value
	while self.levelxp > goal and self.level < levelLimit do
		self.levelxp = self.levelxp - goal
		self:levelDoDelta(inst)
		self:onlevelup(inst)
		goal = chasni_getxpgoals(self.level)
	end
	if self.level == MAX_LEVEL then
		self:addCapXP(self.levelxp - 1, inst)
		self.levelxp = goal - 1
	else
		self.levelxp = capLevelXP(self.level, self.levelxp)
	end
end

function levelsystem:petlevelDoDelta(inst)
	self.petlevel = self.petlevel + 1
	self:petattributepointDoDelta(attributepointsOnLevel)
end

function levelsystem:petxpDoLevelUp(inst)
	local currentXPGoal = chasni_getxpgoals(self.petlevel)
	self:petxpDoDelta(currentXPGoal - self.petlevelxp + 1, inst, true)
end

function levelsystem:petxpDoDelta(value, inst)
	local goal = chasni_getxpgoals(self.petlevel)
	if self.petlevel >= getLevelLimit() then
		self.petlevelxp = goal - 1
		return
	end
	value = math.floor(value)

	self.petoverallxp = self.petoverallxp + value
	self.petlevelxp = self.petlevelxp + value
	while self.petlevelxp > goal and self.petlevel < getLevelLimit() do
		self.petlevelxp = self.petlevelxp - goal
		self:petlevelDoDelta(inst)
		self:onlevelup(inst)
		goal = chasni_getxpgoals(self.petlevel)
	end
	self.petlevelxp = capLevelXP(self.petlevel, self.petlevelxp)
end

function levelsystem:freepickattribute(inst, attr)
	self[attr.."amount"] = self[attr.."amount"] + 1
	if self[attr.."fn"] then
		self[attr.."fn"](self, inst)
	end
end

function levelsystem:pickattribute(inst, attr)
	if self.attributepoints >= self[attr.."cost"] then
		self[attr.."amount"] = self[attr.."amount"] + 1
		self.attributepointsspent = self.attributepointsspent + self[attr.."cost"]
		self:attributepointDoDelta(-self[attr.."cost"])
		self[attr.."cost"] = math.min(3,1 + math.floor(self[attr.."amount"]/level_lists[attr].multi))
		if self[attr.."fn"] then
			self[attr.."fn"](self, inst)
		end
		return true
	end
	return false
end

function levelsystem:petpickattribute(inst, attr)
	if self.petattributepoints >= self[attr.."cost"] then
		self[attr.."amount"] = self[attr.."amount"] + 1
		self.petattributepointsspent = self.petattributepointsspent + self[attr.."cost"]
		self:petattributepointDoDelta(-self[attr.."cost"])
		self[attr.."cost"] = math.min(3,1 + math.floor(self[attr.."amount"]/level_lists[attr].multi))
		if self[attr.."fn"] then
			self[attr.."fn"](self, inst)
		end
		return true
	end
	return false
end

function levelsystem:speedlevelfn(inst)
	if self.speedlevelamount > 0 then
		local spd = 1 + self.speedlevelamount * speedGain
		inst.components.locomotor:SetExternalSpeedMultiplier(inst,"speedUpgrade", spd)
	end
end

function levelsystem:damagelevelfn(inst)
	if self.damagelevelamount > 0 then
		local dmg = 1 + self.damagelevelamount * damageGain
		inst.components.combat.externaldamagemultipliers:SetModifier("damageUpgrade", dmg)
	end
end

function levelsystem:absorblevelpick(inst, free)
	local abs = inst.components.combat.externaldamagetakenmultipliers:CalculateModifierFromSource("absorbUpgrade")
	if abs > 1 - max_absorbGain then
		local picked = free and self:freepickattribute(inst, "absorblevel") or self:pickattribute(inst, "absorblevel")
		if picked then
			self:absorblevelfn(inst)
		end
		return picked
	end
end

function levelsystem:absorblevelfn(inst)
	if self.absorblevelamount > 0 then
		local abs = self.absorblevelamount * absorbGain
		inst.components.combat.externaldamagetakenmultipliers:SetModifier("absorbUpgrade", 1 - abs)
	end
end

function levelsystem:petspeedlevelfn(inst)
	if self.petspeedlevelamount > 0 then
		local pet = inst.components.petleash and inst.components.petleash:GetChasniCritter()
		if pet and pet.components.locomotor then
			local spd = 1 + self.petspeedlevelamount * petspeedGain
			pet.components.locomotor:SetExternalSpeedMultiplier(inst,"speedUpgrade", spd)
		end
	end
end

function levelsystem:petdamagelevelfn(inst)
	if self.petdamagelevelamount > 0 then
		local pet = inst.components.petleash and inst.components.petleash:GetChasniCritter()
		if pet then
			if pet.components.planardamage then
				pet._originaldamage = pet._originaldamage or pet.components.planardamage:GetBaseDamage()
				pet.components.planardamage:SetBaseDamage(pet._originaldamage + self.petdamagelevelamount * petdamageGain)
			elseif pet.components.combat then
				pet._originaldamage = pet._originaldamage or pet.components.combat.defaultdamage
				pet.components.combat:SetDefaultDamage(pet._originaldamage + self.petdamagelevelamount * petdamageGain)
			end
		end
	end
end

function levelsystem:removeattributepoints(inst, free)
	local maxreturn = (self.level-1)*attributepointsOnLevel - self.attributepoints
	local returnattributepoints = math.min(self.attributepointsspent, maxreturn)
	local resetpercentage = free and 1 or reset_refund_percentage
	returnattributepoints = math.ceil(returnattributepoints * resetpercentage)
	self.attributepoints = self.attributepoints + returnattributepoints
	self.attributepointsspent = 0

	local petmaxreturn = (self.level-1)*attributepointsOnLevel - self.petattributepoints
	local petreturnattributepoints = math.min(self.petattributepointsspent, petmaxreturn)
	local petresetpercentage = free and 1 or reset_refund_percentage
	petreturnattributepoints = math.ceil(petreturnattributepoints * petresetpercentage)
	self.petattributepoints = self.petattributepoints + petreturnattributepoints
	self.petattributepointsspent = 0

	if reset_health_penalty and not free then
		inst.components.health:DeltaPenalty(TUNING.REVIVE_HEALTH_PENALTY)
	end
	self:resetbuff(inst)

	for lvlname, _ in pairs(level_lists) do
		self[lvlname.."amount"] = 0
		self[lvlname.."cost"] = 1
	end

	if inst.components.health.currenthealth > 0 and not inst.components.rider:IsRiding() and inst.sg:HasState("changeoutsidewardrobe") and (inst.components.wereness == nil or inst.components.wereness:GetPercent() == 0) then
		inst.components.locomotor:Stop()
		inst.sg:GoToState("changeoutsidewardrobe")
	end
	SpawnPrefab("shadow_despawn").Transform:SetPosition(inst.Transform:GetWorldPosition())
	SpawnPrefab("statue_transition_2").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

function levelsystem:resetpet(inst)
	local petmaxreturn = (self.level-1)*attributepointsOnLevel - self.petattributepoints
	local petreturnattributepoints = math.min(self.petattributepointsspent, petmaxreturn)
	petreturnattributepoints = math.ceil(petreturnattributepoints)
	self.petattributepoints = self.petattributepoints + petreturnattributepoints
	self.petattributepointsspent = 0

	local pet = inst.components.petleash and inst.components.petleash:GetChasniCritter()
	if pet then
		pet.components.locomotor:SetExternalSpeedMultiplier(inst,"speedUpgrade", 1)
	end
	local petattribute = { "petspeedlevel", "petdamagelevel", "petattackspeedlevel", "petcooldownlevel", "petspelllevel", "petpassivelevel", }
	for _, lvlname in ipairs(petattribute) do
		self[lvlname.."amount"] = 0
		self[lvlname.."cost"] = 1
	end
end

function levelsystem:resetbuff(inst)
	inst.components.combat.externaldamagemultipliers:SetModifier("damageUpgrade", 1)
	inst.components.combat.externaldamagetakenmultipliers:SetModifier("absorbUpgrade", 1)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst,"speedUpgrade", 1)
	local pet = inst.components.petleash and inst.components.petleash:GetChasniCritter()
	if pet then
		pet.components.locomotor:SetExternalSpeedMultiplier(inst,"speedUpgrade", 1)
	end
end

function levelsystem:onreroll(inst)
	inst:ListenForEvent("ms_playerreroll", function(rolled_inst)
		local _name = self.savefilename
		if _name == nil then
			_name = "unknown"
		end
		local maxreturn = (self.level-1)*attributepointsOnLevel - self.attributepoints
		local returnattributepoints = math.min(self.attributepointsspent, maxreturn)
		local petmaxreturn = (self.petlevel-1)*attributepointsOnLevel - self.petattributepoints
		local petreturnattributepoints = math.min(self.petattributepointsspent, petmaxreturn)

		local SaveLevel = {}
		SaveLevel["level"] = self.level or 1
		SaveLevel["levelxp"] = self.levelxp or 0
		SaveLevel["overallxp"] = self.overallxp or 0
		SaveLevel["capxp"] = self.capxp or 0
		SaveLevel["attributepoints"] = self.attributepoints + returnattributepoints or 0
		SaveLevel["petlevel"] = self.petlevel or 1
		SaveLevel["petlevelxp"] = self.petlevelxp or 0
		SaveLevel["petoverallxp"] = self.petoverallxp or 0
		SaveLevel["petattributepoints"] = self.petattributepoints + petreturnattributepoints or 0
		SaveLevel["petcanevolve"] = self.petcanevolve or false
		SaveLevel["widgetXpos"] = self.widgetXpos or -1
		SaveLevel["zoomlevel"] = self.zoomlevel or 1
		SaveLevel["mainhudtype"] = self.mainhudtype or false
		self.attributepointsspent = 0
		self.petattributepointsspent = 0
		LevelData[self.savefilename] = SaveLevel
	end)
end

function levelsystem:intogamefn(inst)
	self.savefilename = inst.userid or inst:GetDisplayName()
	inst:DoTaskInTime(2.5, function()
		local _name = self.savefilename
		if _name == nil or LevelData[_name] == nil then
			_name = "unknown"
		end
		if self.overallxp == 0 and _name and LevelData[_name] then
			local leveldata = LevelData[_name]
			self.level = math.min(leveldata["level"] or 1, getLevelLimit())
			self.levelxp = capLevelXP(self.level, leveldata["levelxp"] or 0)
			self.overallxp = leveldata["overallxp"]
			self.capxp = leveldata["capxp"] or 0
			self.attributepoints = leveldata["attributepoints"]
			self.petlevel = math.min(leveldata["petlevel"] or 1, getLevelLimit())
			self.petlevelxp = capLevelXP(self.petlevel, leveldata["petlevelxp"] or 0)
			self.petoverallxp = leveldata["petoverallxp"]
			self.petattributepoints = leveldata["petattributepoints"]
			self.petcanevolve = leveldata["petcanevolve"]
			self.widgetXpos = leveldata["widgetXpos"]
			self.zoomlevel = leveldata["zoomlevel"]
			self.mainhudtype = leveldata["mainhudtype"]
			LevelData[_name] = nil
		end
		if self.level == MAX_LEVEL then
			self:addCapXP(0, inst)
		end
	end)
end

function levelsystem:Init(inst)
	inst:DoTaskInTime(.1, function()
		self:onkilledother(inst)
		self:workinglistener(inst)
		self:intogamefn(inst)
		self:onreroll(inst)
		self:oneatfn(inst)
	end)

	inst:DoTaskInTime(1, function()
		self:speedlevelfn(inst)
		self:damagelevelfn(inst)
		self:absorblevelfn(inst)
		self:petspeedlevelfn(inst)
		self:petdamagelevelfn(inst)
	end)
	inst.components.combat.damagemultiplier = inst.components.combat.damagemultiplier or 1
	inst:DoPeriodicTask(.5, function() self:onupdate(inst) end)
end

function levelsystem:resetbasestat()
	self.achievementhungerup = 0
	self.levelhungerup = 0
	self.achievementsanityup = 0
	self.levelsanityup = 0
	self.achievementhealthup = 0
	self.levelhealthup = 0
end

function levelsystem:loadHunger(inst, percentage)
	local achievement_hunger = allachiv_coindata["hungerup"] * inst.currenthungerup:value()
	if achievement_hunger ~= self.achievementhungerup then
		local amount = inst.components.hunger.max + (achievement_hunger - self.achievementhungerup)
		chasni_setMaxHunger(inst.components.hunger, amount)
		self.achievementhungerup = achievement_hunger
	end
	if self.hungerlevelamount ~= self.levelhungerup then
		local amount = inst.components.hunger.max + (self.hungerlevelamount - self.levelhungerup) * hungerGain
		chasni_setMaxHunger(inst.components.hunger, amount)
		self.levelhungerup = self.hungerlevelamount
	end
	self.hungerlevelmax = inst.components.hunger.max

	if percentage then
		inst:DoTaskInTime(0, function()
			inst.components.hunger:SetPercent(percentage)
		end)
	end
end

function levelsystem:loadSanity(inst, percentage)
	local achievement_sanity = allachiv_coindata["sanityup"] * inst.currentsanityup:value()
	if achievement_sanity ~= self.achievementsanityup then
		local amount = inst.components.sanity.max + (achievement_sanity - self.achievementsanityup)
		chasni_setMaxSanity(inst.components.sanity, amount)
		self.achievementsanityup = achievement_sanity
	end
	if self.sanitylevelamount ~= self.levelsanityup then
		local amount = inst.components.sanity.max + (self.sanitylevelamount - self.levelsanityup) * sanityGain
		chasni_setMaxSanity(inst.components.sanity, amount)
		self.levelsanityup = self.sanitylevelamount
	end
	self.sanitylevelmax = inst.components.sanity.max

	if percentage then
		inst:DoTaskInTime(0, function()
			inst.components.sanity:SetPercent(percentage)
		end)
	end
end

function levelsystem:loadHealth(inst, percentage)
	local health = inst.components.health
	-- Thần Khí stores the native maximum separately and adds permanent elixir
	-- health in SetMaxHealth. Pass that native maximum to avoid adding it twice.
	local function healthBase()
		if health._tbc_elixir_capture ~= nil then
			health:_tbc_elixir_capture()
		end
		return health._tbc_elixir_resource == "health"
			and health._tbc_elixir_base or health.maxhealth
	end
	local achievement_health = allachiv_coindata["healthup"] * inst.currenthealthup:value()
	if achievement_health ~= self.achievementhealthup then
		local amount = healthBase() + (achievement_health - self.achievementhealthup)
		chasni_setMaxHealth(health, amount)
		self.achievementhealthup = achievement_health
	end
	if self.healthlevelamount ~= self.levelhealthup then
		local amount = healthBase() + (self.healthlevelamount - self.levelhealthup) * healthGain
		chasni_setMaxHealth(health, amount)
		self.levelhealthup = self.healthlevelamount
	end
	self.healthlevelmax = health.maxhealth

	if percentage then
		inst:DoTaskInTime(0, function()
			inst.components.health:SetPercent(percentage, false, "file_load")
			inst.components.health:ForceUpdateHUD(true)
		end)
	end
end

function levelsystem:onupdate(inst)
	--hunger
	self:loadHunger(inst)

	--sanity
	self:loadSanity(inst)

	--health
	self:loadHealth(inst)

	--Speed
	local speed = inst.components.locomotor and inst.components.locomotor:GetSpeedMultiplier() or 1
	self.speedlevelmax = 100 * speed

	--Defense
	local itemabsorb = 0
	local inventory = inst.components.inventory
	if inventory then
		for _, v in pairs(inventory.equipslots) do
			if v.components.armor then
				itemabsorb = math.max(itemabsorb, v.components.armor.absorb_percent)
			end
		end
	end
	local damage_taken_multiplier = inst.components.combat and inst.components.combat.externaldamagetakenmultipliers and inst.components.combat.externaldamagetakenmultipliers:Get() or 1
	local absorb = inst.components.health and inst.components.health.externalabsorbmodifiers and inst.components.health.externalabsorbmodifiers:Get() or 0
	itemabsorb = math.max(0, math.min(1, itemabsorb))
	absorb = math.max(0, math.min(1, absorb))
	damage_taken_multiplier = math.max(0, damage_taken_multiplier)
	local effectiveDamage = (1 - itemabsorb) * (1 - absorb) * damage_taken_multiplier
	local damageReduction = 1 - effectiveDamage
	self.absorblevelmax = math.max(0, damageReduction * 100)

	--Damage
	local damagemultiplier = inst.components.combat and inst.components.combat.damagemultiplier or 1
	local externaldamagemultipliers = inst.components.combat and inst.components.combat.externaldamagemultipliers and inst.components.combat.externaldamagemultipliers:Get() or 1
	self.damagelevelmax = 100 * damagemultiplier * externaldamagemultipliers

	---- PET
	local pet = inst.components.petleash and inst.components.petleash:GetChasniCritter()
	if pet then
		self.petspeedlevelmax = pet.components.locomotor and pet.components.locomotor:GetWalkSpeed() or 0
		self.petdamagelevelmax = (pet.components.planardamage and pet.components.planardamage:GetBaseDamage()) or (pet.components.combat and pet.components.combat.defaultdamage) or 0
		self.petattackspeedlevelmax = pet.calculateAttackCD and pet:calculateAttackCD() or 0
		self.petcooldownlevelmax = pet.calculateSpellCD and pet:calculateSpellCD() or 0
		self.petspelllevelmax = pet.calculateSpellValue and pet:calculateSpellValue() or 0
		self.petpassivelevelmax = pet.calculatePassiveValue and pet:calculatePassiveValue() or 0
		self.petcanevolve = pet.canEvolve and pet:canEvolve() or false
	end
end

function levelsystem:onkilledother(inst)
	if _G.KILLXP == true then
		inst:ListenForEvent("killed", function(killer, data)
			if _G.KILLXP ~= true then return end
			local victim = data.victim
			if victim and victim.components.health and killer:HasTag("player") then
				chasni_checkkilllevel(victim)
			end
		end)
	end
end

function levelsystem:oneatfn(inst)
	if _G.FOODXP == true then
		inst:DoTaskInTime(1, function()
			if inst.components.eater == nil then return end
			local oldeatfn = inst.components.eater.oneatfn
			inst.components.eater:SetOnEatFn(function (inst_, food, ...)
				local hunger = food.components.edible.hungervalue
				if hunger > 0 then
					local xpmult = 1
					if inst_.prefab == "warly" then
						xpmult = 5
					end
					-- CC : add "chesspiece_hornucopia_stone" increase xp on eating >> [Perk] groundedscream || Carved Hornucopia
					if chasni_checkifgroundedexists("chesspiece_hornucopia_stone") then
						xpmult = xpmult * 2
					end
					self:xpDoDelta(xpmult*math.floor((hunger/3)+0.5), inst_)
				end
				if oldeatfn then
					oldeatfn(inst_, food, ...)
				end
			end)
		end)
	end
end

function levelsystem:workinglistener(inst)
	if _G.WORKXP == true then
		inst:ListenForEvent("finishedwork",	function()
			if _G.WORKXP ~= true then return end
			local xpmult = 10
			if inst.prefab == "woodie" or inst.prefab == "waxwell" then
				xpmult = 20
			end
			self:xpDoDelta(xpmult, inst, false, true)
		end)
	end
	if _G.FISHXP == true then
		inst:ListenForEvent("fishingcatch", function()
			if _G.FISHXP ~= true then return end
			local xpmult = 17
			if inst.prefab == "wurt" then
				xpmult = 34
			end
			self:xpDoDelta(xpmult, inst, false, true)
		end)
	end
	if _G.FISHXP == true then
		inst:ListenForEvent("fishcaught",	function()
			if _G.FISHXP ~= true then return end
			local xpmult = 75
			if inst.prefab == "wurt" then
				xpmult = 150
			end
			self:xpDoDelta(xpmult, inst, false, true)
		end)
	end
	if _G.BUILDXP == true then
		inst:ListenForEvent("builditem", function(_, data)
			if data and data.recipe and data.recipe.ingredients and #data.recipe.ingredients < 1 then
				return
			end
			if _G.BUILDXP ~= true then return end
			local xpmult = 4
			if inst.prefab == "winona" then
				xpmult = 10
			end
			self:xpDoDelta(xpmult, inst, false, true)
		end)
	end
	if _G.BUILDXP == true then
		inst:ListenForEvent("buildstructure", function(_, data)
			if data and data.recipe and data.recipe.ingredients and #data.recipe.ingredients < 1 then
				return
			end
			if _G.BUILDXP ~= true then return end
			local xpmult = 14
			if inst.prefab == "winona" then
				xpmult = 35
			end
			self:xpDoDelta(xpmult, inst, false, true)
		end)
	end
	if _G.PICKXP == true then
		inst:ListenForEvent("picksomething", function()
			if _G.PICKXP ~= true then return end
			local xpmult = 1
			self:xpDoDelta(xpmult, inst, false, true)
		end)
	end
end

return levelsystem
