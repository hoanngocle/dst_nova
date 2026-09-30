local Entry=require('hn_dungeon/entry')
local function ShowConfirm(gate)
    if not gate or not gate:IsValid() or not TheFrontEnd then return end
    local active=TheFrontEnd:GetActiveScreen()
    if active and active.hn_confirm then return end
    local Popup=require('screens/redux/popupdialog')
    local screen
    screen=Popup('Chinh Phạt Hầm Ngục','Vào Hầm Ngục cùng tổ đội? Từ làn 2 không thể nhập cuộc; khi boss xuất hiện lối ra sẽ khóa.',{
        {text='Tiến vào',cb=function() TheFrontEnd:PopScreen(screen);SendModRPCToServer(GetModRPC(modname,'hn_enter_dungeon'),gate) end},
        {text='Để sau',cb=function() TheFrontEnd:PopScreen(screen) end},
    })
    screen.hn_confirm=true;TheFrontEnd:PushScreen(screen)
end
AddPlayerPostInit(function(inst)
    inst.hn_confirm_gate=net_entity(inst.GUID,'hn.confirm_gate','hn_confirm_dirty')
    if not TheWorld.ismastersim then inst:ListenForEvent('hn_confirm_dirty',function(p)
        if p==ThePlayer then ShowConfirm(p.hn_confirm_gate:value()) end
    end) end
end)
local enter=Action({priority=10,mount_valid=false});enter.id='HN_ENTER_DUNGEON';enter.str='Tiến vào'
enter.fn=function(act)
    if not act.target or act.target.prefab~='hn_dungeon_gate' then return false end
    if act.doer==ThePlayer then ShowConfirm(act.target)
    elseif TheWorld.ismastersim and act.doer.hn_confirm_gate then
        act.doer.hn_confirm_gate:set(act.target)
        act.doer:DoTaskInTime(.2,function(p) if p:IsValid() then p.hn_confirm_gate:set(nil) end end)
    end
    return true
end
AddAction(enter)
local leave=Action({priority=10,mount_valid=false});leave.id='HN_LEAVE_DUNGEON';leave.str='Rời Hầm Ngục'
leave.fn=function(act)
    local manager=TheWorld.components.hn_dungeon_manager
    if not manager or not act.target or act.target~=manager.exit or act.target:HasTag('hn_locked_by_boss')
        or not manager.players_in_dungeon[act.doer] or act.doer:HasTag('hn_dungeon_transition') then return false end
    act.doer.sg:GoToState('hn_dungeon_migrate',{mode='leave'});return true
end
AddAction(leave)
AddComponentAction('SCENE','inspectable',function(inst,doer,actions)
    if inst:HasTag('hn_dungeon_gate') and not inst:HasTag('hn_dungeon_resetting') then actions[#actions+1]=ACTIONS.HN_ENTER_DUNGEON end
    if inst:HasTag('hn_dungeon_exit') and doer:HasTag('in_hn_dungeon') and not inst:HasTag('hn_locked_by_boss') then actions[#actions+1]=ACTIONS.HN_LEAVE_DUNGEON end
end)
for _,sg in ipairs({'wilson','wilson_client'}) do
    AddStategraphActionHandler(sg,ActionHandler(ACTIONS.HN_ENTER_DUNGEON,'doshortaction'))
    AddStategraphActionHandler(sg,ActionHandler(ACTIONS.HN_LEAVE_DUNGEON,'doshortaction'))
end
AddModRPCHandler(modname,'hn_enter_dungeon',function(player,gate)
    local manager=TheWorld.components.hn_dungeon_manager
    if Entry.CanRequest(player,gate,manager) then player.sg:GoToState('hn_dungeon_migrate',{mode='enter',gate=gate}) end
end)
