package.path = "TienIchTuTien_Steam_2026-09-27/scripts/?.lua;ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;" .. package.path
local ok, Stats = pcall(require, "ttk_character_stats")
assert(ok, "character information collector must be available")
local function near(a, b) assert(type(a) == "number" and math.abs(a-b) < .0001, tostring(a).." ~= "..b) end
local function modifier(value, sources)
    return {Get=function() return value end, _modifiers=sources or {}}
end
local sword = {prefab="sword", GetDisplayName=function() return "Kiếm thử" end,
    components={weapon={damage=100}, armor={absorb_percent=.8, condition=100}}}
local equipped = sword
local p = {prefab="nyx", HasTag=function() return false end, components={
    health={currenthealth=75,maxhealth=200,GetMaxWithPenalty=function() return 150 end,
        absorb=.1, externalabsorbmodifiers=modifier(.5)},
    hunger={current=90,max=120}, sanity={current=60,max=200},
    combat={defaultdamage=10,GetWeapon=function() return equipped end,
        damagemultiplier=1.5, damagebonus=10,
        externaldamagemultipliers=modifier(2,{damagePerk={modifiers={key=2}}}),
        externaldamagetakenmultipliers=modifier(.8), min_attack_period=.4},
    locomotor={GetRunSpeed=function() return 9 end},
    inventory={equipslots={HANDS=sword,ALIAS=sword}},
    xd_htz_lq={current=50,max=100},
    hh_buff={hh_buffs={add_health={time=12.5}}},
}}
local source = {combat_stats=function() return {crit_rate=20,crit_effect=50,pierce=10} end,
    flat_pierce=function() return 30 end,
    preview_attack=function(_, _, damage) return {damage=(damage+20)*1.2,
        pierce_percent=10,pierce_damage=69.6,total_damage=465.6} end}
local s = Stats.Measure(p, {TTK_EQUIPMENT_DETAIL_SOURCE=source})
near(s.values.damage,465.6) -- physical 396 + armor-piercing 69.6
near(s.values.damage_physical,396)
near(s.values.pierce_damage,69.6)
near(s.values.base_damage,310)
near(s.values.health_max,150) -- penalties must be reflected
local penalized=p.components.health.GetMaxWithPenalty
p.components.health.maxhealth=680
p.components.health.GetMaxWithPenalty=function(self) return self.maxhealth end
near(Stats.Measure(p,{TTK_EQUIPMENT_DETAIL_SOURCE=source}).values.health_max,680)
p.components.health.GetMaxWithPenalty=penalized
p.components.health.maxhealth=200
near(s.values.speed,9)
near(s.values.health_absorption,55) -- sequential 10% then 50%, not 60%
near(s.values.armor,80) -- duplicate equip slot must not double count armor
near(s.values.damage_taken,80)
assert(s.values.lingli == 50 and s.values.lingli_max == 100)
local found, timer = false, false
for _,row in ipairs(s.tabs[4]) do
    if row[1]:find("Thành tựu",1,true) and row[2]:find("2",1,true) then found=true end
    if row[2]:find("13s",1,true) then timer=true end
end
assert(found, "damage multiplier must retain its contributing source")
assert(timer, "active timed buffs must include remaining seconds")
equipped=nil; p.components.inventory.equipslots={}; p.components.hh_buff.hh_buffs={}
p.components.combat.externaldamagemultipliers=modifier(1)
local after = Stats.Measure(p,{})
near(after.values.damage,25)
near(after.values.armor,0)
assert(#after.tabs[4] < #s.tabs[4], "removed equipment and buffs must disappear")
p.HasTag=function(_,tag) return tag=="playerghost" end
local ghost=Stats.Measure(p,{})
assert(ghost.ghost and ghost.values.damage==nil, "ghost must not retain living attack statistics")
assert(Stats.Measure({components={}},{}).values.damage==nil, "missing component is unknown, not zero damage")
p.HasTag=function() return false end
p.components.rider={IsRiding=function() return true end,GetSaddle=function() return nil end,
    GetMount=function() return {components={combat={defaultdamage=50,damagemultiplier=4,
        externaldamagemultipliers=modifier(3),damagebonus=2}}} end}
local riding=Stats.Measure(p,{})
near(riding.values.damage,602)
near(riding.values.damage_multiplier,4)
p.components.rider=nil
p.components.nyx_skills={controller={Snapshot=function() return {ready=true,regen=2} end}}
p._tbc_affix_mana={regen=.5}
near(Stats.Measure(p,{}).values.lingli_regen,2.5)

-- The achievement provider already includes Thần Khí's baseline crit. Never add it twice.
p.HasTag=function() return false end
p.components.chasnicritchancer={CalculateCrit=function() return 1.5,.2 end}
p.components.allachivcoin={criticalupamount=2,criticaldmgupamount=1}
local crit=Stats.Measure(p,{TTK_EQUIPMENT_DETAIL_SOURCE=source,
    allachiv_coindata={criticalup=.1,criticaldmgup=.5}})
near(crit.values.crit_rate,36) -- 1-(1-.2)*(1-.2)
near(crit.values.crit_damage,300) -- 1 base + .5 perk + 1.5 provider
near(crit.values.crit_bonus,200) -- total multiplier x3 means +200% over normal damage
-- Achievement's own provider can omit Thần Khí's elixir bonus. Show the
-- combined bonus once: native +100% critical damage and elixir +40% = +140%.
local tbc_provider=p.components.chasnicritchancer
local achievement_perks=p.components.allachivcoin
p.components.chasnicritchancer={crits={},CalculateCrit=function() return 0,0 end}
p.components.allachivcoin={criticalupamount=0,criticaldmgupamount=0}
local elixir_crit=Stats.Measure(p,{TTK_EQUIPMENT_DETAIL_SOURCE={combat_stats=function()
    return {crit_rate=10,crit_effect=40,pierce=10}
end}})
near(elixir_crit.values.crit_rate,10)
near(elixir_crit.values.crit_damage,240)
near(elixir_crit.values.crit_bonus,140)
assert((function()
    for _,row in ipairs(elixir_crit.tabs[2]) do
        if row[1]=='ST bạo kích cộng thêm' and row[2]=='140%' then return true end
    end
end)(),'attack tab must display the combined critical bonus')
p.components.chasnicritchancer=tbc_provider
p.components.allachivcoin=achievement_perks
p.dodgechance=.1
p.components.chasnidodgechancer={CalculateDodge=function() return .2 end}
p.HasDebuff=function(_,key) return key=="chasni_kimchibuff" end
local defended=Stats.Measure(p,{})
near(defended.values.dodge,78.4) -- 1 - .9 * .8 * .3
p.components.tbc_elixir_progress={
    GetCount=function(_,key) return key=='health' and 10 or 3 end,
    GetBonus=function(_,key) return key=='health' and 500 or 150 end,
    Consume=function() error('information must not consume potions') end,
}
local elixirs=Stats.Measure(p,{})
near(elixirs.values.elixir_health,500)
near(elixirs.values.elixir_mana,150)
local counts=0
for _,row in ipairs(elixirs.tabs[4]) do
    if row[1]:find('Linh dược · ',1,true) and row[2]:find('/10',1,true) then counts=counts+1 end
end
assert(counts==6,'information exposes each permanent potion counter')
print("character_stats_test: ok")
