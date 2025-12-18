-- Rename items in SkinLibrary to add 111 prefix
-- Copy this entire script and paste it into Roblox Studio Command Bar, then press Enter

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local skinLibrary = ReplicatedStorage:FindFirstChild("SkinLibrary")

if not skinLibrary then
    warn("❌ SkinLibrary not found!")
    return
end

-- List of items to rename (add 111 prefix to these)
local itemsToRename = {
    "Amerigun",
    "BattleAxeII",
    "Blaster",
    "Blue Candy",
    "Blue Seer",
    "Blue Sugar",
    "Boneblade",
    "Candy",
    "Chill",
    "Chroma Boneblade",
    "Chroma Fang",
    "Chroma Gingerblade",
    "Clockwork",
    "Deathshard",
    "Eternal",
    "Eternal II",
    "Fang",
    "Frostsaber",
    "Ginger Luger",
    "Gingerblade",
    "Gold Sugar",
    "Green Luger",
    "Hallow's Blade",
    "Hallow's Edge",
    "Hand Saw",
    "Ice Dragon",
    "Ice Shard",
    "Knife Box 2 Kit",
    "Laser",
    "Luger",
    "Nightblade",
    "Old Glory",
    "Orange Seer",
    "Pixel",
    "Pumpking",
    "Purple Seer",
    "Red Hallow ",
    "Red Luger",
    "Red Seer",
    "Saw",
    "Seer",
    "Shark",
    "Slasher",
    "Snowflake",
    "Spider",
    "Tides",
    "Virtual",
    "Winter's Edge",
    "Xmas",
    "Yellow Seer",
    "escape",
}

local renamed = 0
local notFound = 0

print("🔄 Starting rename process...")

for _, itemName in ipairs(itemsToRename) do
    local item = skinLibrary:FindFirstChild(itemName)
    if item then
        local newName = "111" .. itemName
        -- Check if target name already exists
        if skinLibrary:FindFirstChild(newName) then
            warn("⚠️ '" .. newName .. "' already exists! Skipping '" .. itemName .. "'")
        else
            item.Name = newName
            renamed = renamed + 1
            print("✅ Renamed: '" .. itemName .. "' → '" .. newName .. "'")
        end
    else
        notFound = notFound + 1
        warn("❌ Not found: '" .. itemName .. "'")
    end
end

print("\n========================================")
print("📊 RENAME COMPLETE")
print("========================================")
print("✅ Renamed: " .. renamed .. " items")
print("❌ Not found: " .. notFound .. " items")
print("========================================")
