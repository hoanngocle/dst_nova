package.path='Achivement_Steam_2026-09-27/scripts/?.lua;ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;'..package.path
dofile(assert(os.getenv('DST_TEST_SCRIPTS'))..'/class.lua')
package.loaded['functions/helperfunctions']=true
level_lists={};allachiv_coindata={healthup=3,hungerup=3,sanityup=3}
healthGain=5;hungerGain=5;sanityGain=5
local Level=require('components/levelsystem')
local Resources=require('tbc_elixir/resources')
local Passives=require('tbc_affix/passives')
local function eq(a,b,label) assert(math.abs(a-b)<1e-8,label..': '..a..' ~= '..b) end
local p={components={}}
function p:DoTaskInTime(_,fn) fn(self) end
for _,name in ipairs({'health','hunger','sanity'}) do
    local field=name=='health' and 'maxhealth' or 'max'
    local current=name=='health' and 'currenthealth' or 'current'
    local r={inst=p,[field]=name=='sanity' and 200 or 125,[current]=60}
    function r:GetPercent() return self[current]/self[field] end
    function r:SetPercent(n) self[current]=n*self[field] end
    function r:SetMaxHealth(n) self[field]=n;self[current]=n end
    r.SetMax=r.SetMaxHealth
    function r:GetMaxWithPenalty() return self[field]*(1-(self.penalty or 0)) end
    function r:SetCurrentHealth(n) self[current]=math.max(0,math.min(n,self:GetMaxWithPenalty())) end
    r.SetCurrent=r.SetCurrentHealth
    function r:ForceUpdateHUD() end
    p.components[name]=r
    p['current'..name..'up']={value=function() return 10 end}
end
function chasni_setMaxHealth(h,n) local percent=h:GetPercent();h:SetMaxHealth(n);h:SetPercent(percent) end
chasni_setMaxHunger=chasni_setMaxHealth;chasni_setMaxSanity=chasni_setMaxHealth
local elixir=0
p.components.tbc_elixir_progress={GetBonus=function(_,kind) return kind=='health' and elixir or 0 end}
local h=p.components.health
Resources.Install(h,'health')
local level=setmetatable({achievementhealthup=0,levelhealthup=0,healthlevelamount=70,
    achievementhungerup=0,levelhungerup=0,hungerlevelamount=10,
    achievementsanityup=0,levelsanityup=0,sanitylevelamount=20},{__index=Level})
local function apply() level:loadHealth(p);level:loadHunger(p);level:loadSanity(p) end
-- Native cultivation changes its own portion directly; original health remains.
h.maxhealth=h.maxhealth+162.5
p.components.hunger.max=p.components.hunger.max+150
apply()
eq(h.maxhealth,667.5,'125 original + 162.5 cultivation + 30 perk + 350 levels')
eq(p.components.hunger.max,355,'125 original + 150 cultivation + 30 perk + 50 levels')
eq(p.components.sanity.max,330,'200 original + 30 perk + 100 levels')
elixir=100;Resources.Refresh(p)
eq(h.maxhealth,767.5,'elixir adds only its own 100')
-- Equipment percentage is calculated on the native + Achievement subtotal.
p._tbc_passive_state={health_percent=20,body_health=50,health_bonus=0}
Resources.Refresh(p)
eq(h.maxhealth,951,'all health sources compose exactly once')
h.currenthealth=80
apply();Resources.Refresh(p);Resources.Refresh(p)
eq(h.maxhealth,951,'repeated updates do not stack sources')
eq(h.currenthealth,80,'refresh does not heal')
-- Raising cultivation while the same item stays equipped must immediately
-- recompute that item's percentage bonus, even if Achievement points did not change.
h.maxhealth=h.maxhealth+12.5
p.components.hunger.max=p.components.hunger.max+10
apply()
eq(h.maxhealth,966,'cultivation change also refreshes existing percentage equipment')
eq(p.components.hunger.max,365,'hunger retains original/perk/level on cultivation change')
eq(h.currenthealth,80,'capturing cultivation does not heal')
level.healthlevelamount=71;apply()
eq(h.maxhealth,972,'buying a level preserves cultivation, perk, elixir and equipment')
level.healthlevelamount=70;apply()
eq(h.maxhealth,966,'removing a level removes only its five health plus dependent equipment percent')
p._tbc_passive_state.health_percent=0;p._tbc_passive_state.body_health=0;Resources.Refresh(p)
eq(h.maxhealth,780,'unequipping removes only the equipment contribution')
elixir=0;Resources.Refresh(p)
eq(h.maxhealth,680,'removing elixir leaves original/cultivation/Achievement')
for _,name in ipairs({'health','hunger','sanity'}) do p['current'..name..'up'].value=function() return 0 end end
level.healthlevelamount=0;level.hungerlevelamount=0;level.sanitylevelamount=0;apply()
eq(h.maxhealth,300,'removing Achievement leaves original + current cultivation')
eq(p.components.hunger.max,285,'removing Achievement preserves hunger cultivation')
eq(p.components.sanity.max,200,'removing Achievement preserves native sanity')
print('stat_resource_composition_test: ok')
