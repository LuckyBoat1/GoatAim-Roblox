-- ShootingAnimation.client.luau
-- Procedural weapon recoil via spring physics on the RightGrip Motor6D.
-- The GUN physically kicks back and tilts up on every shot, then springs to rest.
-- Camera and head are completely unaffected.
-- Triggered by ShootingHandler via _G.OnShootAnimation(weapon) after every shot.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Rs         = game:GetService("ReplicatedStorage")

local SkinConfig = require(Rs:WaitForChild("Shared"):WaitForChild("SkinConfig"))

local player = Players.LocalPlayer

-- ── Recoil tuning ─────────────────────────────────────────────────────────────
-- RECOIL_MULTIPLIER: master scale applied on top of every weapon's own mult.
--   Raise this to make everything kick harder across the board.
local RECOIL_MULTIPLIER = 1.0

-- angle = degrees the barrel tilts upward per shot
-- back  = studs the weapon slides backward per shot
-- mult  = per-weapon strength (light = 2, heavy = 4)
local RECOIL_BY_WEAPON = {
	Pistol   = { angle = 8,  back = 0.35, mult = 2 },
	Revolver = { angle = 13, back = 0.55, mult = 4 },
	SMG      = { angle = 5,  back = 0.25, mult = 2 },
	AK       = { angle = 10, back = 0.45, mult = 2 },
	M4       = { angle = 8,  back = 0.35, mult = 2 },
	Rifle    = { angle = 10, back = 0.45, mult = 2 },
	Sniper   = { angle = 20, back = 0.90, mult = 4 },
	Shotgun  = { angle = 15, back = 0.75, mult = 4 },
	LMG      = { angle = 6,  back = 0.30, mult = 4 },
	Minigun  = { angle = 3,  back = 0.18, mult = 2 },
}
local RECOIL_DEFAULT = { angle = 8, back = 0.35, mult = 2 }

-- Spring constants
local STIFFNESS = 22   -- higher = snaps back faster
local DAMPING   = 11   -- higher = less bounce

-- ── Melee exclusion ───────────────────────────────────────────────────────────
local MELEE_TYPES = {
	Blade=true, Spear=true, Axe=true, GreatAxe=true, HandAxe=true,
	Sword=true, Greatsword=true, Hammer=true, Mace=true, Club=true,
	Halberd=true, Staff=true, Machete=true, Shiv=true, Cutlass=true,
	Banner=true, Bone=true, Melee=true,
}

-- ── Spring state ──────────────────────────────────────────────────────────────
local recoilAngle = 0   -- radians, current tilt
local recoilBack  = 0   -- studs, current backward offset
local velAngle    = 0
local velBack     = 0

-- ── Grip tracking ─────────────────────────────────────────────────────────────
local cachedGrip   = nil
local cachedGripC0 = CFrame.new()

local function findGrip(character)
	local hand = character and character:FindFirstChild("RightHand")
	return hand and hand:FindFirstChild("RightGrip")
end

-- Full cache: captures both the grip reference AND its resting C0.
-- Only call this when recoil is at zero (i.e. at equip time).
local function cacheGrip(character)
	local grip = findGrip(character)
	if grip then
		cachedGrip   = grip
		cachedGripC0 = grip.C0   -- clean resting pose — never read mid-recoil
	else
		cachedGrip   = nil
		cachedGripC0 = CFrame.new()
	end
end

-- Reference-only refresh: updates the grip object pointer but NEVER overwrites
-- cachedGripC0, so the resting pose is safe even if called mid-recoil.
local function refreshGripRef(character)
	local grip = findGrip(character)
	if grip and grip ~= cachedGrip then
		-- New grip appeared (shouldn't normally happen mid-recoil, but just in case).
		-- Only capture C0 if the spring has fully settled.
		local settled = math.abs(recoilAngle) < 0.0001 and math.abs(recoilBack) < 0.0001
		cachedGrip = grip
		if settled then cachedGripC0 = grip.C0 end
	end
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function rad(deg) return deg * (math.pi / 180) end

local function getProfile(weapon)
	if not weapon then return RECOIL_DEFAULT end
	local meta = SkinConfig.GetSkinMeta(weapon:GetAttribute("SkinId") or "")
	if not meta then return RECOIL_DEFAULT end
	if MELEE_TYPES[meta.weapon] then return nil end
	return RECOIL_BY_WEAPON[meta.weapon] or RECOIL_DEFAULT
end

-- ── Per-frame spring (weapon Motor6D only, camera untouched) ──────────────────
RunService:BindToRenderStep("ShootingRecoil", Enum.RenderPriority.Last.Value, function(dt)
	local dead = math.abs(recoilAngle) < 0.0001
	          and math.abs(recoilBack)  < 0.0001
	          and math.abs(velAngle)    < 0.0001
	          and math.abs(velBack)     < 0.0001
	if dead then return end

	local aA = -STIFFNESS * recoilAngle - DAMPING * velAngle
	local aB = -STIFFNESS * recoilBack  - DAMPING * velBack

	velAngle    = velAngle + aA * dt
	velBack     = velBack  + aB * dt
	recoilAngle = recoilAngle + velAngle * dt
	recoilBack  = recoilBack  + velBack  * dt

	local char = player.Character
	if not char then return end

	-- Re-find grip reference if lost, but don't overwrite the resting C0
	if not cachedGrip or not cachedGrip.Parent then
		refreshGripRef(char)
	end

	if cachedGrip and cachedGrip.Parent then
		-- Barrel tilts up, gun slides backward (-Z = away from barrel tip) and rises slightly
		cachedGrip.C0 = cachedGripC0
			* CFrame.new(0, recoilBack * 0.3, recoilBack)
			* CFrame.Angles(recoilAngle, 0, 0)
	end
end)

-- ── Public hook ───────────────────────────────────────────────────────────────
_G.OnShootAnimation = function(weapon)
	local profile = getProfile(weapon)
	if not profile then return end
	-- Do NOT re-cache here — cacheGrip is only called at equip time so
	-- cachedGripC0 always holds the true resting pose, never a mid-recoil value.
	local scale = (profile.mult or 2) * RECOIL_MULTIPLIER
	velAngle = velAngle + rad(profile.angle) * scale
	velBack  = velBack  + profile.back       * scale
end

-- ── Character respawn ─────────────────────────────────────────────────────────
local function onCharacterAdded(character)
	recoilAngle = 0
	recoilBack  = 0
	velAngle    = 0
	velBack     = 0
	cachedGrip  = nil

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			-- Wait for EquipServer + GripAdjuster to finish adjusting the grip before
			-- caching. GripAdjuster sets GripReady=true AFTER EquipServer signals done.
			-- This prevents cachedGripC0 from capturing the pre-rotation pose, which
			-- would cause the recoil spring to animate from the wrong base (visible as
			-- broken rotation/position after shooting, especially on mobile).
			local deadline = tick() + 5
			while child.Parent and not child:GetAttribute("GripReady") and tick() < deadline do
				task.wait(0.05)
			end
			if not child.Parent then return end -- tool was unequipped while we waited
			cacheGrip(character)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			cachedGrip   = nil
			cachedGripC0 = CFrame.new()
		end
	end)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

print("[ShootingAnimation] Weapon recoil active — gun kicks, camera stays still.")

