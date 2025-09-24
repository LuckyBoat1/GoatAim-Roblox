-- Minimal Working Dash with Wall Stop + "DASH" text
-- LocalScript: StarterPlayer > StarterPlayerScripts

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local Debris             = game:GetService("Debris")
local RunService         = game:GetService("RunService")
local Workspace          = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

-- Re-bind on respawn
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid  = char:WaitForChild("Humanoid")
	rootPart  = char:WaitForChild("HumanoidRootPart")
end)

----------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------
local COOLDOWN          = 5        -- seconds
local FORCE             = 60       -- studs/sec
local BASE_DURATION     = 0.25     -- seconds (will shrink near walls)
local WALL_BUFFER       = 0.75     -- gap left before the wall
local LIVE_CHECK_STEP   = 0.03     -- how often to re-check forward while dashing
local PROBE_DISTANCE    = 2        -- forward probe during dash
local MIN_DURATION      = 0.05     -- smallest dash if wall very close
local MIN_MOVE_MAG      = 0.05     -- need at least some movement
local ALLOW_AIR         = true     -- allow mid-air dash

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local lastDashTime = -1e9
local glowActive = false

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "DashUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 105, 0, 36)  -- a bit smaller
frame.Position = UDim2.new(0, 20, 1, -60)
frame.AnchorPoint = Vector2.new(0,1)
frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,8)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(0,255,0)
stroke.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1,0,1,0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(0,255,0)
label.Text = "DASH"
label.Parent = frame

----------------------------------------------------------------
-- GLOW (only during cooldown)
----------------------------------------------------------------
local function startGlow()
	if glowActive then return end
	glowActive = true
	task.spawn(function()
		while glowActive do
			local t1 = TweenService:Create(stroke, TweenInfo.new(0.45, Enum.EasingStyle.Sine), {
				Thickness = 6,
				Color = Color3.fromRGB(0,180,0)
			})
			t1:Play(); t1.Completed:Wait()
			local t2 = TweenService:Create(stroke, TweenInfo.new(0.45, Enum.EasingStyle.Sine), {
				Thickness = 3,
				Color = Color3.fromRGB(0,255,0)
			})
			t2:Play(); t2.Completed:Wait()
		end
	end)
end

local function stopGlow()
	glowActive = false
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(0,255,0)
end

----------------------------------------------------------------
-- UI STATE
----------------------------------------------------------------
local function setReady()
	label.Text = "DASH"
	label.TextColor3 = Color3.fromRGB(0,255,0)
	stopGlow()
end

local function setCooldown(secondsLeft)
	label.Text = string.format("%.1f", secondsLeft)
	label.TextColor3 = Color3.fromRGB(160,160,160)
	startGlow()
end

----------------------------------------------------------------
-- WALL / DURATION CALC
----------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function computeDuration(direction)
	local maxDistance = FORCE * BASE_DURATION
	rayParams.FilterDescendantsInstances = {character}
	local result = Workspace:Raycast(rootPart.Position, direction * maxDistance, rayParams)
	if result and result.Instance and result.Instance.CanCollide then
		local allowed = math.max(0, result.Distance - WALL_BUFFER)
		local adjusted = allowed / FORCE
		if adjusted < MIN_DURATION then
			adjusted = MIN_DURATION
		end
		return adjusted
	end
	return BASE_DURATION
end

local function liveWallMonitor(direction, bodyVelocity, plannedEnd)
	while bodyVelocity.Parent do
		task.wait(LIVE_CHECK_STEP)
		if tick() >= plannedEnd then break end
		rayParams.FilterDescendantsInstances = {character}
		local hit = Workspace:Raycast(rootPart.Position, direction * PROBE_DISTANCE, rayParams)
		if hit and hit.Instance and hit.Instance.CanCollide then
			bodyVelocity:Destroy()
			break
		end
	end
end

----------------------------------------------------------------
-- DASH
----------------------------------------------------------------
local function canDash()
	local now = tick()
	if now < lastDashTime + COOLDOWN then return false end
	if humanoid.MoveDirection.Magnitude < MIN_MOVE_MAG then return false end
	if not ALLOW_AIR and humanoid.FloorMaterial == Enum.Material.Air then return false end
	return true
end

local function dash()
	if not canDash() then return end
	lastDashTime = tick()

	local dir = humanoid.MoveDirection
	if dir.Magnitude < MIN_MOVE_MAG then return end
	dir = Vector3.new(dir.X,0,dir.Z).Unit

	-- Adjust duration if a wall is near
	local duration = computeDuration(dir)

	-- BodyVelocity (simple + familiar)
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = dir * FORCE
	bv.MaxForce = Vector3.new(1e5, 0, 1e5)
	bv.Parent = rootPart
	local plannedEnd = tick() + duration
	Debris:AddItem(bv, duration)

	-- Monitor forward collisions
	task.spawn(function()
		liveWallMonitor(dir, bv, plannedEnd)
	end)

	-- Cooldown UI update loop (integer-ish feel, but we also refine each frame below)
end

----------------------------------------------------------------
-- INPUT
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		dash()
	end
end)

----------------------------------------------------------------
-- FRAME UPDATE (UI)
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	local now = tick()
	local remaining = (lastDashTime + COOLDOWN) - now
	if remaining <= 0 then
		setReady()
	else
		setCooldown(remaining)
	end
end)

-- Initialize
setReady()