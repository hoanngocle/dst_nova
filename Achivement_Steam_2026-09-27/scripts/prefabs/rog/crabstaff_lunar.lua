local assets =
{
    Asset("ANIM", "anim/chasni_stafflunar.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_stafflunar.xml"),
}

local prefabs =
{
    "crabstaff_lunar_fx",
    "sparklefx",
}

local DAMAGE = chasni_getitemconfig("crabstaff_lunar", "DMG") or 10
local USES = chasni_getitemconfig("crabstaff_lunar", "USES") or 100
local USAGE = 25
local SANITY_COST = chasni_getitemconfig("crabstaff_lunar", "SAN") or 10
local RANGE = chasni_getitemconfig("crabstaff_lunar", "RNG") or 8
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_chasni_stafflunar", "swap_sword_lunarplant")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    chasni_equipanimatedswaphand(inst, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    chasni_equipanimatedswaphand(inst, nil)
end

local function oncast(inst, target, pos)
    local players = FindPlayersInRange(pos.x, pos.y, pos.z, RANGE)
    for i, player in ipairs(players) do
        local px, py, pz = player.Transform:GetWorldPosition()
        chasni_spawnprefab("sparklefx", px, -1, pz, 1.6,1.6,1.6)
        if player.components.inventory then
            for k, equipment in pairs(player.components.inventory.equipslots) do
                if equipment and not equipment:HasTag("charges_percentage") and equipment.prefab ~= inst.prefab then
                    if equipment.components.finiteuses then
                        equipment.components.finiteuses:SetPercent(1)
                    end
                    if equipment.components.armor then
                        equipment.components.armor:SetPercent(1)
                    end
                    if equipment.components.fueled then
                        equipment.components.fueled:SetPercent(1)
                    end
                    if equipment and equipment.components.perishable then
                        equipment.components.perishable:SetPercent(1)
                    end
                end
            end
            for k, item in pairs(player.components.inventory.itemslots) do
                if item and not item:HasTag("charges_percentage") and item.prefab ~= inst.prefab then
                    if item.components.finiteuses then
                        item.components.finiteuses:SetPercent(1)
                    end
                    if item.components.armor then
                        item.components.armor:SetPercent(1)
                    end
                    if item.components.fueled then
                        item.components.fueled:SetPercent(1)
                    end
                    if item.components.perishable then
                        item.components.perishable:SetPercent(1)
                    end
                end
            end
        end
    end
    local owner = inst.components.inventoryitem:GetGrandOwner()
    inst.components.finiteuses:Use(USAGE)
    if owner then
        if owner.components.staffsanity then
            owner.components.staffsanity:DoCastingDelta(-SANITY_COST)
        elseif owner.components.sanity then
            owner.components.sanity:DoDelta(-SANITY_COST)
        end
    end
    return true
end

local function reticule_target_function(inst)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0.001, 0))
end

local function onfinished(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("chasni_stafflunar")
    inst.AnimState:SetBuild("chasni_stafflunar")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetSymbolBloom("pb_energy_loop01")
    inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", .5)
    inst.AnimState:SetLightOverride(.1)

    inst:AddTag("weapon")

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = reticule_target_function
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
    inst.AnimState:SetFrame(frame)
    inst._fxswap = SpawnPrefab("crabstaff_lunar_fx")
    inst._fxswap.AnimState:PlayAnimation("swap_energy", true)
    inst._fxswap.AnimState:SetFrame(frame)
    chasni_equipanimatedswaphand(inst, nil)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DAMAGE)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetOnFinished(onfinished)
    inst.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_stafflunar"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_stafflunar.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster:SetSpellFn(oncast)

    MakeHauntableLaunch(inst)

    return inst
end

local function fxfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("chasni_stafflunar")
    inst.AnimState:SetBuild("chasni_stafflunar")
    inst.AnimState:PlayAnimation("swap_energy", true)
    inst.AnimState:SetSymbolBloom("pb_energy_loop01")
    inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", .5)
    inst.AnimState:SetLightOverride(.1)

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("colouradder")

    inst.persists = false

    return inst
end

return
Prefab("crabstaff_lunar", fn, assets, prefabs),
Prefab("crabstaff_lunar_fx", fxfn, assets)
