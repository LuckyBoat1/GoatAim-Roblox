-- Simple timer test to debug timing issues
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Test both timing functions
local startTime = os.time()
local startTick = tick()

print("=== TIMER TEST START ===")
print("os.time() at start:", startTime)
print("tick() at start:", startTick)

spawn(function()
    for i = 1, 10 do
        wait(1)
        local currentTime = os.time()
        local currentTick = tick()
        
        local elapsedTime = currentTime - startTime
        local elapsedTick = currentTick - startTick
        
        print(string.format("Second %d - os.time elapsed: %d, tick elapsed: %.1f", 
            i, elapsedTime, elapsedTick))
        
        if elapsedTime == 0 and i > 3 then
            print("WARNING: os.time() appears to be frozen! Use tick() instead.")
            break
        end
    end
end)
