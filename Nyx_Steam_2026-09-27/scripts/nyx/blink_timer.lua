-- Use the same cooldown list as Tu Tien characters (widgets/xd_skilltimer).
-- Read the replicated server cooldown so reconnects also restore the display.
local M = {}
local NAME = 'Hồi chiêu Thuấn Ảnh'
function M.Update(owner, snapshot)
    local controls = owner and owner.HUD and owner.HUD.controls
    local timer = controls and controls.xd_skilltimer
    if not timer or not snapshot.ready then return end
    local remaining = math.max(0, tonumber(snapshot.blink_cd) or 0)
    if remaining > 0 then
        if timer._nyx_blink_remaining ~= remaining or not timer:HasBuff(NAME) then
            timer:AddBuff(NAME, remaining)
        end
    elseif timer:HasBuff(NAME) then
        -- Native RemoveBuff assumes that the row exists.
        timer:RemoveBuff(NAME)
    end
    timer._nyx_blink_remaining = remaining
end
return M
