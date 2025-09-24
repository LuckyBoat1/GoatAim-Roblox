-- SkinConfig Update Script for Goblin Weapons
-- This script updates the old Meshes/weps names to new Goblin names while preserving all data

-- Read the current SkinConfig
local file = io.open("d:/Apps/Roblox/src/shared/SkinConfig.lua", "r")
if not file then
    print("Error: Could not open SkinConfig.lua")
    return
end

local content = file:read("*all")
file:close()

-- Mapping of old names to new names based on your rename output
local nameMapping = {
    -- weps1 items
    ["Meshes/weps1_SM_Wep_Axe_Nature_01"] = "Goblin_Axe_Nature_01",
    ["Meshes/weps1_SM_Wep_Axe_Rune_01"] = "Goblin_Axe_Rune_01", 
    ["Meshes/weps1_SM_Wep_Crystal_Axe_01"] = "Goblin_Crystal_Axe_01",
    ["Meshes/weps1_SM_Wep_Crystal_DoubleSword_01"] = "Goblin_Crystal_DoubleSword_01",
    ["Meshes/weps1_SM_Wep_Goblin_Axe_01"] = "Goblin_Goblin_Axe_01",
    ["Meshes/weps1_SM_Wep_Goblin_Axe_Spikes_01"] = "Goblin_Goblin_Axe_Spikes_01",
    ["Meshes/weps1_SM_Wep_Goblin_Club_01"] = "Goblin_Goblin_Club_01",
    ["Meshes/weps1_SM_Wep_Goblin_Halberd_01"] = "Goblin_Goblin_Halberd_01",
    ["Meshes/weps1_SM_Wep_Goblin_Mace_01"] = "Goblin_Goblin_Mace_01",
    ["Meshes/weps1_SM_Wep_Goblin_Machete_01"] = "Goblin_Goblin_Machete_01",
    ["Meshes/weps1_SM_Wep_Goblin_Machete_Spikes_01"] = "Goblin_Goblin_Machete_Spikes_01",
    ["Meshes/weps1_SM_Wep_Goblin_Shiv_Bone_01"] = "Goblin_Goblin_Shiv_Bone_01",
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
    
    -- weps2 items
    ["Meshes/weps2_SM_Wep_Axe_01"] = "Goblin_Axe_01",
    ["Meshes/weps2_SM_Wep_Banner_01"] = "Goblin_Banner_01",
    ["Meshes/weps2_SM_Wep_Bone_01"] = "Goblin_Bone_01",
    ["Meshes/weps2_SM_Wep_Bone_02"] = "Goblin_Bone_02",
    ["Meshes/weps2_SM_Wep_BrokenSword_01"] = "Goblin_BrokenSword_01",
    ["Meshes/weps2_SM_Wep_Crysta_Halberd_01"] = "Goblin_Crysta_Halberdl_01", -- Note: matches your typo
    ["Meshes/weps2_SM_Wep_Crystal_Axe_Large_01"] = "Goblin_Crystal_Axe_Large_01",
    ["Meshes/weps2_SM_Wep_Crystal_Ornate_Straightsword_01"] = "Goblin_Crystal_Ornate_Straightsword_01",
    
    -- Additional items that might exist
    ["Meshes/weps1_SM_Wep_Cutlass_01"] = "Goblin_Cutlass_01",
    ["Meshes/weps1_SM_Wep_Goblin_Axe_Large_01"] = "Goblin_Goblin_Axe_Large_01",
    ["Meshes/weps1_SM_Wep_Goblin_Bone_Axe_01"] = "Goblin_Goblin_Bone_Axe_01",
    ["Meshes/weps1_SM_Wep_Goblin_Gem_Hammer_01"] = "Goblin_Goblin_Gem_Hammer_01",
    ["Meshes/weps1_SM_Wep_Goblin_Shiv_Stone_01"] = "Goblin_Goblin_Shiv_Stone_01",
    ["Meshes/weps1_SM_Wep_Goblin_Spear_01"] = "Goblin_Goblin_Spear_01",
    ["Meshes/weps1_SM_Wep_GreatSword_01"] = "Goblin_GreatSword_01",
    ["Meshes/weps1_SM_Wep_Greatsword_Round_01"] = "Goblin_Greatsword_Round_01",
    ["Meshes/weps2_SM_Wep_Halberd_06"] = "Goblin_Halberd_06",
    ["Meshes/weps1_SM_Wep_Hammer_Large_Stone_01"] = "Goblin_Hammer_Large_Stone_01",
    ["Meshes/weps1_SM_Wep_Hammer_Large_Wood_01"] = "Goblin_Hammer_Large_Wood_01",
    ["Meshes/weps1_SM_Wep_Hammer_Mace_Sphere_01"] = "Goblin_Hammer_Mace_Sphere_01",
    ["Meshes/weps1_SM_Wep_Hammer_Mace_Spikes_01"] = "Goblin_Hammer_Mace_Spikes_01",
    ["Meshes/weps1_SM_Wep_Hammer_Small_01"] = "Goblin_Hammer_Small_01",
    ["Meshes/weps1_SM_Wep_HandAxe_01"] = "Goblin_HandAxe_01",
    ["Meshes/weps1_SM_Wep_Ornate_Axe_01"] = "Goblin_Ornate_Axe_01",
    ["Meshes/weps1_SM_Wep_Ornate_Spear_01"] = "Goblin_Ornate_Spear_01",
    ["Meshes/weps1_SM_Wep_Ornate_Spikes_01"] = "Goblin_Ornate_Spikes_01",
    ["Meshes/weps1_SM_Wep_Ornate_Spikes_Long_01"] = "Goblin_Ornate_Spikes_Long_01",
    ["Meshes/weps1_SM_Wep_Ornate_Sword_01"] = "Goblin_Ornate_Sword_01",
    ["Meshes/weps1_SM_Wep_Ornate_Sword_02"] = "Goblin_Ornate_Sword_02",
}

print("Updating SkinConfig with new Goblin weapon names...")

-- Replace each old name with new name in the content
local updatedContent = content
local updateCount = 0

for oldName, newName in pairs(nameMapping) do
    local oldPattern = '["' .. oldName:gsub("([%[%]%(%)%.%+%-%*%?%^%$%%])", "%%%1") .. '"]'
    local newReplacement = '["' .. newName .. '"]'
    
    local newContent = updatedContent:gsub(oldPattern, newReplacement)
    if newContent ~= updatedContent then
        print("✓ Updated: " .. oldName .. " -> " .. newName)
        updatedContent = newContent
        updateCount = updateCount + 1
    end
end

-- Write the updated content back to the file
local outputFile = io.open("d:/Apps/Roblox/src/shared/SkinConfig.lua", "w")
if outputFile then
    outputFile:write(updatedContent)
    outputFile:close()
    print("")
    print("=== UPDATE COMPLETE ===")
    print("Total updates made: " .. updateCount)
    print("SkinConfig.lua has been updated with new Goblin weapon names!")
else
    print("Error: Could not write to SkinConfig.lua")
end
