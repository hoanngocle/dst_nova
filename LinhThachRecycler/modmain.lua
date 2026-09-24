local _G = GLOBAL
local containers = _G.require("containers")

PrefabFiles = { "nova_lingshi_recycler" }

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
            position = _G.Vector3(-80, -170, 0),
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
    local Text = _G.require("widgets/text")

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
            self.nova_balance_text:SetString("Số dư: " .. FormatUnits(balance) .. " Hạ Phẩm")
        end
        if self.nova_preview_text ~= nil then
            self.nova_preview_text:SetString("Lô hiện tại: " .. FormatUnits(preview) .. " Hạ Phẩm")
        end
        if self.nova_status_text ~= nil then
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

            local withdraw = widget_self:AddChild(ImageButton(
                "images/ui.xml",
                "button_small.tex",
                "button_small_over.tex",
                "button_small_disabled.tex"
            ))
            withdraw:SetPosition(80, -170, 0)
            withdraw:SetText("Rút")
            withdraw:SetFont(_G.BUTTONFONT)
            withdraw:SetDisabledFont(_G.BUTTONFONT)
            withdraw:SetTextSize(33)
            withdraw:SetOnClick(function()
                if container:IsValid() then
                    _G.SendModRPCToServer(_G.MOD_RPC[RPC_NAMESPACE].Withdraw, container)
                end
            end)
            widget_self.nova_withdraw_button = withdraw

            widget_self.nova_balance_text = widget_self:AddChild(Text(_G.BODYTEXTFONT, 28, ""))
            widget_self.nova_balance_text:SetPosition(0, 178, 0)
            widget_self.nova_preview_text = widget_self:AddChild(Text(_G.BODYTEXTFONT, 25, ""))
            widget_self.nova_preview_text:SetPosition(0, -215, 0)
            widget_self.nova_status_text = widget_self:AddChild(Text(_G.BODYTEXTFONT, 22, ""))
            widget_self.nova_status_text:SetPosition(0, -250, 0)
            widget_self.nova_status_text:SetRegionSize(520, 50)
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
            if container ~= nil and widget_self.nova_dirty_fn ~= nil then
                widget_self.inst:RemoveEventCallback("nova_recycler_dirty", widget_self.nova_dirty_fn, container)
            end

            KillWidget(widget_self.nova_withdraw_button)
            KillWidget(widget_self.nova_balance_text)
            KillWidget(widget_self.nova_preview_text)
            KillWidget(widget_self.nova_status_text)
            widget_self.nova_withdraw_button = nil
            widget_self.nova_balance_text = nil
            widget_self.nova_preview_text = nil
            widget_self.nova_status_text = nil
            widget_self.nova_dirty_fn = nil
            widget_self.nova_recycler_container = nil
            widget_self.nova_recycler_doer = nil

            return CloseBase(widget_self, ...)
        end
    end)
end

_G.STRINGS.NAMES.NOVA_LINGSHI_RECYCLER = "Máy Tái Luyện"
_G.STRINGS.RECIPE_DESC.NOVA_LINGSHI_RECYCLER = "Luyện đồ dư thành Hạ Phẩm Linh Thạch."
_G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.NOVA_LINGSHI_RECYCLER = "Một cỗ máy gom linh khí còn sót lại."

AddRecipe2(
    "nova_lingshi_recycler",
    {
        Ingredient("cutstone", 4),
        Ingredient("boards", 4),
        Ingredient("goldnugget", 2),
        Ingredient("gears", 1),
    },
    TECH.SCIENCE_TWO,
    {
        placer = "nova_lingshi_recycler_placer",
        min_spacing = 1.5,
        atlas = "images/inventoryimages.xml",
        image = "treasurechest.tex",
    },
    { "STRUCTURES" }
)
