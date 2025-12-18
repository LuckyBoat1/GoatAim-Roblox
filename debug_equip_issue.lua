-- Debug script to check why grip adjustments aren't working
-- Run this in Roblox Studio Command Bar while holding a weapon

local player = game.Players.LocalPlayer
local char = player.Character
if not char then
    warn("No character found!")
    return
end

local tool = char:FindFirstChildOfClass("Tool")
if not tool then
    warn("No tool equipped!")
    return
end

print("=== WEAPON DEBUG INFO ===")
print("Tool Name:", tool.Name)
print("SkinId Attribute:", tool:GetAttribute("SkinId"))
print("Current Grip:", tool.Grip)
print("\n=== ATTRIBUTES ===")
for _, attr in pairs(tool:GetAttributes()) do
    print(attr)
end

-- Check if it's been adjusted
local skinId = tool:GetAttribute("SkinId") or "default"
local cleanSkinId = skinId:gsub("[%s/''&]", "_")
print("\nClean SkinId:", cleanSkinId)
print("WeaponRotated Key:", "WeaponRotated_" .. cleanSkinId)
print("GripAdjusted Key:", "GripAdjusted_" .. cleanSkinId)
print("\nWeaponRotated?", tool:GetAttribute("WeaponRotated_" .. cleanSkinId))
print("GripAdjusted?", tool:GetAttribute("GripAdjusted_" .. cleanSkinId))
print("EquipServerWatched?", tool:GetAttribute("EquipServerWatched"))
