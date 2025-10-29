-- Rotation Adjuster UI - FOR TESTING ONLY
-- Applies additional rotations on top of server's final grip calculations

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local _TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentTool = nil
local rotationAdjusterGui = nil
local serverFinalGrip = nil -- Store the server's final grip result as baseline
local gripChangedConnection = nil -- Track the connection to clean it up

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
        if not currentTool then 
            return 
        end
        
        if not serverFinalGrip then
            return
        end
        
        -- Get current rotation values
        rotationX = tonumber(xTextBox.Text) or 0
        rotationY = tonumber(yTextBox.Text) or 0
        rotationZ = tonumber(zTextBox.Text) or 0
        
        -- Start from the server's final grip (which already has all server calculations applied)
        local baseGrip = serverFinalGrip
        
        -- Create additional rotation adjustment from UI values
        local adjusterRotation = CFrame.Angles(math.rad(rotationX), math.rad(rotationY), math.rad(rotationZ))
        
        -- Apply adjuster rotation on top of server's final result
        currentTool.Grip = baseGrip * adjusterRotation
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
    
    -- Create rotation sliders (ALWAYS start at 0 for fresh weapon)
    xTextBox, xResetBtn, xUpdateSlider = createRotationSlider("RotX", "X", 40, 0, 360, 0)
    yTextBox, yResetBtn, yUpdateSlider = createRotationSlider("RotY", "Y", 70, 0, 360, 0)
    zTextBox, zResetBtn, zUpdateSlider = createRotationSlider("RotZ", "Z", 100, 0, 360, 0)
    
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
    
    -- Individual reset buttons (reset to 0 = no offset from server rotation)
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
    
    -- Reset all button (reset to server's final grip)
    resetAllBtn.MouseButton1Click:Connect(function()
        if not currentTool then return end
        
        -- Reset adjuster values to 0,0,0 (no additional rotation)
        xTextBox.Text = "0"
        yTextBox.Text = "0"
        zTextBox.Text = "0"
        xUpdateSlider()
        yUpdateSlider()
        zUpdateSlider()
        
        -- Restore the server's final grip (which already has all server calculations)
        if serverFinalGrip then
            currentTool.Grip = serverFinalGrip
        else
            -- Fallback: update with 0,0,0 rotation (which should match server result)
            updateRotation()
        end
    end)
    
    -- Close button
    closeBtn.MouseButton1Click:Connect(function()
        if rotationAdjusterGui then
            rotationAdjusterGui:Destroy()
            rotationAdjusterGui = nil
        end
    end)
end

-- Function to show/hide UI based on tool equipping
local function onToolEquipped(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    -- Clean up old grip watcher
    if gripChangedConnection then
        gripChangedConnection:Disconnect()
        gripChangedConnection = nil
    end
    
    currentTool = tool
    serverFinalGrip = nil -- Clear old baseline
    
    -- ALWAYS reset to 0,0,0 when switching weapons
    rotationX = 0
    rotationY = 0
    rotationZ = 0
    
    -- Destroy old UI immediately
    if rotationAdjusterGui then
        rotationAdjusterGui:Destroy()
        rotationAdjusterGui = nil
    end
    
    -- Wait for server to finish its grip adjustments
    spawn(function()
        -- Wait for the tool's OriginalGripStored attribute (server sets this)
        local startTime = tick()
        while not tool:GetAttribute("OriginalGripStored") and (tick() - startTime) < 2 do
            wait(0.1)
        end
        
        -- Additional wait to ensure server's FINAL rotation is applied
        wait(0.5)
        
        if currentTool ~= tool then return end -- Tool was unequipped, abort
        
        -- Read the server's FINAL grip from stored attributes (never includes adjuster rotations)
        if tool:GetAttribute("ServerFinalGripStored") then
            local x = tool:GetAttribute("ServerFinalGripX") or 0
            local y = tool:GetAttribute("ServerFinalGripY") or 0
            local z = tool:GetAttribute("ServerFinalGripZ") or 0
            local rx = tool:GetAttribute("ServerFinalGripRX") or 1
            local ry = tool:GetAttribute("ServerFinalGripRY") or 0
            local rz = tool:GetAttribute("ServerFinalGripRZ") or 0
            local ux = tool:GetAttribute("ServerFinalGripUX") or 0
            local uy = tool:GetAttribute("ServerFinalGripUY") or 1
            local uz = tool:GetAttribute("ServerFinalGripUZ") or 0
            
            serverFinalGrip = CFrame.fromMatrix(
                Vector3.new(x, y, z),
                Vector3.new(rx, ry, rz),
                Vector3.new(ux, uy, uz)
            )
        else
            serverFinalGrip = tool.Grip
        end
        
        -- Set tool grip to server baseline (remove any leftover adjuster rotations)
        tool.Grip = serverFinalGrip
        
        -- Watch for server changing the grip and update baseline automatically
        gripChangedConnection = tool:GetPropertyChangedSignal("Grip"):Connect(function()
            -- If rotations are 0, this is a server change - update baseline
            if rotationX == 0 and rotationY == 0 and rotationZ == 0 then
                local newGrip = tool.Grip
                -- Only update if significantly different
                if (newGrip.Position - serverFinalGrip.Position).Magnitude > 0.01 or
                   math.abs(newGrip.LookVector:Dot(serverFinalGrip.LookVector) - 1) > 0.01 then
                    serverFinalGrip = newGrip
                    tool.Grip = serverFinalGrip
                end
            end
        end)
        
        -- Create fresh UI with 0,0,0 values
        createRotationUI()
    end)
end

local function onToolUnequipped(tool)
    -- Clean up grip watcher
    if gripChangedConnection then
        gripChangedConnection:Disconnect()
        gripChangedConnection = nil
    end
    
    if rotationAdjusterGui then
        rotationAdjusterGui:Destroy()
        rotationAdjusterGui = nil
    end
    currentTool = nil
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
        elseif currentTool then
            createRotationUI()
        end
    end
end)
