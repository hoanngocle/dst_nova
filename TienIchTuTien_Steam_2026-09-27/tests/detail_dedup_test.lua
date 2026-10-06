local mod_root = os.getenv('TTK_TEST_MOD_ROOT') or 'TienIchTuTien_Steam_2026-09-27'
package.path = mod_root .. '/scripts/?.lua;' .. package.path
local Hover = require('ttk_xd_hover')
local Detail = {
    Name = function() return 'Equipment' end,
    Colour = function() return {1, 1, 1, 1} end,
    StrengthenRows = function()
        return {{label = '+1', text = 'Upgrade milestone', colour = {1, 1, 1, 1}}}
    end,
}
local function count(text, marker)
    local n, start = 0, 1
    while true do
        local at = text:find(marker, start, true)
        if not at then return n end
        n, start = n + 1, at + #marker
    end
end
for _, kind in ipairs({'weapon', 'soul_banner', 'stone'}) do
    local detail = {kind = kind, level = 1, affixes = {}, other_affixes = {},
        name = 'Stone', colour = {1, 1, 1, 1}, affix_name = 'Affix',
        atlas = 'atlas', image = 'image', stat = 'Stat', description = 'Description', slot = 'Head'}
    local marker = kind == 'stone' and 'THUỘC TÍNH'
        or kind == 'soul_banner' and 'CƯỜNG HÓA' or 'THUỘC TÍNH · '
    for _, inline in ipairs({true, false}) do
        local rows = {{'Equipment'}, {'Native description'}}
        if inline then
            rows[2][1] = rows[2][1] .. '\n' .. marker .. '\nOld detail'
        else
            rows[3] = {marker}
            rows[4] = {'Old detail'}
        end
        local data = {str = rows}
        local first = Hover.Augment(data, {}, detail, Detail)
        local second = Hover.Augment(first, {}, detail, Detail)
        for _, result in ipairs({first, second}) do
            local text = {}
            for _, row in ipairs(result.str) do text[#text + 1] = row[1] end
            text = table.concat(text, '\n')
            assert(count(text, marker) == 1, kind .. ': detail section must appear once')
            assert(text:find('Native description', 1, true), 'native prefix must be preserved')
            assert(not text:find('Old detail', 1, true), 'previous appended detail must be replaced')
        end
        assert(rows[inline and 2 or 4][1]:find('Old detail', 1, true),
            'dedup must not mutate the incoming native data')
    end
end
print('detail_dedup_test: weapon, banner and stone detail passed')
