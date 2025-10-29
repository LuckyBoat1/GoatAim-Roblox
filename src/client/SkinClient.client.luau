-- SkinClient: Interface to server-side SkinService
-- Watches for SkinId attribute changes and triggers server-side skin application

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Remote setup
local Remotes = ReplicatedStorage:FindFirstChild("RemoteEvents") or ReplicatedStorage:FindFirstChild("Remotes")
local EquipSkin

-- Safe setup that won't block script execution
local function setupRemoteEvents()
	if not Remotes then
		Remotes = ReplicatedStorage:FindFirstChild("RemoteEvents") 
		if not Remotes then
			Remotes = ReplicatedStorage:FindFirstChild("Remotes")
		end
		if not Remotes then
			Remotes = Instance.new("Folder")
			Remotes.Name = "RemoteEvents"
			Remotes.Parent = ReplicatedStorage
		end
	end

	if not EquipSkin then
		EquipSkin = Remotes:FindFirstChild("EquipSkin")
		if not EquipSkin then
			EquipSkin = Instance.new("RemoteEvent")
			EquipSkin.Name = "EquipSkin"
			EquipSkin.Parent = Remotes
		end
	end
end

setupRemoteEvents()

-- Apply skin to tool by requesting server-side application
local function applySkinToTool(tool, skinId)
	if not tool or not tool:IsA("Tool") then return end
	if not skinId or skinId == "" then return end
	
	-- Request server-side skin application through SkinService
	setupRemoteEvents()
	if EquipSkin then
		EquipSkin:FireServer({ skinId = skinId, target = "tool", toolName = tool.Name })
	end
end

-- Watch for SkinId attribute changes on a tool
local function watchToolForSkin(tool)
	if not tool:IsA("Tool") then return end
	
	-- Check for existing SkinId
	
	-- Check for existing SkinId
	local currentSkinId = tool:GetAttribute("SkinId")
	if currentSkinId then
		applySkinToTool(tool, currentSkinId)
	end
	
	-- Watch for attribute changes
	local connection = tool:GetAttributeChangedSignal("SkinId"):Connect(function()
		local newSkinId = tool:GetAttribute("SkinId")
		if newSkinId then
			applySkinToTool(tool, newSkinId)
		end
	end)
	
	-- Clean up connection when tool is removed
	tool.AncestryChanged:Connect(function()
		if not tool.Parent then
			connection:Disconnect()
		end
	end)
end

-- Watch character for new tools
local function watchCharacter(character)
	if not character then return end
	
	-- Watch for existing tools
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			watchToolForSkin(child)
		end
	end
	
	-- Watch for new tools
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			watchToolForSkin(child)
		end
	end)
end

-- Watch backpack for tools
local function watchBackpack(backpack)
	if not backpack then return end
	
	-- Watch for existing tools
	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("Tool") then
			watchToolForSkin(child)
		end
	end
	
	-- Watch for new tools
	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			watchToolForSkin(child)
		end
	end)
end

-- Initialize the skin system
local function initialize()
	-- Watch current character
	if player.Character then
		watchCharacter(player.Character)
	end
	
	-- Watch for character respawn
	player.CharacterAdded:Connect(watchCharacter)
	
	-- Watch backpack
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		watchBackpack(backpack)
	end
	
	player.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			watchBackpack(child)
		end
	end)
end

-- API for other scripts
local SkinClient = {}

function SkinClient.EquipToTool(skinId, toolName)
	setupRemoteEvents()
	if not EquipSkin then
		return
	end
	EquipSkin:FireServer({ skinId = skinId, target = "tool", toolName = toolName })
end

function SkinClient.EquipToCharacter(skinId, attachTo)
	setupRemoteEvents()
	if not EquipSkin then
		return
	end
	EquipSkin:FireServer({ skinId = skinId, target = "character", attachTo = attachTo })
end

function SkinClient.EquipToModel(skinId, modelPath)
	setupRemoteEvents()
	if not EquipSkin then
		return
	end
	EquipSkin:FireServer({ skinId = skinId, target = "model", modelPath = modelPath })
end

-- Start the automatic skin application system
initialize()

return SkinClient