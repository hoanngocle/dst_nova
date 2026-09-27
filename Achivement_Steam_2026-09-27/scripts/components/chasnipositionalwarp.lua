local PositionalWarp = require("components/positionalwarp")

local ChasniPositionalWarp = Class(function(self, inst)
    PositionalWarp._ctor(self, inst)
end)

for k, v in pairs(PositionalWarp) do
    if type(v) == "function" then
        ChasniPositionalWarp[k] = v
    end
end

return ChasniPositionalWarp