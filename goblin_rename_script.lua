-- Roblox Studio Command Bar Script
-- Paste this entire script into the Command Bar in Roblox Studio to rename Goblin weapons

print("Starting Goblin weapon renaming...")

-- Function to rename items based on pattern
local function renameGoblinWeapons()
    local renamed = 0
    local notFound = 0
    
    -- Get all locations where items might be stored
    local locations = {
        game.Workspace,
        game.ReplicatedStorage,
        game.ServerStorage,
        game.StarterPack,
        game.StarterGui,
        game.StarterPlayer
    }
    
    -- Function to recursively search for items
    local function searchAndRename(parent, depth)
        if depth > 10 then return end -- Prevent infinite recursion
        
        for _, child in pairs(parent:GetChildren()) do
            local itemName = child.Name
            
            -- Check if item matches weps1 or weps2 pattern
            if string.find(itemName, "Meshes/weps1_SM_Wep_") or string.find(itemName, "Meshes/weps2_SM_Wep_") then
                local newName = ""
                
                -- Extract weapon name after the pattern
                local weaponName = string.gsub(itemName, "Meshes/weps[12]_SM_Wep_", "")
                newName = "Goblin_" .. weaponName
                
                -- Rename the item
                child.Name = newName
                print("✓ Renamed: " .. itemName .. " -> " .. newName)
                renamed = renamed + 1
                
            -- Also check for items that start with "Meshes" and contain "weps1" or "weps2"
            elseif string.sub(itemName, 1, 6) == "Meshes" and (string.find(itemName, "weps1") or string.find(itemName, "weps2")) then
                -- Remove everything up to and including "weps1_SM_Wep_" or "weps2_SM_Wep_"
                local weaponName = itemName
                weaponName = string.gsub(weaponName, ".*weps[12]_SM_Wep_", "")
                local newName = "Goblin_" .. weaponName
                
                child.Name = newName
                print("✓ Renamed: " .. itemName .. " -> " .. newName)
                renamed = renamed + 1
            end
            
            -- Recursively search children
            if #child:GetChildren() > 0 then
                searchAndRename(child, depth + 1)
            end
        end
    end
    
    -- Search all locations
    for _, location in pairs(locations) do
        if location then
            print("Searching in: " .. location.Name)
            searchAndRename(location, 0)
        end
    end
    
    print("")
    print("=== RENAMING COMPLETE ===")
    print("Items renamed: " .. renamed)
    if renamed == 0 then
        print("No matching items found. Make sure the items exist in your workspace.")
        print("Looking for items that match patterns:")
        print("  - Meshes/weps1_SM_Wep_*")
        print("  - Meshes/weps2_SM_Wep_*")
    end
end

-- Run the renaming function
renameGoblinWeapons()

-- Additional specific renaming for common items (if they exist with exact names)
local specificItems = {
    ["Meshes/weps1_SM_Wep_Goblin_Staff_01"] = "Goblin_Goblin_Staff_01",
    ["Meshes/weps1_SM_Wep_Greatsword_Curved_01"] = "Goblin_Greatsword_Curved_01",
    ["Meshes/weps1_SM_Wep_Greatsword_Straight_01"] = "Goblin_Greatsword_Straight_01",
    ["Meshes/weps1_SM_Wep_Hammer_Large_Metal_01"] = "Goblin_Hammer_Large_Metal_01",
    ["Meshes/weps1_SM_Wep_Hammer_Large_Metal_010"] = "Goblin_Hammer_Large_Metal_010",
    ["Meshes/weps1_SM_Wep_Hammer_Mace_Stone_01"] = "Goblin_Hammer_Mace_Stone_01",
    ["Meshes/weps1_SM_Wep_Hammer_Small_02"] = "Goblin_Hammer_Small_02",
    ["Meshes/weps1_SM_Wep_Handle_Metal_01"] = "Goblin_Handle_Metal_01",
    ["Meshes/weps1_SM_Wep_Handle_Wood_01"] = "Goblin_Handle_Wood_01",
    ["Meshes/weps1_SM_Wep_Mace_Blades_01"] = "Goblin_Mace_Blades_01",
    ["Meshes/weps1_SM_Wep_Ornate_Axe_02"] = "Goblin_Ornate_Axe_02",
    ["Meshes/weps1_SM_Wep_Ornate_GreatAxe_01"] = "Goblin_Ornate_GreatAxe_01",
    ["Meshes/weps1_SM_Wep_Spear_01"] = "Goblin_Spear_01",
    ["Meshes/weps1_SM_Wep_Spear_02"] = "Goblin_Spear_02",
    ["Meshes/weps1_SM_Wep_Staff_DoubleBlade_01"] = "Goblin_Staff_DoubleBlade_01",
    ["Meshes/weps1_SM_Wep_Staff_Gem_01"] = "Goblin_Staff_Gem_01",
    ["Meshes/weps1_SM_Wep_Straightsword_01"] = "Goblin_Straightsword_01",
    ["Meshes/weps2_SM_Wep_Axe_01"] = "Goblin_Axe_01",
    ["Meshes/weps2_SM_Wep_Banner_01"] = "Goblin_Banner_01",
    ["Meshes/weps2_SM_Wep_Bone_01"] = "Goblin_Bone_01",
    ["Meshes/weps2_SM_Wep_Bone_02"] = "Goblin_Bone_02",
    ["Meshes/weps2_SM_Wep_BrokenSword_01"] = "Goblin_BrokenSword_01",
    ["Meshes/weps2_SM_Wep_Crysta_Halberd_01"] = "Goblin_Crysta_Halberd_01",
    ["Meshes/weps2_SM_Wep_Crystal_Axe_Large_01"] = "Goblin_Crystal_Axe_Large_01",
    ["Meshes/weps2_SM_Wep_Crystal_Ornate_Straightsword_01"] = "Goblin_Crystal_Ornate_Straightsword_01"
}

print("")
print("Checking for specific items...")
local specificRenamed = 0

for oldName, newName in pairs(specificItems) do
    -- Search all locations for exact matches
    for _, location in pairs({game.Workspace, game.ReplicatedStorage, game.ServerStorage}) do
        local item = location:FindFirstChild(oldName, true)
        if item then
            item.Name = newName
            print("✓ Specifically renamed: " .. oldName .. " -> " .. newName)
            specificRenamed = specificRenamed + 1
        end
    end
end

print("Specific items renamed: " .. specificRenamed)
print("")
print("🎯 GOBLIN RENAMING SCRIPT COMPLETE! 🎯")
print("Remember to save your place after renaming!")
