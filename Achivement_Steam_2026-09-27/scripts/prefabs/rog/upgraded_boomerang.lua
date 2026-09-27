local assets =
{
    Asset("ANIM", "anim/chasni_boomerang.zip"),
    Asset("ANIM", "anim/swap_chasni_boomerang.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_boomerang.xml"),
}

local BASE_DAMAGE = chasni_getitemconfig("upgraded_boomerang", "BDM") or 1
local MAX_STACK = chasni_getitemconfig("upgraded_boomerang", "BDM") or 10

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_chasni_boomerang", "swap_boomerang", 4)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function OnDropped(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.components.inventoryitem.pushlandedevents = true
    inst:PushEvent("on_landed")
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
end

local function OnThrown(inst, owner, target)
    if target ~= owner then
        owner.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_throw")
    end
    inst.AnimState:PlayAnimation("spin_loop", true)
    inst.components.inventoryitem.pushlandedevents = false
end

local function OnCaught(inst, catcher)
    if catcher ~= nil and catcher.components.inventory ~= nil and catcher.components.inventory.isopen then
        if inst.components.equippable ~= nil and not catcher.components.inventory:GetEquippedItem(inst.components.equippable.equipslot) then
            catcher.components.inventory:Equip(inst)
        else
            catcher.components.inventory:GiveItem(inst)
        end
        catcher:PushEvent("catch")
        local boomstack = inst.boomstack and inst.boomstack:value() or 0
        if boomstack < MAX_STACK then
            inst.boomstack:set(boomstack + 1)
        end
    end
end

local function ReturnToOwner(inst, owner)
    if owner ~= nil then
        owner.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_return")
        inst.components.projectile:Throw(owner, owner)
    end
end

local function OnHit(inst, owner, target)
    if owner == target or owner:HasTag("playerghost") then
        OnDropped(inst)
        inst.boomstack:set(0)
    else
        ReturnToOwner(inst, owner)
    end
    if target ~= nil and target:IsValid() and target.components.combat then
        local impactfx = SpawnPrefab("impact")
        if impactfx ~= nil then
            local follower = impactfx.entity:AddFollower()
            follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
            impactfx:FacePoint(inst.Transform:GetWorldPosition())
        end
    end
end

local function OnMiss(inst, owner, target)
    if owner == target then
        OnDropped(inst)
        inst.boomstack:set(0)
    else
        ReturnToOwner(inst, owner)
    end
end

local function getDamage(inst)
    local boomstack = inst.boomstack and inst.boomstack:value() > 0 and inst.boomstack:value() or 0
    return BASE_DAMAGE * bit.lshift(1, boomstack)
end

local function SetBoomStack(inst, boomstack)
    if boomstack then
        inst.boomstack:set(boomstack)
    else
        inst.boomstack:set(0)
    end
end

local function OnSave(inst, data)
    data.boomstack = inst.boomstack:value()
end

local function OnLoad(inst, data)
    if data and data.boomstack then
        SetBoomStack(inst, data.boomstack)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)
    MakeInventoryFloatable(inst, "small", 0.18, {0.8, 0.9, 0.8})

    inst.AnimState:SetBank("chasni_boomerang")
    inst.AnimState:SetBuild("chasni_boomerang")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("thrown")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.boomstack = net_smallbyte(inst.GUID, "boomerang.boomstack", "boomstackdirty")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(getDamage)
    inst.components.weapon:SetRange(TUNING.BOOMERANG_DISTANCE, TUNING.BOOMERANG_DISTANCE+2)
    -------

    inst:AddComponent("inspectable")
    -- >>>> This is hack so itemtiles shows... :(
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(10)
    inst.components.finiteuses:SetUses(10)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(10)
    inst.components.projectile:SetCanCatch(true)
    inst.components.projectile:SetOnThrownFn(OnThrown)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile:SetOnCaughtFn(OnCaught)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_boomerang"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_boomerang.xml"
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("upgraded_boomerang", fn, assets)
