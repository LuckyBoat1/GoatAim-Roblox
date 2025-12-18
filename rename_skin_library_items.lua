-- Roblox Studio Command Bar Script
-- This script renames all items in ReplicatedStorage.SkinLibrary
-- by removing "111" and "123" prefixes from their names

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkinLibrary = ReplicatedStorage:FindFirstChild("SkinLibrary")

if not SkinLibrary then
    warn("SkinLibrary not found in ReplicatedStorage!")
    return
end

local renamed = 0
local skipped = 0
local errors = 0

print("Starting to rename skins in SkinLibrary...")
print("----------------------------------------")

for _, item in pairs(SkinLibrary:GetChildren()) do
    local oldName = item.Name
    local newName = oldName
    
    -- Remove "111" prefix
    if string.sub(oldName, 1, 3) == "111" then
        newName = string.sub(oldName, 4)
    -- Remove "123" prefix (including special case "1238Bit")
    elseif string.sub(oldName, 1, 7) == "1238Bit" then
        newName = "8Bit"
    elseif string.sub(oldName, 1, 3) == "123" then
        newName = string.sub(oldName, 4)
    end
    
    -- Only rename if the name actually changed
    if newName ~= oldName and newName ~= "" then
        -- Check if an item with the new name already exists
        local existing = SkinLibrary:FindFirstChild(newName)
        if existing and existing ~= item then
            warn("Cannot rename '" .. oldName .. "' to '" .. newName .. "' - name already exists!")
            errors = errors + 1
        else
            local success, err = pcall(function()
                item.Name = newName
            end)
            
            if success then
                print("Renamed: '" .. oldName .. "' -> '" .. newName .. "'")
                renamed = renamed + 1
            else
                warn("Error renaming '" .. oldName .. "': " .. tostring(err))
                errors = errors + 1
            end
        end
    else
        skipped = skipped + 1
    end
end

print("----------------------------------------")
print("Renaming complete!")
print("Renamed: " .. renamed)
print("Skipped: " .. skipped)
print("Errors: " .. errors)
print("Total items: " .. #SkinLibrary:GetChildren())
