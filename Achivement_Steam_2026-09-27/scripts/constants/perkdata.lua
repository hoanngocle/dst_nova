local files = {
    "attributes",
    "abilities",
    "crafting",
    "global",
}

local perk_lists = {}

for _, name in ipairs(files) do
    local data = require("constants/perks/" .. name)
    for k, v in pairs(data) do
        perk_lists[k] = v
    end
end

return perk_lists
