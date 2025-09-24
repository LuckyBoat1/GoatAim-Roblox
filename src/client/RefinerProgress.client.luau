-- ⚡ EPIC REFINER PROGRESS SYSTEM ⚡
-- 🚀 Spectacular holographic progress display with movie-level visual effects!

print("🔥 REFINER PROGRESS LOADING - STEP 1")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService") 
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

print("🔥 REFINER PROGRESS LOADING - STEP 2 - Services loaded")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
print("🔥 REFINER PROGRESS LOADING - STEP 3 - Player:", player.Name)

local RemoteEvents = RS:WaitForChild("RemoteEvents")
print("🔥 REFINER PROGRESS LOADING - STEP 4 - Found RemoteEvents folder")

local RefinerProgressRemote = RemoteEvents:WaitForChild("RefinerProgress")
print("🔥 REFINER PROGRESS LOADING - STEP 5 - Found RefinerProgress remote:", RefinerProgressRemote.Name)

print("✅ RefinerProgress client starting up...")

-- (Removed snapshot/prompt usage) HUD starts only from main RefinerProgress event

-- Prevent re-creating the HUD if we're already showing the same refiner/timing
local currentRefinerId: string? = nil
local currentDuration: number? = nil
local currentStartTime: number? = nil

-- Visual effect toggles
local ENABLE_MATRIX_SCAN = true
local ENABLE_CODE_RAIN = true
local ENABLE_PARTICLES = true

-- Create UI if not exists
local screenGui = playerGui:FindFirstChild("RefinerProgressUI")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RefinerProgressUI"
    screenGui.Parent = playerGui
end
-- Enforce properties every run to guarantee visibility
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10000 -- keep on top of most UI
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = true

-- 🚀 EPIC BAR CREATION FUNCTION - Now with MOVIE-LEVEL effects!
local function createBar(refinerName, duration, startTime)
    -- Skip if already showing the same cycle
    if currentRefinerId == refinerName and currentDuration == duration and currentStartTime and startTime and math.abs(currentStartTime - startTime) <= 1 then
        return
    end
    -- Clean up any existing progress bars
    local existingBars = screenGui:GetChildren()
    for _, child in ipairs(existingBars) do
        if child.Name:match("Progress_") then
            child:Destroy()
        end
    end

    print("🎬 Creating SPECTACULAR progress bar for", refinerName, "with", duration, "seconds duration!")
    
    -- Main holographic frame with vibrant blue theme
    local frame = Instance.new("Frame")
    frame.Name = "Progress_" .. refinerName
    frame.Size = UDim2.new(0, 420, 0, 110)
    -- Dock near top-right; start off-screen and slide in
    frame.AnchorPoint = Vector2.new(1, 0)
        frame.Position = UDim2.new(1, 500, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(10, 14, 24) -- deep dark bluish
    frame.BorderSizePixel = 3
    frame.BorderColor3 = Color3.fromRGB(0, 170, 255) -- neon blue border
    frame.ZIndex = 10
    frame.Visible = true
    frame.Parent = screenGui
    -- Round the main background card (keep background)
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 12)
    frameCorner.Parent = frame

    -- Slide-in animation from the right
    local slideIn = TweenService:Create(
        frame,
        TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Position = UDim2.new(1, -30, 0, 60) }
    )
    local settle = TweenService:Create(
        frame,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.new(1, -26, 0, 64) }
    )
    slideIn:Play()
    slideIn.Completed:Connect(function()
        settle:Play()
    end)

    -- Add holographic glow effect
    local glow = Instance.new("Frame")
    glow.Name = "GlowFrame"
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.new(0, -10, 0, -10)
    glow.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    glow.BackgroundTransparency = 0.7
    glow.BorderSizePixel = 0
    glow.ZIndex = frame.ZIndex - 1
    glow.Parent = frame
    -- Match glow rounding to card
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 12)
    glowCorner.Parent = glow

    -- Pulsing glow animation that never stops
    local glowPulse = TweenService:Create(
        glow,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.3}
    )
    glowPulse:Play()

    -- Title with holographic effect
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Refiner" -- No emoji
    titleLabel.TextColor3 = Color3.fromRGB(160, 210, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = frame.ZIndex + 5
    titleLabel.Parent = frame

    -- Progress bar background with holographic border
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, -20, 0, 18)
    progressBg.Position = UDim2.new(0, 10, 0, 42)
    progressBg.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
    progressBg.BorderSizePixel = 2
    progressBg.BorderColor3 = Color3.fromRGB(0, 170, 255)
    progressBg.ZIndex = frame.ZIndex + 1
    progressBg.Parent = frame
    -- Round progress background
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 8)
    bgCorner.Parent = progressBg

    -- Animated border that cycles through colors
    spawn(function()
        -- slow pulse between two green hues
        while progressBg.Parent do
            TweenService:Create(progressBg, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BorderColor3 = Color3.fromRGB(80, 180, 255)}):Play()
            task.wait(1.8)
            TweenService:Create(progressBg, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BorderColor3 = Color3.fromRGB(40, 130, 255)}):Play()
            task.wait(1.8)
        end
    end)

    -- The actual progress fill with epic gradient
    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(40, 140, 255)
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = frame.ZIndex + 2
    progressFill.Parent = progressBg
    -- Round fill to match
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 8)
    fillCorner.Parent = progressFill

    -- Add subtle gradient to the fill for a premium look
    local fillGradient = Instance.new("UIGradient")
    fillGradient.Color = ColorSequence.new(
        Color3.fromRGB(80, 200, 255),
        Color3.fromRGB(30, 120, 255)
    )
    fillGradient.Rotation = 0
    fillGradient.Parent = progressFill

    -- Add scan line effect that sweeps across constantly!
    local scanLine = Instance.new("Frame")
    scanLine.Size = UDim2.new(0, 4, 1, 0)
    scanLine.Position = UDim2.new(0, -10, 0, 0)
    scanLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    scanLine.BackgroundTransparency = 0.3
    scanLine.BorderSizePixel = 0
    scanLine.ZIndex = frame.ZIndex + 10
    scanLine.Parent = progressBg

    -- Continuous scan line animation
    local scanTween = TweenService:Create(
        scanLine,
        TweenInfo.new(2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
        {Position = UDim2.new(1, 10, 0, 0)}
    )
    scanTween:Play()

    -- MATRIX-LIKE FULL PANEL SCAN BAND
    if ENABLE_MATRIX_SCAN then
        local band = Instance.new("Frame")
        band.Name = "MatrixScanBand"
        band.Size = UDim2.new(1, 0, 0, 64)
        band.Position = UDim2.new(0, 0, -0.2, 0)
    band.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        band.BackgroundTransparency = 0.85
        band.BorderSizePixel = 0
        band.ZIndex = frame.ZIndex + 6
        band.Parent = frame
        local grad = Instance.new("UIGradient")
        grad.Rotation = 90
        grad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        })
        grad.Parent = band
        task.spawn(function()
            while band.Parent do
                band.Position = UDim2.new(0, 0, -0.3, 0)
                TweenService:Create(band, TweenInfo.new(2.2, Enum.EasingStyle.Linear), {Position = UDim2.new(0, 0, 1.3, 0)}):Play()
                task.wait(2.3)
            end
        end)
    end

    -- VERTICAL SCAN BEAM across the card (every ~5 seconds)
    if ENABLE_MATRIX_SCAN then
        local beam = Instance.new("Frame")
        beam.Name = "MatrixScanBeam"
        beam.Size = UDim2.new(0, 24, 1, 0)
        beam.Position = UDim2.new(-0.2, 0, 0, 0)
    beam.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        beam.BackgroundTransparency = 0.85
        beam.BorderSizePixel = 0
        beam.ZIndex = frame.ZIndex + 6
        beam.Parent = frame
        local beamCorner = Instance.new("UICorner")
        beamCorner.CornerRadius = UDim.new(0, 12)
        beamCorner.Parent = beam
        local grad = Instance.new("UIGradient")
        grad.Rotation = 0
        grad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        })
        grad.Parent = beam
        task.spawn(function()
            while beam.Parent do
                beam.Position = UDim2.new(-0.2, 0, 0, 0)
                TweenService:Create(beam, TweenInfo.new(5.0, Enum.EasingStyle.Linear), {Position = UDim2.new(1.2, 0, 0, 0)}):Play()
                task.wait(5.1)
            end
        end)
    end

    -- Progress percentage text with holographic glow
    local percentText = Instance.new("TextLabel")
    percentText.Size = UDim2.new(0, 80, 0, 20)
    percentText.Position = UDim2.new(1, -90, 0, 40)
    percentText.BackgroundTransparency = 1
    percentText.Text = "0%"
    percentText.TextColor3 = Color3.fromRGB(160, 210, 255)
    percentText.TextScaled = true
    percentText.Font = Enum.Font.GothamBold
    percentText.ZIndex = frame.ZIndex + 3
    percentText.Parent = frame

    -- Timer display with epic formatting
    local timerText = Instance.new("TextLabel")
    timerText.Size = UDim2.new(1, -20, 0, 22)
    timerText.Position = UDim2.new(0, 10, 0, 68)
    timerText.BackgroundTransparency = 1
    timerText.Text = "Starting..."
    timerText.TextColor3 = Color3.fromRGB(180, 230, 255)
    timerText.TextScaled = true
    timerText.Font = Enum.Font.Gotham
    timerText.ZIndex = frame.ZIndex + 3
    timerText.Parent = frame

    -- Add animated padding that grows and shrinks
    local animatedPadding = Instance.new("Frame")
    animatedPadding.Size = UDim2.new(1, 0, 1, 0)
    animatedPadding.Position = UDim2.new(0, 0, 0, 0)
    animatedPadding.BackgroundTransparency = 1
    animatedPadding.BorderSizePixel = 2
    animatedPadding.BorderColor3 = Color3.fromRGB(255, 255, 255)
    animatedPadding.ZIndex = frame.ZIndex + 8
    animatedPadding.Parent = frame
    -- Round animated padding border
    local paddingCorner = Instance.new("UICorner")
    paddingCorner.CornerRadius = UDim.new(0, 12)
    paddingCorner.Parent = animatedPadding

    -- Animated padding effect that pulses
    local paddingTween = TweenService:Create(
        animatedPadding,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {
            Size = UDim2.new(1, 10, 1, 10),
            Position = UDim2.new(0, -5, 0, -5)
        }
    )
    paddingTween:Play()

    -- CODE RAIN (lightweight) over the card
    if ENABLE_CODE_RAIN then
        local rain = Instance.new("Frame")
        rain.Name = "CodeRain"
        rain.Size = UDim2.new(1, -20, 1, -20)
        rain.Position = UDim2.new(0, 10, 0, 10)
        rain.BackgroundTransparency = 1
        rain.ClipsDescendants = true
        rain.ZIndex = frame.ZIndex + 5
        rain.Parent = frame

    local columns = 24
    local maxGlyphs = 120
        task.spawn(function()
            while rain.Parent do
                if #rain:GetChildren() > maxGlyphs then
                    -- trim oldest
                    for i = 1, #rain:GetChildren() - maxGlyphs do
                        local ch = rain:GetChildren()[i]
                        if ch then ch:Destroy() end
                    end
                end
                local col = math.random(0, columns - 1)
                local x = col / columns
                local glyph = Instance.new("TextLabel")
                glyph.BackgroundTransparency = 1
                glyph.Size = UDim2.new(0, 12, 0, 14)
                glyph.Position = UDim2.new(x, 0, 0, -16)
                glyph.Font = Enum.Font.Code
                local char = (math.random() < 0.5) and string.char(48 + math.random(0,1)) or string.char(65 + math.random(0,25))
                glyph.Text = char
                glyph.TextSize = 12
                glyph.TextColor3 = Color3.fromRGB(80, 200, 255)
                glyph.TextTransparency = 0.2
                glyph.ZIndex = rain.ZIndex
                glyph.Parent = rain
                local fallTime = 1.6 + math.random() * 0.8
                TweenService:Create(glyph, TweenInfo.new(fallTime, Enum.EasingStyle.Linear), {Position = UDim2.new(x, 0, 1.05, 0)}):Play()
                TweenService:Create(glyph, TweenInfo.new(fallTime, Enum.EasingStyle.Sine), {TextTransparency = 1}):Play()
                task.delay(fallTime + 0.2, function()
                    if glyph then glyph:Destroy() end
                end)
                task.wait(0.05)
            end
        end)
    end

    -- PARTICLE EFFECTS near progress bar (denser + second layer)
    if ENABLE_PARTICLES then
        -- Fast sparks layer
        local sparkContainer = Instance.new("Frame")
        sparkContainer.Name = "Sparks"
        sparkContainer.Size = UDim2.new(1, -20, 0, 24)
        sparkContainer.Position = UDim2.new(0, 10, 0, 34)
        sparkContainer.BackgroundTransparency = 1
        sparkContainer.ClipsDescendants = true
        sparkContainer.ZIndex = frame.ZIndex + 7
        sparkContainer.Parent = frame

        -- Slow embers layer
        local emberContainer = Instance.new("Frame")
        emberContainer.Name = "Embers"
        emberContainer.Size = UDim2.new(1, -20, 0, 26)
        emberContainer.Position = UDim2.new(0, 10, 0, 32)
        emberContainer.BackgroundTransparency = 1
        emberContainer.ClipsDescendants = true
        emberContainer.ZIndex = frame.ZIndex + 6
        emberContainer.Parent = frame

        local maxSparks = 80
        local maxEmbers = 24
        task.spawn(function()
            while sparkContainer.Parent do
                if #sparkContainer:GetChildren() > maxSparks then
                    sparkContainer:GetChildren()[1]:Destroy()
                end
                local sizePx = math.random(3, 6)
                local s = Instance.new("Frame")
                s.Size = UDim2.fromOffset(sizePx, sizePx)
                s.Position = UDim2.new(math.random(), -2, math.random(), -2)
                s.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
                s.BackgroundTransparency = 0.1 + math.random() * 0.2
                s.BorderSizePixel = 0
                s.ZIndex = sparkContainer.ZIndex
                s.Parent = sparkContainer
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(1, 0)
                corner.Parent = s
                local life = 0.45 + math.random() * 0.35
                local driftX = 0.18 + math.random() * 0.08
                local driftY = -0.06 - math.random() * 0.05
                local target = UDim2.new(s.Position.X.Scale + driftX, 0, s.Position.Y.Scale + driftY, 0)
                TweenService:Create(s, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = target, BackgroundTransparency = 1}):Play()
                task.delay(life + 0.05, function()
                    if s then s:Destroy() end
                end)
                task.wait(0.06)
            end
        end)

        task.spawn(function()
            while emberContainer.Parent do
                if #emberContainer:GetChildren() > maxEmbers then
                    emberContainer:GetChildren()[1]:Destroy()
                end
                local w = math.random(6, 10)
                local e = Instance.new("Frame")
                e.Size = UDim2.fromOffset(w, w)
                e.Position = UDim2.new(math.random(), -3, 1, -3)
                e.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
                e.BackgroundTransparency = 0.7
                e.BorderSizePixel = 0
                e.ZIndex = emberContainer.ZIndex
                e.Parent = emberContainer
                local cr = Instance.new("UICorner")
                cr.CornerRadius = UDim.new(1, 0)
                cr.Parent = e
                local life = 1.2 + math.random() * 0.8
                local driftX = -0.12 + (math.random() * 0.24)
                local target = UDim2.new(e.Position.X.Scale + driftX, 0, -0.2, 0)
                TweenService:Create(e, TweenInfo.new(life, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = target, BackgroundTransparency = 1}):Play()
                task.delay(life + 0.05, function()
                    if e then e:Destroy() end
                end)
                task.wait(0.22)
            end
        end)

        -- Soft orbs layer (large, translucent circles drifting subtly)
        local orbs = Instance.new("Frame")
        orbs.Name = "Orbs"
        orbs.Size = UDim2.new(1, -24, 1, -24)
        orbs.Position = UDim2.new(0, 12, 0, 12)
        orbs.BackgroundTransparency = 1
        orbs.ClipsDescendants = true
        orbs.ZIndex = frame.ZIndex + 5
        orbs.Parent = frame
        local maxOrbs = 16
        task.spawn(function()
            while orbs.Parent do
                if #orbs:GetChildren() > maxOrbs then
                    orbs:GetChildren()[1]:Destroy()
                end
                local d = math.random(10, 22)
                local o = Instance.new("Frame")
                o.Size = UDim2.fromOffset(d, d)
                o.Position = UDim2.new(math.random(), -d/2, math.random(), -d/2)
                o.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
                o.BackgroundTransparency = 0.9
                o.BorderSizePixel = 0
                o.ZIndex = orbs.ZIndex
                o.Parent = orbs
                local oc = Instance.new("UICorner")
                oc.CornerRadius = UDim.new(1, 0)
                oc.Parent = o
                local life = 1.4 + math.random() * 0.8
                local dx = (-0.08 + math.random() * 0.16)
                local dy = (-0.04 + math.random() * 0.08)
                local tgt = UDim2.new(o.Position.X.Scale + dx, o.Position.X.Offset, o.Position.Y.Scale + dy, o.Position.Y.Offset)
                TweenService:Create(o, TweenInfo.new(life, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = tgt, BackgroundTransparency = 1}):Play()
                task.delay(life + 0.05, function()
                    if o then o:Destroy() end
                end)
                task.wait(0.12)
            end
        end)
    end

    print("🚀 EPIC visual effects initialized! Starting countdown system...")

    -- Variables for countdown (use os.time to match server)
    local realStartTime = startTime or os.time()
    currentRefinerId = refinerName
    currentDuration = duration
    currentStartTime = realStartTime
    local targetEndTime = realStartTime + duration
    local isActive = true

    -- Epic countdown loop using tick() for accuracy
    local updateConnection
    updateConnection = RunService.Heartbeat:Connect(function()
        if not isActive or not frame.Parent then
            updateConnection:Disconnect()
            return
        end

    -- Use os.time so math aligns with server-provided startTime
    local currentTime = os.time()
        local elapsed = currentTime - realStartTime
        local remaining = math.max(0, targetEndTime - currentTime)
        local progress = math.min(1, elapsed / duration)

        -- Update progress bar with smooth animation
        local targetSize = UDim2.new(progress, 0, 1, 0)
        if progressFill.Size.X.Scale ~= progress then
            local fillTween = TweenService:Create(
                progressFill,
                TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = targetSize}
            )
            fillTween:Play()
        end

        -- Update percentage display
        local displayPercent = math.floor(progress * 100)
        percentText.Text = displayPercent .. "%"

        -- Update timer display with epic formatting (HH:MM:SS when needed)
        if remaining > 0 then
            local hours = math.floor(remaining / 3600)
            local minutes = math.floor((remaining % 3600) / 60)
            local seconds = remaining % 60
            if hours > 0 then
                timerText.Text = string.format("%02d:%02d:%02d remaining", hours, minutes, seconds)
            else
                timerText.Text = string.format("%02d:%02d remaining", minutes, seconds)
            end
            
            -- Color changes based on time remaining
            if remaining < 10 then
                timerText.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red for urgency
            elseif remaining < 30 then
                timerText.TextColor3 = Color3.fromRGB(255, 200, 100) -- Orange
            else
                timerText.TextColor3 = Color3.fromRGB(160, 210, 255) -- Blue calm
            end
        else
            timerText.Text = "COMPLETED!"
            timerText.TextColor3 = Color3.fromRGB(100, 200, 255)
        end

        -- Complete when timer reaches 0
        if remaining <= 0 and isActive then
            isActive = false
            progressFill.Size = UDim2.new(1, 0, 1, 0)
            percentText.Text = "100%"
            
            print("🎉 Refiner", refinerName, "completed! Starting epic completion sequence!")
            
            -- Epic completion effects
            local completionTween = TweenService:Create(
                frame,
                TweenInfo.new(0.8, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 470, 0, 130)}
            )
            completionTween:Play()

            -- Flash effect
            local flashFrame = Instance.new("Frame")
            flashFrame.Size = UDim2.new(1, 0, 1, 0)
            flashFrame.Position = UDim2.new(0, 0, 0, 0)
            flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            flashFrame.BackgroundTransparency = 0.7
            flashFrame.BorderSizePixel = 0
            flashFrame.ZIndex = frame.ZIndex + 50
            flashFrame.Parent = frame

            local flashTween = TweenService:Create(
                flashFrame,
                TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            )
            flashTween:Play()

            -- Wait 3 seconds then start epic fade out
            wait(3)
            
            local fadeOut = TweenService:Create(
                frame,
                TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 500, 0, 150),
                    Position = UDim2.new(0, -5, 0, 5)
                }
            )
            fadeOut:Play()

            -- Fade all children
            spawn(function()
                for _, child in ipairs(frame:GetChildren()) do
                    if child:IsA("TextLabel") then
                        local childFade = TweenService:Create(
                            child,
                            TweenInfo.new(1.2),
                            {TextTransparency = 1}
                        )
                        childFade:Play()
                    elseif child:IsA("Frame") then
                        local childFade = TweenService:Create(
                            child,
                            TweenInfo.new(1.2),
                            {BackgroundTransparency = 1, TextTransparency = 1}
                        )
                        childFade:Play()
                    end
                end
            end)

            fadeOut.Completed:Wait()
            frame:Destroy()
            print("🗑️ Epic cleanup completed for", refinerName)
        end
    end)
end

-- Listen for refiner progress events
RefinerProgressRemote.OnClientEvent:Connect(function(data)
    print("📦 RECEIVED RefinerProgress event:", data)
    
    if not data then 
        warn("❌ RefinerProgress: No data received!")
        return 
    end

    -- Be flexible with server payload keys
    local refinerId = data.refiner or data.id
    local duration = data.duration or data.interval
    local startTime = data.startTime
    if (not startTime) and data.timeAccum and duration then
        local ta = tonumber(data.timeAccum) or 0
        startTime = os.time() - math.floor(ta)
    end

    if not refinerId then
        warn("❌ RefinerProgress: No refiner id in data:", data)
        return
    end
    if not duration then
        warn("❌ RefinerProgress: No duration/interval in data:", data)
        return
    end

    print("🚀 Starting progress bar for refiner:", refinerId, "Duration:", duration, "seconds")
    createBar(refinerId, duration, startTime or os.time())
end)

print("✅ RefinerProgress client loaded successfully and listening for events!")
print("🎯 RefinerProgress remote connection established:", RefinerProgressRemote.Name)