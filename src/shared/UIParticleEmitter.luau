--assert(game["Run Service"]:IsServer(), "UIParticleEmitter cannot be requested on server!")

-- // Variables
local UIParticleEmitter = {}
UIParticleEmitter.__index = function(self, index)
	return self.Config[index] or UIParticleEmitter[index]
end

UIParticleEmitter.__newindex = function(self, index, value)
	rawset(self.Config, index, value)
	rawset(self.Config, "Updaters", self:GetUpdaters()) -- Re-evaluate updaters
	
	if (index == "Enabled" and value == true) then
		self:Enable()
	elseif (index == "Flipbook" and value ~= nil) then
		task.spawn(function()
			self:ConfigureFlipbook()
		end)
	end
end

local RunS = game:GetService("RunService")

local plugin
local PluginUI
local Widget
local UIParticle = require(script.UIParticle)

local DefaultConfig = {
	Updaters = {}, -- a list of updater modules to use for rendering the particles
	
	Flipbook = {},
	
	Parent = nil,
	
	-- Fire-optimized defaults
	Rate = 15, -- particles per second
	Lifetime = 2, -- seconds
	Velocity = Vector2.new(0, -50), -- upward movement
	Acceleration = Vector2.new(0, -20), -- upward acceleration
	Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0.2)
	},
	Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	},
	Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)), -- Orange
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 200, 0)), -- Yellow-orange
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 255, 100)), -- Light yellow
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)) -- White
	},
	ZIndex = 10,
	Enabled = false
}

local UI

task.spawn(function()
	if game.Players.LocalPlayer and ((game["Run Service"]:IsRunMode() and game["Run Service"]:IsStudio()) or (not game["Run Service"]:IsStudio())) then
		-- For particles that arent locked to parent
		UI = Instance.new("ScreenGui")
		UI.Name = "UIParticleEmitters"
		UI.ResetOnSpawn = false
		UI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	DefaultConfig.UI = UI
end)

-- // Functions

-- Creates a new UIParticleEmitter using the provided Config table or configuration folder.
function UIParticleEmitter.new(Config)
	Config = Config or {}
	
	for i, v in pairs(DefaultConfig) do
		if Config[i] ~= nil then
			continue
		end

		Config[i] = v
	end
	
	local self = setmetatable({
		Config = Config
	}, UIParticleEmitter)
	
	self.Particles = {}
	
	self:ConfigureFlipbook()
	
	if rawget(self.Config, "Enabled") then
		self:Enable()
	end
	
	self.Config.Updaters = self:GetUpdaters()
	
	return self
end

-- Sets up the particle flipbook.
function UIParticleEmitter:ConfigureFlipbook()
	if self.Config.Flipbook and self.Config.Flipbook.Image then
		-- Get Flipbook Size
		local Image = self.Config.Flipbook.Image :: number

		if not self.Config.Flipbook.Size then
			local x, y = 1024, 1024 -- Default size for fire textures
			self.Config.Flipbook.Size = Vector2.new(x, y)
		end
		
		self.Config.Image = "rbxassetid://".. tostring(Image)
	end
end

-- Returns a dictionary of module names = module functions that will be used to render the particle.
function UIParticleEmitter:GetUpdaters()
	local Updaters = {}
	
	-- Basic updaters for fire effects
	Updaters.Velocity = function(particle, dt)
		if particle.Velocity and particle.Velocity.Magnitude > 0 then
			local newPos = particle.Visual.Position + UDim2.fromOffset(particle.Velocity.X * dt, particle.Velocity.Y * dt)
			particle.Visual.Position = newPos
		end
	end
	
	Updaters.Acceleration = function(particle, dt)
		if particle.Acceleration and particle.Acceleration.Magnitude > 0 then
			particle.Velocity = particle.Velocity + (particle.Acceleration * dt)
		end
	end
	
	Updaters.Size = function(particle, dt)
		if particle.Size and typeof(particle.Size) == "NumberSequence" then
			local sizeValue = self:EvalNumberSequence(particle.Size, particle.TimeAlpha)
			particle.Visual.Size = UDim2.fromScale(sizeValue * 0.1, sizeValue * 0.1) -- Scale for UI
		end
	end
	
	Updaters.Transparency = function(particle, dt)
		if particle.Transparency and typeof(particle.Transparency) == "NumberSequence" then
			local transparencyValue = self:EvalNumberSequence(particle.Transparency, particle.TimeAlpha)
			particle.Visual.ImageTransparency = transparencyValue
		end
	end
	
	Updaters.Color = function(particle, dt)
		if particle.Color and typeof(particle.Color) == "ColorSequence" then
			local colorValue = self:EvalColorSequence(particle.Color, particle.TimeAlpha)
			particle.Visual.ImageColor3 = colorValue
		end
	end
	
	return Updaters
end

-- Helper function to evaluate NumberSequence
function UIParticleEmitter:EvalNumberSequence(sequence, time)
	if typeof(sequence) == "number" then
		return sequence
	end
	
	if time == 0 then
		return sequence.Keypoints[1].Value
	elseif time == 1 then
		return sequence.Keypoints[#sequence.Keypoints].Value
	end

	for i = 1, #sequence.Keypoints - 1 do
		local currKeypoint = sequence.Keypoints[i]
		local nextKeypoint = sequence.Keypoints[i + 1]
		if time >= currKeypoint.Time and time < nextKeypoint.Time then
			local alpha = (time - currKeypoint.Time) / (nextKeypoint.Time - currKeypoint.Time)
			return currKeypoint.Value + (nextKeypoint.Value - currKeypoint.Value) * alpha
		end
	end
end

-- Helper function to evaluate ColorSequence
function UIParticleEmitter:EvalColorSequence(sequence, time)
	if typeof(sequence) ~= "ColorSequence" then
		return sequence
	end
	
	if time == 0 then
		return sequence.Keypoints[1].Value
	elseif time == 1 then
		return sequence.Keypoints[#sequence.Keypoints].Value
	end

	for i = 1, #sequence.Keypoints - 1 do
		local thisKeypoint = sequence.Keypoints[i]
		local nextKeypoint = sequence.Keypoints[i + 1]
		if time >= thisKeypoint.Time and time < nextKeypoint.Time then
			local alpha = (time - thisKeypoint.Time) / (nextKeypoint.Time - thisKeypoint.Time)
			return Color3.new(
				(nextKeypoint.Value.R - thisKeypoint.Value.R) * alpha + thisKeypoint.Value.R,
				(nextKeypoint.Value.G - thisKeypoint.Value.G) * alpha + thisKeypoint.Value.G,
				(nextKeypoint.Value.B - thisKeypoint.Value.B) * alpha + thisKeypoint.Value.B
			)
		end
	end
end

-- Starts emitting UIParticles. Can also be achieved via UIParticleEmitter.Enabled = true
function UIParticleEmitter:Enable()
	task.spawn(function()
		if rawget(self, "IsEmitting") == true then
			return
		end
		
		rawset(self, "IsEmitting", true)
		
		while rawget(self.Config, "Enabled") == true do
			self:Emit()
			task.wait(1/self.Rate)
		end
		
		rawset(self, "IsEmitting", false)
	end)
end

-- Emits a single particle. Count can be used to emit multiple particles at once.
function UIParticleEmitter:Emit(Count)
	pcall(function()
		Count = Count or 1
		
		for i = 1, Count do
			local newParticle = UIParticle.new(self.Config)
			newParticle:Start()
			
			table.insert(self.Particles, newParticle)
			
			task.delay(newParticle.Lifetime, function()
				local index = table.find(self.Particles, newParticle)
				if index then
					table.remove(self.Particles, index)
				end
			end)
		end
	end)
end

-- Removes all UIParticles emitted by this UIParticleEmitter that are currently visible.
function UIParticleEmitter:Clear()
	for index, Particle in pairs(self.Particles) do
		Particle:Destroy()
		local particleIndex = table.find(self.Particles, Particle)
		if particleIndex then
			table.remove(self.Particles, particleIndex)
		end
	end
end

-- Set a new ScreenGUI to use for rendering particles that aren't locked to parent.
function UIParticleEmitter.SetUI(newUI)
	UI = newUI
end

return UIParticleEmitter
