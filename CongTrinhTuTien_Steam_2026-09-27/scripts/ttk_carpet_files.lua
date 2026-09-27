-- Files from Carpet (workshop-2898491859) needed by both clients and servers.
local files = {
    "main/ttk_carpet.lua",
    "modworldgenmain.lua",
    "anim/py_turf.zip",
    "levels/tiles/py_carpet.xml",
    "levels/tiles/py_carpet.tex",
}

for i = 1, 15 do
    for _, extension in ipairs({"xml", "tex"}) do
        files[#files + 1] = "images/turf_py_carpet" .. i .. "." .. extension
        files[#files + 1] = "levels/textures/py_carpet" .. i .. "_noise." .. extension
    end
end

return files
