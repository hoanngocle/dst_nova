-- Guardian combat adapted from Solo Leveling 2.2.7 / Saikuno.
local Brain=require('brains/hn_minotaubrain')
local H=require('hn_dungeon/boss_hazards')
local T=require('hn_dungeon/minotau_tuning')
local assets={Asset('ANIM','anim/rook.zip'),Asset('ANIM','anim/rook_build.zip'),Asset('ANIM','anim/rook_rhino.zip'),Asset('SOUND','sound/chess.fsb')}
local function fn()
    local inst=CreateEntity()
    inst.entity:AddTransform();inst.entity:AddAnimState();inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow();inst.entity:AddNetwork()
    MakeGiantCharacterPhysics(inst,1000,1.5)
    inst.Transform:SetFourFaced();inst.DynamicShadow:SetSize(2.5,1.5)
    inst.AnimState:SetBank('rook');inst.AnimState:SetBuild('rook_rhino');inst.AnimState:PlayAnimation('idle',true)
    for _,tag in ipairs({'monster','hostile','epic','largecreature','hn_dungeon_mob'}) do inst:AddTag(tag) end
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end
    inst:AddComponent('health');inst.components.health:SetMaxHealth(T.HEALTH)
    inst.components.health.fire_damage_scale=0
    inst:AddComponent('combat');inst.components.combat:SetDefaultDamage(T.DAMAGE)
    inst.components.combat:SetAttackPeriod(T.ATTACK_PERIOD);inst.components.combat:SetRange(3.5,6)
    inst.components.combat.hiteffectsymbol='spring'
    inst:AddComponent('locomotor');inst.components.locomotor.walkspeed=T.WALK_SPEED;inst.components.locomotor.runspeed=T.RUN_SPEED
    inst:AddComponent('timer');inst:AddComponent('planarentity');inst:AddComponent('inspectable');inst:AddComponent('lootdropper')
    inst.nightmare=false
    inst.InNightmareMode=function(self) return self.nightmare end
    inst.ActivateNightmareMode=function(self) self.nightmare=true;self.AnimState:SetMultColour(.15,.15,.15,1) end
    inst:SetStateGraph('SGhn_minotau');inst:SetBrain(Brain)
    inst:AddComponent('hn_boss_phases')
    inst:ListenForEvent('attacked',function(_,data)
        if data and H.CanTarget(inst,data.attacker) then inst.components.combat:SetTarget(data.attacker) end
    end)
    return inst
end
return Prefab('hn_minotau',fn,assets,{'hn_minotau_shadowblaze','hn_minotau_deadlyshockwave','hn_minotau_transform_fx','hn_minotau_shadowpoundring_fx'})
