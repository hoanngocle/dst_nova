-- Four-slot Crock Pot examples checked against the game's cooking recipes.
-- Wet Goop is handled separately because it has no fixed ingredient recipe.
local examples = {
    asparagussoup = {"asparagus", "asparagus", "potato", "onion"},
    baconeggs = {"honey", "meat", "meat", "tallbirdegg"},
    bananajuice = {"honey", "honey", "cave_banana", "cave_banana"},
    bananapop = {"cave_banana", "ice", "ice", "twigs"},
    barnaclepita = {"honey", "honey", "barnacle", "carrot"},
    barnaclestuffedfishhead = {"barnacle", "fishmeat_small", "fishmeat_small", "potato"},
    barnaclesushi = {"barnacle", "kelp", "kelp", "bird_egg"},
    barnaclinguine = {"barnacle", "barnacle", "carrot", "carrot"},
    bonestew = {"meat", "meat", "meat", "meat"},
    bunnystew = {"smallmeat", "ice", "ice", "tomato"},
    butterflymuffin = {"butterflywings", "carrot", "carrot", "berries"},
    californiaroll = {"kelp", "kelp", "fishmeat_small", "fishmeat_small"},
    ceviche = {"honey", "fishmeat", "fishmeat", "ice"},
    dragonpie = {"dragonfruit", "dragonfruit", "potato", "pepper"},
    figatoni = {"honey", "carrot", "carrot", "fig"},
    figkabab = {"fig", "twigs", "smallmeat", "smallmeat"},
    fishsticks = {"fishmeat_small", "fishmeat_small", "fishmeat_small", "twigs"},
    fishtacos = {"fishmeat_small", "fishmeat_small", "corn", "onion"},
    flowersalad = {"carrot", "carrot", "carrot", "cactus_flower"},
    frogglebunwich = {"froglegs", "red_cap", "red_cap", "carrot"},
    frognewton = {"meat", "meat", "froglegs", "fig"},
    fruitmedley = {"twigs", "watermelon", "watermelon", "watermelon"},
    guacamole = {"mole", "rock_avocado_fruit_ripe", "rock_avocado_fruit_ripe", "corn"},
    honeyham = {"honey", "honey", "meat", "meat"},
    honeynuggets = {"honey", "honey", "smallmeat", "smallmeat"},
    hotchili = {"meat", "meat", "tomato", "pepper"},
    icecream = {"honey", "honey", "ice", "butter"},
    jammypreserves = {"honey", "honey", "bird_egg", "berries"},
    jellybean = {"honey", "honey", "honey", "royal_jelly"},
    justeggs = {"honey", "honey", "bird_egg", "tallbirdegg"},
    kabobs = {"meat", "onion", "eggplant", "twigs"},
    koalefig_trunk = {"honey", "honey", "fig", "trunk_summer"},
    leafloaf = {"honey", "meat", "plantmeat", "plantmeat"},
    leafymeatburger = {"honey", "plantmeat", "carrot", "onion"},
    leafymeatsouffle = {"honey", "honey", "plantmeat", "plantmeat"},
    lobsterbisque = {"honey", "honey", "wobster_sheller_land", "ice"},
    mashedpotatoes = {"honey", "potato", "potato", "garlic"},
    meatballs = {"meat", "meat", "smallmeat", "bird_egg"},
    meatysalad = {"plantmeat", "tomato", "tomato", "carrot"},
    monsterlasagna = {"honey", "honey", "monstermeat", "monstermeat"},
    pepperpopper = {"pepper", "smallmeat", "smallmeat", "potato"},
    perogies = {"honey", "meat", "bird_egg", "carrot"},
    potatotornado = {"honey", "honey", "twigs", "potato"},
    pumpkincookie = {"pumpkin", "honey", "honey", "berries"},
    ratatouille = {"honey", "honey", "bird_egg", "kelp"},
    salsa = {"honey", "honey", "onion", "tomato"},
    seafoodgumbo = {"honey", "fishmeat_small", "fishmeat", "eel"},
    shroomcake = {"moon_cap", "red_cap", "blue_cap", "green_cap"},
    stuffedeggplant = {"eggplant", "potato", "onion", "garlic"},
    surfnturf = {"honey", "meat", "fishmeat_small", "fishmeat"},
    sweettea = {"forgetmelots", "honey", "ice", "ice"},
    taffy = {"honey", "honey", "honey", "berries"},
    talleggs = {"honey", "honey", "tallbirdegg", "carrot"},
    trailmix = {"acorn_cooked", "acorn_cooked", "berries", "berries"},
    turkeydinner = {"drumstick", "drumstick", "meat", "berries"},
    unagi = {"honey", "honey", "eel", "kelp"},
    veggieomlet = {"honey", "honey", "bird_egg", "carrot"},
    waffles = {"honey", "bird_egg", "berries", "butter"},
    watermelonicle = {"honey", "ice", "twigs", "watermelon"},
}

local function GetTooltip(prefab, names)
    if prefab == "wetgoop" then
        return "Không có công thức cố định: 4 nguyên liệu không tạo được món khác."
    end

    local ingredients = examples[prefab]
    if ingredients == nil then
        return nil
    end

    local parts = {}
    local used = {}
    for _, ingredient in ipairs(ingredients) do
        if not used[ingredient] then
            used[ingredient] = true
            local count = 0
            for _, other in ipairs(ingredients) do
                if other == ingredient then
                    count = count + 1
                end
            end
            local name = names and names[string.upper(ingredient)] or nil
            parts[#parts + 1] = (count > 1 and count .. "× " or "") .. (name or ingredient)
        end
    end

    return "Công thức gợi ý: " .. table.concat(parts, " + ")
end

return { examples = examples, GetTooltip = GetTooltip }
