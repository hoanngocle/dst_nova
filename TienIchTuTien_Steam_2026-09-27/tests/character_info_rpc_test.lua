package.path="TienIchTuTien_Steam_2026-09-27/scripts/?.lua;"..package.path
-- Use DST's own codec when supplied by the integration runner (no replacement codec).
local path=assert(os.getenv("DST_TEST_SCRIPTS"),"set DST_TEST_SCRIPTS to extracted DST scripts")
loadstring=loadstring or load -- DST uses Lua 5.1; the standalone runner uses 5.4.
local jsonenv=setmetatable({module=function() end},{__index=_G})
assert(loadfile(path.."/json.lua","t",jsonenv))()
package.preload.json=function() return jsonenv end
local ok,Info=pcall(require,"ttk_character_info")
assert(ok,"character info RPC transport must exist")
local now,requests,replies=10,0,0
local server,client
local owner={userid="KU_SELF",IsValid=function() return true end,
    components={health={currenthealth=50,maxhealth=100}}}
local G={ThePlayer=owner,GetTime=function() return now end,
    TheNet={IsDedicated=function() return true end},
    GetClientModRPC=function(_,name) return name end,
    GetModRPC=function(_,name) return name end,
    SendModRPCToClient=function(_,userid,raw,token)
        assert(userid=="KU_SELF","snapshot must only be sent to its requesting owner")
        replies=replies+1; client(raw,token)
    end,
    SendModRPCToServer=function(_,token) requests=requests+1; server(owner,token) end}
Info.Install({GLOBAL=G,modname="test",
    AddModRPCHandler=function(_,_,fn) server=fn end,
    AddClientModRPCHandler=function(_,_,fn) client=fn end})
Info.Reset(owner); Info.Request(owner)
assert(Info.Read(owner).tabs[1][1][2]=="50 / 100","remote snapshot must survive real JSON serialization")
Info.Request(owner)
assert(replies==1,"server must throttle repeated requests")
now=11;owner.components.health.currenthealth=25;Info.Request(owner)
assert(Info.Read(owner).tabs[1][1][2]=="25 / 100","refresh must replace earlier values")
client('{"version":1,"tabs":[[["Máu","99 / 100"]],[],[],[]]}',1)
assert(Info.Read(owner).tabs[1][1][2]=="25 / 100","out-of-order reply must not restore older statistics")
assert(Info.Read({})==nil,"snapshot must never leak between owners")
client('{"version":1,"tabs":false}',requests)
assert(Info.Read(owner)==nil,"malformed response must not preserve a stale valid panel")
now=15;Info.Request(owner);now=19
assert(Info.Read(owner)==nil,"expired snapshot must not claim to be current")
Info.Reset(owner);client('{"version":1,"tabs":[[],[],[],[]]}',1)
assert(Info.Read(owner)==nil,"late reply from a previous session must be ignored")
-- HUD icon retains scale updates and only opens one screen for its owner.
local function Widget()
    local w={children={}}
    function w:AddChild(child) self.children[#self.children+1]=child;return child end
    function w:SetPosition(x,y) self.position={x,y} end
    function w:SetScale(s) self.scale=s end
    function w:ForceImageSize(x,y) self.size={x,y} end
    function w:SetOnClick(fn) self.click=fn end
    for _,method in ipairs({'SetScaleMode','SetMaxPropUpscale','SetHAnchor','SetVAnchor','SetHoverText'}) do
        w[method]=function() end
    end
    return w
end
package.preload['widgets/widget']=function() return Widget end
package.preload['widgets/imagebutton']=function() return Widget end
local opened,scale=0,1.25
G.unpack=table.unpack
G.TheNet.IsDedicated=function() return false end
G.TheFrontEnd={GetHUDScale=function() return scale end,PushScreen=function() opened=opened+1 end}
package.preload['screens/ttk_character_info_screen']=function()
    return function(player,_,close) return {owner=player,close=close} end
end
local build
Info.Install({GLOBAL=G,modname='test',AddModRPCHandler=function(_,_,fn) server=fn end,
    AddClientModRPCHandler=function(_,_,fn) client=fn end,
    AddClassPostConstruct=function(_,fn) build=fn end})
local controls=Widget();controls.owner=owner
controls.SetHUDSize=function() return 'original',nil,3 end
build(controls)
assert(controls.ttk_character_info_root.scale==1.25)
scale=.75
local a,b,c=controls:SetHUDSize()
assert(a=='original' and b==nil and c==3,'HUD scale wrapper preserves original return values')
assert(controls.ttk_character_info_root.scale==.75,'icon follows user HUD scale changes')
local icon=controls.ttk_character_info_button
icon.click();icon.click()
assert(opened==1,'repeat clicks must not stack modal screens')
controls._ttk_info_screen.close()
controls.owner={};icon.click()
assert(opened==1,'icon cannot request another owner snapshot')
print("character_info_rpc_test: ok")
