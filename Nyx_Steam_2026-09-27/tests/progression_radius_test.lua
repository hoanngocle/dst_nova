package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path

local progression = require('nyx/progression')

local milestones = {
    {9, 2, 20},
    {10, 2, 20},
    {19, 2, 20},
    {20, 2.5, 30},
    {30, 3, 40},
    {40, 3.5, 50},
    {49, 3.5, 50},
    {50, 4.5, 60},
    {60, 5, 70},
    {69, 5, 70},
    {70, 6, 80},
    {80, 6.5, 90},
    {90, 7, 100},
    {99, 7, 100},
    {100, 8, nil},
    {110, 8, nil},
}

for _, case in ipairs(milestones) do
    local level, radius, next_level = case[1], case[2], case[3]
    assert(progression.Radius(level) == radius,
        ('level %d radius: expected %s, got %s'):format(level, radius, progression.Radius(level)))
    assert(progression.NextRadiusLevel(level) == next_level,
        ('level %d next increase: expected %s, got %s'):format(
            level, tostring(next_level), tostring(progression.NextRadiusLevel(level))))
end

print('gather radius: all level milestones verified')
