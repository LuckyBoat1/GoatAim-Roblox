-- SwingAnimation.server.luau
-- Handles server-side swing animation for blades and spears so other players can see the swing

local Rs = game:GetService("ReplicatedStorage")
local remoteEvents = Rs:WaitForChild("RemoteEvents")

-- Get/create Swing remote event
local swingRemote = remoteEvents:FindFirstChild("SwingAnimation")
if not swingRemote then
	swingRemote = Instance.new("RemoteEvent")
	swingRemote.Name = "SwingAnimation"
	swingRemote.Parent = remoteEvents
end

swingRemote.OnServerEvent:Connect(function(player, isSwinging, rightC0, leftC0)
	local character = player.Character
	if not character then return end
	
	print("[SwingAnimation] Received swing event from", player.Name, "- isSwinging:", isSwinging)
	
	-- Find the torso and shoulders
	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if not torso then 
		warn("[SwingAnimation] No torso found for", player.Name)
		return 
	end
	
	local rightShoulder = torso:FindFirstChild("Right Shoulder")
	local leftShoulder = torso:FindFirstChild("Left Shoulder")
	
	if not rightShoulder or not leftShoulder then
		warn("[SwingAnimation] Shoulders not found for", player.Name, "- might be R15")
		return
	end
	
	-- Apply the positions sent from client (this replicates to all players)
	if rightC0 and leftC0 then
		rightShoulder.C0 = rightC0
		leftShoulder.C0 = leftC0
		if isSwinging then
			print("[SwingAnimation] ✅ Applied swing positions for", player.Name)
		else
			print("[SwingAnimation] ✅ Reset to idle positions for", player.Name)
		end
	end
end)

print("[SwingAnimation] Swing animation server initialized - arm movements will replicate to all clients")
