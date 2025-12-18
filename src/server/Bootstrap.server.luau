
print("!!! BOOTSTRAP ROOT IS RUNNING !!!")

-- Provide a default onShot handler so AntiCheat can call it safely.
_G.onShot = _G.onShot or function(_player: Player)
	-- noop placeholder
end

-- Ensure ShootEvent exists in ReplicatedStorage (simple bootstrap)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
if not ReplicatedStorage:FindFirstChild("ShootEvent") then
    local ev = Instance.new("RemoteEvent")
    ev.Name = "ShootEvent"
    ev.Parent = ReplicatedStorage
end

-- Force load the ShootingServer (now a ModuleScript) to ensure it runs
task.spawn(function()
	require(script.Parent:WaitForChild("GameShooting"))
end)

-- Force load EquipServer if it's not running automatically (debugging measure)
-- Note: EquipServer is a ServerScript, so we can't require it, but we can check if it's present
task.spawn(function()
    local equipScript = script.Parent:WaitForChild("EquipServer", 5)
    if equipScript then
        print("[Bootstrap] EquipServer script found in ServerScriptService")
    else
        warn("[Bootstrap] EquipServer script NOT found in ServerScriptService!")
    end
end)