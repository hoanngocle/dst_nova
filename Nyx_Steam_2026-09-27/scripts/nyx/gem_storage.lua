local M = {}

-- Exact prefab names: do not accept equipment or unrelated mod items by tag/prefix.
local allowed = {
    redgem=true, bluegem=true, purplegem=true, orangegem=true,
    yellowgem=true, greengem=true, opalpreciousgem=true,
    hh_effect_stone=true, hh_effect_tally=true, hh_remove_stone=true,
    ac_refreshstone=true, ad_cleanstone=true,
    wb_enhancegem=true,
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

function M.Install(api)
    M.Register(require('containers'), Vector3)
    api.AddPrefabPostInit('nyx', function(inst)
        if TheWorld.ismastersim then inst:AddComponent('nyx_gem_storage') end
    end)
    api.AddModRPCHandler('NYX', 'GEM_STORAGE', function(player)
        local storage = player ~= nil and player.prefab == 'nyx'
            and player.components.nyx_gem_storage or nil
        if storage == nil then return end
        local now = GetTime()
        if storage.last_toggle ~= nil and now-storage.last_toggle < .25 then return end
        storage.last_toggle = now
        storage:Toggle()
    end)
    if not TheNet:IsDedicated() then
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
