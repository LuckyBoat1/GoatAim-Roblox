local lastShot ={}
local ReplicatedStorage = game:GetService ("ReplicatedStorage")
local shootEvent = Instance.new("RemoteEvent") shootEvent.Name = "ShootEvent" shootEvent.Parent = ReplicatedStorage


shootEvent.OnServerEvent:Connect (function(player)
	
	local now = tick()
	if now - (lastShot[player.UserId] or 0)<0.08 then player:Kick ("Auto-cliking detected")	return end
	lastShot[player.UserId]= now
	_G.onShot(player)

	
end)

