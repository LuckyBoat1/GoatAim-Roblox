-- BulletManager.server.luau
-- Manages custom bullet visuals for weapons

local RS = game:GetService("ReplicatedStorage")

print("[BulletManager] 🔫 Initializing bullet system...")

-- Bullet storage
local BulletsFolder = RS:WaitForChild("Bullets", 5)
if not BulletsFolder then
	warn("[BulletManager] ❌ Bullets folder not found in ReplicatedStorage!")
	BulletsFolder = Instance.new("Folder")
	BulletsFolder.Name = "Bullets"
	BulletsFolder.Parent = RS
	warn("[BulletManager] Created Bullets folder")
end

-- Weapon to bullet mapping (lowercase normalized names)
local WEAPON_BULLETS = {
	["necromancer"] = "Darkness",
}

-- Get bullet for weapon
local function getBulletForWeapon(weaponName)
	if not weaponName then return nil end
	
	-- Normalize weapon name (lowercase, remove spaces)
	local normalizedName = string.lower(weaponName):gsub("%s+", "")
	
	-- Check if weapon has custom bullet
	local bulletName = WEAPON_BULLETS[normalizedName]
	if not bulletName then return nil end
	
	-- Get bullet from folder
	local bullet = BulletsFolder:FindFirstChild(bulletName)
	if not bullet then
		warn(string.format("[BulletManager] ❌ Bullet '%s' not found for weapon '%s'", bulletName, weaponName))
		return nil
	end
	
	return bullet
end

-- Create bullet instance for firing
function createBullet(weaponName, startPosition, direction)
	local bulletTemplate = getBulletForWeapon(weaponName)
	if not bulletTemplate then return nil end
	
	-- Clone the bullet
	local bullet = bulletTemplate:Clone()
	bullet.Position = startPosition
	bullet.CFrame = CFrame.lookAt(startPosition, startPosition + direction)
	bullet.Parent = workspace
	
	return bullet
end

-- Global API
_G.BulletManager = {
	getBullet = getBulletForWeapon,
	createBullet = createBullet,
	registerWeaponBullet = function(weaponName, bulletName)
		WEAPON_BULLETS[string.lower(weaponName):gsub("%s+", "")] = bulletName
	end
}

print("[BulletManager] ✅ Bullet system initialized")
print("[BulletManager] 📦 Registered bullets:", WEAPON_BULLETS)
