local assets =
{
    Asset("ANIM", "anim/pakun.zip"),
    Asset("ATLAS", "images/inventoryimages/pakun.xml"),
}

local RADIUS = 1.5
local DAMAGE = 80
local RESET_TIME = 10
local RESET_VARIANCE = 5
local UP_TIME = 0.1
local MINE_TEST_TAG = { "monster", "character", "animal" }
local MINE_MUST_TAGS = { "_combat" }
local MINE_NO_TAGS = { "notraptrigger", "flying", "ghost", "playerghost", "player" }
local function OnAnimOver(inst)
    if inst.components.mine.issprung then return end
    inst.AnimState:PushAnimation("idle", true)
end

local  function hitfn(target, inst)
    return not (target.components.health and target.components.health:IsDead()) and (target.components.combat and target.components.combat:CanBeAttacked(inst))
end

local function doSnap(inst)
    inst.SoundEmitter:PlaySound("turnoftides/creatures/together/starfishtrap/trap", nil, 0.8)

    local x, y, z = inst.Transform:GetWorldPosition()
    local target_ents = TheSim:FindEntities(x, y, z, RADIUS, MINE_MUST_TAGS, MINE_NO_TAGS, MINE_TEST_TAG)
    for i, target in ipairs(target_ents) do
        if target ~= inst and target.entity:IsVisible() and hitfn(target, inst) and not chasni_friendpet(target) then
            local dmg = target:HasTag("smallcreature") and target.components.health and target.components.health.currenthealth or DAMAGE
            target.components.combat:GetAttacked(inst, dmg)
            target.components.locomotor:SetExternalSpeedMultiplier(target, "trap_flytrap", 0)
            target:AddDebuff("wormwood_vined_debuff", "wormwood_vined_debuff")
            target:DoTaskInTime(6, function()
                target.components.locomotor:RemoveExternalSpeedMultiplier(target, "trap_flytrap")
            end)
        end
    end

    if inst._snap_task then
        inst._snap_task:Cancel()
        inst._snap_task = nil
    end
end

local function reset(inst)
    inst.components.mine:Reset()
end

local function start_reset_task(inst)
    if inst._reset_task then
        inst._reset_task:Cancel()
    end
    local reset_task_randomized_time = GetRandomWithVariance(RESET_TIME, RESET_VARIANCE)
    inst._reset_task = inst:DoTaskInTime(reset_task_randomized_time, reset)
    inst._reset_task_end_time = GetTime() + reset_task_randomized_time
end

local function OnExplode(inst, target)
    inst.AnimState:PlayAnimation("trap")
    inst.AnimState:PushAnimation("trap_idle", true)

    inst:RemoveEventCallback("animover", OnAnimOver)

    if target and inst._snap_task == nil then
        local frames_until_anim_snap = 8
        inst._snap_task = inst:DoTaskInTime(frames_until_anim_snap * FRAMES, doSnap)
    end

    start_reset_task(inst)
end

local function OnReset(inst)
    inst:ListenForEvent("animover", OnAnimOver)

    if inst.AnimState:IsCurrentAnimation("trap_idle") then
        inst.AnimState:PlayAnimation("reset")
        inst.SoundEmitter:PlaySound("turnoftides/creatures/together/starfishtrap/idle")
        inst.AnimState:PushAnimation("idle", true)
    end
end

local function OnSprung(inst)
    inst.AnimState:PlayAnimation("trap_idle", true)
    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
    inst:RemoveEventCallback("animover", OnAnimOver)

    start_reset_task(inst)
end

local function OnDeactivate(inst)
    if inst.components.lootdropper then
        inst.components.lootdropper:SpawnLootPrefab("dug_trap_flytrap")
    end

    inst:Remove()
end

local function get_status(inst)
    return (inst.components.mine.issprung and "CLOSED") or nil
end

local function OnDug(inst, digger)
    OnDeactivate(inst)
end

local function CalculateResetTime()
    return UP_TIME
end

local function on_save(inst, data)
    if inst._reset_task then
        local remaining_task_time = inst._reset_task_end_time - GetTime()
        if remaining_task_time >= 0 then
            data.reset_task_time_remaining = remaining_task_time
        end
    end
end

local function on_load(inst, data)
    if data and data.reset_task_time_remaining then
        if inst._reset_task then
            inst._reset_task:Cancel()
        end

        inst._reset_task = inst:DoTaskInTime(data.reset_task_time_remaining, reset)
        inst._reset_task_end_time = GetTime() + data.reset_task_time_remaining
    end
end

local function trap_flytrap()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("pakun")
    inst.AnimState:SetBuild("pakun")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("trap")
    inst:AddTag("trapdamage")
    inst:AddTag("birdblocker")
    inst:AddTag("wet")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "TRAP_FLYTRAP"
    inst.components.inspectable.getstatus = get_status

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnDug)
    inst.components.workable:SetWorkable(true)

    inst:AddComponent("hauntable")
    inst.components.hauntable.hauntvalue = TUNING.HAUNT_TINY

    inst:AddComponent("mine")
    inst.components.mine:SetRadius(RADIUS)
    inst.components.mine:SetAlignment("player")
    inst.components.mine:SetOnExplodeFn(OnExplode)
    inst.components.mine:SetOnResetFn(OnReset)
    inst.components.mine:SetOnSprungFn(OnSprung)
    inst.components.mine:SetOnDeactivateFn(OnDeactivate)
    inst.components.mine:SetTestTimeFn(CalculateResetTime)
    inst.components.mine:SetReusable(false)
    reset(inst)

    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

    inst:ListenForEvent("animover", OnAnimOver)

    inst.OnSave = on_save
    inst.OnLoad = on_load

    return inst
end

local function OnDeploy(inst, position, deployer)
    local new_trap_flytrap = SpawnPrefab("trap_flytrap")
    if new_trap_flytrap then
        new_trap_flytrap.AnimState:PlayAnimation("trap_idle")
        new_trap_flytrap.components.mine:Spring()

        new_trap_flytrap.Transform:SetPosition(position:Get())
        new_trap_flytrap.SoundEmitter:PlaySound("dontstarve/common/plant")

        inst:Remove()
    end
end

local function dug_trap_flytrap()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med")

    inst.AnimState:SetBank("pakun")
    inst.AnimState:SetBuild("pakun")
    inst.AnimState:PlayAnimation("inactive", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "TRAP_FLYTRAP"

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "pakun"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/pakun.xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = OnDeploy

    return inst
end

return
Prefab("trap_flytrap", trap_flytrap, assets),
Prefab("dug_trap_flytrap", dug_trap_flytrap, assets),
MakePlacer("dug_trap_flytrap_placer", "pakun", "pakun", "trap_idle")
