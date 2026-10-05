package.path='TienIchTuTien_Steam_2026-09-27/scripts/?.lua;'
    ..'ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;'..package.path
local Detail=require('ttk_item_detail')
local Banner=require('tbc_soul_banner')
local item={prefab='vanhonphien',components={},
    IsValid=function() return true end,
    HasTag=function(_,tag) return tag=='tbc_upgradeable' or tag=='weapon' end,
    GetDisplayName=function() return 'Vạn Linh Phiên' end,
    _tbc_detail={value=function() return '16;' end}}
local source={max_affixes=5,soul_banner_damage=Banner.Damage,soul_banner_crit=Banner.CritBonus}
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
local sim_post_init
local xd_widget={SetNew=function() end}
local G={TheNet={IsDedicated=function() return false end},UIFONT='font',unpack=unpack or table.unpack,
    TTK_EQUIPMENT_DETAIL_SOURCE=source,KnownModIndex=nil,pcall=pcall,
    TheInput={GetHUDEntityUnderMouse=function() return {widget={item=item}} end,
        GetWorldEntityUnderMouse=function() end,GetScreenPosition=function() return {x=20,y=30} end},
    require=function(name)
        if name=='widgets/xd_showhoverui' then return xd_widget end
        assert(name=='widgets/image' or name=='widgets/text');return Widget
    end}
-- DST modmain/modimport does not export select; standard required modules do.
local env={GLOBAL=G,require=require,print=function() end,type=type,ipairs=ipairs,pairs=pairs,
    math=math,tostring=tostring,
    AddClassPostConstruct=function(name,fn) callbacks[name]=fn end,
    AddSimPostInit=function(fn) sim_post_init=fn end}
assert(env.select==nil)
local chunk=assert(loadfile('TienIchTuTien_Steam_2026-09-27/main/ttk_item_detail.lua'))
setfenv(chunk,env);chunk()
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
sim_post_init()
assert(hover:OnUpdate(.1)=='original result')
assert(old_calls==2 and not hover.text.shown,
    'Tu Tien detail panel must not overlap the standard hover text')
assert(not hover.ttk_title.shown,
    'Tu Tien detail panel must not overlap the standard hover title')
item={prefab='ordinary',IsValid=function() return true end}
hover.str='Ordinary item'
assert(hover:OnUpdate(.1)=='original result')
assert(hover.text.shown, 'ordinary item hover remains visible after equipment')
item=nil
assert(hover:OnUpdate(.1)=='original result')
assert(old_calls==4 and not hover.ttk_title.shown)
print('item_detail_hooks_test: DST sandbox hover and container tooltip passed')
