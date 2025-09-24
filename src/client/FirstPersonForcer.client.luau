-- FirstPersonForcer: Forces first-person mode and overrides all camera restrictions
-- This script bypasses all other camera controls and locks to first-person only

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Set global flag to indicate FirstPersonForcer is active
_G.FirstPersonForcer = false

-- Configuration
local FORCE_FIRST_PERSON = false  -- ❌ DISABLED - First person mode disabled for now
local ZOOM_LOCK_DISTANCE = 0.5    -- Camera distance from character (0.5 = very close first-person)
local DEBUG_OUTPUT = true         -- Show debug messages

local function log(message)
	if DEBUG_OUTPUT then
		warn("[FirstPersonForcer] " .. message)
	end
end

local function forceFirstPerson()
	if not FORCE_FIRST_PERSON then return end
	
	pcall(function()
		-- Force camera mode to first-person
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		
		-- Lock zoom distances to force first-person
		player.CameraMinZoomDistance = ZOOM_LOCK_DISTANCE
		player.CameraMaxZoomDistance = ZOOM_LOCK_DISTANCE
		
		-- Set DevCameraOcclusionMode to help with first-person
		player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
		
		log("✅ Applied first-person camera settings")
	end)
end

local function enforceFirstPersonContinuously()
	if not FORCE_FIRST_PERSON then return end
	
	-- Continuously enforce first-person settings, but completely disable when UI is open
	RunService.Heartbeat:Connect(function()
		pcall(function()
			-- If any UI mouse enabler is active, DON'T enforce anything and unlock mouse
			if _G.UIMouseEnabler == true then
				-- Make sure mouse is unlocked when UI is open
				if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
					UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				end
				if not UserInputService.MouseIconEnabled then
					UserInputService.MouseIconEnabled = true
				end
				return -- Exit without enforcing first-person
			end
			
			-- Only enforce first-person when no UI is open
			if player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
				player.CameraMode = Enum.CameraMode.LockFirstPerson
			end
			
			if player.CameraMinZoomDistance ~= ZOOM_LOCK_DISTANCE then
				player.CameraMinZoomDistance = ZOOM_LOCK_DISTANCE
			end
			
			if player.CameraMaxZoomDistance ~= ZOOM_LOCK_DISTANCE then
				player.CameraMaxZoomDistance = ZOOM_LOCK_DISTANCE
			end
		end)
	end)
end

local function blockScrollZoom()
	if not FORCE_FIRST_PERSON then return end
	
	-- Block mouse wheel zoom attempts only when UI is closed
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- Don't block anything if UI is open
		if _G.UIMouseEnabler == true then return end
		
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			-- Block zoom attempts
			return
		end
	end)
end

-- Initialize first-person enforcement
log("🚀 FirstPersonForcer initializing...")

-- Apply initial settings
forceFirstPerson()

-- Start continuous enforcement
enforceFirstPersonContinuously()

-- Block zoom inputs
blockScrollZoom()

-- Handle character respawn
player.CharacterAdded:Connect(function()
	log("👤 Character respawned - reapplying first-person settings")
	wait(1) -- Wait for character to fully load
	forceFirstPerson()
end)

-- Apply to current character if it exists
if player.Character then
	forceFirstPerson()
end

log("❌ FirstPersonForcer initialized - first-person mode DISABLED")

-- Expose controls for other scripts
local FirstPersonForcer = {}

function FirstPersonForcer.Enable()
	FORCE_FIRST_PERSON = true
	forceFirstPerson()
	log("🔓 FirstPersonForcer enabled")
end

function FirstPersonForcer.Disable()
	FORCE_FIRST_PERSON = false
	pcall(function()
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 400
	end)
	log("🔓 FirstPersonForcer disabled - camera controls restored")
end

function FirstPersonForcer.SetZoomDistance(distance)
	ZOOM_LOCK_DISTANCE = distance
	if FORCE_FIRST_PERSON then
		forceFirstPerson()
	end
	log("🔧 Zoom distance set to " .. distance)
end

return FirstPersonForcer
