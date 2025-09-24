-- MouseHandler: Centralized mouse behavior control for UI interactions
-- Handles mouse unlocking when UIs are open and relocking when closed

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Configuration
local DEBUG_OUTPUT = true
local UNLOCK_ATTEMPTS = 5
local UNLOCK_DELAY = 0.05

local function log(message)
    if DEBUG_OUTPUT then
        warn("[MouseHandler] " .. message)
    end
end

-- Mouse unlock function with multiple attempts
local function forceUnlockMouse()
    log("🖱️ Force unlocking mouse for UI interaction...")
    
    -- Set global flag for other scripts
    _G.UIMouseEnabler = true
    
    -- Multiple unlock attempts for reliability
    for i = 1, UNLOCK_ATTEMPTS do
        pcall(function()
            -- Camera settings - MUST be Classic for mouse to work
            player.CameraMode = Enum.CameraMode.Classic
            player.CameraMinZoomDistance = 0.5
            player.CameraMaxZoomDistance = 1000
            
            -- Mouse settings - Force unlock
            UserInputService.MouseIconEnabled = true
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseDeltaSensitivity = 1
            
            -- Core GUI settings
            GuiService:SetMenuIsOpen(false)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
            
            -- Additional mouse unlock attempts
            UserInputService.MouseIconEnabled = true -- Repeat for emphasis
        end)
        
        if i < UNLOCK_ATTEMPTS then
            task.wait(UNLOCK_DELAY)
        end
    end
    
    log("✅ Mouse unlocked for UI interaction - MouseBehavior: " .. tostring(UserInputService.MouseBehavior))
end

-- Mouse relock function
local function relockMouse()
    log("🔒 Relocking mouse...")
    
    -- Clear global flag
    _G.UIMouseEnabler = false
    
    -- Restore first-person mode if FirstPersonForcer is active
    if _G.FirstPersonForcer then
        pcall(function()
            player.CameraMode = Enum.CameraMode.LockFirstPerson
            player.CameraMinZoomDistance = 0.5
            player.CameraMaxZoomDistance = 0.5
        end)
        log("✅ First-person mode restored")
    else
        log("ℹ️ FirstPersonForcer not active - leaving in Classic mode")
    end
end

-- Monitor global flag changes and actively maintain mouse state
local lastUIState = false
RunService.Heartbeat:Connect(function()
    local currentUIState = _G.UIMouseEnabler == true
    
    -- If UI is open, continuously ensure mouse is unlocked
    if currentUIState then
        pcall(function()
            -- Aggressively maintain unlocked mouse state
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                log("🔧 Corrected MouseBehavior to Default")
            end
            if not UserInputService.MouseIconEnabled then
                UserInputService.MouseIconEnabled = true
                log("🔧 Re-enabled MouseIcon")
            end
            if player.CameraMode ~= Enum.CameraMode.Classic then
                player.CameraMode = Enum.CameraMode.Classic
                log("🔧 Corrected CameraMode to Classic")
            end
        end)
    end
    
    -- Only act on state changes for main transitions
    if currentUIState ~= lastUIState then
        if currentUIState then
            forceUnlockMouse()
        else
            relockMouse()
        end
        lastUIState = currentUIState
    end
end)

-- API for other scripts
local MouseHandler = {}

function MouseHandler.UnlockMouse()
    forceUnlockMouse()
end

function MouseHandler.LockMouse()
    relockMouse()
end

function MouseHandler.IsUIOpen()
    return _G.UIMouseEnabler == true
end

-- Initialize
log("🚀 MouseHandler initialized")

-- Global access
_G.MouseHandler = MouseHandler

return MouseHandler
