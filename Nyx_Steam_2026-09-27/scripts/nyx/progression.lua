local P = {}
function P.Finite(v) return type(v)=='number' and v==v and v>-math.huge and v<math.huge end
function P.Radius(level) return math.min(17,8+math.floor(math.max(0,level-10)/10)) end
function P.NextRadiusLevel(level)
    if level>=100 then return nil end
    return math.max(20,10+(math.floor(math.max(0,level-10)/10)+1)*10)
end
function P.WingDrain(level) return level>=100 and 1 or level>=90 and 2 or level>=70 and 3 or 4 end
function P.EyeDrain(level) return level>=100 and 1 or level>=70 and 2 or level>=50 and 3 or 4 end
function P.Unlocked(def,s)
    if not s.ready then return false end
    if def.gate.kind=='always' then return true end
    local v=def.gate.kind=='level' and s.level or s.realm_rank
    return P.Finite(v) and v>=def.gate.value
end
P.Realms={'Luyện Khí Tiền Kỳ','Luyện Khí Trung Kỳ','Luyện Khí Hậu Kỳ',
    'Trúc Cơ Tiền Kỳ','Trúc Cơ Trung Kỳ','Trúc Cơ Hậu Kỳ',
    'Kết Đan Tiền Kỳ','Kết Đan Trung Kỳ','Kết Đan Hậu Kỳ',
    'Nguyên Anh Tiền Kỳ','Nguyên Anh Trung Kỳ','Nguyên Anh Hậu Kỳ',
    'Hóa Thần Tiền Kỳ','Hóa Thần Trung Kỳ','Hóa Thần Hậu Kỳ','Luyện Hư'}
return P
