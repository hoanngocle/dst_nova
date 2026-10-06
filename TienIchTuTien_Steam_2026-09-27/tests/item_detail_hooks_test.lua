local mod_root = os.getenv('TTK_TEST_MOD_ROOT') or 'TienIchTuTien_Steam_2026-09-27'
package.path=mod_root..'/scripts/?.lua;'
    ..'ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;'..package.path
local Detail=require('ttk_item_detail')
local Banner=require('tbc_soul_banner')
local item={prefab='vanhonphien',components={},
    IsValid=function() return true end,
    HasTag=function(_,tag) return tag=='tbc_upgradeable' or tag=='weapon' end,
    GetDisplayName=function() return 'Vạn Linh Phiên' end,
    _tbc_detail={value=function() return '16;' end}}
local source={max_affixes=5,soul_banner_damage=Banner.Damage,soul_banner_crit=Banner.CritBonus}
local equipment = item
local function Widget()
    local w={shown=true}
    function w:SetString(s) self.str=s end
    function w:SetColour() end
    function w:SetClickable() end
    function w:SetTexture() end
    function w:SetSize() end
    function w:SetPosition(x,y,z) self.position={x=x,y=y,z=z} end
    function w:GetPosition() return {x=0,y=0} end
    function w:GetRegionSize() return 400,240 end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    return w
end
local callbacks={}
local sim_init
local native_hover={SetNew=function() end}
local G={TheNet={IsDedicated=function() return false end},UIFONT='font',unpack=unpack or table.unpack,
    TTK_EQUIPMENT_DETAIL_SOURCE=source,KnownModIndex=nil,
    TheInput={GetHUDEntityUnderMouse=function() return {widget={item=item}} end,
        GetWorldEntityUnderMouse=function() end,GetScreenPosition=function() return {x=20,y=30} end},
    pcall=pcall,
    require=function(name)
        if name=='widgets/xd_showhoverui' then return native_hover end
        assert(name=='widgets/image' or name=='widgets/text');return Widget
    end}
-- DST modmain/modimport does not export select; standard required modules do.
local env={GLOBAL=G,require=require,print=function() end,type=type,ipairs=ipairs,pairs=pairs,
    math=math,tostring=tostring,
    AddClassPostConstruct=function(name,fn) callbacks[name]=fn end,
    AddSimPostInit=function(fn) sim_init=fn end}
assert(env.select==nil)
local chunk
if setfenv then
    chunk=assert(loadfile(mod_root..'/main/ttk_item_detail.lua'))
    setfenv(chunk,env)
else
    chunk=assert(loadfile(mod_root..'/main/ttk_item_detail.lua','t',env))
end
chunk()
local old_calls=0
local hover={shown=true,text=Widget(),str='Vạn Linh Phiên\nTrang bị',
    OnUpdate=function(_,dt) assert(dt==.1);old_calls=old_calls+1;return 'original result' end,
    AddChild=function(_,child) return child end,
    UpdatePosition=function(self,x,y) self.pointer={x,y} end}
callbacks['widgets/hoverer'](hover)
assert(hover:OnUpdate(.1)=='original result')
assert(old_calls==1 and hover.ttk_title.shown)
assert(hover.text.str:find('CƯỜNG HÓA',1,true))
assert(hover.text.str:find('(+16)',1,true))
assert(hover.pointer[1]==20 and hover.pointer[2]==30)
local tile={item=item,GetDescriptionString=function() return 'Vạn Linh Phiên\nTrang bị' end}
callbacks['widgets/itemtile'](tile)
assert(tile:GetDescriptionString():find('CƯỜNG HÓA',1,true))
item=nil
assert(hover:OnUpdate(.1)=='original result')
assert(old_calls==2 and not hover.ttk_title.shown)
item=equipment
sim_init()
assert(hover:OnUpdate(.1)=='original result')
assert(not hover.text.shown and not hover.ttk_title.shown,
    'standard detail must be hidden when Tu Tien owns the detail panel')
for _, icon in ipairs(hover.ttk_icons or {}) do
    assert(not icon.shown, 'standard detail icons must not overlap native detail')
end
item=nil
hover:OnUpdate(.1)
assert(hover.text.shown and not hover.ttk_title.shown,
    'ordinary tooltip must return after leaving enhanced equipment')
print('item_detail_hooks_test: DST sandbox hover and container tooltip passed')
