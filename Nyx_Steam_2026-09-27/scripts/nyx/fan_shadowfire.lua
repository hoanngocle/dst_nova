local CLOSERANGE = 1
local SkillDamage=require('util/nyx_skill_damage')

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
					local damage = Xd_CalcDamage(source,110,target)
					damage = SkillDamage.Scale(source,'triflame_fan',damage)
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
return function(owner,x,z,rotation)
    local fire=SpawnPrefab('willow_shadow_flame')
    if fire then
        fire.Transform:SetRotation(rotation)
        fire.Transform:SetPosition(x,0,z)
        settarget(fire,nil,50,owner)
    end
    return fire
end
