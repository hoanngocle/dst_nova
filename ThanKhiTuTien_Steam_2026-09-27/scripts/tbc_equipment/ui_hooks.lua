local M = {}

function M.Install(add_class_post_construct)
    add_class_post_construct("widgets/controls", function(controls)
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
            local rpc = MOD_RPC.ThanKhiTuTien ~= nil
                and MOD_RPC.ThanKhiTuTien.tbc_equipment_open or nil
            if rpc ~= nil then SendModRPCToServer(rpc) end
        end)
        controls.tbc_equipment_button = button
    end)
end

return M
