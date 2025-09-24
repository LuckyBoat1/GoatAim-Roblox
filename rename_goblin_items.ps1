# PowerShell script to rename Meshes/weps1 and Meshes/weps2 items to Goblin_Name format
# This script will rename items in Roblox Studio hierarchy

Write-Host "Goblin Item Renaming Script" -ForegroundColor Green
Write-Host "This script will rename Meshes/weps1 and Meshes/weps2 items to Goblin_Name format" -ForegroundColor Yellow
Write-Host ""

# Define the patterns to match
$meshesWeps1Pattern = "Meshes/weps1_SM_Wep_"
$meshesWeps2Pattern = "Meshes/weps2_SM_Wep_"

# Sample items based on your list
$itemsToRename = @(
    "Meshes/weps1_SM_Wep_Goblin_Staff_01",
    "Meshes/weps1_SM_Wep_Greatsword_Curved_01", 
    "Meshes/weps1_SM_Wep_Greatsword_Straight_01",
    "Meshes/weps1_SM_Wep_Hammer_Large_Metal_01",
    "Meshes/weps1_SM_Wep_Hammer_Large_Metal_010",
    "Meshes/weps1_SM_Wep_Hammer_Mace_Stone_01",
    "Meshes/weps1_SM_Wep_Hammer_Small_02",
    "Meshes/weps1_SM_Wep_Handle_Metal_01",
    "Meshes/weps1_SM_Wep_Handle_Wood_01",
    "Meshes/weps1_SM_Wep_Mace_Blades_01",
    "Meshes/weps1_SM_Wep_Ornate_Axe_02",
    "Meshes/weps1_SM_Wep_Ornate_GreatAxe_01",
    "Meshes/weps1_SM_Wep_Spear_01",
    "Meshes/weps1_SM_Wep_Spear_02",
    "Meshes/weps1_SM_Wep_Staff_DoubleBlade_01",
    "Meshes/weps1_SM_Wep_Staff_Gem_01",
    "Meshes/weps1_SM_Wep_Straightsword_01",
    "Meshes/weps2_SM_Wep_Axe_01",
    "Meshes/weps2_SM_Wep_Banner_01",
    "Meshes/weps2_SM_Wep_Bone_01",
    "Meshes/weps2_SM_Wep_Bone_02",
    "Meshes/weps2_SM_Wep_BrokenSword_01",
    "Meshes/weps2_SM_Wep_Crysta_Halberd_01",
    "Meshes/weps2_SM_Wep_Crystal_Axe_Large_01",
    "Meshes/weps2_SM_Wep_Crystal_Ornate_Straightsword_01"
)

Write-Host "Items to be renamed:" -ForegroundColor Cyan
foreach ($item in $itemsToRename) {
    $newName = ""
    
    if ($item -match "Meshes/weps[12]_SM_Wep_(.+)") {
        $weaponName = $matches[1]
        $newName = "Goblin_$weaponName"
        
        Write-Host "  $item" -ForegroundColor White
        Write-Host "    -> $newName" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Roblox Studio Renaming Instructions:" -ForegroundColor Yellow
Write-Host "1. Open Roblox Studio" -ForegroundColor White
Write-Host "2. In the Explorer window, find each item listed above" -ForegroundColor White
Write-Host "3. Right-click the item and select 'Rename' or press F2" -ForegroundColor White
Write-Host "4. Replace the full name with the new name shown above" -ForegroundColor White
Write-Host ""

Write-Host "Alternatively, you can use this Lua script in Roblox Studio Command Bar:" -ForegroundColor Yellow
Write-Host ""

# Generate Lua script for Roblox Studio
$luaScript = @"
-- Lua script to rename Goblin weapons in Roblox Studio
-- Paste this into the Command Bar in Roblox Studio

local itemsToRename = {
"@

foreach ($item in $itemsToRename) {
    if ($item -match "Meshes/weps[12]_SM_Wep_(.+)") {
        $weaponName = $matches[1]
        $newName = "Goblin_$weaponName"
        $luaScript += "    {`"$item`", `"$newName`"}," + "`n"
    }
}

$luaScript += @"
}

for _, renameData in pairs(itemsToRename) do
    local oldName = renameData[1]
    local newName = renameData[2]
    
    -- Try to find the item in workspace or other common locations
    local item = game.Workspace:FindFirstChild(oldName, true) or 
                 game.ReplicatedStorage:FindFirstChild(oldName, true) or
                 game.ServerStorage:FindFirstChild(oldName, true)
    
    if item then
        item.Name = newName
        print("Renamed: " .. oldName .. " -> " .. newName)
    else
        warn("Could not find item: " .. oldName)
    end
end

print("Goblin renaming complete!")
"@

Write-Host $luaScript -ForegroundColor Magenta

Write-Host ""
Write-Host "Script completed! Copy the Lua code above into Roblox Studio's Command Bar to automatically rename items." -ForegroundColor Green
