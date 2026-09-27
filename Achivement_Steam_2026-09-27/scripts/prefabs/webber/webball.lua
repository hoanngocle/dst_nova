local assets =
{
    Asset("ANIM", "anim/webball.zip"),
    Asset("ATLAS", "images/inventoryimages/webball.xml"),
}

local prefabs =
{
    "spoiled_food" 
}

local function ReticuleTargetFn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0.001, 0))
end
local function OnHit(inst, attacker, target)
    inst:RemoveTag("NOCLICK")
    inst.AnimState:PlayAnimation("idle")
    inst.SoundEmitter:KillSound("spin_loop")
    inst.components.inventoryitem.canbepickedup = true

    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("spider_heal_ground_fx").Transform:SetPosition(x, y, z)
    local spiders = TheSim:FindEntities(x,y,z, 5, {"spider"}, chasni_TAG_NOTARGET)
    local catchspider = false
    for _, spider in ipairs(spiders) do
        if spider:IsValid() and spider.components.inventoryitem and spider.components.health and not spider.components.health:IsDead() then
            local success = inst.components.inventory:GiveItem(spider, nil, spider:GetPosition())
            if success then
                catchspider = true
            end
        end
    end
    if not catchspider then
        inst.components.inventory:DropEverything()
    end
    local entities = TheSim:FindEntities(x,y,z, 5, {"locomotor"}, { "FX", "NOCLICK", "DECOR", "INLIMBO", "spider", "player", "flying" })
    for _, entity in ipairs(entities) do
        if entity.components.health and not entity.components.health:IsDead() and entity.components.locomotor then
            if entity._webball_task then
                entity._webball_task:Cancel()
                entity._webball_task = nil
            end
            entity._webball_task = entity:DoTaskInTime(5, function(en)
                en.components.locomotor:RemoveExternalSpeedMultiplier(en, "webball")
            end)
            entity.components.locomotor:SetExternalSpeedMultiplier(entity, "webball", 0.5)
        end
    end

    local structures = TheSim:FindEntities(x, 0, z, 5, {"structure"}, {"spidermonkey_creeped"})
    for i, structure in ipairs(structures) do
        if structure:IsValid() then
            local x1, _, z1 = structure.Transform:GetWorldPosition()
            local creep = chasni_spawnprefab("spidermonkey_creep", x1, 0, z1)
            creep.InitCreep(creep, structure)
        end
    end
end
local function onthrown(inst, attacker)
    inst:AddTag("NOCLICK")

    inst.AnimState:PlayAnimation("proj", true)
    inst.components.inventoryitem.canbepickedup = false
    inst.SoundEmitter:PlaySound("wilson_rework/torch/torch_spin", "spin_loop")

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

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("chasni_webball")
    inst.AnimState:SetBuild("webball")
    inst.AnimState:PlayAnimation("idle", false)

    inst:AddTag("projectile")
    --inst:AddTag("special_action_toss")
    inst:AddTag("keep_equip_toss")

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventory")
    inst:AddComponent("inspectable")
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(30)
    inst.components.complexprojectile:SetGravity(-90)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(OnHit)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipstack = true

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "webball"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/webball.xml"

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("chasni_webball", fn, assets, prefabs)
