local assets =
{
    Asset("ANIM", "anim/chasni_ghostaff.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_ghostaff.xml")
}

local assets_proj = {
    Asset("ANIM", "anim/butterfly_proj.zip"),
}

local prefabs =
{
    "pipspook_staff_fx",
    "smallghost",
}

local DAMAGE = chasni_getitemconfig("pipspook_staff", "DMG") or 10
local COOLDOWN = chasni_getitemconfig("pipspook_staff", "CD") or 120
local COOLDOWN_RES = chasni_getitemconfig("pipspook_staff", "CD") or 240
local RANGE = chasni_getitemconfig("pipspook_staff", "RNG") or 10

local function OnAbigailSpawned(owner, abigail)
    abigail = abigail or (owner and owner.components.ghostlybond and owner.components.ghostlybond.ghost) or nil
    local levelsystem = owner and owner.components.levelsystem
    if levelsystem and abigail then
        if abigail.components.combat then
            if levelsystem.damagelevelamount > 0 then
                local damagemult = 1 + (levelsystem.damagelevelamount * damageGain)
                abigail.components.combat.externaldamagemultipliers:SetModifier("pipspook_staff", damagemult)
            end
            if levelsystem.absorblevelamount > 0 then
                local absorbmult = 1 - (levelsystem.absorblevelamount * absorbGain)
                abigail.components.combat.externaldamagetakenmultipliers:SetModifier("pipspook_staff", absorbmult)
            end
        end
        if abigail.components.locomotor then
            if levelsystem.speedlevelamount > 0 then
                local speedmult = 1 + (levelsystem.speedlevelamount * speedGain)
                abigail.components.locomotor:SetExternalSpeedMultiplier(abigail, "pipspook_staff", speedmult)
            end
        end
    end
end

local function OnAbigailDespawned(owner, abigail)
    if abigail then
        if abigail.components.combat then
            abigail.components.combat.externaldamagemultipliers:RemoveModifier("pipspook_staff")
            abigail.components.combat.externaldamagetakenmultipliers:RemoveModifier("pipspook_staff")
        end
        if abigail.components.locomotor then
            abigail.components.locomotor:RemoveExternalSpeedMultiplier(abigail, "pipspook_staff")
        end
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_chasni_ghostaff", "swap_sword_lunarplant")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    chasni_equipanimatedswaphand(inst, owner)

    owner:ListenForEvent("chasni_attributechange", OnAbigailSpawned)
    owner:ListenForEvent("ghostlybond_summoncomplete", OnAbigailSpawned)
    owner:ListenForEvent("ghostlybond_recallcomplete", OnAbigailDespawned)
    local abigail = owner.components.ghostlybond and owner.components.ghostlybond.ghost
    if abigail and abigail:IsValid() then
        OnAbigailSpawned(owner, abigail)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    chasni_equipanimatedswaphand(inst, nil)

    owner:RemoveEventCallback("chasni_attributechange", OnAbigailSpawned)
    owner:RemoveEventCallback("ghostlybond_summoncomplete", OnAbigailSpawned)
    owner:RemoveEventCallback("ghostlybond_recallcomplete", OnAbigailDespawned)
    local abigail = owner.components.ghostlybond and owner.components.ghostlybond.ghost
    if abigail and abigail:IsValid() then
        OnAbigailDespawned(owner, abigail)
    end
end

local function summonPipspook(inst, target, pos)
    if pos then
        local resurrect = false
        local owner = inst.components.inventoryitem:GetGrandOwner()
        local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, RANGE, { "playerghost" })
        for i, v in ipairs(ents) do
            local announcement_string = v:GetDisplayName().." "..STRINGS.UI.HUD.REZ_ANNOUNCEMENT.." "..owner.name.."."
            TheNet:AnnounceResurrect(announcement_string, owner.entity)
            v:PushEvent("respawnfromghost", { source = inst, user = owner })
            resurrect = true
        end

        if resurrect == false then
            chasni_spawnprefab("smallghost", pos.x, pos.y, pos.z)
        end
        inst.components.rechargeable:Discharge(COOLDOWN)
    else
        inst.components.talker:Say(GetString(inst, "SISTURN_TELE_FAIL"))
    end
end

local function OnHaunt(inst, haunter)
    inst.components.rechargeable:Discharge(COOLDOWN_RES)
    local announcement_string = haunter:GetDisplayName().." "..STRINGS.UI.HUD.REZ_ANNOUNCEMENT.." Ghostaff."
    TheNet:AnnounceResurrect(announcement_string, haunter.entity)
    haunter:PushEvent("respawnfromghost", { source = inst, user = haunter })
end

local function OnCharged(inst)
    inst.components.spellcaster:SetSpellFn(summonPipspook)
    if inst.components.hauntable == nil then
        inst:AddComponent("hauntable")
    end
    inst.components.hauntable:SetOnHauntFn(OnHaunt)
end

local function OnDischarged(inst)
    inst.components.spellcaster:SetSpellFn(nil)
    if inst.components.hauntable ~= nil then
        inst:RemoveComponent("hauntable")
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("chasni_ghostaff")
    inst.AnimState:SetBuild("chasni_ghostaff")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst:AddTag("rechargeable")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
    inst.AnimState:SetFrame(frame)
    inst._fxswap = SpawnPrefab("pipspook_staff_fx")
    inst._fxswap.AnimState:PlayAnimation("swap_energy", true)
    inst._fxswap.AnimState:SetFrame(frame)
    chasni_equipanimatedswaphand(inst, nil)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DAMAGE)
    inst.components.weapon:SetRange(RANGE, RANGE+5)
    inst.components.weapon:SetProjectile("pipspook_staff_proj")

    inst:AddComponent("inspectable")
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_ghostaff"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_ghostaff.xml"

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster.canusefrominventory = false
    inst.components.spellcaster:SetSpellFn(summonPipspook)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    return inst
end

local function fxfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("chasni_ghostaff")
    inst.AnimState:SetBuild("chasni_ghostaff")
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

local function proj_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("butterfly_proj")
    inst.AnimState:SetBuild("butterfly_proj")
    inst.AnimState:PlayAnimation("loop2", true)

    inst.Light:SetIntensity(.7)
    inst.Light:SetRadius(1)
    inst.Light:SetFalloff(.7)
    inst.Light:SetColour(1, 1, 1)
    inst.Light:Enable(true)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("projectile")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(5)
    inst.components.projectile:SetHoming(true)
    inst.components.projectile:SetHitDist(0.3)
    inst.components.projectile:SetOnHitFn(inst.Remove)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetLaunchOffset({x=0,y=2,z=0})

    inst.persists = false

    return inst
end

return
Prefab("pipspook_staff", fn, assets, prefabs),
Prefab("pipspook_staff_fx", fxfn, assets),
Prefab("pipspook_staff_proj", proj_fn, assets_proj)

