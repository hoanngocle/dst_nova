local root = 'HamNgucTuTien/'
package.path = root..'scripts/?.lua;'..root..'tests/?.lua;'..package.path
unpack = unpack or table.unpack
local groups = {extra_bosses=true,worldgen=true,lifecycle=true,cooldown=true,actions=true,combat=true,rewards=true,recovery=true,restrictions=true,compat=true,network=true}
local selected = arg[1] or 'all'
assert(selected == 'all' or groups[selected], 'unknown test group: '..selected)
local passed, failed = 0, 0
function test(name, fn)
    local ok, err = xpcall(fn, debug.traceback)
    if ok then passed=passed+1; print('PASS '..name)
    else failed=failed+1; print('FAIL '..name..'\n'..err) end
end
for name in pairs(groups) do
    if selected == 'all' or selected == name then
        local ok, err = pcall(dofile, root..'tests/'..name..'_test.lua')
        if not ok then failed=failed+1; print('FAIL '..name..': '..tostring(err)) end
    end
end
print(string.format('%d passed, %d failed', passed, failed))
os.exit(failed == 0 and 0 or 1)

