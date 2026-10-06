local M = {}

-- Exact prefab names: do not accept equipment or unrelated mod items by tag/prefix.
local allowed = {
    redgem=true, bluegem=true, purplegem=true, orangegem=true,
    yellowgem=true, greengem=true, opalpreciousgem=true,
    hh_effect_stone=true, hh_effect_tally=true, hh_remove_stone=true,
    ac_refreshstone=true, ad_cleanstone=true,
    wb_enhancegem=true,
    hh_essence=true,
    xd_lingshi1=true, xd_lingshi2=true, xd_lingshi3=true, xd_lingshi4=true,
    ttk_huyen_tinh_ha_pham=true, ttk_huyen_tinh_trung_pham=true,
    ttk_huyen_tinh_thuong_pham=true,
}

function M.Accepts(item)
    return item ~= nil and allowed[item.prefab] == true
end

function M.Register(containers, vector3)
    local slots = {}
    for row = 0, 5 do
        for column = 0, 5 do
            slots[#slots+1] = vector3((column-2.5)*80, (2.5-row)*80, 0)
        end
    end
    containers.params.nyx_gem_storage = {
        widget = {
            slotpos = slots,
            animbank = 'xd_ui_6x6', animbuild = 'xd_ui_6x6',
            pos = vector3(0, 200, 0), side_align_tip = 260,
        },
        type = 'chest', openlimit = 1,
        itemtestfn = function(_, item) return M.Accepts(item) end,
    }
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, #slots)
end

function M.InstallPickup(inventory)
    local give = inventory.GiveItem
    inventory.GiveItem = function(self, item, slot, src_pos, ...)
        local player = self.inst
        local storage = player.prefab == 'nyx' and player.components.nyx_gem_storage or nil
        local invitem = item ~= nil and item.components.inventoryitem or nil
        -- Preserve load, explicit transfers and items taken out of a container.
        if storage ~= nil and not self.isloading and slot == nil and M.Accepts(item)
            and item:IsValid() and invitem ~= nil and invitem.owner == nil
            and item.prevcontainer == nil and item ~= self.activeitem then
            local container = storage:GetContainer()
            local count = container ~= nil and container:CanAcceptCount(item) or 0
            if count > 0 then
                local stack = item.components.stackable
                local partial = stack ~= nil and count < stack:StackSize()
                local accepted = partial and stack:Get(count) or item
                -- Keep the native pickup callback, including items it consumes.
                if not accepted.components.inventoryitem:OnPickup(player, src_pos) then
                    if not self.ignoresound then
                        player:PushEvent('gotnewitem', {item=accepted})
                    end
                    if not container:GiveItem(accepted, nil, src_pos, false) then
                        -- A third-party container hook may reject after the capacity check.
                        -- Keep the item by returning it through the normal inventory path.
                        local result = give(self, accepted, slot, src_pos, ...)
                        if not partial then return result end
                    end
                end
                if not partial then return true end
            end
        end
        return give(self, item, slot, src_pos, ...)
    end
end

local function CloseFromHUD(hud, chest)
    if TheWorld.ismastersim then
        local storage = hud.owner.components.nyx_gem_storage
        if storage ~= nil then storage:Close() end
    else
        SendModRPCToServer(GetModRPC('NYX', 'CLOSE_GEM_STORAGE'))
        chest.replica.container:Close()
    end
end

local function IsInsideWidget(widget, x, y)
    local entity = TheInput:GetHUDEntityUnderMouse()
    local hovered = entity ~= nil and entity.widget or nil
    while hovered ~= nil do
        if hovered == widget then return true end
        hovered = hovered.parent
    end
    -- Include the background and gaps between the 6x6 slots, which may not
    -- produce a HUD hit. GetScale includes the user's HUD scale and parents.
    local pos, scale = widget:GetWorldPosition(), widget:GetScale()
    return math.abs(x-pos.x) <= 260*math.abs(scale.x)
        and math.abs(y-pos.y) <= 260*math.abs(scale.y)
end

function M.InstallEscape(api)
    api.AddModRPCHandler('NYX', 'CLOSE_GEM_STORAGE', function(player)
        local storage = player ~= nil and player.components.nyx_gem_storage or nil
        if storage ~= nil then storage:Close() end
    end)
    if TheNet:IsDedicated() then return end
    api.AddClassPostConstruct('screens/playerhud', function(hud)
        local oncontrol = hud.OnControl
        hud.OnControl = function(self, control, down, ...)
            if control == CONTROL_PAUSE and not down and not TheInput:ControllerAttached()
                and self.shown and self.controls ~= nil and self.controls.containers ~= nil then
                for chest, widget in pairs(self.controls.containers) do
                    if chest.prefab == 'nyx_gem_storage' and chest:IsValid()
                        and widget ~= nil and widget.isopen then
                        CloseFromHUD(self, chest)
                        return true
                    end
                end
            end
            return oncontrol(self, control, down, ...)
        end
        local onmousebutton = hud.OnMouseButton
        hud.OnMouseButton = function(self, button, down, x, y, ...)
            if down and (button == MOUSEBUTTON_LEFT or button == MOUSEBUTTON_RIGHT)
                and self.shown and self.controls ~= nil and self.controls.containers ~= nil then
                for chest, widget in pairs(self.controls.containers) do
                    if chest.prefab == 'nyx_gem_storage' and chest:IsValid()
                        and widget ~= nil and widget.isopen and not IsInsideWidget(widget, x, y) then
                        CloseFromHUD(self, chest)
                        break
                    end
                end
            end
            return onmousebutton(self, button, down, x, y, ...)
        end
    end)
end

function M.Install(api)
    M.Register(require('containers'), Vector3)
    api.AddPrefabPostInit('nyx', function(inst)
        if TheWorld.ismastersim then inst:AddComponent('nyx_gem_storage') end
    end)
    api.AddComponentPostInit('inventory', M.InstallPickup)
    api.AddModRPCHandler('NYX', 'GEM_STORAGE', function(player)
        local storage = player ~= nil and player.prefab == 'nyx'
            and player.components.nyx_gem_storage or nil
        if storage == nil then return end
        local now = GetTime()
        if storage.last_toggle ~= nil and now-storage.last_toggle < .25 then return end
        storage.last_toggle = now
        storage:Toggle()
    end)
    M.InstallEscape(api)
    if not TheNet:IsDedicated() then
        api.AddClassPostConstruct('widgets/containerwidget', function(widget)
            local close = widget.Close
            widget.Close = function(self, ...)
                local is_gem_storage = self.container ~= nil
                    and self.container.prefab == 'nyx_gem_storage'
                local result = close(self, ...)
                -- Native Close leaves the background visible until a simulation
                -- timer disposes the widget. Hide our 6x6 panel immediately so its
                -- closing frame cannot linger as a dark bar (including on pause).
                -- Native Open calls Show again; keep native cleanup unchanged.
                if is_gem_storage then self:Hide() end
                return result
            end
        end)
        -- Solo Leveling is optional. AddClassPostConstruct requires its module
        -- immediately, so probe it before registering this compatibility hook.
        local available, summary = pcall(require, 'widgets/hh_ui/hh_equip_ui')
        if not available or type(summary) ~= 'table' then return end
        -- Remove the old summary's two bulk-processing buttons for Nyx as well.
        api.AddClassPostConstruct('widgets/hh_ui/hh_equip_ui', function(widget)
            if widget.owner == nil or widget.owner.prefab ~= 'nyx' then return end
            local panel = widget.hh_main
            if panel == nil then return end
            for _, key in ipairs({'hh_put_in', 'hh_disassembly_btn'}) do
                if panel[key] ~= nil then panel[key]:Kill(); panel[key] = nil end
            end
        end)
    end
end

return M
