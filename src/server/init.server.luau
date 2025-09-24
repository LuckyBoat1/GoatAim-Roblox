
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