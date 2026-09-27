local assets =
{
    Asset("ANIM", "anim/roc_egg.zip"),
    Asset("ATLAS", "images/inventoryimages/robin_egg.xml"),
    Asset("ATLAS", "images/inventoryimages/robin_egg_cold.xml"),
    Asset("ATLAS", "images/inventoryimages/robin_egg_hot.xml"),
}

local prefabs =
{
    "chasni_robin_stone",
    "spoiled_food",
}

local ROBIN_HATCH_TIME = 60
local function GenerateId()
    local id = math.random()
    if TheWorld.components.robinregistry then
        if (TheWorld.components.robinregistry:GetRobin(id)) then
            return GenerateId()
        end
    end
    return id
end

local function PlaySound(inst, sound)
    inst.SoundEmitter:PlaySound(sound)
end
local function Hatch(inst)
    inst.components.inventoryitem.canbepickedup = false
    inst.AnimState:PlayAnimation("hatch")

    inst:DoTaskInTime(34 * FRAMES, PlaySound, "dontstarve/creatures/together/lavae/egg_bounce")
    inst:DoTaskInTime(44 * FRAMES, PlaySound, "dontstarve/creatures/together/lavae/egg_hatch")
    inst:ListenForEvent("animover", function(inst, data)
        local _id = GenerateId()

        local stone = SpawnPrefab("chasni_robin_stone")
        if stone.SetId then
            stone:SetId(_id)
        end
        local ro_bin = SpawnPrefab("chasni_ro_bin")
        if ro_bin.SetId then
            ro_bin:SetId(_id)
        end

        local pt = Point(inst.Transform:GetWorldPosition())
        local down = TheCamera:GetDownVec()
        local angle = math.atan2(down.z, down.x) + (math.random()*60-30) * DEGREES
        local speed = 3
        stone.Transform:SetPosition(pt.x,pt.y,pt.z)
        ro_bin.Transform:SetPosition(pt.x,pt.y,pt.z)
        stone.Physics:SetVel(speed*math.cos(angle), GetRandomWithVariance(8, 4), speed*math.sin(angle))
        inst:Remove()
    end)
end

local function CheckHatch(inst)
    if inst.components.playerprox and
            inst.components.playerprox:IsPlayerClose() and
            inst.components.hatchable.state == "hatch" and
            not inst.components.inventoryitem:IsHeld() then
        local posx, _, posz = inst.Transform:GetWorldPosition()
        if TheWorld.Map:IsVisualGroundAtPoint(posx, 0, posz) then
            Hatch(inst)
        end
    end
end

local function PlayUncomfySound(inst)
    inst.SoundEmitter:KillSound("uncomfy")
    if inst.components.hatchable.toohot then
        inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hot_steam_LP", "uncomfy")
    elseif inst.components.hatchable.toocold then
        inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_cold_shiver_LP", "uncomfy")
    end
end

local function OnNear(inst)
    inst.playernear = true
    CheckHatch(inst)
end

local function OnFar(inst)
    inst.playernear = false
end

local function OnPutInInventory(inst)
    inst.components.hatchable:StopUpdating()
    inst.SoundEmitter:KillSound("uncomfy")
end

local function GetStatus(inst)
    if inst.components.hatchable then
        local state = inst.components.hatchable.state
        return (state == "uncomfy" and "COLD")
                or (state == "comfy" and "COMFY")
                or "GENERIC"
    end
end

local function OnHatchState(inst, state)
    inst.SoundEmitter:KillSound("uncomfy")
    if state == "uncomfy" then
        if inst.components.hatchable.toohot then
            inst.AnimState:PlayAnimation("idle_hot_smoulder", true)
        elseif inst.components.hatchable.toocold then
            inst.AnimState:PlayAnimation("idle_cold_frost", true)
        end
        PlayUncomfySound(inst)
    elseif state == "comfy" then
        inst.AnimState:PlayAnimation("idle", true)
    elseif state == "hatch" then
        CheckHatch(inst)
    end
end

local function OnDropped(inst)
    inst.components.hatchable:StartUpdating()
    CheckHatch(inst)
    PlayUncomfySound(inst)
end

local function commonfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBuild("roc_egg")
    inst.AnimState:SetBank("roc_egg")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("ro_bin_egg")
    inst:AddTag("aquatic")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(true)
    inst.components.inventoryitem.atlasname = "images/inventoryimages/robin_egg.xml"
    inst.components.inventoryitem.imagename = "robin_egg"
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(4, 6)
    inst.components.playerprox:SetOnPlayerNear(OnNear)
    inst.components.playerprox:SetOnPlayerFar(OnFar)

    inst:AddComponent("hatchable")
    inst.components.hatchable:SetOnState(OnHatchState)
    inst.components.hatchable:SetCrackTime(10)
    inst.components.hatchable:SetHatchTime(ROBIN_HATCH_TIME)
    inst.components.hatchable:SetHatchFailTime(60)
    inst.components.hatchable:SetHeaterPrefs(false, nil, true)
    inst.components.hatchable:StartUpdating()

    inst.hatch = Hatch
    inst.playernear = false

    return inst
end

return Prefab("chasni_robin_egg", commonfn, assets, prefabs)
