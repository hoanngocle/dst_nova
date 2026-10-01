-- Adapted from Solo Leveling 2.2.7 / Saikuno: hh_boss.lua pig definitions.
local Brain=require('brains/hn_com_monster')
local Combat=require('hn_dungeon/combat')
local function definition(name,bank,build,health,animations,timers,sg)
    local assets={}
    for _,anim in ipairs(animations) do assets[#assets+1]=Asset('ANIM','anim/'..anim..'.zip') end
    return {name=name,desc=name,health=health,assets=assets,
        client_fn=function(inst)
            inst.entity:AddSoundEmitter();inst.entity:AddDynamicShadow()
            inst.DynamicShadow:SetSize(3.5,1.5)
            inst:SetPhysicsRadiusOverride(1.5);MakeGiantCharacterPhysics(inst,1000,1.5)
            inst.Transform:SetFourFaced()
            inst.AnimState:SetBank(bank);inst.AnimState:SetBuild(build);inst.AnimState:PlayAnimation('idle_loop',true)
            for _,tag in ipairs({'monster','hostile','epic','largecreature','hn_dungeon_mob'}) do inst:AddTag(tag) end
        end,
        server_fn=function(inst)
            inst:AddComponent('inspectable');inst:AddComponent('locomotor')
            inst.components.locomotor.runspeed=7;inst.components.locomotor.walkspeed=7
            inst:AddComponent('combat');inst.components.combat:SetDefaultDamage(50)
            inst.components.combat:SetAttackPeriod(2);inst.components.combat:SetRange(4.5)
            inst.components.combat.hiteffectsymbol='body';inst.components.combat.battlecryenabled=false
            inst.components.combat.forcefacing=false
            inst:AddComponent('health');inst.components.health:SetMaxHealth(health);inst.components.health.fire_damage_scale=0
            inst:AddComponent('timer');for timer,delay in pairs(timers) do inst.components.timer:StartTimer(timer,delay) end
            inst:AddComponent('grouptargeter');inst:AddComponent('lootdropper')
            inst:AddComponent('planarentity');inst:AddComponent('planardamage');inst.components.planardamage:SetBaseDamage(30)
            inst:AddComponent('hn_combat_effects')
            inst:SetStateGraph(sg);inst:SetBrain(Brain)
            inst:ListenForEvent('attacked',function(_,data)
                if data and Combat:CanHitTarget(inst,data.attacker) then inst.components.combat:SetTarget(data.attacker) end
            end)
        end}
end
return {
    hn_beetle_pig=definition('Lợn Rừng Bọ Hung','beetletaur','lavaarena_beetletaur',25000,
        {'lavaarena_beetletaur','lavaarena_beetletaur_basic','lavaarena_beetletaur_actions','lavaarena_beetletaur_block','lavaarena_beetletaur_fx','lavaarena_beetletaur_break'},
        {pig_jump_cd=7,pig_strong_cd=27,pig_control_cd=45},'SGhn_beetle_pig'),
    hn_dual_wield_pig=definition('Siêu Lợn Song Kiếm','boarrior','lavaarena_boarrior_basic',30000,
        {'lavaarena_boarrior_basic'},{pig_around_cd=12},'SGhn_dual_wield_pig'),
}
