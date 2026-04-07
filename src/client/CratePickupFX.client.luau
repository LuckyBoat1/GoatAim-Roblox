-- CratePickupFX.client.luau
-- Plays the smooth fly-to-player animation when a crate is picked up.
-- Runs entirely client-side via TweenService for buttery smooth movement.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 30)
if not RemoteEvents then return end

local CratePickupFXRE = RemoteEvents:WaitForChild("CratePickupFX", 30)
if not CratePickupFXRE then return end

------------------------------------------------------------------------
-- CRATE COLOURS (match server-side CRATE_INFO)
------------------------------------------------------------------------
local CRATE_COLORS = {
	BRONZE   = Color3.fromRGB(205, 127, 50),
	SILVER   = Color3.fromRGB(192, 192, 192),
	SAPPHIRE = Color3.fromRGB(65,  105, 225),
	OMEGA    = Color3.fromRGB(255, 128,   0),
	RUBY     = Color3.fromRGB(220,  20,  60),
}

local CRATE_NAMES = {
	BRONZE   = "Bronze Crate",
	SILVER   = "Silver Crate",
	SAPPHIRE = "Sapphire Crate",
	OMEGA    = "Omega Crate",
	RUBY     = "Ruby Crate",
}

------------------------------------------------------------------------
-- FX FUNCTION
------------------------------------------------------------------------
local function playFX(startPos, crateType)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local color = CRATE_COLORS[crateType:upper()] or Color3.fromRGB(255, 255, 255)

	------------------------------------------------------------------------
	-- Glowing neon orb that flies to the player
	------------------------------------------------------------------------
	local orb = Instance.new("Part")
	orb.Anchored     = true
	orb.CanCollide   = false
	orb.CanQuery     = false
	orb.CanTouch     = false
	orb.CastShadow   = false
	orb.Size         = Vector3.new(1.4, 1.4, 1.4)
	orb.Shape        = Enum.PartType.Ball
	orb.Material     = Enum.Material.Neon
	orb.Color        = color
	orb.CFrame       = CFrame.new(startPos)
	orb.Parent       = workspace

	-- Short point-light so it casts a coloured glow briefly
	local light = Instance.new("PointLight")
	light.Brightness = 4
	light.Range      = 12
	light.Color      = color
	light.Parent     = orb

	------------------------------------------------------------------------
	-- Pop sound (plays at crate world position)
	------------------------------------------------------------------------
	local sound = Instance.new("Sound")
	sound.SoundId          = "rbxassetid://5065880665"
	sound.Volume           = 0.7
	sound.PlaybackSpeed    = 1.05 + math.random() * 0.3
	sound.RollOffMaxDistance = 60
	sound.Parent           = orb
	sound:Play()

	------------------------------------------------------------------------
	-- Two-phase arc tween: rise toward midpoint, then accelerate into player
	------------------------------------------------------------------------
	local midPos = startPos:Lerp(root.Position, 0.45) + Vector3.new(0, 3.5, 0)

	local phase1 = TweenService:Create(orb,
		TweenInfo.new(0.36, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(midPos), Size = Vector3.new(1.0, 1.0, 1.0) }
	)

	phase1:Play()
	phase1.Completed:Connect(function()
		local targetPos = root.Position + Vector3.new(0, 0.5, 0)
		local phase2 = TweenService:Create(orb,
			TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = CFrame.new(targetPos), Size = Vector3.new(0.05, 0.05, 0.05) }
		)
		phase2:Play()
		phase2.Completed:Connect(function()
			orb:Destroy()

			-- Tiny screen-flash: brief +brightness on a white Part at origin
			-- (cheap "pop" feel without full screen effect)
			local flash = Instance.new("Part")
			flash.Anchored    = true
			flash.CanCollide  = false
			flash.CanQuery    = false
			flash.CanTouch    = false
			flash.Size        = Vector3.new(0.05, 0.05, 0.05)
			flash.Material    = Enum.Material.Neon
			flash.Color       = color
			flash.CFrame      = CFrame.new(targetPos)
			flash.Parent      = workspace
			TweenService:Create(flash,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = Vector3.new(3, 3, 3), Transparency = 1 }
			):Play()
			task.delay(0.3, function() flash:Destroy() end)
		end)
	end)
end

------------------------------------------------------------------------
-- LISTEN
------------------------------------------------------------------------
CratePickupFXRE.OnClientEvent:Connect(function(startPos, crateType)
	task.spawn(playFX, startPos, crateType)
end)
