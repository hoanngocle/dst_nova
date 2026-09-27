local assets =
{
    Asset("ATLAS", "images/inventoryimages/corkchest.xml"),
    Asset("IMAGE", "images/inventoryimages/corkchest.tex"),
    Asset("ANIM", "anim/treasure_chest_cork.zip"),
}
local prefabs =
{
    "collapse_small",
}

local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("open")
        inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_cork_chest/open")
    end
end

local function onclose(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("close")
        inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_cork_chest/close")
    end
end
local function onhammered(inst, worker)
    if inst.components.burnable and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container then
        inst.components.container:DropEverything()
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    chasni_spawnprefab("collapse_small", x, y, z)
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
        if inst.components.container then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_cork_chest/place")

    if TheWorld.components.crafterchestregistry and TheWorld.components.crafterchestregistry:TooMuch() then
        local x, y, z = inst.Transform:GetWorldPosition()
        local player = FindClosestPlayer(x, y, z)
        inst.components.lootdropper.GenerateLoot = function(...)
            return {}
        end
        inst.components.workable:Destroy(player)
        if player.components.talker then
            player.components.talker:Say(GetString(player, "CRAFTER_EXIST"))
        end
    end
end

local function onsave(inst, data)
    if inst.components.burnable and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data and data.burnt and inst.components.burnable then
        inst.components.burnable.onburnt(inst)
    end
end

local function ResetClientItem(inst)
    if not TheWorld.ismastersim then
        return
    end

    local container = inst.components.container or inst.components.inventory
    if container and not container.excludefromcrafting then
        local crafterchestitems = {}

        for k, v in pairs(container.slots) do
            if v and not v:HasTag("nocrafting") then
                local current = crafterchestitems[v.prefab] or 0
                if v.components.stackable then
                    crafterchestitems[v.prefab] = current + v.components.stackable:StackSize()
                else
                    crafterchestitems[v.prefab] = current + 1
                end
            end
        end

        local json = json.encode(crafterchestitems)
        inst.crafterchestitems = crafterchestitems
        inst.crafterchestitems_net:set(json)
    end

    for _, player in ipairs(AllPlayers) do
        if player then
            player:DoTaskInTime(0.5, function()
                SendModRPCToClient(GetClientModRPC("CrafterChest", "RefreshCrafting"), player)
            end)
        end
    end
end

local function RegisterPlayerCrafterChest(inst)
    for _, player in ipairs(AllPlayers) do
        if player.components.inventory then
            player.components.inventory:RegisterCrafterChest(inst)
        end
        if player.replica.inventory then
            player.replica.inventory:RegisterCrafterChest(inst)
        end
        player:PushEvent("refreshcrafting")
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.MiniMapEntity:SetIcon("corkchest.tex")

    inst.AnimState:SetBank("treasure_chest_cork")
    inst.AnimState:SetBuild("treasure_chest_cork")
    inst.AnimState:PlayAnimation("closed", true)

    inst:AddTag("structure")
    inst:AddTag("chest")

    MakeSnowCoveredPristine(inst)
    inst.crafterchestitems_net = net_string(inst.GUID, "container.crafterchestitems_net", "crafterchestitemsdirty")
    inst:ListenForEvent("crafterchestitemsdirty", function()
        local jsonData = inst.crafterchestitems_net:value()
        if jsonData and jsonData ~= "" then
            local decoded = json.decode(jsonData)
            if decoded then
                inst.crafterchestitems = decoded
            end
        end
    end)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst:DoPeriodicTask(2, RegisterPlayerCrafterChest)
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("crafterchest")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    MakeSmallBurnable(inst, nil, nil, true)
    MakeSmallPropagator(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:ListenForEvent("onbuilt", onbuilt)
    MakeSnowCovered(inst)

    if TheWorld.components.crafterchestregistry == nil then
        TheWorld:AddComponent("crafterchestregistry")
    end
    TheWorld.components.crafterchestregistry:Register(inst)

    inst:DoTaskInTime(1.5, function()
        ResetClientItem(inst)
    end)
    inst:ListenForEvent("itemget", ResetClientItem)
    inst:ListenForEvent("gotnewitem", ResetClientItem)
    inst:ListenForEvent("itemlose", ResetClientItem)
    inst:ListenForEvent("stacksizechange", ResetClientItem)
    inst:ListenForEvent("onclose", ResetClientItem)

    inst.entity:SetCanSleep(false)

    inst:DoPeriodicTask(2, RegisterPlayerCrafterChest)
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("crafterchest", fn, assets, prefabs),
MakePlacer("crafterchest_placer", "treasure_chest_cork", "treasure_chest_cork", "closed")