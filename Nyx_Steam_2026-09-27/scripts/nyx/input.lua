local Defs=require('nyx/skilldefs')
local Net=require('nyx/skillnet')
local R={SKILLS={},SPELL_INDEX={}}
local custom_icons={triflame_fan='nyx_triflame_icon',yellow_river='nyx_yellow_river_icon',eternal_night='nyx_night_icon',purple_eye='nyx_eye_icon',bean_soldiers='nyx_clone_icon'}
local textures={'life','array','daydu','daydu','array','harvest','life','wings','array'}
for i,id in ipairs(Defs.Order()) do
    local d=Defs.Get(id)
    R.SKILLS[id]={label=d.name,tooltip=d.name,range=d.range,atlas='images/nyx_skill_icons.xml',texture='nyx_skill_'..textures[i]..'.tex'}
    local icon=custom_icons[id]
    if icon then
        R.SKILLS[id].atlas='images/'..icon..'.xml'
        R.SKILLS[id].texture=icon..'.tex'
    end
    if id=='bean_soldiers' then
        R.SKILLS[id].tooltip=d.name..' · 3 phân thân; máu ×12 và hệ số Nguyên Thần; mỗi đòn nền 20 × level; đậu nổ nền 200 + 100 mỗi 10 level. Cả hai không giới hạn, cộng sát thương vũ khí và tính bonus Nyx.'
    end
    R.SPELL_INDEX[id]=i
end
function R.GetBoundBook(p)
    return p and p._nyx_skillbook and p._nyx_skillbook:value() or nil
end
function R.IsBoundBook(b,p) return p and p.prefab=='nyx' and b and b:IsValid() and R.GetBoundBook(p)==b and b:GetNyxOwner()==p end
function R.CanUsePanel(p,f)
    local screen=f and f:GetActiveScreen()
    return p and p.prefab=='nyx' and not p:HasTag('playerghost') and screen and screen.name=='HUD'
        and not f:IsControlsDisabled() and (not p.HUD or not p.HUD:HasInputFocus())
end
function R.IsSkillUnlocked(p,id) local s=Net.Read(p); return s.ready and s.unlocked and s.unlocked[id] end
function R.RequestImmediate(id) if R.send then R.send(id) end end
function R.ActivateSkill(p,f,id)
    if not R.CanUsePanel(p,f) or not R.IsSkillUnlocked(p,id) then return false end
    local b=R.GetBoundBook(p); local index=R.SPELL_INDEX[id]
    if not R.IsBoundBook(b,p) or not index then return false end
    if b.components.spellbook:SelectSpell(index) then b.components.spellbook.items[index].execute(b); return true end
end
function R.Request(p,id,pos)
    if not p or p.prefab~='nyx' or not p.components.nyx_skills then return false end
    local now=GetTime()
    if p._nyx_request_time and now-p._nyx_request_time<.2 then return false end
    p._nyx_request_time=now
    p._nyx_request_id=(p._nyx_request_id or 0)%2147483646+1
    return p.components.nyx_skills:Request(id,pos or {},p._nyx_request_id)
end
function R.CastAt(book,p,id,x,z)
    if not R.IsBoundBook(book,p) or book._nyx_selected_skill~=id then return false end
    p._nyx_cast_authorized=true
    local ok,result=pcall(R.Request,p,id,{x=x,z=z})
    p._nyx_cast_authorized=nil
    return ok and result or false
end
function R.CanEnterNativeCast(p,a)
    local b=a and a.invobject; local id=b and b._nyx_selected_skill; local d=Defs.Get(id)
    return a and a.action==ACTIONS.CASTAOE and d and d.target=='point' and R.IsBoundBook(b,p) and R.IsSkillUnlocked(p,id)
end
function R.CanUseGroundBlink(p,position,target,spellbook,f)
    if not p or p.prefab~='nyx' or p:HasTag('playerghost') or spellbook or not position then return false end
    if target and not target:HasTag('walkableplatform') and not target:HasTag('walkableperipheral') then return false end
    if f and p==ThePlayer and not R.CanUsePanel(p,f) then return false end
    local c=p.components.playercontroller
    if not c or c:IsAOETargeting() or c.placer or c.deployplacer then return false end
    if not p.replica.inventory or p.replica.inventory:GetActiveItem() then return false end
    if p.replica.rider and p.replica.rider:IsRiding() then return false end
    return (Net.Read(p).blink_cd or 0)<=0
end
function R.CastBlink(a)
    local p=a.doer; local pos=a:GetActionPoint()
    if not p or p.prefab~='nyx' or not p.components.nyx_blink or not pos then return false end
    p._nyx_cast_authorized=true
    local ok,result=pcall(p.components.nyx_blink.CastAt,p.components.nyx_blink,pos.x,pos.z)
    p._nyx_cast_authorized=nil
    return ok and result or false
end
return R
