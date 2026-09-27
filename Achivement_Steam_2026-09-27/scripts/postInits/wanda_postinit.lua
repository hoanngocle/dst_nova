-- CC : watchcase dropping pocketwatch_revive >> [Reward] expertwanda1
if not chasni_getperkexcludeconfig("expertwanda1") then
    AddPrefabPostInit("pocketwatch_revive",function(inst)
        inst:AddTag("drop_formbag_bydeath")
    end)
    AddStategraphPostInit("wilson", function(sg)
        if sg.states['death'] then
            local old_onenter = sg.states['death'].onenter
            sg.states['death'].onenter = function(inst,...)
                if inst.components.inventory then
                    inst.components.inventory:DropEverythingWithTag("drop_formbag_bydeath")
                end
                if old_onenter then
                    old_onenter(inst,...)
                end
            end
        end
    end)
end

-- CC : better watch >> [Reward] expertwanda2
if not chasni_getperkexcludeconfig("expertwanda2") then
    if TheNet:GetIsServer() then
        AddPrefabPostInit("pocketwatch_revive", function(inst)
            local old_OnHaunt = inst.components.hauntable.onhaunt
            local new_OnHaunt = function(_inst, haunter, ...)
                if haunter.components.allachivcoin and haunter.components.allachivcoin.expertwanda2 then
                    _inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
                    _inst.components.pocketwatch:CastSpell(haunter, haunter)
                else
                    if old_OnHaunt then
                        old_OnHaunt(_inst, haunter, ...)
                    end
                end
            end
            inst.components.hauntable:SetOnHauntFn(new_OnHaunt)
        end)
        AddPrefabPostInit("pocketwatch_portal", function(inst)
            if inst.components.pocketwatch then
                local function noentcheckfn(pt)
                    return not TheWorld.Map:IsPointNearHole(pt) and #TheSim:FindEntities(pt.x, pt.y, pt.z, 1, nil, { "FX", "INLIMBO" }) == 0
                end
                local function DelayedMarkTalker(player)
                    if player.sg == nil or player.sg:HasStateTag("idle") then
                        player.components.talker:Say(GetString(player, "ANNOUNCE_POCKETWATCH_MARK"))
                    end
                end
                local old_DoCastSpell = inst.components.pocketwatch.DoCastSpell
                local _DoCastSpell = function(_inst, doer, target, pos, ...)
                    if doer.components.allachivcoin and doer.components.allachivcoin.expertwanda2 then
                        local recallmark = _inst.components.recallmark
                        if recallmark:IsMarked() then
                            local pt = doer:GetPosition()
                            local offset = FindWalkableOffset(pt, math.random() * 2 * PI, 3 + math.random(), 16, false, true, noentcheckfn, true, true)
                                    or FindWalkableOffset(pt, math.random() * 2 * PI, 5 + math.random(), 16, false, true, noentcheckfn, true, true)
                                    or FindWalkableOffset(pt, math.random() * 2 * PI, 7 + math.random(), 16, false, true, noentcheckfn, true, true)
                            if offset then
                                pt = pt + offset
                            end

                            if not Shard_IsWorldAvailable(recallmark.recall_worldid) then
                                return false, "SHARD_UNAVAILABLE"
                            end

                            local portal = SpawnPrefab("pocketwatch_portal_entrance")
                            portal.Transform:SetPosition(pt:Get())
                            portal:SpawnExit(recallmark.recall_worldid, recallmark.recall_x, recallmark.recall_y, recallmark.recall_z)
                            _inst.SoundEmitter:PlaySound("wanda1/wanda/portal_entrance_pre")
                            _inst.components.rechargeable:Discharge(TUNING.POCKETWATCH_RECALL_COOLDOWN / 4)

                            return true
                        else
                            local x, y, z = doer.Transform:GetWorldPosition()
                            recallmark:MarkPosition(x, y, z)
                            _inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/MarkPosition")

                            doer:DoTaskInTime(12 * FRAMES, DelayedMarkTalker)
                            return true
                        end
                    else
                        if old_DoCastSpell then
                            old_DoCastSpell(_inst, doer, target, pos, ...)
                        end
                    end
                end
                inst.components.pocketwatch.DoCastSpell = _DoCastSpell
            end
        end)
    end
end
