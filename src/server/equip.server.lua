-- Server-side equipment handler
-- Handles weapon grip positioning that's visible to all players

local Players = game:GetService("Players")

-- Correct weapon rotations (separate from viewport rotations)
-- These rotations are specifically for when weapons are equipped and held by players
local CORRECT_WEAPON_ROTATIONS = {
    -- Non-spear weapons
    ["PKM"] = CFrame.Angles(math.rad(360), math.rad(0), math.rad(90)),
    ["shiv"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
    ["Vintorez"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Viper/Mp5"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(-90)),
    ["Chaser"] = CFrame.Angles(math.rad(90), math.rad(270), math.rad(180)),
    
    -- WORKING ROTATIONS - These weapons rotate correctly
    ["Meshes/blue"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/storm"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/magma"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/dragonspine"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(90)) * CFrame.Angles(0, math.rad(180), 0),
    ["Meshes/hydra"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(90)) * CFrame.Angles(0, math.rad(180), 0),
    
    -- Generic fallback for Meshes/ weapons
    ["Meshes/"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(90)),
    
    -- OTHER MESHES WEAPONS - Using same rotation as working ones
    ["Meshes/Blackcliff Pole"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)), -- Changed to match working weapons
    ["Meshes/primordial jade winged-spear"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/tassel"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/black tassel"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/Mountain Piercer"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/damage"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/calamity queller"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/crescent pike"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/dragon's teeth"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/deathmatch"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/mini dragooon"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/dragon's bane"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/favonius lance"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/lance"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/halberd"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/iron blood"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/iron"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/iron point"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/kitain cross spear"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/lithic spear"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/prototype grudge"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/regicide"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/royal spear"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/skyward spine"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/the catch"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/vortex vanquisher"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/wavebreaker's fin"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/white tassel"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["Meshes/gold tassel"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
}

-- FINAL ROTATION ADJUSTMENTS - Applied AFTER everything else (like RotationAdjuster)
-- Use this to test if RotationAdjuster values match when applied server-side
-- Format: CFrame.Angles(math.rad(X), math.rad(Y), math.rad(Z))
-- START WITH 0,0,0 then add values from RotationAdjuster testing
local FINAL_ROTATION_ADJUSTMENTS = {
    -- All weapons from SkinConfig not already in CORRECT_WEAPON_ROTATIONS
    ["20MM L39"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["357 Magnum"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["357 Magnum - Artisan"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["357 Magnum - Ice Capped"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["870 Express"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["870 Express - Fort Hope Elite"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["870 Express - Marine Mag"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["870 Express - Pink Sunset"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["8Bit"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["AA12"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["AA12 - Digicam"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["AA12 - Festive Wrap"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Abakan/AC-96"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Ace"] = CFrame.Angles(math.rad(90), math.rad(90), math.rad(0)),
    ["Adurite Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["AK47"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["AK47 - Gold Lord"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["AK47 - Tracksuit Life"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["AK74"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["AK-Chaos"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["AK-Ice"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["AK-Jungle"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["AKS-74U"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["AKS-74U (SoC)"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["AlphaSapphire Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["ambassador"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Ambassador Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["amp"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["AppleShooter Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Aqua Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["AS-VAL"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["backburner"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Ball"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Barrett M95"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Barrett M95 - Damascus"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Barrett M95 - Sand Cannon"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["bazaar"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["beginner's protector"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(90)),
    ["beginner's protector 2"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(90)),
    ["Beretta M9"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Beretta M9 - Chrome"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Beretta M9 - Combat Pro"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Black kite"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["BlackIron Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Blizzard"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Blood"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(90)),
    ["Blood&Bones"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Bluesteel Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Borders"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["carbine"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Carbon"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["Caution"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Cheesy"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Chroma Fang"] = CFrame.Angles(math.rad(0), math.rad(10), math.rad(0)),
    ["classic"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["ComputerBlaster Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["crossbow"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Crystal"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["CyanMissingTexture Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Cyborg"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Death"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Desert Eagle"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Desert Eagle - Bengal Bling"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Desert Eagle - Dead Red"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["diamondback"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Donkey Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Dragon Glass"] = CFrame.Angles(math.rad(90), math.rad(90), math.rad(0)),
    ["Dreams of Revolvers"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Ego"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Elite Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Enfield Bren"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["enforcer"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Engraved Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Fabric Storm"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["Fabulous Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Fang"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Flame"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["flaregun"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["FN2000"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Fort"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["frontier"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["G36"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Galactic Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Gauss rifle"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Gear"] = CFrame.Angles(math.rad(90), math.rad(270), math.rad(0)),
    ["Genesis"] = CFrame.Angles(math.rad(90), math.rad(270), math.rad(0)),
    ["Glock 23"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Glock 23 - Bengal"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Glock 23 - Homeland"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Glock 23 - Packin' Heat"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Goblin_Axe_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Axe_Nature_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Axe_Rune_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Banner_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Bone_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Bone_02"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_BrokenSword_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Crystal_Axe_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Crystal_Axe_Large_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Crystal_DoubleSword_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Crystal_Halberd_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Crystal_Ornate_Straightsword_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Cutlass_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Goblin_Axe_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Goblin_Axe_Large_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Goblin_Axe_Spikes_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Goblin_Bone_Axe_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Goblin_Club_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Goblin_Gem_Hammer_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Goblin_Halberd_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Goblin_Mace_01"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Goblin_Goblin_Machete_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Goblin_Machete_Spikes_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Goblin_Shiv_Bone_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Goblin_Shiv_Stone_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Goblin_Spear_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Goblin_Staff_01"] = CFrame.Angles(math.rad(270), math.rad(0), math.rad(0)),
    ["Goblin_GreatSword_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Greatsword_Round_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Greatsword_Straight_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Halberd_06"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Hammer_Large_Metal_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Hammer_Large_Metal_010"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Hammer_Large_Stone_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Hammer_Large_Wood_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Hammer_Mace_Sphere_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Hammer_Mace_Spikes_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Hammer_Mace_Stone_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Hammer_Small_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Hammer_Small_02"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_HandAxe_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Handle_Metal_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Handle_Wood_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Mace_Blades_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Ornate_Axe_02"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Ornate_GreatAxe_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Ornate_Spear_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Ornate_Spikes_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Ornate_Spikes_Long_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Ornate_Sword_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Ornate_Sword_02"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Spear_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Spear_02"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Staff_DoubleBlade_01"] = CFrame.Angles(math.rad(270), math.rad(-90), math.rad(0)),
    ["Goblin_Staff_Gem_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Goblin_Straightsword_01"] = CFrame.Angles(math.rad(270), math.rad(90), math.rad(0)),
    ["Gold"] = CFrame.Angles(math.rad(90), math.rad(270), math.rad(0)),
    ["Gold Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Grand Prix"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["Handgun"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Heat"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["heatmaker"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["HyperRed Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Illusion"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["Infiltrator Revolver"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["iRevolver"] = CFrame.Angles(math.rad(180), math.rad(180), math.rad(0)),
    ["Knife"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Knife Box 2 Kit"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Kypto"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["L85"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["leechgun"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["le'tranger"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Leviathan"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Linked"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Lizard"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["M16"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M16 - Green Envy"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M1911"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M1911 - Earthy"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M1911 - Star-Spangled"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M1A"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M1A - Flammo"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M1A - Wood Classic"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M249"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M249 - Festive Wrap"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M249 - Mojave"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M249 - Plastic"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M4 Black"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["M4 Carbine"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M4 Carbine - Bengal"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M4 Carbine - Fort Hope Elite"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["M4 Carbine - Golden Death"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["machina"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Makarov"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["McDonald Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Missing"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Molecular Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Money"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["Monster"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Morgan"] = CFrame.Angles(math.rad(90), math.rad(90), math.rad(0)),
    ["MP5"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["MP5 - Copperhead"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["MP5 - Festive Wrap"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["MP5 - Purple People Eater"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["MS Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Nano"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["natach"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Necromancer"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["NightStalker Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Original Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Overseer Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["overuse"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["P99"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["PB"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Phoenix"] = CFrame.Angles(math.rad(90), math.rad(270), math.rad(0)),
    ["PM"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Portal Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Power"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Predator"] = CFrame.Angles(math.rad(90), math.rad(90), math.rad(0)),
    ["Pro"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["quickfix"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Rainbow"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Rainbow Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Ranch Rifle"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Ranch Rifle - Laminated"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Red Dragon"] = CFrame.Angles(math.rad(90), math.rad(90), math.rad(0)),
    ["Revolver of Destiny"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Rose Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["RPG-7"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["RPK"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["RPK - Fort Hope Elite"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["RPK - Winter Warfare"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Ruger American"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Ruger American - Heirloom"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Samurai"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["Sand Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["sawn-off"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["SCAR"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["SCAR - Bengal"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["SCAR - Desert Classic"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["SCAR - Fancicam"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Scratch"] = CFrame.Angles(math.rad(90), math.rad(270), math.rad(0)),
    ["shna"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Sig220"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["SiG550"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Sky"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["Slate"] = CFrame.Angles(math.rad(360), math.rad(180), math.rad(0)),
    ["sleeper"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Sparkles"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["SparkleTime Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["SPAS"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Spectum"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["Speed"] = CFrame.Angles(math.rad(90), math.rad(270), math.rad(0)),
    ["Splitfire Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Sport"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["Sport V2"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["Stalker"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["StarPlayer Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Sun"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Super 90"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Super 90 - Festive Wrap"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Super 90 - Hexed"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["SVD"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["SVU"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Swag"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["TAC14"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["TAC14 - Bengal"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["TAC14 - ODG"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["TAC14 - Zombie Slayer"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["TEC-9"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["TEC-9 - Bengal"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["TEC-9 - Killing You Softly"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["The Belgian"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["The Belgian - First Class"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["TheHyperLaser Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Thunder"] = CFrame.Angles(math.rad(90), math.rad(90), math.rad(0)),
    ["Tiger"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["tommy gun"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["TOZ"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Treasure Hunter"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["TRS-301"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Tunder S14"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["type 99"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["ubersaw"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["UMP-45"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["UMP-45 - Festive Wrap"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["UMP-45 - Lava Lamp"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["United States Revolver"] = CFrame.Angles(math.rad(270), math.rad(180), math.rad(0)),
    ["Uzi"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Uzi - Fort Hope Elite"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Uzi - Porcelain Vengeance"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["vac"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Vector"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Vector - Bengal"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Vector - Circuit Breaker"] = CFrame.Angles(math.rad(0), math.rad(270), math.rad(0)),
    ["Vision"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["vita"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
    ["waka"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Winner"] = CFrame.Angles(math.rad(90), math.rad(90), math.rad(0)),
    ["Winter Sport"] = CFrame.Angles(math.rad(90), math.rad(270), math.rad(0)),
    ["Wolf"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["Worm"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
    ["wrangler"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(0)),
    ["XM24A3"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    ["Zoom"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
}

-- Equipment positioning settings
local GRIP_OFFSET = CFrame.new(0, 0, 0) -- Base forward position with higher Y offset

-- Specific grip adjustments for different weapon types
local GRIP_ADJUSTMENTS = {
    -- Default for all Meshes/ weapons
    ["Meshes/"] = CFrame.new(0, -5.9, 0),
    
    -- Specific weapon overrides (different from default)
    ["Meshes/dragonspine"] = CFrame.new(0, -9.6, 0.4),
    ["Meshes/hydra"] = CFrame.new(0, -10.7, -0.2),
    
    -- All other Meshes/ weapons using the default positioning
    ["Meshes/blue"] = CFrame.new(0, -5.1, 0),
    ["Meshes/storm"] = CFrame.new(0, -5.1, 0),
    ["Meshes/magma"] = CFrame.new(0, -5.8, 0),
    ["Meshes/Blackcliff Pole"] = CFrame.new(-0.5, -7.5, 0),
    ["Meshes/primordial jade winged-spear"] = CFrame.new(0, -5.8, 0),
    ["Meshes/tassel"] = CFrame.new(0, 0, 0),
    ["Meshes/black tassel"] = CFrame.new(0, -8.8, 0),
    ["Meshes/Mountain Piercer"] = CFrame.new(-0.5, -9, -0.1),
    ["Meshes/damage"] = CFrame.new(0, -8.30, 0),
    ["Meshes/calamity queller"] = CFrame.new(0, -8.3, 0),
    ["Meshes/crescent pike"] = CFrame.new(0, -9.2, 0),
    ["Meshes/dragon's teeth"] = CFrame.new(0, -8, 0),
    ["Meshes/deathmatch"] = CFrame.new(0, -7.30, 0),
    ["Meshes/mini dragooon"] = CFrame.new(0, -9, 0),
    ["Meshes/dragon's bane"] = CFrame.new(-0.1, -9, -0.1),
    ["Meshes/favonius lance"] = CFrame.new(0, -9.6, 0),
    ["Meshes/lance"] = CFrame.new(0, -9.5, 0),
    ["Meshes/halberd"] = CFrame.new(0, -9, 0),
    ["Meshes/iron blood"] = CFrame.new(-0.2, -9, 0),
    ["Meshes/iron"] = CFrame.new(0, 0, 0),
    ["Meshes/iron point"] = CFrame.new(0, -7.2, 0),
    ["Meshes/kitain cross spear"] = CFrame.new(0, -7.13, 0),
    ["Meshes/lithic spear"] = CFrame.new(0, -6, 0),
    ["Meshes/prototype grudge"] = CFrame.new(-0.4, -6, 0),
    ["Meshes/regicide"] = CFrame.new(-0.4, -5.60, 0),
    ["Meshes/royal spear"] = CFrame.new(0, -5, 0),
    ["Meshes/skyward spine"] = CFrame.new(0, -5, 0),
    ["Meshes/the catch"] = CFrame.new(0, -5, 0),
    ["Meshes/vortex vanquisher"] = CFrame.new(0, -5.3, 0),
    ["Meshes/wavebreaker's fin"] = CFrame.new(0, -5, 0),
    ["Meshes/white tassel"] = CFrame.new(0, -6.3, 0),
    ["Meshes/gold tassel"] = CFrame.new(0, -5.8, 0),
    
    -- Items from FINAL_ROTATION_ADJUSTMENTS (all set to 0,0,0 for now)
    ["20MM L39"] = CFrame.new(0, 0.1, 0),
    ["357 Magnum"] = CFrame.new(0, -0.7, 0.2),
    ["357 Magnum - Artisan"] = CFrame.new(0, -0.7, 0.2),
    ["357 Magnum - Ice Capped"] = CFrame.new(0, -0.7, 0.2),
    ["870 Express"] = CFrame.new(0.2, 0, 1.7),
    ["870 Express - Fort Hope Elite"] = CFrame.new(0,-0.3,4.1),
    ["870 Express - Marine Mag"] = CFrame.new(0.2, 0, 1.7),
    ["870 Express - Pink Sunset"] = CFrame.new(0.2, 0, 1.7),
    ["8Bit"] = CFrame.new(0, -0.9, 0),
    ["AA12"] = CFrame.new(0, 0.2, 1.2),
    ["AA12 - Digicam"] = CFrame.new(0, 0.2, 1.2),
    ["AA12 - Festive Wrap"] = CFrame.new(0, 0.2, 1.2),
    ["Abakan/AC-96"] = CFrame.new(0, 0, 2.7),
    ["Ace"] = CFrame.new(0, -0.1, 0.8),
    ["Adurite Revolver"] = CFrame.new(0, 0, 0.9),
    ["AK47"] = CFrame.new(0, -0.2, 1.1),
    ["AK47 - Gold Lord"] = CFrame.new(0, -0.2, 1.1),
    ["AK47 - Tracksuit Life"] = CFrame.new(0, -0.2, 1.1),
    ["AK74"] = CFrame.new(0, -0.7, 0.5),
    ["AK-Chaos"] = CFrame.new(0, 0, 0),
    ["AK-Ice"] = CFrame.new(0, 0, 1),
    ["AK-Jungle"] = CFrame.new(0, 0, 1),
    ["AKS-74U"] = CFrame.new(0, -0.1, 0.7),
    ["AKS-74U (SoC)"] = CFrame.new(0, 0.5, 1.2),
    ["AlphaSapphire Revolver"] = CFrame.new(0, 0, 0.9),
    ["ambassador"] = CFrame.new(0, -0.1, 0.5),
    ["Ambassador Revolver"] = CFrame.new(0, 0, 0.9),
    ["amp"] = CFrame.new(0, -0.2, 0.8),
    ["AppleShooter Revolver"] = CFrame.new(0, 0, 0.9),
    ["Aqua Revolver"] = CFrame.new(0, 0, 0.9),
    ["AS-VAL"] = CFrame.new(0, 0, 0.8),
    ["backburner"] = CFrame.new(0, 0.1, 0.5),
    ["Ball"] = CFrame.new(0, -0.8, 0),
    ["Barrett M95"] = CFrame.new(0, 0, -1.20),
    ["Barrett M95 - Damascus"] = CFrame.new(0, 0, -1.20),
    ["Barrett M95 - Sand Cannon"] = CFrame.new(0, 0, -1.20),
    ["bazaar"] = CFrame.new(0, -0.2, 1.80),
    ["beginner's protector"] = CFrame.new(0, -8.60, 0),
    ["beginner's protector 2"] = CFrame.new(0, -8.60, 0),
    ["Beretta M9"] = CFrame.new(0, -0.3, 0),
    ["Beretta M9 - Chrome"] = CFrame.new(0, -0.3, 0),
    ["Beretta M9 - Combat Pro"] = CFrame.new(0, -0.3, 0),
    ["Black kite"] = CFrame.new(0, 0, 0.6),
    ["BlackIron Revolver"] = CFrame.new(0, 0, 0.9),
    ["Blizzard"] = CFrame.new(0, -3.20, 0.5),
    ["Blood"] = CFrame.new(0, 0, 0.8),
    ["Blood&Bones"] = CFrame.new(0, 0, 1.2),
    ["Bluesteel Revolver"] = CFrame.new(0, 0, 0.9),
    ["Borders"] = CFrame.new(0, -0.8, 0),
    ["carbine"] = CFrame.new(0, 0.2, 0.4),
    ["Carbon"] = CFrame.new(0, -0.3, 0.9),
    ["Caution"] = CFrame.new(0, -0.8, 0),
    ["Cheesy"] = CFrame.new(0, -0.8, 0),
    ["Chroma Fang"] = CFrame.new(0, -1, 0),
    ["classic"] = CFrame.new(0, -0.3, 1.3),
    ["ComputerBlaster Revolver"] = CFrame.new(0, 0, 0.9),
    ["crossbow"] = CFrame.new(0, -0.8, 0.8),
    ["Crystal"] = CFrame.new(0, -0.8, 0),
    ["CyanMissingTexture Revolver"] = CFrame.new(0, 0, 0.9),
    ["Cyborg"] = CFrame.new(0, -0.1, 0.5),
    ["Death"] = CFrame.new(0, -0.1, 0.5),
    ["Desert Eagle"] = CFrame.new(0, 0, 0),
    ["Desert Eagle - Bengal Bling"] = CFrame.new(0, 0, 0),
    ["Desert Eagle - Dead Red"] = CFrame.new(0, 0, 0),
    ["diamondback"] = CFrame.new(0, -0.1, 0.7),
    ["Donkey Revolver"] = CFrame.new(0, 0, 0.9),
    ["Dragon Glass"] = CFrame.new(0, 0, 0.8),
    ["Dreams of Revolvers"] = CFrame.new(0, 0, 0.9),
    ["Ego"] = CFrame.new(0, -3.20, 0.5),
    ["Elite Revolver"] = CFrame.new(0, 0, 0.9),
    ["Enfield Bren"] = CFrame.new(0, 0, 0),
    ["enforcer"] = CFrame.new(0, 0, 0.4),
    ["Engraved Revolver"] = CFrame.new(0, 0, 0.9),
    ["Fabric Storm"] = CFrame.new(0, 0, 0),
    ["Fabulous Revolver"] = CFrame.new(0, 0, 0.9),
    ["Fang"] = CFrame.new(0, -1, 0),
    ["Flame"] = CFrame.new(0, -1.40, -0.3),
    ["flaregun"] = CFrame.new(0, -0.3, 0.6),
    ["FN2000"] = CFrame.new(0, -0.6, 0.9),
    ["Fort"] = CFrame.new(0, -0.10, 1.2),
    ["frontier"] = CFrame.new(0, 0, 0),
    ["G36"] = CFrame.new(0, -0.3, 3.90),
    ["Galactic Revolver"] = CFrame.new(0, 0, 0.9),
    ["Gauss rifle"] = CFrame.new(0, -0.8, 0.4),
    ["Gear"] = CFrame.new(0, -0.3, 0.5),
    ["Genesis"] = CFrame.new(0, -0.3, 0.5),
    ["Glock 23"] = CFrame.new(0, 0, 0),
    ["Glock 23 - Bengal"] = CFrame.new(0, 0, 0),
    ["Glock 23 - Homeland"] = CFrame.new(0, 0, 0),
    ["Glock 23 - Packin' Heat"] = CFrame.new(0, 0, 0),
    ["Goblin_Axe_01"] = CFrame.new(0, -2, 0),
    ["Goblin_Axe_Nature_01"] = CFrame.new(0, -2, 0),
    ["Goblin_Axe_Rune_01"] = CFrame.new(0, -2.2, 0.3),
    ["Goblin_Banner_01"] = CFrame.new(0, -2, 0),
    ["Goblin_Bone_01"] = CFrame.new(0, -2.1, 0.4),
    ["Goblin_Bone_02"] = CFrame.new(0, -2.1, 0.4),
    ["Goblin_BrokenSword_01"] = CFrame.new(0, -1.6, 0),
    ["Goblin_Crystal_Axe_01"] = CFrame.new(0, -2, 0),
    ["Goblin_Crystal_Axe_Large_01"] = CFrame.new(0, -3.6, 0.8),
    ["Goblin_Crystal_DoubleSword_01"] = CFrame.new(0, -2.4, 0),
    ["Goblin_Crystal_Halberd_01"] = CFrame.new(0, -4.5, 0.3),
    ["Goblin_Crystal_Ornate_Straightsword_01"] = CFrame.new(0, -2.6, 0),
    ["Goblin_Cutlass_01"] = CFrame.new(0, -2.6, 0),
    ["Goblin_Goblin_Axe_01"] = CFrame.new(0, -1.8, 0.4),
    ["Goblin_Goblin_Axe_Large_01"] = CFrame.new(0, -4.2, 0),
    ["Goblin_Goblin_Axe_Spikes_01"] = CFrame.new(0, -2, 0.7),
    ["Goblin_Goblin_Bone_Axe_01"] = CFrame.new(0, -2.8, 0.4),
    ["Goblin_Goblin_Club_01"] = CFrame.new(0, -2.5, 0),
    ["Goblin_Goblin_Gem_Hammer_01"] = CFrame.new(0, -2.6, 0.1),
    ["Goblin_Goblin_Halberd_01"] = CFrame.new(0, -6.6, -0.5),
    ["Goblin_Goblin_Mace_01"] = CFrame.new(0, -2, 0),
    ["Goblin_Goblin_Machete_01"] = CFrame.new(0, -2.6, 0),
    ["Goblin_Goblin_Machete_Spikes_01"] = CFrame.new(0, -2.7, 0),
    ["Goblin_Goblin_Shiv_Bone_01"] = CFrame.new(0, -2.1, 0.4),
    ["Goblin_Goblin_Shiv_Stone_01"] = CFrame.new(0, -2, 0),
    ["Goblin_Goblin_Spear_01"] = CFrame.new(0.3, -2.9, 0),
    ["Goblin_Goblin_Staff_01"] = CFrame.new(0, -4.2, 0),
    ["Goblin_GreatSword_01"] = CFrame.new(0, -3, 0),
    ["Goblin_Greatsword_Round_01"] = CFrame.new(0, -3.3, 0),
    ["Goblin_Greatsword_Straight_01"] = CFrame.new(0, -5.5, 0),
    ["Goblin_Halberd_06"] = CFrame.new(0, -2.8, -0.2),
    ["Goblin_Hammer_Large_Metal_01"] = CFrame.new(-0.1, -3.7, 0),
    ["Goblin_Hammer_Large_Metal_010"] = CFrame.new(0, -3.7, 0),
    ["Goblin_Hammer_Large_Stone_01"] = CFrame.new(0, -2.9, 0),
    ["Goblin_Hammer_Large_Wood_01"] = CFrame.new(0, -3.5, 0),
    ["Goblin_Hammer_Mace_Sphere_01"] = CFrame.new(0, -1.6, 0),
    ["Goblin_Hammer_Mace_Spikes_01"] = CFrame.new(0, -2, 0),
    ["Goblin_Hammer_Mace_Stone_01"] = CFrame.new(0, -2, 0.2),
    ["Goblin_Hammer_Small_01"] = CFrame.new(0, -2, 0),
    ["Goblin_Hammer_Small_02"] = CFrame.new(0, -2, 0),
    ["Goblin_HandAxe_01"] = CFrame.new(0, -2, 0.7),
    ["Goblin_Handle_Metal_01"] = CFrame.new(0, -2, 0),
    ["Goblin_Handle_Wood_01"] = CFrame.new(0, -3.4, 0),
    ["Goblin_Mace_Blades_01"] = CFrame.new(0, -4, 0),
    ["Goblin_Ornate_Axe_02"] = CFrame.new(0, -3, 0),
    ["Goblin_Ornate_GreatAxe_01"] = CFrame.new(0, -2, -0.2),
    ["Goblin_Ornate_Spear_01"] = CFrame.new(0, -4.1, 0),
    ["Goblin_Ornate_Spikes_01"] = CFrame.new(0, -2, 0),
    ["Goblin_Ornate_Spikes_Long_01"] = CFrame.new(0, -4.8, 0),
    ["Goblin_Ornate_Sword_01"] = CFrame.new(0, -3.5, 0),
    ["Goblin_Ornate_Sword_02"] = CFrame.new(0, -3.5, 0),
    ["Goblin_Spear_01"] = CFrame.new(0, -5, 0),
    ["Goblin_Spear_02"] = CFrame.new(0, -5, 0),
    ["Goblin_Staff_DoubleBlade_01"] = CFrame.new(0, -3.6, 0),
    ["Goblin_Staff_Gem_01"] = CFrame.new(0, -3.6, 0.8),
    ["Goblin_Straightsword_01"] = CFrame.new(0, -3, 0.2),
    ["Gold"] = CFrame.new(0, -0.3, 0.5),
    ["Gold Revolver"] = CFrame.new(0, 0, 0.9),
    ["Grand Prix"] = CFrame.new(0, -0.4, 0.5),
    ["Handgun"] = CFrame.new(0, 0, 0.4),
    ["Heat"] = CFrame.new(0, -0.1, 0.5),
    ["heatmaker"] = CFrame.new(0, -0.30, 0.6),
    ["HyperRed Revolver"] = CFrame.new(0, 0, 0.9),
    ["Illusion"] = CFrame.new(0, -0.4, 0.5),
    ["Infiltrator Revolver"] = CFrame.new(0, 0, 0.9),
    ["iRevolver"] = CFrame.new(0, 0, 0.9),
    ["Knife"] = CFrame.new(0, -0.4, 0),
    ["Knife Box 2 Kit"] = CFrame.new(0, 0, 0),
    ["Kypto"] = CFrame.new(0, -0.8, 0),
    ["L85"] = CFrame.new(0, 0.3, -0.60),
    ["leechgun"] = CFrame.new(0, -0.30, 0.7),
    ["le'tranger"] = CFrame.new(0, 0, 0),
    ["Leviathan"] = CFrame.new(0, -0.4, 0.5),
    ["Linked"] = CFrame.new(0, -0.8, 0),
    ["Lizard"] = CFrame.new(0, -0.4, 0.5),
    ["M16"] = CFrame.new(0, 0, 0),
    ["M16 - Green Envy"] = CFrame.new(0, 0, 0),
    ["M1911"] = CFrame.new(0, -0.4, 0.1),
    ["M1911 - Earthy"] = CFrame.new(0, -0.4, 0.1),
    ["M1911 - Star-Spangled"] = CFrame.new(0, -0.4, 0.1),
    ["M1A"] = CFrame.new(0, 0.1, 1.40),
    ["M1A - Flammo"] = CFrame.new(0, 0.1, 1.40),
    ["M1A - Wood Classic"] = CFrame.new(0, 0.1, 1.40),
    ["M249"] = CFrame.new(1.6, -1, 1.40),
    ["M249 - Festive Wrap"] = CFrame.new(1.6, -1, 1.40),
    ["M249 - Mojave"] = CFrame.new(1.6, -1, 1.40),
    ["M249 - Plastic"] = CFrame.new(1.6, -1, 1.40),
    ["M4 Black"] = CFrame.new(0, -0.4, 0.5),
    ["M4 Carbine"] = CFrame.new(0, 0.20, 1),
    ["M4 Carbine - Bengal"] = CFrame.new(0, 0.20, 1),
    ["M4 Carbine - Fort Hope Elite"] = CFrame.new(0, 0.20, 1),
    ["M4 Carbine - Golden Death"] = CFrame.new(0, 0.20, 1),
    ["machina"] = CFrame.new(0,-0.50, 1),
    ["Makarov"] = CFrame.new(0, 0, 0.3),
    ["McDonald Revolver"] = CFrame.new(0, 0, 0.9),
    ["Missing"] = CFrame.new(0, -0.8, 0),
    ["Molecular Revolver"] = CFrame.new(0, 0, 0.9),
    ["Money"] = CFrame.new(0, -0.4, 0.9),
    ["Monster"] = CFrame.new(0, 0, 1.3),
    ["Morgan"] = CFrame.new(0, 0, 0.5),
    ["MP5"] = CFrame.new(0, -0.50, 0.8),
    ["MP5 - Copperhead"] = CFrame.new(0, -0.50, 0.8),
    ["MP5 - Festive Wrap"] = CFrame.new(0, -0.50, 0.8),
    ["MP5 - Purple People Eater"] = CFrame.new(0, -0.50, 0.8),
    ["MS Revolver"] = CFrame.new(0, 0, 0.9),
    ["Nano"] = CFrame.new(0, -0.4, 0.9),
    ["natach"] = CFrame.new(0, -0.2, 3.3),
    ["Necromancer"] = CFrame.new(0, -0.4, 0.5),
    ["NightStalker Revolver"] = CFrame.new(0, 0, 0.9),
    ["Original Revolver"] = CFrame.new(0, 0, 0.9),
    ["Overseer Revolver"] = CFrame.new(0, 0, 0.9),
    ["overuse"] = CFrame.new(0, -0.30, 0.6),
    ["P99"] = CFrame.new(0, 0, 0.4),
    ["PB"] = CFrame.new(0, 0, 0.9),
    ["Phoenix"] = CFrame.new(0, -0.3, 0.5),
    ["PM"] = CFrame.new(0, 0, 0.4),
    ["Portal Revolver"] = CFrame.new(0, 0, 0.9),
    ["Power"] = CFrame.new(0, -3.20, 0.5),
    ["Predator"] = CFrame.new(0, 0, 0.9),
    ["Pro"] = CFrame.new(0, -0.4, 0.5),
    ["quickfix"] = CFrame.new(0, -0.20, 0.20),
    ["Rainbow"] = CFrame.new(0, -0.8, 0),
    ["Rainbow Revolver"] = CFrame.new(0, 0, 0.9),
    ["Ranch Rifle"] = CFrame.new(0, 0, 1.2),
    ["Ranch Rifle - Laminated"] = CFrame.new(0, 0, 1.2),
    ["Red Dragon"] = CFrame.new(0, 0, 0.9),
    ["Revolver of Destiny"] = CFrame.new(0, 0, 0.9),
    ["Rose Revolver"] = CFrame.new(0, 0, 0.9),
    ["RPG-7"] = CFrame.new(0, -0.5, 1.10),
    ["RPK"] = CFrame.new(),
    ["RPK - Fort Hope Elite"] = CFrame.new(0, 0.3, 1.3),
    ["RPK - Winter Warfare"] = CFrame.new(0, 0.3, 1.3),
    ["Ruger American"] = CFrame.new(0, 0, 1),
    ["Ruger American - Heirloom"] = CFrame.new(0, 0, 1),
    ["Samurai"] = CFrame.new(0, -0.4, 0.5),
    ["Sand Revolver"] = CFrame.new(0, 0, 0.9),
    ["sawn-off"] = CFrame.new(0, -0.1, 0),
    ["SCAR"] = CFrame.new(0, -0.40, 1),
    ["SCAR - Bengal"] = CFrame.new(0, -0.40, 1),
    ["SCAR - Desert Classic"] = CFrame.new(0, -0.40, 1),
    ["SCAR - Fancicam"] = CFrame.new(0, -0.40, 1),
    ["Scratch"] = CFrame.new(0, -0.3, 0.5),
    ["shna"] = CFrame.new(0, -0.6, 0),
    ["Sig220"] = CFrame.new(0, 0, 0.5),
    ["SiG550"] = CFrame.new(0, -0.1, 1.40),
    ["Sky"] = CFrame.new(0, -0.4, 0.9),
    ["Slate"] = CFrame.new(0, -0.8, 0),
    ["sleeper"] = CFrame.new(0, -0.20, 1.1),
    ["Sparkles"] = CFrame.new(0, -0.8, 0),
    ["SparkleTime Revolver"] = CFrame.new(0, 0, 0.9),
    ["SPAS"] = CFrame.new(0, 0, 2.2),
    ["Spectum"] = CFrame.new(0, -0.8, 0),
    ["Speed"] = CFrame.new(0, -0.3, 0.5),
    ["Splitfire Revolver"] = CFrame.new(0, 0, 0.9),
    ["Sport"] = CFrame.new(0, -0.3, 0.5),
    ["Sport V2"] = CFrame.new(0, -0.3, 0.5),
    ["Stalker"] = CFrame.new(0, -0.8, 0),
    ["StarPlayer Revolver"] = CFrame.new(0, 0, 0.9),
    ["Sun"] = CFrame.new(0, -0.3, 1.1),
    ["Super 90"] = CFrame.new(0, -0.20, 0.8),
    ["Super 90 - Festive Wrap"] = CFrame.new(0, -0.20, 0.8),
    ["Super 90 - Hexed"] = CFrame.new(0, -0.20, 0.8),
    ["SVD"] = CFrame.new(0, 0, 1.3),
    ["SVU"] = CFrame.new(0, 0, -0.9),
    ["Swag"] = CFrame.new(0, -0.8, 0),
    ["TAC14"] = CFrame.new(0, 0, 0.8),
    ["TAC14 - Bengal"] = CFrame.new(0, 0, 0.8),
    ["TAC14 - ODG"] = CFrame.new(0, 0, 0.8),
    ["TAC14 - Zombie Slayer"] = CFrame.new(0, 0, 0.8),
    ["TEC-9"] = CFrame.new(0, 0.3, 1.10),
    ["TEC-9 - Bengal"] = CFrame.new(0, 0.3, 1.10),
    ["TEC-9 - Killing You Softly"] = CFrame.new(0, 0.3, 1.10),
    ["The Belgian"] = CFrame.new(0, -0.5, 1.10),
    ["The Belgian - First Class"] = CFrame.new(0, -0.5, 1.10),
    ["TheHyperLaser Revolver"] = CFrame.new(0, 0, 0.9),
    ["Thunder"] = CFrame.new(0, 0, 0.9),
    ["Tiger"] = CFrame.new(0, -0.4, 0.5),
    ["tommy gun"] = CFrame.new(0, -0.20, 0),
    ["TOZ"] = CFrame.new(0, -0.3, 2.60),
    ["Treasure Hunter"] = CFrame.new(0, -0.4, 0.9),
    ["TRS-301"] = CFrame.new(0, -0.8, 0.4),
    ["Tunder S14"] = CFrame.new(0, 0, -0.9),
    ["type 99"] = CFrame.new(0, 0.2, 0),
    ["ubersaw"] = CFrame.new(0, -0.1, 0.9),
    ["UMP-45"] = CFrame.new(0, 0.4, 1.1),
    ["UMP-45 - Festive Wrap"] = CFrame.new(0, 0.4, 1.1),
    ["UMP-45 - Lava Lamp"] = CFrame.new(0, 0.4, 1.1),
    ["United States Revolver"] = CFrame.new(0, 0, 0.9),
    ["Uzi"] = CFrame.new(0, 0.3, 0.1),
    ["Uzi - Fort Hope Elite"] = CFrame.new(0, 0.3, 0.1),
    ["Uzi - Porcelain Vengeance"] = CFrame.new(0, 0.3, 0.1),
    ["vac"] = CFrame.new(0, 0.3, 0),
    ["Vector"] = CFrame.new(0, 0.7, 1),
    ["Vector - Bengal"] = CFrame.new(0, 0.7, 1),
    ["Vector - Circuit Breaker"] = CFrame.new(0, 0.7, 1),
    ["Vintorez"] = CFrame.new(0, 0, 0.8),
    ["Vision"] = CFrame.new(0, -0.80, 0),
    ["vita"] = CFrame.new(0, -0.3, 0.7),
    ["waka"] = CFrame.new(0, -0.5, 0),
    ["Winner"] = CFrame.new(0, 0, 0.9),
    ["Winter Sport"] = CFrame.new(0, -0.3, 0.5),
    ["Wolf"] = CFrame.new(0, -0.4, 0.5),
    ["Worm"] = CFrame.new(0, -0.4, 0.9),
    ["wrangler"] = CFrame.new(0, -0.50, 0.3),
    ["XM24A3"] = CFrame.new(0, 0.3, 0.4),
    ["Zoom"] = CFrame.new(0, -0.4, 0.9),
}

-- Function to get equipped weapon rotation (separate from viewport rotations)
local function getEquippedWeaponRotation(weaponName, skinId)
    local sourceName = weaponName or "Unknown"
    
    -- Check for skin-specific name first
    if skinId and skinId ~= "" then
        sourceName = skinId
    end
    
    -- Check for specific weapon rotations FIRST (including specific Meshes/ weapons)
    if CORRECT_WEAPON_ROTATIONS[sourceName] then
        local specificRotation = CORRECT_WEAPON_ROTATIONS[sourceName]
        return specificRotation
    end
    
    -- Default: no rotation for equipped weapons
    return CFrame.new()
end
local function adjustWeaponGrip(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    -- Get skin ID for processing
    local skinId = tool:GetAttribute("SkinId") or "default"
    
    -- Check if weapon rotation has been applied (separate from grip adjustment)
    -- Clean the skinId to remove illegal attribute name characters (spaces, slashes, apostrophes, ampersands)
    local cleanSkinId = skinId and skinId:gsub("[%s/''&]", "_") or "default"
    local rotationKey = "WeaponRotated_" .. cleanSkinId
    if not tool:GetAttribute(rotationKey) then
        -- Apply rotation only once
        local weaponRotation = getEquippedWeaponRotation(tool.Name, skinId)
        if weaponRotation and weaponRotation ~= CFrame.new() then
            local currentGrip = tool.Grip
            tool.Grip = currentGrip * weaponRotation
            tool:SetAttribute(rotationKey, true)
        end
    end
    
    -- Now check grip adjustment processing (use cleaned skinId for the key)
    local gripKey = "GripAdjusted_" .. cleanSkinId
    if tool:GetAttribute(gripKey) then
        return
    end
    
    -- Store the original grip BEFORE we modify it (for client grip adjuster to use)
    if not tool:GetAttribute("OriginalGripStored") then
        local original = tool.Grip
        tool:SetAttribute("OriginalGripX", original.X)
        tool:SetAttribute("OriginalGripY", original.Y)
        tool:SetAttribute("OriginalGripZ", original.Z)
        tool:SetAttribute("OriginalGripRX", original.RightVector.X)
        tool:SetAttribute("OriginalGripRY", original.RightVector.Y)
        tool:SetAttribute("OriginalGripRZ", original.RightVector.Z)
        tool:SetAttribute("OriginalGripUX", original.UpVector.X)
        tool:SetAttribute("OriginalGripUY", original.UpVector.Y)
        tool:SetAttribute("OriginalGripUZ", original.UpVector.Z)
        tool:SetAttribute("OriginalGripLX", original.LookVector.X)
        tool:SetAttribute("OriginalGripLY", original.LookVector.Y)
        tool:SetAttribute("OriginalGripLZ", original.LookVector.Z)
        tool:SetAttribute("OriginalGripStored", true)
    end
    
    -- Get the SkinId attribute (this is where "Meshes/" info is stored)
    -- (reusing skinId variable from above)
    
    -- Check if it's a Meshes/ weapon (check both tool name and skin)
    local isMeshesWeapon = (skinId and string.find(skinId, "Meshes/")) or string.find(tool.Name, "Meshes/")
    
    -- Rotation already handled above, now just do grip adjustments
    local weaponRotation = CFrame.new() -- No additional rotation here
    
    -- Get grip adjustment for this weapon type
    local gripAdjustment = CFrame.new()
    
    -- Check for specific weapon adjustments first (including hydra and dragonspine)
    -- Try skinId first, then fall back to tool name if skinId is "default"
    local gripLookupKey = (skinId and skinId ~= "default") and skinId or tool.Name
    
    if GRIP_ADJUSTMENTS[gripLookupKey] then
        gripAdjustment = GRIP_ADJUSTMENTS[gripLookupKey]
    -- Apply Meshes/ adjustment for all other Meshes/ weapons
    elseif isMeshesWeapon and GRIP_ADJUSTMENTS["Meshes/"] then
        gripAdjustment = GRIP_ADJUSTMENTS["Meshes/"]
    end
    
    -- Add height adjustment for spear weapons (Meshes/)
    local heightOffset = CFrame.new()
    
    -- Apply combined transformations (visible to all players)
    local originalGrip = tool.Grip
    
    -- Step 1: Apply rotation first
    tool.Grip = originalGrip * weaponRotation
    
    -- Step 2: Apply FINAL rotation adjustments (simulating RotationAdjuster)
    if skinId and FINAL_ROTATION_ADJUSTMENTS[skinId] then
        local finalRotation = FINAL_ROTATION_ADJUSTMENTS[skinId]
        tool.Grip = tool.Grip * finalRotation
    end
    
    -- Step 3: Apply grip adjustment AFTER all rotations (matches client GripAdjuster behavior)
    local positionOffset = gripAdjustment * heightOffset
    tool.Grip = tool.Grip * positionOffset
    
    -- Store the server's FINAL grip for RotationAdjuster to use as baseline
    local finalGrip = tool.Grip
    tool:SetAttribute("ServerFinalGripX", finalGrip.X)
    tool:SetAttribute("ServerFinalGripY", finalGrip.Y)
    tool:SetAttribute("ServerFinalGripZ", finalGrip.Z)
    tool:SetAttribute("ServerFinalGripRX", finalGrip.RightVector.X)
    tool:SetAttribute("ServerFinalGripRY", finalGrip.RightVector.Y)
    tool:SetAttribute("ServerFinalGripRZ", finalGrip.RightVector.Z)
    tool:SetAttribute("ServerFinalGripUX", finalGrip.UpVector.X)
    tool:SetAttribute("ServerFinalGripUY", finalGrip.UpVector.Y)
    tool:SetAttribute("ServerFinalGripUZ", finalGrip.UpVector.Z)
    tool:SetAttribute("ServerFinalGripLX", finalGrip.LookVector.X)
    tool:SetAttribute("ServerFinalGripLY", finalGrip.LookVector.Y)
    tool:SetAttribute("ServerFinalGripLZ", finalGrip.LookVector.Z)
    tool:SetAttribute("ServerFinalGripStored", true)
    
    -- Mark this tool+skin combination as processed so we don't adjust it again
    tool:SetAttribute(gripKey, true)
end

local function watchToolForGripAdjustment(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    -- Check if we're already watching this tool for SkinId changes
    -- But still allow grip adjustment to be applied on re-equip
    local alreadyWatching = tool:GetAttribute("EquipServerWatched")
    if not alreadyWatching then
        tool:SetAttribute("EquipServerWatched", true)
    end
    
    -- Apply grip adjustment with a small delay to ensure skin is loaded
    
    -- Apply initial grip adjustment
    spawn(function()
        wait(0.2) -- Give time for SkinId to be applied
        
        pcall(adjustWeaponGrip, tool)
    end)
    
    -- Only set up the watcher connection if we haven't already
    if not alreadyWatching then
        -- Track the last processed SkinId to avoid reprocessing when it's set to the same value multiple times
        local lastProcessedSkinId = tool:GetAttribute("SkinId")
    
    -- Re-adjust grip when SkinId changes (but only if it's ACTUALLY a different skin)
    local attributeConnection
    attributeConnection = tool.AttributeChanged:Connect(function(attribute)
        if attribute == "SkinId" then
            local newSkinId = tool:GetAttribute("SkinId")
            
            -- Ignore if it's the same skin being applied again
            if newSkinId == lastProcessedSkinId then
                return
            end
            
            lastProcessedSkinId = newSkinId
            
            -- Clear all old grip adjustment and rotation attributes (to allow reprocessing)
            local attributesToClear = {}
            for attributeName, _ in pairs(tool:GetAttributes()) do
                if string.find(attributeName, "GripAdjusted_") or string.find(attributeName, "WeaponRotated_") then
                    table.insert(attributesToClear, attributeName)
                end
            end
            
            for _, attrName in ipairs(attributesToClear) do
                tool:SetAttribute(attrName, nil)
            end
            
            -- Reset grip to original if we have it stored
            if tool:GetAttribute("OriginalGripStored") then
                local originalX = tool:GetAttribute("OriginalGripX") or 0
                local originalY = tool:GetAttribute("OriginalGripY") or 0
                local originalZ = tool:GetAttribute("OriginalGripZ") or 0
                tool.Grip = CFrame.new(originalX, originalY, originalZ)
            end
            
            -- Now reprocess with new skin
            wait(0.1) -- Small delay to ensure skin is fully applied
            adjustWeaponGrip(tool)
        end
    end)
    
    -- Clean up connections when tool is destroyed
    tool.AncestryChanged:Connect(function()
        if not tool.Parent then
            if attributeConnection then
                attributeConnection:Disconnect()
            end
        end
    end)
    end -- Close the "if not alreadyWatching" block
end

local function watchPlayerTools(player)
    local function watchContainer(container)
        if not container then return end
        
        -- Watch existing tools
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") then
                watchToolForGripAdjustment(child)
            end
        end
        
        -- Watch for new tools
        container.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                watchToolForGripAdjustment(child)
            end
        end)
    end
    
    -- Watch character (equipped tools)
    if player.Character then
        watchContainer(player.Character)
    end
    
    -- Watch backpack (unequipped tools)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        watchContainer(backpack)
    end
    
    -- Watch for character respawns
    player.CharacterAdded:Connect(function(character)
        watchContainer(character)
    end)
    
    -- Watch for backpack creation
    player.ChildAdded:Connect(function(child)
        if child.Name == "Backpack" then
            watchContainer(child)
        end
    end)
end

-- Initialize for all current players
for _, player in ipairs(Players:GetPlayers()) do
    watchPlayerTools(player)
end

-- Watch for new players joining
Players.PlayerAdded:Connect(function(player)
    watchPlayerTools(player)
end)
