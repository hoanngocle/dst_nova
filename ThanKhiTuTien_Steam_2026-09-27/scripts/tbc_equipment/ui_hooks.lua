local M = {}

function M.Install(add_class_post_construct, rpc_namespace)
    add_class_post_construct("widgets/controls", function(controls)
        if controls.tbc_equipment_button ~= nil then return end
        local ImageButton = require("widgets/imagebutton")
        local button = controls:AddChild(ImageButton("images/ttk_forge/controls.xml", "primary.tex"))
        button.ignore_standard_scaling = true
        button:SetHAnchor(ANCHOR_RIGHT)
        button:SetVAnchor(ANCHOR_TOP)
        button:SetPosition(-210, -180)
        button:SetNormalScale(1, 1)
        button:SetFocusScale(1.04, 1.04)
        button:ForceImageSize(112, 38)
        button:SetFont(BODYTEXTFONT)
        button:SetTextSize(16)
        button:SetText("TRANG BỊ")
        button:SetOnClick(function()
            local namespace = MOD_RPC ~= nil and MOD_RPC[rpc_namespace] or nil
            local rpc = namespace ~= nil and namespace.tbc_equipment_open or nil
            if rpc ~= nil then SendModRPCToServer(rpc) end
        end)
        controls.tbc_equipment_button = button
    end)
end

return M
