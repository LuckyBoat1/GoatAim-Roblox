-- ShootingHandler.client.luau
-- Paste the ShootingHandler LocalScript code here.
print("[ShootingHandler] ShootingHandler loaded and ready.")
local Rs = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Require SkinConfig to identify weapon types
local SkinConfig = require(Rs:WaitForChild("Shared"):WaitForChild("SkinConfig"))

local shootEvent = Rs:WaitForChild("ShootEvent", 20)
if not shootEvent then
	warn("[ShootingHandler] CRITICAL: ShootEvent not found after 20 seconds! Shooting will not work.")
end
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Use CrossHair > Frame > Dot center as the aim point instead of the mouse cursor
local dotFrame = player:WaitForChild("PlayerGui")
	:WaitForChild("CrossHair")
	:WaitForChild("Frame")
	:WaitForChild("Dot")

local function getDotAimPosition()
	-- Always use the Dot crosshair frame — this is the on-screen aim point for both PC and mobile.
	local center = dotFrame.AbsolutePosition + dotFrame.AbsoluteSize * 0.5
	local ray = camera:ScreenPointToRay(center.X, center.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local char = player.Character
	if char then
		params.FilterDescendantsInstances = { char }
	end
	local result = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
	if result then
		return result.Position
	end
	return ray.Origin + ray.Direction * 2000
end

-- List of weapon types that are MELEE (should NOT shoot)
local MELEE_TYPES = {
	"Blade", "Spear", "Axe", "GreatAxe", "HandAxe", "Sword", "Greatsword",
	"Hammer", "Mace", "Club", "Halberd", "Staff", "Machete", "Shiv",
	"Cutlass", "Banner", "Bone", "Melee",
	"Handle", "Wing", "Spikes",
}

local function tryShoot(gameProcessed)
	if gameProcessed then return end

	if not shootEvent then
		warn("[ShootingHandler] ❌ Cannot shoot - ShootEvent is missing!")
		return
	end

	-- 1. Check if player has a character
	local character = player.Character
	if not character then return end

	-- 2. Check if a weapon (Tool) is equipped
	local weapon = character:FindFirstChildOfClass("Tool")
	if not weapon then return end

	-- 3. Fire shoot event — aim direction from Dot crosshair center
	local aimPos = getDotAimPosition()
	shootEvent:FireServer(aimPos)

	-- Notify ShootingAnimation so it can play the firing anim in sync
	if _G.OnShootAnimation then
		_G.OnShootAnimation(weapon)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- PC left click only.
	-- Mobile shooting is handled exclusively by the shoot button (tap) and the auto-fire loop.
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		print("[ShootingHandler] 🖱️ MB1 Detected. GameProcessed:", gameProcessed)
		tryShoot(gameProcessed)
	end
end)

-- Exposed for the mobile Shoot button so it can bypass gameProcessed
_G.MobileTryShoot = function()
	tryShoot(false)
end

-- ── Mobile auto-fire ──────────────────────────────────────────────────────
-- On mobile, automatically shoot whenever the crosshair is aimed at an enemy.
-- No need to tap the shoot button; just aim and it fires.
local AUTO_FIRE_INTERVAL = 0.2  -- seconds between shots (customisable)

local function isEnemy(instance: BasePart): boolean
	-- Walk up to the model root and check for a Humanoid or boss Health attribute
	local model = instance:FindFirstAncestorOfClass("Model")
	if not model then return false end
	if model == player.Character then return false end
	-- Standard player / NPC: has a Humanoid
	if model:FindFirstChildOfClass("Humanoid") then return true end
	-- Boss / Bull: uses a Health attribute instead of Humanoid
	if model:GetAttribute("Health") ~= nil and (model:GetAttribute("Health") :: number) > 0 then
		return true
	end
	return false
end

local function crosshairAimedAtEnemy(): boolean
	local center = dotFrame.AbsolutePosition + dotFrame.AbsoluteSize * 0.5
	local ray = camera:ScreenPointToRay(center.X, center.Y)
	local aimDir = ray.Direction
	local origin = ray.Origin
	local char = player.Character

	-- Primary: direct raycast — fastest path, works for unobstructed PvE.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if char then params.FilterDescendantsInstances = { char } end
	local result = workspace:Raycast(origin, aimDir * 2000, params)
	if result and result.Instance and isEnemy(result.Instance) then
		return true
	end

	-- Secondary: 15-degree aim-cone scan — handles PvP arena walls, Abyss, and
	-- mobile aiming imprecision. 15° half-cone = 30° total, forgiving on mobile.
	local AIM_COS = math.cos(math.rad(15))
	local MAX_DIST = 2000

	-- 1. Other player characters (PvP arena, Abyss open-world PvP)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local plrChar = plr.Character
			local root = plrChar and plrChar:FindFirstChild("HumanoidRootPart")
			if root then
				local toTarget = root.Position - origin
				if toTarget.Magnitude <= MAX_DIST and aimDir:Dot(toTarget.Unit) >= AIM_COS then
					return true
				end
			end
		end
	end

	-- 2. All workspace models — covers PvE NPCs (which live in workspace root, NOT
	-- workspace.Game) and bull/boss models with a Health attribute.
	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model ~= char then
			local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
			if root then
				local toTarget = root.Position - origin
				if toTarget.Magnitude <= MAX_DIST and aimDir:Dot(toTarget.Unit) >= AIM_COS then
					-- Living Humanoid = standard NPC or player model
					local humanoid = model:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid.Health > 0 then
						return true
					end
					-- Health attribute = boss / non-humanoid enemy (e.g. Bull)
					local health = model:GetAttribute("Health")
					if health and (health :: number) > 0 then
						return true
					end
				end
			end
		end
	end

	return false
end

if UserInputService.TouchEnabled then
	task.spawn(function()
		while true do
			task.wait(AUTO_FIRE_INTERVAL)
			if crosshairAimedAtEnemy() then
				tryShoot(false)
			end
		end
	end)
end
