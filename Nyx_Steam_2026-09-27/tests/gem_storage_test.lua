package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path
local ok, Rules = pcall(require, 'nyx/gem_storage')
assert(ok, 'gem storage rules must be available')
for _, id in ipairs({'redgem','bluegem','purplegem','orangegem','yellowgem','greengem',
    'opalpreciousgem','hh_effect_stone','hh_effect_tally','hh_remove_stone',
    'ac_refreshstone','ad_cleanstone','wb_enhancegem','hh_essence',
    'xd_lingshi1','xd_lingshi2','xd_lingshi3','xd_lingshi4',
    'ttk_huyen_tinh_ha_pham','ttk_huyen_tinh_trung_pham','ttk_huyen_tinh_thuong_pham'}) do
    assert(Rules.Accepts({prefab=id}), 'must accept '..id)
end
for _, id in ipairs({'rocks','goldnugget','spear','papyrus','xd_lingshi5','nn_liquidluck',
    'nn_magicpaper','wb_strengthen_strengthen_protectpaper','fakegem','hh_effect_stone_fake'}) do
    assert(not Rules.Accepts({prefab=id}), 'must reject '..id)
end
assert(not Rules.Accepts(nil))
local containers = {params={}, MAXITEMSLOTS=80}
Rules.Register(containers, function(x,y,z) return {x=x,y=y,z=z} end)
local params = containers.params.nyx_gem_storage
assert(#params.widget.slotpos == 36, 'exactly 36 slots')
assert(containers.MAXITEMSLOTS == 80, 'must not reduce another mod slot limit')
assert(params.widget.buttoninfo == nil, 'storage has no processing buttons')
local seen = {}
for i, pos in ipairs(params.widget.slotpos) do
    local row, col = math.floor((i-1)/6), (i-1)%6
    assert(pos.x == (col-2.5)*80 and pos.y == (2.5-row)*80, '6 by 6 row-major layout')
    local key=pos.x..':'..pos.y
    assert(not seen[key]); seen[key]=true
end
assert(params.itemtestfn(nil,{prefab='hh_effect_stone'},36))
assert(not params.itemtestfn(nil,{prefab='spear'},1))
print('gem_storage_test: ok')
