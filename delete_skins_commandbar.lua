-- Paste this into Roblox Studio Command Bar (or a Script) to delete matched skin items from SkinLibrary
-- Matched from SkinConfig.lua key names

local skinLibrary = game:GetService("ReplicatedStorage"):FindFirstChild("SkinLibrary")
if not skinLibrary then
	warn("SkinLibrary not found in ReplicatedStorage!")
	return
end

local toDelete = {
	"AA12 - Amas",          -- Shotgun / epic
	"Amethyst",             -- Blade / legendary
	"Anarchy",              -- Axe / epic
	"Apex",                 -- Blade / legendary
	"Astroid",              -- Launcher / epic
	"Axe of Wealth ",       -- GreatAxe / epic  (trailing space matches SkinConfig key)
	"Axe of Wealth",        -- also try without trailing space
	"Black Frost",          -- Blade / legendary
	"Black Matter",         -- Blade / legendary
	"Blood",                -- Blade / legendary
	"Blood Hungry",         -- Sword / epic
	"Blueberry",            -- Blade / epic
	"Buzz Cut",             -- Blade / legendary
	"Carpenter",            -- Blade / legendary
	"Champion",             -- Blade / legendary
	"China Fury",           -- SMG / epic
	"Cookie Cutter",        -- Blade / epic
	"Crimson Drake",        -- Blade / legendary
	"Demon",                -- Blade / legendary
	"Destroyer",            -- Mace / epic
	"Drip",                 -- Blade / epic
	"Ego",                  -- Blade / legendary
	"End",                  -- Mace / epic
	"Flame",                -- Blade / legendary
	"Gem Hammer",           -- Hammer / epic
	"Golden Sweet",         -- Blade / epic
	"GreatSword",           -- Greatsword / epic
	"Heavy Spin",           -- Minigun / epic
	"Hot Cheetoz",          -- Blade / epic
	"Huge Spoon",           -- Greatsword / epic
	"Horror",               -- Blade / legendary
	"Just give me my money",-- Revolver / epic
	"Laser Beam",           -- Revolver / epic
	"Magma Flow",           -- SMG / epic
	"Midnight",             -- Blade / epic
	"Moon Pike",            -- Spear / epic
	"Omega",                -- Blade / legendary
	"Red Falcon",           -- Axe / epic
	"Razor Edge",           -- Blade / epic
	"Sea Bone",             -- AK / epic
	"Skeleton",             -- AK / epic
	"Skull Disintigrator",  -- Hammer / epic
	"Sky",                  -- Rifle / legendary
	"Spooky Edge",          -- Blade / legendary
	"The Log",              -- Hammer / epic
	"trump",                -- Pistol / epic
}

local deleted = {}
local notFound = {}

for _, name in ipairs(toDelete) do
	local item = skinLibrary:FindFirstChild(name)
	if item then
		table.insert(deleted, name)
		item:Destroy()
	else
		table.insert(notFound, name)
	end
end

print("=== Skin Deletion Complete ===")
print("Deleted (" .. #deleted .. "):")
for _, name in ipairs(deleted) do
	print("  ✓ " .. name)
end
print("Not found (" .. #notFound .. "):")
for _, name in ipairs(notFound) do
	print("  ✗ " .. name)
end
