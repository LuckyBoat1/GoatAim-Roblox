local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Core references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load modules
local SkinConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SkinConfig"))
local CrateConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CrateConfig"))
local MythicEffects = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MythicEffects"))
local LegendaryAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LegendaryAura"))
local EpicAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EpicAura"))
local RareAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RareAura"))
local CommonAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CommonAura"))

-- Color shortcuts
local function C3(r,g,b) return Color3.fromRGB(r,g,b) end
local GREEN, BRIGHT_GREEN, DIM_GREEN = C3(0,200,100), C3(50,255,130), C3(0,150,80)
local GOLD, BLACK = C3(255,215,0), C3(6,8,10)

-- Matrix rain cleanup function storage
local rainCleanup = nil
local BLOOD_RED = C3(220, 20, 40)  -- Blood red color for mythic items

-- Core constants
local SLOT_FIT_FACTOR = 0.80
local SLOT_MIN_DIST = 2
local ITEM_FIT_FACTOR = 0.80
local ITEM_MIN_DIST = 2

-- Check if an item is a crate
local function isCrate(itemName)
    if not CrateConfig then return false end
    local crates = CrateConfig.GetAllCrates()
    for crateType, _ in pairs(crates) do
        if itemName == crateType then return true end
    end
    return false
end

-- Remote functions
local GetPlayerData = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("GetPlayerData")
local EquipSkinRemote = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("EquipSkin")

-- Setup GUI
if playerGui:FindFirstChild("MatrixVault") then playerGui.MatrixVault:Destroy() end
for _, v in ipairs(Lighting:GetChildren()) do if v.Name=="VaultBlur" then v:Destroy() end end
pcall(function() ContextActionService:UnbindAction("ToggleMatrixVault") end)
pcall(function() ContextActionService:UnbindAction("CloseMatrixVault") end)

local gui = Instance.new("ScreenGui")
gui.Name = "MatrixVault"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local blur = Instance.new("BlurEffect"); blur.Name="VaultBlur"; blur.Size=0; blur.Parent=Lighting

local backdrop = Instance.new("TextButton")
backdrop.Name="Backdrop"; backdrop.Size=UDim2.fromScale(1,1); backdrop.BackgroundColor3=BLACK
backdrop.BackgroundTransparency=1; backdrop.TextTransparency=1; backdrop.AutoButtonColor=false
backdrop.Visible=false; backdrop.Parent=gui

local main = Instance.new("Frame")
main.Name="MainPanel"; main.Size=UDim2.fromOffset(0,0); main.Position=UDim2.fromScale(0.5,0.5); main.AnchorPoint=Vector2.new(0.5,0.5)
main.BackgroundColor3=BLACK; main.BorderSizePixel=0; main.Visible=false; main.ClipsDescendants=false; main.Parent=gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,16)
local mainStroke = Instance.new("UIStroke", main); mainStroke.Color=GREEN; mainStroke.Thickness=2
-- Scale entire inventory by 15% larger
local mainScale = Instance.new("UIScale", main)
mainScale.Scale = 1.15

-- Header
local header = Instance.new("Frame"); header.Size=UDim2.new(1,0,0,60); header.BackgroundColor3=C3(10,15,12); header.BackgroundTransparency=0.2; header.Parent=main
Instance.new("UICorner", header).CornerRadius=UDim.new(0,12)
local title = Instance.new("TextLabel")
title.Size=UDim2.new(1,-20,1,0); title.Position=UDim2.new(0,20,0,0); title.BackgroundTransparency=1
title.Font=Enum.Font.FredokaOne; title.Text="VAULT"; title.TextSize=28; title.TextColor3=GREEN; title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=header

local closeBtn = Instance.new("TextButton")
closeBtn.Size=UDim2.fromOffset(40,40); closeBtn.Position=UDim2.new(1,-20,0.5,0); closeBtn.AnchorPoint=Vector2.new(1,0.5)
closeBtn.BackgroundColor3=C3(20,30,25); closeBtn.BackgroundTransparency=0.2; closeBtn.Text="X"; closeBtn.TextColor3=GREEN; closeBtn.TextSize=20; closeBtn.Font=Enum.Font.FredokaOne; closeBtn.Parent=header
Instance.new("UICorner", closeBtn).CornerRadius=UDim.new(0,8)

-- Data fetching
local currentSearchTerm = ""
local currentSortMode = "alphabetical" -- "alphabetical" or "rarity"
local playerData = nil -- Cache for player data

local function fetchData()
    if not GetPlayerData then return nil end
    local ok, d = pcall(function() return GetPlayerData:InvokeServer() end)
    if ok and type(d) == "table" then 
        playerData = d
        return d 
    end
    return nil
end

-- Format time helper
local function fmtTime(ts)
    if not ts or ts==0 then return "-" end
    local dt = DateTime.fromUnixTimestamp(ts):ToLocalTime()
    return dt:FormatUniversalTime("YYYY-MM-DD HH:mm:ss","en-us")
end

-- Skin access and metadata
local function getSkinInstance(name)
    if isCrate(name) then
        local cratesFolder = ReplicatedStorage:FindFirstChild("Crates")
        if cratesFolder then
            -- Try to find by modelName from config first
            if CrateConfig then
                local crateData = CrateConfig.GetCrate(name)
                if crateData and crateData.modelName then
                    local model = cratesFolder:FindFirstChild(crateData.modelName)
                    if model then return model end
                end
            end
            -- Fallback to name
            return cratesFolder:FindFirstChild(name)
        end
        return nil
    end
    
    local lib = ReplicatedStorage:FindFirstChild("SkinLibrary")
    if not lib then return nil end
    
    return lib:FindFirstChild(name, true)
end

-- Get skin metadata from SkinConfig
local function getSkinMeta(skinName)
    if not SkinConfig then return nil end
    return SkinConfig.GetSkinMeta(skinName)
end

-- Get skin rarity (1-5 scale: common=1, rare=2, epic=3, legendary=4, mythic=5)
local function getSkinRarity(skinName)
    -- Check if it's a crate
    if isCrate(skinName) then
        local crates = CrateConfig.GetAllCrates()
        local crate = crates[skinName]
        if crate then
            local r = (crate.rarity or "common"):lower()
            local rarityMap = {common=1, uncommon=1, rare=2, epic=3, legendary=4, mythic=5}
            return rarityMap[r] or 1
        end
    end

    if not SkinConfig then return 1 end
    local meta = SkinConfig.GetSkinMeta(skinName)
    if not meta then return 1 end
    
    local rarity = (meta.rarity or "common"):lower()
    local rarityMap = {common=1, rare=2, epic=3, legendary=4, mythic=5}
    return rarityMap[rarity] or 1
end

-- EQUIP: helpers
local function findPreferredTool(skinName)
    local char = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")
    if char then
        local same = char:FindFirstChild(skinName)
        if same and same:IsA("Tool") then return same end
        for _, ch in ipairs(char:GetChildren()) do
            if ch:IsA("Tool") then return ch end
        end
    end
    if backpack then
        local same = backpack:FindFirstChild(skinName)
        if same and same:IsA("Tool") then return same end
        for _, ch in ipairs(backpack:GetChildren()) do
            if ch:IsA("Tool") then return ch end
        end
    end
    return nil
end

local function equipToolLocal(tool)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum:EquipTool(tool) end)
    else
        tool.Parent = char
    end
end

local function equipSkinToTool(skinName)
    local tool = findPreferredTool(skinName)
    if not tool then return false end
    
    pcall(function()
        tool:SetAttribute("SkinId", skinName)
    end)
    
    pcall(function()
        EquipSkinRemote:FireServer({ skinId = skinName, target = "tool", toolName = tool.Name })
    end)
    
    equipToolLocal(tool)
    return true
end

-- Matrix rain effect
local function playOrganicMatrixRain(parent, opts)
    opts = opts or {}
    if not parent then return function() end end

    local zIndex      = opts.zIndex or 12
    local colW        = opts.colWidth or 10
    local gap         = opts.gap or 6
    local baseSize    = opts.textSize or 11
    local color       = opts.color or BRIGHT_GREEN
    local speedMin    = opts.speedMin or 180
    local speedMax    = opts.speedMax or 300
    local spawnMin    = opts.spawnMin or 0.03
    local spawnMax    = opts.spawnMax or 0.08
    local headChance  = opts.headChance or 0.18
    local hexBias     = opts.hexBias or 0.12
    local driftMax    = opts.driftMax or 2

    parent.ClipsDescendants = true

    local fx = Instance.new("Folder")
    fx.Name = "MatrixRainFX"
    fx.Parent = parent

    local alive = true
    local rebuildConn

    local function randGlyph()
        if math.random() < (1-hexBias) then
            return (math.random(1,2) == 1) and "0" or "1"
        else
            return string.format("%X", math.random(0,15))
        end
    end

    local function build()
        for _,c in ipairs(fx:GetChildren()) do c:Destroy() end
        if rebuildConn then rebuildConn:Disconnect(); rebuildConn = nil end
        if not fx.Parent then return end

        local abs = parent.AbsoluteSize
        if abs.X <= 0 or abs.Y <= 0 then
            local hb; hb = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if parent.AbsoluteSize.X > 0 and parent.AbsoluteSize.Y > 0 then hb:Disconnect(); build() end
            end)
            return
        end

        local baseCols = math.max(1, math.floor(abs.X / (colW + gap)))
        local cols = baseCols -- Keep full column density for proper spacing
        local spacing = abs.X / cols -- Spread columns evenly across full width

        for i = 1, cols do
            task.spawn(function()
                local xCenter = (i - 0.5) * spacing -- Evenly distribute across full width
                while alive and fx.Parent do
                    local sizeJitter = math.random(-2, 2)
                    local textSize = math.max(8, baseSize + sizeJitter)
                    local isHead = (math.random() < headChance)
                    local startX = xCenter + math.random(-driftMax, driftMax)
                    local startY = -textSize - math.random(0, 20)
                    local speed = math.random(speedMin, speedMax)
                    local dur = (abs.Y + textSize + 40) / speed

                    local lbl = Instance.new("TextLabel")
                    lbl.BackgroundTransparency = 1
                    lbl.Text = randGlyph()
                    lbl.Font = Enum.Font.GothamMedium
                    lbl.TextColor3 = color
                    lbl.TextSize = textSize
                    lbl.Size = UDim2.fromOffset(textSize + 2, textSize + 2)
                    lbl.Position = UDim2.fromOffset(startX, startY)
                    lbl.ZIndex = zIndex
                    lbl.Active = false -- Don't let rain interfere with mouse events
                    lbl.Parent = fx

                    local baseAlpha = isHead and math.random() * 0.15 or math.random(55, 95) / 100
                    lbl.TextTransparency = baseAlpha
                    
                    -- Enhanced ghost effect for better background rain
                    if math.random() < 0.22 then
                        local ghost = lbl:Clone()
                        ghost.TextTransparency = math.clamp(baseAlpha + 0.25, 0, 0.95)
                        ghost.Position = UDim2.fromOffset(startX + math.random(-2,2), startY - (textSize + 2))
                        ghost.ZIndex = zIndex - 1
                        ghost.Active = false -- Don't let ghost rain interfere with mouse events
                        ghost.Parent = fx
                        local ghostDur = dur * math.random(90, 115) / 100
                        TweenService:Create(ghost, TweenInfo.new(ghostDur, Enum.EasingStyle.Linear), {
                            Position = UDim2.fromOffset(startX + math.random(-1,1), abs.Y + 30),
                            TextTransparency = 1
                        }):Play()
                        Debris:AddItem(ghost, ghostDur + 0.1)
                    end

                    local fall = TweenService:Create(lbl, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                        Position = UDim2.fromOffset(startX + math.random(-1,1), abs.Y + 30),
                        TextTransparency = math.clamp(baseAlpha + 0.55 + math.random() * 0.35, 0, 1)
                    })
                    fall:Play()

                    task.spawn(function()
                        local steps = math.random(1,3)
                        for _=1,steps do
                            task.wait(dur * math.random(15,70)/100)
                            if lbl and lbl.Parent then
                                lbl.TextTransparency = math.clamp((isHead and 0.05 or 0.2) + math.random()*0.6, 0, 1)
                            end
                        end
                    end)

                    Debris:AddItem(lbl, dur + 0.1)
                    -- Further reduced rain density by 50% again while keeping same coverage
                    task.wait(math.random(math.floor(spawnMin*20000), math.floor(spawnMax*20000)) / 1000)
                end
            end)
        end

        local debounce = false
        rebuildConn = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if debounce then return end
            debounce = true
            task.delay(0.08, function()
                debounce = false
                if alive and fx.Parent then build() end
            end)
        end)
    end

    build()

    return function()
        alive = false
        if rebuildConn then rebuildConn:Disconnect() end
        if fx then fx:Destroy() end
    end
end

-- Viewport helpers
local function iterBaseParts(root)
    local t = {}
    if root:IsA("Model") then
        for _,d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then table.insert(t,d) end end
    elseif root:IsA("BasePart") then table.insert(t, root) end
    return t
end

local function getVisualSize(part)
    local size = part.Size
    local sm = part:FindFirstChildOfClass("SpecialMesh")
    if sm then size = Vector3.new(size.X*sm.Scale.X, size.Y*sm.Scale.Y, size.Z*sm.Scale.Z) end
    return size
end

-- setupViewport with fitFactor and minDist
local function setupViewport(vp, source, opts)
    -- List of revolver items to rotate left in small viewport
    local revolverLeftItems = {
    "FireTouch",
    "Alpha Sapphire",
    "Copper",
    "Apple",
    "Bubble",
    "BlackIron",
    "Cheese",
    "Zone",
    "Cube Squared",
    "Spoon",
    "Dreams of Gold",
    "Ali",
    "Engraved",
    "Fabulous",
    "Neon Revolver",
    "Gold",
    "HyperRed",
    "Infiltrator",
    "MSRevolver",
    "McDonald",
    "Atomic Shot",
    "All Seeing",
    "First Shot",
    "Moon Hunter",
    "Warp Shot",
    "Spectrum Six",
    "Thorn Blossom",
    "Revolver",
    "Fate Shot",
    "Desert Wind",
    "Glitter Blast",
    "MVP",
    "Double Tap",
    "LaserBeam",
    "LibertySix",
    "Med Saw",
    "Tech Six",
    "Imperial",
    "Gangster"
    }
    local function normalizeName(name)
        return string.lower((name or ""):gsub("[ %-]", ""))
    end
    local function shouldRotateLeft(name)
        local norm = normalizeName(name)
        for _,v in ipairs(revolverLeftItems) do
            if normalizeName(v) == norm then return true end
        end
        return false
    end
    -- List of items to rotate left in small viewport
    -- Split matched items into 'Up' and 'Me' lists (examples, you can expand as needed)
    local upItems = {
        "ak chaos", "sea bone", "ak jungle", "as val", "copper", "black kite", "carbon ruby", "chaser", "hardscope", "diamond six", "law bringer", "signal blast", "wild west", "handgun", "hot shot", "archer", "stranger", "leaderboard", "life drain", "machine snipe", "makarov", "heavy spin", "overheater", "compact nine", "pocket blast", "pocket mag", "fast heal", "alpine", "swiss guard", "marksman", "tactical boom", "short barrel", "elite marksman", "thunder bolt", "tactical three", "serpent", "vacuum", "controller"
    }
    local meItems = {
        "apple", "bubble", "fire touch alpha sapphire copper", "black iron", "cheese", "zone", "crossbow", "spoon", "just give me my money", "engraved", "fabulous", "neon revolver", "gold", "hyperred", "ms revolver", "mcdonald", "atomic shot", "moon hunter", "first shot", "warp shot", "spectrum six", "fate shot", "desert wind", "glitter blast", "mvp", "laser beam", "liberty six", "emergency surgery"
    }
    local function normalizeName(name)
        return string.lower((name or ""):gsub("[ %-]", ""))
    end
    local function shouldRotateLeft(name)
        local norm = normalizeName(name)
        for _,v in ipairs(upItems) do if norm == v then return true end end
        for _,v in ipairs(meItems) do if norm == v then return true end end
        return false
    end
    opts = opts or {}
    
    -- Tables for different Meshes item categories
    local meshesWepsItems = {"weps1", "weps2"} -- Meshes items that include weps1/weps2
    -- Non-weps Meshes items are any Meshes items not containing weps1/weps2
    
    -- Check item category
    local sourceName = source and source.Name or ""
    local isMeshesSource = string.sub(sourceName, 1, 6) == "Meshes" or sourceName == "beginner's protector" or sourceName == "beginner's protector 2"
    
    local isWepsItem = false
    local isOtherMeshesItem = false
    
    if isMeshesSource then
        -- Check if it's a weps item
        for _, wepsPattern in ipairs(meshesWepsItems) do
            if string.find(sourceName, wepsPattern) then
                isWepsItem = true
                break
            end
        end
        
        -- If it's Meshes but not weps, it's in the "other" category
        if not isWepsItem then
            isOtherMeshesItem = true
        end
    end
    
    -- Check if it's a Goblin item (needs Z-axis rotation)
    -- Also check SkinConfig for isGoblin flag
    local skinMeta = getSkinMeta(sourceName)
    local isGoblinItem = (string.find(sourceName, "Goblin_") ~= nil) or (skinMeta and skinMeta.isGoblin)

    -- Check if it's a renamed Spear item (formerly Meshes/...)
    if skinMeta and skinMeta.weapon == "Spear" and not isGoblinItem then
        isOtherMeshesItem = true
    end
    
    -- Use closer camera for non-weps Meshes items
    local fitFactor = opts.fitFactor or 1.6
    local minDist = opts.minDist or 12
    
    if isOtherMeshesItem then
        -- Remove all safety limits for extreme zoom
        minDist = 0 -- No minimum distance protection
    end

    for _,c in ipairs(vp:GetChildren()) do c:Destroy() end
    local world = Instance.new("WorldModel"); world.Parent = vp
    local cam = Instance.new("Camera"); 
    
    -- Adjust field of view for different item types
    if isOtherMeshesItem then
        if opts.isBigViewport then
            cam.FieldOfView = 20 -- Closer FOV for big viewport Meshes items
        else
            cam.FieldOfView = 12 -- Narrow FOV for small viewport (reduced by 5 from 17)
        end
    elseif isGoblinItem then
        cam.FieldOfView = 65 -- Special FOV for Goblin items (60+5)
    elseif sourceName == "Tactical Boom" then
        cam.FieldOfView = 65 -- Special FOV for Tactical Boom (60+5)
    elseif sourceName == "Chaser" then
        cam.FieldOfView = 60 -- Special FOV for Chaser (55+5)
    elseif sourceName == "Retro Pixel" or sourceName == "Sphere Strike" or sourceName == "Default" or sourceName == "Warning Strike" or 
           sourceName == "Mac Attack" or sourceName == "Prism Edge" or sourceName == "Cash" or
           sourceName == "Sharp" or sourceName == "Whity" or sourceName == "Sight" or sourceName == "Jaz" or
           sourceName == "Somber" or sourceName == "Cool" or sourceName == "Poison" or sourceName == "Shade" or
           sourceName == "Sugar Swag" or sourceName == "Retro Pixel" or sourceName == "Sphere Strike" or sourceName == "Default" or
           sourceName == "Warning Strike" or sourceName == "Walking Stick" or sourceName == "Mac Attack" or sourceName == "Butcher" or
           sourceName == "Prism Edge" then
        cam.FieldOfView = 60 -- Special FOV for rotated blade items (55+5)
    elseif sourceName == "Chroma" then
        cam.FieldOfView = 60 -- Special FOV for Chroma (55+5)
    elseif sourceName == "Rainbow Bite" then
        cam.FieldOfView = 65 -- Special FOV for Rainbow Bite (80+5)
    elseif sourceName == "Viper Tooth" then
        cam.FieldOfView = 65 -- Special FOV for Viper Tooth (80+5)
    elseif sourceName == "Flame" then
        cam.FieldOfView = 84 -- Special FOV for Flame (75+5)
    elseif sourceName == "Hardscope" or sourceName == "Demon" or sourceName == "Biggie" or sourceName == "Medievel Sword" or
           sourceName == "Titan Smash" or sourceName == "Tracker" or sourceName == "Freedom" or sourceName == "Omega" or
           sourceName == "Backup" or sourceName == "Desert Wind" or
           sourceName == "Rocket Launcher" or sourceName == "Dark Samurai" or sourceName == "Burner" or sourceName == "Shadow Strike" then
        cam.FieldOfView = 60 -- FOV 60 for these items (was 55)
    elseif sourceName == "Ego" or sourceName == "Power" or sourceName == "Blizzard" then
        cam.FieldOfView = 35 -- Special FOV for Ego, Ultimate, and Blizzard
    elseif sourceName == "Flash" then
        cam.FieldOfView = 43 -- Special FOV for Flash (38+5)
    elseif sourceName == "UltraZooka" then
        cam.FieldOfView = 65 -- FOV 65 for UltraZooka
    elseif sourceName == "Hotdog" then
        cam.FieldOfView = 65 -- FOV 60 for Hotdog
    elseif sourceName == "Pow" then
        cam.FieldOfView = 55 -- FOV 50 for Pow
    elseif sourceName == "Back Blast" then
        cam.FieldOfView = 55 -- FOV 50 for Back Blast
    elseif sourceName == "Skull Basher" then
        cam.FieldOfView = 65 -- FOV 50 for Skull Basher
    elseif sourceName == "Bye" then
        cam.FieldOfView = 65 -- FOV 65 for Bye
    elseif sourceName == "Piano" then
        cam.FieldOfView = 60 -- FOV 45 for Piano
    elseif sourceName == "Caveman" then
        cam.FieldOfView = 70 -- FOV 55 for Caveman
    elseif sourceName == "Caveman Gone Wrong" then
        cam.FieldOfView = 70 -- FOV 50 for Caveman Gone Wrong
    elseif sourceName == "Walking Stick" then
        cam.FieldOfView = 60 -- FOV 55 for Walking Stick
    elseif sourceName == "Butcher" then
        cam.FieldOfView = 65 -- FOV 50 for Butcher
    elseif sourceName == "conch" then
        cam.FieldOfView = 60 -- FOV 50 for conch
    elseif sourceName == "Biggie" then
        cam.FieldOfView = 60 -- FOV 60 for Biggie
    elseif sourceName == "Balanced" then
        cam.FieldOfView = 55 -- FOV 50 for Balanced
    elseif sourceName == "Quick Exit" then
        cam.FieldOfView = 60 -- FOV 50 for Quick Exit
    elseif sourceName == "Medievel Sword" then
        cam.FieldOfView = 65 -- FOV 65 for Medievel Sword
    elseif sourceName == "Bulky" then
        cam.FieldOfView = 60 -- FOV 60 for Bulky
    elseif sourceName == "Shovel" then
        cam.FieldOfView = 65 -- FOV 50 for Shovel
    elseif sourceName == "Titan Smash" then
        cam.FieldOfView = 70 -- FOV 65 for Titan Smash
    elseif sourceName == "Sky Rocket" then
        cam.FieldOfView = 65 -- FOV 65 for Sky Rocket
    elseif sourceName == "Freedom" then
        cam.FieldOfView = 65 -- FOV 65 for Freedom
    elseif sourceName == "Royal Guard" then
        cam.FieldOfView = 65 -- FOV 50 for Royal Guard
    elseif sourceName == "Handgun" then
        cam.FieldOfView = 55 -- FOV 55 for Handgun
    elseif sourceName == "Pretty Gun" then
        cam.FieldOfView = 40 -- FOV 40 for Pretty Gun
    elseif sourceName == "Backup" then
        cam.FieldOfView = 60 -- FOV 55 for Backup
    elseif sourceName == "Rocket Launcher" then
        cam.FieldOfView = 55 -- FOV 55 for Rocket Launcher
    elseif sourceName == "Quick Shot" then
        cam.FieldOfView = 55 -- FOV 55 for Quick Shot
    elseif sourceName == "Holy Fire" then
        cam.FieldOfView = 65 -- FOV 60 for Holy Fire
    elseif sourceName == "Solar Staff" then
        cam.FieldOfView = 65 -- FOV 60 for Solar Staff
    elseif sourceName == "Side Arm" then
        cam.FieldOfView = 45 -- FOV 35 for Side Arm
    elseif sourceName == "Burner" then
        cam.FieldOfView = 65 -- FOV 50 for Burner
    elseif sourceName == "Lash" then
        cam.FieldOfView = 65 -- FOV 50 for Lash
    elseif sourceName == "Shadow Strike" then
        cam.FieldOfView = 65 -- FOV 50 for Shadow Strike
    elseif sourceName == "Dark Samurai" then
        cam.FieldOfView = 65 -- FOV 65 for Dark Samurai--
    elseif sourceName == "Viper Tooth" or sourceName == "Rainbow Bite" then
        cam.FieldOfView = 70 -- Special FOV for Viper Tooth and Rainbow Bite (65+5)
    elseif sourceName == "casoh" or 
           sourceName == "Blood Rush" or sourceName == "Highland" or
           sourceName == "Astroid" or sourceName == "Doom" or sourceName == "Twin Boom" or
           sourceName == "Prism Edge" or
           sourceName == "Hook" or sourceName == "Wolf Cry" or
           sourceName == "Grenade" or sourceName == "Classic Jumper" or
           sourceName == "Cannon Ball" or sourceName == "Wild Shot" or
           sourceName == "Mid" or sourceName == "Omega" or sourceName == "Classic Rocket" or
           sourceName == "Panic Button" or sourceName == "Red Jewel" or sourceName == "Sharp" or
           sourceName == "Fire Strike" or sourceName == "Bone Slicer" or sourceName == "War" then
        cam.FieldOfView = 65 -- Special FOV for these items (55+5)
    elseif sourceName == "Quick Exit" then
        cam.FieldOfView = 55 -- FOV 55 for Quick Exit (50+5)0+5)
    elseif sourceName == "Ginger Man" or sourceName == "Lime Shot" or
           sourceName == "Classic Gun" or sourceName == "Scarlet Shot" then
        cam.FieldOfView = 35 -- FOV 45 for these items (40+5)
    elseif sourceName == "Pixel" then
        cam.FieldOfView = 8 -- FOV 40 for Pixel (35+5)
    elseif sourceName == "Blueberry" or sourceName == "Work" or
           sourceName == "Frozen Fang" or sourceName == "Sunset Vision" or
           sourceName == "Mystic Vision" or sourceName == "Blood Vision" or
           sourceName == "Vision Blade" or sourceName == "Golden Vision" then
        cam.FieldOfView = 25 -- FOV 40 for these items (35+5)
    elseif sourceName == "Ocean Hunter" then
        cam.FieldOfView = 50 -- FOV 40 for Ocean Hunter (35+5)
    elseif sourceName == "Ocean Wave" then
        cam.FieldOfView = 30 -- FOV 40 for Ocean Wave (35+5)
    elseif sourceName == "Cyber Strike" then
        cam.FieldOfView = 35 -- FOV 75 for Cyber Strike (70+5)
    elseif sourceName == "Spooky Edge" or sourceName == "Ghost Blade" or
           sourceName == "Crimson Ghost" then
        cam.FieldOfView = 45 -- FOV 80 for these items (75+5)
    elseif sourceName == "Crystal Cold" or sourceName == "Winter Crystal" or sourceName == "Holiday Cheer" then
        cam.FieldOfView = 38 -- FOV 80 for these items (75+5)
    elseif sourceName == "Frost Fury" then
        cam.FieldOfView = 45 -- FOV 80 for Frost Fury (75+5)
    elseif sourceName == "Carpenter" or sourceName == "Patriot" then
        cam.FieldOfView = 42 -- FOV 80 for Carpenter and Patriot (75+5)
    elseif sourceName == "Midnight" or sourceName == "Halloween King" then
        cam.FieldOfView = 50 -- FOV 80 for Midnight and Halloween King (75+5)
    elseif sourceName == "Buzz Cut" then
        cam.FieldOfView = 45 -- FOV 80 for Buzz Cut (75+5)
    elseif sourceName == "Web Weaver" then
        cam.FieldOfView = 40 -- FOV 80 for Web Weaver (75+5)
    elseif sourceName == "Ultimate Frost" then
        cam.FieldOfView = 45 -- FOV 80 for Ultimate Frost (75+5)
    elseif sourceName == "Horror" then
        cam.FieldOfView = 50 -- FOV 80 for Horror (75+5)
    elseif sourceName == "Shark Bite" or sourceName == "Black Matter" or
           sourceName == "Happy Hour" or sourceName == "Cookie Cutter" then
        cam.FieldOfView = 33 -- FOV 65 for Shark Bite/Cookie Cutter items (60+5)
    elseif sourceName == "Forever Edge" or sourceName == "Infinite Power" then
        cam.FieldOfView = 53 -- FOV 65 for eternal weapons (60+5)
    elseif sourceName == "Snow Blaster!" or sourceName == "Golden Sweet" or sourceName == "Sweet Tooth" then
        cam.FieldOfView = 28 -- FOV 65 for sugar items (60+5)
    elseif sourceName == "Raven" or sourceName == "Frozen Touch" then
        cam.FieldOfView = 40 -- FOV 65 for these items (60+5)
    elseif sourceName == "trump" or sourceName == "Power Shot" or
           sourceName == "Cyan" or sourceName == "Sweet Strike" or
           sourceName == "Pointy" or sourceName == "Light Beam" then
        cam.FieldOfView = 60 -- FOV 55 for these items (50+5)
    else
        cam.FieldOfView = 60 -- Default field of view (45+5)
    end
    
    cam.Parent=vp; vp.CurrentCamera = cam

    -- Move camera down by 40 units on Y axis for Meshes items in big viewport
    if isOtherMeshesItem and opts.isBigViewport then
        cam.CFrame = cam.CFrame * CFrame.new(0, -40, 0)
    else
        cam.CFrame = cam.CFrame * CFrame.new(0, -20, 0)
    end

    local clone
    if source and (source:IsA("Model") or source:IsA("BasePart")) then
        clone = source:Clone()
    elseif source and source:IsA("Folder") then
        local m=Instance.new("Model"); m.Name=source.Name
        for _,ch in ipairs(source:GetChildren()) do if ch:IsA("Model") or ch:IsA("BasePart") then ch:Clone().Parent=m end end
        clone=m
    else
        local p=Instance.new("Part"); p.Size=Vector3.new(4,1,1); p.Material=Enum.Material.Metal; p.Color=Color3.fromRGB(80,80,80)
        local sm = Instance.new("SpecialMesh", p); sm.MeshType=Enum.MeshType.Brick
        clone=p
    end
    clone.Parent = world

    if clone:IsA("Model") then
        if not clone.PrimaryPart then for _,bp in ipairs(iterBaseParts(clone)) do clone.PrimaryPart=bp; break end end
    end
    for _,bp in ipairs(iterBaseParts(clone)) do bp.Anchored=true; bp.CanCollide=false; bp.Massless=true end
    
    -- Simple rotation for specific items in small viewport
    local needsLeftRotation = false
    local needsTestRotation = false
    local needsTest2Rotation = false
    local needsTest3Rotation = false
    local needsSpecialYRotation = false
    local needsSpecialXZRotation = false
    local needsTest4Rotation = false
    local needsTest5Rotation = false
    local needsTest6Rotation = false
    local needsTest7Rotation = false
    local needsTest8Rotation = false
    local needsTest15Rotation = false
    local needsTest16Rotation = false
    local needsTest17Rotation = false
    local needsTest18Rotation = false
    local needsTest19Rotation = false
    local needsTest20Rotation = false
    local needsTest21Rotation = false -- 90° Y only
    local needsTest22Rotation = false -- 90° Z only
    local needsTest23Rotation = false -- 90° Y + 30° Z
    local needsTest24Rotation = false -- 90° Z + -90° X
    local needsTest25Rotation = false -- 30° X only
    local needsTest26Rotation = false -- 90° Y only
    local needsTest27Rotation = false -- 180° Y only
    local needsTest28Rotation = false -- 180° Y only
    local needsTest29Rotation = false -- 90° X + 180° Z
    local needsTest30Rotation = false -- 270° Z only
    local needsTest31Rotation = false -- 90° X only
    local needsTest32Rotation = false -- 90° Z + 90° X
    local needsTest33Rotation = false -- 180° X
    local needsTest34Rotation = false -- -90° X
    local needsTest35Rotation = false -- 90° X + 90° Z
    local needsTest36Rotation = false -- 90° Z + 90° X
    local needsTest37Rotation = false -- 90° X only
    local needsTest38Rotation = false -- 90° Y + 90° Z
    local needsTest39Rotation = false -- -90° Z (rotate left)
    local needsTest40Rotation = false -- -90° Z (rotate left) for Prism Edge & Cannon Ball
    local needsTest41Rotation = false -- 90° Y for 111 items (excluding Deathshard and Winter's Edge)
    local needsTest42Rotation = false -- custom 111 set (90° Z + 180° Y)
    local needsTest43Rotation = false -- custom 111 set (90° Z + 90° Y)
    local needsTest44Rotation = false -- custom 111 set (0° Z + 0° Y)
    local needsTest45Rotation = false -- custom 111 set (placeholder)
    local needsTest46Rotation = false -- custom 111 set (handsaw-only)
    local needsTest47Rotation = false -- Flame only (180° Y)
    local needsTest48Rotation = false -- -90° Y rotation for 123chargin and 123splended
    local needsTest49Rotation = false -- 180° X rotation for 123solemn
    local needsTest50Rotation = false -- Viper Tooth and Rainbow Bite rotation (90° Y)
    local needsChaserRotation = false
    
    -- Apply rotations to both small and big viewport
    -- Check if this item should face left (Z-axis rotation)
    local itemsToRotateLeft = {
            "Fire Touch", "Alpha Sapphire", "Copper", "Apple", 
            "Bubble", "BlackIron Revolver", "Cheese", "Zone",
            "Cube Squared", "Spoon", "Dreams of Gold", "Engraved Revolver",
            "Fabulous Revolver", "Neon Revolver", "Gold Revolver", "HyperRed Revolver",
            "Infiltrator Revolver", "MS Revolver", "McDonald Revolver", "Atomic Shot",
            "All Seeing", "First Shot", "Moon Hunter", "Warp Shot",
            "Spectrum Six", "Thorn Blossom", "Fate Shot", "Desert Wind",
            "Glitter Blast", "MVP", "Double Tap", "Laser Beam",
            "Liberty Six", "Tech Six", "Gangster"
        }
        
        -- Check if this item needs test 1 rotation (-90 Y-axis)
        local testItems = {
            "AK-Chaos", "Sea Bone", "AK-Jungle", "L85", "Makarov", "Pocket Blast", 
            "Elite Marksman", "Swiss Guard", "Soviet Classic", "Serpent", "Thunder Bolt", "Short Barrel",
            "Blood&Bones", "Cyborg", "Death", "Leviathan", "Sun"
        }
        
        -- Check if this item needs test 2 rotation (-90 Z-axis)
        local test2Items = {
            "Fort", "Handgun", "Pocket Mag", 
            "Rocket Rain", "Marksman", "Tactical Boom", "Copper", "Pyranna", "Fishing Rod", "Light Rifle", "Hardscope", 
            "Arrow Launcher", "Diamond Six", "Law Bringer", "Signal Blast", "Wild West", "Hot Shot", "Stranger", 
            "Life Drain", "Machine Snipe", "Heavy Spin", "Overheater", "Fast Heal", "Silent Scope", "Vacuum", "Controller"
        }
        
        -- Check if this item needs special Y-axis rotation (+90 degrees)
        local specialYRotationItems = {
            "LMG AE"
        }
        
        -- Check if this item needs special X and Z rotation (180 degrees each)
        local specialXZRotationItems = {
            "Enfield Bren"
        }
        
        -- Check if this item needs test 4 rotation (-90 degrees on X axis)
        local test4Items = {
            "FN2000", "Compact Nine", "Alpine", "Black kite"
        }
        
        -- Check if this item needs test 5 rotation (90 degrees on X and Y axes)
        local test5Items = {
            "AS-VAL"
        }
        
        -- Check if this item needs test 6 rotation (90 degrees on X, Y, and Z axes)
        local test6Items = {
            -- TRS-301 and Vintorez moved to test23Items
        }
        
        -- Check if this item needs test 7 rotation (-270 degrees on Z axis only)
        local test7Items = {
            "Blizzard", "Power", "Ego"
        }
        
        -- Check if this item needs test 8 rotation (-90 degrees on Y axis only)
        local test8Items = {
            "Blood&Bones", "Cyborg", "Death", "Leviathan", "Sun", "Monster", "Heat"
        }
        
        -- Check if this item needs test 15 rotation (90 degrees on X and 270 degrees on Z axes)
        local test15Items = {
            "Thunder Bolt", "Swiss Guard", "Short Barrel", 
            "Pocket Blast", "Makarov", "L85", "Soviet Classic", "Elite Marksman"
        }
        
        -- Check if this item needs test 16 rotation (90 degrees on X and Z axes)
        local test16Items = {
            "Pocket Mag", "Tactical Boom", "Marksman", "Fort"
        }
        
        -- Check if this item needs test 17 rotation (90 degrees on Z axis only)
        local test17Items = {
            "Just give me my money"
        }
        
        -- Check if this item needs test 18 rotation (90 degrees on Z and 180 degrees on X axes)  
        local test18Items = {
            "Rocket Rain"
        }
        
        -- Check if this item needs test 19 rotation (90 degrees on Z and X axes)
        local test19Items = {
            "Emergency Surgery"
        }
        
        -- Check if this item needs test 20 rotation (180 degrees on Z axis only)
        local test20Items = {
            "Gangster"
        }
        
        -- Check if this item needs test 21 rotation (90° Y only for blade skins - excluding Fang and Chroma Fang)
        local test21Items = {
            "Retro Pixel", "Sphere Strike", "Default", "Warning Strike", "Mac Attack", "Chroma", 
            "Prism Edge", "Cash", "Sharp", "Whity", "Sight", 
            "Jaz", "Somber", "Cool", "Poison", "Shade", "Sugar Swag",
            "Retro Pixel", "Sphere Strike", "Default", "Warning Strike", "Walking Stick", "Mac Attack", "Butcher", "Prism Edge",
            "SAPPHIRE", "RUBY", "Sapphire", "Ruby" -- Added crates (both case variants just in case)
        }
        
        -- Check if this item needs test 22 rotation (90° Z)  
        local test22Items = {
            "Knife"
        }
        
        -- Check if this item needs test 23 rotation (360° Z)
        local test23Items = {
            "MP5"
        }
        
        -- Check if this item needs test 24 rotation (90° Z + -90° X)
        local test24Items = {
            "Med Saw"
        }
        
        -- Check if this item needs test 25 rotation (removed - reverted to original)
        local test25Items = {
            -- Removed LMG AE - reverted to original rotation
        }
        
        -- Check if this item needs test 26 rotation (90° X + 90° Z)
        local test26Items = {
            "Classic Shot"
        }
        
        -- Check if this item needs test 27 rotation (-90° Z only)
        local test27Items = {
            "Tactical Three"
        }
        
        -- Check if this item needs test 28 rotation (180° X + 180° Z)
        local test28Items = {
            "Prototype X"
        }
        
        -- Check if this item needs test 29 rotation (180° Y + 30° Z + 90° X)
        local test29Items = {
            "Imperial"
        }
        
        -- Check if this item needs test 30 rotation (360° X + 90° Z)
        local test30Items = {
            "Heavy Storm"
        }
        
        -- Check if this item needs test 31 rotation (270° Z + 90° X)
        local test31Items = {
            "Sharp Point"
        }
        
        -- Check if this item needs test 32 rotation (90° Z + 90° X)
        local test32Items = {
        }
        
        -- Check if this item needs test 33 rotation (270° Z)
        local test33Items = {
            "Whisper"
        }
        
        -- Check if this item needs test 34 rotation (-90° Z + 90° X)
        local test34Items = {
            "Serpent"
        }
        
        -- Check if this item needs test 35 rotation (90° X + 90° Z)
        local test35Items = {
            "Stinger"
        }
        
        -- Check if this item needs test 36 rotation (90° Z + 90° X)
        local test36Items = {
            "Rapid Shot"
        }
        
        -- Check if this item needs test 37 rotation (15° X + 90° Y + 180° Z - facing left)
        local test37Items = {
        }
        
        -- Check if this item needs test 38 rotation (90° Y + 90° Z)
        local test38Items = {
        }
        
        -- Check if this item needs test 39 rotation (-90° Z - rotate left)
        local test39Items = {
            "UltraZooka", "Pow", "casoh", "Back Blast", "Bye", "Astroid",
            "Biggie", "Butcher", "Medievel Sword", "Bulky", "Grenade", "Sky Rocket",
            "Classic Jumper", "Freedom", "Wild Shot", "Classic Rocket", "Panic Button",
            "Pretty Gun", "Backup", "Rocket Launcher", "Quick Shot", "Guard", "Controller", "Side Arm",
            "Walking Stick"
        }
        
        -- Check if this item needs test 40 rotation (-90° Z - rotate left for Prism Edge & Cannon Ball)
        local test40Items = {
            "Prism Edge", "Cannon Ball"
        }
        
        -- Check if this item needs test 41 rotation (90° Y for many items — excluding the custom 42/43 sets below)
        local test41Items = {
            "trump", "Power Shot", "Cyan", "Sweet Strike",
            "Ginger Man", "Lime Shot", "Knife Box 2 Kit", "Light Beam",
            "Classic Gun", "Patriot", "Scarlet Shot", "Ocean Hunter", "Winter Crystal", "Quick Exit"
        }

        -- Test 42: user's custom set — these should be rotated 180° Y and 90° Z
        local test42Items = {
            "Raven", "Blueberry", "Snow Blaster!", "Shark Bite", "Frozen Touch",
            "Black Matter", "Happy Hour", "Forever Edge", "Infinite Power", "Cookie Cutter",
            "Spooky Edge", "Ghost Blade", "Golden Sweet", "Midnight", "Sunset Vision",
            "Halloween King", "Mystic Vision", "Crimson Ghost", "Blood Vision", "Buzz Cut",
            "Vision Blade", "Horror", "Sweet Tooth", "Cyber Strike", "Golden Vision"
        }

        -- Test 43: user's other set — rotate 90° Y and 90° Z
        local test43Items = {
            "Work", "Crystal Cold", "Pixel",
            "Web Weaver", "Holiday Cheer"
        }

        -- Test 44: small placeholder set — currently no rotation (0,0,0)
        local test44Items = {
            "Ocean Wave", "Frozen Fang", "Frost Fury", "Patriot"
        }

        -- Test 45: user request — Quick Exit (hand saw moved to test46)
        local test45Items = {
            "Quick Exit"
        }

        -- Test 46: handsaw-only list
        local test46Items = {
            "Carpenter"
        }
        
        -- Test 47: Flame only (180° Y rotation)
        local test47Items = {
            "Flame"
        }
        
        -- Test 48: Bull Rush and Grand Strike (-90° Y rotation)
        local test48Items = {
            "Bull Rush", "Grand Strike"
        }
        
        -- Test 49: Holy Fire (180° X rotation)
        local test49Items = {
            "Holy Fire"
        }
        
        -- Test 50: Fang and Chroma Fang (90° Y rotation)
        local test50Items = {
            "Viper Tooth", "Rainbow Bite"
        }
        
        for _, itemName in ipairs(test4Items) do
            if sourceName == itemName then
                needsTest4Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test5Items) do
            if sourceName == itemName then
                needsTest5Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test6Items) do
            if sourceName == itemName then
                needsTest6Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test7Items) do
            if sourceName == itemName then
                needsTest7Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test8Items) do
            if sourceName == itemName then
                needsTest8Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test15Items) do
            if sourceName == itemName then
                needsTest15Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test16Items) do
            if sourceName == itemName then
                needsTest16Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test17Items) do
            if sourceName == itemName then
                needsTest17Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test18Items) do
            if sourceName == itemName then
                needsTest18Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test19Items) do
            if sourceName == itemName then
                needsTest19Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test20Items) do
            if sourceName == itemName then
                needsTest20Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test21Items) do
            if sourceName == itemName then
                needsTest21Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test22Items) do
            if sourceName == itemName then
                needsTest22Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test23Items) do
            if sourceName == itemName then
                needsTest23Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test24Items) do
            if sourceName == itemName then
                needsTest24Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test25Items) do
            if sourceName == itemName then
                needsTest25Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test26Items) do
            if sourceName == itemName then
                needsTest26Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test27Items) do
            if sourceName == itemName then
                needsTest27Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test28Items) do
            if sourceName == itemName then
                needsTest28Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test29Items) do
            if sourceName == itemName then
                needsTest29Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test30Items) do
            if sourceName == itemName then
                needsTest30Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test31Items) do
            if sourceName == itemName then
                needsTest31Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test32Items) do
            if sourceName == itemName then
                needsTest32Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test33Items) do
            if sourceName == itemName then
                needsTest33Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test34Items) do
            if sourceName == itemName then
                needsTest34Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test35Items) do
            if sourceName == itemName then
                needsTest35Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test36Items) do
            if sourceName == itemName then
                needsTest36Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test37Items) do
            if sourceName == itemName then
                needsTest37Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test38Items) do
            if sourceName == itemName then
                needsTest38Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test39Items) do
            if sourceName == itemName then
                needsTest39Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test40Items) do
            if sourceName == itemName then
                needsTest40Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test41Items) do
            if sourceName == itemName then
                needsTest41Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test42Items) do
            if sourceName == itemName then
                needsTest42Rotation = true
                break
            end
        end

        for _, itemName in ipairs(test43Items) do
            if sourceName == itemName then
                needsTest43Rotation = true
                break
            end
        end

        for _, itemName in ipairs(test44Items) do
            if sourceName == itemName then
                needsTest44Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test45Items) do
            if sourceName == itemName then
                needsTest45Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test46Items) do
            if sourceName == itemName then
                needsTest46Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test47Items) do
            if sourceName == itemName then
                needsTest47Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test48Items) do
            if sourceName == itemName then
                needsTest48Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test49Items) do
            if sourceName == itemName then
                needsTest49Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test50Items) do
            if sourceName == itemName then
                needsTest50Rotation = true
                break
            end
        end
        
        -- Check for Chaser specifically
        if sourceName == "Chaser" then
            needsChaserRotation = true
        end
        
        for _, itemName in ipairs(itemsToRotateLeft) do
            if sourceName == itemName then
                needsLeftRotation = true
                break
            end
        end
        
        for _, itemName in ipairs(testItems) do
            if sourceName == itemName then
                needsTestRotation = true
                break
            end
        end
        
        for _, itemName in ipairs(test2Items) do
            if sourceName == itemName then
                needsTest2Rotation = true
                break
            end
        end
        
        for _, itemName in ipairs(specialYRotationItems) do
            if sourceName == itemName then
                needsSpecialYRotation = true
                break
            end
        end
        
        for _, itemName in ipairs(specialXZRotationItems) do
            if sourceName == itemName then
                needsSpecialXZRotation = true
                break
            end
        end
    
    if needsTest4Rotation then
        -- Check if this item needs test 4 rotation (-90 degrees on X axis)
        -- (FN2000, Compact Nine, Alpine, Black kite)
        local test4Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test4Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test4Rotation
        end
    elseif needsTest5Rotation then
        -- Rotate 180 degrees on X axis and 90 degrees on Z axis for test 5 items (AS-VAL)
        local test5Rotation = CFrame.Angles(math.rad(180), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test5Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test5Rotation
        end
    elseif needsTest44Rotation then
        -- Test 44: placeholder rotation (0° Y, 0° Z) for now
        local test44Rotation = CFrame.Angles(math.rad(90), math.rad(-90), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test44Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test44Rotation
        end
    elseif needsTest45Rotation then
        -- Test 45: Quick Exit and Carpenter (placeholder rotation 0° for now)
        local test45Rotation = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test45Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test45Rotation
        end
    elseif needsTest46Rotation then
        -- Test 46: handsaw-only (placeholder rotation 0° for now)
        local test46Rotation = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test46Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test46Rotation
        end
    elseif needsTest47Rotation then
        -- Test 47: Flame only (180° Y rotation)
        local test47Rotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test47Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test47Rotation
        end
    elseif needsTest48Rotation then
        -- Test 48: -90° Y rotation for 123chargin and 123splended
        local test48Rotation = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test48Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test48Rotation
        end
    elseif needsTest49Rotation then
        -- Test 49: 180° X rotation for 123solemn
        local test49Rotation = CFrame.Angles(math.rad(180), math.rad(0), math.rad(180))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test49Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test49Rotation
        end
    elseif needsTest50Rotation then
        -- Test 50: 90° Y rotation for Fang and Chroma Fang
        local test50Rotation = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test50Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test50Rotation
        end
    elseif needsTest6Rotation then
        -- Rotate 90 degrees on Y axis and 270 degrees on Z axis for test 6 items (Chaser, TRS-301, Vintorez)
        local test6Rotation = CFrame.Angles(math.rad(0), math.rad(90), math.rad(270))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test6Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test6Rotation
        end
    elseif needsTest7Rotation then
        -- Rotate 270 degrees on Z axis only for test 7 items (Wind, Power, Ego)
        local test7Rotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270))
        -- Position 1 unit above center for better camera focus
        local test7Position = CFrame.new(0, 1, 0)
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test7Position * test7Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test7Position * test7Rotation
        end
    elseif needsTest8Rotation then
        -- Rotate -90 degrees on Y axis only for test 8 items (rifle skins, Monster, Dragooon)
        local test8Rotation = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))
        -- Position at center for camera focus
        local test8Position = CFrame.new(0, 0, 0)
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test8Position * test8Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test8Position * test8Rotation
        end
    elseif needsTest15Rotation then
        -- Rotate 90 degrees on X axis and 270 degrees on Z axis for test 15 items (Serpent, MP5, Gangster, etc.)
        local test15Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test15Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test15Rotation
        end
    elseif needsTest16Rotation then
        -- Rotate 90 degrees on X axis and 90 degrees on Z axis for test 16 items (Pocket Mag, Tactical Boom, Marksman, Fort)
        local test16Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test16Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test16Rotation
        end
    elseif needsTest17Rotation then
        -- Rotate 90 degrees on Z axis only for test 17 items (Just give me my money, Chaser, Rocket Rain, Gangster, Emergency Surgery)
        local test17Rotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test17Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test17Rotation
        end
    elseif needsTest18Rotation then
        -- Rotate -90 degrees on Z and 360 degrees on X for test 18 items (Rocket Rain)
        local test18Rotation = CFrame.Angles(math.rad(360), math.rad(0), math.rad(-90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test18Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test18Rotation
        end
    elseif needsTest19Rotation then
        -- Rotate 90 degrees on Z and -90 degrees on X for test 19 items (Emergency Surgery)
        local test19Rotation = CFrame.Angles(math.rad(-90), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test19Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test19Rotation
        end
    elseif needsTest20Rotation then
        -- Rotate 360 degrees on Z for test 20 items (Gangster)
        local test20Rotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(360))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test20Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test20Rotation
        end
    elseif needsChaserRotation then
        -- Rotate 90 degrees on Z, 90 degrees on X, and 180 degrees on Y for Chaser
        local chaserRotation = CFrame.Angles(math.rad(90), math.rad(180), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * chaserRotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * chaserRotation
        end
    elseif needsTest21Rotation then
        -- Rotate 90 degrees on Y only for test 21 items (blade skins)
        local test21Rotation = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)) -- 90° Y only
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test21Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test21Rotation
        end
    elseif needsTest22Rotation then
        -- Rotate 90 degrees on Z for test 22 items (knife)
        local test22Rotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test22Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test22Rotation
        end
    elseif needsTest23Rotation then
        -- Rotate 360 degrees on Z for test 23 items (MP5)
        local test23Rotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(360))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test23Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test23Rotation
        end
    elseif needsTest24Rotation then
        -- Rotate 90 degrees on Z and -90 degrees on X for test 24 items (Med Saw)
        local test24Rotation = CFrame.Angles(math.rad(-90), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test24Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test24Rotation
        end
    elseif needsTest25Rotation then
        -- Rotate 30 degrees on X for test 25 items (LMG AE)
        local test25Rotation = CFrame.Angles(math.rad(30), math.rad(0), math.rad(0))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test25Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test25Rotation
        end
    elseif needsTest26Rotation then
        -- Rotate 90 degrees on X and 90 degrees on Z for test 26 items (shna)
        local test26Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test26Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test26Rotation
        end
    elseif needsTest27Rotation then
        -- Rotate -90 degrees on Z for test 27 items (TRS-301)
        local test27Rotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test27Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test27Rotation
        end
    elseif needsTest28Rotation then
        -- Rotate 180 degrees on X and 180 degrees on Z for test 28 items (Prototype X)
        local test28Rotation = CFrame.Angles(math.rad(180), math.rad(0), math.rad(180))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test28Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test28Rotation
        end
    elseif needsTest29Rotation then
        -- Rotate 180 degrees on Y, 30 degrees on Z, and 360 degrees on X for test 29 items (Imperial)
        local test29Rotation = CFrame.Angles(math.rad(360), math.rad(180), math.rad(30))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test29Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test29Rotation
        end
    elseif needsTest30Rotation then
        -- Rotate 360 degrees on X and 90 degrees on Z for test 30 items (PKM)
        local test30Rotation = CFrame.Angles(math.rad(360), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test30Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test30Rotation
        end
    elseif needsTest31Rotation then
        -- Rotate 270 degrees on Z and 90 degrees on X for test 31 items (Sharp Point)
        local test31Rotation = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test31Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test31Rotation
        end
    elseif needsTest32Rotation then
        -- Rotate 90 degrees on Z and 90 degrees on X for test 32 items
        local test32Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test32Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test32Rotation
        end
    elseif needsTest33Rotation then
        -- Rotate 270 degrees on Z for test 33 items (Vintorez)
        local test33Rotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test33Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test33Rotation
        end
    elseif needsTest34Rotation then
        -- Rotate -90 degrees on Z and 90 degrees on X for test 34 items (Serpent)
        local test34Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(-90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test34Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test34Rotation
        end
    elseif needsTest35Rotation then
        -- Rotate 90 degrees on X and 90 degrees on Z for test 35 items (Stinger)
        local test35Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test35Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test35Rotation
        end
    elseif needsTest36Rotation then
        -- Rotate 90 degrees on Z and 90 degrees on X for test 36 items (Rapid Shot - keeping same)
        local test36Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test36Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test36Rotation
        end
    elseif needsTest37Rotation then
        -- Rotate for test37 items to face left (15° X + 90° Y + 180° Z)
        local test37Rotation = CFrame.Angles(math.rad(15), math.rad(90), math.rad(180))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test37Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test37Rotation
        end
        --elseif clone:IsA("BasePart") then
            --clone.CFrame = clone.CFrame * sksRotation
        --end
    --elseif sourceName == "SKS Grey" then
        ---- SKS Grey: 90° X + 90° Z rotation
        --local sksRotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
        --if clone:IsA("Model") and clone.PrimaryPart then
            --clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * sksRotation)
        --elseif clone:IsA("BasePart") then
            --clone.CFrame = clone.CFrame * sksRotation
        --end
    --elseif sourceName == "SKS Wood" then
        ---- SKS Wood: 180° Z + 90° Z + 90° X = 90° X + 270° Z rotation
        --local sksRotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270))
        --if clone:IsA("Model") and clone.PrimaryPart then
            --clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * sksRotation)
        --elseif clone:IsA("BasePart") then
            --clone.CFrame = clone.CFrame * sksRotation
        --end
    elseif needsTest39Rotation then
        -- Rotate -90 degrees on Z axis for test 39 items (rotate left)
        local test39Rotation = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test39Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test39Rotation
        end
    elseif needsTest40Rotation then
        -- Rotate -90 degrees on Z axis for test 40 items (rotate left for Prism Edge & Cannon Ball)
        local test40Rotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test40Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test40Rotation
        end
    elseif needsTest41Rotation then
        -- Rotate 90 degrees on Y axis for test 41 items (111 items excluding Deathshard and Winter's Edge)
        local test41Rotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test41Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test41Rotation
        end
    elseif needsTest42Rotation then
        -- Rotate 180° on Y and 90° on Z for test 42 items (custom 111 set)
        local test42Rotation = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test42Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test42Rotation
        end
    elseif needsTest43Rotation then
        -- Rotate 90° on Y and 90° on Z for test 43 items (custom 111 set)
        local test43Rotation = CFrame.Angles(math.rad(0), math.rad(90), math.rad(180))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test43Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test43Rotation
        end
    elseif needsLeftRotation then
        -- Rotate only 90 on Z axis
        local leftFacing = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * leftFacing)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * leftFacing
        end
    elseif needsTestRotation then
        -- Rotate -90 degrees on Y axis for test 1 items
        local testRotation = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * testRotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * testRotation
        end
    elseif needsTest2Rotation then
        -- Rotate -90 degrees on Y axis for test 2 items
        local test2Rotation = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test2Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test2Rotation
        end
    elseif needsSpecialYRotation then
        -- Rotate 360 degrees on X axis for special items (LMG AE)
        local specialYRotation = CFrame.Angles(math.rad(360), math.rad(0), math.rad(0))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * specialYRotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * specialYRotation
        end
    elseif needsSpecialXZRotation then
        -- Rotate 360 degrees on Z axis for special items (Enfield Bren)
        local specialXZRotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(360))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * specialXZRotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * specialXZRotation
        end
    elseif isGoblinItem then
        -- Rotate 180 degrees on Z axis for Goblin items
        local goblinRotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(180))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * goblinRotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * goblinRotation
        end
    elseif isOtherMeshesItem then
        -- Apply rotation for both small and big viewport for Meshes items
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(CFrame.new() * CFrame.Angles(math.rad(90), 0, 0)) -- Rotate 90 degrees around X-axis
        elseif clone:IsA("BasePart") then
            clone.CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0) -- Rotate 90 degrees around X-axis
        end
    else
        -- No rotation - just standard positioning
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(CFrame.new())
        elseif clone:IsA("BasePart") then
            clone.CFrame = CFrame.new()
        end
    end

    -- Fit camera
    local min, max = Vector3.new(1e9,1e9,1e9), Vector3.new(-1e9,-1e9,-1e9)
    for _,bp in ipairs(iterBaseParts(clone)) do
        local s=getVisualSize(bp); local cf=bp.CFrame; local h=s*0.5
        local corners = {
            cf*CFrame.new(-h.X,-h.Y,-h.Z), cf*CFrame.new(h.X,-h.Y,-h.Z),
            cf*CFrame.new(-h.X,h.Y,-h.Z),  cf*CFrame.new(h.X,h.Y,-h.Z),
            cf*CFrame.new(-h.X,-h.Y,h.Z),  cf*CFrame.new(h.X,-h.Y,h.Z),
            cf*CFrame.new(-h.X,h.Y,h.Z),   cf*CFrame.new(h.X,h.Y,h.Z),
        }
        for _,c in ipairs(corners) do
            local p=c.Position
            min = Vector3.new(math.min(min.X,p.X), math.min(min.Y,p.Y), math.min(min.Z,p.Z))
            max = Vector3.new(math.max(max.X,p.X), math.max(max.Y,p.Y), math.max(max.Z,p.Z))
        end
    end
    local center=(min+max)/2
    local span = (max-min).Magnitude
    
    -- Use safer distance for Meshes items to avoid viewport issues
    local dist
    if isOtherMeshesItem then
        -- Use moderate distance to prevent safety clamps
        dist = span*fitFactor*2 -- Moderate distance to prevent safety clamps
    else
        dist = math.max(minDist, span*fitFactor)
    end
    
    local camPos = center + Vector3.new(0,0,dist)
    
    -- Camera target for Meshes items
    local camTarget = center
    if isOtherMeshesItem then
        if opts.isBigViewport then
            -- Focus 6 units above the center for big viewport Meshes items
            camTarget = center + Vector3.new(0, 6, 0) -- 6 units above center
            camPos = camPos + Vector3.new(0, 50, 0) -- Move camera up by 50 units
            camPos = camPos + Vector3.new(0, 20, 0) -- Move camera up by 20 units
            camPos = camPos + Vector3.new(0, -40, 0) -- Move camera down by 40 units for big viewport Meshes items
        else
            -- Look at point 4 units from the top for small viewport
            camTarget = Vector3.new(center.X, max.Y - 4, center.Z)
        end
    end
    
    -- Special camera focus adjustments for specific weapons
    local specialFocusWeapons = {
        "Meshes/skyward spine", "Meshes/vortex vanquisher", "Meshes/storm", "Meshes/magma", "Meshes/blue",
        "Meshes/deathmatch", "Meshes/regicide", "Meshes/vortex", "Meshes/gold", "Meshes/tassel",
        "Meshes/kilitain", "Meshes/cross", "Meshes/lithic", "Meshes/spear", "Meshes/prototype",
        "Meshes/royal spear", "Meshes/the catch", "Meshes/wavebreaker", "Meshes/fin", "Meshes/white tassel",
        "Meshes/primordial jade", "Meshes/jade"
    }
    
    local needsSpecialFocus = false
    for _, weaponName in ipairs(specialFocusWeapons) do
        if string.find(sourceName:lower(), weaponName:lower()) or sourceName == weaponName then
            needsSpecialFocus = true
            break
        end
    end
    
    if needsSpecialFocus then
        if opts.isBigViewport then
            -- For big viewport: Move camera down to bring weapon into better view
            camPos = camPos + Vector3.new(0, -30, 0) -- Move camera down by 30 units
        else
            -- For small viewport: Just raise focus slightly
            camTarget = camTarget + Vector3.new(0, 1, 0) -- Raise focus by 1 unit
        end
    end
    
    cam.CFrame = CFrame.new(camPos, camTarget)
    vp.Ambient = Color3.new(0.7, 0.7, 0.7) -- Reduced ambient to allow lights to show
    vp.LightDirection = Vector3.new(-1,-1,-1)
    vp.LightColor = Color3.new(1, 1, 1) -- Maximum directional light for all weapons
    
    -- Check if this is a legendary item and adjust brightness
    local skinData = SkinConfig.GetSkinMeta(sourceName)
    if skinData and skinData.rarity == "legendary" then
        vp.Ambient = Color3.new(0.9, 0.9, 0.9) -- 90% brightness for legendary items
        vp.LightColor = Color3.new(0.9, 0.9, 0.9) -- 90% directional light for legendary items
    end
    
    -- Special extra lighting for Flash mythic item
    if sourceName == "Flash" then
        -- Find all parts in the Flash model to add lights
        local function addLightsToAllParts(model)
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    -- Add multiple PointLights to each part
                    local pointLight1 = Instance.new("PointLight")
                    pointLight1.Brightness = 10 -- EXTREMELY bright
                    pointLight1.Range = 100 -- Matched to SpotLight range
                    pointLight1.Color = Color3.new(1, 1, 1)
                    pointLight1.Parent = part
                    
                    -- Add SurfaceLight for additional brightness
                    local surfaceLight = Instance.new("SurfaceLight")
                    surfaceLight.Brightness = 10 -- Maximum brightness
                    surfaceLight.Range = 100
                    surfaceLight.Color = Color3.new(1, 1, 1)
                    surfaceLight.Face = Enum.NormalId.Front
                    surfaceLight.Parent = part
                    
                    -- Add SpotLight for focused illumination
                    local spotLight = Instance.new("SpotLight")
                    spotLight.Brightness = 10
                    spotLight.Range = 100
                    spotLight.Color = Color3.new(1, 1, 1)
                    spotLight.Angle = 180 -- Wide angle
                    spotLight.Face = Enum.NormalId.Front -- Ensure it faces forward
                    spotLight.Parent = part
                end
            end
        end
        
        addLightsToAllParts(clone)
        
        -- Also boost the viewport lighting even more for Flash
        vp.Ambient = Color3.new(2, 2, 2) -- OVER-BRIGHT ambient (beyond normal limits)
        vp.LightColor = Color3.new(2, 2, 2) -- OVER-BRIGHT directional
        
        -- Add blue-tinted lighting to enhance blue details
        local blueLight = Instance.new("PointLight")
        blueLight.Brightness = 5
        blueLight.Range = 100
        blueLight.Color = Color3.new(0.5, 0.8, 1) -- Blue-tinted light to enhance blue details
        
        -- Create a part positioned to enhance blue visibility
        local blueLightHolder = Instance.new("Part")
        blueLightHolder.Name = "FlashBlueLightHolder"
        blueLightHolder.Size = Vector3.new(0.1, 0.1, 0.1)
        blueLightHolder.Transparency = 1
        blueLightHolder.CanCollide = false
        blueLightHolder.Anchored = true
        blueLightHolder.CFrame = CFrame.new(center + Vector3.new(5, 5, 5)) -- Position to side for contrast
        blueLightHolder.Parent = clone
        
        blueLight.Parent = blueLightHolder
    end

    return clone
end

-- Stats strip (Money / Coins / Rank)
local statsContainer = Instance.new("Frame")
statsContainer.Size = UDim2.new(1, -40, 0, 90)
statsContainer.Position = UDim2.new(0, 20, 0, 70)
statsContainer.BackgroundTransparency = 1
statsContainer.Parent = main

-- Credits card
local moneyDisplay = Instance.new("Frame")
moneyDisplay.Size = UDim2.new(0.32, 0, 1, 0)
moneyDisplay.BackgroundColor3 = C3(8, 20, 12)
moneyDisplay.BackgroundTransparency = 0.1
moneyDisplay.ClipsDescendants = true
moneyDisplay.Parent = statsContainer
Instance.new("UICorner", moneyDisplay).CornerRadius = UDim.new(0, 12)
local moneyStroke = Instance.new("UIStroke", moneyDisplay); moneyStroke.Color = BRIGHT_GREEN; moneyStroke.Transparency = 0.25; moneyStroke.Thickness = 2
local moneyIcon = Instance.new("TextLabel")
moneyIcon.Size = UDim2.new(0, 32, 0, 32)
moneyIcon.Position = UDim2.new(0, 14, 0.5, -2)
moneyIcon.AnchorPoint = Vector2.new(0, 0.5)
moneyIcon.BackgroundTransparency = 1
moneyIcon.Font = Enum.Font.FredokaOne
moneyIcon.Text = "$"
moneyIcon.TextSize = 26
moneyIcon.TextColor3 = BRIGHT_GREEN
moneyIcon.TextStrokeTransparency = 0.5
moneyIcon.Parent = moneyDisplay
local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(1, -64, 0, 18)
moneyLabel.Position = UDim2.new(0, 54, 0, 10)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Font = Enum.Font.GothamMedium
moneyLabel.Text = "CREDITS"
moneyLabel.TextSize = 14
moneyLabel.TextColor3 = DIM_GREEN
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = moneyDisplay
local moneyValue = Instance.new("TextLabel")
moneyValue.Size = UDim2.new(1, -64, 0, 34)
moneyValue.Position = UDim2.new(0, 54, 0, 34)
moneyValue.BackgroundTransparency = 1
moneyValue.Font = Enum.Font.GothamMedium
moneyValue.Text = "0"
moneyValue.TextSize = 24
moneyValue.TextColor3 = BRIGHT_GREEN
moneyValue.TextStrokeTransparency = 0.7
moneyValue.TextXAlignment = Enum.TextXAlignment.Left
moneyValue.Parent = moneyDisplay

-- Coins card
local coinsDisplay = Instance.new("Frame")
coinsDisplay.Size = UDim2.new(0.32, 0, 1, 0)
coinsDisplay.Position = UDim2.new(0.34, 0, 0, 0)
coinsDisplay.BackgroundColor3 = C3(28, 18, 6)
coinsDisplay.BackgroundTransparency = 0.1
coinsDisplay.ClipsDescendants = true
coinsDisplay.Parent = statsContainer
Instance.new("UICorner", coinsDisplay).CornerRadius = UDim.new(0, 12)
local coinsStroke = Instance.new("UIStroke", coinsDisplay); coinsStroke.Color = C3(255, 190, 80); coinsStroke.Transparency = 0.25; coinsStroke.Thickness = 2
local coinLogo = Instance.new("TextLabel")
coinLogo.Size = UDim2.new(0, 32, 0, 32)
coinLogo.Position = UDim2.new(0, 40, 0.5, -2)
coinLogo.AnchorPoint = Vector2.new(0, 0.5)
coinLogo.BackgroundTransparency = 1
coinLogo.Font = Enum.Font.FredokaOne
coinLogo.Text = "T"
coinLogo.TextSize = 24
coinLogo.TextColor3 = C3(255, 200, 100)
coinLogo.TextStrokeTransparency = 0.5
coinLogo.Parent = coinsDisplay
local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1, -84, 0, 18)
coinLabel.Position = UDim2.new(0, 78, 0, 10)
coinLabel.BackgroundTransparency = 1
coinLabel.Font = Enum.Font.GothamMedium
coinLabel.Text = "TRUMP COINS"
coinLabel.TextSize = 14
coinLabel.TextColor3 = C3(255, 190, 90)
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Parent = coinsDisplay
local coinValue = Instance.new("TextLabel")
coinValue.Size = UDim2.new(1, -84, 0, 34)
coinValue.Position = UDim2.new(0, 78, 0, 34)
coinValue.BackgroundTransparency = 1
coinValue.Font = Enum.Font.GothamMedium
coinValue.Text = "0"
coinValue.TextSize = 24
coinValue.TextColor3 = C3(255, 230, 150)
coinValue.TextStrokeTransparency = 0.7
coinValue.TextXAlignment = Enum.TextXAlignment.Left
coinValue.Parent = coinsDisplay

-- Status Rank card
local rankDisplay = Instance.new("Frame")
rankDisplay.Size = UDim2.new(0.32, 0, 1, 0)
rankDisplay.Position = UDim2.new(0.68, 0, 0, 0)
rankDisplay.BackgroundTransparency = 1
rankDisplay.ClipsDescendants = true
rankDisplay.Parent = statsContainer
local badge = Instance.new("Frame")
badge.Size = UDim2.new(0, 64, 0, 64)
badge.Position = UDim2.new(0, 10, 0.5, 0)
badge.AnchorPoint = Vector2.new(0, 0.5)
badge.BackgroundTransparency = 1
badge.Parent = rankDisplay
local rankIcon = Instance.new("TextLabel")
rankIcon.Size = UDim2.new(0, 32, 0, 32)
rankIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
rankIcon.AnchorPoint = Vector2.new(0.5, 0.5)
rankIcon.BackgroundTransparency = 1
rankIcon.Font = Enum.Font.FredokaOne
rankIcon.Text = "⚜"
rankIcon.TextSize = 22
rankIcon.TextColor3 = GOLD
rankIcon.Parent = badge
local rankLabel = Instance.new("TextLabel")
rankLabel.Size = UDim2.new(1, -84, 0, 18)
rankLabel.Position = UDim2.new(0, 84, 0, 10)
rankLabel.BackgroundTransparency = 1
rankLabel.Font = Enum.Font.GothamMedium
rankLabel.Text = "STATUS RANK"
rankLabel.TextSize = 14
rankLabel.TextColor3 = GOLD
rankLabel.TextXAlignment = Enum.TextXAlignment.Left
rankLabel.Parent = rankDisplay
local rankValue = Instance.new("TextLabel")
rankValue.Name = "Value"
rankValue.Size = UDim2.new(1, -84, 0, 30)
rankValue.Position = UDim2.new(0, 84, 0, 32)
rankValue.BackgroundTransparency = 1
rankValue.Font = Enum.Font.FredokaOne
rankValue.Text = "1"
rankValue.TextSize = 26
rankValue.TextColor3 = GOLD
rankValue.TextXAlignment = Enum.TextXAlignment.Left
rankValue.Parent = rankDisplay

-- Rank progress bar
local rankProgressBarBg = Instance.new("Frame")
rankProgressBarBg.Name = "RankProgressBg"
rankProgressBarBg.Size = UDim2.new(1, -84, 0, 10)
rankProgressBarBg.Position = UDim2.new(0, 84, 0, 60)
rankProgressBarBg.BackgroundColor3 = Color3.fromRGB(30, 22, 8)
rankProgressBarBg.BackgroundTransparency = 0.3
rankProgressBarBg.BorderSizePixel = 0
rankProgressBarBg.Parent = rankDisplay
Instance.new("UICorner", rankProgressBarBg).CornerRadius = UDim.new(0,4)
local rpStroke = Instance.new("UIStroke", rankProgressBarBg); rpStroke.Thickness=1; rpStroke.Color=GOLD; rpStroke.Transparency=0.4
local rankProgressFill = Instance.new("Frame")
rankProgressFill.Name = "Fill"
rankProgressFill.Size = UDim2.new(0,0,1,0)
rankProgressFill.BackgroundColor3 = GOLD
rankProgressFill.BorderSizePixel = 0
rankProgressFill.Parent = rankProgressBarBg
Instance.new("UICorner", rankProgressFill).CornerRadius = UDim.new(0,4)
local rankProgressLabel = Instance.new("TextLabel")
rankProgressLabel.Name = "ProgressLabel"
rankProgressLabel.Size = UDim2.new(1,0,1,0)
rankProgressLabel.BackgroundTransparency = 1
rankProgressLabel.Font = Enum.Font.GothamMedium
rankProgressLabel.Text = ""
rankProgressLabel.TextSize = 10
rankProgressLabel.TextColor3 = GOLD
rankProgressLabel.Parent = rankProgressBarBg

-- Rank chevrons
local rankChevrons = Instance.new("Frame")
rankChevrons.Size = UDim2.new(0, 70, 0, 12)
rankChevrons.Position = UDim2.new(0, 84, 0, 74)
rankChevrons.BackgroundTransparency = 1
rankChevrons.Parent = rankDisplay
for i=1,5 do
    local ch = Instance.new("ImageLabel")
    ch.Name = "Ch"..i
    ch.Size = UDim2.new(0,10,0,10)
    ch.Position = UDim2.new(0,(i-1)*14,0,0)
    ch.BackgroundTransparency = 1
    ch.Image = "rbxassetid://6764432408"
    ch.ImageColor3 = GOLD
    ch.ImageTransparency = (i<=1) and 0 or 0.7
    ch.Parent = rankChevrons
end

-- Tab and content container
local tabBar = Instance.new("Frame")
tabBar.Size=UDim2.new(1,-40,0,40); tabBar.Position=UDim2.new(0,20,0,170)
tabBar.BackgroundColor3=C3(10,15,12); tabBar.BackgroundTransparency=0.5; tabBar.ZIndex=10; tabBar.Parent=main
Instance.new("UICorner", tabBar).CornerRadius=UDim.new(0,8)

local contentArea = Instance.new("Frame")
contentArea.Size=UDim2.new(1,-40,1,-220); contentArea.Position=UDim2.new(0,20,0,220)
contentArea.BackgroundColor3=C3(8,12,10); contentArea.BackgroundTransparency=0.5; contentArea.ClipsDescendants=false; contentArea.Parent=main
Instance.new("UICorner", contentArea).CornerRadius=UDim.new(0,8)
local contentStroke = Instance.new("UIStroke", contentArea); contentStroke.Color=GREEN; contentStroke.Transparency=0.7; contentStroke.Thickness=1

local currentTab = "skins" -- "skins" or "crates"

local skinsTabBtn = Instance.new("TextButton")
skinsTabBtn.Size=UDim2.new(0,100,1,-10); skinsTabBtn.Position=UDim2.new(0,10,0,5)
skinsTabBtn.BackgroundColor3=BLACK; skinsTabBtn.Text="SKINS"; skinsTabBtn.TextColor3=BRIGHT_GREEN; skinsTabBtn.TextSize=16; skinsTabBtn.Font=Enum.Font.FredokaOne; skinsTabBtn.Parent=tabBar
Instance.new("UICorner", skinsTabBtn).CornerRadius=UDim.new(0,6)

local cratesTabBtn = Instance.new("TextButton")
cratesTabBtn.Size=UDim2.new(0,100,1,-10); cratesTabBtn.Position=UDim2.new(0,120,0,5)
cratesTabBtn.BackgroundColor3=C3(20,30,25); cratesTabBtn.BackgroundTransparency=0.5; cratesTabBtn.Text="CRATES"; cratesTabBtn.TextColor3=GREEN; cratesTabBtn.TextSize=16; cratesTabBtn.Font=Enum.Font.FredokaOne; cratesTabBtn.Parent=tabBar
Instance.new("UICorner", cratesTabBtn).CornerRadius=UDim.new(0,6)

-- Sort dropdown (right beside tabs)
local sortFrame = Instance.new("Frame")
sortFrame.Size=UDim2.fromOffset(120,30); sortFrame.Position=UDim2.new(0,230,0,5); sortFrame.AnchorPoint=Vector2.new(0,0)
sortFrame.BackgroundColor3=C3(5,8,6); sortFrame.BackgroundTransparency=0.3; sortFrame.ZIndex=10; sortFrame.Parent=tabBar
Instance.new("UICorner", sortFrame).CornerRadius=UDim.new(0,6)
local sortStroke = Instance.new("UIStroke", sortFrame); sortStroke.Color=GREEN; sortStroke.Transparency=0.6; sortStroke.Thickness=1

local sortBtn = Instance.new("TextButton")
sortBtn.Size=UDim2.new(1,0,1,0); sortBtn.BackgroundTransparency=1; sortBtn.ZIndex=11
sortBtn.Font=Enum.Font.FredokaOne; sortBtn.Text="Sort: A-Z"; sortBtn.TextSize=12; sortBtn.TextColor3=GREEN; sortBtn.TextXAlignment=Enum.TextXAlignment.Center; sortBtn.Parent=sortFrame

-- Sort dropdown menu (initially hidden) - parented to main to avoid clipping
local sortDropdown = Instance.new("Frame")
sortDropdown.Size=UDim2.fromOffset(120,60); sortDropdown.Position=UDim2.new(0,160,0,215); sortDropdown.Visible=false
sortDropdown.BackgroundColor3=C3(5,8,6); sortDropdown.BackgroundTransparency=0.1; sortDropdown.ZIndex=200; sortDropdown.Parent=main
Instance.new("UICorner", sortDropdown).CornerRadius=UDim.new(0,6)
local dropStroke = Instance.new("UIStroke", sortDropdown); dropStroke.Color=GREEN; dropStroke.Transparency=0.6; dropStroke.Thickness=1; dropStroke.ZIndex=200

local sortOption1 = Instance.new("TextButton")
sortOption1.Size=UDim2.new(1,0,0.5,0); sortOption1.BackgroundTransparency=0.8; sortOption1.BackgroundColor3=C3(10,20,15); sortOption1.ZIndex=201
sortOption1.Font=Enum.Font.FredokaOne; sortOption1.Text="Alphabetical"; sortOption1.TextSize=11; sortOption1.TextColor3=GREEN; sortOption1.Active=true; sortOption1.AutoButtonColor=true; sortOption1.Parent=sortDropdown

local sortOption2 = Instance.new("TextButton")
sortOption2.Size=UDim2.new(1,0,0.5,0); sortOption2.Position=UDim2.new(0,0,0.5,0); sortOption2.BackgroundTransparency=0.8; sortOption2.BackgroundColor3=C3(10,20,15); sortOption2.ZIndex=201
sortOption2.Font=Enum.Font.FredokaOne; sortOption2.Text="Rarity"; sortOption2.TextSize=11; sortOption2.TextColor3=GREEN; sortOption2.Active=true; sortOption2.AutoButtonColor=true; sortOption2.Parent=sortDropdown

-- Search bar (all the way to the right)
local searchFrame = Instance.new("Frame")
searchFrame.Size=UDim2.fromOffset(200,30); searchFrame.Position=UDim2.new(1,-210,0,5); searchFrame.AnchorPoint=Vector2.new(0,0)
searchFrame.BackgroundColor3=C3(5,8,6); searchFrame.BackgroundTransparency=0.3; searchFrame.Parent=tabBar
Instance.new("UICorner", searchFrame).CornerRadius=UDim.new(0,6)
local searchStroke = Instance.new("UIStroke", searchFrame); searchStroke.Color=GREEN; searchStroke.Transparency=0.6; searchStroke.Thickness=1

local searchBox = Instance.new("TextBox")
searchBox.Size=UDim2.new(1,-20,1,0); searchBox.Position=UDim2.new(0,10,0,0); searchBox.BackgroundTransparency=1
searchBox.Font=Enum.Font.FredokaOne; searchBox.Text=""; searchBox.PlaceholderText="Search..."; searchBox.TextSize=12; searchBox.TextColor3=GREEN; searchBox.PlaceholderColor3=Color3.new(0.5,0.7,0.5); searchBox.TextXAlignment=Enum.TextXAlignment.Left; searchBox.Parent=searchFrame

-- INVENTORY GRID VIEW
local gridView = Instance.new("ScrollingFrame")
gridView.Name="GridView"; gridView.Size=UDim2.new(1,0,1,0); gridView.BackgroundTransparency=1; gridView.BorderSizePixel=0
gridView.ScrollBarThickness=6; gridView.ScrollBarImageColor3=GREEN; gridView.Parent=contentArea
local pad = Instance.new("UIPadding", gridView); pad.PaddingTop=UDim.new(0,10); pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)

local inventoryContainer = Instance.new("Frame")
inventoryContainer.Size=UDim2.new(1,-20,1,-10); inventoryContainer.Position=UDim2.new(0,10,0,10)
inventoryContainer.BackgroundTransparency=1; inventoryContainer.ClipsDescendants=false; inventoryContainer.Parent=gridView
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize=UDim2.new(0,163,0,197); gridLayout.CellPadding=UDim2.new(0,35,0,40)
gridLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; gridLayout.SortOrder=Enum.SortOrder.LayoutOrder; gridLayout.Parent=inventoryContainer
gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    gridView.CanvasSize = UDim2.new(0,0,0, gridLayout.AbsoluteContentSize.Y + 20)
end)

-- ITEM PAGE (in-panel)
local itemPage = Instance.new("Frame")
itemPage.Name="ItemPage"; itemPage.Visible=false; itemPage.Size=UDim2.new(1,0,1,0); itemPage.BackgroundTransparency=1; itemPage.Parent=contentArea
local backBtn = Instance.new("TextButton")
backBtn.Size=UDim2.fromOffset(80,32); backBtn.Position=UDim2.new(0,0,0,0)
backBtn.BackgroundColor3=C3(20,30,25); backBtn.Text="< BACK"; backBtn.TextColor3=GREEN; backBtn.Font=Enum.Font.FredokaOne; backBtn.TextSize=16; backBtn.Parent=itemPage
Instance.new("UICorner", backBtn).CornerRadius=UDim.new(0,6)

-- EQUIP button (top-right of item page)
local equipBtn = Instance.new("TextButton")
equipBtn.Name = "EquipButton"
equipBtn.Size = UDim2.fromOffset(100,32)
equipBtn.Position = UDim2.new(1,-110,0,0)
equipBtn.AnchorPoint = Vector2.new(0,0)
equipBtn.BackgroundColor3 = C3(20,30,25)
equipBtn.Text = "EQUIP"
equipBtn.TextColor3 = BRIGHT_GREEN
equipBtn.Font = Enum.Font.GothamMedium
equipBtn.TextSize = 16
equipBtn.AutoButtonColor = true
equipBtn.Parent = itemPage
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = equipBtn
    local s = Instance.new("UIStroke"); s.Thickness = 2; s.Color = GREEN; s.Transparency = 0.3; s.Parent = equipBtn
end

local itemTitle = Instance.new("TextLabel")
itemTitle.Size=UDim2.new(1,-220,0,32); itemTitle.Position=UDim2.new(0,110,0,0); itemTitle.BackgroundTransparency=1
itemTitle.Font=Enum.Font.FredokaOne; itemTitle.TextXAlignment=Enum.TextXAlignment.Left; itemTitle.TextSize=20; itemTitle.TextColor3=BRIGHT_GREEN; itemTitle.Parent=itemPage

local itemPanel = Instance.new("Frame")
itemPanel.Size=UDim2.new(1,0,1,-40); itemPanel.Position=UDim2.new(0,0,0,40)
itemPanel.BackgroundTransparency=1; itemPanel.Parent=itemPage

-- Left: big viewport
local bigViewport = Instance.new("ViewportFrame")
bigViewport.Name="BigViewport"; bigViewport.Size=UDim2.new(0.62,-20,1,-20); bigViewport.Position=UDim2.new(0,10,0,10)
bigViewport.BackgroundTransparency=1; bigViewport.Parent=itemPanel

-- Right: stats box
local statsBox = Instance.new("Frame")
statsBox.Size=UDim2.new(0.38,-20,1,-20); statsBox.Position=UDim2.new(0.62,10,0,10)
statsBox.BackgroundColor3=C3(10,15,12); statsBox.BackgroundTransparency=0.2; statsBox.Parent=itemPanel
Instance.new("UICorner", statsBox).CornerRadius=UDim.new(0,10)
local statsStroke2 = Instance.new("UIStroke", statsBox); statsStroke2.Color=GREEN; statsStroke2.Transparency=0.3

local function mkRow(text, order)
    local row = Instance.new("TextLabel")
    row.Size=UDim2.new(1,-20,0,26); row.Position=UDim2.new(0,10,0,(order-1)*30+10)
    row.BackgroundTransparency=1; row.Font=Enum.Font.FredokaOne; row.TextXAlignment=Enum.TextXAlignment.Left
    row.TextSize=16; row.TextColor3=BRIGHT_GREEN; row.Text=text; row.Parent=statsBox
    return row
end

local bulletsRow = mkRow("Bullets Shot: 0", 1)
local itemsRow   = mkRow("Items Shot: 0", 2)
local timeRow    = mkRow("Time Rolled: -", 3)
local rarityRow  = mkRow("Rarity: Common", 4) -- Added rarity row

-- Simple tooltip
local detailsPanel = Instance.new("Frame")
detailsPanel.Size=UDim2.fromOffset(0,0); detailsPanel.BackgroundColor3=C3(10,15,12)
detailsPanel.BackgroundTransparency=0.2; detailsPanel.Visible=false; detailsPanel.ZIndex=100; detailsPanel.Parent=gui
Instance.new("UICorner", detailsPanel).CornerRadius=UDim.new(0,8)
local dpStroke=Instance.new("UIStroke", detailsPanel); dpStroke.Color=GREEN; dpStroke.Transparency=0.3; dpStroke.Thickness=2

local function setDetailsText(txt)
    for _,c in ipairs(detailsPanel:GetChildren()) do if not (c:IsA("UICorner") or c:IsA("UIStroke")) then c:Destroy() end end
    local l = Instance.new("TextLabel"); l.Size=UDim2.new(1,-20,1,-20); l.Position=UDim2.new(0,10,0,10)
    l.BackgroundTransparency=1; l.Font=Enum.Font.FredokaOne; l.Text=txt; l.TextSize=12; l.TextColor3=BRIGHT_GREEN; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=detailsPanel
end

-- Item page rotation controls
local bigViewRotateConn
local bigViewDragging=false
local bigViewAngle=0
local bigViewVelocity=0
local bigViewModel
local bigViewBaseRotation = CFrame.new() -- Store the weapon's base rotation from setupViewport
local currentBigViewIsOtherMeshes = false -- Track if current big view item is a Meshes type
local function bindBigViewportControls(vp)
    if bigViewRotateConn then bigViewRotateConn:Disconnect(); bigViewRotateConn=nil end
    bigViewDragging=false; bigViewVelocity=0
    local lastX
    vp.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            bigViewDragging = true; lastX = input.Position.X
        end
    end)
    vp.InputChanged:Connect(function(input)
        if bigViewDragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local dx = input.Position.X - (lastX or input.Position.X)
            lastX = input.Position.X
            local deg = dx * 0.4
            bigViewAngle += deg
            bigViewVelocity = deg
        end
    end)
    vp.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            bigViewDragging = false
        end
    end)
    local autoSpin = 20 -- deg/sec
    bigViewRotateConn = RunService.RenderStepped:Connect(function(dt)
        if not bigViewModel then return end
        
        if not bigViewDragging then
            bigViewAngle += autoSpin * dt + bigViewVelocity
            bigViewVelocity *= 0.90
            if math.abs(bigViewVelocity) < 0.02 then bigViewVelocity = 0 end
        end
        local yaw = math.rad(bigViewAngle)
        
        if bigViewModel:IsA("Model") and bigViewModel.PrimaryPart then
            if currentBigViewIsOtherMeshes then
                -- Meshes items: First stand upright (90° X-axis), then spin around Z-axis
                local standingRotation = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0)
                bigViewModel:SetPrimaryPartCFrame(standingRotation * CFrame.Angles(0, 0, yaw))
            else
                -- All other items: Apply base rotation + spinning rotation
                bigViewModel:SetPrimaryPartCFrame(bigViewBaseRotation * CFrame.Angles(0, yaw, 0))
            end
        elseif bigViewModel:IsA("BasePart") then
            if currentBigViewIsOtherMeshes then
                -- Meshes items: First stand upright (90° X-axis), then spin around Z-axis
                local standingRotation = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0)
                bigViewModel.CFrame = standingRotation * CFrame.Angles(0, 0, yaw)
            else
                -- All other items: Apply base rotation + spinning rotation
                bigViewModel.CFrame = bigViewBaseRotation * CFrame.Angles(0, yaw, 0)
            end
        end
    end)
end

local currentItemSkinName = nil
local currentItemRarity = nil
local mythicEffectsCleanup = nil -- Tracking for mythic effects cleanup

local function openItemPage(skinId)
    currentItemSkinName = skinId
    
    -- Use display name for crates
    local displayName = skinId
    if isCrate(skinId) then
        local crateData = CrateConfig and CrateConfig.GetCrate(skinId)
        if crateData and crateData.name then
            displayName = crateData.name
        end
    end
    itemTitle.Text = displayName
    
    -- Get item rarity
    currentItemRarity = getSkinRarity(skinId)
    local rarityNames = {"COMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC"}
    local rarityName = rarityNames[currentItemRarity] or "COMMON"
    
    -- Set rarity-based colors
    local rarityColors = { 
        Color3.new(0.7, 0.7, 0.7),  -- Common: Light gray
        Color3.new(0.2, 0.8, 0.2),  -- Rare: Bright green
        Color3.new(0.6, 0.2, 1.0),  -- Epic: Purple
        Color3.new(1.0, 0.8, 0.0),  -- Legendary: Gold
        BLOOD_RED                   -- Mythic: Blood Red
    }
    local rarityColor = rarityColors[currentItemRarity]
    
    -- Update rarity row - apply color for all rarities including legendary and mythic
    rarityRow.Text = "Rarity: " .. rarityName
    rarityRow.TextColor3 = rarityColor
    
    -- Check if this is a crate
    local isItemCrate = isCrate(skinId)
    
    if isItemCrate then
        -- For crates, show crate info instead of weapon stats
        local crateData = CrateConfig and CrateConfig.GetCrate(skinId)
        if crateData then
            -- Use 3D model for crate
            local src = getSkinInstance(skinId)
            bigViewModel = setupViewport(bigViewport, src, {fitFactor = ITEM_FIT_FACTOR, minDist = ITEM_MIN_DIST, isBigViewport = true})
            
            -- Capture base rotation
            if bigViewModel then
                if bigViewModel:IsA("Model") and bigViewModel.PrimaryPart then
                    bigViewBaseRotation = bigViewModel.PrimaryPart.CFrame
                elseif bigViewModel:IsA("BasePart") then
                    bigViewBaseRotation = bigViewModel.CFrame
                end
            end
            
            -- Update stats to show crate info
            bulletsRow.Text = "Type: " .. crateData.name
            itemsRow.Text = "Cost: " .. (crateData.openCost == 0 and "FREE" or crateData.openCost .. " credits")
            if crateData.contents then
                timeRow.Text = "Contents: " .. #crateData.contents .. " possible items"
            else
                timeRow.Text = "Contents: Unknown"
            end
        end
        
        -- Change button to OPEN
        equipBtn.Text = "OPEN"
        equipBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50) -- Orange for crates
    else
        -- Normal skin handling
        local src = getSkinInstance(skinId)
        
        -- Check if this is an "other" Meshes item (non-weps) for special spinning rotation
        currentBigViewIsOtherMeshes = false
        local isMeshesSource = string.find(skinId, "Meshes") or skinId == "beginner's protector" or skinId == "beginner's protector 2"
        if isMeshesSource then
            -- Check if it's a weps item (weps1/weps2)
            local isWepsItem = string.find(skinId, "weps1") or string.find(skinId, "weps2")
            -- Only non-weps Meshes items get special Z-axis rotation
            if not isWepsItem then
                currentBigViewIsOtherMeshes = true
            end
        end
        
        bigViewModel = setupViewport(bigViewport, src, {fitFactor = ITEM_FIT_FACTOR, minDist = ITEM_MIN_DIST, isBigViewport = true})
        
        -- Capture the base rotation after setupViewport applies weapon-specific rotations
        if bigViewModel then
            if bigViewModel:IsA("Model") and bigViewModel.PrimaryPart then
                bigViewBaseRotation = bigViewModel.PrimaryPart.CFrame
            elseif bigViewModel:IsA("BasePart") then
                bigViewBaseRotation = bigViewModel.CFrame
            else
                bigViewBaseRotation = CFrame.new()
            end
        end
        
        bigViewAngle=0; bigViewVelocity=0
        bindBigViewportControls(bigViewport)

        -- Cleanup any existing mythic effects
        if mythicEffectsCleanup then
            mythicEffectsCleanup()
            mythicEffectsCleanup = nil
        end

        -- Apply mythic effects to model if applicable
        local isMythic = (currentItemRarity == 5)
        if isMythic and MythicEffects and bigViewModel then
            -- Apply effects to both the viewport frame AND the model
            local _vpEffect, vpCleanup = MythicEffects.ApplyMythicFrameEffects(bigViewport)
            local _modelEffect, modelCleanup = MythicEffects.ApplyMythicModelEffects(bigViewModel)
            
            -- Combined cleanup function
            mythicEffectsCleanup = function()
                if vpCleanup then vpCleanup() end
                if modelCleanup then modelCleanup() end
            end
        end

        local data = fetchData()
        -- Derive base weapon from skin id like "M4-Dragoon" => "M4" for stats lookup
        local baseWeapon = (type(skinId) == "string" and skinId:match("^[^%-]+")) or skinId
        local ws = data and data.weaponStats and data.weaponStats[baseWeapon] or {bulletsShot=0, itemsShot=0, timeRolled=0}
        bulletsRow.Text = ("Bullets Shot: %d"):format(ws.bulletsShot or 0)
        itemsRow.Text   = ("Items Shot: %d"):format(ws.itemsShot or 0)
        timeRow.Text    = ("Time Rolled: %s"):format(fmtTime(ws.timeRolled))
        
        -- Normal EQUIP button
        equipBtn.Text = "EQUIP"
        equipBtn.BackgroundColor3 = C3(20,30,25) -- Normal color
        
        -- For mythic items, make the equip button blood red
        if isMythic then
            equipBtn.BackgroundColor3 = C3(120, 20, 30)
            equipBtn.TextColor3 = C3(255, 100, 100)
            
            -- Special border for mythic items
            local equipStroke = equipBtn:FindFirstChildOfClass("UIStroke")
            if equipStroke then
                equipStroke.Color = BLOOD_RED
                equipStroke.Thickness = 3
                equipStroke.Transparency = 0.1
            end
        end
    end
    
    gridView.Visible = false
    itemPage.Visible = true
    -- reset equip button state if not mythic
    if currentItemRarity ~= 5 then
        equipBtn.TextColor3 = BRIGHT_GREEN
    end
end

local function closeItemPage()
    itemPage.Visible = false
    gridView.Visible = true
    if bigViewRotateConn then bigViewRotateConn:Disconnect(); bigViewRotateConn=nil end
    bigViewModel = nil
    currentItemSkinName = nil
    currentItemRarity = nil
    
    -- Clean up mythic effects if they exist
    if mythicEffectsCleanup then
        mythicEffectsCleanup()
        mythicEffectsCleanup = nil
    end
end

backBtn.MouseButton1Click:Connect(closeItemPage)

-- Equip button behavior
equipBtn.MouseButton1Click:Connect(function()
    if not currentItemSkinName then return end
    
    -- Check if current item is a crate
    if isCrate(currentItemSkinName) then
        -- Open crate instead of equipping
        equipBtn.Active = false
        equipBtn.AutoButtonColor = false
        equipBtn.Text = "OPENING..."
        
        -- First, try to use the crate (remove from inventory)
        local PlayerDataRF = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if PlayerDataRF then
            PlayerDataRF = PlayerDataRF:FindFirstChild("PlayerDataRF")
        end
        if PlayerDataRF then
            local success, result = pcall(function()
                return PlayerDataRF:InvokeServer("UseCrate", {crateType = currentItemSkinName})
            end)
            
            if success and result and result.success then
                -- Crate was successfully removed, now open it
                closeItemPage()
                
                -- Small delay then open crate
                task.wait(0.3)
                if _G.OpenCrate then
                    _G.OpenCrate(currentItemSkinName)
                end
            else
                -- Failed to use crate
                equipBtn.Text = "NO CRATES"
                equipBtn.Active = true
                equipBtn.AutoButtonColor = true
                task.wait(2)
                equipBtn.Text = "OPEN"
            end
        else
            equipBtn.Text = "ERROR"
            equipBtn.Active = true
            equipBtn.AutoButtonColor = true
            task.wait(2)
            equipBtn.Text = "OPEN"
        end
        return
    end
    
    -- Normal skin equip behavior
    equipBtn.Active = false
    equipBtn.AutoButtonColor = false
    equipBtn.Text = "EQUIPPING..."
    local ok = equipSkinToTool(currentItemSkinName)
    if ok then
        equipBtn.Text = "EQUIPPED!"
        
        -- Use blood red for mythic confirmation
        if currentItemRarity == 5 then
            equipBtn.TextColor3 = C3(255, 120, 120)
        else
            equipBtn.TextColor3 = C3(180, 255, 200)
        end
    else
        equipBtn.Text = "NO TOOL"
        equipBtn.TextColor3 = C3(255, 120, 120)
    end
    task.delay(0.9, function()
        if equipBtn and equipBtn.Parent == itemPage and itemPage.Visible then
            local isItemCrate = isCrate(currentItemSkinName)
            equipBtn.Text = isItemCrate and "OPEN" or "EQUIP"
            
            -- Maintain blood red for mythics
            if currentItemRarity == 5 then
                equipBtn.TextColor3 = C3(255, 100, 100)
            else
                equipBtn.TextColor3 = BRIGHT_GREEN
            end
            
            equipBtn.Active = true
            equipBtn.AutoButtonColor = true
        end
    end)
end)

-- Create item slot with mythic effects
local function createItemSlot(sourceInstance, displayName)
    local name = displayName or (sourceInstance and sourceInstance.Name) or "Unknown"
    
    -- Rarities from SkinConfig
    local rarityValue = getSkinRarity(name)
    local rarityNames = {"COMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC"}
    local _rarityName = rarityNames[rarityValue] or "COMMON"
    
    -- Rarity colors for base styling
    local rarityColors = { 
        Color3.new(0.7, 0.7, 0.7),  -- Common: Light gray
        Color3.new(0.2, 0.6, 1.0),  -- Rare: Blue
        Color3.new(0.6, 0.2, 1.0),  -- Epic: Purple
        Color3.new(1.0, 0.8, 0.0),  -- Legendary: Gold
        BLOOD_RED                   -- Mythic: Blood Red
    }
    local rarityColor = rarityColors[rarityValue]
    
    -- Main slot container
    local slot = Instance.new("Frame")
    slot.Name = name
    -- Make slot bigger for 123 items to prevent clipping
    if string.match(name, "^123") then
        slot.Size = UDim2.new(0, 300, 0, 300) -- Much bigger for 123 items
    else
        slot.Size = UDim2.new(0, 222, 0, 170) -- Standard size: 234*0.95=222, 179*0.95=170
    end
    slot.BackgroundColor3 = C3(10,15,12)
    slot.BackgroundTransparency = 1 -- Made completely transparent to remove grey background
    slot.BorderSizePixel = 0
    -- Lower ZIndex so aura renders on top
    if string.match(name, "^123") then
        slot.ZIndex = 1 -- Lower than aura (was 100)
    else
        slot.ZIndex = 1 -- Lower than aura (was 5)
    end
    -- Disable ClipsDescendants for 123 items to allow models to extend beyond slot
    if string.match(name, "^123") then
        slot.ClipsDescendants = false
    end
    slot.Parent = inventoryContainer
    slot.Active = true -- Enable mouse events on the slot
    
    -- Rounded corners (skip for 123 items to prevent clipping)
    if not string.match(name, "^123") then
        local corner = Instance.new("UICorner", slot)
        corner.CornerRadius = UDim.new(0, 12)
    end
    
    -- UIScale for hover effects (works with UIGridLayout)
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1.0
    uiScale.Parent = slot
    
    -- Border stroke - no borders for any rarity (clean look for all)
    -- All rarities (common, rare, epic, legendary, mythic) have no borders
    
    -- Viewport container - slightly above center positioning for all items
    local viewportContainer = Instance.new("Frame")
    if rarityValue == 4 or rarityValue == 5 then -- No padding for legendary and mythic
        viewportContainer.Size = UDim2.new(0, 115, 0, 115) -- 115x115 for all items
        viewportContainer.Position = UDim2.new(0.5, 0, 0.41, 0) -- 5px higher from top (was 0.45)
    else
        viewportContainer.Size = UDim2.new(0, 115, 0, 115) -- 115x115 for all items
        viewportContainer.Position = UDim2.new(0.5, 0, 0.41, 0) -- 5px higher from top (was 0.45)
    end
    viewportContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    viewportContainer.BackgroundTransparency = 1 -- Fully transparent for all rarities
    viewportContainer.BorderSizePixel = 0
    -- Lower ZIndex so aura renders on top
    if string.match(name, "^123") then
        viewportContainer.ZIndex = 2 -- Lower than aura (was 101)
        viewportContainer.ClipsDescendants = false
    else
        viewportContainer.ZIndex = 2 -- Lower than aura (was 6)
    end
    viewportContainer.Active = false -- Don't let this container block mouse events
    viewportContainer.Parent = slot
    
    -- Only add UICorner if it's NOT a 123 item (removes clipping/limiter for 123 items)
    if not string.match(name, "^123") then
        local vcCorner = Instance.new("UICorner", viewportContainer)
        vcCorner.CornerRadius = UDim.new(0, 8)
    end
    
    -- Viewport for 3D model
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.fromOffset(160, 135) -- 160 wide, 135 tall
    viewport.Position = UDim2.fromScale(0.5, 0.5)
    viewport.AnchorPoint = Vector2.new(0.5, 0.5)
    viewport.BackgroundTransparency = 1
    viewport.BorderSizePixel = 0
    viewport.Active = false -- Don't let viewport block mouse events
    -- Lower ZIndex so aura renders on top
    if string.match(name, "^123") then
        viewport.ZIndex = 3 -- Lower than aura (was 102)
        viewport.ClipsDescendants = false
    else
        viewport.ZIndex = 3 -- Lower than aura (was 7)
    end
    viewport.Parent = viewportContainer
    
    -- Setup 3D model in viewport with closer camera for Meshes items
    -- The setupViewport function will automatically detect Meshes items and move camera closer
    local slotModel = setupViewport(viewport, sourceInstance, {fitFactor = SLOT_FIT_FACTOR, minDist = SLOT_MIN_DIST})
    if not sourceInstance then
        -- Placeholder for missing models
        local placeholder = Instance.new("TextLabel")
        placeholder.Size = UDim2.fromScale(1, 1)
        placeholder.BackgroundTransparency = 1
        placeholder.Text = "?"
        placeholder.TextColor3 = Color3.new(0.7, 0.7, 0.7)
        placeholder.TextSize = 24
        placeholder.Font = Enum.Font.FredokaOne
        placeholder.TextXAlignment = Enum.TextXAlignment.Center
        placeholder.TextYAlignment = Enum.TextYAlignment.Center
        placeholder.ZIndex = 8
        placeholder.Parent = viewportContainer
    end
    
    -- Name label with rarity styling - don't apply color for legendary and mythic
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    if rarityValue == 5 then -- Mythic items positioned higher
        nameLabel.Position = UDim2.new(0.5, 0, 1, -55) -- 5 pixels lower (was -60)
    elseif rarityValue == 4 then -- Legendary items
        nameLabel.Position = UDim2.new(0.5, 0, 1, -45) -- 5 pixels lower (was -50)
    else
        nameLabel.Position = UDim2.new(0.5, 0, 1, -50) -- 5 pixels lower (was -55)
    end
    nameLabel.AnchorPoint = Vector2.new(0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.FredokaOne
    
    -- Process name: remove "Meshes/" and capitalize first letters
    local processedName = name
    
    -- Check if it's a crate and use the display name from config
    if isCrate(name) then
        local crateData = CrateConfig and CrateConfig.GetCrate(name)
        if crateData and crateData.name then
            processedName = crateData.name
        end
    elseif string.find(name, "Meshes/") then
        processedName = string.gsub(name, "Meshes/", "") -- Remove "Meshes/"
        -- Capitalize first letter of each word
        processedName = string.gsub(processedName, "(%l)([%w_']*)", function(first, rest)
            return string.upper(first) .. rest
        end)
    end
    
    nameLabel.Text = processedName
    nameLabel.TextSize = 21 -- Increased from 18 to 21 (bigger text)
    -- Apply rarity colors for all items including legendary and mythic
    nameLabel.TextColor3 = rarityColor
    nameLabel.TextWrapped = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.ZIndex = 10000  -- Higher than anything else
    nameLabel.Parent = slot
    
    -- Apply mythic blood-red effects for mythic items
    local slotEffectsCleanup
    if rarityValue == 5 and MythicEffects then
        -- Apply to slot frame - the UI lightning
        local _, cleanup = MythicEffects.ApplyMythicFrameEffects(slot)
        slotEffectsCleanup = cleanup
        
        -- Also apply effects to the 3D model in viewport if it exists
        if slotModel then
            local success, modelCleanup = MythicEffects.ApplyMythicModelEffects(slotModel)
            if success then
                local originalCleanup = slotEffectsCleanup
                slotEffectsCleanup = function()
                    if originalCleanup then originalCleanup() end
                    if modelCleanup then modelCleanup() end
                end
            end
        end
    end
    
    -- Apply legendary yellow aura effects for legendary items
    if rarityValue == 4 and LegendaryAura then
        -- Find the gridView container for proper aura parenting
        local inventoryContainer = slot.Parent
        local gridView = inventoryContainer and inventoryContainer.Parent
        if gridView and gridView.Name == "GridView" then
            local _, auraCleanup = LegendaryAura.ApplyLegendaryAuraEffect(slot, gridView)
            if auraCleanup then
                local originalCleanup = slotEffectsCleanup
                slotEffectsCleanup = function()
                    if originalCleanup then originalCleanup() end
                    if auraCleanup then auraCleanup() end
                end
            end
        end
    end
    
    -- Apply epic purple particle effects for epic items
    if rarityValue == 3 and EpicAura then
        -- Find the gridView container for proper aura parenting
        local inventoryContainer = slot.Parent
        local gridView = inventoryContainer and inventoryContainer.Parent
        if gridView and gridView.Name == "GridView" then
            local _, auraCleanup = EpicAura.ApplyEpicAuraEffect(slot, gridView)
            if auraCleanup then
                local originalCleanup = slotEffectsCleanup
                slotEffectsCleanup = function()
                    if originalCleanup then originalCleanup() end
                    if auraCleanup then auraCleanup() end
                end
            end
        end
    end

    -- Apply rare green particle effects for rare items
    if rarityValue == 2 and RareAura then
        -- Find the gridView container for proper aura parenting
        local inventoryContainer = slot.Parent
        local gridView = inventoryContainer and inventoryContainer.Parent
        if gridView and gridView.Name == "GridView" then
            local _, auraCleanup = RareAura.ApplyRareAuraEffect(slot, gridView)
            if auraCleanup then
                local originalCleanup = slotEffectsCleanup
                slotEffectsCleanup = function()
                    if originalCleanup then originalCleanup() end
                    if auraCleanup then auraCleanup() end
                end
            end
        end
    end

    -- Apply common aura effects for common items
    if rarityValue == 1 and CommonAura then
        -- Find the gridView container for proper aura parenting
        local inventoryContainer = slot.Parent
        local gridView = inventoryContainer and inventoryContainer.Parent
        if gridView and gridView.Name == "GridView" then
            local _, auraCleanup = CommonAura.ApplyCommonAuraEffect(slot, gridView)
            if auraCleanup then
                local originalCleanup = slotEffectsCleanup
                slotEffectsCleanup = function()
                    if originalCleanup then originalCleanup() end
                    if auraCleanup then auraCleanup() end
                end
            end
        end
    end
    
    -- Click handler
    local clickButton = Instance.new("TextButton")
    clickButton.Size = UDim2.fromScale(1, 1)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.ZIndex = 50
    clickButton.Active = true
    clickButton.AutoButtonColor = false
    clickButton.Parent = slot
    
    -- Hover effects
    clickButton.MouseEnter:Connect(function()
        TweenService:Create(uiScale, 
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1.1}
        ):Play()
        
        -- Show details panel
        local sp, ss = slot.AbsolutePosition, slot.AbsoluteSize
        local view = workspace.CurrentCamera.ViewportSize
        local x = sp.X + ss.X * 1.2
        if x + 180 > view.X then x = sp.X - 180 end
        detailsPanel.Position = UDim2.new(0, x, 0, sp.Y)
        detailsPanel.Size = UDim2.fromOffset(0, 60)
        detailsPanel.Visible = true
        
        local displayName = name
        local weaponInfo = "Unknown"
        
        if isCrate(name) then
            local crateData = CrateConfig and CrateConfig.GetCrate(name)
            if crateData then
                displayName = crateData.name
                weaponInfo = "Crate"
            end
        else
            local skinMeta = getSkinMeta(name)
            weaponInfo = skinMeta and skinMeta.weapon or "Unknown"
        end
        
        local detailText = string.format("%s\n%s %s", displayName, rarityNames[rarityValue], weaponInfo)
        setDetailsText(detailText)
        
        -- For mythic items, change tooltip color to blood red
        if rarityValue == 5 then
            local detailsStroke = detailsPanel:FindFirstChildOfClass("UIStroke")
            if detailsStroke then
                detailsStroke.Color = BLOOD_RED
                detailsStroke.Transparency = 0.1
                detailsStroke.Thickness = 3
            end
            
            local textLabel = detailsPanel:FindFirstChildOfClass("TextLabel")
            if textLabel then
                textLabel.TextColor3 = C3(255, 100, 100)
            end
        end
        
        TweenService:Create(detailsPanel, 
            TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.fromOffset(180, 60)}
        ):Play()
    end)
    
    clickButton.MouseLeave:Connect(function()
        TweenService:Create(uiScale, 
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1.0}
        ):Play()
        
        detailsPanel.Visible = false
        
        -- Reset tooltip colors
        local detailsStroke = detailsPanel:FindFirstChildOfClass("UIStroke")
        if detailsStroke then
            detailsStroke.Color = GREEN
            detailsStroke.Transparency = 0.3
            detailsStroke.Thickness = 2
        end
        
        local textLabel = detailsPanel:FindFirstChildOfClass("TextLabel")
        if textLabel then
            textLabel.TextColor3 = BRIGHT_GREEN
        end
    end)
    
    clickButton.MouseButton1Click:Connect(function()
        openItemPage(name)
    end)
    
    -- Cleanup function for effects when slot is destroyed
    slot.AncestryChanged:Connect(function(_, newParent)
        if not newParent and slotEffectsCleanup then
            slotEffectsCleanup()
            slotEffectsCleanup = nil
        end
    end)
    
    return slot, slotModel
end

-- Populate inventory
local function populateInventory()
    for _,c in ipairs(inventoryContainer:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end
    
    local allSkinsList = {}
    
    if currentTab == "skins" then
        -- Get all skins from SkinConfig
        allSkinsList = SkinConfig.GetAllSkinNames()
        
        -- Update tab buttons visual state
        skinsTabBtn.BackgroundColor3 = BLACK
        skinsTabBtn.BackgroundTransparency = 0
        skinsTabBtn.TextColor3 = BRIGHT_GREEN
        
        cratesTabBtn.BackgroundColor3 = C3(20,30,25)
        cratesTabBtn.BackgroundTransparency = 0.5
        cratesTabBtn.TextColor3 = GREEN
        
    elseif currentTab == "crates" then
        -- Add crates to the list
        if CrateConfig then
            local crates = CrateConfig.GetAllCrates()
            for crateName, _ in pairs(crates) do
                -- Only add if player owns it (count > 0)
                if playerData and playerData.boxes and playerData.boxes[crateName] and playerData.boxes[crateName] > 0 then
                    table.insert(allSkinsList, crateName)
                end
            end
        end
        
        -- Update tab buttons visual state
        skinsTabBtn.BackgroundColor3 = C3(20,30,25)
        skinsTabBtn.BackgroundTransparency = 0.5
        skinsTabBtn.TextColor3 = GREEN
        
        cratesTabBtn.BackgroundColor3 = BLACK
        cratesTabBtn.BackgroundTransparency = 0
        cratesTabBtn.TextColor3 = BRIGHT_GREEN
    end
    
    -- Filter by search term
    if currentSearchTerm ~= "" then
        local filteredList = {}
        local searchLower = string.lower(currentSearchTerm)
        for _, skinName in ipairs(allSkinsList) do
            local matchName = skinName
            -- If it's a crate, search against its display name (e.g. "Bronze Crate")
            if isCrate(skinName) then
                local crateData = CrateConfig and CrateConfig.GetCrate(skinName)
                if crateData and crateData.name then
                    matchName = crateData.name
                end
            end
            
            if string.find(string.lower(matchName), searchLower, 1, true) then
                table.insert(filteredList, skinName)
            end
        end
        allSkinsList = filteredList
    end
    
    -- Apply sort based on current mode
    if currentSortMode == "rarity" then
        -- Sort by rarity (mythic items first)
        table.sort(allSkinsList, function(a, b)
            local rarityA = getSkinRarity(a)
            local rarityB = getSkinRarity(b)
            
            if rarityA ~= rarityB then
                return rarityA > rarityB -- Higher rarity first
            end
            return string.lower(a) < string.lower(b) -- Alphabetical tiebreaker
        end)
    else
        -- Sort alphabetically
        table.sort(allSkinsList, function(a,b) return string.lower(a) < string.lower(b) end)
    end
    
    for i, skinName in ipairs(allSkinsList) do
        local inst = getSkinInstance(skinName)
        local slot = createItemSlot(inst, skinName)
        if slot then
            slot.LayoutOrder = i
            
            -- Z-index layering: higher rarity gets higher Z-index, each slot higher than previous
            local rarity = getSkinRarity(skinName)
            local baseZIndex = 5 -- Starting Z-index
            if rarity == 5 then -- mythic
                baseZIndex = 5005
            elseif rarity == 4 then -- legendary  
                baseZIndex = 4004
            elseif rarity == 3 then -- epic
                baseZIndex = 3003
            elseif rarity == 2 then -- rare
                baseZIndex = 2002
            else -- common
                baseZIndex = 1001
            end
            
            -- Each slot gets lower Z-index than the previous (so earlier items are on top)
            slot.ZIndex = baseZIndex - i
        end
    end
end

-- Tab button connections
skinsTabBtn.MouseButton1Click:Connect(function()
    if currentTab ~= "skins" then
        currentTab = "skins"
        populateInventory()
    end
end)

cratesTabBtn.MouseButton1Click:Connect(function()
    if currentTab ~= "crates" then
        currentTab = "crates"
        populateInventory()
    end
end)

-- Top stats refresh
local function refreshTopStats()
    local data = fetchData()
    if not data then return end
    
    local money = tonumber(data.money) or 0
    local coins = tonumber(data.trumpCoin) or 0  
    local rank  = tonumber(data.rank) or 1
    
    moneyValue.Text = tostring(money)
    coinValue.Text  = tostring(coins)
    rankValue.Text = tostring(rank)
    
    -- Update rank chevrons
    for i=1,5 do
        local ch = rankChevrons:FindFirstChild("Ch"..i)
        if ch then ch.ImageTransparency = (i <= math.clamp(rank,1,5)) and 0 or 0.7 end
    end

    -- Rank progress bar update
    local prog = data.rankProgress
    if prog then
        local fill = rankProgressFill
        local label = rankProgressLabel
        local frac = prog.overallFrac or 0
        TweenService:Create(fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(frac,0,1,0)}):Play()
        if prog.isMax then
            label.Text = string.format("R%d MAX", prog.currentRank)
        else
            label.Text = string.format("R%d→R%d %.0f%%", prog.currentRank, prog.nextRank, frac*100)
        end
    else
        rankProgressLabel.Text = ""
        TweenService:Create(rankProgressFill, TweenInfo.new(0.2), {Size = UDim2.new(0,0,1,0)}):Play()
    end
end

-- Toggle
local isOpen, isBusy = false, false

-- Mouse enabler functions
local function enableInventoryMouse()
    _G.UIMouseEnabler = true
    pcall(function()
        player.CameraMode = Enum.CameraMode.Classic
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end)
end

local function disableInventoryMouse()
    _G.UIMouseEnabler = false
    
    -- Restore first-person mode if FirstPersonForcer is active
    if _G.FirstPersonForcer then
        pcall(function()
            player.CameraMode = Enum.CameraMode.LockFirstPerson
            player.CameraMinZoomDistance = 0.5
            player.CameraMaxZoomDistance = 0.5
        end)
    end
end

-- Function to start rain effect (with cleanup of previous rain)
local function startRainEffect()
    -- Clean up existing rain first
    if rainCleanup then
        rainCleanup()
        rainCleanup = nil
    end
    
    -- Start new rain effect and store cleanup function
    rainCleanup = playOrganicMatrixRain(main, {
        color = BRIGHT_GREEN,
        zIndex = 1, -- Lower than all interactive elements
        textSize = 14
    })
end

local function toggleInventory()
    if isBusy then return end; isBusy = true
    if not isOpen then
        _G.InventoryUIOpen = true
        enableInventoryMouse()
        
        backdrop.Visible=true; main.Visible=true; main.Size=UDim2.fromOffset(0,0)
        TweenService:Create(backdrop, TweenInfo.new(0.15), {BackgroundTransparency=0.5}):Play()
        TweenService:Create(blur, TweenInfo.new(0.15), {Size=10}):Play()
        local t = TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.fromOffset(840,624)})
        t:Play(); t.Completed:Connect(function()
            isOpen=true; isBusy=false
            refreshTopStats()
            populateInventory()
            
            -- Start rain effect when inventory opens
            startRainEffect()
            
            -- Update stats while open
            task.spawn(function()
                local token = Instance.new("BoolValue")
                token.Name = "OpenToken"
                token.Parent = main
                while token.Parent and isOpen do
                    refreshTopStats()
                    task.wait(4) -- Refresh every 4 seconds
                end
                if token and token.Parent then token:Destroy() end
            end)
        end)
    else
        _G.InventoryUIOpen = false
        disableInventoryMouse()
        
        if itemPage.Visible then closeItemPage() end
        TweenService:Create(backdrop, TweenInfo.new(0.15), {BackgroundTransparency=1}):Play()
        TweenService:Create(blur, TweenInfo.new(0.15), {Size=0}):Play()
        local t = TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size=UDim2.fromOffset(0,0)})
        t:Play()
        t.Completed:Connect(function() 
            backdrop.Visible = false
            main.Visible = false
            isOpen = false
            isBusy = false
            detailsPanel.Visible = false 
            
            -- Clean up rain effect when inventory closes
            if rainCleanup then
                rainCleanup()
                rainCleanup = nil
            end
        end)
    end
end

-- Search box event handler
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    currentSearchTerm = searchBox.Text
    populateInventory()
end)

-- Sort dropdown functionality
local isDropdownOpen = false

sortBtn.MouseButton1Click:Connect(function()
    isDropdownOpen = not isDropdownOpen
    sortDropdown.Visible = isDropdownOpen
end)

sortOption1.MouseButton1Click:Connect(function()
    currentSortMode = "alphabetical"
    sortBtn.Text = "Sort: Alphabetical"
    sortDropdown.Visible = false
    isDropdownOpen = false
    populateInventory()
end)

sortOption2.MouseButton1Click:Connect(function()
    currentSortMode = "rarity"
    sortBtn.Text = "Sort: Rarity"
    sortDropdown.Visible = false
    isDropdownOpen = false
    populateInventory()
end)

-- Only X closes
closeBtn.MouseButton1Click:Connect(function() 
    if isOpen then toggleInventory() end 
end)

-- B/Escape bindings
ContextActionService:BindAction(
    "ToggleMatrixVault",
    function(_, inputState)
        if inputState == Enum.UserInputState.Begin then 
            toggleInventory() 
        end
        return Enum.ContextActionResult.Sink
    end,
    false,
    Enum.KeyCode.B
)

ContextActionService:BindAction(
    "CloseMatrixVault",
    function(_, inputState)
        if inputState == Enum.UserInputState.Begin and isOpen then 
            toggleInventory() 
        end
        return Enum.ContextActionResult.Sink
    end,
    false,
    Enum.KeyCode.Escape
)

-- Mobile button for touch devices
if UserInputService.TouchEnabled then
    local mb = Instance.new("TextButton")
    mb.Size = UDim2.fromOffset(50,50)
    mb.Position = UDim2.new(0,20,1,-70)
    mb.AnchorPoint = Vector2.new(0,1)
    mb.BackgroundColor3 = C3(10,20,15)
    mb.Text = "📋"
    mb.TextSize = 24
    mb.TextColor3 = GREEN
    mb.Parent = gui
    Instance.new("UICorner", mb).CornerRadius = UDim.new(0,25)
    local s = Instance.new("UIStroke", mb)
    s.Color = GREEN
    s.Thickness = 2
    mb.MouseButton1Click:Connect(toggleInventory)
end

-- Initialize inventory
populateInventory()
refreshTopStats()

-- Start initial rain effect
startRainEffect()

-- Debug function to test mythic effects on an item
local function testMythicEffect(slotName)
    for _, item in pairs(inventoryContainer:GetChildren()) do
        if item.Name == slotName then
            MythicEffects.ApplyMythicFrameEffects(item)
            return true
        end
    end
    return false
end

-- Return global API
_G.MatrixInventory = {
    ToggleInventory = toggleInventory,
    RefreshStats = refreshTopStats,
    IsOpen = function() return isOpen end,
    Close = function() if isOpen then toggleInventory() end end,
    TestMythicEffect = testMythicEffect
}

return _G.MatrixInventory
