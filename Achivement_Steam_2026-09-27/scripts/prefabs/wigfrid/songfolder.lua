local assets =
{
    Asset("ANIM", "anim/songfolder.zip"),
    Asset("ATLAS", "images/inventoryimages/songfolder.xml"),
}

local DAMAGE_MULT = chasni_getitemconfig("songfolder", "MULT") or 0.03
local function onburnt(inst)
    if inst.components.container then
        inst.components.container:DropEverything()
        inst.components.container:Close()
    end

    SpawnPrefab("ash").Transform:SetPosition(inst.Transform:GetWorldPosition())

    inst:Remove()
end

local function onignite(inst)
    if inst.components.container then
        inst.components.container.canbeopened = false
    end
end

local function onextinguish(inst)
    if inst.components.container then
        inst.components.container.canbeopened = true
    end
end

local function checkfull(inst)
    local owner
    if inst.components.inventoryitem then owner = inst.components.inventoryitem:GetGrandOwner() end
    if owner and owner.components.combat then
        local _, count = inst.components.container:HasItemWithTag("battlesong", 1)
        owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1 + count * DAMAGE_MULT)
        if count >= 8 then
            local songs = {}
            local unique = true
            for k,v in pairs(inst.components.container.slots) do
                if not songs[v.prefab] then
                    songs[v.prefab] = true
                else
                    unique = false
                    break
                end
            end
            if unique then
                inst:AddTag("fullfolder")
            else
                inst:RemoveTag("fullfolder")
            end
        else
            inst:RemoveTag("fullfolder")
        end
        inst.folderholder = owner
        inst:ListenForEvent("inspirationdelta", inst.ondelta, inst.folderholder)
    end
end

local function removebuff(inst)
    if inst.folderholder then
        inst.folderholder.components.combat.externaldamagemultipliers:RemoveModifier(inst)
        inst:RemoveTag("fullfolder")
        inst:RemoveEventCallback("inspirationdelta", inst.ondelta, inst.folderholder)
        inst.folderholder = nil
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.2)

    inst.AnimState:SetBank("songfolder")
    inst.AnimState:SetBuild("songfolder")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/songfolder.xml"

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)
    inst.components.burnable:SetOnIgniteFn(onignite)
    inst.components.burnable:SetOnExtinguishFn(onextinguish)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("songfolder")

    inst.folderholder = nil

    inst:ListenForEvent("onputininventory", checkfull)
    inst:ListenForEvent("ondropped", removebuff)

    inst:ListenForEvent("itemget", checkfull)
    inst:ListenForEvent("itemlose", checkfull)

    inst.ondelta = function(owner, data)
        if owner and owner.components.singinginspiration then
            for k,v in pairs(inst.components.container.slots) do
                local oldowner = v._owner
                v._owner = owner
                v._oninspirationdelta(v)
                v._owner = oldowner
            end
        end
    end

    MakeHauntableLaunchAndDropFirstItem(inst)
    return inst
end

return Prefab("songfolder", fn, assets)
