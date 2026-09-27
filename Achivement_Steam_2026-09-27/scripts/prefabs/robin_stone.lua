local assets =
{
    Asset("ANIM", "anim/ro_bin_gem.zip"),
    Asset("ATLAS", "images/inventoryimages/robin_stone.xml"),
    Asset("ATLAS", "images/inventoryimages/robin_stone_death.xml"),
}

local function OnRoBinDeath(inst)
    inst.AnimState:PlayAnimation("dead", true)
    inst.components.inventoryitem.atlasname = "images/inventoryimages/robin_stone_death.xml"
    inst.components.inventoryitem:ChangeImageName(inst.closedEye)
end

local function GetRobin(inst)
    if TheWorld.components.robinregistry then
        return TheWorld.components.robinregistry:GetRobin(inst._id)
    end
    return nil
end

local function RebindRoBin(inst)
    local ro_bin = inst.ro_bin or GetRobin(inst)
    if ro_bin then
        inst.AnimState:PlayAnimation("idle_loop", true)
        inst.components.inventoryitem.atlasname = "images/inventoryimages/robin_stone.xml"
        inst.components.inventoryitem:ChangeImageName(inst.openEye)
        if ro_bin.components.follower.leader ~= inst then
            ro_bin.components.follower:SetLeader(inst)
        end
        if ro_bin.SetStone then
            ro_bin:SetStone(inst)
        end
        inst:ListenForEvent("death", function() inst:OnRoBinDeath() end, ro_bin)
        inst.ro_bin = ro_bin
        return true
    end
    inst.ro_bin = nil
    inst:OnRoBinDeath()
    return inst.ro_bin
end

local function FixRoBin(inst)
    inst.fixtask = nil
    RebindRoBin(inst)
end

local function OnPutInInventory(inst)
    if not inst.fixtask then
        inst.fixtask = inst:DoTaskInTime(1, function() FixRoBin(inst) end)
    end
end

local function SetId(inst, id)
    inst._id = id
end

local function OnSave(inst, data)
    if inst._id then
        data._id = inst._id
    end
end

local function OnLoad(inst, data)
    if data and data._id then
        inst._id = data._id
    end
end

local function GetStatus(inst)
    if inst.respawntask then
        return "WAITING"
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("ro_bin_gizzard_stone")
    inst:AddTag("irreplaceable")
    inst:AddTag("nonpotatable")
    inst:AddTag("follower_leash")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("ro_bin_gem")
    inst.AnimState:SetBuild("ro_bin_gem")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/robin_stone.xml"
    inst.components.inventoryitem.imagename = "robin_stone"
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    inst.components.inspectable:RecordViews()

    inst:AddComponent("leader")
    inst:AddComponent("tradable")

    inst.SetId = SetId
    inst.OnLoad = OnLoad
    inst.OnSave = OnSave
    inst.OnRoBinDeath = OnRoBinDeath
    inst._id = nil
    inst.ro_bin = nil
    inst.openEye = "robin_stone"
    inst.closedEye = "robin_stone_death"

    inst.fixtask = inst:DoTaskInTime(0.5, function() RebindRoBin(inst) end)

    return inst
end

return Prefab("chasni_robin_stone", fn, assets)