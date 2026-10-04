package.path='ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;'..package.path
EQUIPSLOTS={HEAD='HEAD',BODY='BODY',NECK='NECK'}
local Defs=require('tbc_affix/defs')
local Slots=require('tbc_affix/slots')
local row=Defs.by_code.equip_mana_regen_i
assert(row~=nil)
local item={components={equippable={equipslot=EQUIPSLOTS.BODY}}}
local ok,reason=Slots.CanAdd(item,{},row)
assert(not ok and reason=='Đá này không hợp vị trí trang bị.')
item.components.equippable.equipslot=EQUIPSLOTS.HEAD
ok,reason=Slots.CanAdd(item,{{id='equip_mana_regen_ii'}},row)
assert(not ok and reason=='Trang bị đã có thuộc tính cùng nhóm.')
local full={}
for i=1,Defs.MAX_SLOTS do full[i]={id='some_code_'..i} end
ok,reason=Slots.CanAdd(item,full,row)
assert(not ok and reason=='Trang bị đã đủ 5 dòng thuộc tính.')
print('affix_rejection_reason_test: ok')
