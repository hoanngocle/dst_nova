package.path='Achivement_Steam_2026-09-27/scripts/?.lua;'..assert(os.getenv('DST_TEST_SCRIPTS'))..'/?.lua;'..package.path
dofile(os.getenv('DST_TEST_SCRIPTS')..'/class.lua')
EntityScript={is_instance=function() return false end}
package.loaded['functions/helperfunctions']=true
perk_lists={};level_lists={}
allachiv_coindata={speedup=.01,damageup=.01,absorbup=.025}
speedGain=.005;damageGain=.005;absorbGain=.005;max_absorbGain=.9
local Modifiers=require('util/sourcemodifierlist')
local Coin=require('components/allachivcoin')
local Level=require('components/levelsystem')
local function near(a,b,label) assert(math.abs(a-b)<1e-8,label..': '..a..' ~= '..b) end
local p={components={}}
local speed=Modifiers(p)
p.components.locomotor={
    SetExternalSpeedMultiplier=function(_,source,key,m) speed:SetModifier(source,m,key) end,
    RemoveExternalSpeedMultiplier=function(_,source,key) speed:RemoveModifier(source,key) end,
}
local damage,taken=Modifiers(p),Modifiers(p)
p.components.combat={damagemultiplier=2,externaldamagemultipliers=damage,externaldamagetakenmultipliers=taken}
speed:SetModifier('tutien',1.3)
damage:SetModifier('item',1.5)
taken:SetModifier('tutien',.8)
local perk={speedupamount=10,damageupamount=10,absorbupamount=4}
local level={speedlevelamount=20,damagelevelamount=20,absorblevelamount=20}
local function apply()
    Coin.speedupfn(perk,p);Coin.damageupfn(perk,p);Coin.absorbupfn(perk,p)
    Level.speedlevelfn(level,p);Level.damagelevelfn(level,p);Level.absorblevelfn(level,p)
end
apply()
near(speed:Get(),1.573,'native movement, perk and level are each retained')
near(100*p.components.combat.damagemultiplier*damage:Get(),363,'base attack and every bonus retained')
near(taken:Get(),.648,'native defense, perk and level retained')
apply()
near(speed:Get(),1.573,'refresh does not stack movement bonuses')
near(damage:Get(),1.815,'refresh does not stack damage bonuses')
perk.speedupamount=0;perk.damageupamount=0;perk.absorbupamount=0
apply()
near(speed:Get(),1.43,'removing perk preserves level/native speed')
near(damage:Get(),1.65,'removing perk preserves level/item damage')
near(taken:Get(),.72,'removing perk preserves level/native defense')
level.speedlevelamount=0;level.damagelevelamount=0;level.absorblevelamount=0
apply()
near(speed:Get(),1.3,'zero level removes only its speed key')
near(damage:Get(),1.5,'zero level removes only its damage key')
near(taken:Get(),.8,'zero level removes only its defense key')
near(p.components.combat.damagemultiplier,2,'Tu Tien attack multiplier was not overwritten')
print('stat_modifier_composition_test: ok')
