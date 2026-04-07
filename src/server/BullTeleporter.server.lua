-- BullTeleporter.server.lua
-- Handles BullPlatform touch detection and arena teleportation

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local COUNTDOWN_TIME = 3 -- Seconds to stand on platform before teleport

-- Wait for BullArenaManager to load
task.wait(1)

-- Get the platform (inside Game > SpawnArena folder)
local gameFolder = workspace:WaitForChild("Game", 30)
if not gameFolder then
	error("❌ Game folder not found in Workspace!")
end

local spawnArena = gameFolder:WaitForChild("SpawnArena", 30)
if not spawnArena then
	error("❌ SpawnArena folder not found in Game folder!")
end

local bullPlatform = spawnArena:FindFirstChild("BullPlatform")
if not bullPlatform then
	error("❌ BullPlatform not found in SpawnArena!")
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

-- ── BILLBOARD GUI (matches PvP / Arcade style) ────────────────────────────
local function createBullGui()
	local existing = bullPlatform:FindFirstChild("BullArenaGui")
	if existing then existing:Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Name = "BullArenaGui"
	bb.Size = UDim2.new(0, 200, 0, 80)
	bb.StudsOffset = Vector3.new(0, 8, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 60
	bb.Adornee = bullPlatform
	bb.Parent = bullPlatform

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(20, 10, 5)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = bb
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 140, 0)
	stroke.Thickness = 2
	stroke.Transparency = 0.2
	stroke.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "⚔️ BOSS ARENA"
	titleLabel.TextColor3 = Color3.fromRGB(255, 140, 0)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = frame

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Sub"
	subLabel.Size = UDim2.new(1, 0, 0.5, 0)
	subLabel.Position = UDim2.new(0, 0, 0.5, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = "Stand to Enter"
	subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	subLabel.TextScaled = true
	subLabel.Font = Enum.Font.GothamBold
	subLabel.Parent = frame
end

createBullGui()

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
							local inMagmorArena = _G.GetPlayerMagmorArena and _G.GetPlayerMagmorArena(player)
							if not currentArena and not inMagmorArena then
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

print("✅ Bull Teleporter ready - stand on SpawnArena.BullPlatform for " .. COUNTDOWN_TIME .. " seconds to enter!")
