local assets =
{
    Asset("ANIM", "anim/pugalisk_trapdoor.zip"),
    Asset("IMAGE", "images/inventoryimages/pugalisk_trapdoor.tex"),
    Asset("ATLAS", "images/inventoryimages/pugalisk_trapdoor.xml"),
    Asset("SOUNDPACKAGE", "sound/pugalisk_trapdoor.fev"),
    Asset("SOUND", "sound/pugalisk_trapdoor.fsb"),
}

local RADIUS = chasni_getitemconfig("pugalisk_trapdoor", "RAD") or 5
local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("closing")
    inst.AnimState:PushAnimation("closed")
end

local function onopen(inst)
    inst.AnimState:PlayAnimation("opening")
    inst.AnimState:PushAnimation("open")
    inst.SoundEmitter:KillSound("open", nil, 0.5)
    inst.SoundEmitter:PlaySound("pugalisk_trapdoor/pugalisk_trapdoor/open", "open", 0.1)
end

local function MoveSlotContainer(inst_from, slot, inst_to)
    local d_item = inst_from.components.container:RemoveItemBySlot(slot)
    if d_item then
        d_item.prevslot = nil
        d_item.prevcontainer = nil
        if inst_to.components.container:GiveItem(d_item) then
            return true
        else
            inst_from.components.container:GiveItem(d_item, slot)
            return false
        end
    end
end

local function onclose(inst)
    inst.AnimState:PlayAnimation("closing")
    inst.AnimState:PushAnimation("closed")
    inst.SoundEmitter:KillSound("open")
    inst.SoundEmitter:PlaySound("pugalisk_trapdoor/pugalisk_trapdoor/open", "open", 0.1)

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, RADIUS * 4, { "structure" }, nil, { "chest", "saltbox", "fridge" }) --20
    for i=1,inst.components.container:GetNumSlots() do
        local d_item = inst.components.container:GetItemInSlot(i)
        if d_item then
            for n,chest in ipairs(ents) do
                if chest~=inst then --not itself
                    if chest.components.container and chest.components.container:Has(d_item.prefab, 1) then
                        if MoveSlotContainer(inst, i, chest) then
                            SpawnPrefab("sand_puff").Transform:SetPosition(chest.Transform:GetWorldPosition())
                            SpawnPrefab("sand_puff_large_front").Transform:SetPosition(inst.Transform:GetWorldPosition())
                            break
                        end
                    end
                end
            end
        end
    end

    inst.components.container:DropEverything()
end

local function ondug(inst, worker)
    inst.components.lootdropper:DropLoot()

    if inst.components.container then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("closing")
    inst.AnimState:PushAnimation("closed")
end

local PLACER_SCALE = math.sqrt(RADIUS)

local function OnEnableHelper(inst, enabled)
    if enabled then
        if inst.helper == nil then
            inst.helper = CreateEntity()

            inst.helper.entity:SetCanSleep(false)
            inst.helper.persists = false

            inst.helper.entity:AddTransform()
            inst.helper.entity:AddAnimState()

            inst.helper:AddTag("CLASSIFIED")
            inst.helper:AddTag("NOCLICK")
            inst.helper:AddTag("placer")

            inst.helper.Transform:SetScale(PLACER_SCALE, PLACER_SCALE, PLACER_SCALE)

            inst.helper.AnimState:SetBank("firefighter_placement")
            inst.helper.AnimState:SetBuild("firefighter_placement")
            inst.helper.AnimState:PlayAnimation("idle")
            inst.helper.AnimState:SetLightOverride(1)
            inst.helper.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.helper.AnimState:SetLayer(LAYER_BACKGROUND)
            inst.helper.AnimState:SetSortOrder(1)
            inst.helper.AnimState:SetAddColour(1.0, 1.0, .0, 0)

            inst.helper.entity:SetParent(inst.entity)
        end
    elseif inst.helper then
        inst.helper:Remove()
        inst.helper = nil
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("structure")
    inst:AddTag("chest")

    inst.AnimState:SetBank("pugalisk_trapdoor")
    inst.AnimState:SetBuild("pugalisk_trapdoor")
    inst.AnimState:PlayAnimation("closed", true)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.Transform:SetScale(0.8, 0.8, 0.8)

    MakeSnowCoveredPristine(inst)
    MakeObstaclePhysics(inst, 1, 1)

    --Dedicated server does not need deployhelper
    if not TheNet:IsDedicated() then
        inst:AddComponent("deployhelper")
        inst.components.deployhelper.onenablehelper = OnEnableHelper
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("chasni_pugalisk_trapdoor")
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(ondug)
    inst.components.workable:SetOnWorkCallback(onhit)
    inst.components.workable:SetWorkLeft(3)

    inst:ListenForEvent("onbuilt", onbuilt)

    MakeSnowCovered(inst)
    MakeMediumPropagator(inst)
    AddHauntableDropItemOrWork(inst)

    return inst
end

return Prefab("chasni_pugalisk_trapdoor", fn, assets),
MakePlacer("chasni_pugalisk_trapdoor_placer", "pugalisk_trapdoor", "pugalisk_trapdoor", "closed")