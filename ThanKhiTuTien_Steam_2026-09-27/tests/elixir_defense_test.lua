package.path='ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;'..package.path
local Combat=require('tbc_combat')
local p={components={tbc_player_effects={Get=function(_,key) return key=='reduceAttackedDamage' and 50 or 0 end}},
    HasTag=function(_,tag) return tag=='player' end}
local received
local combat={inst=p,GetAttacked=function(_,_,damage) received=damage; return true end}
Combat.Install(combat,true)
local monster={HasTag=function() return false end}
assert(combat:GetAttacked(monster,120)); assert(received==70,'elixir defense applies to boss/mob hits')
assert(combat:GetAttacked(nil,120)); assert(received==70,'non-attacker combat damage')
assert(combat:GetAttacked(p,120)); assert(received==70,'PvP subtracts only once')
print('elixir_defense_test: monster and player damage reduction passed')
