require "functions/helperfunctions"

local assets =
{
    Asset("ANIM", "anim/fire_hat.zip"),
    Asset("ATLAS", "images/inventoryimages/fire_hat.xml"),
}

local prefabs =
{
    "firesplash_fx",
    "fire_hat_fx",
}

local ARMOR = chasni_getitemconfig("fire_hat", "ARM") or 0.7
local BURN_RADIUS = chasni_getitemconfig("fire_hat", "BRR") or 3
local IGNITE_RADIUS = chasni_getitemconfig("fire_hat", "IGR") or 10
local IGNITE_INTERVAL = chasni_getitemconfig("fire_hat", "IGI") or 22
local function aoeIgnite(inst, rad, count)
    local pos = Vector3(inst.Transform:GetWorldPosition())
    chasni_spawnprefab("firesplash_fx", pos.x, pos.y, pos.z)
    local targets = TheSim:FindEntities(pos.x, pos.y, pos.z, rad, nil, chasni_TAG_NOATTACK)
    for k, target in pairs(targets) do
        if target and target ~= inst and target.components.burnable and not target:HasTag("burnt") and target.components.fueled == nil then
            target.components.burnable:Ignite(true, inst, inst)
            if count then
                count = count - 1
                if count <= 0 then
                    break
                end
            end
        end
    end
end

local function onattacked(inst, data)
    if (data and data.attacker and not data.redirected) then
        if data.attacker.components.combat
                and (data.attacker.components.health and not data.attacker.components.health:IsDead())
                and (data.attacker.components.inventory == nil or not data.attacker.components.inventory:IsInsulated())
                and (data.weapon == nil or (data.weapon.components.projectile == nil and (data.weapon.components.weapon == nil or data.weapon.components.weapon.projectile == nil))
        ) then
            aoeIgnite(inst, BURN_RADIUS)
        end
    end
end

local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "fire_hat", "swap_hat")
    chasni_hatswapequip(owner)
    if inst.fx then
        inst.fx:Remove()
    end
    inst.fx = SpawnPrefab("fire_hat_fx")
    inst.fx:AttachToOwner(owner)

    owner:ListenForEvent("blocked", onattacked)
    owner:ListenForEvent("attacked", onattacked)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.task = inst:DoPeriodicTask(IGNITE_INTERVAL, function()
        local chance = math.random(-6, 10)
        if chance >= 1 then
            if inst.doanim then
                inst.doanim(false)
                inst.doanim(true)
            end
            inst:DoTaskInTime(0.5, function()
                aoeIgnite(owner, IGNITE_RADIUS, chance + 5)
            end)
        end
    end)
end

local function onunequip(inst, owner)
    chasni_hatswapunequip(owner)
    if inst.fx then
        inst.fx:Remove()
        inst.fx = nil
    end

    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    owner:RemoveEventCallback("blocked", onattacked)
    owner:RemoveEventCallback("attacked", onattacked)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("fire_hat")
    inst.AnimState:SetBuild("fire_hat")
    inst.AnimState:PlayAnimation("anim", true)

    inst:AddTag("hat")
    inst:AddTag("hide_percentage")

    inst._restrictedtag = "expertwillow3"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("armor")
    inst.components.armor:InitIndestructible(ARMOR)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "fire_hat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/fire_hat.xml"

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES.EXPERTWILLOW3)

    inst.doanim = function(off)
        if inst.fx then
            inst.fx.doanim:set(off)
        end
    end

    inst.task = nil
    return inst
end

local function CreateFxFollowFrame(i)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()

    inst:AddTag("FX")

    inst.AnimState:SetBank("fire_hat")
    inst.AnimState:SetBuild("fire_hat")
    inst.anim = "idle"..tostring(i)
    inst.AnimState:PlayAnimation(inst.anim, true)

    inst:AddComponent("highlightchild")

    inst.persists = false

    return inst
end

-- COMMON FUNCTIONS
local function FollowFx_OnRemoveEntity(inst)
    for i, v in ipairs(inst.fx) do
        v:Remove()
    end
end

local function FollowFx_ColourChanged(inst, r, g, b, a)
    for i, v in ipairs(inst.fx) do
        v.AnimState:SetAddColour(r, g, b, a)
    end
end

local function SpawnFollowFxForOwner(inst, owner, createfn, framebegin, frameend, isfullhelm)
    local follow_symbol = isfullhelm and owner:HasTag("player") and owner.AnimState:BuildHasSymbol("headbase_hat") and "headbase_hat" or "swap_hat"
    inst.fx = {}
    local frame
    for i = framebegin, frameend do
        local fx = createfn(i)
        frame = frame or math.random(fx.AnimState:GetCurrentAnimationNumFrames()) - 1
        fx.entity:SetParent(owner.entity)
        fx.Follower:FollowSymbol(owner.GUID, follow_symbol, nil, nil, nil, true, nil, i - 1)
        fx.AnimState:SetFrame(frame)
        fx.components.highlightchild:SetOwner(owner)
        table.insert(inst.fx, fx)
    end
    inst.components.colouraddersync:SetColourChangedFn(FollowFx_ColourChanged)
    inst.OnRemoveEntity = FollowFx_OnRemoveEntity
end

local function OnEntityReplicated(inst)
    local owner = inst.entity:GetParent()
    if owner then
        SpawnFollowFxForOwner(inst, owner, inst._hatfxcreatefn, inst._hatfxframebegin, inst._hatfxframeend, inst._hatfxisfullhelm)
    end
end

local function AttachToOwner(inst, owner)
    inst.entity:SetParent(owner.entity)
    if owner.components.colouradder then
        owner.components.colouradder:AttachChild(inst)
    end
    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        SpawnFollowFxForOwner(inst, owner, inst._hatfxcreatefn, inst._hatfxframebegin, inst._hatfxframeend, inst._hatfxisfullhelm)
    end
end
-- END OF : COMMON FUNCTIONS

local function fire_hat_fx_buffeddirty(inst)
    if inst.fx ~= nil then
        if inst.doanim:value() then
            for i, v in ipairs(inst.fx) do
                local anim = v.anim.."_powerup"
                v.AnimState:PlayAnimation(anim)
                v.AnimState:PushAnimation(v.anim, true)
            end
        end
    end
end

local function fxfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst:AddComponent("colouraddersync")
    inst._hatfxcreatefn = CreateFxFollowFrame
    inst._hatfxframebegin = 1
    inst._hatfxframeend = 3
    inst._hatfxisfullhelm = false

    inst.doanim = net_bool(inst.GUID, "fire_hat_fx.doanim", "doanimdirty")
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("doanimdirty", fire_hat_fx_buffeddirty)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnEntityReplicated
        return inst
    end

    inst.AttachToOwner = AttachToOwner
    inst.persists = false

    return inst
end

return 
Prefab("fire_hat", fn, assets, prefabs), 
Prefab("fire_hat_fx", fxfn, assets)
