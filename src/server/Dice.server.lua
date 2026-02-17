--[[
	Dice NPC - Using NPCController
	
	All configuration is in: src/shared/NPCConfig.lua
	All AI logic is in: src/shared/NPCController.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local NPCController = require(sharedFolder:WaitForChild("NPCController"))

-- Initialize with config name (matches key in NPCConfig)
NPCController.init("Dice")
