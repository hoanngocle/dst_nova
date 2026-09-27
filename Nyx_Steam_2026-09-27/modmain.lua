local G=GLOBAL
G.setmetatable(env,{__index=function(_,key) return G.rawget(G,key) end})
PrefabFiles={'nyx','nyx_none','nyx_skillbook','nyx_domain_fx','nyx_gather_fx','nyx_wings_fx','nyx_htz_xtzlj','nyx_wmz_spell','nyx_ice_fx'}
Assets={Asset('ANIM','anim/nyx_purple.zip'),Asset('ANIM','anim/nyx_ghost.zip'),
    Asset('ANIM','anim/status_xd_htz_lq.zip')}
for _,path in ipairs({'images/nyx_eye_icon','images/nyx_night_icon','images/nyx_triflame_icon','images/nyx_yellow_river_icon','images/nyx_skill_icons','images/nyx_skill_toggle','images/nyx_skin_dress_icon',
    'images/nyx_skin_ui/frame','images/nyx_skin_ui/controls','images/nyx_skin_ui/close_icon','images/saveslot_portraits/nyx',
    'images/selectscreen_portraits/nyx','images/selectscreen_portraits/nyx_silho','images/map_icons/nyx',
    'images/avatars/avatar_nyx','images/avatars/avatar_ghost_nyx','images/avatars/self_inspect_nyx','bigportraits/nyx','bigportraits/nyx_none'}) do
    Assets[#Assets+1]=Asset('ATLAS',path..'.xml'); Assets[#Assets+1]=Asset('IMAGE',path..'.tex')
end
Assets[#Assets+1]=Asset('IMAGE','images/names_gold_nyx.tex')
for _,path in ipairs({'images/names_gold_nyx.xml','images/names_gold_cn_nyx.xml','images/names_nyx.xml'}) do
    Assets[#Assets+1]=Asset('ATLAS',path)
end
AddMinimapAtlas('images/map_icons/nyx.xml')
STRINGS.CHARACTER_TITLES.nyx='Tử Tiêu Tiên Ảnh'
STRINGS.CHARACTER_NAMES.nyx='Nyx'
STRINGS.CHARACTER_DESCRIPTIONS.nyx='*5 chiêu chiến đấu, 3 tiện ích\n*Linh Lực ban đầu: 60\n*Khô Vinh Song Sinh, Vạn Linh Phiên'
STRINGS.CHARACTER_QUOTES.nyx='Một ý niệm, vạn pháp quy nhất.'
STRINGS.CHARACTER_SURVIVABILITY.nyx='Khó'
STRINGS.CHARACTERS.NYX=require('speech_wendy')
STRINGS.NAMES.NYX='Nyx'
STRINGS.SKIN_NAMES.nyx_none='Nyx'
AddModCharacter('nyx','FEMALE',{{type='ghost_skin',anim_bank='ghost',idle_anim='idle',scale=.75,offset={0,-25}}})
require('nyx/register_effects')
require('util/nyx_skill_damage').InstallNativeHook(AddComponentPostInit)
AddPrefabPostInit('wilson',require('nyx/dps_compat').Protect)
local Router=require('nyx/input')
AddModRPCHandler('NYX','IMMEDIATE',function(player,id)
    local d=type(id)=='string' and require('nyx/skilldefs').Get(id)
    if d and d.target~='point' then Router.Request(player,id) end
end)
Router.send=function(id) SendModRPCToServer(MOD_RPC.NYX.IMMEDIATE,id) end
AddModRPCHandler('NYX','APPEARANCE',function(player,build)
    if player and player.prefab=='nyx' and player.components.nyx_appearance then
        local now=GetTime()
        if not player._nyx_skin_time or now-player._nyx_skin_time>=.3 then
            player._nyx_skin_time=now; player.components.nyx_appearance:Set(build)
        end
    end
end)
local blink=AddAction('NYX_BLINK','Thuấn Ảnh',Router.CastBlink)
blink.rmb=true; blink.priority=1; blink.distance=math.huge; blink.invalid_hold_action=true; blink.mount_valid=false
require('nyx/states').Install({add_state=AddStategraphState,add_postinit=AddStategraphPostInit,add_action_handler=AddStategraphActionHandler})
AddComponentPostInit('playeractionpicker',function(picker)
    local old=picker.GetRightClickActions
    picker.GetRightClickActions=function(self,pos,target,book)
        local actions=old(self,pos,target,book)
        if actions and #actions>0 then return actions end
        if Router.CanUseGroundBlink(self.inst,pos,target,book,TheFrontEnd) then return {BufferedAction(self.inst,nil,ACTIONS.NYX_BLINK,nil,pos)} end
        return actions or {}
    end
end)
require('nyx/items').Install(env)
require('nyx/soul_banner').Install(env)
require('nyx/cauldron').Install(env)
require('nyx/unique_weapons').Install(env)
require('nyx/unique_deploy').Install(env)
require('nyx/unique_inventory').Install(env)
require('nyx/unique_cloud').Install(env)
if not TheNet:IsDedicated() then require('nyx/unique_map').Install(env) end
local _, recipes_missing = require('nyx/recipes').Register(env)
if #recipes_missing > 0 then
    print('[Nyx] Tu Tiên source recipes unavailable: '..table.concat(recipes_missing, ', '))
end
if not TheNet:IsDedicated() then
    require('nyx/huaxia_layout').Install(AddClassPostConstruct)
    local Panel=require('widgets/nyx_skillpanel')
    local Resource=require('widgets/nyx_resource')
    local ImageButton=require('widgets/imagebutton')
    AddClassPostConstruct('widgets/controls',function(controls)
        if not controls.owner or controls.owner.prefab~='nyx' then return end
        controls.nyx_skillpanel=controls:AddChild(Panel(controls.owner))
        local status=controls.status or controls.statusdisplays or controls
        controls.owner.nyx_resourcehud=status:AddChild(Resource(controls.owner))
        require('nyx/hud_layout').Apply(controls)
        local button=controls.nyx_skillpanel:AddChild(ImageButton('images/nyx_skin_dress_icon.xml','nyx_skin_dress_icon.tex'))
        controls.nyx_skillpanel.appearance_button=button
        require('nyx/hud_layout').ConfigurePanel(controls.nyx_skillpanel)
        button:SetHoverText('Trang phục')
        button:SetOnClick(function()
            TheFrontEnd:PushScreen(require('screens/nyx_skin_screen')(function(build) SendModRPCToServer(MOD_RPC.NYX.APPEARANCE,build) end))
        end)
    end)
end

require('nyx/character_info').Install(env)
