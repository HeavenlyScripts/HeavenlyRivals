local SCRIPT_URL = "https://raw.githubusercontent.com/HeavenlyScripts/HeavenlyRivals/refs/heads/main/Rivals.lua"

local function LoadScript()
    pcall(function()
        local scriptContent = game:HttpGet(SCRIPT_URL, true)
        if scriptContent and scriptContent ~= "" then
            loadstring(scriptContent)()
        end
    end)
end

if queue_on_teleport then
    pcall(queue_on_teleport, [[
        task.wait(1)
        loadstring(game:HttpGet("]] .. SCRIPT_URL .. [[", true))()
    ]])
end

LoadScript()
