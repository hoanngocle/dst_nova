local BuffAura = require "prefabs/buffaura_common"

local prefablist = {}
local function MakeBanner(name, flagnumber, buffdata, onstartfn, onstopfn)
    local bannerprefabname = "chasni_banner_"..name

    local assets =
    {
        Asset("ANIM", "anim/winona_banner.zip"),
    }
    local assets_item =
    {
        Asset("ANIM", "anim/winona_banner_dropped.zip"),
        Asset("ATLAS", "images/inventoryimages/"..bannerprefabname..".xml"),
    }
    local prefabs =
    {
        "collapse_small",
        "ash",
    }

    local function ChangeToItem(inst)
        local item = SpawnPrefab(bannerprefabname .."_item")
        item.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end

    local function setflagnumber(inst, number)
        inst.AnimState:OverrideSymbol("flag_01", "winona_banner", "flag_0"..flagnumber)
    end

    local function onhammered(inst)
        if inst.components.burnable and inst.components.burnable:IsBurning() then
            inst.components.burnable:Extinguish()
        end

        if inst:HasTag("burnt") then
            inst.components.lootdropper:SpawnLootPrefab("ash")
            local fx = SpawnPrefab("collapse_small")
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            fx:SetMaterial("metal")
        else
            local fx = SpawnPrefab("collapse_small")
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            ChangeToItem(inst)
        end

        inst:Remove()
    end

    local function onhit(inst)--, worker)
        if not inst:HasTag("burnt") then
            inst.AnimState:PlayAnimation("hit")
            inst.AnimState:PushAnimation("idle1", false)
        end
    end

    local function onsave(inst, data)
        if inst:HasTag("burnt") or (inst.components.burnable and inst.components.burnable:IsBurning()) then
            data.burnt = true
        end
    end

    local function onload(inst, data)
        if data and data.burnt then
            inst.components.burnable.onburnt(inst)
        else
            setflagnumber(inst, flagnumber)
        end
    end

    local function OnDismantle(inst)--, doer)
        inst.AnimState:PlayAnimation("unplace")
        inst.SoundEmitter:PlaySound("dontstarve/common/together/portable/cookpot/collapse")
        inst:ListenForEvent("animover", function(inst_)
            ChangeToItem(inst_)
            inst_:Remove() 
        end)
    end

    local function OnRemove(inst)
        if inst.components.buffaura then
            inst.components.buffaura:StopAura()
        end
    end
    local function OnBurnt(inst)
        DefaultBurntStructureFn(inst)
        RemovePhysicsColliders(inst)
        SpawnPrefab("ash").Transform:SetPosition(inst.Transform:GetWorldPosition())
        if inst.components.workable then
            inst:RemoveComponent("workable")
        end
        if inst.components.portablestructure then
            inst:RemoveComponent("portablestructure")
        end
        inst.persists = false
        inst:AddTag("FX")
        inst:AddTag("NOCLICK")
        inst:ListenForEvent("animover", ErodeAway)
        inst.AnimState:PlayAnimation("burnt_collapse")
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddLight()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        inst:SetPhysicsRadiusOverride(.5)
        MakeObstaclePhysics(inst, inst.physicsradiusoverride)

        inst.Light:Enable(false)
        inst.Light:SetRadius(.6)
        inst.Light:SetFalloff(1)
        inst.Light:SetIntensity(.5)
        inst.Light:SetColour(235/255,62/255,12/255)

        inst.DynamicShadow:SetSize(2, 1)

        inst:AddTag("structure")
        inst:AddTag("buffaura")

        inst.AnimState:SetBank("winona_banner")
        inst.AnimState:SetBuild("winona_banner")
        inst.AnimState:PlayAnimation("idle1", true)

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("portablestructure")
        inst.components.portablestructure:SetOnDismantleFn(OnDismantle)

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(2)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit)

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

        inst:AddComponent("buffaura")
        inst.components.buffaura:AddAura(bannerprefabname.."_buff", bannerprefabname.."_buff", 12)
        if name == "shadow" then
            inst.components.buffaura:SetAuraFindFn(bannerprefabname.."_buff", function(x, y, z, radius)
                return TheSim:FindEntities(x, y, z, radius, {"_combat"}, {"player", "FX", "NOCLICK", "DECOR", "INLIMBO"}, function(target) return target.components.combat and not chasni_friendpet(target) end)
            end)
        end
        if onstartfn then
            inst.components.buffaura:SetOnStartFn(onstartfn)
        end
        if onstopfn then
            inst.components.buffaura:SetOnStopFn(onstopfn)
        end
        inst:DoTaskInTime(0, function()
            inst.components.buffaura:StartAura()
        end)

        MakeMediumBurnable(inst, nil, nil, true)
        MakeSmallPropagator(inst)
        inst.components.burnable:SetFXLevel(2)
        inst.components.burnable:SetOnBurntFn(OnBurnt)

        setflagnumber(inst)

        inst.OnSave = onsave
        inst.OnLoad = onload
        inst.OnRemoveEntity = OnRemove

        return inst
    end

    local function ondeploy(inst, pt, deployer)
        local banner = SpawnPrefab(bannerprefabname)
        if banner then
            banner.Physics:SetCollides(false)
            banner.Physics:Teleport(pt.x, 0, pt.z)
            banner.Physics:SetCollides(true)
            banner.AnimState:PlayAnimation("place")
            banner.AnimState:PushAnimation("idle1", true)
            banner.SoundEmitter:PlaySound("dontstarve/common/together/portable/cookpot/place")
            inst:Remove()
            PreventCharacterCollisionsWithPlacedObjects(banner)
        end
    end

    local function itemfn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", 0.1, 0.8)

        inst.AnimState:SetBank("winona_banner_dropped")
        inst.AnimState:SetBuild("winona_banner_dropped")
        inst.AnimState:PlayAnimation("idle_"..name)

        inst:AddTag("portableitem")

        inst:SetPrefabNameOverride(bannerprefabname)

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = bannerprefabname
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..bannerprefabname..".xml"

        inst:AddComponent("deployable")
        inst.components.deployable.ondeploy = ondeploy

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

        MakeMediumBurnable(inst)
        MakeSmallPropagator(inst)

        return inst
    end

    local function bufffn()
        local inst = BuffAura.common_fn(buffdata)

        if not TheWorld.ismastersim then
            return inst
        end

        return inst
    end

    local function placer_postinit(inst)
        inst.AnimState:OverrideSymbol("flag_01", "winona_banner", "flag_0"..flagnumber)
    end

    table.insert(prefablist, Prefab(bannerprefabname, fn, assets, prefabs))
    table.insert(prefablist, MakePlacer(bannerprefabname .."_item_placer", "winona_banner", "winona_banner", "placer", false, false, false, nil, nil, nil, placer_postinit))
    table.insert(prefablist, Prefab(bannerprefabname .."_item", itemfn, assets_item))
    table.insert(prefablist, Prefab(bannerprefabname .."_buff", bufffn))
end

local buffdata_miss =
{
    ONATTACH = function(inst, target)
        if target.chasni_banner_misstask == nil then
            local misscd = target.components.allachivcoin and target.components.allachivcoin.expertwinona2 and 24 or 120
            target.chasni_banner_misstask = target:DoTaskInTime(misscd, function()
                if target.chasni_banner_missfxtask then
                    target.chasni_banner_missfxtask:Cancel()
                    target.chasni_banner_missfxtask = nil
                end
                target.chasni_banner_missfxtask = target:DoPeriodicTask(3, function()
                    chasni_spawnprefab("chasni_music_fx", 0,0,0,1,1,1, target.entity)
                end)
                if target.chasni_banner_misstask then
                    target.chasni_banner_misstask:Cancel()
                    target.chasni_banner_misstask = nil
                end
            end)
        end
    end,
    ONDETACH = function(inst, target)
        if target.chasni_banner_misstask then
            target.chasni_banner_misstask:Cancel()
            target.chasni_banner_misstask = nil
        end
        if target.chasni_banner_missfxtask then
            target.chasni_banner_missfxtask:Cancel()
            target.chasni_banner_missfxtask = nil
        end
    end,
}

local buffdata_repair =
{
    PERIOD = 60, -- if you change this, need to change gearfrontfx on chasni_buff
    PERIOD_FN = function(inst, target)
        if target and target:HasTag("player") then
            local inventory = target.components.inventory
            if inventory then
                inventory:ForEachItemSlot(function(item)
                    if item and item:IsValid() then
                        if not item:HasTag("charges_percentage") and not chasni_isMagicItem(item.prefab) then
                            local repairamount = target.components.allachivcoin and target.components.allachivcoin.expertwinona2 and 0.05 or 0.01
                            if item.components.finiteuses then
                                local p = item.components.finiteuses:GetPercent()
                                p = math.min(p + repairamount, 1.0)
                                item.components.finiteuses:SetPercent(p)
                            end
                            if item.components.armor then
                                local p = item.components.armor:GetPercent()
                                p = math.min(p + repairamount, 1.0)
                                item.components.armor:SetPercent(p)
                            end
                            if item.components.fueled then
                                local p = item.components.fueled:GetPercent()
                                p = math.min(p + repairamount, 1.0)
                                item.components.fueled:SetPercent(p)
                            end
                        end
                    end
                end)
            end
        end
    end,
    ONATTACH = function(inst, target)
        target:AddDebuff("gear_buff", "gear_buff")
    end,
    ONDETACH = function(inst, target)
        target:RemoveDebuff("gear_buff", "gear_buff")
    end,
    fxscale = 2.5,
    yoffset = 3,
}

local function buffstart_moon(inst)
    inst._butterflies = inst._butterflies or {}
    local bx, by, bz = inst.Transform:GetWorldPosition()

    local count = 8
    for i = 1, count do
        local angle = (2 * PI * (i - 1)) / count
        local x = bx + 10 * math.cos(angle)
        local z = bz + 10 * math.sin(angle)

        local fx = chasni_spawnprefab("moonbutterfly_fx", x, by, z)
        fx._moonbanner = inst
        fx._circlingradius = 20
        fx._circlingangle   = angle
        inst:DoTaskInTime(0, function()
            if fx.sg then
                fx.sg:GoToState("idle")
            end
        end)

        table.insert(inst._butterflies, fx)
    end
end

local function buffstop_moon(inst)
    if inst._butterflies then
        for _, bf in ipairs(inst._butterflies) do
            if bf and bf:IsValid() then
                ErodeAway(bf)
            end
        end
        inst._butterflies = nil
    end
end

local buffdata_shadow =
{
    PERIOD = 1,
    PERIOD_FN = function(inst, target)
        if target.components.combat then
            local currentarmorreduced = target.components.combat.externaldamagetakenmultipliers:CalculateModifierFromSource("chasni_banner_shadow")
            local x, y, z = target.Transform:GetWorldPosition()
            local players = FindPlayersInRange(x, y, z, 10)
            local armorreduction = 0.002
            for _, v in ipairs(players) do
                if v.components.allachivcoin and v.components.allachivcoin.expertwinona2 then
                    armorreduction = 0.01
                    break
                end
            end
            target.components.combat.externaldamagetakenmultipliers:SetModifier("chasni_banner_shadow", currentarmorreduced + armorreduction)
        end
    end,
    ONDETACH = function(inst, target)
        if target.components.combat then
            target.components.combat.externaldamagetakenmultipliers:RemoveModifier("chasni_banner_shadow")
        end
    end,
}

local function buffstart_shadow(inst)
    inst._roses = inst._roses or {}
    local bx, by, bz = inst.Transform:GetWorldPosition()

    local count = 20
    for i = 1, count do
        local angle = (2 * PI * (i - 1)) / count
        local x = bx + 10 * math.cos(angle)
        local z = bz + 10 * math.sin(angle)

        local fx = chasni_spawnprefab("vine_bridge_decor_fx", x, by, z)
        table.insert(inst._roses, fx)
    end
end

local function buffstop_shadow(inst)
    if inst._roses then
        for _, rose in ipairs(inst._roses) do
            if rose and rose:IsValid() then
                rose.AnimState:PlayAnimation("extra_"..tostring(rose.variation).."_pst")
                rose:ListenForEvent("animover", rose.Remove)
            end
        end
        inst._roses = nil
    end
end

MakeBanner("miss", "5", buffdata_miss)
MakeBanner("repair", "1", buffdata_repair)
MakeBanner("xp", "4", {})
MakeBanner("moon", "3", {}, buffstart_moon, buffstop_moon)
MakeBanner("shadow", "2", buffdata_shadow, buffstart_shadow, buffstop_shadow)

return unpack(prefablist)
