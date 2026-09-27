local PHONE_DATA = require("constants/warlyphonedata")

local assets =
{
    Asset("ANIM", "anim/warlyphone.zip"),
    Asset("ATLAS", "images/inventoryimages/warlyphone.xml"),
    Asset("SOUNDPACKAGE", "sound/warlyphone.fev"),
    Asset("SOUND", "sound/warlyphone.fsb"),
}
local fxassets =
{
    Asset("ANIM", "anim/deliveryphone.zip"),
}

local prefabs =
{
    "collapse_small",
    "deliveryphonefx",
}

local MIN_CALL_DELAY = TUNING.TOTAL_DAY_TIME * (chasni_getitemconfig("warly_phone", "MIND") or 3)
local MAX_CALL_DELAY = TUNING.TOTAL_DAY_TIME * (chasni_getitemconfig("warly_phone", "MAXD") or 5)
local HANGUP_DELAY = chasni_getitemconfig("warly_phone", "HANG") or 15
local function spawnfx(inst)
    if inst.AnimState:IsCurrentAnimation("ring") then
        if inst.fx == nil then
            inst.fx = chasni_spawnprefab("deliveryphonefx",0,0,0,1,1,1, inst.entity)
        end
        inst.fx.AnimState:PlayAnimation("ringing", true)
    elseif inst.AnimState:IsCurrentAnimation("pickup") then
        if inst.fx == nil then
            inst.fx = chasni_spawnprefab("deliveryphonefx",0,0,0,1,1,1, inst.entity)
        end
        inst.fx.AnimState:PlayAnimation("picked", true)
    end
end

local function despawnfx(inst)
    if inst.fx then
        inst.fx.AnimState:PlayAnimation("idle", true)
    end
end

local function ontalk(inst, script)
    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/no", nil, 0.8)
end

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal", nil, 0.3)
    inst:Remove()
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("idle")
    despawnfx(inst)
    inst.components.timer:StartTimer("gotoring", math.random(MIN_CALL_DELAY, MAX_CALL_DELAY))
    inst:AddTag("fueldepleted")
end

local function OnTimerDone(inst, data)
    if data.name == "gotoring" then
        inst.SoundEmitter:PlaySound("warlyphone/warlyphone/ringing", "ringing")
        inst.AnimState:PlayAnimation("ring", true)
        spawnfx(inst)
        inst.components.machine:TurnOff()
        inst:RemoveTag("fueldepleted")
        inst.components.timer:StartTimer("hangup", HANGUP_DELAY)
    elseif data.name == "hangup" then
        inst.SoundEmitter:KillSound("ringing")
        inst.SoundEmitter:PlaySound("warlyphone/warlyphone/hangup")
        inst:AddTag("fueldepleted")
        inst.AnimState:PlayAnimation("idle")
        despawnfx(inst)
        inst.components.timer:StartTimer("gotoring", math.random(MIN_CALL_DELAY, MAX_CALL_DELAY))
    end
end

local function OnInit(inst)
    if not inst.components.timer:TimerExists("gotoring") then
        inst.components.timer:StartTimer("gotoring", math.random(MIN_CALL_DELAY, MAX_CALL_DELAY))
    end
end

local function OnGetOrder(inst)
    inst.AnimState:PlayAnimation("hangup")
    inst.AnimState:PushAnimation("idle")
    despawnfx(inst)
    inst.components.timer:StartTimer("gotoring", math.random(MIN_CALL_DELAY, MAX_CALL_DELAY))
end

local function getGofoodDestination(loop)
    if loop > 20 then return nil end

    local desttag = TheWorld and TheWorld:HasTag("cave") and PHONE_DATA.gofood_dest_cave[math.random(#PHONE_DATA.gofood_dest_cave)] or PHONE_DATA.gofood_dest[math.random(#PHONE_DATA.gofood_dest)]
    local gofood_dest = TheSim:FindFirstEntityWithTag("gofood_dest_"..desttag)
    return gofood_dest == nil and getGofoodDestination(loop+1) or gofood_dest
end

local function getGofoodOrder(loop, rarity)
    if loop > 20 then return nil, 0 end
    local randomseed = math.random(0, 6)
    if rarity < 1 then
        if randomseed == 0 then
            return PHONE_DATA.food_insane[math.random(#PHONE_DATA.food_insane)], 2
        elseif randomseed > 4 then
            return PHONE_DATA.food_hard[math.random(#PHONE_DATA.food_hard)], 1
        else
            return PHONE_DATA.food_easy[math.random(#PHONE_DATA.food_easy)], 0
        end
    elseif rarity == 1 then
        if randomseed > 4 then
            return PHONE_DATA.food_warly[math.random(#PHONE_DATA.food_warly)], 3
        end
    elseif rarity == 2 then
        if randomseed > 4 then
            return PHONE_DATA.food_expertwarly4[math.random(#PHONE_DATA.food_expertwarly4)], 4
        end
    end
    return getGofoodOrder(loop+1, rarity-1)
end

local function getGofoodPayment(rarity)
    if rarity == nil then return nil end
    local payments = {}
    local easyreward = deepcopy(PHONE_DATA.reward_easy)
    local hardreward = deepcopy(PHONE_DATA.reward_hard)
    local bossreward = deepcopy(PHONE_DATA.reward_boss)
    if rarity < 2 then
        local payment = table.remove(easyreward, math.random(#easyreward))
        table.insert(payments, payment)
    end
    if rarity > 0 then
        local payment = table.remove(bossreward, math.random(#bossreward))
        table.insert(payments, payment)
        if math.random() > .5 then
            payment = table.remove(bossreward, math.random(#bossreward))
            table.insert(payments, payment)
        end
    end
    if rarity > 2 then
        local payment = table.remove(hardreward, math.random(#hardreward))
        table.insert(payments, payment)
    end
    if rarity == 2 or rarity == 4 then
        local payment = table.remove(hardreward, math.random(#hardreward))
        table.insert(payments, payment)
        payment = table.remove(hardreward, math.random(#hardreward))
        table.insert(payments, payment)
        if math.random() > .5 then
            payment = table.remove(bossreward, math.random(#bossreward))
            table.insert(payments, payment)
        end
    end
    return payments
end

local function Picked(inst)
    if inst.components.timer:TimerExists("gotoring") and not inst.components.timer:TimerExists("hangup") then
        return
    end
    inst.AnimState:PlayAnimation("pickup")
    spawnfx(inst)
    inst.components.timer:StopTimer("hangup")
    inst.SoundEmitter:KillSound("ringing")
    inst.SoundEmitter:PlaySound("warlyphone/warlyphone/pickedup")

    local rarity = 0
    for i, v in ipairs(AllPlayers) do
        if v then
            if rarity == 0 and (v:HasTag("masterchef") or v.currentwarlychef:value() == 1) then
                rarity = 1
            end
            if v.components.allachivcoin and v.components.allachivcoin.expertwarly4 then
                rarity = 2
                break
            end
        end
    end
    local gofood_order, ordertype = getGofoodOrder(0, rarity)
    local gofood_payment = getGofoodPayment(ordertype)
    local gofood_dest = getGofoodDestination(0)
    if gofood_order == nil or gofood_dest == nil or gofood_order == "" or gofood_payment == nil or gofood_payment == {} then
        local pos = inst:GetPosition()
        local nearby_player = FindClosestPlayerInRange(pos.x, pos.y, pos.z, 5, true)
        if nearby_player and nearby_player.components.talker then
            nearby_player.components.talker:Say(GetString(nearby_player, "WARLYPHONE_FAIL"))
        end
        inst:AddTag("fueldepleted")
        OnGetOrder(inst)
        return
    end
    local gofood_order_name = STRINGS.NAMES[string.upper(gofood_order)]

    if rarity > 0 then
        local spice = PHONE_DATA.spices[math.random(#PHONE_DATA.spices)]
        if spice ~= "" then
            gofood_order_name = subfmt(STRINGS.NAMES[string.upper(spice).."_FOOD"], { food = gofood_order_name })
            gofood_order = gofood_order .. "_" .. spice
        end
    end

    local lines = {}

    local greetings_line = math.random() < .5 and STRINGS.WARLYPHONE_GREETINGS1[math.random(#STRINGS.WARLYPHONE_GREETINGS1)]..STRINGS.WARLYPHONE_NAMES[math.random(#STRINGS.WARLYPHONE_NAMES)] or STRINGS.WARLYPHONE_GREETINGS2[math.random(#STRINGS.WARLYPHONE_GREETINGS2)]
    local order_line = STRINGS.WARLYPHONE_ORDERS1[math.random(#STRINGS.WARLYPHONE_ORDERS1)]..gofood_order_name..STRINGS.WARLYPHONE_ORDERS2[math.random(#STRINGS.WARLYPHONE_ORDERS2)]..STRINGS.NAMES[string.upper(gofood_dest.prefab)].."."
    table.insert(lines, Line(greetings_line, nil, 3))
    table.insert(lines, Line(order_line, nil, 7))
    inst.components.talker:Say(lines)
    inst:DoTaskInTime(7, function()
        OnGetOrder(inst)
        TheNet:Announce(STRINGS.WARLYPHONE_ANNOUNCEMENT1..gofood_order_name..STRINGS.WARLYPHONE_ANNOUNCEMENT2..STRINGS.NAMES[string.upper(gofood_dest.prefab)]..".")
    end)

    local pos = gofood_dest:GetPosition()
    local spawn_pt = chasni_getspawnpoint(pos, 5)
    if spawn_pt then
        local customer = SpawnPrefab(math.random() < .5 and "customer_goatmum" or "customer_goatkid")
        if customer then
            if customer.Physics then
                customer.Physics:Teleport(spawn_pt:Get())
            elseif customer.Transform then
                customer.Transform:SetPosition(spawn_pt:Get())
            end
            customer:FacePoint(pos:Get())
            customer.wantedfoodprefab = gofood_order
            customer.wantedfoodname = gofood_order_name
            customer.rewards = gofood_payment
        end
    end

    inst:AddTag("fueldepleted")
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("warlyphone")
    inst.AnimState:SetBuild("warlyphone")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("structure")
    inst:AddTag("fueldepleted")
    inst:AddTag("warlyphone")

    inst:AddComponent("talker")
    inst.components.talker.ontalk = ontalk
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0,-500,0)
    inst.components.talker.lineduration = 2
    inst.components.talker:MakeChatter()

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("machine")
    inst.components.machine.turnonfn = Picked
    inst.components.machine.cooldowntime = 0.1

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onhammered)

    inst:AddComponent("timer")

    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("onbuilt", onbuilt)
    inst.task = inst:DoTaskInTime(1, OnInit)

    return inst
end

local function MakeFX(name)
    local function fxfn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("deliveryphone")
        inst.AnimState:SetBuild("deliveryphone")
        inst.AnimState:PlayAnimation("idle", true)

        inst:AddTag("FX")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false
        return inst
    end

    return Prefab(name, fxfn, fxassets)
end

return Prefab("warlyphone", fn, assets, prefabs),
MakePlacer("warlyphone_placer", "warlyphone", "warlyphone", "idle"),
MakeFX("deliveryphonefx")