local assets =
{
    book_gather = {
        Asset("ANIM", "anim/swap_book_gather.zip"),
        Asset("ANIM", "anim/book_gather.zip"),
        Asset("ATLAS", "images/inventoryimages/book_gather.xml"),
        Asset("IMAGE", "images/inventoryimages/book_gather.tex"),
    },
    book_teleport = {
        Asset("ANIM", "anim/swap_book_teleport.zip"),
        Asset("ANIM", "anim/book_teleport.zip"),
        Asset("ATLAS", "images/inventoryimages/book_teleport.xml"),
        Asset("IMAGE", "images/inventoryimages/book_teleport.tex"),
    },
    book_shield = {
        Asset("ANIM", "anim/swap_book_shield.zip"),
        Asset("ANIM", "anim/book_shield.zip"),
        Asset("ATLAS", "images/inventoryimages/book_shield.xml"),
        Asset("IMAGE", "images/inventoryimages/book_shield.tex"),
    },
    book_shadow = {
        Asset("ANIM", "anim/swap_book_shadow.zip"),
        Asset("ANIM", "anim/book_shadow.zip"),
        Asset("ATLAS", "images/inventoryimages/book_shadow.xml"),
        Asset("IMAGE", "images/inventoryimages/book_shadow.tex"),
    },
    book_lunar = {
        Asset("ANIM", "anim/swap_book_lunar.zip"),
        Asset("ANIM", "anim/book_lunar.zip"),
        Asset("ATLAS", "images/inventoryimages/book_lunar.xml"),
        Asset("IMAGE", "images/inventoryimages/book_lunar.tex"),
    },
}

-- book_gather
local function dopuff(inst)
    local fx = SpawnPrefab("small_puff")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx.Transform:SetScale(1.1, 1.1, 1.1)
end

local function trypicking(inst, reader)
    if inst.components.pickable and inst.components.pickable:CanBePicked() then
        inst.components.pickable:Pick(reader)
        dopuff(inst)
    elseif inst.components.harvestable and inst.components.harvestable:CanBeHarvested() then 
        inst.components.harvestable:Harvest(reader)
        dopuff(inst)
    elseif inst.components.inventoryitem and inst.components.inventoryitem.canbepickedup == true then
        reader.components.inventory:GiveItem(inst)
        dopuff(inst)
    end
end

--book tele
local function Appear(target)
    target.sg:GoToState(target:HasTag("playerghost") and "appear" or "doshortaction")
    target:Show()
end

local function TeleEffect(target)
    SpawnPrefab("statue_transition_2").Transform:SetPosition(target.Transform:GetWorldPosition())
    SpawnPrefab("spawn_fx_medium").Transform:SetPosition(target.Transform:GetWorldPosition())
    if target.DynamicShadow then
        target.DynamicShadow:Enable(true)
    end
end

local function TeleportTime(target)
    local x, y, z = target.Transform:GetWorldPosition()
    local telebases = FindNearestActiveTelebase(x, y, z, nil, 1)
    if telebases then
        local teleport = telebases:GetPosition()
        target.Transform:SetPosition(teleport.x, 0, teleport.z)
        target:SnapCamera()
        target:ScreenFade(true, 2)
        target:DoTaskInTime(1.8, TeleEffect)
    else
        target:SnapCamera()
        target:ScreenFade(true, 2)
        target:DoTaskInTime(1.8, TeleEffect)
    end
end

-- book_shield
local SHIELD_DURATION = chasni_getitemconfig("book_shield", "DUR") or 7
local function fxanim(inst, data)
    inst.chasniForceShield_fx.AnimState:PlayAnimation("hit")
    inst.chasniForceShield_fx.AnimState:PushAnimation("idle_loop")
end

local function removeshield_fn(inst)
    if inst.chasniForceShield_fx then
        inst.chasniForceShield_fx:kill_fx()
        inst.chasniForceShield_fx = nil
    end
    if inst.chasniForceShield_fx_task then
        inst.chasniForceShield_fx_task:Cancel()
        inst.chasniForceShield_fx_task = nil
    end
    inst.forceshield_counter = nil
    inst:RemoveEventCallback("attacked", fxanim)
    inst:RemoveTag("chasniForceShield")
end

local giveshield = function(inst, reader)
    if not inst:HasTag("chasniForceShield") and inst.forceshield_counter == nil and inst.chasniForceShield_fx_task == nil then
        inst:AddTag("chasniForceShield")
        inst.chasniForceShield_fx = SpawnPrefab("forcefieldfx")
        inst.chasniForceShield_fx.entity:SetParent(inst.entity)
        inst.chasniForceShield_fx.Transform:SetPosition(0, 0.2, 0)
        inst:ListenForEvent("attacked", fxanim)

        inst.forceshield_counter = SHIELD_DURATION
        inst.chasniForceShield_fx_task = inst:DoPeriodicTask(1, function(inst)
            if inst.forceshield_counter and inst.forceshield_counter > 0 then
                inst.forceshield_counter = inst.forceshield_counter -1
            elseif inst.forceshield_counter == nil or inst.forceshield_counter <= 0 then
                removeshield_fn(inst)
            end
        end)
    elseif inst:HasTag("chasniForceShield") and inst.forceshield_counter and inst.chasniForceShield_fx_task then
        inst.forceshield_counter = SHIELD_DURATION
    end
end

local function perusefn(inst,reader)
    if reader.peruse_web then
        reader.peruse_web(reader)
    end
    reader.components.talker:Say(GetString(reader, "ANNOUNCE_READ_BOOK","BOOK_LIGHT_UPGRADED"))
    return true
end

local book_defs =
{
    {
        name = "book_gather",
        animbuild = "book_gather",
        animbank = "book_meteor",
        animplay = "book_meteor1",
        swapprefix = "book_meteor",
        invename = "book_gather",
        uses = chasni_getitemconfig("book_gather", "USE") or 4,
        read_sanity = -TUNING.SANITY_LARGE,
        peruse_sanity = -TUNING.SANITY_MED,
        deps = { "small_puff" },
        fn = function(inst, reader)
            local worked = false
            local x, y, z = reader.Transform:GetWorldPosition()
            local range = chasni_getitemconfig("book_gather", "RNG") or 10
            local trees = TheSim:FindEntities(x, y, z, range)
            for i, v in ipairs(trees) do
                if v.components.workable then
                    if v.components.workable.action == ACTIONS.CHOP then
                        v.components.workable:WorkedBy(reader, v.components.workable.workleft)
                        worked = true
                    elseif v.components.workable.action == ACTIONS.MINE then
                        v.components.workable:WorkedBy(reader, v.components.workable.workleft)
                        worked = true
                    end
                end
            end

            local stump = TheSim:FindEntities(x, y, z, range, {"stump"})
            for i, v in ipairs(stump) do
                if v.components.workable and v.components.workable.action == ACTIONS.DIG then
                    v.components.workable:WorkedBy(reader, v.components.workable.workleft)
                    worked = true
                end
            end

            reader:DoTaskInTime(.5, function()
                local ents = TheSim:FindEntities(x, y, z, range, nil, { "barren", "stump", "withered", "INLIMBO" })
                for i, v in ipairs(ents) do
                    local timevar = 2 - 1 / (#ents + 1)
                    v:DoTaskInTime(timevar * math.random(), trypicking(v, reader))
                    worked = true
                end
            end)
            if worked then return true end
            return false
        end,
    },
    {
        name = "book_teleport",
        animbuild = "book_teleport",
        animbank = "book_meteor",
        animplay = "book_meteor1",
        swapprefix = "book_meteor",
        invename = "book_teleport",
        uses = chasni_getitemconfig("book_teleport", "USE") or 5,
        read_sanity = -TUNING.SANITY_LARGE,
        peruse_sanity = -TUNING.SANITY_LARGE,
        deps = { "spawn_fx_medium", "statue_transition_2" },
        fn = function(inst, reader)
            local x, y, z = reader.Transform:GetWorldPosition()
            local range = chasni_getitemconfig("book_teleport", "RNG") or 15
            local ents = FindPlayersInRange(x, y, z, range)
            for i, v in ipairs(ents) do
                v:ScreenFade(false)
                v:DoTaskInTime(3, Appear, v)
                v.sg:GoToState("forcetele")
                v:Hide()
                v:DoTaskInTime(1, TeleportTime)
            end
            return true
        end,
    },
    {
        name = "book_shield",
        animbuild = "book_shield",
        animbank = "book_meteor",
        animplay = "book_meteor1",
        swapprefix = "book_meteor",
        invename = "book_shield",
        uses = chasni_getitemconfig("book_shield", "USE") or 2,
        read_sanity = -100,
        peruse_sanity = 10,
        deps = { "forcefieldfx" },
        fn = function(inst, reader)
            local x, y, z = reader.Transform:GetWorldPosition()
            local range = chasni_getitemconfig("book_shield", "RNG") or 10
            local ents = FindPlayersInRange(x, y, z, range, true)
            for i, v in ipairs(ents) do
                giveshield(v, reader)
            end
            return true
        end,
    },
    {
        name = "book_shadow",
        animbuild = "book_shadow",
        animbank = "book_meteor",
        animplay = "book_meteor1",
        swapprefix = "book_meteor",
        invename = "book_shadow",
        uses = chasni_getitemconfig("book_shadow", "USE") or 4,
        read_sanity = -50,
        peruse_sanity = -100,
        deps = { "book_shadow_buff" },
        fn = function(inst, reader)
            if reader:HasDebuff("book_lunar_buff") then
                reader:RemoveDebuff("book_lunar_buff")
                return true
            end
            if reader:HasDebuff("book_shadow_buff") then
                return false
            end

            reader:AddDebuff("book_shadow_buff", "book_shadow_buff")
            if reader:HasDebuff("book_shadow_buff") then
                if reader.components.sanity then
                    reader.components.sanity:SetPercent(0)
                end
                return true
            end
            return false
        end,
    },
    {
        name = "book_lunar",
        animbuild = "book_lunar",
        animbank = "book_meteor",
        animplay = "book_meteor1",
        swapprefix = "book_meteor",
        invename = "book_lunar",
        uses = chasni_getitemconfig("book_lunar", "USE") or 4,
        read_sanity = 20,
        peruse_sanity = -100,
        deps = { "book_lunar_buff" },
        fn = function(inst, reader)
            if reader:HasDebuff("book_shadow_buff") then
                reader:RemoveDebuff("book_shadow_buff")
                if reader.components.sleeper then
                    reader.components.sleeper:AddSleepiness(5, 5)
                end
                return true
            end
            if reader:HasDebuff("book_lunar_buff") then
                return false
            end

            reader:AddDebuff("book_lunar_buff", "book_lunar_buff")
            if reader:HasDebuff("book_lunar_buff") then
                return true
            end
            return false
        end,
    },
}

local function MakeBook(def)
    local prefabs
    if def.deps then
        prefabs = {}
        for i, v in ipairs(def.deps) do
            table.insert(prefabs, v)
        end
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", nil, 0.75)

        inst.AnimState:SetBank(def.animbank)
        inst.AnimState:SetBuild(def.animbuild)
        inst.AnimState:PlayAnimation(def.animplay)

        inst:AddTag("book")
        inst:AddTag("bookcabinet_item")
        if def.tag then
            inst:AddTag(def.tag)
            inst:AddTag("allow_action_on_impassable")

            inst:AddComponent("reticule")
            inst.components.reticule.targetfn = reticule_target_function
            inst.components.reticule.ease = true
            inst.components.reticule.ispassableatallpoints = true
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        -----------------------------------

        inst.def = def
        inst.swap_build = "swap_"..def.animbuild
        inst.swap_prefix = def.swapprefix

        inst:AddComponent("inspectable")
        inst:AddComponent("book")
        inst.components.book:SetOnRead(def.fn)
        inst.components.book:SetOnPeruse(def.perusefn or perusefn)
        inst.components.book:SetReadSanity(def.read_sanity)
        inst.components.book:SetPeruseSanity(def.peruse_sanity)
        inst.components.book:SetFx(def.fx, def.fxmount)

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = def.invename
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..def.invename..".xml"

        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(def.uses)
        inst.components.finiteuses:SetUses(def.uses)
        inst.components.finiteuses:SetOnFinished(inst.Remove)

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.MED_FUEL

        MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
        MakeSmallPropagator(inst)
        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab("chasni_"..def.name, fn, assets[def.animbuild], prefabs)
end

local ret = { }
for i, v in ipairs(book_defs) do
    table.insert(ret, MakeBook(v))
end
book_defs = nil
return unpack(ret)
