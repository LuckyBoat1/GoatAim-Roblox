-- RefinerSystem: rank-gated refiners that generate loot boxes over time.
-- RemoteEvent for loot box progress bar updates
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RemoteEvents = RS:FindFirstChild("RemoteEvents")
if not RemoteEvents then
    RemoteEvents = Instance.new("Folder")
    RemoteEvents.Name = "RemoteEvents"
    RemoteEvents.Parent = RS
end

local RefinerProgressRE = RemoteEvents:FindFirstChild("RefinerProgress") or Instance.new("RemoteEvent")
RefinerProgressRE.Name = "RefinerProgress"
RefinerProgressRE.Parent = RemoteEvents

-- New RemoteEvent for refiner info (client UI)
local RefinerInfoRE = RemoteEvents:FindFirstChild("RefinerInfo") or Instance.new("RemoteEvent")
RefinerInfoRE.Name = "RefinerInfo"
RefinerInfoRE.Parent = RemoteEvents

-- RemoteEvent for collecting completed loot boxes
local RefinerCollectRE = RemoteEvents:FindFirstChild("RefinerCollect") or Instance.new("RemoteEvent")
RefinerCollectRE.Name = "RefinerCollect"
RefinerCollectRE.Parent = RemoteEvents
-- Refiner prices and upgrade logic
local RefinerPrices = {
    [1] = 25000,
    [2] = 100000,
    [3] = 500000,
    [4] = 2000000,
}
local MAX_UPGRADE = 5
local BoxChances = {
    BASIC = 0.5,
    BRONZE = 0.2,
    SILVER = 0.15,
    GOLD = 0.1,
    OMEGA = 0.05,
}

-- Duration (in seconds) for one refiner cycle. Adjust freely.
-- For production you might want 24 * 60 * 60 (one day).
local REFINE_DURATION = 24 * 60 * 60 -- 24 hours

local function getRefinerPrice(index, upgradeLevel)
    local base = RefinerPrices[index] or 25000
    return base * (2 ^ (upgradeLevel or 0))
end

local function getUpgradeLevel(inst)
    if not inst:GetAttribute("UpgradeLevel") then 
        inst:SetAttribute("UpgradeLevel", 0) 
    end
    return inst:GetAttribute("UpgradeLevel")
end

local function upgradeRefiner(inst)
    local lvl = getUpgradeLevel(inst)
    if lvl < MAX_UPGRADE then
        inst:SetAttribute("UpgradeLevel", lvl + 1)
        print("Upgraded", inst.Name, "to level", lvl + 1)
        return true
    end
    return false
end

local function pickBoxType()
    local r = math.random()
    local acc = 0
    for box, chance in pairs(BoxChances) do
        acc = acc + chance
        if r <= acc then return box end
    end
    return "BASIC"
end

local LastBoxTimes = {} -- [plr.UserId][refinerName] = os.time()
local RefinerProgress = {} -- [plr.UserId][refinerName] = {startTime, duration, active}

local ACTIVATION_RADIUS = 14
-- Folder name to store player refiner progress
local PROGRESS_FOLDER_NAME = "RefinerProgress"

-- Get or create a BoolValue to track if a player has unlocked a specific refiner
local function getProgress(plr, refinerId)
    if not plr or not plr:IsDescendantOf(game.Players) then return nil end
    local progressFolder = plr:FindFirstChild(PROGRESS_FOLDER_NAME)
    if not progressFolder then
        progressFolder = Instance.new("Folder")
        progressFolder.Name = PROGRESS_FOLDER_NAME
        progressFolder.Parent = plr
    end
    local refinerFlag = progressFolder:FindFirstChild(refinerId)
    if not refinerFlag then
        refinerFlag = Instance.new("BoolValue")
        refinerFlag.Name = refinerId
        refinerFlag.Value = false
        refinerFlag.Parent = progressFolder
    end
    return refinerFlag
end

-- Send refiner info to a specific player
local function sendRefinerInfo(plr)
    local refinersFolder = workspace:FindFirstChild("Refiners")
    if not refinersFolder then return end
    
    local pdata = _G.getData and _G.getData(plr)
    if not pdata then return end
    
    local refinerData = {}
    
    for _, inst in ipairs(refinersFolder:GetChildren()) do
        local requiredRank = tonumber(inst.Name:match("%d+$")) or 1
        local upgradeLevel = getUpgradeLevel(inst)
        local price = getRefinerPrice(requiredRank, upgradeLevel)
        local progressFlag = getProgress(plr, inst.Name)
        local isOwned = progressFlag.Value
        
        -- Check if refiner has active progress
        local progress = RefinerProgress[plr.UserId] and RefinerProgress[plr.UserId][inst.Name]
    local isActive = false
    local timeAccum = 0
    local interval = REFINE_DURATION
        
        if progress and progress.active then
            local elapsed = os.time() - progress.startTime
            if elapsed < progress.duration then
                isActive = true
                timeAccum = elapsed
                interval = progress.duration
            else
                -- Refiner finished, grant loot box
                local boxType = pickBoxType()
                if _G.GrantBox then
                    _G.GrantBox(plr, boxType, 1)
                    print("Granted", boxType, "box to", plr.Name, "from refiner", inst.Name)
                else
                    warn("_G.GrantBox function not available!")
                end
                RefinerProgress[plr.UserId][inst.Name].active = false
                LastBoxTimes[plr.UserId] = LastBoxTimes[plr.UserId] or {}
                LastBoxTimes[plr.UserId][inst.Name] = os.time()
            end
        end
        
        table.insert(refinerData, {
            id = inst.Name,
            tier = "T" .. tostring(requiredRank),
            req = requiredRank,
            manualUnlocked = isOwned,
            owned = isOwned,
            active = isActive,
            timeAccum = timeAccum,
            interval = interval,
            upgradeLevel = upgradeLevel,
            price = price
        })
    end
    
    RefinerInfoRE:FireClient(plr, {
        type = "snapshot",
        refiners = refinerData,
        rank = pdata.rank or 1
    })
end

-- Create a ProximityPrompt on the refiner model or part if needed
local function ensurePrompt(inst)
    local targetPart = nil
    if inst:IsA("Model") then
        targetPart = inst.PrimaryPart or inst:FindFirstChildOfClass("BasePart")
    elseif inst:IsA("BasePart") then
        targetPart = inst
    end
    if not targetPart then return end
    
    targetPart.CanCollide = true
    targetPart.Transparency = 0
    
    -- Add cool visual effects to the refiner part
    local function addVisualEffects()
        -- Add subtle glow effect
        local pointLight = targetPart:FindFirstChild("RefinerLight") or Instance.new("PointLight")
        pointLight.Name = "RefinerLight"
        pointLight.Brightness = 0.8
        pointLight.Range = 8
        pointLight.Color = Color3.fromRGB(100, 200, 255)
        pointLight.Parent = targetPart
        
        -- Add floating orb effect
        local orb = targetPart:FindFirstChild("FloatingOrb")
        if not orb then
            orb = Instance.new("Part")
            orb.Name = "FloatingOrb"
            orb.Shape = Enum.PartType.Ball
            orb.Size = Vector3.new(0.5, 0.5, 0.5)
            orb.Position = targetPart.Position + Vector3.new(0, 3, 0)
            orb.Anchored = true
            orb.CanCollide = false
            orb.Material = Enum.Material.ForceField
            orb.BrickColor = BrickColor.new("Cyan")
            orb.TopSurface = Enum.SurfaceType.Smooth
            orb.BottomSurface = Enum.SurfaceType.Smooth
            orb.Parent = workspace
            
            -- Add orb light
            local orbLight = Instance.new("PointLight")
            orbLight.Brightness = 2
            orbLight.Range = 6
            orbLight.Color = Color3.fromRGB(0, 200, 255)
            orbLight.Parent = orb
            
            -- Animate floating orb
            spawn(function()
                local startPos = orb.Position
                while orb and orb.Parent do
                    local time = tick() * 2
                    orb.Position = startPos + Vector3.new(
                        math.sin(time) * 1.5,
                        math.sin(time * 1.3) * 0.8 + 1,
                        math.cos(time * 0.7) * 1.2
                    )
                    orb.Rotation = Vector3.new(
                        time * 30,
                        time * 45,
                        time * 20
                    )
                    wait(0.1)
                end
            end)
        end
    end
    
    addVisualEffects()
    
    -- Remove any existing prompt to avoid duplicate events
    for _, child in ipairs(targetPart:GetChildren()) do
        if child:IsA("ProximityPrompt") then
            child:Destroy()
        end
    end
    
    local prompt = Instance.new("ProximityPrompt")
    prompt.ObjectText = "🏭 Refiner"
    prompt.ActionText = "Loading..."
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = ACTIVATION_RADIUS
    prompt.HoldDuration = 0.5
    prompt.Enabled = true
    prompt.Name = "RefinerPrompt"
    prompt.Style = Enum.ProximityPromptStyle.Default
    prompt.Parent = targetPart
    -- Directly connect the event
    prompt.Triggered:Connect(function(plr)
        local parent = prompt.Parent
        if not parent then return end
        local refinerModel = parent:IsA("BasePart") and parent.Parent or parent
        if not refinerModel then return end
        
        local pdata = _G.getData and _G.getData(plr)
        if not pdata then return end
        
        -- Play interaction sound
        local function playServerSound(soundId, volume, pitch)
            spawn(function()
                pcall(function()
                    local sound = Instance.new("Sound")
                    sound.SoundId = soundId
                    sound.Volume = volume or 0.5
                    sound.Pitch = pitch or 1
                    sound.Parent = targetPart
                    sound:Play()
                    sound.Ended:Connect(function()
                        sound:Destroy()
                    end)
                end)
            end)
        end
        
        local requiredRank = tonumber(refinerModel.Name:match("%d+$")) or 1
        local playerRank = pdata.rank or 1
        local upgradeLevel = getUpgradeLevel(refinerModel)
        local price = getRefinerPrice(requiredRank, upgradeLevel)
        local progressFlag = getProgress(plr, refinerModel.Name)
        
        -- Check if player meets rank requirement
        if playerRank < requiredRank then
            -- Player can't use this refiner yet
            print("Player", plr.Name, "needs rank", requiredRank, "but has rank", playerRank)
            playServerSound("rbxasset://sounds/impact_generic_large_02.mp3", 0.3, 0.8)
            return
        end
        
        -- If not owned yet, purchase it
        if not progressFlag.Value then
            if pdata.money >= price then
                pdata.money = pdata.money - price
                progressFlag.Value = true
                refinerModel:SetAttribute("Owner", plr.Name)
                
                print("Player", plr.Name, "purchased refiner", refinerModel.Name, "for", price)
                playServerSound("rbxasset://sounds/impact_generic_large_01.mp3", 0.6, 1.2)
                
                -- Add purchase effects
                local light = targetPart:FindFirstChild("RefinerLight")
                if light then
                    spawn(function()
                        local originalColor = light.Color
                        light.Color = Color3.fromRGB(100, 255, 100)
                        light.Brightness = 2
                        wait(1)
                        light.Color = originalColor
                        light.Brightness = 0.8
                    end)
                end
                
                -- Start refiner progress
                RefinerProgress[plr.UserId] = RefinerProgress[plr.UserId] or {}
                local currentTime = os.time()
                RefinerProgress[plr.UserId][refinerModel.Name] = {
                    startTime = currentTime,
                    duration = REFINE_DURATION,
                    active = true
                }

                print("SERVER: Starting refiner progress for", plr.Name, refinerModel.Name, "at time", currentTime, "duration", REFINE_DURATION)
                
                -- Notify client to start loot box progress bar
                RefinerProgressRE:FireClient(plr, {
                    refiner = refinerModel.Name,
                    duration = REFINE_DURATION,
                    startTime = currentTime,
                })

                print("SERVER: Sent progress data to client - startTime:", currentTime, "duration:", REFINE_DURATION)
                
                -- Send immediate update to client
                sendRefinerInfo(plr)
            else
                print("Player", plr.Name, "cannot afford refiner", refinerModel.Name, "- needs", price, "has", pdata.money)
                playServerSound("rbxasset://sounds/impact_generic_large_02.mp3", 0.4, 0.7)
            end
        else
            -- If owned, always send current progress info so UI can slide in
            do
                RefinerProgress[plr.UserId] = RefinerProgress[plr.UserId] or {}
                local state = RefinerProgress[plr.UserId][refinerModel.Name]
                if state and state.active then
                    RefinerProgressRE:FireClient(plr, {
                        refiner = refinerModel.Name,
                        duration = state.duration or REFINE_DURATION,
                        startTime = state.startTime or os.time(),
                    })
                end
            end
            -- If owned, try to upgrade
            if upgradeLevel < MAX_UPGRADE then
                if pdata.money >= price then
                    pdata.money = pdata.money - price
                    upgradeRefiner(refinerModel)
                    print("Player", plr.Name, "upgraded refiner", refinerModel.Name, "for", price)
                    playServerSound("rbxasset://sounds/impact_generic_medium_01.mp3", 0.5, 1.4)
                    
                    -- Add upgrade effects
                    local light = targetPart:FindFirstChild("RefinerLight")
                    if light then
                        spawn(function()
                            local originalBrightness = light.Brightness
                            for i = 1, 3 do
                                light.Brightness = 3
                                light.Color = Color3.fromRGB(255, 200, 100)
                                wait(0.2)
                                light.Brightness = originalBrightness
                                light.Color = Color3.fromRGB(100, 200, 255)
                                wait(0.2)
                            end
                        end)
                    end
                    
                    -- Send immediate update to client
                    sendRefinerInfo(plr)
                else
                    print("Player", plr.Name, "cannot afford upgrade for", refinerModel.Name, "- needs", price, "has", pdata.money)
                    playServerSound("rbxasset://sounds/impact_generic_large_02.mp3", 0.4, 0.7)
                end
            else
                print("Player", plr.Name, "tried to upgrade max level refiner", refinerModel.Name)
                playServerSound("rbxasset://sounds/impact_generic_large_02.mp3", 0.3, 0.6)
            end
        end
    end)
    return prompt
end

-- Send refiner info to all players
local function broadcastRefinerInfo()
    for _, plr in ipairs(Players:GetPlayers()) do
        sendRefinerInfo(plr)
    end
end

-- Initial setup: create prompts for all refiners
local function setupAllRefiners()
    local refinersFolder = workspace:FindFirstChild("Refiners")
    if not refinersFolder then return end

    for _, inst in ipairs(refinersFolder:GetChildren()) do
        local refinerName = inst.Name
        local req = tonumber(refinerName:match("%d+$")) or 1
        wait(0.1)
        print("Refiner:", refinerName, "Required Rank:", req)
        ensurePrompt(inst)
    end
end

setupAllRefiners()

-- Update prompts and send client updates
local function updateRefinerPrompts()
    local refinersFolder = workspace:FindFirstChild("Refiners")
    if not refinersFolder then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        local pdata = _G.getData and _G.getData(plr)
        if not pdata then continue end
        
        local playerRank = pdata.rank or 1
        
        for _, inst in ipairs(refinersFolder:GetChildren()) do
            local req = tonumber(inst.Name:match("%d+$")) or 1
            local canUse = playerRank >= req
            local upgradeLevel = getUpgradeLevel(inst)
            local price = getRefinerPrice(req, upgradeLevel)
            local progressFlag = getProgress(plr, inst.Name)
            local isOwned = progressFlag.Value
            
            inst:SetAttribute("Price", price)
            
            -- Set transparency and lighting based on access
            local transparency = canUse and 0 or 0.7
            local light = inst:FindFirstChild("RefinerLight")
            
            for _, part in ipairs(inst:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    part.Transparency = transparency
                end
                if part:IsA("BasePart") then
                    local prompt = part:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        -- Only show prompt if player can interact
                        prompt.Enabled = canUse
                        
                        if not canUse then
                            prompt.ActionText = "🔒 Locked (Rank " .. req .. ")"
                            prompt.Enabled = false
                            -- Dim the light for locked refiners
                            if light then
                                light.Brightness = 0.3
                                light.Color = Color3.fromRGB(150, 150, 150)
                            end
                        elseif not isOwned then
                            prompt.ActionText = string.format("💰 Purchase $%s", price)
                            prompt.Enabled = pdata.money >= price
                            -- Yellow light for purchasable refiners
                            if light then
                                light.Brightness = 1.2
                                light.Color = Color3.fromRGB(255, 200, 100)
                            end
                        elseif upgradeLevel < MAX_UPGRADE then
                            prompt.ActionText = string.format("⬆️ Upgrade $%s (Lv.%d)", price, upgradeLevel)
                            prompt.Enabled = pdata.money >= price
                            -- Blue light for upgradeable refiners
                            if light then
                                light.Brightness = 1.0
                                light.Color = Color3.fromRGB(100, 150, 255)
                            end
                        else
                            prompt.ActionText = "⭐ Max Level"
                            prompt.Enabled = false
                            -- Gold light for maxed refiners
                            if light then
                                light.Brightness = 1.5
                                light.Color = Color3.fromRGB(255, 215, 0)
                            end
                        end
                        
                        -- Set prompt colors based on affordability
                        if prompt.Enabled and canUse then
                            if pdata.money >= price then
                                prompt.Style = Enum.ProximityPromptStyle.Default
                            else
                                prompt.Style = Enum.ProximityPromptStyle.Default
                                prompt.ActionText = prompt.ActionText .. " ❌"
                                prompt.Enabled = false
                            end
                        end
                    end
                end
            end
        end
    end
end

setupAllRefiners()

-- Initialize system
print("RefinerSystem: Starting up...")
print("Found RefinerProgress RE:", RefinerProgressRE ~= nil)
print("Found RefinerInfo RE:", RefinerInfoRE ~= nil)
print("Found _G.getData:", _G.getData ~= nil)
print("Found _G.GrantBox:", _G.GrantBox ~= nil)

-- Check for refiners folder
local refinersFolder = workspace:FindFirstChild("Refiners")
if refinersFolder then
    print("Found", #refinersFolder:GetChildren(), "refiners in workspace")
else
    warn("No Refiners folder found in workspace!")
end

-- Runtime system: update prompts and broadcast info periodically
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastUpdate > 1 then -- Only update once per second
        lastUpdate = now
        updateRefinerPrompts()
    end
end)

-- Send refiner info every few seconds
spawn(function()
    while true do
        wait(2) -- Update every 2 seconds
        broadcastRefinerInfo()
    end
end)

-- Handle new players
Players.PlayerAdded:Connect(function(plr)
    wait(1) -- Give time for player data to load
    sendRefinerInfo(plr)
    -- If player has any active refiner progress, send progress packets so client shows bar immediately
    local refFolder = workspace:FindFirstChild("Refiners")
    if refFolder then
        for _, inst in ipairs(refFolder:GetChildren()) do
            local state = RefinerProgress[plr.UserId] and RefinerProgress[plr.UserId][inst.Name]
            if state and state.active then
                RefinerProgressRE:FireClient(plr, {
                    refiner = inst.Name,
                    duration = state.duration or REFINE_DURATION,
                    startTime = state.startTime or os.time(),
                })
            end
        end
    end
end)

-- Handle loot box collection when refiner completes
RefinerCollectRE.OnServerEvent:Connect(function(plr, refinerName)
    if not refinerName or refinerName == "" then
        warn("Invalid refiner name for collection:", refinerName)
        return
    end
    
    print("Player", plr.Name, "collecting loot from refiner:", refinerName)
    
    -- Find the refiner part
    local refiner = workspace:FindFirstChild("Refiners")
    if refiner then
        refiner = refiner:FindFirstChild(refinerName)
    end
    
    if not refiner then
        warn("Refiner not found for collection:", refinerName)
        return
    end
    
    -- Check if player owns this refiner
    if refiner:GetAttribute("Owner") ~= plr.Name then
        warn("Player", plr.Name, "tried to collect from refiner owned by", refiner:GetAttribute("Owner"))
        return
    end
    
    -- Generate loot box based on refiner level and box chances
    local upgradeLevel = getUpgradeLevel(refiner)
    local boxTypes = {"BASIC", "BRONZE", "SILVER", "GOLD", "OMEGA"}
    local totalWeight = 0
    local weights = {}
    
    -- Calculate weights based on upgrade level (higher levels = better boxes)
    for i, boxType in ipairs(boxTypes) do
        local baseChance = BoxChances[boxType] or 0
        local levelMultiplier = 1 + (upgradeLevel * 0.1) -- Each level adds 10% better chance
        local adjustedChance = baseChance * levelMultiplier
        
        -- Higher levels get better boxes
        if i <= upgradeLevel + 2 then -- Can get boxes up to 2 tiers above current level
            weights[boxType] = adjustedChance
            totalWeight = totalWeight + adjustedChance
        end
    end
    
    -- Pick a random box type
    local random = math.random() * totalWeight
    local selectedBoxType = "BASIC" -- Default fallback
    
    for boxType, weight in pairs(weights) do
        if random <= weight then
            selectedBoxType = boxType
            break
        end
        random = random - weight
    end
    
    -- Grant the loot box to the player
    if _G.GrantBox then
        _G.GrantBox(plr, selectedBoxType, 1)
        print("Granted", selectedBoxType, "loot box to", plr.Name, "from refiner", refinerName)
        
        -- Send notification to client
        local NotificationRE = RemoteEvents:FindFirstChild("RefinerNotification")
        if NotificationRE then
            NotificationRE:FireClient(plr, {
                text = "Refiner Complete! Received " .. selectedBoxType .. " loot box!",
                color = Color3.fromRGB(100, 255, 100)
            })
        end
    else
        warn("_G.GrantBox function not available - cannot grant loot box")
    end
    
    -- Reset refiner's last collection time to prevent immediate re-collection
    refiner:SetAttribute("LastCollection", os.time())
    
    -- Update client with new refiner info
    sendRefinerInfo(plr)
end)

-- Handle player interaction with proximity prompt
workspace.DescendantAdded:Connect(function(desc)
    -- No longer needed: event is now connected directly in ensurePrompt
end)
