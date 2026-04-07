-- _Bootstrap: Creates core RemoteEvents and default _G handlers.
-- Runs under ServerScriptService as an independent Script.
warn("!!! BOOTSTRAP SERVER SCRIPT IS RUNNING !!!")
print("!!! BOOTSTRAP SERVER SCRIPT IS RUNNING !!!")

-- Provide a default onShot handler so AntiCheat can call it safely.
_G.onShot = _G.onShot or function(_player: Player)
	-- noop placeholder
end

-- Ensure ShootEvent exists in ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
if not ReplicatedStorage:FindFirstChild("ShootEvent") then
	local ev = Instance.new("RemoteEvent")
	ev.Name = "ShootEvent"
	ev.Parent = ReplicatedStorage
end

warn("[Bootstrap] Init complete. All sibling scripts run independently.")
