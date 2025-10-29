-- MythicAura Module - Creates red aura effects over mythic weapon slots

local MythicAura = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the Aura decal from ReplicatedStorage
local function getAuraDecal()
    local decalsFolder = ReplicatedStorage:FindFirstChild("Decals")
    if decalsFolder then
        local auraDecal = decalsFolder:FindFirstChild("Aura")
        if auraDecal then
            return auraDecal.Texture
        else
            warn("MythicAura: Aura decal not found in Decals folder")
        end
    else
        warn("MythicAura: Decals folder not found in ReplicatedStorage")
    end
    
    -- Fallback texture
    return "rbxassetid://98886850679836"
end

-- Apply mythic aura effect to a frame (slot) but parent to gridView container
function MythicAura.ApplyMythicAuraEffect(frame, gridView)
    if not frame then 
        warn("MythicAura: No frame provided")
        return false, nil 
    end
    
    if not gridView then
        warn("MythicAura: No gridView container provided")
        return false, nil
    end
    
    -- Remove any existing aura effects from gridView (not frame)
    local existing = gridView:FindFirstChild("MythicAura_ClipFrame_" .. frame.Name)
    if existing then 
        existing:Destroy() 
    end
    
    -- Create clipping frame positioned over the slot but parented to slot frame
    local clippingFrame = Instance.new("Frame")
    clippingFrame.Name = "MythicAura_ClipFrame_" .. frame.Name
    clippingFrame.Size = UDim2.new(0, 325, 0, 337) -- Made 20% wider and taller (271*1.20=325, 281*1.20=337)
    clippingFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center in slot
    clippingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    clippingFrame.BackgroundTransparency = 1
    clippingFrame.ZIndex = 20 -- Higher ZIndex to ensure visibility
    
    -- Add UICorner to make it circular
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = clippingFrame
    
    clippingFrame.Parent = frame -- Parent to slot frame instead of gridView
    
    -- Create aura ImageLabel - simple and guaranteed to be visible
    local aura = Instance.new("ImageLabel")
    aura.Name = "MythicAura_" .. frame.Name
    aura.Image = getAuraDecal()
    aura.Size = UDim2.new(1, 0, 1, 0) -- Fill the clipping frame
    aura.Position = UDim2.new(0, 0, 0, 0) -- Top-left corner of clipping frame
    aura.AnchorPoint = Vector2.new(0, 0)
    aura.BackgroundTransparency = 1
    aura.ImageColor3 = Color3.fromRGB(255, 30, 60) -- Same color as mythic effects
    aura.ImageTransparency = 0 -- Always fully visible (no transparency)
    aura.ZIndex = 15 -- Above everything else
    aura.BorderSizePixel = 0
    
    aura.Parent = clippingFrame -- Parent to clipping frame instead of gridView
    
    -- Super fast flashing animation - faster than lightning
    local animationRunning = true
    task.spawn(function()
        while animationRunning do
            -- 1 second flash sequence
            aura.ImageTransparency = 0 -- Fully visible instantly
            task.wait(0.4) -- Longer initial flash (0.4s)
            
            aura.ImageTransparency = 0.7 -- Dim quickly
            task.wait(0.2) -- Longer dim pause (0.2s)
            
            aura.ImageTransparency = 0 -- Flash again
            task.wait(0.4) -- Longer second flash (0.4s) - Total: 1.0s
            
            -- No fade - instant disappear
            aura.ImageTransparency = 1 -- Instantly invisible
            
            -- Almost instant return - very short pause
            task.wait(0.05) -- Almost instant return
        end
    end)
    
    -- Cleanup function
    local function cleanup()
        animationRunning = false -- Stop the animation
        
        if aura and aura.Parent then
            -- Fade out before destroying
            task.spawn(function()
                for transparency = aura.ImageTransparency, 1, 0.1 do
                    if aura and aura.Parent then
                        aura.ImageTransparency = transparency
                        task.wait(0.02)
                    end
                end
                if aura and aura.Parent then
                    aura:Destroy()
                end
            end)
        end
        
        if clippingFrame and clippingFrame.Parent then
            clippingFrame:Destroy()
        end
    end
    
    return true, cleanup
end

-- Test function for debugging
function MythicAura.Test()
    return "MythicAura module is working!"
end

return MythicAura
