local slingshot_helper = require("prefabs.walter.slingshot_helper")

local SPLITSHOT_MUST_TAGS = { "_combat", "_health", "hostile" }
local SPLITSHOT_CANT_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO", "notarget", "noattack", "invisible", "wall", "player", "companion", "hiding" }
local function OnProjectileLaunched_SplitShot(inst, attacker, target)
    if attacker and attacker.components.rider and attacker.components.rider:IsRiding() and attacker.components.rider.mount and attacker.components.rider.mount.prefab == "wobybig" then
        local projectileprefab = inst.components.weapon.projectile
        if projectileprefab then
            local x, y, z = attacker.Transform:GetWorldPosition()
            local splittargets = TheSim:FindEntities(x, 0, z, TUNING.SLINGSHOT_DISTANCE + 3, SPLITSHOT_MUST_TAGS, SPLITSHOT_CANT_TAGS)
            for _, splittarget in ipairs(splittargets) do
                if splittarget ~= target then
                    local weaponcomponent = inst.components.weapon
                    local proj = SpawnPrefab(projectileprefab)
                    if proj then
                        if proj.components.projectile then
                            if weaponcomponent.projectile_offset then
                                local dir = (splittarget:GetPosition() - Vector3(x, y, z)):Normalize()
                                dir = dir * weaponcomponent.projectile_offset
                                proj.Transform:SetPosition(x + dir.x, y, z + dir.z)
                            end
                            proj.components.projectile:Throw(inst, splittarget, attacker)
                        end
                    end
                end
            end
        end
    end
end
local function OnEquip_Splithost(inst, owner)
    if owner.components.combat then
        owner.components.combat.externaldamagemultipliers:SetModifier("slingshot_splitshot", 0.6)
    end
end
local function OnUnequip_Splithost(inst, owner)
    if owner.components.combat then
        owner.components.combat.externaldamagemultipliers:RemoveModifier("slingshot_splitshot")
    end
end

local function OnProjectileLaunched_Gereminate(inst, attacker, target)
    if attacker and attacker.components.rider and attacker.components.rider:IsRiding() and attacker.components.rider.mount and attacker.components.rider.mount.prefab == "wobybig" then
        local projectileprefab = inst.components.weapon.projectile
        if projectileprefab then
            local dist = attacker:GetDistanceSqToInst(target)
            local multicast = math.floor(dist / 55)
            for i=1, multicast do
                inst:DoTaskInTime(0.11 * i,function()
                    local weaponcomponent = inst.components.weapon
                    local proj = SpawnPrefab(projectileprefab)
                    if proj then
                        if proj.components.projectile then
                            if weaponcomponent.projectile_offset then
                                local x, y, z = attacker.Transform:GetWorldPosition()
                                local dir = (target:GetPosition() - Vector3(x, y, z)):Normalize()
                                dir = dir * weaponcomponent.projectile_offset
                                proj.Transform:SetPosition(x + dir.x, y, z + dir.z)
                            end
                            proj.components.projectile:Throw(inst, target, attacker)
                        end
                    end
                end)
            end
        end
    end
end
local function OnEquip_Gereminate(inst, owner)
    if owner.components.combat then
        owner.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1.4)
    end
end
local function OnUnequip_Gereminate(inst, owner)
    if owner.components.combat then
        owner.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst)
    end
end

--local function MakeSlingshot(name, assets, prefabs, common_postinit, master_postinit)
local function MakeSlingshot(name, slingshottype, tags, projectileLaunchedFn, EquipFn, UnequipFn, common_postinit, master_postinit)
    local assets =
    {
        Asset("ANIM", "anim/chasni_slingshot_".. slingshottype ..".zip"),
        Asset("ANIM", "anim/swap_slingshot_".. slingshottype ..".zip"),
        Asset("IMAGE", "images/inventoryimages/chasni_slingshot_".. slingshottype ..".tex"),
        Asset("IMAGE", "images/inventoryimages/chasni_slingshot_".. slingshottype .."_band_back.tex"),
        Asset("IMAGE", "images/inventoryimages/chasni_slingshot_".. slingshottype .."_band_front.tex"),
        Asset("IMAGE", "images/inventoryimages/chasni_slingshot_".. slingshottype .."_body.tex"),
        Asset("ATLAS", "images/inventoryimages/chasni_slingshot_".. slingshottype ..".xml"),
        Asset("ATLAS", "images/inventoryimages/chasni_slingshot_".. slingshottype .."_band_back.xml"),
        Asset("ATLAS", "images/inventoryimages/chasni_slingshot_".. slingshottype .."_band_front.xml"),
        Asset("ATLAS", "images/inventoryimages/chasni_slingshot_".. slingshottype .."_body.xml"),
    }

    local function OnEquip(inst, owner)
        slingshot_helper.OnEquip(inst, owner)
        owner.AnimState:OverrideSymbol("swap_object", "swap_slingshot_".. slingshottype, "swap_slingshot")

        EquipFn(inst, owner)
    end

    local function OnUnequip(inst, owner)
        slingshot_helper.OnUnequip(inst, owner)
        UnequipFn(inst, owner)
    end

    local function OnEquipToModel(inst, owner, from_ground)
        slingshot_helper.OnEquipToModel(inst, owner, from_ground)
    end

    local function OnProjectileLaunched(inst, attacker, target, proj)
        slingshot_helper.OnProjectileLaunched(inst, attacker, target, proj)
        projectileLaunchedFn(inst, attacker, target)
    end

    local function OnAmmoLoaded(inst, data)
        slingshot_helper.OnAmmoLoaded(inst, data)
    end

    local function OnAmmoUnloaded(inst, data)
        slingshot_helper.OnAmmoUnloaded(inst, data)
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("slingshot")
        inst.AnimState:SetBuild("chasni_slingshot_".. slingshottype)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("rangedweapon")
        inst:AddTag("slingshot")
        inst:AddTag("weapon")
        if tags then
            for _, tag in pairs(tags) do
                inst:AddTag(tag)
            end
        end

        inst:AddComponent("slingshotmods")
        inst:AddComponent("linkeditem")
        inst:AddComponent("clientpickupsoundsuppressor")

        inst.bandid = net_tinybyte(inst.GUID, "slingshot.bandid", "icondirty")
        inst.handleid = net_tinybyte(inst.GUID, "slingshot.handleid", "icondirty")
        inst.buildname = net_string(inst.GUID, "slingshot.buildname", "icondirty")
        inst.slingshottype = slingshottype

        --inst._iconlayers = nil
        inst.layeredinvimagefn = slingshot_helper.LayeredInvImageFn

        MakeInventoryFloatable(inst, "med", 0.07, { 0.53, 0.5, 0.5 })

        if common_postinit then
            common_postinit(inst, slingshottype)
            inst:SetPrefabNameOverride("chasni_slingshot_".. slingshottype)
            inst.playerinspectable_override = "chasni_slingshot_".. slingshottype
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            inst:ListenForEvent("icondirty", slingshot_helper.OnIconDirty)

            return inst
        end

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = "chasni_slingshot_".. slingshottype
        inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_slingshot_".. slingshottype ..".xml"

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = slingshot_helper.GetStatus

        inst.components.linkeditem:SetEquippableRestrictedToOwner(true)

        inst:AddComponent("equippable")
        inst.components.equippable.restrictedtag = "slingshot_sharpshooter"
        inst.components.equippable:SetOnEquip(OnEquip)
        inst.components.equippable:SetOnUnequip(OnUnequip)
        inst.components.equippable:SetOnEquipToModel(OnEquipToModel)

        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(0)
        inst.components.weapon:SetRange(TUNING.SLINGSHOT_DISTANCE, TUNING.SLINGSHOT_DISTANCE_MAX)
        inst.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)
        inst.components.weapon:SetProjectile(nil)
        inst.components.weapon:SetProjectileOffset(1)

        inst:AddComponent("container")
        inst.components.container:WidgetSetup(name..slingshottype)
        inst.components.container.canbeopened = false
        inst.components.container.stay_open_on_hide = true
        inst:ListenForEvent("itemget", OnAmmoLoaded)
        inst:ListenForEvent("itemlose", OnAmmoUnloaded)

        inst:ListenForEvent("containerinstalleditem", slingshot_helper.OnInstalledPartsChanged)
        inst:ListenForEvent("containeruninstalleditem", slingshot_helper.OnInstalledPartsChanged)
        inst:ListenForEvent("installreplacedslingshot", slingshot_helper.UpdateLinkedItemOwner)
        inst:ListenForEvent("ondeconstructstructure", slingshot_helper.OnDeconstruct)

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
        inst.components.burnable:SetOnBurntFn(slingshot_helper.OnBurnt)

        MakeHauntableLaunch(inst)

        inst:ListenForEvent("floater_startfloating", slingshot_helper.OnStartFloating)
        inst:ListenForEvent("floater_stopfloating", slingshot_helper.OnStopFloating)

        if master_postinit then
            master_postinit(inst)
        end

        return inst
    end

    return Prefab(name..slingshottype, fn, assets)
end

local function partsfx_OnEntityReplicated(inst)
    local parent = inst.entity:GetParent()
    if parent then
        slingshot_helper.SetHighlightChildren(inst, parent)
    end
end

local function MakeSlingshotPartFx(name, slingshottype)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddFollower()
        inst.entity:AddNetwork()

        inst:AddTag("FX")

        inst.AnimState:SetBank("slingshot")
        inst.AnimState:SetBuild("chasni_slingshot_".. slingshottype)
        inst.AnimState:PlayAnimation("swap_1_to_5")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = partsfx_OnEntityReplicated

            return inst
        end

        inst.persists = false

        return inst
    end
    return Prefab(name, fn)
end


return
MakeSlingshot("chasni_slingshot_", "splitshot", {"slingshot_splitshot"}, OnProjectileLaunched_SplitShot, OnEquip_Splithost, OnUnequip_Splithost),
MakeSlingshot("chasni_slingshotex_", "splitshot", {"slingshot_splitshot"}, OnProjectileLaunched_SplitShot, OnEquip_Splithost, OnUnequip_Splithost, slingshot_helper.slingshotex_common_postinit, slingshot_helper.slingshotex_master_postinit),
MakeSlingshot("chasni_slingshot999ex_", "splitshot", {"slingshot_splitshot"}, OnProjectileLaunched_SplitShot, OnEquip_Splithost, OnUnequip_Splithost, slingshot_helper.slingshot999ex_common_postinit, slingshot_helper.slingshot999ex_master_postinit),
MakeSlingshot("chasni_slingshot2_", "splitshot", {"slingshot_splitshot"}, OnProjectileLaunched_SplitShot, OnEquip_Splithost, OnUnequip_Splithost, slingshot_helper.slingshot2_common_postinit, slingshot_helper.slingshot2_master_postinit),
MakeSlingshot("chasni_slingshot2ex_", "splitshot", {"slingshot_splitshot"}, OnProjectileLaunched_SplitShot, OnEquip_Splithost, OnUnequip_Splithost, slingshot_helper.slingshot2ex_common_postinit, slingshot_helper.slingshot2ex_master_postinit),

MakeSlingshot("chasni_slingshot_", "gereminate", {"slingshot_gereminate"}, OnProjectileLaunched_Gereminate, OnEquip_Gereminate, OnUnequip_Gereminate),
MakeSlingshot("chasni_slingshotex_", "gereminate", {"slingshot_gereminate"}, OnProjectileLaunched_Gereminate, OnEquip_Gereminate, OnUnequip_Gereminate, slingshot_helper.slingshotex_common_postinit, slingshot_helper.slingshotex_master_postinit),
MakeSlingshot("chasni_slingshot999ex_", "gereminate", {"slingshot_gereminate"}, OnProjectileLaunched_Gereminate, OnEquip_Gereminate, OnUnequip_Gereminate, slingshot_helper.slingshot999ex_common_postinit, slingshot_helper.slingshot999ex_master_postinit),
MakeSlingshot("chasni_slingshot2_", "gereminate", {"slingshot_gereminate"}, OnProjectileLaunched_Gereminate, OnEquip_Gereminate, OnUnequip_Gereminate, slingshot_helper.slingshot2_common_postinit, slingshot_helper.slingshot2_master_postinit),
MakeSlingshot("chasni_slingshot2ex_", "gereminate", {"slingshot_gereminate"}, OnProjectileLaunched_Gereminate, OnEquip_Gereminate, OnUnequip_Gereminate, slingshot_helper.slingshot2ex_common_postinit, slingshot_helper.slingshot2ex_master_postinit),
MakeSlingshotPartFx("chasni_slingshotparts_splitshot_fx", "splitshot"),
MakeSlingshotPartFx("chasni_slingshotparts_gereminate_fx", "gereminate")
