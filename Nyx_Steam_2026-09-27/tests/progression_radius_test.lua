package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path

local progression = require('nyx/progression')

local milestones = {
    {9, 6, 20},
    {10, 6, 20},
    {19, 6, 20},
    {20, 6.5, 30},
    {30, 7, 40},
    {40, 7.5, 50},
    {49, 7.5, 50},
    {50, 8.5, 60},
    {60, 9, 70},
    {69, 9, 70},
    {70, 10, 80},
    {80, 10.5, 90},
    {90, 11, 100},
    {99, 11, 100},
    {100, 12, nil},
    {110, 12, nil},
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
