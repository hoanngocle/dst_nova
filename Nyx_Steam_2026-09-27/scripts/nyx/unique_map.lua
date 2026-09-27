-- Open native Beidou map targeting for Nyx. Native action validates ownership/cost.
local M={}
function M.Install(api)
local function ShouldUseBeidouGuideMap(inst)
    return inst ~= nil
        and inst.prefab == "nyx"
        and inst.replica ~= nil
        and inst.replica.inventory ~= nil
        and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= nil
        and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "xd_chenpingan_bd"
end

api.AddClassPostConstruct("widgets/controls", function(self)
    local old_ToggleMap = self.ToggleMap
    function self:ToggleMap()
        local was_open = self.owner ~= nil and self.owner.HUD ~= nil and self.owner.HUD:IsMapScreenOpen()
        local use_beidou = not was_open and ShouldUseBeidouGuideMap(self.owner)
        local pc = use_beidou and self.owner ~= nil and self.owner.components.playercontroller or nil

        if use_beidou and MOD_RPC ~= nil and MOD_RPC["xd_skill_button"] ~= nil and MOD_RPC["xd_skill_button"]["xd_skill_button"] ~= nil then
            SendModRPCToServer(MOD_RPC["xd_skill_button"]["xd_skill_button"], "xd_chenpingan_bd_map")
        end

        if pc ~= nil then
            pc.skip_inherentmapaction = true
        end
        old_ToggleMap(self)
        if pc ~= nil then
            pc.skip_inherentmapaction = nil
        end

        if use_beidou and self.owner ~= nil and self.owner.HUD ~= nil and self.owner.HUD:IsMapScreenOpen() then
            local mapscreen = TheFrontEnd:GetActiveScreen()
            if mapscreen ~= nil and mapscreen.SetNewMapTarget ~= nil then
                mapscreen._hack_ignore_held_controls = 1
                mapscreen._hack_ignore_ups_for = {}
                mapscreen:SetNewMapTarget(nil, ACTIONS.XD_CHENPINGAN_GUIDE_MAP)
            end
        end
    end
end)


end
return M
