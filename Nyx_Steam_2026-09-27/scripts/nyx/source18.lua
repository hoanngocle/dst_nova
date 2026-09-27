-- Uses the actual 18.1 components; cultivation and its save data remain source owned.
local P=require('nyx/progression')
local S={}
function S.Attach(inst)
    if not XD_CanAttackTrget then return false,'Thiếu Tu Tiên 18.1.' end
    if not inst.components.xd_htz_lq then inst:AddComponent('xd_htz_lq') end
    local c=inst.components.xd_htz_lq
    if not c._nyx_resource then
        c._nyx_resource=true
        -- Source DoDec debits its own two toggles. Nyx's controller owns those costs.
        c.DoDec=function(self)
            if self:IsPaused() or inst:HasTag('playerghost') or inst.components.health:IsDead() then return end
            self:DoDelta(inst:HasDebuff('xd_lingqiheal_buff') and 4 or 2,false)
        end
        inst:ListenForEvent('ms_becameghost',function() c:Pause() end)
        inst:ListenForEvent('ms_respawnedfromghost',function() c:Resume() end)
        inst:DoTaskInTime(0,function() if inst:HasTag('playerghost') then c:Pause() else c:Resume() end end)
    end
    return true
end
function S.Read(inst)
    local c=inst.components.xd_htz_lq
    local realm=inst.components.xd_level
    local level=inst.components.levelsystem
    if not c or not realm then return {ready=false,reason='Thiếu Tu Tiên 18.1.'} end
    if not level or not P.Finite(level.level) then return {ready=false,reason='Cần bật Achievement & Level bản local.'} end
    return {ready=true,level=level.level,realm_rank=realm.level,
        realm_label=P.Realms[realm.level+1] or tostring(realm.level),
        current=c.current,maximum=c.max,regen=inst:HasDebuff('xd_lingqiheal_buff') and 4 or 2}
end
function S.Spend(inst,amount)
    local c=inst.components.xd_htz_lq
    if not P.Finite(amount) or amount<0 or not c or c.current<amount then return false,'Không đủ Linh Lực.' end
    c:DoDelta(-amount)
    return true
end
function S.Refund(inst,amount)
    local c=inst.components.xd_htz_lq
    if c and P.Finite(amount) and amount>0 then c:DoDelta(amount) end
end
return S
