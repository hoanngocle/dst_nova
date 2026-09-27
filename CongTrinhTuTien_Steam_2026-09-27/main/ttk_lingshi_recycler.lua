local _G = GLOBAL
local tonumber = _G.tonumber
local tostring = _G.tostring
local ipairs = _G.ipairs
local containers = require("containers")

table.insert(PrefabFiles, "nova_lingshi_recycler")
AddMinimapAtlas("images/ttk_spirit_workshop/icon.xml")

local RPC_NAMESPACE = "NovaLinhThachRecycler"
local MAX_RPC_DISTANCE_SQ = 16

local recycler_params = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = _G.Vector3(0, 200, 0),
        side_align_tip = 160,
        buttoninfo = {
            text = "Luyện hóa",
            position = _G.Vector3(155, -117, 0),
        },
    },
    type = "chest",
    openlimit = 1,
}

for y = 2, 0, -1 do
    for x = 0, 2 do
        table.insert(
            recycler_params.widget.slotpos,
            _G.Vector3(80 * x - 80, 80 * y - 80, 0)
        )
    end
end

function recycler_params.widget.buttoninfo.fn(container, doer)
    if container ~= nil and doer ~= nil then
        _G.SendModRPCToServer(_G.MOD_RPC[RPC_NAMESPACE].Refine, container)
    end
end

function recycler_params.widget.buttoninfo.validfn(container)
    return container ~= nil
        and container._nova_preview ~= nil
        and container._nova_preview:value() > 0
end

local containers_widgetsetup_base = containers.widgetsetup
function containers.widgetsetup(container, prefab, data, ...)
    local requested_prefab = prefab or container.inst.prefab
    if requested_prefab == "nova_lingshi_recycler" then
        for key, value in pairs(recycler_params) do
            container[key] = value
        end
        container:SetNumSlots(#recycler_params.widget.slotpos)
        return
    end
    return containers_widgetsetup_base(container, prefab, data, ...)
end

containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, #recycler_params.widget.slotpos)

local function IsValidRequest(player, machine)
    if player == nil or not player:IsValid() or player:HasTag("playerghost") then
        return false
    end
    if machine == nil or not machine:IsValid()
        or machine.prefab ~= "nova_lingshi_recycler"
        or machine.components == nil
    then
        return false
    end
    if player.components.inventory == nil then
        return false
    end
    if player:GetDistanceSqToInst(machine) > MAX_RPC_DISTANCE_SQ then
        return false
    end

    local container = machine.components.container
    return container ~= nil and container:IsOpenedBy(player)
end

AddModRPCHandler(RPC_NAMESPACE, "Refine", function(player, machine)
    if IsValidRequest(player, machine) and machine.TryRefine ~= nil then
        machine:TryRefine(player)
    end
end)

AddModRPCHandler(RPC_NAMESPACE, "Withdraw", function(player, machine)
    if IsValidRequest(player, machine) and machine.TryWithdraw ~= nil then
        machine:TryWithdraw(player)
    end
end)

local function FormatUnits(units)
    units = math.max(0, math.floor(tonumber(units) or 0))
    local whole = math.floor(units / 2)
    return units % 2 == 0 and tostring(whole) or (tostring(whole) .. ",5")
end

if not _G.TheNet:IsDedicated() then
    local ImageButton = _G.require("widgets/imagebutton")
    local Image = _G.require("widgets/image")
    local Text = _G.require("widgets/text")
    local GRID_X = -160
    local PANEL_X = 155
    local LABEL_X = 90
    local VALUE_X = 215

    local function AddPanelRect(parent, x, y, width, height, colour, back)
        local rect = parent:AddChild(Image("images/ui.xml", "white.tex"))
        rect:SetPosition(x, y, 0)
        rect:ScaleToSize(width, height)
        rect:SetTint(colour[1], colour[2], colour[3], colour[4])
        if back then
            rect:MoveToBack()
        end
        return rect
    end

    local function KillWidget(widget)
        if widget ~= nil then
            widget:Kill()
        end
    end

    local function RefreshRecyclerUi(self)
        local container = self.nova_recycler_container
        if container == nil or not container:IsValid() then
            return
        end

        local balance = container._nova_balance ~= nil and container._nova_balance:value() or 0
        local preview = container._nova_preview ~= nil and container._nova_preview:value() or 0
        local status = container._nova_status ~= nil and container._nova_status:value() or ""
        local confirming = container._nova_confirm ~= nil and container._nova_confirm:value() or false

        if self.button ~= nil then
            self.button:SetText(confirming and "Xác nhận" or "Luyện hóa")
            if preview > 0 then
                self.button:Enable()
            else
                self.button:Disable()
            end
        end
        if self.nova_withdraw_button ~= nil then
            if balance >= 2 then
                self.nova_withdraw_button:Enable()
            else
                self.nova_withdraw_button:Disable()
            end
        end
        if self.nova_balance_text ~= nil then
            self.nova_balance_text:SetString(FormatUnits(balance) .. " Hạ Phẩm")
        end
        if self.nova_preview_text ~= nil then
            self.nova_preview_text:SetString(FormatUnits(preview) .. " Hạ Phẩm")
        end
        if self.nova_status_text ~= nil then
            self.nova_status_text:SetSize(#status <= 40 and 30 or 24)
            self.nova_status_text:SetString(status)
        end
    end

    AddClassPostConstruct("widgets/containerwidget", function(self)
        local OpenBase = self.Open
        local RefreshBase = self.Refresh
        local CloseBase = self.Close

        self.Open = function(widget_self, container, doer, ...)
            OpenBase(widget_self, container, doer, ...)
            if container == nil or container.prefab ~= "nova_lingshi_recycler" then
                return
            end

            widget_self.nova_recycler_container = container
            widget_self.nova_recycler_doer = doer

            -- ContainerWidget uses 0.6 by default; the recycler needs readable text.
            widget_self:SetScale(.8, .8, .8)
            if widget_self.bganim ~= nil then
                widget_self.bganim:SetPosition(GRID_X, 0, 0)
            end
            if widget_self.bgimage ~= nil then
                widget_self.bgimage:SetPosition(GRID_X, 0, 0)
            end
            for i, slot in ipairs(widget_self.inv) do
                local pos = recycler_params.widget.slotpos[i]
                slot:SetPosition(pos.x + GRID_X, pos.y, pos.z)
            end

            widget_self.nova_panel = AddPanelRect(widget_self, PANEL_X, -10, 290, 450, { .07, .055, .045, .86 }, true)
            widget_self.nova_panel_top = AddPanelRect(widget_self, PANEL_X, 213, 290, 4, { .68, .48, .21, 1 })
            widget_self.nova_panel_rule = AddPanelRect(widget_self, PANEL_X, 107, 248, 2, { .52, .38, .20, .85 })

            widget_self.nova_slots_title = widget_self:AddChild(Text(_G.TITLEFONT, 34, "VẬT PHẨM"))
            widget_self.nova_slots_title:SetPosition(GRID_X, 176, 0)
            widget_self.nova_slots_title:SetColour(.95, .85, .62, 1)

            widget_self.nova_title = widget_self:AddChild(Text(_G.TITLEFONT, 39, "MÁY TÁI LUYỆN"))
            widget_self.nova_title:SetPosition(PANEL_X, 160, 0)
            widget_self.nova_title:SetColour(.98, .87, .65, 1)

            widget_self.button:SetTextures(
                "images/frontend.xml", "button_long.tex", "button_long_highlight.tex",
                "button_long_disabled.tex", "button_long_down.tex"
            )
            widget_self.button:ForceImageSize(236, 62)
            widget_self.button:SetTextSize(38)
            widget_self.button.scale_on_focus = false

            local withdraw = widget_self:AddChild(ImageButton(
                "images/frontend.xml",
                "button_long.tex",
                "button_long_highlight.tex",
                "button_long_disabled.tex",
                "button_long_down.tex"
            ))
            withdraw:SetPosition(PANEL_X, -187, 0)
            withdraw:ForceImageSize(236, 62)
            withdraw.scale_on_focus = false
            withdraw:SetText("Rút Linh Thạch")
            withdraw:SetFont(_G.BUTTONFONT)
            withdraw:SetDisabledFont(_G.BUTTONFONT)
            withdraw:SetTextSize(32)
            withdraw:SetOnClick(function()
                if container:IsValid() then
                    _G.SendModRPCToServer(_G.MOD_RPC[RPC_NAMESPACE].Withdraw, container)
                end
            end)
            widget_self.nova_withdraw_button = withdraw

            widget_self.nova_balance_label = widget_self:AddChild(Text(_G.BODYTEXTFONT, 31, "Số dư:"))
            widget_self.nova_balance_label:SetPosition(LABEL_X, 73, 0)
            widget_self.nova_balance_label:SetRegionSize(110, 44)
            widget_self.nova_balance_label:SetHAlign(_G.ANCHOR_LEFT)
            widget_self.nova_balance_label:SetColour(.89, .83, .72, 1)
            widget_self.nova_balance_text = widget_self:AddChild(Text(_G.BODYTEXTFONT, 31, ""))
            widget_self.nova_balance_text:SetPosition(VALUE_X, 73, 0)
            widget_self.nova_balance_text:SetRegionSize(130, 44)
            widget_self.nova_balance_text:SetHAlign(_G.ANCHOR_LEFT)
            widget_self.nova_balance_text:SetColour(.94, .85, .61, 1)
            widget_self.nova_preview_label = widget_self:AddChild(Text(_G.BODYTEXTFONT, 31, "Lô hiện tại:"))
            widget_self.nova_preview_label:SetPosition(LABEL_X, 21, 0)
            widget_self.nova_preview_label:SetRegionSize(110, 44)
            widget_self.nova_preview_label:SetHAlign(_G.ANCHOR_LEFT)
            widget_self.nova_preview_label:SetColour(.89, .83, .72, 1)
            widget_self.nova_preview_text = widget_self:AddChild(Text(_G.BODYTEXTFONT, 31, ""))
            widget_self.nova_preview_text:SetPosition(VALUE_X, 21, 0)
            widget_self.nova_preview_text:SetRegionSize(130, 44)
            widget_self.nova_preview_text:SetHAlign(_G.ANCHOR_LEFT)
            widget_self.nova_preview_text:SetColour(.88, .94, .85, 1)
            widget_self.nova_status_text = widget_self:AddChild(Text(_G.BODYTEXTFONT, 30, ""))
            widget_self.nova_status_text:SetPosition(PANEL_X, -42, 0)
            widget_self.nova_status_text:SetColour(.92, .87, .78, 1)
            widget_self.nova_status_text:SetRegionSize(270, 80)
            widget_self.nova_status_text:EnableWordWrap(true)

            widget_self.nova_dirty_fn = function()
                if widget_self.nova_recycler_container ~= nil then
                    widget_self:Refresh()
                end
            end
            widget_self.inst:ListenForEvent("nova_recycler_dirty", widget_self.nova_dirty_fn, container)
            RefreshRecyclerUi(widget_self)
        end

        self.Refresh = function(widget_self, ...)
            RefreshBase(widget_self, ...)
            RefreshRecyclerUi(widget_self)
        end

        self.Close = function(widget_self, ...)
            local container = widget_self.nova_recycler_container
            local was_recycler = container ~= nil
            if container ~= nil and widget_self.nova_dirty_fn ~= nil then
                widget_self.inst:RemoveEventCallback("nova_recycler_dirty", widget_self.nova_dirty_fn, container)
            end

            KillWidget(widget_self.nova_withdraw_button)
            KillWidget(widget_self.nova_balance_text)
            KillWidget(widget_self.nova_balance_label)
            KillWidget(widget_self.nova_preview_text)
            KillWidget(widget_self.nova_preview_label)
            KillWidget(widget_self.nova_status_text)
            KillWidget(widget_self.nova_slots_title)
            KillWidget(widget_self.nova_title)
            KillWidget(widget_self.nova_panel_rule)
            KillWidget(widget_self.nova_panel_top)
            KillWidget(widget_self.nova_panel)
            widget_self.nova_withdraw_button = nil
            widget_self.nova_balance_text = nil
            widget_self.nova_balance_label = nil
            widget_self.nova_preview_text = nil
            widget_self.nova_preview_label = nil
            widget_self.nova_status_text = nil
            widget_self.nova_slots_title = nil
            widget_self.nova_title = nil
            widget_self.nova_panel_rule = nil
            widget_self.nova_panel_top = nil
            widget_self.nova_panel = nil
            widget_self.nova_dirty_fn = nil
            widget_self.nova_recycler_container = nil
            widget_self.nova_recycler_doer = nil

            local result = CloseBase(widget_self, ...)
            if was_recycler then
                widget_self:SetScale(.6, .6, .6)
                if widget_self.bganim ~= nil then
                    widget_self.bganim:SetPosition(0, 0, 0)
                end
                if widget_self.bgimage ~= nil then
                    widget_self.bgimage:SetPosition(0, 0, 0)
                end
            end
            return result
        end
    end)
end

_G.STRINGS.NAMES.NOVA_LINGSHI_RECYCLER = "Máy Tái Luyện"
_G.STRINGS.RECIPE_DESC.NOVA_LINGSHI_RECYCLER = "Luyện đồ dư thành Hạ Phẩm Linh Thạch."
_G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.NOVA_LINGSHI_RECYCLER = "Một cỗ máy gom linh khí còn sót lại."

AddRecipe2(
    "nova_lingshi_recycler",
    {
        _G.Ingredient("cutstone", 4),
        _G.Ingredient("boards", 4),
        _G.Ingredient("goldnugget", 2),
        _G.Ingredient("gears", 1),
    },
    _G.TECH.SCIENCE_TWO,
    {
        placer = "nova_lingshi_recycler_placer",
        min_spacing = 5,
        atlas = "images/ttk_spirit_workshop/icon.xml",
        image = "ttk_spirit_workshop.tex",
    },
    { "STRUCTURES" }
)
