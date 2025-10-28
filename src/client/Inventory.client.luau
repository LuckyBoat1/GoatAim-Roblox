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
print("DEBUG: MythicEffects module loaded successfully:", MythicEffects ~= nil)
print("DEBUG: Testing MythicEffects:", MythicEffects.Test and MythicEffects.Test() or "Test function not found")
print("EPICAURA DEBUG: EpicAura module loaded successfully:", EpicAura ~= nil)
print("EPICAURA DEBUG: Testing EpicAura:", EpicAura.Test and EpicAura.Test() or "Test function not found")

-- Color shortcuts
local function C3(r,g,b) return Color3.fromRGB(r,g,b) end
local GREEN, BRIGHT_GREEN, DIM_GREEN = C3(20,250,120), C3(50,255,150), C3(10,160,80)
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

-- Header
local header = Instance.new("Frame"); header.Size=UDim2.new(1,0,0,60); header.BackgroundColor3=C3(10,15,12); header.BackgroundTransparency=0.2; header.Parent=main
Instance.new("UICorner", header).CornerRadius=UDim.new(0,12)
local title = Instance.new("TextLabel")
title.Size=UDim2.new(1,-20,1,0); title.Position=UDim2.new(0,20,0,0); title.BackgroundTransparency=1
title.Font=Enum.Font.Code; title.Text="VAULT"; title.TextSize=28; title.TextColor3=GREEN; title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=header

local closeBtn = Instance.new("TextButton")
closeBtn.Size=UDim2.fromOffset(40,40); closeBtn.Position=UDim2.new(1,-20,0.5,0); closeBtn.AnchorPoint=Vector2.new(1,0.5)
closeBtn.BackgroundColor3=C3(20,30,25); closeBtn.BackgroundTransparency=0.2; closeBtn.Text="X"; closeBtn.TextColor3=GREEN; closeBtn.TextSize=20; closeBtn.Font=Enum.Font.Code; closeBtn.Parent=header
Instance.new("UICorner", closeBtn).CornerRadius=UDim.new(0,8)

-- Data fetching
local currentSearchTerm = ""
local currentSortMode = "alphabetical" -- "alphabetical" or "rarity"

local function fetchData()
    if not GetPlayerData then return nil end
    local ok, d = pcall(function() return GetPlayerData:InvokeServer() end)
    if ok and type(d) == "table" then return d end
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
                    lbl.Font = Enum.Font.Code
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
    "Adurite",
    "AlphaSapphire",
    "Ambassador",
    "AppleShooter",
    "Aqua",
    "BlackIron",
    "BlueSteel",
    "ComputerBlaster",
    "CyanMissingTextureRevolver",
    "Donkey",
    "DreamsOfRevolvers",
    "Ali",
    "Engraved",
    "Fabulous",
    "Galactic",
    "Gold",
    "HyperRed",
    "Infiltrator",
    "MSRevolver",
    "McDonald",
    "Molecular",
    "Overseer",
    "OriginalRevolver",
    "NightStalker",
    "Portal",
    "Rainbow",
    "Rose",
    "Revolver",
    "RevolverOfDestiny",
    "Sand",
    "Sparkletime",
    "Starplayer",
    "Splitfire",
    "TheHyperLaser",
    "United",
    "Amp",
    "IRevolver",
    "Type99",
    "Tommygun"
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
        "ak chaos", "ak ice", "ak jungle", "as val", "ambassador", "black kite", "carbon", "chaser", "classic", "diamondback", "enforcer", "flare gun", "frontier", "handgun", "heatmaker", "huntsman", "l'etranger", "leaderboard", "leech gun", "machina", "makarov", "natasha", "overuse", "p99", "pb", "pm", "quick fix", "sig220", "sig550", "svd", "spaz", "spawn off", "svu", "thunder s14", "trs301", "viper mp5", "vac", "wangler"
    }
    local meItems = {
        "apple shooter", "aqua", "azerite alpha sapphire ambassador", "black iron", "blue steel", "computer blaster", "crossbow", "donkey", "elite", "engraved", "fabulous", "galactic", "gold", "hyperred", "ms revolver", "mcdonald", "molecular", "night stalker", "original", "portal", "rainbow", "revolver of destiny", "rose", "sand", "sparkle time", "starplayer", "the hyper laser", "united", "ubersaw"
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
    local isGoblinItem = string.find(sourceName, "Goblin_") ~= nil
    
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
            cam.FieldOfView = 15 -- Closer FOV for big viewport Meshes items
        else
            cam.FieldOfView = 12 -- Narrow FOV for small viewport
        end
    elseif isGoblinItem then
        cam.FieldOfView = 60 -- Special FOV for Goblin items
    elseif sourceName == "SPAS" then
        cam.FieldOfView = 60 -- Special FOV for SPAS
    elseif sourceName == "Chaser" then
        cam.FieldOfView = 55 -- Special FOV for Chaser
    elseif sourceName == "8Bit" or sourceName == "Ball" or sourceName == "Borders" or sourceName == "Caution" or 
           sourceName == "Cheesy" or sourceName == "Crystal" or sourceName == "Kypto" or
           sourceName == "Linked" or sourceName == "Missing" or sourceName == "Vision" or sourceName == "Rainbow" or
           sourceName == "Slate" or sourceName == "Sparkles" or sourceName == "Spectum" or sourceName == "Stalker" or
           sourceName == "Swag" then
        cam.FieldOfView = 55 -- Special FOV for rotated blade items (increased by 20: 35→55)
    elseif sourceName == "Chroma" then
        cam.FieldOfView = 55 -- Special FOV for Chroma (reduced by 5: 60→55)
    elseif sourceName == "Chroma Fang" then
        cam.FieldOfView = 80 -- Special FOV for Chroma Fang (increased by 5 more: 75→80)
    elseif sourceName == "Fang" then
        cam.FieldOfView = 80 -- Special FOV for Fang (increased by 5 more: 75→80)
    elseif sourceName == "Ego" or sourceName == "Power" or sourceName == "Blizzard" then
        cam.FieldOfView = 55 -- Special FOV for Ego, Power, and Blizzard (set to 55)
    elseif sourceName == "Wolf" then
        cam.FieldOfView = 38 -- Special FOV for Wolf (reduced by 12 from original default 50)
    else
        cam.FieldOfView = 45 -- Default field of view (reduced by 5 from 50 for closer view)
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
    local needsChaserRotation = false
    print("[DEBUG] Processing item: '" .. tostring(sourceName) .. "', isBigViewport: " .. tostring(opts.isBigViewport))
    
    if not (opts.isBigViewport) then
        -- Check if this item should face left (Z-axis rotation)
        local itemsToRotateLeft = {
            "Adurite Revolver", "AlphaSapphire Revolver", "Ambassador Revolver", "AppleShooter Revolver", 
            "Aqua Revolver", "BlackIron Revolver", "Bluesteel Revolver", "ComputerBlaster Revolver",
            "CyanMissingTexture Revolver", "Donkey Revolver", "Dreams of Revolvers", "Engraved Revolver",
            "Fabulous Revolver", "Galactic Revolver", "Gold Revolver", "HyperRed Revolver",
            "Infiltrator Revolver", "MS Revolver", "McDonald Revolver", "Molecular Revolver",
            "Overseer Revolver", "Original Revolver", "NightStalker Revolver", "Portal Revolver",
            "Rainbow Revolver", "Rose Revolver", "Revolver of Destiny", "Sand Revolver",
            "SparkleTime Revolver", "StarPlayer Revolver", "Splitfire Revolver", "TheHyperLaser Revolver",
            "United States Revolver", "iRevolver", "tommy gun"
        }
        
        -- Check if this item needs test 1 rotation (-90 Y-axis)
        local testItems = {
            "AK-Chaos", "AK-Ice", "AK-Jungle", "L85", "Makarov", "PB", 
            "SVU", "SiG550", "TOZ", "Viper/Mp5", "Tunder S14", "sawn-off",
            "Blood%Bones", "Cyborg", "Death", "leciathan", "Sun"
        }
        
        -- Check if this item needs test 2 rotation (-90 Z-axis)
        local test2Items = {
            "Fort", "Handgun", "PM", 
            "RPG-7", "SVD", "SPAS", "ambassador", "backburner", "bazaar", "carbine", "classic", 
            "crossbow", "diamondback", "enforcer", "flaregun", "frontier", "heatmaker", "le'tranger", 
            "leechgun", "machina", "natach", "overuse", "quickfix", "sleeper", "vac", "wrangler"
        }
        
        -- Check if this item needs special Y-axis rotation (+90 degrees)
        local specialYRotationItems = {
            "20MM L39"
        }
        
        -- Check if this item needs special X and Z rotation (180 degrees each)
        local specialXZRotationItems = {
            "Enfield Bren"
        }
        
        -- Check if this item needs test 4 rotation (-90 degrees on X axis)
        local test4Items = {
            "FN2000", "P99", "Sig220", "Black kite"
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
            "Tunder S14", "SiG550", "sawn-off", 
            "PB", "Makarov", "L85", "TOZ", "SVU"
        }
        
        -- Check if this item needs test 16 rotation (90 degrees on X and Z axes)
        local test16Items = {
            "PM", "SPAS", "SVD", "Fort"
        }
        
        -- Check if this item needs test 17 rotation (90 degrees on Z axis only)
        local test17Items = {
            "Elite Revolver"
        }
        
        -- Check if this item needs test 18 rotation (90 degrees on Z and 180 degrees on X axes)  
        local test18Items = {
            "RPG-7"
        }
        
        -- Check if this item needs test 19 rotation (90 degrees on Z and X axes)
        local test19Items = {
            "ubersaw"
        }
        
        -- Check if this item needs test 20 rotation (180 degrees on Z axis only)
        local test20Items = {
            "tommy gun"
        }
        
        -- Check if this item needs test 21 rotation (90° Y only for blade skins - excluding Fang and Chroma Fang)
        local test21Items = {
            "8Bit", "Ball", "Borders", "Caution", "Cheesy", "Chroma", 
            "Crystal", "Kypto", "Linked", "Missing", "Vision", 
            "Rainbow", "Slate", "Sparkles", "Spectum", "Stalker", "Swag"
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
            "amp"
        }
        
        -- Check if this item needs test 25 rotation (removed - reverted to original)
        local test25Items = {
            -- Removed 20MM L39 - reverted to original rotation
        }
        
        -- Check if this item needs test 26 rotation (90° X + 90° Z)
        local test26Items = {
            "shna"
        }
        
        -- Check if this item needs test 27 rotation (-90° Z only)
        local test27Items = {
            "TRS-301"
        }
        
        -- Check if this item needs test 28 rotation (180° X + 180° Z)
        local test28Items = {
            "XM24A3"
        }
        
        -- Check if this item needs test 29 rotation (180° Y + 30° Z + 90° X)
        local test29Items = {
            "type 99"
        }
        
        -- Check if this item needs test 30 rotation (360° X + 90° Z)
        local test30Items = {
            "PKM"
        }
        
        -- Check if this item needs test 31 rotation (270° Z + 90° X)
        local test31Items = {
            "shiv"
        }
        
        -- Check if this item needs test 32 rotation (90° Z + 90° X)
        local test32Items = {
        }
        
        -- Check if this item needs test 33 rotation (270° Z)
        local test33Items = {
            "Vintorez"
        }
        
        -- Check if this item needs test 34 rotation (-90° Z + 90° X)
        local test34Items = {
            "Viper/Mp5"
        }
        
        -- Check if this item needs test 35 rotation (90° X + 90° Z)
        local test35Items = {
            "vita"
        }
        
        -- Check if this item needs test 36 rotation (90° Z + 90° X)
        local test36Items = {
            "waka"
        }
        
        -- Check if this item needs test 37 rotation (15° X + 90° Y + 180° Z - facing left)
        local test37Items = {
        }
        
        -- Check if this item needs test 38 rotation (90° Y + 90° Z)
        local test38Items = {
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
    end
    
    if needsTest4Rotation then
        -- Rotate 90 degrees on X axis and 270 degrees on Z axis for test 4 items (FN2000, P99, Sig220, Black kite)
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
        -- Rotate 90 degrees on X axis and 270 degrees on Z axis for test 15 items (Viper/Mp5, MP5, tommy gun, etc.)
        local test15Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test15Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test15Rotation
        end
    elseif needsTest16Rotation then
        -- Rotate 90 degrees on X axis and 90 degrees on Z axis for test 16 items (PM, SPAS, SVD, Fort)
        local test16Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test16Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test16Rotation
        end
    elseif needsTest17Rotation then
        -- Rotate 90 degrees on Z axis only for test 17 items (Elite Revolver, Chaser, RPG-7, tommy gun, ubersaw)
        local test17Rotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test17Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test17Rotation
        end
    elseif needsTest18Rotation then
        -- Rotate -90 degrees on Z and 360 degrees on X for test 18 items (RPG-7)
        local test18Rotation = CFrame.Angles(math.rad(360), math.rad(0), math.rad(-90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test18Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test18Rotation
        end
    elseif needsTest19Rotation then
        -- Rotate 90 degrees on Z and -90 degrees on X for test 19 items (ubersaw)
        local test19Rotation = CFrame.Angles(math.rad(-90), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test19Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test19Rotation
        end
    elseif needsTest20Rotation then
        -- Rotate 360 degrees on Z for test 20 items (tommy gun)
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
        local test22Rotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90))
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
        -- Rotate 90 degrees on Z and -90 degrees on X for test 24 items (amp)
        local test24Rotation = CFrame.Angles(math.rad(-90), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test24Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test24Rotation
        end
    elseif needsTest25Rotation then
        -- Rotate 30 degrees on X for test 25 items (20MM L39)
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
        -- Rotate 180 degrees on X and 180 degrees on Z for test 28 items (XM24A3)
        local test28Rotation = CFrame.Angles(math.rad(180), math.rad(0), math.rad(180))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test28Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test28Rotation
        end
    elseif needsTest29Rotation then
        -- Rotate 180 degrees on Y, 30 degrees on Z, and 360 degrees on X for test 29 items (type 99)
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
        -- Rotate 270 degrees on Z and 90 degrees on X for test 31 items (shiv)
        local test31Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test31Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test31Rotation
        end
    elseif needsTest32Rotation then
        -- Rotate 90 degrees on Z and 90 degrees on X for test 32 items (SKS Wood Large)
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
        -- Rotate -90 degrees on Z and 90 degrees on X for test 34 items (Viper/Mp5)
        local test34Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(-90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test34Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test34Rotation
        end
    elseif needsTest35Rotation then
        -- Rotate 90 degrees on X and 90 degrees on Z for test 35 items (vita)
        local test35Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test35Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test35Rotation
        end
    elseif needsTest36Rotation then
        -- Rotate 90 degrees on Z and 90 degrees on X for test 36 items (waka - keeping same)
        local test36Rotation = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test36Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test36Rotation
        end
    elseif needsTest37Rotation then
        -- Rotate for SKS variants to face left (15° X + 90° Y + 180° Z)
        local test37Rotation = CFrame.Angles(math.rad(15), math.rad(90), math.rad(180))
        if clone:IsA("Model") and clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * test37Rotation)
        elseif clone:IsA("BasePart") then
            clone.CFrame = clone.CFrame * test37Rotation
        end
    -- Individual SKS weapon rotations (DISABLED)
    --elseif sourceName == "SKS Camo Large" then
        ---- SKS Camo Large: 90° Z + 50° X = 50° X + 90° Z rotation
        --local sksRotation = CFrame.Angles(math.rad(50), math.rad(0), math.rad(90))
        --if clone:IsA("Model") and clone.PrimaryPart then
            --clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * sksRotation)
        --elseif clone:IsA("BasePart") then
            --clone.CFrame = clone.CFrame * sksRotation
        --end
    --elseif sourceName == "SKS Wood Large" then
        ---- SKS Wood Large: 90° X + 90° Z + 90° X = 180° X + 90° Z rotation
        --local sksRotation = CFrame.Angles(math.rad(180), math.rad(0), math.rad(90))
        --if clone:IsA("Model") and clone.PrimaryPart then
            --clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * sksRotation)
        --elseif clone:IsA("BasePart") then
            --clone.CFrame = clone.CFrame * sksRotation
        --end
    --elseif sourceName == "SKS Camo" then
        ---- SKS Camo: 90° X + 90° Z + 40° X = 130° X + 90° Z rotation
        --local sksRotation = CFrame.Angles(math.rad(130), math.rad(0), math.rad(90))
        --if clone:IsA("Model") and clone.PrimaryPart then
            --clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * sksRotation)
        --elseif clone:IsA("BasePart") then
            --clone.CFrame = clone.CFrame * sksRotation
        --end
    --elseif sourceName == "SKS Dark Wood" then
        ---- SKS Dark Wood: 90° Z + 90° X + 90° X = 180° X + 90° Z rotation
        --local sksRotation = CFrame.Angles(math.rad(180), math.rad(0), math.rad(90))
        --if clone:IsA("Model") and clone.PrimaryPart then
            --clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * sksRotation)
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
        -- Rotate 360 degrees on X axis for special items (20MM L39)
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
    local specialFocusWeapons = {"Meshes/skyward spine", "Meshes/vortex vanquisher", "Meshes/storm", "Meshes/magma", "Meshes/blue"}
    for _, weaponName in ipairs(specialFocusWeapons) do
        if sourceName == weaponName then
            camTarget = camTarget + Vector3.new(0, 1, 0) -- Raise focus by 1 unit
            break
        end
    end
    
    cam.CFrame = CFrame.new(camPos, camTarget)
    vp.Ambient = Color3.new(1, 1, 1) -- Maximum brightness for ALL weapons now
    vp.LightDirection = Vector3.new(-1,-1,-1)
    vp.LightColor = Color3.new(1, 1, 1) -- Maximum directional light for all weapons
    
    -- Check if this is a legendary item and adjust brightness
    local skinData = SkinConfig.GetSkinMeta(sourceName)
    if skinData and skinData.rarity == "legendary" then
        vp.Ambient = Color3.new(0.9, 0.9, 0.9) -- 90% brightness for legendary items
        vp.LightColor = Color3.new(0.9, 0.9, 0.9) -- 90% directional light for legendary items
    end
    
    -- Special extra lighting for Wolf mythic item
    if sourceName == "Wolf" then
        -- Find all parts in the Wolf model to add lights
        local function addLightsToAllParts(model)
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    -- Add multiple PointLights to each part
                    local pointLight1 = Instance.new("PointLight")
                    pointLight1.Brightness = 10 -- EXTREMELY bright
                    pointLight1.Range = 200 -- Massive range
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
                    spotLight.Parent = part
                end
            end
        end
        
        addLightsToAllParts(clone)
        
        -- Also boost the viewport lighting even more for Wolf
        vp.Ambient = Color3.new(2, 2, 2) -- OVER-BRIGHT ambient (beyond normal limits)
        vp.LightColor = Color3.new(2, 2, 2) -- OVER-BRIGHT directional
        
        -- Add blue-tinted lighting to enhance blue details
        local blueLight = Instance.new("PointLight")
        blueLight.Brightness = 5
        blueLight.Range = 100
        blueLight.Color = Color3.new(0.5, 0.8, 1) -- Blue-tinted light to enhance blue details
        
        -- Create a part positioned to enhance blue visibility
        local blueLightHolder = Instance.new("Part")
        blueLightHolder.Name = "WolfBlueLightHolder"
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
moneyIcon.Font = Enum.Font.GothamBold
moneyIcon.Text = "$"
moneyIcon.TextSize = 26
moneyIcon.TextColor3 = BRIGHT_GREEN
moneyIcon.TextStrokeTransparency = 0.5
moneyIcon.Parent = moneyDisplay
local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(1, -64, 0, 18)
moneyLabel.Position = UDim2.new(0, 54, 0, 10)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Font = Enum.Font.Code
moneyLabel.Text = "CREDITS"
moneyLabel.TextSize = 14
moneyLabel.TextColor3 = DIM_GREEN
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = moneyDisplay
local moneyValue = Instance.new("TextLabel")
moneyValue.Size = UDim2.new(1, -64, 0, 34)
moneyValue.Position = UDim2.new(0, 54, 0, 34)
moneyValue.BackgroundTransparency = 1
moneyValue.Font = Enum.Font.Code
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
coinLogo.Font = Enum.Font.GothamBold
coinLogo.Text = "T"
coinLogo.TextSize = 24
coinLogo.TextColor3 = C3(255, 200, 100)
coinLogo.TextStrokeTransparency = 0.5
coinLogo.Parent = coinsDisplay
local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1, -84, 0, 18)
coinLabel.Position = UDim2.new(0, 78, 0, 10)
coinLabel.BackgroundTransparency = 1
coinLabel.Font = Enum.Font.Code
coinLabel.Text = "TRUMP COINS"
coinLabel.TextSize = 14
coinLabel.TextColor3 = C3(255, 190, 90)
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Parent = coinsDisplay
local coinValue = Instance.new("TextLabel")
coinValue.Size = UDim2.new(1, -84, 0, 34)
coinValue.Position = UDim2.new(0, 78, 0, 34)
coinValue.BackgroundTransparency = 1
coinValue.Font = Enum.Font.Code
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
rankIcon.Font = Enum.Font.GothamBold
rankIcon.Text = "⚜"
rankIcon.TextSize = 22
rankIcon.TextColor3 = GOLD
rankIcon.Parent = badge
local rankLabel = Instance.new("TextLabel")
rankLabel.Size = UDim2.new(1, -84, 0, 18)
rankLabel.Position = UDim2.new(0, 84, 0, 10)
rankLabel.BackgroundTransparency = 1
rankLabel.Font = Enum.Font.Code
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
rankValue.Font = Enum.Font.GothamBold
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
rankProgressLabel.Font = Enum.Font.Code
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

local invTabBtn = Instance.new("TextButton")
invTabBtn.Size=UDim2.new(0,120,1,-10); invTabBtn.Position=UDim2.new(0,10,0,5)
invTabBtn.BackgroundColor3=BLACK; invTabBtn.Text="INVENTORY"; invTabBtn.TextColor3=BRIGHT_GREEN; invTabBtn.TextSize=16; invTabBtn.Font=Enum.Font.Code; invTabBtn.Parent=tabBar
Instance.new("UICorner", invTabBtn).CornerRadius=UDim.new(0,6)

-- Sort dropdown (right beside inventory tab)
local sortFrame = Instance.new("Frame")
sortFrame.Size=UDim2.fromOffset(120,30); sortFrame.Position=UDim2.new(0,140,0,5); sortFrame.AnchorPoint=Vector2.new(0,0)
sortFrame.BackgroundColor3=C3(5,8,6); sortFrame.BackgroundTransparency=0.3; sortFrame.ZIndex=10; sortFrame.Parent=tabBar
Instance.new("UICorner", sortFrame).CornerRadius=UDim.new(0,6)
local sortStroke = Instance.new("UIStroke", sortFrame); sortStroke.Color=GREEN; sortStroke.Transparency=0.6; sortStroke.Thickness=1

local sortBtn = Instance.new("TextButton")
sortBtn.Size=UDim2.new(1,0,1,0); sortBtn.BackgroundTransparency=1; sortBtn.ZIndex=11
sortBtn.Font=Enum.Font.Code; sortBtn.Text="Sort: A-Z"; sortBtn.TextSize=12; sortBtn.TextColor3=GREEN; sortBtn.TextXAlignment=Enum.TextXAlignment.Center; sortBtn.Parent=sortFrame

-- Sort dropdown menu (initially hidden) - parented to main to avoid clipping
local sortDropdown = Instance.new("Frame")
sortDropdown.Size=UDim2.fromOffset(120,60); sortDropdown.Position=UDim2.new(0,160,0,215); sortDropdown.Visible=false
sortDropdown.BackgroundColor3=C3(5,8,6); sortDropdown.BackgroundTransparency=0.1; sortDropdown.ZIndex=200; sortDropdown.Parent=main
Instance.new("UICorner", sortDropdown).CornerRadius=UDim.new(0,6)
local dropStroke = Instance.new("UIStroke", sortDropdown); dropStroke.Color=GREEN; dropStroke.Transparency=0.6; dropStroke.Thickness=1; dropStroke.ZIndex=200

local sortOption1 = Instance.new("TextButton")
sortOption1.Size=UDim2.new(1,0,0.5,0); sortOption1.BackgroundTransparency=0.8; sortOption1.BackgroundColor3=C3(10,20,15); sortOption1.ZIndex=201
sortOption1.Font=Enum.Font.Code; sortOption1.Text="Alphabetical"; sortOption1.TextSize=11; sortOption1.TextColor3=GREEN; sortOption1.Active=true; sortOption1.AutoButtonColor=true; sortOption1.Parent=sortDropdown

local sortOption2 = Instance.new("TextButton")
sortOption2.Size=UDim2.new(1,0,0.5,0); sortOption2.Position=UDim2.new(0,0,0.5,0); sortOption2.BackgroundTransparency=0.8; sortOption2.BackgroundColor3=C3(10,20,15); sortOption2.ZIndex=201
sortOption2.Font=Enum.Font.Code; sortOption2.Text="Rarity"; sortOption2.TextSize=11; sortOption2.TextColor3=GREEN; sortOption2.Active=true; sortOption2.AutoButtonColor=true; sortOption2.Parent=sortDropdown

-- Search bar (all the way to the right)
local searchFrame = Instance.new("Frame")
searchFrame.Size=UDim2.fromOffset(200,30); searchFrame.Position=UDim2.new(1,-210,0,5); searchFrame.AnchorPoint=Vector2.new(0,0)
searchFrame.BackgroundColor3=C3(5,8,6); searchFrame.BackgroundTransparency=0.3; searchFrame.Parent=tabBar
Instance.new("UICorner", searchFrame).CornerRadius=UDim.new(0,6)
local searchStroke = Instance.new("UIStroke", searchFrame); searchStroke.Color=GREEN; searchStroke.Transparency=0.6; searchStroke.Thickness=1

local searchBox = Instance.new("TextBox")
searchBox.Size=UDim2.new(1,-20,1,0); searchBox.Position=UDim2.new(0,10,0,0); searchBox.BackgroundTransparency=1
searchBox.Font=Enum.Font.Code; searchBox.Text=""; searchBox.PlaceholderText="Search..."; searchBox.TextSize=12; searchBox.TextColor3=GREEN; searchBox.PlaceholderColor3=Color3.new(0.5,0.7,0.5); searchBox.TextXAlignment=Enum.TextXAlignment.Left; searchBox.Parent=searchFrame

-- INVENTORY GRID VIEW
local gridView = Instance.new("ScrollingFrame")
gridView.Name="GridView"; gridView.Size=UDim2.new(1,0,1,0); gridView.BackgroundTransparency=1; gridView.BorderSizePixel=0
gridView.ScrollBarThickness=6; gridView.ScrollBarImageColor3=GREEN; gridView.Parent=contentArea
local pad = Instance.new("UIPadding", gridView); pad.PaddingTop=UDim.new(0,10); pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)

local inventoryContainer = Instance.new("Frame")
inventoryContainer.Size=UDim2.new(1,-20,1,-10); inventoryContainer.Position=UDim2.new(0,10,0,10)
inventoryContainer.BackgroundTransparency=1; inventoryContainer.Parent=gridView
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
backBtn.BackgroundColor3=C3(20,30,25); backBtn.Text="< BACK"; backBtn.TextColor3=GREEN; backBtn.Font=Enum.Font.Code; backBtn.TextSize=16; backBtn.Parent=itemPage
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
equipBtn.Font = Enum.Font.Code
equipBtn.TextSize = 16
equipBtn.AutoButtonColor = true
equipBtn.Parent = itemPage
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = equipBtn
    local s = Instance.new("UIStroke"); s.Thickness = 2; s.Color = GREEN; s.Transparency = 0.3; s.Parent = equipBtn
end

local itemTitle = Instance.new("TextLabel")
itemTitle.Size=UDim2.new(1,-220,0,32); itemTitle.Position=UDim2.new(0,110,0,0); itemTitle.BackgroundTransparency=1
itemTitle.Font=Enum.Font.Code; itemTitle.TextXAlignment=Enum.TextXAlignment.Left; itemTitle.TextSize=20; itemTitle.TextColor3=BRIGHT_GREEN; itemTitle.Parent=itemPage

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
    row.BackgroundTransparency=1; row.Font=Enum.Font.Code; row.TextXAlignment=Enum.TextXAlignment.Left
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
    l.BackgroundTransparency=1; l.Font=Enum.Font.Code; l.Text=txt; l.TextSize=12; l.TextColor3=BRIGHT_GREEN; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=detailsPanel
end

-- Item page rotation controls
local bigViewRotateConn
local bigViewDragging=false
local bigViewAngle=0
local bigViewVelocity=0
local bigViewModel
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
        
        -- Get the center of the viewport frame
        local vpCenter = Vector3.new(0, 0, 0) -- Viewport center is at origin
        
        if bigViewModel:IsA("Model") and bigViewModel.PrimaryPart then
            if currentBigViewIsOtherMeshes then
                -- Meshes items: First stand upright (90° X-axis), then spin around Z-axis
                -- Step 1: Stand upright around viewport center
                local standingRotation = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0)
                -- Step 2: Then spin around Z-axis from that standing position
                bigViewModel:SetPrimaryPartCFrame(standingRotation * CFrame.Angles(0, 0, yaw))
            else
                -- All other items: Normal spinning
                bigViewModel:SetPrimaryPartCFrame(CFrame.Angles(0, yaw, 0))
            end
        elseif bigViewModel:IsA("BasePart") then
            if currentBigViewIsOtherMeshes then
                -- Meshes items: First stand upright (90° X-axis), then spin around Z-axis
                -- Step 1: Stand upright around viewport center
                local standingRotation = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0)
                -- Step 2: Then spin around Z-axis from that standing position
                bigViewModel.CFrame = standingRotation * CFrame.Angles(0, 0, yaw)
            else
                -- All other items: Normal spinning
                bigViewModel.CFrame = CFrame.Angles(0, yaw, 0)
            end
        end
    end)
end

local currentItemSkinName = nil
local currentItemRarity = nil
local mythicEffectsCleanup = nil -- Tracking for mythic effects cleanup

local function openItemPage(skinId)
    currentItemSkinName = skinId
    itemTitle.Text = skinId
    
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
            -- Create crate display instead of weapon viewport
            bigViewport:ClearAllChildren()
            local crateFrame = Instance.new("Frame")
            crateFrame.Size = UDim2.new(1, 0, 1, 0)
            crateFrame.BackgroundColor3 = crateData.color
            crateFrame.Parent = bigViewport
            
            local crateCorner = Instance.new("UICorner")
            crateCorner.CornerRadius = UDim.new(0, 20)
            crateCorner.Parent = crateFrame
            
            local crateTitle = Instance.new("TextLabel")
            crateTitle.Size = UDim2.new(1, 0, 0.3, 0)
            crateTitle.Position = UDim2.new(0, 0, 0.35, 0)
            crateTitle.BackgroundTransparency = 1
            crateTitle.Text = crateData.name
            crateTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            crateTitle.TextSize = 24
            crateTitle.Font = Enum.Font.GothamBold
            crateTitle.Parent = crateFrame
            
            -- Update stats to show crate info
            bulletsRow.Text = "Type: " .. crateData.name
            itemsRow.Text = "Cost: " .. (crateData.openCost == 0 and "FREE" or crateData.openCost .. " credits")
            timeRow.Text = "Contents: " .. #crateData.contents .. " possible items"
        end
        
        -- Change button to OPEN
        equipBtn.Text = "OPEN"
        equipBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50) -- Orange for crates
    else
        -- Normal skin handling
        local src = getSkinInstance(skinId)
        
        -- Check if this is a Meshes item for spinning rotation
        currentBigViewIsOtherMeshes = false
        if string.find(skinId, "Meshes") or skinId == "beginner's protector" or skinId == "beginner's protector 2" then
            currentBigViewIsOtherMeshes = true
        end
        
        bigViewModel = setupViewport(bigViewport, src, {fitFactor = ITEM_FIT_FACTOR, minDist = ITEM_MIN_DIST, isBigViewport = true})
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
    -- Standard slot size for all items
    local slotSize = UDim2.new(0, 222, 0, 170) -- Made 5% smaller: 234*0.95=222, 179*0.95=170
    slot.Size = slotSize
    slot.BackgroundColor3 = C3(10,15,12)
    slot.BackgroundTransparency = 1 -- Made completely transparent to remove grey background
    slot.BorderSizePixel = 0
    slot.ZIndex = 5
    slot.Parent = inventoryContainer
    slot.Active = true -- Enable mouse events on the slot
    
    -- Rounded corners
    local corner = Instance.new("UICorner", slot)
    corner.CornerRadius = UDim.new(0, 12)
    
    -- UIScale for hover effects (works with UIGridLayout)
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1.0
    uiScale.Parent = slot
    
    -- Border stroke - no borders for any rarity (clean look for all)
    -- All rarities (common, rare, epic, legendary, mythic) have no borders
    
    -- Viewport container - slightly above center positioning for all items
    local viewportContainer = Instance.new("Frame")
    if rarityValue == 4 or rarityValue == 5 then -- No padding for legendary and mythic
        viewportContainer.Size = UDim2.new(1, 0, 0, 115) -- Full width, same size as other rarities (115px)
        viewportContainer.Position = UDim2.new(0.5, 0, 0.41, 0) -- 5px higher from top (was 0.45)
    else
        viewportContainer.Size = UDim2.new(1, -12, 0, 115) -- Normal padding, scaled 25% bigger (92 * 1.25 = 115)
        viewportContainer.Position = UDim2.new(0.5, 0, 0.41, 0) -- 5px higher from top (was 0.45)
    end
    viewportContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    viewportContainer.BackgroundTransparency = 1 -- Fully transparent for all rarities
    viewportContainer.BorderSizePixel = 0
    viewportContainer.ZIndex = 6
    viewportContainer.Active = false -- Don't let this container block mouse events
    viewportContainer.Parent = slot
    
    local vcCorner = Instance.new("UICorner", viewportContainer)
    vcCorner.CornerRadius = UDim.new(0, 8)
    
    -- Viewport for 3D model
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.fromScale(1, 1)
    viewport.Position = UDim2.fromScale(0.5, 0.5)
    viewport.AnchorPoint = Vector2.new(0.5, 0.5)
    viewport.BackgroundTransparency = 1
    viewport.BorderSizePixel = 0
    viewport.ZIndex = 7
    viewport.Active = false -- Don't let viewport block mouse events
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
        placeholder.Font = Enum.Font.GothamBold
        placeholder.TextXAlignment = Enum.TextXAlignment.Center
        placeholder.TextYAlignment = Enum.TextYAlignment.Center
        placeholder.ZIndex = 8
        placeholder.Parent = viewportContainer
    end
    
    -- Name label with rarity styling - don't apply color for legendary and mythic
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    if rarityValue == 5 then -- Mythic items positioned higher
        nameLabel.Position = UDim2.new(0.5, 0, 1, -60) -- Higher up for mythic items
    elseif rarityValue == 4 then -- Legendary items
        nameLabel.Position = UDim2.new(0.5, 0, 1, -50) -- Higher up for legendary items
    else
        nameLabel.Position = UDim2.new(0.5, 0, 1, -55) -- Higher up for normal items
    end
    nameLabel.AnchorPoint = Vector2.new(0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.Gotham
    
    -- Process name: remove "Meshes/" and capitalize first letters
    local processedName = name
    if string.find(name, "Meshes/") then
        processedName = string.gsub(name, "Meshes/", "") -- Remove "Meshes/"
        -- Capitalize first letter of each word
        processedName = string.gsub(processedName, "(%l)([%w_']*)", function(first, rest)
            return string.upper(first) .. rest
        end)
    end
    
    nameLabel.Text = processedName
    nameLabel.TextSize = 18 -- Increased from 17 to 18
    -- Apply rarity colors for all items including legendary and mythic
    nameLabel.TextColor3 = rarityColor
    nameLabel.TextWrapped = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.ZIndex = 10000  -- Higher than anything else
    nameLabel.Parent = slot
    
    -- Apply mythic blood-red effects for mythic items
    local slotEffectsCleanup
    if rarityValue == 5 and MythicEffects then
        print("Applying mythic effects to slot:", name)
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
        print("Applying legendary aura to slot:", name)
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
        print("Applying epic aura to slot:", name)
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
        print("Applying rare aura to slot:", name)
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
        print("Applying common aura to slot:", name)
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
        
        local skinMeta = getSkinMeta(name)
        local weaponInfo = skinMeta and skinMeta.weapon or "Unknown"
        local detailText = string.format("%s\n%s %s", name, rarityNames[rarityValue], weaponInfo)
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
    
    -- Get all skins from SkinConfig
    local allSkinsList = SkinConfig.GetAllSkinNames()
    
    -- Filter by search term
    if currentSearchTerm ~= "" then
        local filteredList = {}
        local searchLower = string.lower(currentSearchTerm)
        for _, skinName in ipairs(allSkinsList) do
            if string.find(string.lower(skinName), searchLower, 1, true) then
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
    print("DEBUG: toggleInventory called, isOpen:", isOpen)
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
            print("Testing mythic effect on:", slotName)
            MythicEffects.ApplyMythicFrameEffects(item)
            return true
        end
    end
    return false
end

-- Return global API
return {
    ToggleInventory = toggleInventory,
    RefreshStats = refreshTopStats,
    IsOpen = function() return isOpen end,
    TestMythicEffect = testMythicEffect
}