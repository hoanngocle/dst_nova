package.path="TienIchTuTien_Steam_2026-09-27/scripts/?.lua;"..package.path
local path=assert(os.getenv("DST_TEST_SCRIPTS"),"set DST_TEST_SCRIPTS to extracted DST scripts")
dofile(path.."/class.lua")
unpack=table.unpack
local Widget=Class(function(self,name) self.name=name;self.children={};self.shown=true end)
function Widget:AddChild(child) self.children[#self.children+1]=child;return child end
function Widget:SetString(text) self.text_value=text end
function Widget:SetText(text) self.text_value=text end
function Widget:SetTruncatedString(text,width)
    self.text_value=text
    return (utf8.len(text) or #text)*(self.fontsize or 19)*.5<=width
end
function Widget:SetOnClick(fn) self.click=fn end
function Widget:Hide() self.shown=false end
function Widget:Show() self.shown=true end
function Widget:Enable() self.enabled=true end
function Widget:Disable() self.enabled=false end
function Widget:SetFocus() end
function Widget:OnControl() return false end
for _,key in ipairs({"SetScaleMode","SetHAnchor","SetVAnchor","SetPosition","SetTint","SetSize",
    "SetClickable","SetColour","SetFont","SetTextSize","SetTextColour","SetTextFocusColour",
    "SetRegionSize","SetHAlign","SetHoverText","SetFocusChangeDir","StartUpdating","StopUpdating",
    "SetScale","SetMaxPropUpscale","MoveToFront","MoveToBack","EnableWordWrap"}) do
    Widget[key]=function() end
end
function Widget:SetRegionSize(w,h) self.region={w,h} end
function Widget:SetSize(w,h) self.size={w,h} end
function Widget:GetRegionSize()
    if self.region then return unpack(self.region) end
    return math.min(300,(utf8.len(self.text_value or '') or 0)*8),self.lines and self.lines*18 or 36
end
function Widget:GetString() return self.text_value or '' end
function Widget:SetMultilineTruncatedString(text,maxlines,width)
    self.region=nil;self.text_value=text
    self.lines=math.min(maxlines,math.max(1,math.ceil((utf8.len(text) or #text)*8/width)))
end
function Widget:Kill() self.shown=false end
function Widget:OnGainFocus() end
function Widget:OnLoseFocus() end
function Widget:ClearHoverText() self.hovertext=nil;self.hovertext_bg=nil end
local Text=Class(Widget,function(self,font,size,text) Widget._ctor(self);self.fontsize=size;self.text_value=text end)
function Widget:ForceImageSize() end
function Widget:OnDestroy() end
function Widget:StartUpdating() self.widget_scheduled=true end
local ImageButton=Class(Widget,function(self) Widget._ctor(self);self.image=Widget() end)
for _,key in ipairs({"widgets/screen","widgets/widget","widgets/image","widgets/text","widgets/textbutton"}) do
    package.preload[key]=function() return Widget end
end
package.preload['widgets/text']=function() return Text end
package.preload["widgets/imagebutton"]=function() return ImageButton end
-- Exercise native hover backdrop expansion instead of a no-op UI mock.
if os.getenv('DST_WIDGET_SOURCE') then
    local f=assert(io.open(os.getenv('DST_WIDGET_SOURCE'),'rb'))
    local source=f:read('*a'):gsub('\r','');f:close()
    local start=assert(source:find('function Widget:SetHoverText',1,true))
    local finish=assert(source:find('\nfunction ',start+1,true))
    assert(load('local Widget, Image = ...\n'..source:sub(start,finish-1)))(Widget,Widget)
end
CONTROL_CANCEL=1;CONTROL_SCROLLBACK=2;CONTROL_SCROLLFWD=3
local active,popped
TheFrontEnd={GetActiveScreen=function() return active end,PopScreen=function(_,s) popped=s end}
local ok,Screen=pcall(require,"screens/ttk_character_info_screen")
assert(ok,"character information screen must exist")
local owner={IsValid=function() return true end}
local snapshot={tabs={{{"Máu","50 / 100"}},{},{},{}},name="Nyx"}
for i=1,25 do snapshot.tabs[4][i]={"Buff "..i,tostring(i)} end
local requests,closed=0,false
local info={Request=function() requests=requests+1 end,Read=function() return snapshot end}
local screen=Screen(owner,info,function() closed=true end);active=screen
local initial=requests
-- Native FrontEnd updates the active screen, then registered updating widgets.
screen:OnUpdate(.25)
if screen.widget_scheduled then screen:OnUpdate(.25) end
assert(requests==initial,"native screen and widget loops must not double the polling frequency")
screen:OnUpdate(.6)
assert(requests>0 and screen.rows[1].label.text_value=="Máu")
screen:SelectTab(4);screen:ChangePage(1)
assert(screen.rows[1].label.text_value=="Buff 11","long buff lists need accessible subsequent pages")
snapshot.tabs[4]={{string.rep('Nguồn buff rất dài ',30),string.rep('Chi tiết ',35)}}
screen:OnUpdate(.6)
local hover=screen.rows[1].background.hovertext_bg
if os.getenv('DST_WIDGET_SOURCE') then
    assert(hover and hover.size[1]<=340 and hover.size[2]<=130,'native row tooltip must stay compact')
end
snapshot.tabs[4]={{"Buff còn lại","1"}};screen:OnUpdate(.6)
assert(screen.page==1 and screen.rows[1].label.text_value=="Buff còn lại","expiration clamps page and refreshes rows")
assert(not screen.rows[2].root.shown,"removed buffs must not leave stale visible rows")
assert(not screen.rows[1].background.hovertext,'fully readable rows should not obscure the table with a tooltip')
snapshot=nil;screen:OnUpdate(.6)
assert(not screen.rows[1].root.shown,"expired data must clear displayed statistics")
assert(screen:OnControl(CONTROL_CANCEL,false) and closed and popped==screen)
local before=requests;screen:OnUpdate(1)
assert(requests==before,"closed screen must not keep polling")
local externally_closed=false
local other=Screen(owner,info,function() externally_closed=true end)
other:OnDestroy()
assert(externally_closed and other.closed,"external pop must clear HUD screen ownership")
print("character_info_screen_test: ok")
