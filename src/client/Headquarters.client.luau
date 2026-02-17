-- Headquarters UI Controller
-- Handles the HQ menu with Upgrades and Storage options

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for HeadQuarters GUI
local headquartersGui = playerGui:WaitForChild("HeadQuarters", 10)
if not headquartersGui then
	warn("[Headquarters] HeadQuarters GUI not found in PlayerGui")
	return
end
--
local canvasGroup = headquartersGui:WaitForChild("CanvasGroup")
local mainFrame = canvasGroup:WaitForChild("Main")

-- Get frames
local topFrame = mainFrame:WaitForChild("Top")
local upgradesFrame = mainFrame:WaitForChild("Upgrades")
local storageFrame = mainFrame:WaitForChild("Storage")
local middleFrame = mainFrame:WaitForChild("Middle")

-- Setup text labels
local function setupLabel(frame, text, fontSize)
	local textLabel = frame:FindFirstChild("TextLabel")
	if textLabel then
		textLabel.Text = text
		textLabel.Font = Enum.Font.FredokaOne
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextSize = fontSize or 24
		textLabel.TextStrokeTransparency = 0.8
		textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	end
end

-- Setup all labels
setupLabel(topFrame, "HEADQUARTERS", 32)
setupLabel(upgradesFrame, "UPGRADES", 22)
setupLabel(storageFrame, "STORAGE", 22)

-- Hover effect colors
local hoverColor = Color3.fromRGB(255, 100, 120)

-- Store original properties for restoration
local originalProps = {}

-- Create hover effects for clickable frames
local function addHoverEffect(frame)
	local imageLabel = frame:FindFirstChild("ImageLabel")
	local textLabel = frame:FindFirstChild("TextLabel")
	if not imageLabel then return end
	
	-- Store originals
	originalProps[frame] = {
		size = frame.Size,
		imageColor = imageLabel.ImageColor3,
		textSize = textLabel and textLabel.TextSize or 22,
		rotation = frame.Rotation
	}
	
	local orig = originalProps[frame]
	local isHovering = false
	
	frame.MouseEnter:Connect(function()
		isHovering = true
		
		-- Scale up frame
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(orig.size.X.Scale * 1.05, orig.size.X.Offset, orig.size.Y.Scale * 1.05, orig.size.Y.Offset)
		}):Play()
		
		-- Brighten image
		TweenService:Create(imageLabel, TweenInfo.new(0.15), {
			ImageColor3 = Color3.fromRGB(
				math.min(255, orig.imageColor.R * 255 + 40),
				math.min(255, orig.imageColor.G * 255 + 40),
				math.min(255, orig.imageColor.B * 255 + 40)
			)
		}):Play()
		
		-- Pop text
		if textLabel then
			TweenService:Create(textLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				TextSize = orig.textSize + 3,
				TextColor3 = Color3.fromRGB(255, 255, 150)
			}):Play()
		end
		
		-- Subtle wobble (always ends at original rotation)
		task.spawn(function()
			TweenService:Create(frame, TweenInfo.new(0.08), { Rotation = orig.rotation + 2 }):Play()
			task.wait(0.08)
			TweenService:Create(frame, TweenInfo.new(0.08), { Rotation = orig.rotation - 2 }):Play()
			task.wait(0.08)
			TweenService:Create(frame, TweenInfo.new(0.08), { Rotation = orig.rotation + 1 }):Play()
			task.wait(0.08)
			TweenService:Create(frame, TweenInfo.new(0.08), { Rotation = orig.rotation - 1 }):Play()
			task.wait(0.08)
			TweenService:Create(frame, TweenInfo.new(0.08), { Rotation = orig.rotation }):Play()
		end)
	end)
	
	frame.MouseLeave:Connect(function()
		isHovering = false
		
		-- Restore frame size and ensure rotation is back to original
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = orig.size,
			Rotation = orig.rotation
		}):Play()
		
		-- Restore image color
		TweenService:Create(imageLabel, TweenInfo.new(0.15), {
			ImageColor3 = orig.imageColor
		}):Play()
		
		-- Restore text
		if textLabel then
			TweenService:Create(textLabel, TweenInfo.new(0.15), {
				TextSize = orig.textSize,
				TextColor3 = Color3.fromRGB(255, 255, 255)
			}):Play()
		end
	end)
	
	-- Click effect - bounce and flash
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Quick squish
			TweenService:Create(frame, TweenInfo.new(0.08), {
				Size = UDim2.new(orig.size.X.Scale * 0.95, orig.size.X.Offset, orig.size.Y.Scale * 0.95, orig.size.Y.Offset)
			}):Play()
			
			-- Flash white
			TweenService:Create(imageLabel, TweenInfo.new(0.05), {
				ImageColor3 = Color3.fromRGB(255, 255, 255)
			}):Play()
			
			task.delay(0.08, function()
				-- Bounce back bigger
				TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(orig.size.X.Scale * 1.08, orig.size.X.Offset, orig.size.Y.Scale * 1.08, orig.size.Y.Offset)
				}):Play()
				
				task.delay(0.15, function()
					-- Settle to hover size if still hovering
					local targetSize = isHovering 
						and UDim2.new(orig.size.X.Scale * 1.05, orig.size.X.Offset, orig.size.Y.Scale * 1.05, orig.size.Y.Offset)
						or orig.size
					TweenService:Create(frame, TweenInfo.new(0.1), {
						Size = targetSize
					}):Play()
					
					TweenService:Create(imageLabel, TweenInfo.new(0.1), {
						ImageColor3 = isHovering 
							and Color3.fromRGB(
								math.min(255, orig.imageColor.R * 255 + 40),
								math.min(255, orig.imageColor.G * 255 + 40),
								math.min(255, orig.imageColor.B * 255 + 40)
							)
							or orig.imageColor
					}):Play()
				end)
			end)
			
			print("[Headquarters] Clicked:", frame.Name)
		end
	end)
end

-- Add hover effects to Upgrades and Storage
addHoverEffect(upgradesFrame)
addHoverEffect(storageFrame)

-- Add subtle pulse to Top frame title
task.spawn(function()
	local topText = topFrame:FindFirstChild("TextLabel")
	if topText then
		while topText and topText.Parent do
			TweenService:Create(topText, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				TextColor3 = Color3.fromRGB(255, 220, 150)
			}):Play()
			task.wait(1.5)
			TweenService:Create(topText, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				TextColor3 = Color3.fromRGB(255, 255, 255)
			}):Play()
			task.wait(1.5)
		end
	end
end)

-- State
local isOpen = false

-- Open/Close functions
local function open()
	if isOpen then return end
	isOpen = true
	
	headquartersGui.Enabled = true
	canvasGroup.GroupTransparency = 1
	
	TweenService:Create(canvasGroup, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		GroupTransparency = 0
	}):Play()
end

local function close()
	if not isOpen then return end
	isOpen = false
	
	TweenService:Create(canvasGroup, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		GroupTransparency = 1
	}):Play()
	
	task.wait(0.25)
	if not isOpen then
		headquartersGui.Enabled = false
	end
end

local function toggle()
	if isOpen then
		close()
	else
		open()
	end
end

-- Expose API globally
_G.MatrixHeadquarters = {
	Open = open,
	Close = close,
	Toggle = toggle,
	IsOpen = function() return isOpen end
}

-- Start hidden
headquartersGui.Enabled = false
canvasGroup.GroupTransparency = 1

print("[Headquarters] Controller initialized")
