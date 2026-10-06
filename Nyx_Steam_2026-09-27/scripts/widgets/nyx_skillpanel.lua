local Widget=require('widgets/widget')
local ImageButton=require('widgets/imagebutton')
local Text=require('widgets/text')
local R=require('nyx/input')
local Net=require('nyx/skillnet')
local Defs=require('nyx/skilldefs')
local P=require('nyx/progression')
local Panel=Class(Widget,function(self,owner)
    Widget._ctor(self,'NyxSkillPanel'); self.owner=owner; self.icons={}; self.expanded=true; self.focused_skill=nil
    self.collapse=self:AddChild(ImageButton('images/nyx_skill_toggle.xml','nyx_skill_toggle.tex'))
    self.collapse:SetOnClick(function()
        self.expanded=not self.expanded
        for _,b in pairs(self.icons) do if self.expanded then b:Show() else b:Hide() end end
    end)
    self.collapse:SetHoverText('Nyx · Mở / thu gọn kỹ năng')
    self.skill_tooltip_text=self:AddChild(Text(BODYTEXTFONT,21,''))
    self.skill_tooltip_text:SetClickable(false); self.skill_tooltip_text:Hide()
    for _,id in ipairs(Defs.Order()) do
        local skill=id; local d=Defs.Get(skill); local icon=R.SKILLS[skill]
        local b=self:AddChild(ImageButton(icon.atlas,icon.texture))
        b.cooldown=b:AddChild(Text(NUMBERFONT,26,''))
        b.label=b:AddChild(Text(BODYTEXTFONT,17,d.short)); b.label:SetPosition(0,-39)
        b:SetOnClick(function() R.ActivateSkill(owner,TheFrontEnd,skill) end)
        b.ongainfocus=function() self.focused_skill=skill; self.skill_tooltip_text:Show() end
        b.onlosefocus=function() self.focused_skill=nil; self.skill_tooltip_text:Hide() end
        self.icons[skill]=b
    end
    self:StartUpdating()
end)
function Panel:OnUpdate()
    local s=Net.Read(self.owner)
    require('nyx/blink_timer').Update(self.owner,s)
    for id,b in pairs(self.icons) do
        local unlocked=s.ready and s.unlocked and s.unlocked[id]
        local cd=s.cooldowns and s.cooldowns[id] or 0
        local active=s.active and s.active[id]
        b.cooldown:SetString(not unlocked and '×' or active and '●' or cd>0 and tostring(math.ceil(cd)) or '')
        if active then b:SetImageNormalColour(.8,.45,1,1)
        elseif not unlocked or cd>0 then b:SetImageNormalColour(.4,.4,.45,1)
        else b:SetImageNormalColour(1,1,1,1) end
    end
    if self.focused_skill then
        local d=Defs.Get(self.focused_skill)
        local gate=d.gate.kind=='realm' and P.Realms[d.gate.value+1] or d.gate.kind=='level' and ('Cấp '..d.gate.value) or 'Có sẵn'
        local info=P.SkillCost(d,s.level)..' Linh Lực · Hồi '..d.cooldown..' giây'
        local title=d.name..' · '..gate
        if d.id=='purple_gather' then
            local level=s.level or 0
            title=d.name..' - Cấp '..P.GatherTier(level)
            info=info..'\nBán kính ảnh hưởng: '..P.Radius(level)
        elseif d.id=='moon_wings' then info=P.WingDrain(s.level or 0)..' Linh Lực/giây · Bấm để bật/tắt'
        elseif d.id=='purple_eye' then info=P.EyeDrain(s.level or 0)..' Linh Lực/giây · Bấm để bật/tắt' end
        self.skill_tooltip_text:SetString(title..'\n'..(s.ready and info or s.reason or 'Đang nạp dữ liệu...'))
    end
end
return Panel
