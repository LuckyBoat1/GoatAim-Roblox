-- LegendaryAura Module - Creates yellow aura effects over legendary weapon slots

local LegendaryAura = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Get the Glow decal from Fire folder
local function getGlowDecal()
    local fireFolder = ReplicatedStorage:FindFirstChild("Fire")
    if fireFolder then
        local glowDecal = fireFolder:FindFirstChild("Glow")
        if glowDecal and glowDecal.Texture then
            return glowDecal.Texture
        end
    end
    return "rbxassetid://241650934" -- Fallback glow texture
end

-- Create pulsing sun-like glow effect behind legendary weapons
local function createPulsingSunGlow(container)
    -- Find the actual slot frame
    local slotFrame = container.Parent.Parent -- container -> fireFrame -> clippingFrame -> slotFrame
    
    -- Get the glow texture
    local glowTexture = getGlowDecal()
    
    -- Create main sun glow (large, behind everything)
    local sunGlow = Instance.new("ImageLabel")
    sunGlow.Name = "LegendarySunGlow_" .. tick()
    sunGlow.Image = glowTexture
    sunGlow.BackgroundTransparency = 1
    sunGlow.BorderSizePixel = 0
    
    -- Make it much larger for sun effect (10% wider and higher)
    sunGlow.Size = UDim2.new(2.75, 0, 2.75, 0) -- 175% larger than slot (was 2.5)
    sunGlow.Position = UDim2.new(0.5, 0, 0.4, 0) -- 10% lower (was 0.3)
    sunGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- Bright golden sun color
    sunGlow.ImageColor3 = Color3.fromRGB(255, 220, 0) -- Bright golden yellow
    sunGlow.ImageTransparency = 0.3 -- Start moderately visible
    sunGlow.ZIndex = -2 -- Way behind everything
    
    sunGlow.Parent = slotFrame
    
    -- Create inner core glow (more intense center)
    local coreGlow = Instance.new("ImageLabel")
    coreGlow.Name = "LegendaryCoreGlow_" .. tick()
    coreGlow.Image = glowTexture
    coreGlow.BackgroundTransparency = 1
    coreGlow.BorderSizePixel = 0
    
    -- Smaller but very bright core (10% wider and higher)
    coreGlow.Size = UDim2.new(1.98, 0, 1.98, 0) -- 98% larger than slot (was 1.8)
    coreGlow.Position = UDim2.new(0.5, 0, 0.4, 0) -- 10% lower (was 0.3)
    coreGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- Very bright center
    coreGlow.ImageColor3 = Color3.fromRGB(255, 255, 150) -- Bright white-yellow
    coreGlow.ImageTransparency = 0.3 -- Start moderately visible (same as outer)
    coreGlow.ZIndex = -1 -- Behind weapon, above sun glow
    
    coreGlow.Parent = slotFrame
    
    -- Create pulsing sun animation
    local sunPulseTween = TweenService:Create(
        sunGlow,
        TweenInfo.new(
            2.5, -- Slow 2.5 second pulse like a sun
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut,
            -1, -- Repeat forever
            true, -- Reverse
            0 -- No delay
        ),
        {
            ImageTransparency = 0.4, -- Fades FROM 0.3 TO 0.4 (gets more transparent)
            Size = UDim2.new(3.3, 0, 3.3, 0), -- Grows FROM 2.75 TO 3.3 (expands like sun rays)
            ImageColor3 = Color3.fromRGB(255, 180, 0) -- Fades FROM bright yellow TO deeper gold
        }
    )
    
    -- Create core glow animation (faster, more intense)
    local corePulseTween = TweenService:Create(
        coreGlow,
        TweenInfo.new(
            1.8, -- Faster pulse
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut,
            -1, -- Repeat forever
            true, -- Reverse
            0.8 -- Offset timing
        ),
        {
            ImageTransparency = 0.4, -- Fades FROM 0.3 TO 0.4 (same as outer glow)
            Size = UDim2.new(2.42, 0, 2.42, 0), -- Grows FROM 1.98 TO 2.42 (expands)
            ImageColor3 = Color3.fromRGB(255, 255, 255) -- Fades FROM white-yellow TO pure white
        }
    )
    
    -- Start the sun pulsing animations
    sunPulseTween:Play()
    corePulseTween:Play()
    
    -- Return cleanup function
    return function()
        sunPulseTween:Cancel()
        corePulseTween:Cancel()
        if sunGlow and sunGlow.Parent then
            sunGlow:Destroy()
        end
        if coreGlow and coreGlow.Parent then
            coreGlow:Destroy()
        end
    end
end

-- Get the LegendaryAura decal from ReplicatedStorage
local function getAuraDecal()
    local decalsFolder = ReplicatedStorage:FindFirstChild("Decals")
    if decalsFolder then
        local auraDecal = decalsFolder:FindFirstChild("LegendaryAura")
        if auraDecal then
            return auraDecal.Texture
        end
    end
    
    -- Fallback texture
    return "rbxassetid://98886850679836"
end

-- Apply legendary aura effect to a frame (slot) but parent to gridView container
function LegendaryAura.ApplyLegendaryAuraEffect(frame, gridView)
    if not frame then 
        return false, nil 
    end
    
    if not gridView then
        return false, nil
    end
    
    -- Remove any existing aura effects from gridView (not frame)
    local existing = gridView:FindFirstChild("LegendaryAura_ClipFrame_" .. frame.Name)
    if existing then 
        existing:Destroy() 
    end
    
    -- Create clipping frame positioned over the slot but parented to slot frame
    local clippingFrame = Instance.new("Frame")
    clippingFrame.Name = "LegendaryAura_ClipFrame_" .. frame.Name
    clippingFrame.Size = UDim2.new(0, 265, 0, 281) -- Made 5% wider (252*1.05=265) and 10% taller (255*1.10=281)
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
    aura.Name = "LegendaryAura_" .. frame.Name
    aura.Image = getAuraDecal()
    aura.Size = UDim2.new(1, 0, 1, 0) -- Fill the clipping frame
    aura.Position = UDim2.new(0, 0, 0, 0) -- Top-left corner of clipping frame
    aura.AnchorPoint = Vector2.new(0, 0)
    aura.BackgroundTransparency = 1
    aura.ImageColor3 = Color3.fromRGB(255, 220, 0) -- Yellow color for legendary aura decal
    aura.ImageTransparency = 0 -- Always fully visible (no transparency)
    aura.ZIndex = 15 -- Above everything else
    aura.BorderSizePixel = 0
    
    aura.Parent = clippingFrame -- Parent to clipping frame instead of gridView
    
    -- Create fire frame (ready for future fire effects if needed)
    local fireFrame = Instance.new("Frame")
    fireFrame.Name = "LegendaryFireFrame"
    fireFrame.Size = UDim2.new(1, 0, 1, 0) -- Full size of aura frame
    fireFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    fireFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fireFrame.BackgroundTransparency = 1
    fireFrame.ClipsDescendants = true
    fireFrame.ZIndex = aura.ZIndex + 1 -- Above the aura
    fireFrame.Parent = clippingFrame
    
    -- Create pulsing sun glow effect behind the weapon
    local sunGlowCleanup = createPulsingSunGlow(fireFrame)
    
    -- Store cleanup function for later
    if sunGlowCleanup then
        fireFrame:SetAttribute("SunGlowCleanup", true)
    end
    
    -- Always visible aura - no flashing animation
    local animationRunning = true
    task.spawn(function()
        while animationRunning do
            -- Keep aura always visible - no transparency changes
            aura.ImageTransparency = 0 -- Always fully visible
            task.wait(0.1) -- Small wait to prevent infinite loop
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
function LegendaryAura.Test()
    return "LegendaryAura module is working!"
end

return LegendaryAura
