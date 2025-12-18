-- Roblox Studio Command Bar Script
-- Removes "111" and "123" prefixes from skins in ReplicatedStorage.SkinLibrary

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local skinLibrary = ReplicatedStorage:FindFirstChild("SkinLibrary")

if not skinLibrary then
	warn("SkinLibrary not found in ReplicatedStorage!")
	return
end

local renamed = 0
local skipped = 0

for _, skin in ipairs(skinLibrary:GetChildren()) do
	local originalName = skin.Name
	local newName = nil
	
	-- Check for "111" prefix
	if string.sub(originalName, 1, 3) == "111" then
		newName = string.sub(originalName, 4) -- Remove first 3 characters
	-- Check for "123" prefix
	elseif string.sub(originalName, 1, 3) == "123" then
		newName = string.sub(originalName, 4) -- Remove first 3 characters
	end
	
	if newName and newName ~= "" then
		skin.Name = newName
		print(string.format("Renamed: '%s' -> '%s'", originalName, newName))
		renamed = renamed + 1
	else
		skipped = skipped + 1
	end
end

print(string.format("\nComplete! Renamed: %d | Skipped: %d", renamed, skipped))
