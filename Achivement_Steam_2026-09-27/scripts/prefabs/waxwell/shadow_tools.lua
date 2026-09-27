

local function OnSave(inst, data)
    data.workcounter = inst.workcounter
end

local function OnLoad(inst, data)
    inst.workcounter = data and data.workcounter or 0
end

local function OnPlayerAction(inst, player)
    inst.workcounter = inst.workcounter + 1
end

local function SetFxOwner(inst, owner)
    if inst.fx then
        if inst._fxowner and inst._fxowner.components.colouradder then
            inst._fxowner.components.colouradder:DetachChild(inst.fx)
        end
        inst._fxowner = owner
        if owner then
            inst.fx.entity:SetParent(owner.entity)
            inst.fx.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 2)
            inst.fx.components.highlightchild:SetOwner(owner)
            inst.fx:ToggleEquipped(true)
            if owner.components.colouradder then
                owner.components.colouradder:AttachChild(inst.fx)
            end
        else
            inst.fx.entity:SetParent(inst.entity)
            --For floating
            inst.fx.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 2)
            inst.fx.components.highlightchild:SetOwner(inst)
            inst.fx:ToggleEquipped(false)
        end
    end
end

local function OnEquip(inst, owner)
    owner.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
    owner.AnimState:OverrideSymbol("swap_object", inst._swap_build, inst._swap_bank)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    SetFxOwner(inst, owner)
    inst:ListenForEvent("performaction", inst._OnPlayerAction, owner)
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    SetFxOwner(inst, nil)
    inst:RemoveEventCallback("performaction", inst._OnPlayerAction, owner)
end

local function spawnfx(inst, prefab)
    local fx = SpawnPrefab(prefab)
    if fx then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end

local function OnDropped(inst)
    inst:RemoveComponent("inventoryitem")
    inst:RemoveComponent("equippable")
    inst:DoTaskInTime(1,function()
        spawnfx(inst, "statue_transition")
        local pos = Vector3(inst.Transform:GetWorldPosition())
        local ents = FindPlayersInRange(pos.x,pos.y,pos.z, 16, true)
        for k,v in pairs(ents) do
            if v.components.sanity then
                v:DoTaskInTime(1,function()
                    if v.components.sanity then
                        v.components.sanity:DoDelta(inst.workcounter)
                        local fx = SpawnPrefab("sanity_raise")
                        if fx then
                            fx.entity:SetParent(v.entity)
                            fx.Transform:SetScale(1.7, 1.7, 1.7)
                        end
                    end
                end)
            end
        end
        inst:Remove()
    end)
end

local function HarvestPickable(inst, ent, doer)
    if ent.components.pickable.picksound then
        doer.SoundEmitter:PlaySound(ent.components.pickable.picksound)
    end
    local _, loot = ent.components.pickable:Pick(TheWorld)

    if loot then
        for i, item in ipairs(loot) do
            Launch(item, doer, 1.5)
        end
    end
end

local function IsEntityInFront(inst, entity, doer_rotation, doer_pos)
    local facing = Vector3(math.cos(-doer_rotation / RADIANS), 0 , math.sin(-doer_rotation / RADIANS))

    return IsWithinAngle(doer_pos, facing, TUNING.VOIDCLOTH_SCYTHE_HARVEST_ANGLE_WIDTH, entity:GetPosition())
end

local HARVEST_MUSTTAGS  = {"pickable"}
local HARVEST_ONEOFTAGS = {"plant", "lichen", "oceanvine", "kelp"}
local function DoScythe(inst, target, doer)
    if target.components.pickable then
        local doer_pos = doer:GetPosition()
        local x, y, z = doer_pos:Get()

        local doer_rotation = doer.Transform:GetRotation()
        local ents = TheSim:FindEntities(x, y, z, 2.5, HARVEST_MUSTTAGS, chasni_TAG_NOTARGET, HARVEST_ONEOFTAGS)
        for _, ent in pairs(ents) do
            if ent:IsValid() and ent.components.pickable then
                if inst:IsEntityInFront(ent, doer_rotation, doer_pos) then
                    inst:HarvestPickable(ent, doer)
                end
            end
        end
    end
end

local function MakeTools(name, build, bank, anim, noswap, tags, action, separatebank)
    local assets =
    {
        Asset("ANIM", "anim/"..build.. ".zip"),
        Asset("ATLAS", "images/inventoryimages/shadow_"..name..".xml"),
    }
    if not noswap then
        table.insert(assets, Asset("ANIM", "anim/dark_swap_"..name..".zip"))
    end
    local prefabs =
    {
        "statue_transition",
        "sanity_raise",
    }

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(separatebank or bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim, separatebank and true or false)

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)

        inst:AddTag("shadow")
        inst:AddTag("shadowlevel")
        inst:AddTag("tool")
        inst:AddTag("weapon")
        inst:AddTag("shadow_item")
        if tags then
            for _,v in ipairs(tags) do
                inst:AddTag(v)
            end
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        if name == "oar" then
            inst:AddComponent("oar")
            inst.components.oar.force = 0.5
            inst.components.oar.max_velocity = 3.5
        elseif name == "pitchfork" then
            inst:AddComponent("terraformer")
        else
            inst:AddComponent("tool")
            inst.components.tool:SetAction(action, 1)
        end

        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(1)

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = "shadow_" .. name
        inst.components.inventoryitem.atlasname = "images/inventoryimages/shadow_"..name..".xml"

        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(OnEquip)
        inst.components.equippable:SetOnUnequip(OnUnequip)
        inst.components.equippable.dapperness = -TUNING.DAPPERNESS_MED
        inst.components.equippable.is_magic_dapperness = true

        inst:AddComponent("shadowlevel")
        inst.components.shadowlevel:SetDefaultLevel(1)

        inst:AddComponent("sanityaura")
        inst.components.sanityaura.aurafn = function (inst, observer)
            return chasni_hastag2(observer, "expertwaxwell3") and 0 or -TUNING.SANITYAURA_MED
        end

        inst.workcounter = 0
        inst._OnPlayerAction = function(player, data) OnPlayerAction(inst, player) end

        inst._swap_build = noswap and build or "dark_swap_" .. name
        inst._swap_bank = separatebank and "swap_" .. name or "swap_" .. bank
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.DoScythe = name == "scythe" and DoScythe or nil
        inst.IsEntityInFront = name == "scythe" and IsEntityInFront or nil
        inst.HarvestPickable = name == "scythe" and HarvestPickable or nil
        inst:ListenForEvent("ondropped", OnDropped)

        if name == "scythe" then
            local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
            inst.AnimState:SetFrame(frame)
            inst.fx = SpawnPrefab("shadow_scythe_fx")
            inst.fx.AnimState:SetFrame(frame)
            SetFxOwner(inst, nil)
        end
        MakeHauntableLaunch(inst)
        return inst
    end

    return Prefab("shadow_"..name, fn, assets, prefabs)
end

--------------------------------------------------------------------------

local FX_DEFS =
{
    { anim = "swap_loop_1", frame_begin = 0, frame_end = 2 },
    --{ anim = "swap_loop_3", frame_begin = 2 },
    { anim = "swap_loop_6", frame_begin = 5 },
    { anim = "swap_loop_7", frame_begin = 6 },
    { anim = "swap_loop_8", frame_begin = 7 },
}

local function CreateFxFollowFrame()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()

    inst:AddTag("FX")

    inst.AnimState:SetBank("scythe_voidcloth")
    inst.AnimState:SetBuild("dark_scythe")

    inst:AddComponent("highlightchild")

    inst.persists = false

    return inst
end

local function FxRemoveAll(inst)
    for i = 1, #inst.fx do
        inst.fx[i]:Remove()
        inst.fx[i] = nil
    end
end

local function FxColourChanged(inst, r, g, b, a)
    for i = 1, #inst.fx do
        inst.fx[i].AnimState:SetAddColour(r, g, b, a)
    end
end

local function FxOnEquipToggle(inst)
    local owner = inst.equiptoggle:value() and inst.entity:GetParent() or nil
    if owner then
        if inst.fx == nil then
            inst.fx = {}
        end
        local frame = inst.AnimState:GetCurrentAnimationFrame()
        for i, v in ipairs(FX_DEFS) do
            local fx = inst.fx[i]
            if fx == nil then
                fx = CreateFxFollowFrame()
                fx.AnimState:PlayAnimation(v.anim, true)
                inst.fx[i] = fx
            end
            fx.entity:SetParent(owner.entity)
            fx.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, v.frame_begin, v.frame_end)
            fx.AnimState:SetFrame(frame)
            fx.components.highlightchild:SetOwner(owner)
        end
        inst.components.colouraddersync:SetColourChangedFn(FxColourChanged)
        inst.OnRemoveEntity = FxRemoveAll
    elseif inst.OnRemoveEntity then
        inst.OnRemoveEntity = nil
        inst.components.colouraddersync:SetColourChangedFn(nil)
        FxRemoveAll(inst)
    end
end

local function FxToggleEquipped(inst, equipped)
    if equipped ~= inst.equiptoggle:value() then
        inst.equiptoggle:set(equipped)
        if not TheNet:IsDedicated() then
            FxOnEquipToggle(inst)
        end
    end
end

local function FollowSymbolScytheFxFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("scythe_voidcloth")
    inst.AnimState:SetBuild("dark_scythe")
    inst.AnimState:PlayAnimation("swap_loop_3", true)

    inst:AddComponent("highlightchild")
    inst:AddComponent("colouraddersync")

    inst.equiptoggle = net_bool(inst.GUID, "shadow_scythe_fx.equiptoggle", "equiptoggledirty")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst:ListenForEvent("equiptoggledirty", FxOnEquipToggle)
        return inst
    end

    inst.ToggleEquipped = FxToggleEquipped
    inst.persists = false

    return inst
end

return 
MakeTools("axe", "dark_axe", "axe", "idle", false, {"sharp", "possessable_axe"}, ACTIONS.CHOP),
MakeTools("hammer", "dark_swap_hammer", "hammer", "idle", true, {"hammer"}, ACTIONS.HAMMER),
MakeTools("pickaxe", "dark_pickaxe", "pickaxe", "idle", false, {"sharp"}, ACTIONS.MINE),
MakeTools("shovel", "dark_shovel", "shovel", "idle", false, nil, ACTIONS.DIG),
MakeTools("pitchfork", "dark_pitchfork", "pitchfork", "idle", false, { "sharp" }, ACTIONS.DIG),
MakeTools("oar", "dark_oar", "oar", "idle", false, {"allow_action_on_impassable"}, nil),
MakeTools("scythe", "dark_scythe", "scythe", "idle", true, {"sharp"}, ACTIONS.SCYTHE, "scythe_voidcloth"),
Prefab("shadow_scythe_fx", FollowSymbolScytheFxFn)
