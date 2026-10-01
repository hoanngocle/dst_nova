-- Wave pools adapted from Solo Leveling 2.2.7 / Saikuno.
local vanilla_bosses = {"deerclops", "bearger", "dragonfly", "minotaur", "spiderqueen", "leif", "warg"}

local function GetMixedWave(max_waves, random)
    local cases = {
        {"hn_dungeon_spider", "hn_dungeon_spider", "hn_dungeon_spider", "hn_dungeon_spider", "hn_dungeon_spider", "hn_dungeon_spider", "hn_dungeon_spider", "hn_dungeon_spider", "hn_dungeon_spider", "hn_dungeon_spider"},
        {"hn_dungeon_horrorhound", "hn_dungeon_horrorhound", "hn_dungeon_firehound", "hn_dungeon_firehound", "hn_dungeon_icehound", "hn_dungeon_icehound", "hn_dungeon_snowhound", "hn_dungeon_snowhound", "hn_dungeon_lightninghound", "hn_dungeon_lightninghound"},
        {"spider_hider", "spider_hider", "spider_dropper", "spider_dropper", "spider_dropper", "spider_dropper", "spider_spitter", "spider_spitter", "spider_spitter", "spider_spitter"},
        {"tallbird", "tallbird", "tallbird", "tallbird", "tallbird", "tallbird", "tallbird", "tallbird", "tallbird", "tallbird"},
        {"lightninggoat", "lightninggoat", "lightninggoat", "lightninggoat", "lightninggoat", "lightninggoat", "lightninggoat", "lightninggoat", "lightninggoat", "lightninggoat"},
    }
    
    local hard_cases = {
        {"bishop", "bishop", "knight", "knight", "rook", "rook", "bishop_nightmare", "bishop_nightmare", "knight_nightmare", "rook_nightmare"},
        {"hn_dungeon_pig", "hn_dungeon_pig", "hn_dungeon_pig", "hn_dungeon_pig", "hn_dungeon_pig", "hn_dungeon_pig", "hn_dungeon_pig", "hn_dungeon_pig", "hn_dungeon_pig", "hn_dungeon_pig"},
        {"walrus", "walrus", "walrus", "walrus", "walrus", "walrus", "walrus", "walrus", "walrus", "walrus"},
        {"warglet", "warglet", "warglet", "warglet", "warglet", "warglet", "warglet", "warglet", "warglet", "warglet"}
    }
    
    local selected_case = nil
    if max_waves >= 6 then
        local combined = {}
        for _, v in ipairs(cases) do table.insert(combined, v) end
        for _, v in ipairs(hard_cases) do table.insert(combined, v) end
        selected_case = combined[random(#combined)]
    else
        selected_case = cases[random(#cases)]
    end
    
    local shuffled = {}
    for _, v in ipairs(selected_case) do table.insert(shuffled, v) end
    for i = #shuffled, 2, -1 do
        local j = random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    
    return shuffled
end
local super_bosses = {"hn_sharkboi", "hn_igris", "hn_beru", "hn_beetle_pig", "hn_dual_wield_pig", "hn_minotau"}


local M={}
function M.Get(wave,total,rng)
    rng=rng or math.random
    assert(total>=2 and total<=10 and wave>=1 and wave<=total)
    if wave==total then
        local pool=total>=6 and super_bosses or vanilla_bosses
        return {prefabs={pool[rng(#pool)]},is_boss=true,multiplier=total>=6 and 1.5 or 1}
    end
    return {prefabs=GetMixedWave(total,rng),is_boss=false,multiplier=total>=6 and 3 or 2}
end
return M
