-- EpicAura.luau: Epic rarity UI particle effects for inventory slots
-- Simple particle system using custom decals

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local EpicAura = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Simple particle spawner for custom decals
local function createRandomParticleEffect(container)
    -- Get random particle from ReplicatedStorage/Particles
    local particlesFolder = ReplicatedStorage:FindFirstChild("Particles")
    if not particlesFolder then
        warn("EpicAura: Particles folder not found!")
        return
    end
    
    -- Get all particle decals
    local particleDecals = {}
    for _, child in ipairs(particlesFolder:GetChildren()) do
        if child:IsA("Decal") then
            table.insert(particleDecals, child)
        end
    end
    
    if #particleDecals == 0 then
        warn("EpicAura: No particle decals found!")
        return
    end
    
    -- Choose random particle
    local randomParticle = particleDecals[math.random(1, #particleDecals)]
    
    -- Create ImageLabel for the particle
    local particle = Instance.new("ImageLabel")
    particle.Name = "EpicParticle_" .. randomParticle.Name
    particle.Image = randomParticle.Texture
    particle.BackgroundTransparency = 1
    particle.ImageTransparency = 1 -- Start invisible
    
    -- Random size - 50% BIGGER particles!
    local size = math.random(225, 330) -- 50% bigger particles (was 150-220)
    particle.Size = UDim2.fromOffset(size, size)
    
    -- Start from center for explosion effect
    particle.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center position
    particle.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- Same color for all particles (epic purple)
    particle.ImageColor3 = Color3.fromRGB(150, 100, 255) -- Consistent epic purple
    
    particle.ZIndex = 25 -- Above everything
    particle.Parent = container
    
    -- Explode outward - random direction from center
    local angle = math.random() * math.pi * 2 -- Random angle
    local distance = math.random(150, 300) -- Random explosion distance
    local endX = math.cos(angle) * distance
    local endY = math.sin(angle) * distance
    
    -- Fade in quickly for explosion
    local fadeIn = TweenService:Create(particle, 
        TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- Slower fade in
        {ImageTransparency = 0} -- Fully visible
    )
    
    -- Move randomly - 25% faster than before
    -- Explosion movement - slower outward burst
    local moveTime = math.random(8, 12) -- Slower explosion movement
    local moveTween = TweenService:Create(particle,
        TweenInfo.new(moveTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), -- Gentler easing
        {Position = UDim2.new(0.5, endX, 0.5, endY)} -- Explode outward from center
    )
    
    -- Fade out slower after explosion
    local fadeOut = TweenService:Create(particle,
        TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), -- Slower fade out
        {
            ImageTransparency = 1,
            Size = UDim2.fromOffset(size * 1.5, size * 1.5) -- Grow while fading for explosion effect
        }
    )
    
    -- Start explosion animations
    fadeIn:Play()
    moveTween:Play()
    
    -- Start fade out after movement starts
    fadeIn.Completed:Connect(function()
        task.wait(3) -- Wait longer before fading
        fadeOut:Play()
    end)
    
    fadeOut.Completed:Connect(function()
        particle:Destroy()
    end)
end

-- Get the EpicAura decal from ReplicatedStorage  
local function getAuraDecal()
    local decalsFolder = ReplicatedStorage:FindFirstChild("Decals")
    if decalsFolder then
        local auraDecal = decalsFolder:FindFirstChild("EpicAura")
        if auraDecal then
            print("EpicAura: Found EpicAura decal with texture:", auraDecal.Texture)
            return auraDecal.Texture
        else
            warn("EpicAura: EpicAura decal not found in Decals folder")
        end
    else
        warn("EpicAura: Decals folder not found in ReplicatedStorage")
    end
    
    -- Fallback texture
    return "rbxassetid://98886850679836"
end

local function createEpicAuraEffect(slot, gridView)
    print("EPICAURA DEBUG: Creating epic particle aura for slot:", slot.Name)
    print("EPICAURA DEBUG: Slot size:", slot.Size, "position:", slot.Position)
    print("EPICAURA DEBUG: GridView:", gridView and gridView.Name or "nil")
    
    -- Create aura frame same size as mythic/legendary
    local auraFrame = Instance.new("Frame")
    auraFrame.Name = "EpicAura_Frame_" .. slot.Name
    auraFrame.Size = UDim2.new(0, 252, 0, 289) -- Made 10% wider (229*1.10=252) and 10% taller (263*1.10=289)
    auraFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    auraFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    auraFrame.BackgroundTransparency = 1
    auraFrame.ZIndex = 15 -- Same as mythic/legendary
    auraFrame.Parent = slot
    
    -- Create epic aura decal
    local epicDecal = Instance.new("ImageLabel")
    epicDecal.Name = "EpicAuraDecal"
    epicDecal.Size = UDim2.new(1, 0, 1, 0) -- Fill the frame
    epicDecal.Position = UDim2.new(0, 0, 0, 0)
    epicDecal.BackgroundTransparency = 1
    epicDecal.Image = getAuraDecal() -- Get from ReplicatedStorage/Decals/EpicAura
    epicDecal.ImageTransparency = 0 -- Fully visible
    epicDecal.ZIndex = auraFrame.ZIndex + 1
    epicDecal.Parent = auraFrame
    
    -- Simple pulsing animation like mythic/legendary
    local pulseTween = TweenService:Create(
        epicDecal,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {ImageTransparency = 0.3} -- Pulse to slightly transparent
    )
    pulseTween:Play()
    
    -- Create EPIC particle effects with your custom decals - ONE AT A TIME!
    -- Create outer frame (no clipping) - 10% smaller than slot
    local outerParticleFrame = Instance.new("Frame")
    outerParticleFrame.Name = "OuterParticleFrame"
    outerParticleFrame.Size = UDim2.new(0.9, 0, 0.9, 0) -- 90% of slot size (10% smaller)
    outerParticleFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center it in the slot
    outerParticleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    outerParticleFrame.BackgroundTransparency = 1 -- No debug colors
    outerParticleFrame.ClipsDescendants = false -- No clipping on outer frame
    outerParticleFrame.ZIndex = auraFrame.ZIndex + 2
    outerParticleFrame.Parent = slot
    
    -- Create inner frame (with clipping) inside the outer frame
    local innerParticleFrame = Instance.new("Frame")
    innerParticleFrame.Name = "InnerParticleFrame"
    innerParticleFrame.Size = UDim2.new(1, 0, 1, 0) -- Full size of outer frame
    innerParticleFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center in outer frame
    innerParticleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    innerParticleFrame.BackgroundTransparency = 1 -- No debug colors
    innerParticleFrame.ClipsDescendants = true -- THIS CLIPS THE PARTICLES
    innerParticleFrame.ZIndex = outerParticleFrame.ZIndex + 1
    innerParticleFrame.Parent = outerParticleFrame -- Inside the outer frame
    
    task.spawn(function()
        while auraFrame.Parent do
            -- Wait for any existing particles to finish before spawning new one
            local existingParticles = {}
            for _, child in ipairs(innerParticleFrame:GetChildren()) do
                if child.Name:match("EpicParticle_") then
                    table.insert(existingParticles, child)
                end
            end
            
            -- Only spawn if no particles exist
            if #existingParticles == 0 then
                createRandomParticleEffect(innerParticleFrame) -- Put particles in the INNER clipped frame
            end
            
            task.wait(1) -- Check every second for existing particles
        end
    end)
    
    print("EPICAURA DEBUG: Created epic aura with advanced particle system")
    
    -- Cleanup function
    local function cleanup()
        print("EPICAURA DEBUG: Cleaning up epic aura and particles")
        if pulseTween then
            pulseTween:Cancel()
        end
        if auraFrame then 
            auraFrame:Destroy()
        end
    end
    
    return auraFrame, cleanup
end

function EpicAura.ApplyEpicAuraEffect(slot, gridView)
    if not slot then 
        return false, nil 
    end
    
    if not gridView then
        return false, nil
    end
    
    -- Remove any existing epic aura effects from this slot
    local existing = slot:FindFirstChild("EpicAura_Frame_" .. slot.Name)
    if existing then 
        existing:Destroy() 
    end
    
    print("EPICAURA DEBUG: Applying epic aura decal to slot:", slot.Name)
    return createEpicAuraEffect(slot, gridView)
end

-- Test function
function EpicAura.Test()
    return "EpicAura module loaded successfully!"
end

return EpicAura
