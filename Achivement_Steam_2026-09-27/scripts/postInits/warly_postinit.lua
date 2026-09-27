-- CC : warly new item logic >> [Reward] expertwarly3
if not chasni_getperkexcludeconfig("expertwarly3") then
    -- CC : warly fryingpan >> [Reward] expertwarly3
    local pan_start = State {
        name = "pan_start",
        tags = {"prepan", "panning", "working", "busy"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pan_pre")
        end,
        events =
        {
            GLOBAL.EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            GLOBAL.EventHandler("animover", function(inst) inst.sg:GoToState("pan") end),
        },
    }
    local pan = State {
        name = "pan",
        tags = { "prepan", "panning", "working" },
        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("pan_loop", true)
            inst.sg:SetTimeout(1 + math.random())
        end,
        timeline =
        {
            GLOBAL.TimeEvent(6 * GLOBAL.FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pan/pool") end),
            GLOBAL.TimeEvent(14 * GLOBAL.FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pan/pool") end),
            GLOBAL.TimeEvent((6 + 15) * GLOBAL.FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pan/pool") end),
            GLOBAL.TimeEvent((14 + 15) * GLOBAL.FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pan/pool") end),
            GLOBAL.TimeEvent((6 + 30) * GLOBAL.FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pan/pool") end),
            GLOBAL.TimeEvent((14 + 30) * GLOBAL.FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pan/pool") end),
            GLOBAL.TimeEvent((6 + 45) * GLOBAL.FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pan/pool") end),
            GLOBAL.TimeEvent((14 + 45) * GLOBAL.FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pan/pool") end),
            GLOBAL.TimeEvent((6 + 60) * GLOBAL.FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pan/pool") end),
            GLOBAL.TimeEvent((14 + 60) * GLOBAL.FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pan/pool") end),
        },
        ontimeout = function(inst)
            inst:PerformBufferedAction()
            inst.sg:GoToState("idle", "pan_pst")
        end,
        events =
        {
            GLOBAL.EventHandler("unequip", function(inst) inst.sg:GoToState("idle", "pan_pst") end),
        },
    }
    AddStategraphState("wilson_client", pan_start)
    AddStategraphState("wilson", pan_start)
    AddStategraphState("wilson_client", pan)
    AddStategraphState("wilson", pan)

    -- CC : set action for chasnibox >> [Reward] expertwarly3 || bentobox
    local old_give_fn = ACTIONS.GIVE.fn
    ACTIONS.GIVE.fn = function(act)
        if act.invobject and act.invobject:HasTag("chasnibox") and act.target and act.invobject.components.chasnibox then
            if act.invobject.components.chasnibox:IsBoxable(act.target) then
                return act.invobject.components.chasnibox:DoBox(act.target)
            end
            return false
        end
        return old_give_fn(act)
    end
    local give_stroverridefn = ACTIONS.GIVE.stroverridefn
    ACTIONS.GIVE.stroverridefn = function(act)
        if act.invobject and act.invobject:HasTag("chasnibox") then
            return STRINGS.ACTIONS.CHASNI_BOX
        end
        if give_stroverridefn then
            return give_stroverridefn(act)
        end
    end
    AddComponentAction("USEITEM", "chasnibox", function(inst, doer, target, actions)
        if inst.replica.inventoryitem and inst.replica.inventoryitem:IsGrandOwner(doer) then
            if inst and target then
                table.insert(actions, ACTIONS.GIVE)
            end
        end
    end)
    AddStategraphPostInit("wilson", function(inst)
        local _give_destate = inst.actionhandlers[ACTIONS.GIVE].deststate
        inst.actionhandlers[ACTIONS.GIVE].deststate = function(_inst, action, ...)
            local dest
            if type(_give_destate) == "string" then
                dest = _give_destate
            else
                dest = _give_destate(_inst, action, ...)
            end

            if dest == "give" and action.invobject and action.invobject:HasTag("chasnibox") then
                return "dolongaction"
            end
            return dest
        end
    end)
    -- CC : replace eater Eat function when eating bentobox >> [Reward] expertwarly3 || bentobox
    AddComponentPostInit("eater", function(eater)
        local OldEat = eater.Eat
        eater.Eat = function(self, food, feeder, ...)
            if food and food.prefab == "bentobox" and food.components.chasnibox and food.components.chasnibox.boxedprefab then
                local OldPrefersToEat = eater.PrefersToEat
                eater.PrefersToEat = function(_, ...)
                    return true
                end
                local foodinside = food.components.chasnibox:UnBox(self.inst, false)
                local retval = OldEat(self, foodinside, feeder, ...)
                eater.PrefersToEat = OldPrefersToEat
                return retval
            end
            return OldEat(self, food, feeder, ...)
        end
    end)
end

-- CC : warly new item logic >> [Reward] expertwarly4
if not chasni_getperkexcludeconfig("expertwarly4") then
    -- CC : reduce "armor" durability loss on TakeDamge || chasni_kyivcake >> [Reward] expertwarly4
    AddComponentPostInit("armor", function(Armor)
        local OldTakeDamage = Armor.TakeDamage
        Armor.TakeDamage = function(self, damage_amount, ...)
            local owner = self.inst and self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
            if owner and owner:HasDebuff("chasni_kyivcakebuff") then
                damage_amount = damage_amount * 0.3
            end
            return OldTakeDamage(self, damage_amount, ...)
        end
    end)

    -- CC : add popcorn non food initialization || chasni_popcorn >> [Reward] expertwarly4
    local function ReticuleTargetFn()
        return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0.001, 0))
    end
    local function OnHit(inst, attacker)
        local x, y, z = inst.Transform:GetWorldPosition()
        if inst.components.planardamage == nil then
            inst:AddComponent("planardamage")
            inst.components.planardamage:SetBaseDamage(12.5)
        end

        inst:AddComponent("explosive")
        inst.components.explosive.explosiverange = 2
        inst.components.explosive.explosivedamage = 0
        inst.components.explosive.lightonexplode = false
        if inst.ispvp then
            inst.components.explosive:SetPvpAttacker(attacker)
        else
            inst.components.explosive:SetAttacker(attacker)
        end
        inst.components.explosive:OnBurnt()

        SpawnPrefab("deer_yellow_circle_explode").Transform:SetPosition(x, y, z)
    end
    local function onthrown(inst, attacker)
        inst:AddTag("NOCLICK")
        inst.persists = false

        inst.ispvp = attacker and attacker:IsValid() and attacker:HasTag("player")

        inst.Physics:SetMass(1)
        inst.Physics:SetFriction(0)
        inst.Physics:SetDamping(0)
        inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.GROUND)
        inst.Physics:CollidesWith(COLLISION.OBSTACLES)
        inst.Physics:CollidesWith(COLLISION.ITEMS)
        inst.Physics:SetCapsule(.2, .2)
    end

    local function onequip(inst, owner)
        owner.AnimState:OverrideSymbol("swap_object", "none", "swap_object")

        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
    end

    local function onunequip(inst, owner)
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")
    end

    AddPrefabPostInit("chasni_popcorn", function(inst)
        inst.entity:AddSoundEmitter()

        inst:AddTag("toughworker")
        inst:AddTag("explosive")
        inst:AddTag("projectile")
        inst:AddTag("weapon")

        inst:AddComponent("reticule")
        inst.components.reticule.targetfn = ReticuleTargetFn
        inst.components.reticule.ease = true

        if TheWorld.ismastersim then
            inst:AddComponent("locomotor")

            inst:AddComponent("complexprojectile")
            inst.components.complexprojectile:SetHorizontalSpeed(30)
            inst.components.complexprojectile:SetGravity(-75)
            inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
            inst.components.complexprojectile:SetOnLaunch(onthrown)
            inst.components.complexprojectile:SetOnHit(OnHit)

            inst:AddComponent("equippable")
            inst.components.equippable:SetOnEquip(onequip)
            inst.components.equippable:SetOnUnequip(onunequip)
            inst.components.equippable.equipstack = true

            inst:AddComponent("farmplantable")
            inst.components.farmplantable.plant = "farm_plant_corn"
        end
    end)

    local function spawnmore(pos, doer, xoff, yoff, zoff)
        local x, y, z = doer.Transform:GetWorldPosition()
        local projectile = chasni_spawnprefab("chasni_popcorn", x, y, z)
        if projectile then
            if projectile.AnimState then
                projectile.AnimState:SetBank("corn")
                projectile.AnimState:SetBuild("corn")
                projectile.AnimState:PlayAnimation("cooked", false)
            end
            local newpos = deepcopy(pos)
            newpos.x = newpos.x + xoff
            newpos.z = newpos.z + zoff
            projectile.components.complexprojectile.targetoffset = {x=0,y=yoff or 0,z=0}
            projectile.components.complexprojectile:Launch(newpos, doer)
        end
    end

    local old_toss_fn = ACTIONS.TOSS.fn
    ACTIONS.TOSS.fn = function(act)
        local projectile = act.invobject
        local doer_inventory = act.doer.components.inventory
        if projectile and doer_inventory and projectile.prefab == "chasni_popcorn" then
            projectile = doer_inventory:DropItem(projectile, false)
            if projectile then
                if projectile.AnimState then
                    projectile.AnimState:SetBank("corn")
                    projectile.AnimState:SetBuild("corn")
                    projectile.AnimState:PlayAnimation("cooked", false)
                end
                local pos, yoff
                if act.target then
                    pos = act.target:GetPosition()
                    projectile.components.complexprojectile.targetoffset = {x=0,y=1.5,z=0}
                    yoff = 1.5
                else
                    pos = act:GetActionPoint()
                end

                act.doer:DoTaskInTime(0.1, function()
                    act.doer:DoTaskInTime(0.1, function()
                        act.doer:DoTaskInTime(0.1, function()
                            act.doer:DoTaskInTime(0.1, function()
                                spawnmore(pos, act.doer, 3, yoff, 0)
                            end)
                            spawnmore(pos, act.doer, -3, yoff, 0)
                        end)
                        spawnmore(pos, act.doer, 0, yoff, 3)
                    end)
                    spawnmore(pos, act.doer, 0, yoff, -3)
                end)
                projectile.components.complexprojectile:Launch(pos, act.doer)
                return true
            end
        else
            return old_toss_fn(act)
        end
    end

    -- CC : allow cook when container is not full "chasni_portablegriller" >> [Reward] expertwarly4
    AddComponentPostInit("stewer", function(self)
        local _CanCook = self.CanCook
        self.CanCook = function(_self, harvester, ...)
            if _self.inst and _self.inst:HasTag("chasni_griller") then
                return _self.inst.components.container and not _self.inst.components.container:IsEmpty()
            end
            return _CanCook(_self, harvester, ...)
        end
    end)
end
