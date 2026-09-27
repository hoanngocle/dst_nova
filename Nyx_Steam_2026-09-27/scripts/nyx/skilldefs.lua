local order={'absolute_domain','triflame_fan','yellow_river','eternal_night','spirit_sword','purple_gather','purple_eye','moon_wings'}
local defs={}
local rows={
    {'Tuyệt Đối Lĩnh Vực',30,20,'always',0,'self',0,'Lĩnh Vực'},
    {'Tam Diễm Phiến',40,30,'realm',3,'point',14,'Tam Diễm'},
    {'Cửu Khúc Hoàng Hà Trận',40,40,'realm',5,'self',0,'Hoàng Hà'},
    {'Tàn Dạ – Vĩnh Hằng Lĩnh Vực',50,50,'realm',6,'point',14,'Tàn Dạ'},
    {'Huyền Thiên Trảm Linh Kiếm',80,60,'realm',9,'point',14,'Trảm Linh'},
    {'Tử Phong Tụ Linh',3,10,'level',10,'point',12,'Tụ Linh'},
    {'Tử Tiêu Thần Nhãn',0,0,'level',20,'toggle',0,'Thần Nhãn'},
    {'Tinh Vũ Nguyệt Dực',0,0,'level',30,'toggle',0,'Nguyệt Dực'},
}
for i,r in ipairs(rows) do defs[order[i]]={id=order[i],name=r[1],cost=r[2],cooldown=r[3],gate={kind=r[4],value=r[5]},target=r[6],range=r[7],short=r[8],row=i<=5 and 1 or 2,slot=i<=5 and i or i-5} end
return {Get=function(id) return defs[id] end,Order=function() return order end}
