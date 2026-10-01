-- Solo Leveling Guardian attack sequence, rewritten around arena-owned effects.
require('stategraphs/commonstates')
local H=require('hn_dungeon/boss_hazards')
local T=require('hn_dungeon/minotau_tuning')
local function stop(inst)
    inst.components.locomotor:Stop();inst.Physics:ClearMotorVelOverride();inst.Physics:Stop()
end
local function face(inst)
    local target=inst.components.combat.target
    if H.CanTarget(inst,target) then inst:ForceFacePoint(target.Transform:GetWorldPosition());return target end
end
local function fx(inst,name,pos) return H.Spawn(inst,'hn_minotau_'..name,pos) end
local function fireRing(inst,count,radius)
    local pos=inst:GetPosition()
    for i=1,count do
        local angle=i*2*math.pi/count
        fx(inst,'shadowblaze',{x=pos.x+math.cos(angle)*radius,z=pos.z+math.sin(angle)*radius})
    end
end
local function pound(inst,shadow)
    H.Area(inst,inst:GetPosition(),6,T.SLAM_MULTIPLIER)
    fx(inst,'shadowpoundring_fx')
    inst.SoundEmitter:PlaySound('dontstarve/creatures/rook_minotaur/step')
    if shadow then H.SpawnShockwaves(inst);fireRing(inst,8,3) end
end
local function idle(inst) inst.sg:GoToState('idle') end
local function animDone(inst) if inst.AnimState:AnimDone() then idle(inst) end end
local function timer(inst,name,seconds)
    inst.components.timer:StopTimer(name);inst.components.timer:StartTimer(name,seconds)
end
local function move(inst,speed)
    inst.sg.statemem.safe=inst:GetPosition();inst.Physics:SetMotorVelOverride(speed,0,0)
end
local function checkMove(inst)
    local pos=inst:GetPosition();local safe=inst.sg.statemem.safe
    if safe and (not H.IsInside(inst,pos.x,pos.z) or not TheWorld.Pathfinder:IsClear(safe.x,0,safe.z,pos.x,0,pos.z)) then
        inst.Physics:Teleport(safe.x,0,safe.z);stop(inst);idle(inst);return false
    end
    inst.sg.statemem.safe=pos
    return true
end
local function enterCharge(inst,count,small)
    stop(inst);face(inst);inst.components.combat:StartAttack()
    inst.sg.statemem.count=count or 1;inst.sg.statemem.hits={}
    inst.AnimState:PlayAnimation(small and 'gore' or 'atk',not small)
    inst.sg:SetTimeout(small and .7 or 1.2);move(inst,T.RUN_SPEED*(small and 1.5 or 1))
    if small then fx(inst,'firecharge_fx');fireRing(inst,5,2.5) end
end
local function chargeUpdate(inst)
    if checkMove(inst) then H.Area(inst,inst:GetPosition(),3,1,false,inst.sg.statemem.hits) end
end
local locomote=CommonHandlers.OnLocomote(true,true)
local events={
    EventHandler('locomote',function(inst,data)
        -- Stop() queues locomote; motor-driven attacks must finish their own state.
        if not inst.sg:HasStateTag('busy') then locomote.fn(inst,data) end
    end),
    EventHandler('doattack',function(inst)
        if not inst.sg:HasStateTag('busy') and H.IsActive(inst) then inst.sg:GoToState('attack') end
    end),
    EventHandler('attacked',function(inst)
        if not inst.sg:HasStateTag('busy') and H.IsActive(inst) and not CommonHandlers.HitRecoveryDelay(inst) then inst.sg:GoToState('hit') end
    end),
    CommonHandlers.OnDeath(),
}
local states={
    State{name='idle',tags={'idle','canrotate'},onenter=function(inst) stop(inst);inst.AnimState:PlayAnimation('idle',true) end},
    State{name='attack',tags={'busy','attack'},onenter=function(inst,choice)
        stop(inst);face(inst);inst.components.combat:StartAttack()
        if choice==nil and inst:InNightmareMode() then choice='teleport' end
        inst.sg.statemem.choice=choice
        inst.AnimState:PlayAnimation('taunt')
        inst.SoundEmitter:PlaySound('dontstarve/creatures/rook_minotaur/voice')
    end,timeline={
        TimeEvent(10*FRAMES,function(inst)
            local choice=inst.sg.statemem.choice
            if choice=='slam' then fx(inst,'shadowpoundring_fx')
            elseif choice=='goring' then fx(inst,'firecharge_fx')
            elseif choice=='ringoffire' then fx(inst,'firering_fx') end
        end),
    },events={EventHandler('animover',function(inst)
        local choice=inst.sg.statemem.choice
        if choice=='pinball' then timer(inst,'charge_cd',10);inst.sg:GoToState('charge_start')
        elseif choice=='goring' then timer(inst,'charge_cd',5);inst.sg:GoToState('charge_small')
        elseif choice=='slam' then timer(inst,'slam_cd',20);inst.sg:GoToState('slam_start',2)
        elseif choice=='ringoffire' then timer(inst,'ringoffire_cd',20);inst.sg:GoToState('ringoffire')
        elseif choice=='teleport' then inst.sg:GoToState('teleport_start',inst.components.health:GetPercent()<=.4 and 3 or 1)
        else inst.sg:GoToState('groundpound') end
    end)}},
    State{name='groundpound',tags={'busy','attack'},onenter=function(inst)
        stop(inst);face(inst);inst.AnimState:PlayAnimation('walk_loop');inst.components.combat:StartAttack()
    end,timeline={TimeEvent(20*FRAMES,function(inst) pound(inst,false) end)},events={EventHandler('animover',animDone)}},
    State{name='ringoffire',tags={'busy','attack'},onenter=function(inst)
        stop(inst);inst.AnimState:PlayAnimation('walk_loop')
    end,timeline={
        TimeEvent(15*FRAMES,function(inst) fx(inst,'firering_fx') end),
        TimeEvent(20*FRAMES,function(inst) pound(inst,false);fireRing(inst,36,18);fireRing(inst,8,3) end),
    },events={EventHandler('animover',animDone)}},
    State{name='charge_start',tags={'busy','attack'},onenter=function(inst)
        stop(inst);face(inst);inst.AnimState:PlayAnimation('paw_loop',true);inst.sg:SetTimeout(1.5)
    end,ontimeout=function(inst) inst.sg:GoToState('charge',3) end},
    State{name='charge',tags={'busy','attack','moving'},onenter=function(inst,count) enterCharge(inst,count,false) end,
        onupdate=chargeUpdate,onexit=stop,ontimeout=function(inst)
            local count=inst.sg.statemem.count-1
            if count>0 then inst.sg:GoToState('charge',count) else idle(inst) end
        end},
    State{name='charge_small',tags={'busy','attack','moving'},onenter=function(inst) enterCharge(inst,1,true) end,
        onupdate=chargeUpdate,onexit=stop,ontimeout=idle,
        timeline={TimeEvent(7*FRAMES,stop)}},
    State{name='slam_start',tags={'busy','attack'},onenter=function(inst,count)
        stop(inst);inst.sg.statemem.count=count or 2;inst.AnimState:PlayAnimation('walk_loop')
    end,events={EventHandler('animover',function(inst)
        if inst.sg.statemem.count>1 then inst.sg:GoToState('slam_start',inst.sg.statemem.count-1)
        else inst.sg:GoToState('slam',7) end
    end)}},
    State{name='slam',tags={'busy','attack'},onenter=function(inst,count)
        stop(inst);face(inst);inst.sg.statemem.count=count or 7;inst.AnimState:PlayAnimation('walk_loop')
        if inst.sg.statemem.count%2==1 then move(inst,T.RUN_SPEED*1.5) end
    end,onupdate=function(inst) if inst.sg.statemem.safe then checkMove(inst) end end,onexit=stop,
        timeline={TimeEvent(20*FRAMES,function(inst) stop(inst);pound(inst,inst:InNightmareMode()) end)},
        events={EventHandler('animover',function(inst)
            if inst.sg.statemem.count>1 then inst.sg:GoToState('slam',inst.sg.statemem.count-1) else idle(inst) end
        end)}},
    State{name='teleport_start',tags={'busy','attack'},onenter=function(inst,count)
        stop(inst);inst.sg.statemem.count=count or 1;inst.AnimState:PlayAnimation('taunt')
        local target=face(inst)
        inst.sg.statemem.destination=target and target:GetPosition() or inst:GetPosition()
        fx(inst,'target_fx',inst.sg.statemem.destination)
        inst.sg:SetTimeout(19*FRAMES)
    end,timeline={TimeEvent(10*FRAMES,function(inst) fx(inst,'teleport_fx') end)},
        onupdate=function(inst)
            local t=inst.sg.timeinstate
            if t>=10*FRAMES then inst.AnimState:SetErosionParams(math.min(1,(t-10*FRAMES)/(9*FRAMES)),.1,1) end
        end,
        onexit=function(inst) inst.AnimState:SetErosionParams(0,0,0) end,
        ontimeout=function(inst) inst.sg:GoToState('teleport',{count=inst.sg.statemem.count,destination=inst.sg.statemem.destination}) end},
    State{name='teleport',tags={'busy','attack'},onenter=function(inst,data)
        stop(inst);inst.sg.statemem.count=data and data.count or 1
        local pos=data and data.destination
        if not H.SafePoint(inst,pos) then idle(inst);return end
        inst.AnimState:SetErosionParams(1,.1,1)
        inst.Physics:Teleport(pos.x,0,pos.z);inst.sg:SetTimeout(.2)
    end,onexit=function(inst) inst.AnimState:SetErosionParams(0,0,0) end,
        ontimeout=function(inst) inst.sg:GoToState('teleport_post',inst.sg.statemem.count) end},
    State{name='teleport_post',tags={'busy','attack'},onenter=function(inst,count)
        stop(inst);inst.sg.statemem.count=count or 1
        fx(inst,'teleportpost_fx');inst.AnimState:PlayAnimation('walk_loop');inst.sg:SetTimeout(.55+20*FRAMES)
    end,ontimeout=function(inst)
            -- DST runs timeout before same-time timeline events.
            pound(inst,true)
            if inst.sg.statemem.count>1 then inst.sg:GoToState('teleport_start',inst.sg.statemem.count-1) else idle(inst) end
        end},
    State{name='phase_transition',tags={'busy','noattack'},onenter=function(inst)
        stop(inst);inst.AnimState:PlayAnimation('death')
    end,timeline={TimeEvent(2.5,function(inst) fx(inst,'transform_fx') end)}},
    State{name='initnightmare',tags={'busy','attack'},onenter=function(inst)
        stop(inst);inst.AnimState:PlayAnimation('taunt');fx(inst,'shadowpoundring_fx')
        inst.SoundEmitter:PlaySound('dontstarve/creatures/rook_minotaur/voice')
    end,events={EventHandler('animover',animDone)}},
    State{name='hit',tags={'busy','hit'},onenter=function(inst) stop(inst);inst.AnimState:PlayAnimation('hit') end,
        events={EventHandler('animover',animDone)}},
    State{name='death',tags={'busy','dead'},onenter=function(inst)
        stop(inst);inst.AnimState:PlayAnimation('death');RemovePhysicsColliders(inst)
        -- Final death is visual only. Its loot/reward belongs to the manager.
        local visual=SpawnPrefab('hn_minotau_deathshockwave')
        if visual then
            visual.Transform:SetPosition(inst.Transform:GetWorldPosition())
            if inst.hn_dungeon_manager then inst.hn_dungeon_manager:Track(visual) end
        end
    end},
}
CommonStates.AddWalkStates(states,nil,{startwalk='walk_pre',walk='walk_loop',stopwalk='walk_pst'})
CommonStates.AddRunStates(states,nil,{startrun='walk_pre',run='walk_loop',stoprun='walk_pst'})
return StateGraph('hn_minotau',states,events,'idle')
