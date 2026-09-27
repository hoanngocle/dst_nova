local assets =
{
    rope = {
        Asset("ANIM", "anim/ropemachine.zip"),
        Asset("ATLAS", "images/inventoryimages/icemaker.xml"),
        Asset("IMAGE", "images/inventoryimages/icemaker.tex"),
    },
    boards = {
        Asset("ANIM", "anim/boardsmachine.zip"),
        Asset("ATLAS", "images/inventoryimages/icemaker.xml"),
        Asset("IMAGE", "images/inventoryimages/icemaker.tex"),
    },
    cutstone = {
        Asset("ANIM", "anim/cutstonemachine.zip"),
        Asset("ATLAS", "images/inventoryimages/icemaker.xml"),
        Asset("IMAGE", "images/inventoryimages/icemaker.tex"),
    },
    gem = {
        Asset("ANIM", "anim/gemmachine.zip"),
        Asset("ATLAS", "images/inventoryimages/icemaker.xml"),
        Asset("IMAGE", "images/inventoryimages/icemaker.tex"),
    },
}

local prefabs =
{
    rope = { "collapse_small", "rope", },
    boards = { "collapse_small", "boards", },
    cutstone = { "collapse_small", "cutstone", },
    gem = { "collapse_small", "yellowgem", "orangegem", "greengem", "purplegem", "redgem", "bluegem", "opalpreciousgem", "flint", },
}

local MACHINESTATES =
{
    ON = "_on",
    OFF = "_off",
}
local MAXFUEL = chasni_getitemconfig("materialmaker", "FUEL") or 100
local GEMMOD = chasni_getitemconfig("materialmaker", "GEM") or 1
local gemweight =
{
    yellowgem = GEMMOD * 0.02,
    orangegem = GEMMOD * 0.02,
    greengem = GEMMOD * 0.02,
    purplegem = GEMMOD * 0.03,
    redgem = GEMMOD * 0.05,
    bluegem = GEMMOD * 0.05,
    opalpreciousgem = 0.01,
    flint = 0.80 - ((GEMMOD - 1) * 0.20),
}
--region PLACER FUNCTION
local PLACER_SCALE = 1.5

local function OnUpdatePlacerHelper(helperinst)
    if not helperinst.placerinst:IsValid() then
        helperinst.components.updatelooper:RemoveOnUpdateFn(OnUpdatePlacerHelper)
        helperinst.AnimState:SetAddColour(0, 0, 0, 0)
    else
        local range = TUNING.WINONA_BATTERY_RANGE - TUNING.WINONA_ENGINEERING_FOOTPRINT
        local hx, hy, hz = helperinst.Transform:GetWorldPosition()
        local px, py, pz = helperinst.placerinst.Transform:GetWorldPosition()
        --<= match circuitnode FindEntities range tests
        if distsq(hx, hz, px, pz) <= range * range and TheWorld.Map:GetPlatformAtPoint(hx, hz) == TheWorld.Map:GetPlatformAtPoint(px, pz) then
            helperinst.AnimState:SetAddColour(helperinst.placerinst.AnimState:GetAddColour())
        else
            helperinst.AnimState:SetAddColour(0, 0, 0, 0)
        end
    end
end

local function CreatePlacerBatteryRing()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")

    inst.AnimState:SetBank("winona_battery_placement")
    inst.AnimState:SetBuild("winona_battery_placement")
    inst.AnimState:PlayAnimation("idle_small")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetScale(PLACER_SCALE, PLACER_SCALE)

    return inst
end

local function CreatePlacerRing()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")

    inst.AnimState:SetBank("winona_spotlight_placement")
    inst.AnimState:SetBuild("winona_spotlight_placement")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetAddColour(0, .2, .5, 0)
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetScale(PLACER_SCALE, PLACER_SCALE)

    CreatePlacerBatteryRing().entity:SetParent(inst.entity)

    return inst
end

local function OnEnableHelper(inst, enabled, recipename, placerinst)
    if enabled then
        if inst.helper == nil and inst:HasTag("HAMMER_workable") and not inst:HasTag("burnt") then
            if (placerinst and placerinst.prefab == "materialmaker_placer") then
                inst.helper = CreatePlacerRing()
                inst.helper.entity:SetParent(inst.entity)
            else
                inst.helper = CreatePlacerBatteryRing()
                inst.helper.entity:SetParent(inst.entity)
                if placerinst and (
                        placerinst.prefab == "winona_battery_low_item_placer" or
                                placerinst.prefab == "winona_battery_high_item_placer" or
                                recipename == "winona_battery_low" or
                                recipename == "winona_battery_high"
                ) then
                    inst.helper:AddComponent("updatelooper")
                    inst.helper.components.updatelooper:AddOnUpdateFn(OnUpdatePlacerHelper)
                    inst.helper.placerinst = placerinst
                    OnUpdatePlacerHelper(inst.helper)
                end
            end
        end
    elseif inst.helper ~= nil then
        inst.helper:Remove()
        inst.helper = nil
    end
end

local function OnStartHelper(inst)--, recipename, placerinst)
    if inst.AnimState:IsCurrentAnimation("place") then
        inst.components.deployhelper:StopHelper()
    end
end

local function CreatePlacerSpotlight()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")

    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBank("boardsmachine")
    inst.AnimState:SetBuild("boardsmachine")
    inst.AnimState:PlayAnimation("idle_off")
    inst.AnimState:SetLightOverride(1)

    return inst
end

local function placer_postinit_fn(inst)
    --Show the spotlight placer on top of the spotlight range ground placer
    --Also add the small battery range indicator

    local placer2 = CreatePlacerBatteryRing()
    placer2.entity:SetParent(inst.entity)
    inst.components.placer:LinkEntity(placer2)

    placer2 = CreatePlacerSpotlight()
    placer2.entity:SetParent(inst.entity)
    inst.components.placer:LinkEntity(placer2)

    inst.AnimState:SetScale(PLACER_SCALE, PLACER_SCALE)

    inst.deployhelper_key = "winona_battery_engineering"
end

--endregion

local function spawnproduct(inst)
    inst:RemoveEventCallback("animover", spawnproduct)
    local product = inst.product
    if product == "gem" then
        product = weighted_random_choice(gemweight)
    end
    local prd = SpawnPrefab(product)
    local pt = Vector3(inst.Transform:GetWorldPosition()) + Vector3(0,2,0)
    prd.Transform:SetPosition(pt:Get())
    local down = TheCamera:GetDownVec()
    local angle = math.atan2(down.z, down.x) + (math.random()*60)*DEGREES
    local sp = 3 + math.random()
    prd.Physics:SetVel(sp*math.cos(angle), math.random()*2+8, sp*math.sin(angle))
end

local function fueltaskfn(inst)
    inst.AnimState:PlayAnimation("use")
    inst:ListenForEvent("animover", spawnproduct)
end

local function onhit(inst, worker)
    inst:RemoveEventCallback("animover", spawnproduct)
    inst.AnimState:PlayAnimation("hit"..inst.machinestate)
    inst.AnimState:PushAnimation("idle"..inst.machinestate, true)
end

local function onconnectfn(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
    inst.machinestate = MACHINESTATES.ON
    inst.AnimState:PlayAnimation("turn"..inst.machinestate)
    inst.AnimState:PushAnimation("idle"..inst.machinestate, true)
    if inst.fueltask == nil then
        inst.fueltask = inst:DoPeriodicTask(5, fueltaskfn)
    end
end

local function ondisconnectfn(inst)
    inst.machinestate = MACHINESTATES.OFF
    inst.AnimState:PlayAnimation("turn"..inst.machinestate)
    inst.AnimState:PushAnimation("idle"..inst.machinestate, true)
    if inst.fueltask then
        inst.fueltask:Cancel()
        inst.fueltask = nil
    end
end

local function getstatus(inst)
end

local function NotifyCircuitChanged(inst, node)
    node:PushEvent("engineeringcircuitchanged")
end

local function OnCircuitChanged(inst)
    --Notify other connected batteries
    inst.components.circuitnode:ForEachNode(NotifyCircuitChanged)
end

local function OnLedDirty(inst)
    --if inst._led:value() then
        --inst._beacon.AnimState:OverrideSymbol("beacon_off", "winona_teleport_pad", "beacon_on")
        --inst._beacon.AnimState:SetSymbolBloom("beacon_off")
        --inst._beacon.AnimState:SetSymbolLightOverride("beacon_off", 0.5)
        --inst._beacon.AnimState:SetLightOverride(0.1)
    --else
        --inst._beacon.AnimState:ClearOverrideSymbol("beacon_off")
        --inst._beacon.AnimState:ClearSymbolBloom("beacon_off")
        --inst._beacon.AnimState:SetSymbolLightOverride("beacon_off", 0)
        --inst._beacon.AnimState:SetLightOverride(0)
    --end
end

local function SetLedEnabled(inst, enabled)
    --inst._led:set(enabled)
    --if not TheNet:IsDedicated() then
    --    OnLedDirty(inst)
    --end
end

local function IsPowered(inst)
    return inst._powertask
end

local function SetPowered(inst, powered, duration)
    if not powered then
        if inst._powertask then
            inst._powertask:Cancel()
            inst._powertask = nil
            ondisconnectfn(inst)
        end
        SetLedEnabled(inst, false)
    else
        local waspowered = inst._powertask ~= nil
        local remaining = waspowered and GetTaskRemaining(inst._powertask) or 0
        if duration > remaining then
            if inst._powertask then
                inst._powertask:Cancel()
            end
            inst._powertask = inst:DoTaskInTime(duration, SetPowered, false)
            if not waspowered then
                onconnectfn(inst)
                SetLedEnabled(inst, true)
            end
        end
    end
end

local function OnBuilt2(inst, doer)
    inst:RemoveTag("NOCLICK")
    if not inst:HasTag("burnt") then
        inst.components.circuitnode:ConnectTo("engineeringbattery")
        if doer and doer:IsValid() then
            inst.components.circuitnode:ForEachNode(function(inst, node)
                node:OnUsedIndirectly(doer)
            end)
        end
    end
end

local function onbuilt(inst, data)
    if inst._inittask then
        inst._inittask:Cancel()
        inst._inittask = nil
    end
    inst.components.circuitnode:Disconnect()
    inst:AddTag("NOCLICK")
    SetPowered(inst, false)
    inst:DoTaskInTime(8 * FRAMES, OnBuilt2, (data and data.builder) or nil)

    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle"..inst.machinestate)
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_place")
end

local function onhammered(inst, worked)
    if inst.components.burnable and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal")

    if inst:IsAsleep() then
        inst:Remove()
        return
    end

    if inst._inittask then
        inst._inittask:Cancel()
        inst._inittask = nil
    end
    SetPowered(inst, false)

    inst:Remove()
end

local function OnWorkedBurnt(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function OnBurnt(inst)
    DefaultBurntStructureFn(inst)

    SetPowered(inst, false)

    inst:RemoveComponent("portablestructure")

    inst.components.workable:SetOnWorkCallback(nil)
    inst.components.workable:SetOnFinishCallback(OnWorkedBurnt)

    if inst._inittask then
        inst._inittask:Cancel()
        inst._inittask = nil
    end
    inst.components.circuitnode:Disconnect()
    inst.components.powerload:SetLoad(0)
end

local function AddBatteryPower(inst, power)
    SetPowered(inst, true, power)
end

local function OnConnectCircuit(inst)--, node)
    OnCircuitChanged(inst)
end

local function OnDisconnectCircuit(inst)--, node)
    if inst.components.circuitnode:IsConnected() then
        OnCircuitChanged(inst)
    else
        SetPowered(inst, false)
    end
end

local function OnSave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    else
        data.power = inst._powertask ~= nil and math.ceil(GetTaskRemaining(inst._powertask) * 1000) or nil
    end
    data.machinestate = inst.machinestate
end

local function OnLoad(inst, data)
    if inst._inittask then
        inst._inittask:Cancel()
        inst._inittask = nil
    end
    if data and data.burnt then
        inst.components.burnable.onburnt(inst)
    else
        if data and data.power then
            AddBatteryPower(inst, math.max(2 * FRAMES, data.power / 1000))
        end
        --Enable connections, but leave the initial connection to batteries' OnPostLoad
        inst.components.circuitnode:ConnectTo(nil)
    end
    inst.machinestate = data and data.machinestate or MACHINESTATES.OFF
end

local function OnInit(inst)
    inst._inittask = nil
    inst.components.circuitnode:ConnectTo("engineeringbattery")
end

local function makePrefab(product)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.product = product

        inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.LARGE] / 2)

        MakeObstaclePhysics(inst, .4)

        inst:AddTag("engineering")
        inst:AddTag("engineeringbatterypowered")
        inst:AddTag("structure")

        inst.entity:AddAnimState()
        inst.AnimState:SetBank(product.."machine")
        inst.AnimState:SetBuild(product.."machine")
        inst.AnimState:PlayAnimation("idle_off")

        if not TheNet:IsDedicated() then
            inst:AddComponent("deployhelper")
            inst.components.deployhelper:AddRecipeFilter("winona_spotlight")
            inst.components.deployhelper:AddRecipeFilter("winona_catapult")
            inst.components.deployhelper:AddRecipeFilter("winona_battery_low")
            inst.components.deployhelper:AddRecipeFilter("winona_battery_high")
            inst.components.deployhelper:AddKeyFilter("winona_battery_engineering")
            inst.components.deployhelper.onenablehelper = OnEnableHelper
            inst.components.deployhelper.onstarthelper = OnStartHelper
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")

        inst:AddComponent("circuitnode")
        inst.components.circuitnode:SetRange(TUNING.WINONA_BATTERY_RANGE)
        inst.components.circuitnode:SetFootprint(TUNING.WINONA_ENGINEERING_FOOTPRINT)
        inst.components.circuitnode:SetOnConnectFn(OnConnectCircuit)
        inst.components.circuitnode:SetOnDisconnectFn(OnDisconnectCircuit)
        inst.components.circuitnode.connectsacrossplatforms = false
        inst.components.circuitnode.rangeincludesfootprint = true

        inst:AddComponent("powerload")
        inst.components.powerload:SetLoad(TUNING.WINONA_SPOTLIGHT_POWER_LOAD_OFF, true)

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = getstatus

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit)

        MakeLargePropagator(inst)
        MakeLargeBurnable(inst, 20, nil, true)
        inst.components.burnable:SetOnBurntFn(OnBurnt)

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.AddBatteryPower = AddBatteryPower
        inst.IsPowered = IsPowered

        inst:ListenForEvent("engineeringcircuitchanged", OnCircuitChanged)

        inst.machinestate = MACHINESTATES.OFF
        inst:ListenForEvent("onbuilt", onbuilt)
        inst._inittask = inst:DoTaskInTime(0, OnInit)

        return inst
    end

    return Prefab(product.."maker", fn, assets[product], prefabs[product])
end

return
makePrefab("rope"),
makePrefab("boards"),
makePrefab("cutstone"),
makePrefab("gem"),
MakePlacer("materialmaker_placer", "boardsmachine", "boardsmachine", "none", true, nil, nil, nil, nil, nil, placer_postinit_fn)
