-- SkinServer.lua - Place in ServerScriptService
-- Date: 2025-08-16 15:15:38
-- User: almoe930-dotcom

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Ensure remotes exist in RemoteEvents folder (matching other scripts)
local Remotes = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder")
Remotes.Name = "RemoteEvents"
Remotes.Parent = ReplicatedStorage

local EquipSkin = Remotes:FindFirstChild("EquipSkin") or Instance.new("RemoteEvent")
EquipSkin.Name = "EquipSkin"
EquipSkin.Parent = Remotes

-- Ensure SkinService values exist to avoid errors
local SkinService = ServerScriptService:FindFirstChild("SkinService")
if not SkinService then
	-- Create a temporary script that will create a minimal SkinService
	local tempScript = Instance.new("Script")
	tempScript.Name = "SkinService"

	-- This is the implementation that will be used if there's no SkinService
	tempScript.Source = [[
        -- Temporary SkinService implementation
        
        local SkinLibrary = game:GetService("ReplicatedStorage"):FindFirstChild("SkinLibrary")
        
        local function ApplySkinToTool(tool, skinId)
            if not tool or not skinId then return end
            print("Applying skin: " .. skinId .. " to tool: " .. tool.Name)
            
            -- Try to find the skin in the SkinLibrary
            local skin = nil
            if SkinLibrary then
                skin = SkinLibrary:FindFirstChild(skinId, true)
            end
            
            if not skin then
                print("Skin not found: " .. skinId)
                return
            end
            
            -- Clear existing skinned parts
            for _, child in pairs(tool:GetChildren()) do
                if child:GetAttribute("IsSkin") then
                    child:Destroy()
                end
            end
            
            -- Clone and apply the skin
            local skinClone = skin:Clone()
            
            -- Apply to tool
            for _, child in pairs(skinClone:GetChildren()) do
                child:SetAttribute("IsSkin", true)
                child.Parent = tool
            end
            
            -- Set tool attribute to track which skin is applied
            tool:SetAttribute("AppliedSkin", skinId)
            print("Successfully applied skin: " .. skinId)
        end
        
        local function ApplySkinToModel(model, skinId)
            print("Apply skin to model not implemented")
        end
        
        local function ApplySkinToCharacter(player, skinId, attachTo)
            print("Apply skin to character not implemented")
        end
        
        local function ClearAppliedSkin(target)
            print("Clear skin not implemented")
        end
        
        local function GetSkinClone(skinId)
            if not SkinLibrary then return Instance.new("Part") end
            local skin = SkinLibrary:FindFirstChild(skinId)
            return skin and skin:Clone() or Instance.new("Part")
        end
        
        -- Set global variables that SkinServer can access
        _G.SkinService = {
            ApplySkinToTool = ApplySkinToTool,
            ApplySkinToModel = ApplySkinToModel,
            ApplySkinToCharacter = ApplySkinToCharacter,
            ClearAppliedSkin = ClearAppliedSkin,
            GetSkinClone = GetSkinClone
        }
    ]]

	tempScript.Parent = ServerScriptService
	print("Created temporary SkinService script - restart may be required")
end

-- Function to resolve object paths (e.g. "Workspace.Model.Part")
local function resolvePath(path: string): Instance?
	local current: Instance? = nil
	for token in string.gmatch(path, "[^%.]+") do
		if not current then
			if token == "workspace" or token == "Workspace" then current = workspace
			elseif token == "game" or token == "Game" then current = game
			else
				current = workspace:FindFirstChild(token) or game:FindFirstChild(token)
			end
		else
			current = current:FindFirstChild(token)
		end
		if not current then return nil end
	end
	return current
end

-- Handle EquipSkin remote events
EquipSkin.OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" then return end
	local skinId = payload.skinId
	local target = payload.target
	if type(skinId) ~= "string" or type(target) ~= "string" then return end

	-- Try to access skin functions from global variable (set by SkinService)
	local skinFunctions = _G.SkinService
	if not skinFunctions then
		print("Waiting for SkinService to initialize...")
		wait(1) -- Give a moment for SkinService to initialize
		skinFunctions = _G.SkinService
		if not skinFunctions then
			warn("SkinService not initialized! Skin equipping won't work.")
			return
		end
	end

	if target == "tool" then
		local toolName = payload.toolName
		if type(toolName) ~= "string" then return end
		local tool = (player.Character and player.Character:FindFirstChild(toolName)) or player.Backpack:FindFirstChild(toolName)
		if tool and tool:IsA("Tool") then
			skinFunctions.ApplySkinToTool(tool, skinId)
			print(("[SkinServer] Equipped '%s' on Tool '%s' for %s"):format(skinId, tool.Name, player.Name))
		else
			warn(("[SkinServer] Tool '%s' not found for %s"):format(tostring(toolName), player.Name))
		end

	elseif target == "model" then
		local path = payload.modelPath
		if type(path) ~= "string" then return end
		local obj = resolvePath(path)
		if obj and obj:IsA("Model") then
			skinFunctions.ApplySkinToModel(obj, skinId)
		else
			warn(("[SkinServer] Model path not found: %s"):format(path))
		end

	elseif target == "character" then
		skinFunctions.ApplySkinToCharacter(player, skinId, payload.attachTo)
	end
end)

print("SkinServer initialized! Waiting for EquipSkin requests...")