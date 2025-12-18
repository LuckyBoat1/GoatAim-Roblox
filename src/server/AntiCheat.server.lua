local lastShot ={}
local ReplicatedStorage = game:GetService ("ReplicatedStorage")
-- local shootEvent = Instance.new("RemoteEvent") shootEvent.Name = "ShootEvent" shootEvent.Parent = ReplicatedStorage
local shootEvent = ReplicatedStorage:WaitForChild("ShootEvent", 10)

if shootEvent then
	shootEvent.OnServerEvent:Connect (function(player)
		
		local now = tick()
		if now - (lastShot[player.UserId] or 0)<0.08 then 
			-- player:Kick ("Auto-cliking detected")	
			warn("[AntiCheat] Spam detected from " .. player.Name)
			return 
		end
		lastShot[player.UserId]= now
		-- _G.onShot(player) -- GameShooting handles this now
		
	end)
else
	warn("[AntiCheat] ShootEvent not found!")
end

