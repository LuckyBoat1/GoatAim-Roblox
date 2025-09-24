-- Rotation Adjuster UI - FOR TESTING ONLY
-- Similar to GripAdjuster but for testing rotations

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local _TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentTool = nil
local rotationAdjusterGui = nil
local serverBaselineGrip = nil

-- Default rotation values (in degrees for easier editing)
local rotationX = 0
local rotationY = 0
local rotationZ = 0

local function createRotationUI()
    -- Create ScreenGui
    rotationAdjusterGui = Instance.new("ScreenGui")
    rotationAdjusterGui.Name = "RotationAdjuster"
    rotationAdjusterGui.Parent = playerGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 420, 0, 220) -- Made wider and taller for sliders
    mainFrame.Position = UDim2.new(1, -440, 0.7, -110) -- Moved lower on screen
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
    mainFrame.Parent = rotationAdjusterGui
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    titleLabel.BorderSizePixel = 0
    titleLabel.Text = "🔄 Rotation Adjuster (TESTING)"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = mainFrame
    
    -- Declare textbox and control variables
    local xTextBox, yTextBox, zTextBox
    local xResetBtn, yResetBtn, zResetBtn
    local xUpdateSlider, yUpdateSlider, zUpdateSlider
    
    -- Update rotation function (declared early so sliders can use it)
    local function updateRotation()
        if not currentTool then return end
        
        -- Get current rotation values
        rotationX = tonumber(xTextBox.Text) or 0
        rotationY = tonumber(yTextBox.Text) or 0
        rotationZ = tonumber(zTextBox.Text) or 0
        
        -- Use the server's FINAL processed grip as baseline (after server positioning/rotation)
        -- This is what the user sees and wants to adjust from
        if not serverBaselineGrip then
            serverBaselineGrip = currentTool.Grip
            print("[RotationAdjuster] Using server's final processed grip as baseline:", serverBaselineGrip)
        end
        
        -- Simulate the EXACT server logic to preview what the rotation would look like
        -- Server does: tool.Grip = originalGrip * (weaponRotation * gripAdjustment * heightOffset)
        
        -- We now use the server's final processed grip as the baseline
        
        -- Create test rotation exactly like server: CFrame.Angles(math.rad(X), math.rad(Y), math.rad(Z))
        -- BUT: Check if we need axis remapping due to coordinate system differences
        local testRotation = CFrame.Angles(math.rad(rotationX), math.rad(rotationY), math.rad(rotationZ))
        
        -- Debug: Show what we're testing
        print("[RotationAdjuster] Testing rotation: X=" .. rotationX .. "°, Y=" .. rotationY .. "°, Z=" .. rotationZ .. "°")
        print("[RotationAdjuster] CFrame.Angles(math.rad(" .. rotationX .. "), math.rad(" .. rotationY .. "), math.rad(" .. rotationZ .. "))")
        print("[RotationAdjuster] Server baseline grip:", serverBaselineGrip)
        print("[RotationAdjuster] Test rotation CFrame:", testRotation)
        
        -- Apply rotation to server's final result (this gives the correct axis reference)
        currentTool.Grip = serverBaselineGrip * testRotation
        
        print("[RotationAdjuster] Final grip:", currentTool.Grip)
        print("[RotationAdjuster] This should match server with the same CFrame.Angles values")
        
        print("[RotationAdjuster] Applied rotation: X=" .. rotationX .. "°, Y=" .. rotationY .. "°, Z=" .. rotationZ .. "°")
        print("[RotationAdjuster] New grip:", currentTool.Grip)
    end
    
    -- Function to create rotation slider with actual slider
    local function createRotationSlider(name, axis, yPos, minVal, maxVal, defaultVal)
        local label = Instance.new("TextLabel")
        label.Name = name .. "Label"
        label.Size = UDim2.new(0, 60, 0, 25)
        label.Position = UDim2.new(0, 10, 0, yPos)
        label.BackgroundTransparency = 1
        label.Text = axis .. ":"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.Font = Enum.Font.SourceSans
        label.Parent = mainFrame
        
        -- Slider Track
        local sliderTrack = Instance.new("Frame")
        sliderTrack.Name = name .. "Track"
        sliderTrack.Size = UDim2.new(0, 150, 0, 8)
        sliderTrack.Position = UDim2.new(0, 75, 0, yPos + 8)
        sliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        sliderTrack.BorderSizePixel = 1
        sliderTrack.BorderColor3 = Color3.fromRGB(120, 120, 120)
        sliderTrack.Parent = mainFrame
        
        -- Slider Button
        local sliderButton = Instance.new("Frame")
        sliderButton.Name = name .. "Button"
        sliderButton.Size = UDim2.new(0, 12, 0, 16)
        sliderButton.Position = UDim2.new(defaultVal / maxVal, -6, 0, -4) -- Center on track
        sliderButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        sliderButton.BorderSizePixel = 1
        sliderButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
        sliderButton.Parent = sliderTrack
        
        local textBox = Instance.new("TextBox")
        textBox.Name = name .. "TextBox"
        textBox.Size = UDim2.new(0, 60, 0, 25)
        textBox.Position = UDim2.new(0, 235, 0, yPos)
        textBox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        textBox.BorderSizePixel = 1
        textBox.BorderColor3 = Color3.fromRGB(120, 120, 120)
        textBox.Text = tostring(defaultVal)
        textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        textBox.TextScaled = true
        textBox.Font = Enum.Font.SourceSans
        textBox.Parent = mainFrame
        
        local resetBtn = Instance.new("TextButton")
        resetBtn.Name = name .. "Reset"
        resetBtn.Size = UDim2.new(0, 50, 0, 25)
        resetBtn.Position = UDim2.new(0, 305, 0, yPos)
        resetBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        resetBtn.BorderSizePixel = 1
        resetBtn.Text = "0°"
        resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        resetBtn.TextScaled = true
        resetBtn.Font = Enum.Font.SourceSans
        resetBtn.Parent = mainFrame
        
        -- Slider functionality with auto-update
        local dragging = false
        local function updateSlider(input)
            local relativePos = (input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
            relativePos = math.clamp(relativePos, 0, 1)
            
            sliderButton.Position = UDim2.new(relativePos, -6, 0, -4)
            
            local value = math.floor(relativePos * maxVal)
            textBox.Text = tostring(value)
            
            -- Auto-update rotation when slider moves
            updateRotation()
        end
        
        local function updateSliderFromText()
            local value = tonumber(textBox.Text) or 0
            value = math.clamp(value, minVal, maxVal)
            textBox.Text = tostring(value)
            
            local relativePos = value / maxVal
            sliderButton.Position = UDim2.new(relativePos, -6, 0, -4)
            
            -- Auto-update rotation when text changes
            updateRotation()
        end
        
        -- Slider events
        sliderTrack.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                updateSlider(input)
            end
        end)
        
        sliderTrack.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input)
            end
        end)
        
        sliderTrack.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        -- Text box sync with slider
        textBox.FocusLost:Connect(updateSliderFromText)
        
        return textBox, resetBtn, updateSliderFromText
    end
    
    -- Create rotation sliders
    xTextBox, xResetBtn, xUpdateSlider = createRotationSlider("RotX", "X", 40, 0, 360, rotationX)
    yTextBox, yResetBtn, yUpdateSlider = createRotationSlider("RotY", "Y", 70, 0, 360, rotationY)
    zTextBox, zResetBtn, zUpdateSlider = createRotationSlider("RotZ", "Z", 100, 0, 360, rotationZ)
    
    -- Apply All button
    local applyAllBtn = Instance.new("TextButton")
    applyAllBtn.Name = "ApplyAll"
    applyAllBtn.Size = UDim2.new(0, 100, 0, 30)
    applyAllBtn.Position = UDim2.new(0, 10, 0, 180)
    applyAllBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    applyAllBtn.BorderSizePixel = 1
    applyAllBtn.Text = "🔄 Apply All"
    applyAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyAllBtn.TextScaled = true
    applyAllBtn.Font = Enum.Font.SourceSansBold
    applyAllBtn.Parent = mainFrame
    
    -- Reset All button
    local resetAllBtn = Instance.new("TextButton")
    resetAllBtn.Name = "ResetAll"
    resetAllBtn.Size = UDim2.new(0, 100, 0, 30)
    resetAllBtn.Position = UDim2.new(0, 120, 0, 180)
    resetAllBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    resetAllBtn.BorderSizePixel = 1
    resetAllBtn.Text = "🔄 Reset All"
    resetAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetAllBtn.TextScaled = true
    resetAllBtn.Font = Enum.Font.SourceSansBold
    resetAllBtn.Parent = mainFrame
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 100, 0, 30)
    closeBtn.Position = UDim2.new(0, 300, 0, 180)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    closeBtn.BorderSizePixel = 1
    closeBtn.Text = "❌ Close"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.Parent = mainFrame
    
    -- Apply all button (for convenience)
    applyAllBtn.MouseButton1Click:Connect(updateRotation)
    
    -- Individual reset buttons
    xResetBtn.MouseButton1Click:Connect(function()
        xTextBox.Text = "0"
        xUpdateSlider()
        updateRotation()
    end)
    
    yResetBtn.MouseButton1Click:Connect(function()
        yTextBox.Text = "0"
        yUpdateSlider()
        updateRotation()
    end)
    
    zResetBtn.MouseButton1Click:Connect(function()
        zTextBox.Text = "0"
        zUpdateSlider()
        updateRotation()
    end)
    
    -- Reset all button
    resetAllBtn.MouseButton1Click:Connect(function()
        xTextBox.Text = "0"
        yTextBox.Text = "0"
        zTextBox.Text = "0"
        xUpdateSlider()
        yUpdateSlider()
        zUpdateSlider()
        updateRotation()
    end)
    
    -- Close button
    closeBtn.MouseButton1Click:Connect(function()
        if rotationAdjusterGui then
            rotationAdjusterGui:Destroy()
            rotationAdjusterGui = nil
        end
        print("[RotationAdjuster] UI closed")
    end)
    
    print("[RotationAdjuster] UI created successfully")
end

-- Function to show/hide UI based on tool equipping
local function onToolEquipped(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    currentTool = tool
    serverBaselineGrip = nil -- Reset baseline for new tool
    
    -- Show UI for any weapon (not just Meshes/)
    if not rotationAdjusterGui then
        createRotationUI()
    end
    print("[RotationAdjuster] Tool equipped:", tool.Name, "- UI shown")
end

local function onToolUnequipped(tool)
    if rotationAdjusterGui then
        rotationAdjusterGui:Destroy()
        rotationAdjusterGui = nil
    end
    currentTool = nil
    serverBaselineGrip = nil
    print("[RotationAdjuster] Tool unequipped - UI hidden")
end

-- Watch for character and tools
local function onCharacterAdded(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            onToolEquipped(child)
            
            child.Unequipped:Connect(function()
                onToolUnequipped(child)
            end)
        end
    end)
    
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and child == currentTool then
            onToolUnequipped(child)
        end
    end)
end

-- Setup for current and future characters
if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Keyboard shortcut to toggle UI (R key)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.R then
        if currentTool and rotationAdjusterGui then
            rotationAdjusterGui:Destroy()
            rotationAdjusterGui = nil
            print("[RotationAdjuster] UI toggled off")
        elseif currentTool then
            createRotationUI()
            print("[RotationAdjuster] UI toggled on")
        end
    end
end)

print("[RotationAdjuster] Rotation adjuster initialized - Press R to toggle UI")