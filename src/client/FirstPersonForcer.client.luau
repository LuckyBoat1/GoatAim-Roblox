-- FirstPersonForcer: Forces first-person mode and overrides all camera restrictions
-- This script bypasses all other camera controls and locks to first-person only

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Configuration
local FORCE_FIRST_PERSON = true   -- ✅ ENABLED

-- Set global flag so other scripts (MouseHandler, Inventory) know FPS mode is active
_G.FirstPersonForcer = FORCE_FIRST_PERSON
local ZOOM_LOCK_DISTANCE = 0.5    -- Camera distance from character (0.5 = very close first-person)
local DEBUG_OUTPUT = true         -- Show debug messages

local function log(message)
	if DEBUG_OUTPUT then
		warn("[FirstPersonForcer] " .. message)
	end
end

-- ── CrossHair toggle (uses your CrossHair ScreenGui exactly as built) ─────
local crossHairFrame = player:WaitForChild("PlayerGui")
	:WaitForChild("CrossHair"):WaitForChild("Frame")
local crossHairVisible = true

local function applyMouseState()
	if crossHairVisible then
		-- CrossHair ON: first-person lock, hide mouse
		pcall(function()
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			player.CameraMinZoomDistance = ZOOM_LOCK_DISTANCE
			player.CameraMaxZoomDistance = ZOOM_LOCK_DISTANCE
		end)
		UserInputService.MouseIconEnabled = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		-- CrossHair OFF: Classic at 0.5 zoom (stays first-person visually) + free mouse
		-- Mouse cursor stays HIDDEN even without crosshair so screen stays clean
		pcall(function()
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMinZoomDistance = 0.5
			player.CameraMaxZoomDistance = 0.5
		end)
		UserInputService.MouseIconEnabled = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

-- Apply initial mouse state
applyMouseState()

-- PC-only Q indicator toast
local _qToast = nil
local function showQToast(isOn)
	if UserInputService.TouchEnabled then return end  -- never show on mobile
	if not _qToast then
		_qToast = Instance.new("TextLabel")
		_qToast.Size = UDim2.new(0, 200, 0, 36)
		_qToast.AnchorPoint = Vector2.new(0.5, 1)
		_qToast.Position = UDim2.new(0.5, 0, 1, -90)
		_qToast.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		_qToast.BackgroundTransparency = 0.3
		_qToast.TextColor3 = Color3.fromRGB(255, 255, 255)
		_qToast.Font = Enum.Font.GothamBold
		_qToast.TextSize = 15
		_qToast.BorderSizePixel = 0
		_qToast.ZIndex = 200
		_qToast.TextTransparency = 1
		_qToast.BackgroundTransparency = 1
		Instance.new("UICorner", _qToast).CornerRadius = UDim.new(0, 8)
		_qToast.Parent = player:WaitForChild("PlayerGui"):WaitForChild("CrossHair")
	end
	_qToast.Text = isOn and "[Q] Crosshair: ON" or "[Q] Crosshair: OFF"
	_qToast.TextColor3 = isOn and Color3.fromRGB(100, 255, 130) or Color3.fromRGB(255, 100, 100)
	_qToast.TextTransparency = 0
	_qToast.BackgroundTransparency = 0.3
	task.delay(1.5, function()
		if not _qToast then return end
		for i = 0, 10 do
			task.wait(0.05)
			_qToast.TextTransparency = i / 10
			_qToast.BackgroundTransparency = 0.3 + (0.7 * i / 10)
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if UserInputService.TouchEnabled then return end  -- Q toggle is PC-only
	if input.KeyCode == Enum.KeyCode.Q then
		-- Close any open menu first
		local menuWasOpen = false
		if _G.MatrixInventory and _G.MatrixInventory.IsOpen and _G.MatrixInventory.IsOpen() then
			_G.MatrixInventory.Close()
			menuWasOpen = true
		end
		if _G.MatrixQuest and _G.MatrixQuest.IsOpen and _G.MatrixQuest.IsOpen() then
			_G.MatrixQuest.Close()
			menuWasOpen = true
		end
		if _G.MatrixShop and _G.MatrixShop.IsOpen and _G.MatrixShop.IsOpen() then
			_G.MatrixShop.Close()
			menuWasOpen = true
		end
		if _G.MatrixHeadquarters and _G.MatrixHeadquarters.IsOpen and _G.MatrixHeadquarters.IsOpen() then
			_G.MatrixHeadquarters.Close()
			menuWasOpen = true
		end
		if _G.MatrixSupplyDrop and _G.MatrixSupplyDrop.IsOpen and _G.MatrixSupplyDrop.IsOpen() then
			_G.MatrixSupplyDrop.Close()
			menuWasOpen = true
		end
		if _G.MatrixSpinWheel and _G.MatrixSpinWheel.IsOpen and _G.MatrixSpinWheel.IsOpen() then
			_G.MatrixSpinWheel.Close()
			menuWasOpen = true
		end
		-- Always toggle crosshair
		crossHairVisible = not crossHairVisible
		crossHairFrame.Visible = crossHairVisible
		applyMouseState()
		showQToast(crossHairVisible)
	end
end)

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
			-- If a UI is open (inventory, shop, quests, etc.), skip enforcement
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
			
			-- Enforce state based on crosshair visibility
			if crossHairVisible then
				-- CrossHair ON: keep LockFirstPerson + hidden locked mouse
				if player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
					player.CameraMode = Enum.CameraMode.LockFirstPerson
				end
				if UserInputService.MouseIconEnabled then
					UserInputService.MouseIconEnabled = false
				end
				if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
					UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				end
			else
				-- CrossHair OFF: keep Classic at 0.5 zoom + free mouse
				if player.CameraMode ~= Enum.CameraMode.Classic then
					player.CameraMode = Enum.CameraMode.Classic
				end
				if not UserInputService.MouseIconEnabled then
					UserInputService.MouseIconEnabled = true
				end
				if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
					UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				end
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

log("✅ FirstPersonForcer initialized - first-person mode ENABLED (Q = toggle crosshair)")

-- Expose controls for other scripts
local FirstPersonForcer = {}

function FirstPersonForcer.Enable()
	FORCE_FIRST_PERSON = true
	_G.FirstPersonForcer = true
	forceFirstPerson()
	log("🔓 FirstPersonForcer enabled")
end

function FirstPersonForcer.Disable()
	FORCE_FIRST_PERSON = false
	_G.FirstPersonForcer = false
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
