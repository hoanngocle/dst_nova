local M = {}

function M.Install(add_class_post_construct, rpc_namespace)
    add_class_post_construct("widgets/redux/craftingmenu_skinselector", function(self)
        if self.recipe ~= nil and self.recipe.name == "tbc_forge"
            and self.spinner ~= nil and self.spinner.fgimage ~= nil then
            self.spinner.fgimage:SetScale(0.4)
        end
    end)
    add_class_post_construct("widgets/containerwidget", function(self)
        local open = self.Open
        self.Open = function(widget, container, ...)
            open(widget, container, ...)
            local ui_path = container.prefab == "tbc_forge" and "widgets/tbc_forge_ui"
                or container.prefab == "tbc_equipment_box" and "widgets/tbc_equipment_ui"
                or container.prefab == "tbc_suit_build" and "widgets/tbc_suit_forge_ui"
                or nil
            if ui_path == nil or not widget.isopen then return end
            -- Match Solo's container-level placement so the native inventory
            -- slot and the custom forge surface share one responsive transform.
            widget:SetVAnchor(ANCHOR_MIDDLE)
            widget:SetHAnchor(ANCHOR_MIDDLE)
            widget:SetScaleMode(SCALEMODE_PROPORTIONAL)
            -- Scale the container itself so its native equipment slot stays
            -- aligned with the custom frame and controls.
            local x, y, z = widget.inst.UITransform:GetScale()
            widget.tbc_original_scale = { x, y, z }
            widget:SetScale(x * .9, y * .9, z * .9)
            widget.tbc_background = { widget.bganim.shown, widget.bgimage.shown }
            widget.bganim:Hide()
            widget.bgimage:Hide()
            local owner = (...) or widget.owner or rawget(_G, "ThePlayer")
            local ui = require(ui_path)
            widget.tbc_ui = widget:AddChild(container.prefab == "tbc_equipment_box"
                and ui(owner, container, widget, false, rpc_namespace)
                or ui(owner, container, widget, rpc_namespace))
            widget.tbc_ui:MoveToBack()
            widget.tbc_refresh = function()
                if widget.tbc_ui ~= nil then widget.tbc_ui:Refresh() end
            end
            widget.inst:ListenForEvent("tbc_forge_dirty", widget.tbc_refresh, container)
            widget.inst:ListenForEvent("itemget", widget.tbc_refresh, container)
            widget.inst:ListenForEvent("itemlose", widget.tbc_refresh, container)
            if owner ~= nil and container.prefab == "tbc_equipment_box" then
                widget.inst:ListenForEvent("tbc_wallet_dirty", widget.tbc_refresh, owner)
                widget.tbc_wallet_owner = owner
            end
            widget.tbc_ui:Refresh()
        end
        local close = self.Close
        self.Close = function(widget, ...)
            if widget.tbc_ui ~= nil then
                for _, event in ipairs({ "tbc_forge_dirty", "itemget", "itemlose" }) do
                    widget.inst:RemoveEventCallback(event, widget.tbc_refresh, widget.container)
                end
                if widget.tbc_wallet_owner ~= nil then
                    widget.inst:RemoveEventCallback("tbc_wallet_dirty", widget.tbc_refresh,
                        widget.tbc_wallet_owner)
                    widget.tbc_wallet_owner = nil
                end
                widget.tbc_ui:Kill()
                widget.tbc_ui, widget.tbc_refresh = nil, nil
            end
            close(widget, ...)
            if widget.tbc_original_scale ~= nil then
                widget:SetScale(unpack(widget.tbc_original_scale))
                widget.tbc_original_scale = nil
            end
            if widget.tbc_background ~= nil then
                if widget.tbc_background[1] then widget.bganim:Show() end
                if widget.tbc_background[2] then widget.bgimage:Show() end
                widget.tbc_background = nil
            end
        end
    end)
end

return M
