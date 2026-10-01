package.path="TienIchTuTien_Steam_2026-09-27/scripts/?.lua;"..package.path
local path=assert(os.getenv("DST_TEST_SCRIPTS"),"set DST_TEST_SCRIPTS to extracted DST scripts")
dofile(path.."/class.lua")
unpack=table.unpack
local Widget=Class(function(self,name) self.name=name;self.children={};self.shown=true end)
function Widget:AddChild(child) self.children[#self.children+1]=child;return child end
function Widget:SetString(text) self.text_value=text end
function Widget:SetText(text) self.text_value=text end
function Widget:SetTruncatedString(text) self.text_value=text end
function Widget:SetOnClick(fn) self.click=fn end
function Widget:Hide() self.shown=false end
function Widget:Show() self.shown=true end
function Widget:Enable() self.enabled=true end
function Widget:Disable() self.enabled=false end
function Widget:SetFocus() end
function Widget:OnControl() return false end
for _,key in ipairs({"SetScaleMode","SetHAnchor","SetVAnchor","SetPosition","SetTint","SetSize",
    "SetClickable","SetColour","SetFont","SetTextSize","SetTextColour","SetTextFocusColour",
    "SetRegionSize","SetHAlign","SetHoverText","SetFocusChangeDir","StartUpdating","StopUpdating"}) do
    Widget[key]=function() end
end
function Widget:ForceImageSize() end
function Widget:OnDestroy() end
function Widget:StartUpdating() self.widget_scheduled=true end
local ImageButton=Class(Widget,function(self) Widget._ctor(self);self.image=Widget() end)
for _,key in ipairs({"widgets/screen","widgets/widget","widgets/image","widgets/text","widgets/textbutton"}) do
    package.preload[key]=function() return Widget end
end
package.preload["widgets/imagebutton"]=function() return ImageButton end
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
assert(screen.rows[1].label.text_value=="Buff 13","long buff lists need accessible subsequent pages")
snapshot.tabs[4]={{"Buff còn lại","1"}};screen:OnUpdate(.6)
assert(screen.page==1 and screen.rows[1].label.text_value=="Buff còn lại","expiration clamps page and refreshes rows")
assert(not screen.rows[2].root.shown,"removed buffs must not leave stale visible rows")
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
