-- ADSServer.server.luau
-- Handles server-side ADS arm positioning so other players can see arms move

local Rs = game:GetService("ReplicatedStorage")
local remoteEvents = Rs:WaitForChild("RemoteEvents")

-- Get/create ADS remote event
local adsRemote = remoteEvents:FindFirstChild("ADSToggle")
if not adsRemote then
	adsRemote = Instance.new("RemoteEvent")
	adsRemote.Name = "ADSToggle"
	adsRemote.Parent = remoteEvents
end

adsRemote.OnServerEvent:Connect(function(player, isADS, rightC0, leftC0)
	local character = player.Character
	if not character then return end
	
	print("[ADSServer] Received ADS event from", player.Name, "- isADS:", isADS)
	
	-- Find the torso and shoulders
	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if not torso then 
		warn("[ADSServer] No torso found for", player.Name)
		return 
	end
	
	local rightShoulder = torso:FindFirstChild("Right Shoulder")
	local leftShoulder = torso:FindFirstChild("Left Shoulder")
	
	if not rightShoulder or not leftShoulder then
		warn("[ADSServer] Shoulders not found for", player.Name, "- might be R15")
		return
	end
	
	-- Apply the positions sent from client (this replicates to all players)
	if isADS and rightC0 and leftC0 then
		rightShoulder.C0 = rightC0
		leftShoulder.C0 = leftC0
		print("[ADSServer] ✅ Applied ADS shoulder positions for", player.Name)
	else
		-- Reset positions
		if rightC0 and leftC0 then
			rightShoulder.C0 = rightC0
			leftShoulder.C0 = leftC0
			print("[ADSServer] ✅ Reset shoulder positions for", player.Name)
		end
	end
end)

print("[ADSServer] ADS server initialized - arm movements will replicate to all clients")
