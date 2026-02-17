--[[
	Beginning NPC - Uses shared NPCController
	
	All configuration is in: src/shared/NPCConfig.lua
	All AI logic is in: src/shared/NPCController.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local NPCController = require(sharedFolder:WaitForChild("NPCController"))

-- Initialize with config name
NPCController.init("Beginning")
