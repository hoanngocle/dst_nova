local assets =
{
    Asset("ANIM", "anim/nature_staff.zip"),
    Asset("ANIM", "anim/swap_nature_staff.zip"),
    Asset("ATLAS", "images/inventoryimages/nature_staff.xml")
}

local assets_flowers =
{
    Asset("ANIM", "anim/lavaarena_heal_flowers_fx.zip"),
}

local prefabs =
{
    "nature_staff_circle",
}

local prefabs_circle =
{
    "nature_staff_circle_overlay",
}

local USES = chasni_getitemconfig("nature_staff", "USE") or 500
local DAMAGE = chasni_getitemconfig("nature_staff", "DMG") or 10
local COOLDOWN = chasni_getitemconfig("nature_staff", "CD") or 80
local MAX_DURATION = chasni_getitemconfig("nature_staff", "DUR") or 45
local BASE_DURATION = chasni_getitemconfig("nature_staff", "BDUR") or 5
local REPAIR_SPEED = chasni_getitemconfig("nature_staff", "REP") or 10
local REPAIR_RANGE = chasni_getitemconfig("nature_staff", "REPR") or 8
local function rechargeperiodic(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local plants = TheSim:FindEntities(x, y, z, REPAIR_RANGE, {"plant"}, chasni_TAG_NOTARGET)
    local repairspeed = #plants * 1
    repairspeed = math.min(repairspeed, REPAIR_SPEED)
    if TheWorld.Map:IsInLunacyArea(inst.Transform:GetWorldPosition()) then
        repairspeed = REPAIR_SPEED * 2
    end

    inst.components.finiteuses:Repair(repairspeed)
end
local function OnEquip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_nature_staff", "swap_object")
    inst._rechargetask = inst:DoPeriodicTask(1, rechargeperiodic)

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function OnUnequip(inst, owner)
    if inst._rechargetask then
        inst._rechargetask:Cancel()
        inst._rechargetask = nil
    end

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function summonHeal(inst, target, pos)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and chasni_hastag(inst, owner) then
        local percent = inst.components.finiteuses:GetPercent()
        inst.components.rechargeable:Discharge(COOLDOWN)
        inst.components.finiteuses:Use(USES)
        for k, v in ipairs(AllPlayers) do
            local p = v:GetPosition()
            local healingcircle = chasni_spawnprefab("nature_staff_circle", p.x, p.y, p.z)
            healingcircle.components.timer:StartTimer("healingdone", BASE_DURATION + (MAX_DURATION * percent))
        end
    else
        owner.components.talker:Say(GetString(owner, "NATURE_STAFF_FAIL_1"))
    end
end

local function OnCharged(inst)
    inst.components.spellcaster:SetSpellFn(summonHeal)
end

local function OnDischarged(inst)
    inst.components.spellcaster:SetSpellFn(nil)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("nature_staff")
    inst.AnimState:SetBuild("nature_staff")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst:AddTag("rechargeable")
    inst:AddTag("charges_percentage")

    inst._restrictedtag = "expertworm1"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DAMAGE)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)

    inst.castsound = "dontstarve/common/lava_arena/spell/heal"

    inst:AddComponent("inspectable")
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "nature_staff"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/nature_staff.xml"

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canusefrominventory = true
    inst.components.spellcaster:SetSpellFn(summonHeal)

    return inst
end

local FADE_INTENSITY = .8
local FADE_RADIUS = 1
local FADE_FALLOFF = .5
local HEAL = 5
local RADIUS = 3.5
local TICK = 1
local function OnTimerDone(inst, data)
    if data.name == "healingdone" then
        for k, v in pairs(inst.blooms) do
            if v.RemoveOverlay then
                v.RemoveOverlay(v)
            end
        end
        inst:Remove()
    end
end

local function fncircle()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Light:SetFalloff(FADE_FALLOFF)
    inst.Light:SetIntensity(FADE_INTENSITY)
    inst.Light:SetRadius(FADE_RADIUS)
    inst.Light:SetColour(75 / 255, 255 / 255, 50 / 255)
    inst.Light:Enable(false)
    inst.Light:EnableClientModulation(true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aura")
    inst.components.aura.radius = RADIUS
    inst.components.aura.tickperiod = TICK
    inst.components.aura.healing = HEAL
    inst.components.aura.auraname = "nature"
    inst.components.aura:Enable(true)

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)

    inst:DoTaskInTime(.1, function()
        local prefabname = "nature_staff_circle_overlay"
        for i = 1, 15 do
            local pos = inst:GetPosition()
            if i == 1 then
                inst:DoTaskInTime(math.random(), function()
                    local bloom = chasni_spawnprefab(prefabname, pos.x, pos.y, pos.z)
                    table.insert(inst.blooms, bloom)
                end)
            elseif i >= 2 and i < 7 then
                local theta = (i - 1) / 5 * 2 * PI
                local offset = FindWalkableOffset(pos, theta, RADIUS / 2, 2, true, true)
                if offset then
                    offset.x = offset.x + pos.x
                    offset.z = offset.z + pos.z
                    inst:DoTaskInTime(math.random(), function()
                        local bloom = chasni_spawnprefab(prefabname, offset.x, 0, offset.z)
                        table.insert(inst.blooms, bloom)
                    end)
                end
            elseif i >= 7 then
                local theta = (i - 5) / 9 * 2 * PI
                local offset = FindWalkableOffset(pos, theta, RADIUS, 2, true, true)
                if offset then
                    offset.x = offset.x + pos.x
                    offset.z = offset.z + pos.z
                    inst:DoTaskInTime(math.random(), function()
                        local bloom = chasni_spawnprefab(prefabname, offset.x, 0, offset.z)
                        table.insert(inst.blooms, bloom)
                    end)
                end
            end
        end
    end)
    inst.OnLoad = OnTimerDone
    inst.blooms = {}
    return inst
end

local function removeOverlay(inst)
    inst:DoTaskInTime(math.random(), function()
        inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds", "flower_sound")
        inst.SoundEmitter:SetVolume("flower_sound", .25)
        inst.AnimState:PushAnimation("out_" .. inst.variation, false)
        inst:ListenForEvent("animover", inst.Remove)
    end)
end
local function overlayfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("lavaarena_heal_flowers")
    inst.AnimState:SetBuild("lavaarena_heal_flowers_fx")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.variation = math.random(6)
    inst.AnimState:PlayAnimation("in_" .. inst.variation)
    inst.AnimState:PushAnimation("idle_" .. inst.variation)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds", "flower_sound")
    inst.SoundEmitter:SetVolume("flower_sound", .25)

    inst.persists = false
    inst.OnLoad = removeOverlay
    inst.RemoveOverlay = removeOverlay

    return inst
end

return Prefab("nature_staff", fn, assets, prefabs), 
Prefab("nature_staff_circle", fncircle, {}, prefabs_circle),
Prefab("nature_staff_circle_overlay", overlayfn, assets_flowers)
