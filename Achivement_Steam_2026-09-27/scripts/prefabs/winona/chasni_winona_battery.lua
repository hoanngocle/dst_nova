local assets =
{
    Asset("ANIM", "anim/chasni_winona_battery.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_winona_battery_full.xml"),
    Asset("ATLAS", "images/inventoryimages/chasni_winona_battery_empty.xml"),
}

local MAX_FUEL = 100
local TICK = 1
local RECHARGE_TICK = 10
local RECHARGE_RATE = 1
local EXPERTWINONA1_RECHARGE_RATE = 8
local DRAIN_RATE = 1
local LAMP_DRAIN_RATE = 30
local function SharePower(inst)
    if inst.components.fueled:IsEmpty() then
        return
    end

    local pos = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, 6, {"engineeringbatterypowered"})
    for k,v in pairs(ents) do
        if not v._charged_by_battery and v.components.circuitnode and not v.components.circuitnode:IsConnected() and v.AddBatteryPower and not inst.components.fueled:IsEmpty() then
            v:AddBatteryPower(TICK + 0.05)
            inst.components.fueled:DoDelta(-DRAIN_RATE)
            v._charged_by_battery = true
            v:DoTaskInTime(TICK - 0.05, function()
                if v._charged_by_battery then
                    v._charged_by_battery = false
                end
            end)
        end
    end
    local lamps = TheSim:FindEntities(pos.x,pos.y,pos.z, 6, {"chasni_city_lamp"})
    for k,v in pairs(lamps) do
        if v.components.fueled:GetPercent() < 0.5 and not inst.components.fueled:IsEmpty() then
            v.components.fueled:DoDelta(v.components.fueled.maxfuel)
            inst.components.fueled:DoDelta(-LAMP_DRAIN_RATE)
        end
    end
end

local function Recharging(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    local owneriswinona = owner and owner.components.allachivcoin and owner.components.allachivcoin.expertwinona1
    if not inst.components.fueled:IsEmpty() or owneriswinona then
        local rechargerate = owneriswinona and EXPERTWINONA1_RECHARGE_RATE or RECHARGE_RATE
        inst.components.fueled:DoDelta(rechargerate)
    end
end

local function PercentChanged(inst, data)
    local isempty = inst.components.fueled:IsEmpty()
    local anim = isempty and "idle" or "idle_full"
    local atlas = isempty and "chasni_winona_battery_empty" or "chasni_winona_battery_full"
    inst.AnimState:PlayAnimation(anim, true)

    if inst.components.inventoryitem then
        inst.components.inventoryitem.imagename = atlas
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. atlas ..".xml"
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", nil, 0.7)

    inst.AnimState:SetBank("chasni_winona_battery")
    inst.AnimState:SetBuild("chasni_winona_battery")
    inst.AnimState:PlayAnimation("idle_full", true)

    inst.pickupsound = "metal"
    inst:AddTag("molebait")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("bait")
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_winona_battery_full"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_winona_battery_full.xml"

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(MAX_FUEL)
    inst.components.fueled.no_sewing = true

    inst:ListenForEvent("percentusedchange", PercentChanged)
    inst:DoTaskInTime(1, PercentChanged)

    inst:DoPeriodicTask(TICK, SharePower)
    inst:DoPeriodicTask(RECHARGE_TICK, Recharging)

    MakeHauntableLaunchAndSmash(inst)

    return inst
end

return Prefab("chasni_winona_battery", fn, assets)