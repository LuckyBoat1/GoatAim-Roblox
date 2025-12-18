-- BullTeleporter.server.lua
-- Handles BullPlatform touch detection and arena teleportation

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local COUNTDOWN_TIME = 3 -- Seconds to stand on platform before teleport

-- Wait for BullArenaManager to load
task.wait(1)

-- Get the platform
local bullPlatform = workspace:FindFirstChild("BullPlatform")
if not bullPlatform then
	error("❌ BullPlatform not found in Workspace!")
end

-- Make sure platform is a BasePart and CanCollide
if bullPlatform:IsA("BasePart") then
	bullPlatform.CanCollide = true
else
	-- If it's a model, find the main part
	local mainPart = bullPlatform:FindFirstChildWhichIsA("BasePart")
	if mainPart then
		bullPlatform = mainPart
		bullPlatform.CanCollide = true
	else
		error("❌ BullPlatform has no BasePart!")
	end
end

-- Track players on platform
local playersOnPlatform = {}

-- Global function to clear player from platform tracking (called by BullArenaManager when arena is freed)
_G.ClearPlayerFromPlatform = function(player)
	if playersOnPlatform[player.UserId] then
		playersOnPlatform[player.UserId] = nil
		print("🔄 Cleared " .. player.Name .. " from platform tracking - can retry")
	end
end

-- Setup RemoteEvents for UI
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
end

local TeleportCountdownRE = RemoteEvents:FindFirstChild("TeleportCountdown")
if not TeleportCountdownRE then
	TeleportCountdownRE = Instance.new("RemoteEvent")
	TeleportCountdownRE.Name = "TeleportCountdown"
	TeleportCountdownRE.Parent = RemoteEvents
end

print("🎮 Bull Teleporter initialized")
print("📍 Platform location:", bullPlatform:GetFullName())

local PROXIMITY_RANGE = 10 -- Distance in studs to activate

-- Main loop - check for nearby players
task.spawn(function()
	while true do
		task.wait(0.5) -- Check every half second
		
		for _, player in pairs(game.Players:GetPlayers()) do
			local character = player.Character
			if character then
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				if humanoidRootPart then
					local distance = (humanoidRootPart.Position - bullPlatform.Position).Magnitude
					
					-- Player is near platform
					if distance <= PROXIMITY_RANGE then
						-- Check if not already in countdown or arena
						if not playersOnPlatform[player.UserId] then
							local currentArena = _G.GetPlayerArena and _G.GetPlayerArena(player)
							if not currentArena then
								-- Start countdown
								playersOnPlatform[player.UserId] = true
								print("⏱️ " .. player.Name .. " near platform - starting countdown")
								
								task.spawn(function()
									-- Countdown loop
									for i = COUNTDOWN_TIME, 1, -1 do
										-- Check if player moved away
										local hrp = character:FindFirstChild("HumanoidRootPart")
										if not hrp or (hrp.Position - bullPlatform.Position).Magnitude > PROXIMITY_RANGE then
											print("❌ " .. player.Name .. " moved away from platform")
											TeleportCountdownRE:FireClient(player, 0)
											playersOnPlatform[player.UserId] = nil
											return
										end
										
										print("⏱️ Teleporting " .. player.Name .. " in " .. i .. "...")
										TeleportCountdownRE:FireClient(player, i)
										task.wait(1)
									end
									
									print("✅ Countdown complete for " .. player.Name .. " - attempting teleport...")
									
									-- Clear countdown UI
									TeleportCountdownRE:FireClient(player, 0)
									
									-- Request arena
									if _G.RequestBullArena then
										print("📞 Calling RequestBullArena for " .. player.Name)
										local arenaData = _G.RequestBullArena(player)
										if arenaData then
											print("✅ " .. player.Name .. " teleported to bull arena!")
										else
											warn("❌ Failed to teleport " .. player.Name .. " - no arenas available")
											playersOnPlatform[player.UserId] = nil
										end
									else
										warn("❌ BullArenaManager not loaded yet!")
										playersOnPlatform[player.UserId] = nil
									end
								end)
							end
						end
					else
						-- Player moved away, cancel countdown if active
						if playersOnPlatform[player.UserId] then
							playersOnPlatform[player.UserId] = nil
							TeleportCountdownRE:FireClient(player, 0)
							print("🚶 " .. player.Name .. " left platform area")
						end
					end
				end
			end
		end
	end
end)

print("✅ Bull Teleporter ready - stand on BullPlatform for " .. COUNTDOWN_TIME .. " seconds to enter!")
