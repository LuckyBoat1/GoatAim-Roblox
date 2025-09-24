-- // Variables
local UIParticle = {}
UIParticle.__index = UIParticle
UIParticle.__newindex = function(self, index, value)
	rawset(self, index, value)
end

local RunS = game:GetService("RunService")

-- // Functions

--Creates and returns a new UIParticle with the provided Config table and renders it for the first time.
function UIParticle.new(Config)
	local self = setmetatable({}, UIParticle)
	
	-- Copy config values
	for key, value in pairs(Config) do
		self[key] = value
	end
	
	-- Initialize particle properties
	self.TimeAlpha = 0
	self.Position2D = Vector2.new()
	
	-- Randomize velocity if needed
	if self.Velocity and self.Velocity.Magnitude == 0 and (self.VelocityX or self.VelocityY) then
		local function evalNumberRange(range)
			if typeof(range) == "NumberRange" then
				return math.random() * (range.Max - range.Min) + range.Min
			elseif typeof(range) == "number" then
				return range
			end
			return 0
		end
		
		self.Velocity = Vector2.new(evalNumberRange(self.VelocityX or 0), evalNumberRange(self.VelocityY or 0))
	end
	
	self:CreateVisual()
	
	return self
end

--Creates a new ImageLabel to be used as the visual for the particle.
function UIParticle:CreateVisual()
	local Visual = Instance.new("ImageLabel")
	self.Visual = Visual
	
	Visual.BackgroundTransparency = 1
	
	self.Image = self.Image or "rbxassetid://2592670412"
	
	if typeof(self.Image) == "number" then
		self.Image = "rbxassetid://".. tostring(self.Image)
	end
	
	Visual.Image = self.Image
	
	Visual.ResampleMode = self.ResamplerMode or Enum.ResamplerMode.Pixelated
	Visual.ZIndex = self.ZIndex or 1
	Visual.AnchorPoint = Vector2.new(0.5, 0.5)
	
	-- Set initial position
	if not self.StartPosition then
		-- Default to center of parent if no position specified
		Visual.Position = UDim2.fromScale(0.5, 0.5)
	else
		Visual.Position = self.StartPosition
	end
	
	-- Set initial size
	if typeof(self.Size) == "NumberSequence" then
		local initialSize = self.Size.Keypoints[1].Value
		Visual.Size = UDim2.fromScale(initialSize * 0.1, initialSize * 0.1)
	else
		Visual.Size = UDim2.fromScale(0.05, 0.05) -- Default small size
	end
	
	-- Set initial color
	if typeof(self.Color) == "ColorSequence" then
		Visual.ImageColor3 = self.Color.Keypoints[1].Value
	elseif typeof(self.Color) == "Color3" then
		Visual.ImageColor3 = self.Color
	end
	
	-- Set initial transparency
	if typeof(self.Transparency) == "NumberSequence" then
		Visual.ImageTransparency = self.Transparency.Keypoints[1].Value
	elseif typeof(self.Transparency) == "number" then
		Visual.ImageTransparency = self.Transparency
	else
		Visual.ImageTransparency = 0
	end
	
	Visual.Visible = false
	Visual.Parent = self.Parent or self.UI
	
	return Visual
end

-- Starts rendering the particle.
function UIParticle:Start()
	self.Visual.Visible = true
	self.StartTime = tick()
	
	self.Connection = RunS.RenderStepped:Connect(function(dt)
		self:Update(dt)
	end)
end

-- Renders the particle, optionally with a delta time.
function UIParticle:Update(dt)
	local TimePassed
	
	if self.StartTime then
		TimePassed = tick() - (self.StartTime)
	else
		TimePassed = 0
	end
	
	local TimeAlpha = math.clamp(TimePassed / self.Lifetime, 0, 1)
	self.TimeAlpha = TimeAlpha
	
	if TimePassed >= self.Lifetime then
		self:Destroy()
		return
	end
	
	-- Update particle properties using updaters
	if self.Updaters then
		for Name, Updater in pairs(self.Updaters) do
			Updater(self, dt)
		end
	end
end

function UIParticle:Destroy()
	if self.Connection then
		self.Connection:Disconnect()
	end
	if self.Visual then
		self.Visual:Destroy()
	end
	
	self.isDestroyed = true
	setmetatable(self, nil)
end

-- Gives a new UIParticle constructor.
return UIParticle
