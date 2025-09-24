-- Server-side equipment handler
-- Handles weapon grip positioning that's visible to all players

local Players = game:GetService("Players")

-- Equipped weapon rotations (separate from viewport rotations)
-- These rotations are specifically for when weapons are equipped and held by players
local EQUIPPED_WEAPON_ROTATIONS = {
    -- Meshes/ weapons (spears) - using the complex rotation for equipped weapons
    ["Meshes/"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(90)), -- Complex rotation restored
    
    -- Specific weapon rotations for when equipped
    ["PKM"] = CFrame.Angles(math.rad(360), math.rad(0), math.rad(90)),
    ["shiv"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
    ["Vintorez"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270)),
    ["Viper/Mp5"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(-90)),
    ["Chaser"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(90)),
    
    -- Hydra and Dragonspine use the default Meshes/ rotation with 180° Y flip
    ["Meshes/hydra"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(90)) * CFrame.Angles(0, math.rad(180), 0),
    ["Meshes/dragonspine"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(90)) * CFrame.Angles(0, math.rad(180), 0),
    
    -- Special spear weapons with 90° Y rotation
    ["Meshes/magma"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/primordial jade winged-spear"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
    ["Meshes/storm"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
}

-- Equipment positioning settings
local GRIP_OFFSET = CFrame.new(0, 0.5, 0.3) -- Base forward position with higher Y offset

-- Specific grip adjustments for different weapon types
local GRIP_ADJUSTMENTS = {
    -- Meshes/ weapons (spears) use lighter positioning
    ["Meshes/"] = CFrame.new(0, -0.7, 0.2), -- Position adjustment for most spear weapons
    
  --  -- Specific weapon overrides
    ["Meshes/dragonspine"] = CFrame.new(0, -9.6, 0.4), -- X: 0, Y: -0.7, Z: 0.2
    ["Meshes/hydra"] = CFrame.new(0, -10.7, -0.2), -- Hydra uses the heavier positioning
    
    -- Special spear weapons with custom positioning
    ["Meshes/magma"] = CFrame.new(0, -5.9, 0), -- Magma: raised position
    ["Meshes/primordial jade winged-spear"] = CFrame.new(0, -5.9, 0), -- Primordial: raised position
    ["Meshes/storm"] = CFrame.new(0, -5.9, 0), ---- Storm: highest raised position
}

-- Function to get equipped weapon rotation (separate from viewport rotations)
local function getEquippedWeaponRotation(weaponName, skinId)
    local sourceName = weaponName or "Unknown"
    
    -- Check for skin-specific name first
    if skinId and skinId ~= "" then
        sourceName = skinId
    end
    
    print("[EquipServer] Getting equipped rotation for:", sourceName)
    
    -- Check for specific weapon rotations FIRST (including specific Meshes/ weapons)
    if EQUIPPED_WEAPON_ROTATIONS[sourceName] then
        local specificRotation = EQUIPPED_WEAPON_ROTATIONS[sourceName]
        print("[EquipServer] Applied specific rotation for", sourceName, ":", specificRotation)
        return specificRotation
    end
    
    -- Check if it's a generic Meshes/ weapon (spears) - only if no specific rotation found
    if sourceName:find("Meshes/") then
        local firstRotation = EQUIPPED_WEAPON_ROTATIONS["Meshes/"]
        local secondRotation = CFrame.Angles(0, math.rad(180), 0) -- 180 degrees on Y axis
        local combinedRotation = firstRotation * secondRotation
        print("[EquipServer] Applied generic Meshes/ first rotation:", firstRotation)
        print("[EquipServer] Applied generic Meshes/ second rotation (180° Y):", secondRotation)
        print("[EquipServer] Applied generic Meshes/ combined rotation:", combinedRotation)
        return combinedRotation
    end
    
    -- Default: no rotation for equipped weapons
    print("[EquipServer] No specific rotation found, using default (no rotation)")
    return CFrame.new()
end
local function adjustWeaponGrip(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    -- Create unique key using skin ID to allow reprocessing when skin changes
    local skinId = tool:GetAttribute("SkinId") or "default"
    local gripKey = "GripAdjusted_" .. skinId
    
    -- Exit early if this tool+skin combination has already been processed
    if tool:GetAttribute(gripKey) then
        print("[EquipServer] Tool", tool.Name, "with skin", skinId, "already processed, skipping")
        return
    end
    
    print("[EquipServer] Processing weapon:", tool.Name)
    
    -- Store the original grip BEFORE we modify it (for client grip adjuster to use)
    if not tool:GetAttribute("OriginalGripStored") then
        local original = tool.Grip
        tool:SetAttribute("OriginalGripX", original.X)
        tool:SetAttribute("OriginalGripY", original.Y)
        tool:SetAttribute("OriginalGripZ", original.Z)
        tool:SetAttribute("OriginalGripRX", original.RightVector.X)
        tool:SetAttribute("OriginalGripRY", original.RightVector.Y)
        tool:SetAttribute("OriginalGripRZ", original.RightVector.Z)
        tool:SetAttribute("OriginalGripUX", original.UpVector.X)
        tool:SetAttribute("OriginalGripUY", original.UpVector.Y)
        tool:SetAttribute("OriginalGripUZ", original.UpVector.Z)
        tool:SetAttribute("OriginalGripLX", original.LookVector.X)
        tool:SetAttribute("OriginalGripLY", original.LookVector.Y)
        tool:SetAttribute("OriginalGripLZ", original.LookVector.Z)
        tool:SetAttribute("OriginalGripStored", true)
        print("[EquipServer] Stored original grip:", original)
    end
    
    -- Get the SkinId attribute (this is where "Meshes/" info is stored)
    local skinId = tool:GetAttribute("SkinId")
    print("[EquipServer] SkinId:", skinId or "none")
    
    -- Check if it's a Meshes/ weapon (check both tool name and skin)
    local isMeshesWeapon = (skinId and string.find(skinId, "Meshes/")) or string.find(tool.Name, "Meshes/")
    print("[EquipServer] Is Meshes/ weapon:", isMeshesWeapon and "YES" or "NO")
    
    -- Get equipped weapon rotation (separate from viewport rotations)
    local weaponRotation = getEquippedWeaponRotation(tool.Name, skinId)
    print("[EquipServer] Applied equipped rotation:", weaponRotation)
    
    -- Get grip adjustment for this weapon type
    local gripAdjustment = CFrame.new()
    
    -- Check for specific weapon adjustments first (including hydra and dragonspine)
    if skinId and GRIP_ADJUSTMENTS[skinId] then
        gripAdjustment = GRIP_ADJUSTMENTS[skinId]
        print("[EquipServer] Applied specific grip adjustment for", skinId, ":", gripAdjustment)
        print("[EquipServer] Grip adjustment position:", gripAdjustment.Position)
        print("[EquipServer] Grip adjustment X,Y,Z:", gripAdjustment.X, gripAdjustment.Y, gripAdjustment.Z)
    -- Apply Meshes/ adjustment for all other Meshes/ weapons
    elseif isMeshesWeapon and GRIP_ADJUSTMENTS["Meshes/"] then
        gripAdjustment = GRIP_ADJUSTMENTS["Meshes/"]
        print("[EquipServer] Applied Meshes/ grip adjustment:", gripAdjustment)
        print("[EquipServer] Meshes grip adjustment position:", gripAdjustment.Position)
        print("[EquipServer] Meshes grip adjustment X,Y,Z:", gripAdjustment.X, gripAdjustment.Y, gripAdjustment.Z)
    else
        print("[EquipServer] No grip adjustment found for", skinId, "- using default (no adjustment)")
    end
    
    -- Add height adjustment for spear weapons (Meshes/)
    local heightOffset = CFrame.new()
    if isMeshesWeapon then
        -- TEMPORARILY DISABLED to see default position
        -- heightOffset = CFrame.new(0, 0.5, 0) -- Raise spears by 0.5 studs
        print("[EquipServer] Height adjustment DISABLED for testing")
    end
    
    -- Apply rotation, grip adjustment, and height offset
    local fullOffset = weaponRotation * gripAdjustment * heightOffset
    
    print("[EquipServer] Weapon rotation:", weaponRotation)
    print("[EquipServer] Grip adjustment:", gripAdjustment)
    print("[EquipServer] Height offset:", heightOffset)
    print("[EquipServer] Full offset:", fullOffset)
    print("[EquipServer] Full offset position:", fullOffset.Position)
    print("[EquipServer] Full offset X,Y,Z:", fullOffset.X, fullOffset.Y, fullOffset.Z)
    
    -- Apply combined transformations (visible to all players)
    local originalGrip = tool.Grip
    tool.Grip = originalGrip * fullOffset
    
    print("[EquipServer] Original grip:", originalGrip)
    print("[EquipServer] Original grip position:", originalGrip.Position)
    print("[EquipServer] Original grip X,Y,Z:", originalGrip.X, originalGrip.Y, originalGrip.Z)
    print("[EquipServer] New grip:", tool.Grip)
    print("[EquipServer] New grip position:", tool.Grip.Position)
    print("[EquipServer] New grip X,Y,Z:", tool.Grip.X, tool.Grip.Y, tool.Grip.Z)
    print("[EquipServer] Adjusted grip for:", tool.Name, "with equipped rotation - visible to all players")
    
    -- Mark this tool+skin combination as processed so we don't adjust it again
    tool:SetAttribute(gripKey, true)
end

local function watchToolForGripAdjustment(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    -- Apply grip adjustment with a small delay to ensure skin is loaded
    print("[EquipServer] Found new tool:", tool.Name, "SkinId:", tool:GetAttribute("SkinId") or "none")
    spawn(function()
        wait(0.5) -- Give time for SkinId to be applied
        print("[EquipServer] Processing tool after delay:", tool.Name, "SkinId:", tool:GetAttribute("SkinId") or "none")
        print("[EquipServer] About to call adjustWeaponGrip for:", tool.Name)
        local success, err = pcall(adjustWeaponGrip, tool)
        if not success then
            print("[EquipServer] ERROR in adjustWeaponGrip:", err)
        else
            print("[EquipServer] adjustWeaponGrip completed successfully for:", tool.Name)
        end
    end)
    
    -- Re-adjust grip when SkinId changes (but only if not already processed)
    local attributeConnection
    attributeConnection = tool.AttributeChanged:Connect(function(attribute)
        if attribute == "SkinId" then
            print("[EquipServer] SkinId changed to:", tool:GetAttribute("SkinId"))
            
            -- Clear all old grip adjustment attributes (to allow reprocessing)
            local attributesToClear = {}
            for attributeName, _ in pairs(tool:GetAttributes()) do
                if string.find(attributeName, "GripAdjusted_") then
                    table.insert(attributesToClear, attributeName)
                end
            end
            
            for _, attrName in ipairs(attributesToClear) do
                tool:SetAttribute(attrName, nil)
                print("[EquipServer] Cleared old grip attribute:", attrName)
            end
            
            -- Reset grip to original if we have it stored
            if tool:GetAttribute("OriginalGripStored") then
                local originalX = tool:GetAttribute("OriginalGripX") or 0
                local originalY = tool:GetAttribute("OriginalGripY") or 0
                local originalZ = tool:GetAttribute("OriginalGripZ") or 0
                tool.Grip = CFrame.new(originalX, originalY, originalZ)
                print("[EquipServer] Reset grip to original:", tool.Grip)
            end
            
            -- Now reprocess with new skin
            print("[EquipServer] SkinId changed, adjusting grip for:", tool.Name)
            wait(0.1) -- Small delay to ensure skin is fully applied
            adjustWeaponGrip(tool)
        end
    end)
    
    -- Clean up connections when tool is destroyed
    tool.AncestryChanged:Connect(function()
        if not tool.Parent then
            if attributeConnection then
                attributeConnection:Disconnect()
            end
        end
    end)
end

local function watchPlayerTools(player)
    local function watchContainer(container)
        if not container then return end
        
        -- Watch existing tools
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") then
                watchToolForGripAdjustment(child)
            end
        end
        
        -- Watch for new tools
        container.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                print("[EquipServer] New tool detected for", player.Name, ":", child.Name)
                watchToolForGripAdjustment(child)
            end
        end)
    end
    
    -- Watch character (equipped tools)
    if player.Character then
        watchContainer(player.Character)
    end
    
    -- Watch backpack (unequipped tools)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        watchContainer(backpack)
    end
    
    -- Watch for character respawns
    player.CharacterAdded:Connect(function(character)
        print("[EquipServer] Character respawned for", player.Name)
        watchContainer(character)
    end)
    
    -- Watch for backpack creation
    player.ChildAdded:Connect(function(child)
        if child.Name == "Backpack" then
            print("[EquipServer] Backpack created for", player.Name)
            watchContainer(child)
        end
    end)
end

-- Initialize for all current players
for _, player in ipairs(Players:GetPlayers()) do
    watchPlayerTools(player)
end

-- Watch for new players joining
Players.PlayerAdded:Connect(function(player)
    print("[EquipServer] Player joined:", player.Name)
    watchPlayerTools(player)
end)

print("[EquipServer] Server-side equipment handler initialized")
