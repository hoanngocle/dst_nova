local G = GLOBAL

local function EquippedSword(player)
    local inventory = player.components ~= nil and player.components.inventory or nil
    return inventory ~= nil and inventory:GetEquippedItem(G.EQUIPSLOTS.HANDS) or nil
end

AddModRPCHandler("ttk_vankiem", "ToggleAutoAttack", function(player, enabled)
    enabled = enabled ~= false and enabled ~= nil
    player._ttk_vankiem_auto_attack = enabled
    local classified = player.player_classified
    if classified ~= nil and classified.ttk_vankiem_auto_attack ~= nil then
        classified.ttk_vankiem_auto_attack:set(enabled)
    end
    local sword = EquippedSword(player)
    if sword ~= nil and sword:HasTag("ttk_vankiemquytong") then
        sword:SetAutoAttack(enabled)
    end
end)

AddPrefabPostInit("player_classified", function(inst)
    inst.ttk_vankiem_auto_attack = G.net_bool(
        inst.GUID, "ttk_vankiem_auto_attack", "ttk_vankiem_auto_attack_dirty")
    inst.ttk_vankiem_auto_attack:set(true)
    inst.equip_ttk_vankiem = G.net_bool(
        inst.GUID, "equip_ttk_vankiem", "equip_ttk_vankiem_dirty")
    inst:ListenForEvent("equip_ttk_vankiem_dirty", function(classified)
        if classified._parent ~= nil then
            classified._parent:PushEvent("equip_ttk_vankiem", {
                equipped = classified.equip_ttk_vankiem:value(),
            })
        end
    end)
end)

G.STRINGS.TTK_VANKIEM_SELECT = "Chỉ định mục tiêu cho Vạn Kiếm Quy Tông"
AddAction("TTK_VANKIEM_SELECT", G.STRINGS.TTK_VANKIEM_SELECT, function(act)
    local sword = EquippedSword(act.doer)
    if sword ~= nil and sword:HasTag("ttk_vankiemquytong") then
        return sword:Attack(act.doer, act.target)
    end
    return false
end)
G.ACTIONS.TTK_VANKIEM_SELECT.distance = 24
G.ACTIONS.TTK_VANKIEM_SELECT.instant = true
G.ACTIONS.TTK_VANKIEM_SELECT.mount_valid = true
G.ACTIONS.TTK_VANKIEM_SELECT.priority = 3

AddComponentAction("SCENE", "combat", function(target, doer, actions, right)
    if not right or target:HasTag("player") then return end
    local inventory = doer.replica.inventory
    if inventory == nil or not inventory:EquipHasTag("ttk_vankiemquytong") then return end
    if not G.IsEntityDead(target, true) and target.replica.combat ~= nil
        and target.replica.combat:CanBeAttacked(doer)
        and not doer.replica.combat:IsAlly(target) then
        table.insert(actions, G.ACTIONS.TTK_VANKIEM_SELECT)
    end
end)

local Widget = require("widgets/widget")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")

local function MakeAutoButton(controls)
    if controls.inv == nil or controls.inv.hand_inv == nil then return nil end
    local atlas = G.resolvefilepath(G.CRAFTING_ATLAS)
    local root = controls.inv.hand_inv:AddChild(Widget())
    root:SetPosition(0, 75, 0)
    root:SetScale(.65)
    local button = root:AddChild(ImageButton(atlas,
        "filterslot_frame.tex", "filterslot_frame_highlight.tex",
        nil, nil, "filterslot_frame_select.tex"))
    local icon = root:AddChild(Image(
        G.resolvefilepath(G.CRAFTING_ICONS_ATLAS), "filter_weapon.tex"))
    icon:ScaleToSize(54, 54)
    icon:MoveToBack()
    local background = root:AddChild(Image(atlas, "filterslot_bg_highlight.tex"))
    background:MoveToBack()

    local function Refresh()
        local classified = controls.owner.player_classified
        local enabled = classified ~= nil and classified.ttk_vankiem_auto_attack:value()
        root:SetTooltip(enabled and "Vạn Kiếm Quy Tông: tự đánh đang bật"
            or "Vạn Kiếm Quy Tông: tự đánh đang tắt")
        background:SetTexture(atlas,
            enabled and "filterslot_bg_highlight.tex" or "filterslot_bg.tex")
    end
    button:SetOnClick(function()
        local classified = controls.owner.player_classified
        if classified ~= nil then
            G.SendModRPCToServer(G.MOD_RPC.ttk_vankiem.ToggleAutoAttack,
                not classified.ttk_vankiem_auto_attack:value())
        end
    end)
    controls.owner:ListenForEvent("ttk_vankiem_auto_attack_dirty", Refresh,
        controls.owner.player_classified)
    Refresh()
    root:Hide()
    return root
end

AddClassPostConstruct("widgets/controls", function(controls)
    controls.inst:DoTaskInTime(10 * G.FRAMES, function()
        local button = MakeAutoButton(controls)
        if button == nil then return end
        controls.ttk_vankiem_button = button
        local classified = controls.owner.player_classified
        if classified ~= nil and classified.equip_ttk_vankiem:value() then
            button:Show()
        end
        controls.owner:ListenForEvent("equip_ttk_vankiem", function(_, data)
            if data ~= nil and data.equipped then button:Show() else button:Hide() end
        end)
    end)
end)
