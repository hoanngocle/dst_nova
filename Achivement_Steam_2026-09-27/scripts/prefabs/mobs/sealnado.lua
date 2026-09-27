local brain = require("brains/chasni_sealnadobrain")

local assets =
{
    Asset("ANIM", "anim/twister_build.zip"),
    Asset("ANIM", "anim/twister_basic.zip"),
    Asset("ANIM", "anim/twister_actions.zip"),
    Asset("ANIM", "anim/twister_seal.zip"),
}

local prefabs =
{
    "nightmarefuel",
}

SetSharedLootTable("chasni_sealnado", {
    {"staff_tornado",   1.00},
})

local HEALTH = chasni_getmobconfig("chasni_sealnado", "HP") or 17775
local DAMAGE = chasni_getmobconfig("chasni_sealnado", "DMG") or 51
local DAMAGE_MULT = chasni_getmobconfig("chasni_sealnado", "DMGM") or 0.1
local ATTACK_PERIOD = 3
local MELEE_RANGE = 6
local ATTACK_RANGE = 6
local SPEED = 5
local RETARGET_PERIOD = 3
local RETARGET_RANGE = 25
local RETARGET_MUST_TAGS = { "character", "_combat" }
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 40
local SHARETARGET_MAX = 40
local function CalcSanityAura(inst)
    if inst.components.combat.target then
        return -TUNING.SANITYAURA_HUGE
    end

    return -TUNING.SANITYAURA_LARGE
end

local function RetargetFn(inst)
    return chasni_basicretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, chasni_TAG_NOATTACK)
end

local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "seal", SHARETARGET_MAX)
end

local function Vacuuming(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 14 * inst.Transform:GetScale(), nil, chasni_TAG_NOTARGET)
    for _, v in ipairs(ents) do
        local px, py, pz = v.Transform:GetWorldPosition()
        local rad = math.rad(v:GetAngleToPoint(x, y, z))
        local velx = math.cos(rad)
        local velz = -math.sin(rad)

        local m = math.clamp(inst:GetDistanceSqToPoint(px, py, pz) * inst.Transform:GetScale() / 50, 6, 30)
        local dx, dy, dz = px + (((FRAMES * 18) * velx) / m) * inst.Transform:GetScale(), py, pz + (((FRAMES * 18) * velz) / m) * inst.Transform:GetScale()

        local ground = TheWorld.Map:IsPassableAtPoint(dx, dy, dz)
        local boat = TheWorld.Map:GetPlatformAtPoint(dx, dz)
        local ocean = TheWorld.Map:IsOceanAtPoint(dx, dy, dz)
        if v and v.components.locomotor and dx and (ground or boat or ocean and v.components.locomotor:CanPathfindOnWater()) then
            v.Transform:SetPosition(dx, dy, dz)
        end

        if v and v.Physics and v.components.inventoryitem and not v.components.inventoryitem:IsHeld() and v.replica.inventoryitem:CanBePickedUp() then
            v.Physics:Teleport(px, .1, pz)
            local dir =  v:GetPosition() - inst:GetPosition()
            local angle = math.atan2(-dir.z, -dir.x)
            v.Physics:SetVel(math.cos(angle) * 20, 0, math.sin(angle) * 20)
        end
    end

    local collideents = TheSim:FindEntities(x, y, z, 2, nil, chasni_TAG_NOTARGET)
    for _, v in pairs(collideents) do
        if v and v:IsValid() and not inst.recentlycharged[v] then
            if v.components.inventoryitem and not v.components.inventoryitem:IsHeld() and v.replica.inventoryitem:CanBePickedUp() then
                inst.components.inventory:GiveItem(v)
            elseif v.components.health and not v.components.health:IsDead() then
                inst.components.combat:DoAttack(v)
                inst.recentlycharged[v] = true
                inst:DoTaskInTime(1, function() inst.recentlycharged[v] = nil end)
            end
        end
    end
end

local function StopVacuum(inst)
    if inst.VacuumTask then
        inst.VacuumTask:Cancel()
        inst.VacuumTask = nil
    end
    local filledinventory = 0
    inst.components.inventory:ForEachItemSlot(function(item)
        if item then
            filledinventory = filledinventory + 1
        end
    end)
    inst.components.combat.externaldamagemultipliers:SetModifier("sealnado_inventorymult", 1 + (DAMAGE_MULT * filledinventory))
end

local function DoVacuum(inst)
    StopVacuum(inst)
    inst.VacuumTask = inst:DoPeriodicTask(FRAMES, Vacuuming)
end

local function OnSave(inst, data)
    data.CanVacuum = inst.CanVacuum
    data.CanCharge = inst.CanCharge
end

local function OnLoad(inst, data)
    if data then
        inst.CanVacuum = data.CanVacuum
        inst.CanCharge = data.CanCharge
    end
end

local function ontimerdone(inst, data)
    if data.name == "Vacuum" then
        inst.CanVacuum = true
    elseif data.name == "Charge" then
        inst.CanCharge = true
    end
end

local function OnHitOther(inst, data)
    if data.target then
        inst.components.thief:StealItem(data.target)
        inst.components.thief:StealItem(data.target)
        inst.components.thief:StealItem(data.target)
        inst.components.thief:StealItem(data.target)
        inst.components.thief:StealItem(data.target)
        inst.components.thief:StealItem(data.target)
        inst.components.thief:StealItem(data.target)
        inst.components.thief:StealItem(data.target)
        inst.components.thief:StealItem(data.target)
        inst.components.thief:StealItem(data.target)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    inst.DynamicShadow:SetSize(6, 3.5)
    MakeFlyingCharacterPhysics(inst, 1000, .5)

    inst:AddTag("amphibious")
    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("seal")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")

    inst.AnimState:SetBank("twister")
    inst.AnimState:SetBuild("twister_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE, MELEE_RANGE)
    inst.components.combat:SetAreaDamage(MELEE_RANGE, 1)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)
    inst.components.health.destroytime = 5

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 8
    inst.components.locomotor.pathcaps = { allowocean = true }

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_sealnado")

    inst:AddComponent("thief")
    inst:AddComponent("timer")
    inst:AddComponent("inventory")
    inst.components.inventory.maxslots = 100

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:SetStateGraph("SGCZsealnado")
    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("timerdone", ontimerdone)
    inst:ListenForEvent("onhitother", OnHitOther)

    inst.CanVacuum = true
    inst.CanCharge = true
    inst.DoVacuum = DoVacuum
    inst.StopVacuum = StopVacuum
    inst.VacuumTask = nil
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.recentlycharged = {}

    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_sealnado/twister_active", "wind_loop")
    inst.SoundEmitter:SetParameter("wind_loop", "intensity", 0)

    inst.AnimState:Hide("twister_water_fx")

    return inst
end

return Prefab("chasni_sealnado", fn, assets, prefabs)
