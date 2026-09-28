-- this variable naming to ensure compability with other mod
function chasni_getInstForPlayerName(playerName)
	for _, inst in ipairs(AllPlayers) do
        if inst:GetDisplayName() == playerName then
			return inst
		end
	end
	return nil
end

chasni_TAG_NOTARGET = {"FX", "NOCLICK", "DECOR", "INLIMBO"}
chasni_TAG_NOATTACK = {"FX", "NOCLICK", "DECOR", "INLIMBO", "notarget", "noattack", "invisible"}

-- PREFAB FUNCTION
function chasni_findprefab(list, prefab)
	for _,value in pairs(list) do
		if value == prefab then
			return true
		end
	end
end

function chasni_getspawnpoint(pt, dist)
	local theta = math.random() * 2 * PI
	local radius = dist
	local offset = FindWalkableOffset(pt, theta, radius, 12, true)
	return offset and (pt + offset) or nil
end

function chasni_getspawnpointwater(pt, dist)
	local theta = math.random() * 2 * PI
	local radius = dist
	local offset = FindSwimmableOffset(pt, theta, radius, 12, true)
	return offset and (pt + offset) or nil
end

function chasni_getPos(position, target)
	if target then return target.Transform:GetWorldPosition()
	else return position:Get() end
end

function chasni_getMiddlePos(inst1, inst2)
	local x1,y1,z1 = inst1.Transform:GetWorldPosition()
	local x2,y2,z2 = inst2.Transform:GetWorldPosition()

	local xdiff = (x2 - x1)/2
	local ydiff = (y2 - y1)/2
	local zdiff = (z2 - z1)/2

	local x = x1 + xdiff
	local y = y1 + ydiff
	local z = z1 + zdiff

	return Vector3(x, y, z)
end

function chasni_spawnprefab(prefab, x, y, z, sx, sy, sz, parententity, time, alignsource, aligntarget)
	local p = SpawnPrefab(prefab)
	if p then
		if parententity then p.entity:SetParent(parententity) end
		if x and y and z then p.Transform:SetPosition(x, y, z) end
		if sx and sy and sz then p.Transform:SetScale(sx, sy, sz) end
		if time then
			p:DoTaskInTime(time, function()
				p:Remove()
			end)
		end

		if alignsource and aligntarget then
			local x1, y1, z1 = alignsource.Transform:GetWorldPosition()
			local x2, y2, z2 = aligntarget.Transform:GetWorldPosition()
			local dx, dz = x1 - x2, z1 - z2
			local len = math.sqrt(dx * dx + dz * dz)
			local r = len ~= 0 and (aligntarget:GetPhysicsRadius(0) + .2) / len or 0
			p.Transform:SetPosition(x2 + dx * r, y2 + 1, z2 + dz * r)
		end
	end
	return p
end

function chasni_spawnFX(prefab, target, source, opts)
	local opts = opts or {}
	local fx = SpawnPrefab(prefab)
	local source = source or target
	if source and source.components.scaler then
		if not fx.components.scaler then
			fx:AddComponent("scaler")
		end
		fx.components.scaler:SetBaseScale(opts.scale)
		fx.components.scaler:SetSource(source)
	end
	if opts.position then
		fx.Transform:SetPosition(opts.position:Get())
	end
	if opts.OnSpawn then
		opts.OnSpawn(fx)
	end
	if fx.OnSpawn then
		fx:OnSpawn({target = target, source = source or target})
	end
	return fx
end

function chasni_entWorkableIsCollapsible(ent)
	local COLLAPSIBLE_WORK_ACTIONS =
	{
		CHOP = true,
		DIG = true,
		HAMMER = true,
		MINE = true,
	}
	local work_action = ent.components.workable and ent.components.workable:GetWorkAction()
	return ent.components.workable and ((work_action == nil and v:HasTag("NPC_workable")) or (ent.components.workable:CanBeWorked() and work_action and COLLAPSIBLE_WORK_ACTIONS[work_action.id]))
end

function chasni_giveItem(inst, item, stack)
	local loot = nil
	local maxstack = 1

	local prefab = Prefabs[item] and Prefabs[item].fn and Prefabs[item].fn()
	if prefab and prefab.components.stackable then
		maxstack = prefab.components.stackable.maxsize
		prefab:Remove() -- Remove the temporary instance
	end

	while stack > 0 do
		local give = math.min(stack, maxstack)
		loot = SpawnPrefab(item)
		if loot then
			if loot.components.stackable then
				loot.components.stackable:SetStackSize(give)
			end
			if inst and inst.components.inventory then
				inst.components.inventory:GiveItem(loot, nil, inst:GetPosition())
			else
				LaunchAt(loot, inst, nil, 1, 1)
			end
		end
		stack = stack - give
	end

	return loot
end

function chasni_isValidVictim(victim)
	return victim and
			victim.components.health and
			victim.components.combat and
			not (victim:HasTag("veggie") or
					victim:HasTag("structure") or
					victim:HasTag("wall") or
					victim:HasTag("balloon") or
					victim:HasTag("groundspike") or
					victim:HasTag("smashable") or
					victim:HasTag("companion"))
end

function chasni_isLifeDrainable(victim)
	return not victim:HasAnyTag(NON_LIFEFORM_TARGET_TAGS) or victim:HasTag("lifedrainable")
end

function chasni_isShielded(inst)
	return inst:HasDebuff("book_shieldbuff")
			or inst:HasDebuff("chasni_mooncakebuff")
			or inst:HasDebuff("flame_guard_buff")
			or inst:HasDebuff("wormwood_poop_shield_buff")
			or inst:HasDebuff("hulkhat_shield_buff")
			or inst:HasDebuff("chasni_critter_crab_shield_buff")
end

function chasni_ispetname(pet, name)
	return pet and (pet.prefab == "chasni_critter_" .. name .. "_a" or pet.prefab == "chasni_critter_" .. name .. "_b" or pet.prefab == "chasni_critter_" .. name)
end

function chasni_setMaxHealth(health, maxhealth)
	local health_percent = health:GetPercent()
	health:SetMaxHealth(maxhealth)
	health:SetPercent(health_percent)
end

function chasni_setMaxHunger(hunger, maxhunger)
	local hunger_percent = hunger:GetPercent()
	hunger:SetMax(maxhunger)
	hunger:SetPercent(hunger_percent)
end

function chasni_setMaxSanity(sanity, maxsanity)
	local sanity_percent = sanity:GetPercent()
	sanity:SetMax(maxsanity)
	sanity:SetPercent(sanity_percent)
end

function chasni_getnearestplayers(inst)
	local nearest = nil
	local nearestDistSq = nil

	for _, player in ipairs(AllPlayers) do
		if player ~= inst and player:IsValid() then
			local distsq = inst:GetDistanceSqToInst(player)
			if nearestDistSq == nil or distsq < nearestDistSq then
				nearest = player
				nearestDistSq = distsq
			end
		end
	end
	if nearest == nil then
		return nil
	end
	return nearest, math.sqrt(nearestDistSq)
end

-- GENERIC FUNCTION
function chasni_findindex(list, prefab)
	for index,value in pairs(list) do
		if value == prefab then
			return index
		end
	end
end

function chasni_copylist(list)
	local tmp = {}
	for index,value in pairs(list) do
		table.insert(tmp,list[index])
	end
	return tmp
end

function chasni_transformcombatdamage(list, multiplier, addition)
	if multiplier == 0 then
		return nil
	end
	if list then
		for k, v in pairs(list) do
			if multiplier == 0 then
				list[k] = 0
			else
				list[k] = (v * multiplier) + addition
			end
			if list[k] <= 0 then
				list[k] = nil
			end
		end
		if next(list) == nil then
			return nil
		end
	end
	return list
end

function chasni_mergetables(t1, t2)
	local result = {}

	if t1 then
		for _, v in ipairs(t1) do
			table.insert(result, v)
		end
	end

	if t2 then
		for _, v in ipairs(t2) do
			table.insert(result, v)
		end
	end

	return result
end

-- MOBS FUNCTION
function chasni_basicretarget(inst, range, must, cant, fn)
	return FindEntity(
			inst,
			range,
			function(guy)
				return inst.components.combat:CanTarget(guy) and (fn == nil or fn(guy))
			end,
			must,
			cant
	) or nil
end

function chasni_ownpet(v, owner)
	local realowner = owner.components.follower and owner.components.follower:GetLeader() or owner
	local leader = v.components.follower and v.components.follower.leader
	if leader and leader.components.inventoryitem then
		leader = leader.components.inventoryitem:GetGrandOwner()
	end
	return realowner and leader and leader == realowner
end

function chasni_friendpet(v, tag)
	local leader = v.components.follower and v.components.follower.leader
	if leader and leader.components.inventoryitem then
		leader = leader.components.inventoryitem:GetGrandOwner()
	end
	return leader and leader:HasTag(tag or "player")
end

function chasni_followerretarget(inst, range, must, cant)
	return FindEntity(
			inst,
			range,
			function(guy) 
				return inst.components.combat:CanTarget(guy) and not (inst.components.follower and inst.components.follower.leader == guy) 
			end,
			must,
			cant
	) or nil
end

function chasni_basickeeptarget(inst, target, range)
	return target
			and (range == nil or inst:IsNear(target, range))
			and inst.components.combat:CanTarget(target)
			and not target.components.health:IsDead()
end

function chasni_followerkeeptarget(inst, target)
	return target
			and target.components.combat
			and target.components.health
			and not target.components.health:IsDead()
			and not (inst.components.follower and (inst.components.follower.leader == target or inst.components.follower:IsLeaderSame(target)))
end

function chasni_basicsharetarget(inst, data, range, tag, max, tag2)
	inst.components.combat:SetTarget(data.attacker)
	inst.components.combat:ShareTarget(
			data.attacker,
			range,
			function(dude)
				return not (dude.components.health and dude.components.health:IsDead())
						and (dude:HasTag(tag) or (tag2 and dude:HasTag(tag2)))
						and data.attacker ~= (dude.components.follower and dude.components.follower.leader or nil)
			end,
			max
	)
end

function chasni_solosharetarget(inst, data)
	inst.components.combat:SetTarget(data.attacker)
end

function chasni_amphibiousEnterWaterfn(inst, sound, splashfx, swimspeed, hopdistance)
	if inst.DynamicShadow then
		inst.DynamicShadow:Enable(false)
	end

	if inst.SoundEmitter and sound then
		inst.SoundEmitter:PlaySound(sound)
	end

	if splashfx then
		local ent_pos = Vector3(inst.Transform:GetWorldPosition())
		local splash = SpawnPrefab(splashfx)
		splash.Transform:SetPosition(ent_pos.x, ent_pos.y, ent_pos.z)
	end

	if swimspeed then
		inst.landspeed = inst.components.locomotor.runspeed
		inst.components.locomotor.runspeed = swimspeed
	end
	if hopdistance then
		inst.hop_distance = inst.components.locomotor.hop_distance
		inst.components.locomotor.hop_distance = hopdistance
	end
end

function chasni_amphibiousExitWaterfn(inst, sound, splashfx)
	if inst.DynamicShadow then
		inst.DynamicShadow:Enable(true)
	end

	if inst.SoundEmitter and sound then
		inst.SoundEmitter:PlaySound(sound)
	end

	if splashfx then
		local ent_pos = Vector3(inst.Transform:GetWorldPosition())
		local splash = SpawnPrefab(splashfx)
		splash.Transform:SetPosition(ent_pos.x, ent_pos.y, ent_pos.z)
	end

	if inst.landspeed then
		inst.components.locomotor.runspeed = inst.landspeed
	end
	if inst.hop_distance then
		inst.components.locomotor.hop_distance = inst.hop_distance
	end
end
-- ITEM FUNCTION
function chasni_hatswapequip(owner)
	owner.AnimState:ClearOverrideSymbol("headbase_hat")
	owner.AnimState:Show("HAT")
	owner.AnimState:Show("HAIR_HAT")
	owner.AnimState:Hide("HAIR")
	owner.AnimState:Hide("HAIR_NOHAT")
	if owner:HasTag("player") then
		owner.AnimState:Hide("HEAD")
		owner.AnimState:Show("HEAD_HAT")
		owner.AnimState:Show("HEAD_HAT_NOHELM")
		owner.AnimState:Hide("HEAD_HAT_HELM")
	end
end

function chasni_hatswapunequip(owner)
	owner.AnimState:ClearOverrideSymbol("swap_hat")
	owner.AnimState:Hide("HAT")
	owner.AnimState:Hide("HAIR_HAT")
	owner.AnimState:Show("HAIR")
	owner.AnimState:Show("HAIR_NOHAT")
	if owner:HasTag("player") then
		owner.AnimState:Show("HEAD")
		owner.AnimState:Hide("HEAD_HAT")
		owner.AnimState:Hide("HEAD_HAT_NOHELM")
		owner.AnimState:Hide("HEAD_HAT_HELM")
	end
end

function chasni_hastag(inst, owner)
	local tag = inst._restrictedtag
	return tag and (owner:HasTag(tag) or owner:HasDebuff("chasni_mopanebuff")) or false
end

function chasni_hastag2(owner, tag)
	return tag and (owner:HasTag(tag) or owner:HasDebuff("chasni_mopanebuff")) or false
end

function chasni_unquiprestrictedtag(inst, owner)
	inst:DoTaskInTime(0.5, function()
		local tag = inst._restrictedtag
		if tag and not (owner:HasTag(tag) or owner:HasDebuff("chasni_mopanebuff")) and inst.components.equippable and owner.components.inventory then
			local item = owner.components.inventory:Unequip(inst.components.equippable.equipslot)
			if item then
				owner.components.inventory:GiveItem(item)
				if owner.components.talker then
					owner.components.talker:Say(GetString(owner, "NOT_BLESSED"))
				end
			end
		end
	end)
end

function chasni_unquiprestrictedtag2(owner)
	if owner.components.inventory then
		for k, v in pairs(owner.components.inventory.equipslots) do
			chasni_unquiprestrictedtag(v, owner)
		end
	end
end

function chasni_equipanimatedswaphand(inst, owner)
	if inst._fxowner and inst._fxowner.components.colouradder then
		inst._fxowner.components.colouradder:DetachChild(inst._fxswap)
	end
	inst._fxowner = owner
	if owner then
		inst._fxswap.entity:SetParent(owner.entity)
		inst._fxswap.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 0, 3)
		inst._fxswap.components.highlightchild:SetOwner(owner)
		if owner.components.colouradder then
			owner.components.colouradder:AttachChild(inst._fxswap)
		end
	else
		inst._fxswap.entity:SetParent(inst.entity)
		inst._fxswap.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 0, 3)
		inst._fxswap.components.highlightchild:SetOwner(inst)
	end
end

function chasni_isMagicItem(prefab)
	return prefab and (string.sub(prefab, -6) == "amulet" or
			string.sub(prefab, -5) == "staff" or
			string.sub(prefab, 1, 6) == "amulet" or
			string.sub(prefab, 1, 5) == "staff" or 
			chasni_findprefab(magicitems, prefab))
end

-- COMBAT FUNCTION
function chasni_isincone(target, source)
	if target == source or source.components.combat:IsAlly(target) then
		return false
	end
	local ax, _, az = source.Transform:GetWorldPosition()
	local tx, _, tz = target.Transform:GetWorldPosition()
	local dx = tx - ax
	local dz = tz - az

	local dist_sq = dx * dx + dz * dz
	local len = math.sqrt(dist_sq)

	dx = dx / len
	dz = dz / len

	local rot = source.Transform:GetRotation() * DEGREES
	local fx = math.cos(rot)
	local fz = -math.sin(rot)
	local dot = dx * fx + dz * fz
	local angle = 90
	local half_angle = angle * 0.5 * DEGREES

	return dot >= math.cos(half_angle)
end

function chasni_findentities(x, y, z, rad, musttag, canttag, isfriendlyto)
	local ents = TheSim:FindEntities(x, y, z, rad, musttag, canttag)
	for i = #ents, 1, -1 do
		local v = ents[i]
		if not v:IsValid() then
			table.remove(ents, i)
		elseif isfriendlyto and isfriendlyto.components.combat:IsAlly(v) then
			table.remove(ents, i)
		elseif isfriendlyto and ((TheNet:GetPVPEnabled() and chasni_ownpet(v, isfriendlyto)) or (not TheNet:GetPVPEnabled() and chasni_friendpet(v))) then
			table.remove(ents, i)
		end
	end
	return ents
end


function chasni_doaoedamage(x, y, z, rad, musttag, canttag, attacker, damage, weapon, isfriendly, fx, spdamage)
	local BASE_CANT_TAGS = {"FX", "NOCLICK", "INLIMBO", "DECOR"}
	canttag = canttag or {}
	local final_cant = chasni_mergetables(canttag, BASE_CANT_TAGS)

	local ents = chasni_findentities(x, y, z, rad, musttag, final_cant, isfriendly and attacker)
	for _, v in ipairs(ents) do
		if v ~= attacker then
			if isfriendly and ((TheNet:GetPVPEnabled() and chasni_ownpet(v, attacker)) or (not TheNet:GetPVPEnabled() and chasni_friendpet(v))) then
				-- skip friendly target
			else
				if v.components.health then
					if v.components.combat then
						v.components.combat:GetAttacked(attacker, damage, weapon, nil, spdamage)
						if fx then
							if type(fx) == "string" then
								chasni_spawnprefab(fx, 0,0,0, 1,1,1, v.entity)
							elseif type(fx) == "table" then
								for _, fxname in ipairs(fx) do
									if fxname then
										chasni_spawnprefab(fxname, 0,0,0, 1,1,1, v.entity)
									end
								end
							end
						end
					else
						v.components.health:DoDelta(-damage, nil, weapon, nil, attacker)
						if fx then
							if type(fx) == "string" then
								chasni_spawnprefab(fx, 0,0,0, 1,1,1, v.entity)
							elseif type(fx) == "table" then
								for _, fxname in ipairs(fx) do
									if fxname then
										chasni_spawnprefab(fxname, 0,0,0, 1,1,1, v.entity)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function chasni_doaoeheal(x, y, z, rad, musttag, canttag, healer, heal, isall, fx)
	local BASE_CANT_TAGS = {"FX", "NOCLICK", "INLIMBO", "DECOR"}
	local HEAL_CANT_TAGS = {"playerghost"}

	canttag = canttag or {}
	local final_cant = chasni_mergetables(canttag, BASE_CANT_TAGS)
	final_cant = chasni_mergetables(final_cant, HEAL_CANT_TAGS)

	local ents = TheSim:FindEntities(x, y, z, rad, musttag, final_cant)
	for _, v in ipairs(ents) do
		if v and v.components.health and not v.components.health:IsDead() then
			if isall or v:HasTag("player") or chasni_friendpet(v) or chasni_ownpet(v, healer) then
				v.components.health:DoDelta(heal)
				if fx then
					chasni_spawnprefab(fx, 0, 0, 0, 1, 1, 1, v.entity)
				end
			end
		end
	end
end

function chasni_addtimedbuff(target, debuff, duration, endfn)
	target:AddDebuff(debuff, debuff)
	local taskname = "_chasni_debuff_" .. debuff .. "_task"
	local endtimename = "_chasni_debuff_" .. debuff .. "_endtime"

	local newendtime = GetTime() + duration
	local currentendtime = target[endtimename] or 0
	if newendtime <= currentendtime then
		return
	end

	target[endtimename] = newendtime
	if target[taskname] then
		target[taskname]:Cancel()
		target[taskname] = nil
	end

	target[taskname] = target:DoTaskInTime(duration, function(_target)
		if _target.components.debuffable then
			_target:RemoveDebuff(debuff)
		end
		if endfn then
			endfn(target)
		end
		_target[taskname] = nil
		_target[endtimename] = nil
	end)
end

-- RETICULE FUNCTION
function chasni_single_reticule_mouse_target_function(inst, mousepos)
	if mousepos == nil then
		return nil
	end
	local inventoryitem = inst.replica.inventoryitem
	local owner = inventoryitem:IsHeldBy(ThePlayer) and ThePlayer
	if owner then
		local pos = Vector3(owner.Transform:GetWorldPosition())
		return pos
	end
end

function chasni_single_reticule_target_function(inst)
	if ThePlayer and ThePlayer.components.playercontroller and ThePlayer.components.playercontroller.isclientcontrollerattached then
		local inventoryitem = inst.replica.inventoryitem
		local owner = inventoryitem and inventoryitem:IsGrandOwner(ThePlayer) and ThePlayer
		if owner then
			local pos = Vector3(owner.Transform:GetWorldPosition())
			return pos
		end
	end
end

function chasni_single_reticule_update_position_function(inst, pos, reticule, ease, smoothing, dt)

	local inventoryitem = inst.replica.inventoryitem
	local owner = inventoryitem and inventoryitem:IsGrandOwner(ThePlayer) and ThePlayer

	if owner then
		reticule.Transform:SetPosition(Vector3(owner.Transform:GetWorldPosition()):Get())
		reticule.Transform:SetRotation(0)
	end
end

function chasni_StartAOETargeting(inst)
	local playercontroller = ThePlayer.components.playercontroller
	if playercontroller then
		playercontroller:StartAOETargetingUsing(inst)
	end
end

function chasni_StartInstantCasting(inst)
	if ThePlayer.replica.inventory then
		ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
	end
end

-- SPECIFIC FUNCTION
function chasni_getassistplayers(victim)
	if achievementAssistrange > 0 then
		local pos = Vector3(victim.Transform:GetWorldPosition())
		return FindPlayersInRange(pos.x,pos.y,pos.z, achievementAssistrange)
	else
		local players = {}
		for i, v in ipairs(AllPlayers) do
			table.insert(players, v)
		end
		return players
	end
	return {}
end

function chasni_checkifgroundedexists(prefab)
	local player = AllPlayers and AllPlayers[1] or nil
	return player and player.currentgroundedscream and player.currentgroundedscream:value() == 1 and ((TheWorld.components.groundedregistry and TheWorld.components.groundedregistry:Exist(prefab)) or (ThePlayer and ThePlayer._grounded_cache and ThePlayer._grounded_cache[prefab]))
end

local prefab_to_prefix = {
	deerclops      = "chesspiece_deerclops_",
	bearger        = "chesspiece_bearger_",
	moose          = "chesspiece_moosegoose_",
	dragonfly      = "chesspiece_dragonfly_",
	minotaur       = "chesspiece_minotaur_",
	beequeen       = "chesspiece_beequeen_",
	klaus          = "chesspiece_klaus_",
	antlion        = "chesspiece_antlion_",
	stalker_atrium = "chesspiece_stalker_",
	malbatross     = "chesspiece_malbatross_",
	eyeofterror    = "chesspiece_eyeofterror_",
	daywalker      = "chesspiece_daywalker_",
	daywalker2     = "chesspiece_daywalker2_",
	mutateddeerclops = "chesspiece_deerclops_mutated_",
	mutatedwarg    = "chesspiece_warg_mutated_",
	mutatedbearger = "chesspiece_bearger_mutated_",
	sharkboi       = "chesspiece_sharkboi_",
	worm_boss      = "chesspiece_wormboss_",
	wagboss_robot  = "chesspiece_wagboss_robot_",
	alterguardian_phase4_lunarrift = "chesspiece_wagboss_lunar_",
	vault_pillar_guard = "chesspiece_vault_pillar_guard_",

	toadstool      = "chesspiece_toadstool_",
	toadstool_dark = "chesspiece_toadstool_",
	alterguardian_phase1 = "chesspiece_guardianphase3_",
	alterguardian_phase2 = "chesspiece_guardianphase3_",
	alterguardian_phase3 = "chesspiece_guardianphase3_",
	twinofterror1  = "chesspiece_twinsofterror_",
	twinofterror2  = "chesspiece_twinsofterror_",

	crabking = function(inst)
		return not inst:HasTag("chasni_crabqueen") and "chesspiece_crabking_" or nil
	end,
}
local tag_to_prefix = {
	rook              = "chesspiece_rook_",
	knight            = "chesspiece_knight_",
	bishop            = "chesspiece_bishop_",
	shadowcreature    = "chesspiece_formal_",
	cz_spawnedforhunt = "chesspiece_claywarg_",
	hound             = "chesspiece_clayhound_",
	beefalo           = "chesspiece_beefalo_",
}
function chasni_getGroundedChesspieceKeys(inst, postfix, include_tags)
	local keys = {}
	if inst and inst.prefab then
		local entry = prefab_to_prefix[inst.prefab]
		local prefix = nil
		if type(entry) == "function" then
			prefix = entry(inst)
		else
			prefix = entry
		end
		if prefix then
			table.insert(keys, prefix .. postfix)
		end

		if include_tags then
			for tag, tag_prefix in pairs(tag_to_prefix) do
				if inst:HasTag(tag) then
					table.insert(keys, tag_prefix .. postfix)
				end
			end
		end
	end

	return keys
end

function chasni_checkkilllevel(victim)
	if _G.KILLXP ~= true then return end
	if victim and chasni_isValidVictim(victim) and not victim:HasTag("noxp") then
		local xp = math.ceil(math.sqrt((victim.components.health.maxhealth * 0.1)) + 0.1)
		if boss_bonus_xp[victim.prefab] then
			xp = xp + boss_bonus_xp[victim.prefab]
		end
		if TheWorld.components.groundedregistry then
			local keys = chasni_getGroundedChesspieceKeys(victim, "marble")
			for _, key in ipairs(keys) do
				if TheWorld.components.groundedregistry:Exist(key) then
					xp = xp * 2
					break
				end
			end
		end

		if victim:HasTag("epic") then xp = xp * 2 end
		if victim:HasTag("epicxphp") then xp = xp * 2 end
		if victim:HasTag("epicxpdmg") then xp = xp * 9 end
		if victim:HasTag("chasni_crabqueen") then xp = xp * 100 end
		if victim.bonusxp and victim.bonusxp > 0 then xp = xp * victim.bonusxp end

		local players = chasni_getassistplayers(victim)
		local playercount = #players
		for k,v in pairs(players) do
			if v:HasTag("player") and v.components.levelsystem then
				local xpmult = 1
				if v.prefab == "wathgrithr" then
					xpmult = 2
				end
				v.components.levelsystem:xpDoDelta(xpmult*math.ceil(xp/(playercount * playercount)), v, false, true)
			end
		end
	end
end

function chasni_checkslayachievement(inst, victim)
	local allachivevent = AllPlayers[1] and AllPlayers[1].components.allachivevent
	if allachivevent and victim then -- using AllPlayers[1] because player assist range checked from victim position
		-- SLAY
		--Goat
		if victim.prefab == "lightninggoat" and victim:HasTag("charged") == true then
			allachivevent:SlayAchievement(AllPlayers[1], "lightninggoat", victim)
		end
		--Beefalo
		if victim.prefab == "beefalo" and victim:HasTag("scarytoprey") == true then
			allachivevent:SlayAchievement(AllPlayers[1], "beefalo", victim)
		end
		-- Koalefant
		if victim.prefab == "koalefant_winter" then
			allachivevent:SlayAchievement(AllPlayers[1], "koalefant", victim)
		end
		--saladmander
		if victim.prefab == "fruitdragon" and victim._is_ripe then
			allachivevent:SlayAchievement(AllPlayers[1], "saladmander", victim)
		end
		--horror hound
		if victim.prefab == "mutatedhound" then
			allachivevent:SlayAchievement(AllPlayers[1], "horrorhound", victim)
		end
		--werepig
		if (victim.prefab == "moonpig" or (victim.prefab == "pigman" and victim.components.werebeast:IsInWereState())) then
			allachivevent:SlayAchievement(AllPlayers[1], "werepig", victim)
		end
		--beardlord
		if victim.prefab == "bunnyman" and victim.beardlord then
			allachivevent:SlayAchievement(AllPlayers[1], "beardlord", victim)
		end
		--Snurtle
		if victim.prefab == "snurtle" then
			allachivevent:SlayAchievement(AllPlayers[1], "snurtle", victim)
		end
		--mosling
		if victim.prefab == "mossling" and victim.mother_dead then
			allachivevent:SlayAchievement(AllPlayers[1], "mosling", victim)
		end
		--Crystal-Crested Buzzard
		if victim.prefab == "mutatedbuzzard_gestalt" then
			allachivevent:SlayAchievement(AllPlayers[1], "vulture", victim)
		end
		--Bright-Eyed Frog
		if victim.prefab == "lunarfrog" then
			allachivevent:SlayAchievement(AllPlayers[1], "moonfrog", victim)
		end
		--Mega Blight
		if victim.prefab == "shadowthrall_centipede_controller" and victim.components.centipedebody and victim.components.centipedebody.bodies and #victim.components.centipedebody.bodies > 15 then
			allachivevent:SlayAchievement(AllPlayers[1], "darkcentipede", victim, true)
		end
		--Geothermite
		if victim.prefab == "cave_vent_mite" and victim.components.planarentity ~= nil then
			allachivevent:SlayAchievement(AllPlayers[1], "cavemite", victim)
		end
		-- BOSS
		--Klaus
		if victim.prefab == "klaus" and victim.IsUnchained and victim:IsUnchained() then
			allachivevent:SlayAchievement(AllPlayers[1], "santaklaus", victim, true)
		end
		--Shadow Chess
		if (victim.prefab == "shadow_knight" or victim.prefab == "shadow_rook" or victim.prefab == "shadow_bishop") and victim.level == 3 then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				if v.components.allachivevent.shadowknight ~= true and victim.prefab == "shadow_knight" then
					v.components.allachivevent.shadowknight = true
				end
				if v.components.allachivevent.shadowbishop ~= true and victim.prefab == "shadow_bishop" then
					v.components.allachivevent.shadowbishop = true
				end
				if v.components.allachivevent.shadowrook ~= true and victim.prefab == "shadow_rook" then
					v.components.allachivevent.shadowrook = true
				end
				if v.components.allachivevent.shadowknight and v.components.allachivevent.shadowbishop and v.components.allachivevent.shadowrook and v.components.allachivevent.shadowpieche ~= true then
					v.components.allachivevent:CheckAchievement(v, "shadowpieche")
				end
			end
		end
		--Misery Toadstool
		if victim.prefab == "toadstool_dark" then
			allachivevent:SlayAchievement(AllPlayers[1], "toadstool", victim, true)
		end
		--Celestial Champion
		if victim.prefab == "alterguardian_phase3" then
			allachivevent:SlayAchievement(AllPlayers[1], "celestialchampion", victim, true)
		end
		--Celestial Scion
		if victim.prefab == "alterguardian_phase4_lunarrift" then
			allachivevent:SlayAchievement(AllPlayers[1], "celestialscion", victim, true)
		end
		--Ancient Guard Tower
		if victim.prefab == "vault_pillar_guard" then
			allachivevent:SlayAchievement(AllPlayers[1], "guardtower", victim)
		end
		--Insecticide (Dragonfly, Bee Queen)
		if victim.prefab == "dragonfly" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.dragonflybeequeen1 = true
				if v.components.allachivevent.dragonflybeequeen2 and v.components.allachivevent.dragonflybeequeen1 and v.components.allachivevent.dragonflybeequeen ~= true then
					v.components.allachivevent:CheckAchievement(v, "dragonflybeequeen")
				end
			end
		end
		if victim.prefab == "beequeen" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.dragonflybeequeen2 = true
				if v.components.allachivevent.dragonflybeequeen1 and v.components.allachivevent.dragonflybeequeen2 and v.components.allachivevent.dragonflybeequeen ~= true then
					v.components.allachivevent:CheckAchievement(v, "dragonflybeequeen")
				end
			end
		end
		--Watery Grave (Malbatross, Crab King)
		if victim.prefab == "malbatross" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.malbatrosscrabking1 = true
				if v.components.allachivevent.malbatrosscrabking2 and v.components.allachivevent.malbatrosscrabking1 and v.components.allachivevent.malbatrosscrabking ~= true then
					v.components.allachivevent:CheckAchievement(v, "malbatrosscrabking")
				end
			end
		end
		if victim.prefab == "crabking" and not victim:HasTag("chasni_crabqueen") then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.malbatrosscrabking2 = true
				if v.components.allachivevent.malbatrosscrabking1 and v.components.allachivevent.malbatrosscrabking2 and v.components.allachivevent.malbatrosscrabking ~= true then
					v.components.allachivevent:CheckAchievement(v, "malbatrosscrabking")
				end
			end
		end
		--Ancient Killer (Ancient Guardian, Ancient Fuelweaver)
		if victim.prefab == "minotaur" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.ancientguardianancientfuelweaver1 = true
				if v.components.allachivevent.ancientguardianancientfuelweaver2 and v.components.allachivevent.ancientguardianancientfuelweaver1 and v.components.allachivevent.ancientguardianancientfuelweaver ~= true then
					v.components.allachivevent:CheckAchievement(v, "ancientguardianancientfuelweaver")
				end
			end
		end
		if victim.prefab == "stalker_atrium" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.ancientguardianancientfuelweaver2 = true
				if v.components.allachivevent.ancientguardianancientfuelweaver1 and v.components.allachivevent.ancientguardianancientfuelweaver2 and v.components.allachivevent.ancientguardianancientfuelweaver ~= true then
					v.components.allachivevent:CheckAchievement(v, "ancientguardianancientfuelweaver")
				end
			end
		end
		--Twin Terror
		if victim.prefab == "twinofterror1" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.twinterror1 = true
				if v.components.allachivevent.twinterror2 and v.components.allachivevent.twinterror1 and v.components.allachivevent.twinterror ~= true then
					v.components.allachivevent:CheckAchievement(v, "twinterror")
				end
			end
		end
		if victim.prefab == "twinofterror2" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.twinterror2 = true
				if v.components.allachivevent.twinterror1 and v.components.allachivevent.twinterror2 and v.components.allachivevent.twinterror ~= true then
					v.components.allachivevent:CheckAchievement(v, "twinterror")
				end
			end
		end
		--Season Bosses
		if victim.prefab == "deerclops" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.bosswinter = true
				if v.components.allachivevent.bossautumn and v.components.allachivevent.bosssummer and v.components.allachivevent.bossspring and v.components.allachivevent.bosswinter and v.components.allachivevent.seasonboss ~= true then
					v.components.allachivevent:CheckAchievement(v, "seasonboss")
				end
			end
		end
		if victim.prefab == "moose" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.bossspring = true
				if v.components.allachivevent.bossautumn and v.components.allachivevent.bosssummer and v.components.allachivevent.bossspring and v.components.allachivevent.bosswinter and v.components.allachivevent.seasonboss ~= true then
					v.components.allachivevent:CheckAchievement(v, "seasonboss")
				end
			end
		end
		if victim.prefab == "antlion" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.bosssummer = true
				if v.components.allachivevent.bossautumn and v.components.allachivevent.bosssummer and v.components.allachivevent.bossspring and v.components.allachivevent.bosswinter and v.components.allachivevent.seasonboss ~= true then
					v.components.allachivevent:CheckAchievement(v, "seasonboss")
				end
			end
		end
		if victim.prefab == "bearger" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.bossautumn = true
				if v.components.allachivevent.bossautumn and v.components.allachivevent.bosssummer and v.components.allachivevent.bossspring and v.components.allachivevent.bosswinter and v.components.allachivevent.seasonboss ~= true then
					v.components.allachivevent:CheckAchievement(v, "seasonboss")
				end
			end
		end
		--Mutation Bosses
		if victim.prefab == "mutateddeerclops" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.mutateddeerclops = true
				if v.components.allachivevent.mutatedwarg and v.components.allachivevent.mutatedbearger and v.components.allachivevent.mutateddeerclops and v.components.allachivevent.mutationboss ~= true then
					v.components.allachivevent:CheckAchievement(v, "mutationboss")
				end
			end
		end
		if victim.prefab == "mutatedbearger" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.mutatedbearger = true
				if v.components.allachivevent.mutatedwarg and v.components.allachivevent.mutatedbearger and v.components.allachivevent.mutateddeerclops and v.components.allachivevent.mutationboss ~= true then
					v.components.allachivevent:CheckAchievement(v, "mutationboss")
				end
			end
		end
		if victim.prefab == "mutatedwarg" then
			local players = chasni_getassistplayers(victim)
			for k,v in pairs(players) do
				v.components.allachivevent.mutatedwarg = true
				if v.components.allachivevent.mutatedwarg and v.components.allachivevent.mutatedbearger and v.components.allachivevent.mutateddeerclops and v.components.allachivevent.mutationboss ~= true then
					v.components.allachivevent:CheckAchievement(v, "mutationboss")
				end
			end
		end
	end
end

function chasni_getxpgoals(level)
	local goal = 2 * (50 + math.floor(level * level * 0.1))
	return math.min(9999999, goal)
end

function chasni_getinvokerspellname(ballsi)
	if ballsi then
		if ballsi[1] == 1 then
			if ballsi[2] == 1 then
				if ballsi[3] == 1 then
					return "QQQ"
				elseif ballsi[3] == 2 then
					return "QQW"
				elseif ballsi[3] == 3 then
					return "QQE"
				end
			elseif ballsi[2] == 2 then
				if ballsi[3] == 1 then
					return "QQW"
				elseif ballsi[3] == 2 then
					return "QWW"
				elseif ballsi[3] == 3 then
					return "QWE"
				end
			elseif ballsi[2] == 3 then
				if ballsi[3] == 1 then
					return "QQE"
				elseif ballsi[3] == 2 then
					return "QWE"
				elseif ballsi[3] == 3 then
					return "QEE"
				end
			end
		elseif ballsi[1] == 2 then
			if ballsi[2] == 1 then
				if ballsi[3] == 1 then
					return "QQW"
				elseif ballsi[3] == 2 then
					return "QWW"
				elseif ballsi[3] == 3 then
					return "QWE"
				end
			elseif ballsi[2] == 2 then
				if ballsi[3] == 1 then
					return "QWW"
				elseif ballsi[3] == 2 then
					return "WWW"
				elseif ballsi[3] == 3 then
					return "WWE"
				end
			elseif ballsi[2] == 3 then
				if ballsi[3] == 1 then
					return "QWE"
				elseif ballsi[3] == 2 then
					return "WWE"
				elseif ballsi[3] == 3 then
					return "WEE"
				end
			end
		elseif ballsi[1] == 3 then
			if ballsi[2] == 1 then
				if ballsi[3] == 1 then
					return "QQE"
				elseif ballsi[3] == 2 then
					return "QWE"
				elseif ballsi[3] == 3 then
					return "QEE"
				end
			elseif ballsi[2] == 2 then
				if ballsi[3] == 1 then
					return "QWE"
				elseif ballsi[3] == 2 then
					return "WWE"
				elseif ballsi[3] == 3 then
					return "WEE"
				end
			elseif ballsi[2] == 3 then
				if ballsi[3] == 1 then
					return "QEE"
				elseif ballsi[3] == 2 then
					return "WEE"
				elseif ballsi[3] == 3 then
					return "EEE"
				end
			end
		end
	end
	return "NONE"
end

function chasni_getequippedtrinket(inst)
	local trinketslot = inst and inst.components.trinketowner and inst.components.trinketowner:GetTrinketSlot()
	return trinketslot and trinketslot.components.container and trinketslot.components.container:GetItemInSlot(1)
end

function chasni_gettrinketpoint(trinket, mult, max)
	local stacksize = trinket and trinket.components.stackable and trinket.components.stackable:StackSize() or 1
	-- Doubled trinket count | MoonGlass Bubble Pipe Carving
	if chasni_checkifgroundedexists("chesspiece_pipe_moonglass") then
		stacksize = stacksize * 2
	end
	return math.min((stacksize) * mult, max)
end

function chasni_gettrinketassociation(item1, item2)
	if item1 == nil or item1.prefab == nil then
		return false
	end

	local assoc = cz_trinkets.trinket_association[item1.prefab]
	if assoc == nil then
		return false
	end

	if item2 == nil then
		return assoc
	end

	if item2.prefab == nil then
		return false
	end

	for _, prefab in ipairs(assoc) do
		if prefab == item2.prefab then
			return true
		end
	end

	return false
end

function chasni_getmobconfig(mob, config)
	return
	TUNING.CHASNI_CONFIG and TUNING.CHASNI_CONFIG.MOB and
			TUNING.CHASNI_CONFIG.MOB[string.upper(mob)] and
			TUNING.CHASNI_CONFIG.MOB[string.upper(mob)][config]
			or nil
end

function chasni_getitemconfig(item, config)
	return
	TUNING.CHASNI_CONFIG and TUNING.CHASNI_CONFIG.ITEM and
			TUNING.CHASNI_CONFIG.ITEM[string.upper(item)] and
			TUNING.CHASNI_CONFIG.ITEM[string.upper(item)][config]
			or nil
end

function chasni_getperkexcludeconfig(...)
	for _, perk in ipairs({...}) do
		if not perk:match("^expert") and not (TUNING.CHASNI_CONFIG and TUNING.CHASNI_CONFIG.HIDEPERK and TUNING.CHASNI_CONFIG.HIDEPERK[string.upper(perk)]) then
			return nil
		end
	end

	return true
end

function chasni_getachievementhint(name)
	return
	TUNING.CHASNI_CONFIG and TUNING.CHASNI_CONFIG.ACHIEVEMENT_GUIDE and
			TUNING.CHASNI_CONFIG.ACHIEVEMENT_GUIDE[string.upper(name)]
			or nil
end

function chasni_retalk(inst, stringkey)
	inst:DoTaskInTime(FRAMES, function()
		if inst.components.talker then
			inst.components.talker:ShutUp()
			inst.components.talker:Say(GetString(inst, stringkey))
		end
	end)
end
-- DEBUGGING FUNCTION
function czgt(inst)
	if inst == nil or inst.entity == nil then
		return 0
	end
	local ds = inst.entity:GetDebugString()
	if ds == nil then
		return 0
	end
	local tagsstr = string.match(ds, "Tags: ([^\n]+)\n")
	if tagsstr == nil then
		return 0
	end
	local tags = string.split(tagsstr, " ")
	local tagscount = #tags

	czdb(tagscount, tagsstr)
end
function czdb(s, s2, s3)
	if not _G.LOGING_CONFIG then
		 return
	end

	s2 = s2 or ""
	s3 = s3 or ""
	TheNet:Announce(tostring(s) .. " : " .. tostring(s2) .. " : " .. tostring(s3))
end
function czsn(sound)
	czap().SoundEmitter:PlaySound(sound)
end
function czap() 	return AllPlayers[1] 	end
function ssp(p) 	return c_spawn(p) 		end
function rrs()   	return c_reset() 		end
function ggv(p) 	return c_give(p) 		end
function ggv5(p) 	return c_give(p, 5) 	end
--change pet
function czcc(critter)
	local player = czap()

	local theta = math.random() * TWOPI
	local pt = player:GetPosition()
	local radius = 1
	local offset = FindWalkableOffset(pt, theta, radius, 6, true)
	if offset ~= nil then
		pt.x = pt.x + offset.x
		pt.z = pt.z + offset.z
	end
	player.components.petleash:SpawnPetAt(pt.x, 0, pt.z, critter)
end
--debug pet
function czdd(atkonly, spellonly)
	local pet = czap().components.petleash:GetChasniCritter()
	if pet then
		if not spellonly then
			pet.attack_cd = 0
		end
		if not atkonly then
			pet.spell_cd = 0
		end
	end
end
--add or remove debuff
function czadb(buff)
	local player = czap()
	if player:HasDebuff(buff) then
		player:RemoveDebuff(buff, buff)
	else
		player:AddDebuff(buff, buff)
	end
end
--static leif
function czlf()
	local leif = ssp("leif")
	if leif and leif.components.locomotor then
		leif.components.locomotor:SetExternalSpeedMultiplier(leif, "debug", 0)
	end
end
function czcheckach() return czap().components.allachivevent:checkAll() end

local function CancelAutoRevive(player)
	if player._autorevive_task then
		player._autorevive_task:Cancel()
		player._autorevive_task = nil
	end
end
local function StartAutoRevive(player)
	CancelAutoRevive(player)
	local countdown = 50
	player._autorevive_task = player:DoPeriodicTask(2, function()
		if not player:IsValid() then
			CancelAutoRevive(player)
			return
		end

		if player.components.talker then
			player.components.talker:Say(tostring(countdown))
		end

		countdown = countdown - 1
		if countdown < 0 then
			player:PushEvent("respawnfromghost", { })
			CancelAutoRevive(player)
		end
	end)
end
function ToggleAutoRevive(id)
	local player = AllPlayers[id]
	if player._autorevive then
		player._autorevive = nil
		player:RemoveEventCallback("death", player._autorevive_deathfn)
		CancelAutoRevive(player)
	else
		player._autorevive_deathfn = function() StartAutoRevive(player) end
		player:ListenForEvent("death", player._autorevive_deathfn)

		if player:HasTag("playerghost") then
			StartAutoRevive(player)
		end

		player._autorevive = true
	end
end
