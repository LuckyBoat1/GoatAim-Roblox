-- SkinTextureScanner.luau
-- Run this script in Roblox Studio to automatically scan all skins in ReplicatedStorage.SkinLibrary
-- and extract their TextureIds to generate a complete SkinConfig

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Function to extract TextureId from a skin model
local function extractTextureId(skinModel)
	if not skinModel then return nil end
	
	-- Method 1: Check if the model itself is a MeshPart with TextureId
	if skinModel:IsA("MeshPart") and skinModel.TextureId and skinModel.TextureId ~= "" then
		return skinModel.TextureId
	end
	
	-- Method 2: Look for MeshParts in descendants
	for _, descendant in pairs(skinModel:GetDescendants()) do
		if descendant:IsA("MeshPart") and descendant.TextureId and descendant.TextureId ~= "" then
			return descendant.TextureId
		end
	end
	
	-- Method 3: Look for Parts with Mesh children
	for _, descendant in pairs(skinModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local mesh = descendant:FindFirstChildOfClass("SpecialMesh") or descendant:FindFirstChildOfClass("Mesh")
			if mesh and mesh.TextureId and mesh.TextureId ~= "" then
				return mesh.TextureId
			end
		end
	end
	
	return nil
end

-- Function to determine weapon type from skin name
local function getWeaponFromName(skinName)
	local name = skinName:lower()
	if name:find("m4") then return "M4" end
	if name:find("ak") then return "AK" end
	if name:find("luger") then return "Luger" end
	if name:find("blaster") then return "Blaster" end
	if name:find("amerigun") then return "Amerigun" end
	if name:find("battleaxe") then return "BattleAxe" end
	return "Unknown"
end

-- Function to determine rarity (you might want to adjust this logic)
local function getRarityFromName(skinName)
	local name = skinName:lower()
	if name:find("default") or name:find("basic") then return "common" end
	if name:find("gold") or name:find("elite") or name:find("dragon") then return "legendary" end
	if name:find("death") or name:find("leviathan") or name:find("chaos") then return "mythic" end
	if name:find("monster") or name:find("mind") or name:find("fire") then return "epic" end
	return "rare" -- Default to rare if can't determine
end

-- Main scanning function
local function scanSkinLibrary()
	local skinLibrary = ReplicatedStorage:FindFirstChild("SkinLibrary")
	if not skinLibrary then
		warn("SkinLibrary not found in ReplicatedStorage!")
		return
	end
	
	print("=== SCANNING SKIN LIBRARY ===")
	print("Found SkinLibrary with", #skinLibrary:GetChildren(), "items")
	
	local scannedSkins = {}
	local textureResults = {}
	
	for _, skinModel in pairs(skinLibrary:GetChildren()) do
		local skinName = skinModel.Name
		local textureId = extractTextureId(skinModel)
		local weapon = getWeaponFromName(skinName)
		local rarity = getRarityFromName(skinName)
		
		scannedSkins[skinName] = {
			weapon = weapon,
			rarity = rarity,
			textureId = textureId,
			icon = textureId -- Use same ID for icon
		}
		
		if textureId then
			print(string.format("✅ %s: %s (%s, %s)", skinName, textureId, weapon, rarity))
			textureResults[skinName] = textureId
		else
			print(string.format("❌ %s: NO TEXTURE FOUND (%s, %s)", skinName, weapon, rarity))
		end
	end
	
	print("\n=== GENERATING SKINCONFIG CODE ===")
	print("-- Copy this code into your SkinConfig.lua SKINS table:")
	print("local SKINS = {")
	
	-- Sort by weapon type and name for better organization
	local sortedNames = {}
	for name, _ in pairs(scannedSkins) do
		table.insert(sortedNames, name)
	end
	table.sort(sortedNames, function(a, b)
		local aData = scannedSkins[a]
		local bData = scannedSkins[b]
		if aData.weapon == bData.weapon then
			return a < b
		end
		return aData.weapon < bData.weapon
	end)
	
	local currentWeapon = ""
	for _, skinName in ipairs(sortedNames) do
		local data = scannedSkins[skinName]
		
		-- Add weapon section comment
		if data.weapon ~= currentWeapon then
			if currentWeapon ~= "" then print("") end
			print(string.format("\t-- %s family", data.weapon))
			currentWeapon = data.weapon
		end
		
		-- Generate the skin entry
		local textureId = data.textureId or "rbxassetid://6764432243"
		local iconId = data.textureId or "rbxassetid://6764432243"
		
		print(string.format('\t["%s"] = { weapon="%s", rarity="%s", icon="%s", textureId="%s", adsAllowed=true },', 
			skinName, data.weapon, data.rarity, iconId, textureId))
	end
	
	print("}")
	
	print(string.format("\n=== SUMMARY ==="))
	print(string.format("Total skins scanned: %d", #sortedNames))
	
	local textureCount = 0
	for _ in pairs(textureResults) do textureCount = textureCount + 1 end
	print(string.format("Skins with textures: %d", textureCount))
	print(string.format("Skins missing textures: %d", #sortedNames - textureCount))
	
	-- Also store results globally for easy access
	_G.ScannedSkins = scannedSkins
	_G.TextureResults = textureResults
	
	print("\n✅ Scan complete! Results stored in _G.ScannedSkins and _G.TextureResults")
	print("Copy the generated SKINS table code above into your SkinConfig.lua file")
end

-- Run the scan
scanSkinLibrary()
