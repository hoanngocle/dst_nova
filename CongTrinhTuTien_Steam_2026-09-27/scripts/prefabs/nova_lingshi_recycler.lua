local pricing = require("nova_lingshi_pricing")
local safe_pcall = pcall

local assets = {
    Asset("ANIM", "anim/ttk_spirit_workshop.zip"),
    Asset("ANIM", "anim/ui_chest_3x3.zip"),
    Asset("ATLAS", "images/ttk_spirit_workshop/icon.xml"),
    Asset("IMAGE", "images/ttk_spirit_workshop/icon.tex"),
}

local prefabs = {
    "collapse_small",
}

local SLOT_COUNT = 9
local CONFIRM_UNITS = 200 -- 100 Hạ Phẩm Linh Thạch
local CONFIRM_SECONDS = 8
local MINE_SCALE = 2 -- 320-unit art becomes 640 in the world and placement ghost

local function FormatUnits(units)
    local whole = math.floor(units / 2)
    return units % 2 == 0 and tostring(whole) or (tostring(whole) .. ",5")
end

local function UserKey(player)
    return player ~= nil and (player.userid or tostring(player.GUID)) or ""
end

local function ItemCount(item)
    if item.components.stackable ~= nil then
        return math.max(1, math.floor(item.components.stackable:StackSize()))
    end
    return 1
end

local function CurrencyAvailable()
    return Prefabs ~= nil and Prefabs.xd_lingshi1 ~= nil
end

local function SetStatus(inst, message)
    inst._nova_status:set(message or "")
end

local function ClearConfirmation(inst)
    if inst._confirm_task ~= nil then
        inst._confirm_task:Cancel()
        inst._confirm_task = nil
    end
    inst._confirm_userid = nil
    inst._confirm_revision = nil
    inst._nova_confirm:set(false)
end

local function CanHammer(inst)
    local container = inst.components.container
    return container ~= nil and container:IsEmpty() and inst._balance_units == 0
end

local function UpdateWorkable(inst)
    local workable = inst.components.workable
    if workable ~= nil then
        workable:SetWorkable(CanHammer(inst))
    end
end

local function BuildBatch(inst)
    local entries = {}
    local total_units = 0
    local rejected_count = 0
    local first_reason = nil
    local requires_confirmation = false
    local container = inst.components.container

    for slot = 1, SLOT_COUNT do
        local item = container:GetItemInSlot(slot)
        if item ~= nil then
            local quote = pricing.GetItemQuote(item, AllRecipes)
            if quote.accepted then
                table.insert(entries, {
                    slot = slot,
                    item = item,
                    units = quote.units,
                })
                total_units = total_units + quote.units
                requires_confirmation = requires_confirmation
                    or quote.units >= CONFIRM_UNITS * quote.count
            else
                rejected_count = rejected_count + ItemCount(item)
                first_reason = first_reason or quote.reason
            end
        end
    end

    return entries, total_units, rejected_count, first_reason, requires_confirmation
end

local function RefreshPreview(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _, units, rejected, first_reason = BuildBatch(inst)
    inst._nova_balance:set(inst._balance_units)
    inst._nova_preview:set(units)
    inst._nova_rejected:set(math.min(255, rejected))

    if units == 0 and rejected == 0 then
        SetStatus(inst, "Đặt vật phẩm vào 9 ô")
    elseif first_reason ~= nil then
        SetStatus(inst, "Bỏ qua " .. tostring(rejected) .. " món: " .. first_reason)
    else
        SetStatus(inst, "Sẵn sàng luyện hóa " .. FormatUnits(units) .. " Hạ Phẩm")
    end
    UpdateWorkable(inst)
end

local function OnContentsChanged(inst)
    inst._content_revision = inst._content_revision + 1
    ClearConfirmation(inst)
    if not inst._busy then
        RefreshPreview(inst)
    end
end

local function ArmConfirmation(inst, player)
    ClearConfirmation(inst)
    inst._confirm_userid = UserKey(player)
    inst._confirm_revision = inst._content_revision
    inst._nova_confirm:set(true)
    SetStatus(inst, "Món trị giá từ 100 Hạ Phẩm. Bấm Xác nhận để tiêu hủy")
    inst._confirm_task = inst:DoTaskInTime(CONFIRM_SECONDS, function()
        inst._confirm_task = nil
        inst._confirm_userid = nil
        inst._confirm_revision = nil
        inst._nova_confirm:set(false)
        RefreshPreview(inst)
    end)
end

local function TryRefine(inst, player)
    if inst._busy then
        return false
    end
    if not CurrencyAvailable() then
        ClearConfirmation(inst)
        SetStatus(inst, "Thiếu prefab xd_lingshi1; đầu vào được giữ nguyên")
        return false
    end

    local entries, total_units, _, _, requires_confirmation = BuildBatch(inst)
    if total_units <= 0 then
        ClearConfirmation(inst)
        RefreshPreview(inst)
        return false
    end

    if requires_confirmation then
        local is_confirmed = inst._confirm_userid == UserKey(player)
            and inst._confirm_revision == inst._content_revision
        if not is_confirmed then
            ArmConfirmation(inst, player)
            return false
        end
    end

    ClearConfirmation(inst)
    inst._busy = true
    local credited_units = 0
    local container = inst.components.container

    -- Re-read every accepted slot on the server immediately before mutation.
    for _, entry in ipairs(entries) do
        local item = container:GetItemInSlot(entry.slot)
        if item == entry.item and item ~= nil then
            local quote = pricing.GetItemQuote(item, AllRecipes)
            if quote.accepted then
                local removed = container:RemoveItemBySlot(entry.slot)
                if removed == entry.item then
                    credited_units = credited_units + quote.units
                    removed:Remove()
                end
            end
        end
    end

    inst._balance_units = inst._balance_units + credited_units
    inst._busy = false
    RefreshPreview(inst)
    if credited_units > 0 then
        SetStatus(inst, "Đã luyện hóa " .. FormatUnits(credited_units) .. " Hạ Phẩm")
    end
    return credited_units > 0
end

local function TryWithdraw(inst, player)
    if inst._busy or player == nil or player.components.inventory == nil then
        return false
    end
    if not CurrencyAvailable() then
        SetStatus(inst, "Không tìm thấy xd_lingshi1; số dư được giữ nguyên")
        return false
    end

    local available = math.floor(inst._balance_units / 2)
    if available <= 0 then
        SetStatus(inst, "Chưa đủ 1 Hạ Phẩm để rút")
        return false
    end

    inst._busy = true
    local delivered = 0
    local inventory = player.components.inventory

    for _ = 1, available do
        local stone = SpawnPrefab("xd_lingshi1")
        if stone == nil then
            break
        end

        -- GiveItem normally drops on failure. ignorefull keeps a rejected
        -- one-item spawn detached so it can be removed without losing credit.
        local old_ignorefull = inventory.ignorefull
        inventory.ignorefull = true
        local ok, accepted = safe_pcall(inventory.GiveItem, inventory, stone)
        inventory.ignorefull = old_ignorefull

        if not ok or not accepted then
            if stone:IsValid() then
                stone:Remove()
            end
            break
        end

        inst._balance_units = inst._balance_units - 2
        delivered = delivered + 1
    end

    inst._busy = false
    RefreshPreview(inst)
    if delivered > 0 then
        SetStatus(inst, "Đã rút " .. tostring(delivered) .. " Hạ Phẩm")
    else
        SetStatus(inst, "Túi đã đầy; số dư được giữ nguyên")
    end
    return delivered > 0
end

local function OnOpen(inst)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
end

local function OnClose(inst)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
end

local function OnHammered(inst, worker)
    if not CanHammer(inst) then
        UpdateWorkable(inst)
        return
    end

    inst.components.container:DropEverything()
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    if fx ~= nil then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("wood")
    end
    inst:Remove()
end

local function OnSave(inst, data)
    data.nova_balance_units = inst._balance_units
end

local function OnLoad(inst, data)
    if data ~= nil then
        inst._balance_units = math.max(0, math.floor(tonumber(data.nova_balance_units) or 0))
    end
    inst:DoTaskInTime(0, RefreshPreview)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)
    inst.Transform:SetScale(MINE_SCALE, MINE_SCALE, MINE_SCALE)

    inst.MiniMapEntity:SetIcon("ttk_spirit_workshop.tex")
    inst.AnimState:SetBank("ttk_spirit_workshop")
    inst.AnimState:SetBuild("ttk_spirit_workshop")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("structure")
    inst:AddTag("chest")
    inst:AddTag("nova_lingshi_recycler")

    inst._nova_balance = net_uint(inst.GUID, "nova_lingshi_recycler.balance", "nova_recycler_dirty")
    inst._nova_preview = net_uint(inst.GUID, "nova_lingshi_recycler.preview", "nova_recycler_dirty")
    inst._nova_rejected = net_byte(inst.GUID, "nova_lingshi_recycler.rejected", "nova_recycler_dirty")
    inst._nova_status = net_string(inst.GUID, "nova_lingshi_recycler.status", "nova_recycler_dirty")
    inst._nova_confirm = net_bool(inst.GUID, "nova_lingshi_recycler.confirm", "nova_recycler_dirty")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._balance_units = 0
    inst._content_revision = 0
    inst._busy = false

    inst:AddComponent("inspectable")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("nova_lingshi_recycler")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipopensnd = true
    inst.components.container.skipclosesnd = true

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({ "cutstone", "cutstone", "boards", "boards", "goldnugget" })

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)

    inst:ListenForEvent("itemget", OnContentsChanged)
    inst:ListenForEvent("itemlose", OnContentsChanged)

    inst.RefreshPreview = RefreshPreview
    inst.TryRefine = TryRefine
    inst.TryWithdraw = TryWithdraw
    inst.CanHammer = function()
        return CanHammer(inst)
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    RefreshPreview(inst)
    return inst
end

return Prefab("nova_lingshi_recycler", fn, assets, prefabs),
    MakePlacer("nova_lingshi_recycler_placer", "ttk_spirit_workshop", "ttk_spirit_workshop", "idle", nil, nil, nil, MINE_SCALE)
