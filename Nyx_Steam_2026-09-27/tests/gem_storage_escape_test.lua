package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path
local Rules=require('nyx/gem_storage')
CONTROL_PAUSE=10
MOUSEBUTTON_LEFT=1
MOUSEBUTTON_RIGHT=2
local hovered
TheInput={ControllerAttached=function() return false end,
    GetHUDEntityUnderMouse=function() return hovered end}
TheWorld={ismastersim=false}
local dedicated=false
TheNet={IsDedicated=function() return dedicated end}
local closes, sends, pauses=0,0,0
local handler, hook
local api={AddModRPCHandler=function(_,id,fn)
    assert(id=='CLOSE_GEM_STORAGE'); handler=fn
end, AddClassPostConstruct=function(path,fn)
    assert(path=='screens/playerhud'); hook=fn
end}
function GetModRPC(namespace,id) assert(namespace=='NYX' and id=='CLOSE_GEM_STORAGE'); return 42 end
function SendModRPCToServer(rpc) assert(rpc==42); sends=sends+1 end
Rules.InstallEscape(api)
local chest={prefab='nyx_gem_storage',IsValid=function() return true end,
    replica={container={Close=function() closes=closes+1 end}}}
local player={components={nyx_gem_storage={Close=function() closes=closes+1 end}}}
local widget={isopen=true,GetWorldPosition=function() return {x=500,y=400} end,
    GetScale=function() return {x=.5,y=.5} end}
local mouse_calls=0
local hud={shown=true,owner=player,controls={containers={[chest]=widget}},
    OnMouseButton=function() mouse_calls=mouse_calls+1; return 'native' end,
    OnControl=function() pauses=pauses+1; return false end}
hook(hud)
assert(not hud:OnControl(CONTROL_PAUSE,true))
assert(hud:OnControl(CONTROL_PAUSE,false))
assert(sends==1 and closes==1 and pauses==1,'release closes private box without System')
TheWorld.ismastersim=true
assert(hud:OnControl(CONTROL_PAUSE,false))
assert(sends==1 and closes==2,'host closes directly')
widget.isopen=false
assert(not hud:OnControl(CONTROL_PAUSE,false) and pauses==2,'next Esc opens System normally')
handler(player); handler(nil); handler({components={}})
assert(closes==3,'server closes only sender storage, nil requests safe')
widget.isopen=true
TheWorld.ismastersim=false
hovered={widget={parent={parent=widget}}}
assert(hud:OnMouseButton(MOUSEBUTTON_LEFT,true,500,400)=='native')
assert(closes==3,'clicking a slot/tile does not close the box')
hovered=nil
hud:OnMouseButton(MOUSEBUTTON_LEFT,true,620,520)
assert(closes==3,'blank background inside scaled box does not close it')
hud:OnMouseButton(MOUSEBUTTON_LEFT,false,900,900)
assert(closes==3,'release alone does not dismiss')
hud:OnMouseButton(MOUSEBUTTON_LEFT,true,900,900)
assert(closes==4 and sends==2,'left click outside closes client box')
TheWorld.ismastersim=true
hud:OnMouseButton(MOUSEBUTTON_RIGHT,true,900,900)
assert(closes==5 and sends==2,'right click outside closes host box')
widget.isopen=false
hud:OnMouseButton(MOUSEBUTTON_LEFT,true,900,900)
assert(closes==5 and mouse_calls==6,'outside click preserves native dispatch')
-- Inventory and backpack transfers happen outside the gem panel. A clicked
-- slot must stay protected even if native input already cleared the held item.
widget.isopen=true
local active_item
player.replica={inventory={GetActiveItem=function() return active_item end}}
local inv={}
local other_widget={isopen=true}
hud.controls.inv=inv
hud.controls.containers[{}]=other_widget
for _, master in ipairs({false,true}) do
    TheWorld.ismastersim=master
    local before_closes,before_sends,before_mouse=closes,sends,mouse_calls
    for _, root in ipairs({inv,other_widget,widget}) do
        hovered={widget={parent={parent=root}}}
        for _, button in ipairs({MOUSEBUTTON_LEFT,MOUSEBUTTON_RIGHT}) do
            assert(hud:OnMouseButton(button,true,900,900)=='native')
        end
    end
    hovered=nil
    active_item={prefab='redgem'}
    assert(hud:OnMouseButton(MOUSEBUTTON_LEFT,true,900,900)=='native')
    assert(hud:OnMouseButton(MOUSEBUTTON_RIGHT,true,900,900)=='native')
    active_item=nil
    assert(closes==before_closes and sends==before_sends,
        'taking/storing/splitting items must not dismiss gem storage')
    assert(mouse_calls==before_mouse+8,'item interactions retain native dispatch')
end
TheWorld.ismastersim=false
hud:OnMouseButton(MOUSEBUTTON_LEFT,true,900,900)
assert(closes==6 and sends==3,'world click resumes dismissal after transfer')
dedicated=true
handler=nil
hook=nil
Rules.InstallEscape(api)
assert(handler~=nil and hook==nil,'dedicated server registers close RPC without client HUD')
handler(player)
assert(closes==7)
print('gem_storage_escape_test: ok')
