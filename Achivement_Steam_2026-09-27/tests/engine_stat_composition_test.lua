-- Disposable world only. Enable Tu Tien, Nyx, Achievement and Than Khi.
-- HEALTHGAIN/HUNGERGAIN/SANITYGAIN=5; SPEEDGAIN/DAMAGEGAIN/ABSORBGAIN=.005.
local Resources=require('tbc_elixir/resources')
local Coordinator=require('tbc_affix/coordinator')
local Combat=require('tbc_combat')
local Defs=require('tbc_affix/defs')
local function Near(a,b,label)
    assert(type(a)=='number' and math.abs(a-b)<.0001,label..': '..tostring(a)..' expected '..b)
end
local function PauseDrain(p)
    p.entity:SetCanSleep(false)
    -- Native player setup can restart component updates after OnLoad.
    p.components.hunger.burnratemodifiers:SetModifier(p,0,'stat_composition_qa')
    p.components.sanity.rate_modifier=0
    p:StopUpdatingComponent(p.components.hunger)
    p:StopUpdatingComponent(p.components.sanity)
end
local function Apply(p)
    local c=p.components
    c.levelsystem:loadHealth(p);c.levelsystem:loadHunger(p);c.levelsystem:loadSanity(p)
    c.allachivcoin:speedupfn(p)
    c.allachivcoin:damageupfn(p);c.allachivcoin:absorbupfn(p)
    c.levelsystem:speedlevelfn(p);c.levelsystem:damagelevelfn(p);c.levelsystem:absorblevelfn(p)
end
local function Affix(effect,value)
    for _,row in ipairs(Defs.rows) do
        if row.effect_key==effect and not row.fixed and Defs.IsValidValue(row.code,value*row.scale) then
            return {id=row.code,value=value*row.scale}
        end
    end
    error('missing QA affix '..effect)
end
local function Equip(p)
    local armor=SpawnPrefab('armorwood')
    assert(armor.components.tbc_upgrade:SetLevel(16))
    local hp=Affix('equipMaxHealthPercent',21)
    assert(armor.components.tbc_upgrade:AddAffix(hp.id,hp.value))
    p.components.inventory:Equip(armor)
    local weapon=SpawnPrefab('spear')
    local speed=Affix('addSpeedPercent',20)
    assert(weapon.components.tbc_upgrade:AddAffix(speed.id,speed.value))
    p.components.inventory:Equip(weapon)
    Coordinator.Reconcile(p)
end
local p=SpawnPrefab('nyx')
local native=SpawnPrefab('nyx')
p:DoTaskInTime(3,function()
    for _,inst in ipairs({p,native}) do
        inst.components.xd_level:SetLevel(2)
        inst.components.xd_dtlevel:SetLevel(46)
        PauseDrain(inst)
    end
    Near(p.base_xdhealth,125,'character base health')
    -- Native cultivation applies some movement changes in a deferred task.
    p:DoTaskInTime(1,function()
    local c=p.components
    c.allachivcoin.healthupamount=10;c.allachivcoin.hungerupamount=10;c.allachivcoin.sanityupamount=10
    c.allachivcoin.speedupamount=10
    c.allachivcoin.damageupamount=10;c.allachivcoin.absorbupamount=4
    c.levelsystem.healthlevelamount=70;c.levelsystem.hungerlevelamount=10;c.levelsystem.sanitylevelamount=20
    c.levelsystem.speedlevelamount=20;c.levelsystem.damagelevelamount=20;c.levelsystem.absorblevelamount=20
    Apply(p)
    for _,key in ipairs({'health','power','guard','speed'}) do
        assert(c.tbc_elixir_progress:Consume(key));assert(c.tbc_elixir_progress:Consume(key))
    end
    Equip(p)
    local function Check(inst,label,equipped)
        local cc=inst.components
        local base_attack=native.components.combat.damagemultiplier
        local base_damage=native.components.combat.externaldamagemultipliers:Get()
        local base_taken=native.components.combat.externaldamagetakenmultipliers:Get()
        local base_speed=native.components.locomotor:GetSpeedMultiplier()
        local subtotal=native.components.health.maxhealth+30+350
        local gear=equipped and subtotal*.21+500 or 0
        Near(cc.health.maxhealth,subtotal+100+gear,label..' all health sources')
        Near(cc.hunger.max,native.components.hunger.max+30+50,label..' all hunger sources')
        Near(cc.sanity.max,native.components.sanity.max+30+100,label..' all sanity sources')
        Near(cc.combat.damagemultiplier,base_attack,label..' native attack')
        Near(cc.combat.externaldamagemultipliers:Get(),base_damage*1.1*1.1,label..' attack perk and level sources')
        Near(cc.combat.externaldamagetakenmultipliers:Get(),base_taken*.9*.9,label..' defense perk and level sources')
        -- Body strengthen +16 also contributes 29% movement, separately from the weapon affix.
        Near(cc.locomotor:GetSpeedMultiplier(),base_speed*1.1*1.1*1.04*(equipped and 1.2*1.29 or 1),label..' speed sources')
        Near(Combat.SoloArmorPierce(inst),100,label..' attack elixir')
        Near(Combat.SoloDefense(inst,250),150,label..' defense elixir')
        assert(cc.xd_dtlevel.level==native.components.xd_dtlevel.level,label..' cultivation level')
        print('STAT_COMPOSITION_QA',label,cc.health.maxhealth,cc.hunger.max,cc.sanity.max)
    end
    Check(p,'all_sources',true)
    Apply(p);Resources.Refresh(p);Coordinator.Reconcile(p)
    Check(p,'refresh',true)
    native.components.xd_dtlevel:SetLevel(47)
    c.xd_dtlevel:SetLevel(47)
    Apply(p)
    Check(p,'cultivation_change',true)
    c.levelsystem.healthlevelamount=71;Apply(p)
    Near(c.health.maxhealth,(native.components.health.maxhealth+30+355)*1.21+600,'change level points')
    c.levelsystem.healthlevelamount=70;Apply(p)
    local inventory=c.inventory
    for _,slot in ipairs({EQUIPSLOTS.BODY,EQUIPSLOTS.HANDS}) do
        local item=inventory:Unequip(slot)
        if item then item:Remove() end
    end
    Coordinator.Reconcile(p);Check(p,'unequip',false)
    Equip(p);Check(p,'reequip',true)
    c.health:SetPenalty(.25);c.health:SetCurrentHealth(357)
    c.hunger:SetCurrent(91);c.sanity:SetCurrent(83)
    local function Reload(source,iteration)
        local copy=SpawnSaveRecord(source:GetSaveRecord())
        PauseDrain(copy)
        copy:DoTaskInTime(5,function()
            Check(copy,'reload'..iteration,true)
            Near(copy.components.health.currenthealth,357,'saved current health')
            Near(copy.components.hunger.current,91,'saved current hunger')
            Near(copy.components.sanity.current,83,'saved current sanity')
            Near(copy.components.health.penalty,.25,'revival penalty')
            Resources.Refresh(copy);Apply(copy);Check(copy,'postload_refresh'..iteration,true)
            if iteration<2 then Reload(copy,iteration+1)
            else
                copy.components.health:Kill()
                Near(copy.components.health.currenthealth,0,'native death')
                -- Drive the native ghost lifecycle without depending on animation
                -- completion in this console fixture: SGwilson sends this same event.
                copy:PushEvent('makeplayerghost',{skeleton=false})
                copy:DoTaskInTime(2,function()
                    assert(copy:HasTag('playerghost'),'native death should produce a ghost')
                    -- DST stores resurrect health (normally 50) even while a ghost.
                    local ghosthealth=copy.components.health.currenthealth
                    Resources.Refresh(copy)
                    assert(copy:HasTag('playerghost'),'refresh must not resurrect')
                    Near(copy.components.health.currenthealth,ghosthealth,'ghost health preserved after refresh')
                    local ghost=SpawnSaveRecord(copy:GetSaveRecord())
                    ghost:DoTaskInTime(5,function()
                        assert(ghost:HasTag('playerghost'),'save/load preserves ghost')
                        Near(ghost.components.health.currenthealth,ghosthealth,'ghost reload preserves native resurrect health')
                        ghost:PushEvent('respawnfromghost')
                        ghost:DoTaskInTime(8,function()
                            assert(not ghost:HasTag('playerghost'),'native resurrection succeeds')
                            Apply(ghost);Resources.Refresh(ghost)
                            Check(ghost,'revived_without_dropped_gear',false)
                            print('STAT_COMPOSITION_QA_DONE')
                        end)
                    end)
                end)
            end
        end)
    end
    Reload(p,1)
    end)
end)
