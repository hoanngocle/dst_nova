package.path = 'CongTrinhTuTien_Steam_2026-09-27/scripts/?.lua;' .. package.path
local path = 'CongTrinhTuTien_Steam_2026-09-27/scripts/nova_slot_rewards.lua'
local file = io.open(path, 'r')
assert(file, 'final slot reward catalog must exist')
file:close()
local data = require('nova_slot_rewards')
local expected = {good=24, ok=21, ok2=30, bad=43, bad2=31}
local seen, total = {}, 0
for _, group in ipairs(data.groups) do
    assert(#group.bundles == expected[group.key], group.key)
    for _, bundle in ipairs(group.bundles) do
        assert(not seen[bundle.id], 'bundle IDs must be stable and unique')
        seen[bundle.id] = true
        total = total + 1
        for _, item in ipairs(bundle.items) do
            assert(item.count > 0 and item.count % 1 == 0)
            assert(item.prefab~='nhatvuphuonghoa' and item.prefab~='thanhiquangtruong'
                and item.prefab~='xd_sudaji_ywfh' and item.prefab~='xd_yunxiao_fysz',
                'remove missing legacy weapons without substituting unapproved native versions')
        end
    end
end
assert(total == 149)
local core = require('nova_slot_core')
local available = {a=true,b=true}
local groups = {{key='good',weight=1,bundles={
    {id='complete',weight=1,items={{prefab='a',count=1},{prefab='b',count=1}}},
    {id='missing',weight=1,items={{prefab='absent',count=1}}},
}}}
local pool = assert(core.Eligible(groups, function(id) return available[id] end, true))
assert(#pool[1].bundles == 1, 'exclude the whole unavailable bundle')
available.b = nil
assert(core.Eligible(groups, function(id) return available[id] end, true) == nil,
    'reject payment if a source category has no eligible bundle')
local removed, created = 0, 0
local bundle = {items={{prefab='a',count=2},{prefab='b',count=1}}}
local ok = core.SpawnBundle(bundle, function(id)
    if id == 'b' then return nil end
    created = created + 1
    return {IsValid=function() return true end,Remove=function() removed=removed+1 end}
end, function() end)
assert(not ok and removed == created and created == 2, 'partial failure must roll back all rewards')
print('slot rewards: catalog, eligibility, atomic rollback passed')
