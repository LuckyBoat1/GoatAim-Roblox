-- SkinConfig.lua: Skins + rarity + icons + ADS settings
-- 5-tier rarity: common < rare < epic < legendary < mythic

local SkinConfig = {}

SkinConfig.RARITY_ORDER = { common=1, rare=2, epic=3, legendary=4, mythic=5 }

-- Default icons per base weapon
local DEFAULT_ICONS = {
	M4        = "rbxassetid://6047992706",
	AK        = "rbxassetid://6048009712",
	Luger     = "rbxassetid://6764432243",
	Blaster   = "rbxassetid://6764432243",
	Amerigun  = "rbxassetid://6764432243",
	BattleAxe = "rbxassetid://6764432243",
}

-- Base-weapon ADS defaults
local DEFAULT_ADS = {
	FOV = {
		M4    = 52,
		AK    = 52,
		Luger = 52,
		Rifle = 53,
	},
	Grip = {
		M4    = CFrame.new(0, -0.5, -1.2),
		AK    = CFrame.new(0, -0.3, -1.0),
		Luger = CFrame.new(0, -0.2, -0.8),
	},
}

-- Canonical skins list - Only rarity data, let scanner handle textures automatically
-- Complete list of all 421 skins with correct rarities
-- weapon, rarity, adsAllowed, adsGrip, adsFov
local SKINS = {
	["20MM L39"] = { weapon="Launcher", rarity="common", adsAllowed=true },
	["357 Magnum"] = { weapon="Revolver", rarity="common", adsAllowed=true },
	["357 Magnum - Artisan"] = { weapon="Revolver", rarity="common", adsAllowed=true },
	["357 Magnum - Ice Capped"] = { weapon="Revolver", rarity="rare", adsAllowed=true },
	["870 Express"] = { weapon="Shotgun", rarity="common", adsAllowed=true },
	["870 Express - Fort Hope Elite"] = { weapon="Shotgun", rarity="rare", adsAllowed=true },
	["870 Express - Marine Mag"] = { weapon="Shotgun", rarity="common", adsAllowed=true },
	["870 Express - Pink Sunset"] = { weapon="Shotgun", rarity="rare", adsAllowed=true },
	["AA12"] = { weapon="Shotgun", rarity="common", adsAllowed=true },
	["AA12 - Digicam"] = { weapon="Shotgun", rarity="common", adsAllowed=true },
	["AA12 - Festive Wrap"] = { weapon="Shotgun", rarity="epic", adsAllowed=true },
	["AK47"] = { weapon="AK", rarity="common", adsAllowed=true },
	["AK47 - Gold Lord"] = { weapon="AK", rarity="rare", adsAllowed=true },
	["AK47 - Tracksuit Life"] = { weapon="AK", rarity="epic", adsAllowed=true },
	["AK74"] = { weapon="AK", rarity="rare", adsAllowed=true },
	["AKS-74U"] = { weapon="AK", rarity="common", adsAllowed=true },
	["AKS-74U (SoC)"] = { weapon="AK", rarity="rare", adsAllowed=true },
	-- Add missing AK skins from inventory
	["AK-Chaos"] = { weapon="AK", rarity="mythic", adsAllowed=true },
	["AK-Ice"] = { weapon="AK", rarity="epic", adsAllowed=true },
	["AK-Jungle"] = { weapon="AK", rarity="mythic", adsAllowed=true },
	["Gold"] = { weapon="AK", rarity="legendary", adsAllowed=true },
		["Money"] = { weapon="Sniper", rarity="legendary", adsAllowed=true },

	["AS-VAL"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["Abakan/AC-96"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	-- Add missing rifle skins with specified rarities
	["Blood&Bones"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },
	["Cyborg"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },
	["Death"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },
	["Leviathan"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },
	["Sun"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },
	["Ace"] = { weapon="Blade", rarity="epic", adsAllowed=false },
		["Adurite Revolver"] = {
		weapon = "Revolver",
		rarity = "rare",
		adsAllowed = true,
	},
		["AlphaSapphire Revolver"] = {
		weapon = "Revolver",
		rarity = "rare",
		adsAllowed = true,
	},
		["Ambassador Revolver"] = {
		weapon = "Revolver",
		rarity = "rare",
		adsAllowed = true,
	},
	["AppleShooter Revolver"] = { weapon="Revolver", rarity="common", adsAllowed=true, faceLeft=true },
	["Aqua Revolver"] = { weapon="Revolver", rarity="common", adsAllowed=true, faceLeft=true },
	["Barrett M95"] = { weapon="Sniper", rarity="common", adsAllowed=true },
	["Barrett M95 - Damascus"] = { weapon="Sniper", rarity="rare", adsAllowed=true },
	["Barrett M95 - Sand Cannon"] = { weapon="Sniper", rarity="rare", adsAllowed=true },
	["Beretta M9"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["Beretta M9 - Chrome"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["Beretta M9 - Combat Pro"] = { weapon="Pistol", rarity="rare", adsAllowed=true },
	["Black kite"] = { weapon="Blade", rarity="common", adsAllowed=false },
	["BlackIron Revolver"] = { weapon="Revolver", rarity="common", adsAllowed=true, faceLeft=true },
	["Blood"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Bluesteel Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true, faceLeft=true },
	["Carbon"] = { weapon="Blade", rarity="epic", adsAllowed=false },
	["Chaser"] = { weapon="Blade", rarity="common", adsAllowed=false },
	["ComputerBlaster Revolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true, faceLeft=true },
	["CyanMissingTexture Revolver"] = { weapon="Revolver", rarity="common", adsAllowed=true, faceLeft=true },
	["Desert Eagle"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["Desert Eagle - Bengal Bling"] = { weapon="Pistol", rarity="rare", adsAllowed=true },
	["Desert Eagle - Dead Red"] = { weapon="Pistol", rarity="epic", adsAllowed=true },
	["Donkey Revolver"] = { weapon="Revolver", rarity="common", adsAllowed=true, faceLeft=true },
	["Heat"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },
	["Dragon Glass"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Dreams of Revolvers"] = { weapon="Revolver", rarity="rare", adsAllowed=true, faceLeft=true },
	["Elite Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true },
	["Enfield Bren"] = { weapon="LMG", rarity="common", adsAllowed=true },
	["Engraved Revolver"] = { weapon="Revolver", rarity="common", adsAllowed=true, faceLeft=true },
	["FN2000"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["Fabric Storm"] = { weapon="Blade", rarity="epic", adsAllowed=false },
	["Fabulous Revolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true, faceLeft=true },
	["Fort"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["G36"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["Galactic Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true, faceLeft=true },
	["Gauss rifle"] = { weapon="Rifle", rarity="epic", adsAllowed=true },
	["Gear"] = { weapon="Blade", rarity="epic", adsAllowed=false },
	["Genesis"] = { weapon="Blade", rarity="mythic", adsAllowed=false },
	["Glock 23"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["Glock 23 - Bengal"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["Glock 23 - Homeland"] = { weapon="Pistol", rarity="rare", adsAllowed=true },
	["Glock 23 - Packin' Heat"] = { weapon="Pistol", rarity="epic", adsAllowed=true },
	["Gold Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true },
	["Grand Prix"] = { weapon="Blade", rarity="rare", adsAllowed=false },
	["Handgun"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["HyperRed Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true },
	["Infiltrator Revolver"] = { weapon="Revolver", rarity="common", adsAllowed=true },
	["Knife"] = { weapon="Blade", rarity="common", adsAllowed=false },
	["Knife Box 2 Kit"] = { weapon="Blade", rarity="common", adsAllowed=false },
	-- Additional blade weapons
	["8Bit"] = { weapon="Blade", rarity="epic", adsAllowed=false },
	["Ball"] = { weapon="Blade", rarity="epic", adsAllowed=false },
	["Borders"] = { weapon="Blade", rarity="rare", adsAllowed=false },
	["Caution"] = { weapon="Blade", rarity="rare", adsAllowed=false },
	["Cheesy"] = { weapon="Blade", rarity="epic", adsAllowed=false },
	["Chroma Fang"] = { weapon="Blade", rarity="mythic", adsAllowed=false },
	["Crystal"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Fang"] = { weapon="Blade", rarity="mythic", adsAllowed=false },
	["Kypto"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Linked"] = { weapon="Blade", rarity="common", adsAllowed=false },
	["Missing"] = { weapon="Blade", rarity="rare", adsAllowed=false },
	["Vision"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Rainbow"] = { weapon="Blade", rarity="epic", adsAllowed=false },
	["Slate"] = { weapon="Blade", rarity="rare", adsAllowed=false },
	["Sparkles"] = { weapon="Blade", rarity="rare", adsAllowed=false },
	["Spectum"] = { weapon="Blade", rarity="epic", adsAllowed=false },
	["Stalker"] = { weapon="Blade", rarity="rare", adsAllowed=false },
	["Swag"] = { weapon="Blade", rarity="rare", adsAllowed=false },
	["L85"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["Lizard"] = { weapon="Rifle", rarity="legendary", adsAllowed=false },
	["Sky"] = { weapon="Rifle", rarity="legendary", adsAllowed=false },
	["M16"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["M16 - Green Envy"] = { weapon="Rifle", rarity="epic", adsAllowed=true },
	["M1911"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["M1911 - Earthy"] = { weapFm1on="Pistol", rarity="common", adsAllowed=true },
	["M1911 - Star-Spangled"] = { weapon="Pistol", rarity="epic", adsAllowed=true },
	["M1A"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["M1A - Flammo"] = { weapon="Rifle", rarity="rare", adsAllowed=true },
	["M1A - Wood Classic"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["M249"] = { weapon="LMG", rarity="common", adsAllowed=true },
	["M249 - Festive Wrap"] = { weapon="LMG", rarity="epic", adsAllowed=true },
	["M249 - Mojave"] = { weapon="LMG", rarity="rare", adsAllowed=true },
	["M249 - Plastic"] = { weapon="LMG", rarity="legendary", adsAllowed=true },
	-- Add missing M4 variants
	["M4 Black"] = { weapon="M4", rarity="epic", adsAllowed=true },
	["M4 Carbine"] = { weapon="M4", rarity="common", adsAllowed=true },
	["M4 Carbine - Bengal"] = { weapon="M4", rarity="epic", adsAllowed=true },
	["M4 Carbine - Fort Hope Elite"] = { weapon="M4", rarity="common", adsAllowed=true },
	["M4 Carbine - Golden Death"] = { weapon="M4", rarity="rare", adsAllowed=true },
	["MP5"] = { weapon="SMG", rarity="common", adsAllowed=true },
	["MP5 - Copperhead"] = { weapon="SMG", rarity="rare", adsAllowed=true },
	["MP5 - Festive Wrap"] = { weapon="SMG", rarity="epic", adsAllowed=true },
	["MP5 - Purple People Eater"] = { weapon="SMG", rarity="epic", adsAllowed=true },
	["MS Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true },
	["Makarov"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["McDonald Revolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true },
	["Meshes/Blackcliff Pole"] = { weapon="Spear", rarity="legendary", adsAllowed=false },
	["Meshes/tassel"] = { weapon="Spear", rarity="common", adsAllowed=false },
	["Meshes/black tassel"] = { weapon="Spear", rarity="rare", adsAllowed=false },
	["Meshes/Mountain Piercer"] = { weapon="Spear", rarity="legendary", adsAllowed=false },
	["Meshes/damage"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Meshes/calamity queller"] = { weapon="Spear", rarity="legendary", adsAllowed=false },
	["Meshes/crescent pike"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Meshes/dragon's teeth"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Meshes/deathmatch"] = { weapon="Spear", rarity="legendary", adsAllowed=false },
	["Meshes/mini dragooon"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Meshes/dragon's bane"] = { weapon="Spear", rarity="legendary", adsAllowed=false },
	["Meshes/hydra"] = { weapon="Spear", rarity="mythic", adsAllowed=false },
	["Meshes/favonius lance"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Meshes/lance"] = { weapon="Spear", rarity="rare", adsAllowed=false },
	["Meshes/halberd"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Meshes/iron blood"] = { weapon="Spear", rarity="legendary", adsAllowed=false },
	["Meshes/iron"] = { weapon="Spear", rarity="common", adsAllowed=false },
	["Meshes/iron point"] = { weapon="Spear", rarity="rare", adsAllowed=false },
	["Meshes/kitain cross spear"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Meshes/lithic spear"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Meshes/primordial jade winged-spear"] = { weapon="Spear", rarity="mythic", adsAllowed=false },
	["Meshes/prototype grudge"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Meshes/regicide"] = { weapon="Spear", rarity="legendary", adsAllowed=false },
	["Meshes/royal spear"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Meshes/blue"] = { weapon="Spear", rarity="legendary", adsAllowed=false },
	["Meshes/dragonspine"] = { weapon="Spear", rarity="mythic", adsAllowed=false },
    ["Meshes/magma"] = { weapon="Spear", rarity="mythic", adsAllowed=false },
	["Meshes/skyward spine"] = { weapon="Spear", rarity="legendary", adsAllowed=false },
	["Meshes/the catch"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Meshes/vortex vanquisher"] = { weapon="Spear", rarity="legendary", adsAllowed=false },
	["Meshes/storm"] = { weapon="Spear", rarity="mythic", adsAllowed=false },
	["Meshes/wavebreaker's fin"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Goblin_Axe_Nature_01"] = { weapon="Axe", rarity="rare", adsAllowed=false },
	["Goblin_Axe_Rune_01"] = { weapon="Axe", rarity="rare", adsAllowed=false },
	["Goblin_Crystal_Axe_01"] = { weapon="Axe", rarity="epic", adsAllowed=false },
	["Goblin_Crystal_DoubleSword_01"] = { weapon="Sword", rarity="epic", adsAllowed=false },
	["Goblin_Goblin_Axe_01"] = { weapon="Axe", rarity="rare", adsAllowed=false },
	["Goblin_Goblin_Axe_Spikes_01"] = { weapon="Axe", rarity="rare", adsAllowed=false },
	["Goblin_Goblin_Club_01"] = { weapon="Club", rarity="rare", adsAllowed=false },
	["Goblin_Goblin_Halberd_01"] = { weapon="Halberd", rarity="rare", adsAllowed=false },
	["Goblin_Goblin_Mace_01"] = { weapon="Mace", rarity="epic", adsAllowed=false },
	["Goblin_Goblin_Machete_01"] = { weapon="Machete", rarity="rare", adsAllowed=false },
	["Goblin_Goblin_Machete_Spikes_01"] = { weapon="Machete", rarity="rare", adsAllowed=false },
	["Goblin_Goblin_Shiv_Bone_01"] = { weapon="Shiv", rarity="rare", adsAllowed=false },
	["Goblin_Goblin_Staff_01"] = { weapon="Staff", rarity="epic", adsAllowed=false },
	["Goblin_Greatsword_Straight_01"] = { weapon="Greatsword", rarity="rare", adsAllowed=false },
	["Goblin_Hammer_Large_Metal_01"] = { weapon="Hammer", rarity="rare", adsAllowed=false },
	["Goblin_Hammer_Large_Metal_010"] = { weapon="Hammer", rarity="epic", adsAllowed=false },
	["Goblin_Hammer_Mace_Stone_01"] = { weapon="Hammer", rarity="epic", adsAllowed=false },
	["Goblin_Hammer_Small_02"] = { weapon="Hammer", rarity="rare", adsAllowed=false },
	["Goblin_Handle_Metal_01"] = { weapon="Handle", rarity="common", adsAllowed=false },
	["Goblin_Handle_Wood_01"] = { weapon="Handle", rarity="common", adsAllowed=false },
	["Goblin_Mace_Blades_01"] = { weapon="Mace", rarity="epic", adsAllowed=false },
	["Goblin_Ornate_Axe_02"] = { weapon="Axe", rarity="rare", adsAllowed=false },
	["Goblin_Ornate_GreatAxe_01"] = { weapon="GreatAxe", rarity="epic", adsAllowed=false },
	["Goblin_Spear_01"] = { weapon="Spear", rarity="common", adsAllowed=false },
	["Goblin_Spear_02"] = { weapon="Spear", rarity="common", adsAllowed=false },
	["Goblin_Staff_DoubleBlade_01"] = { weapon="Staff", rarity="common", adsAllowed=false },
	["Goblin_Staff_Gem_01"] = { weapon="Staff", rarity="rare", adsAllowed=false },
	["Goblin_Straightsword_01"] = { weapon="Sword", rarity="rare", adsAllowed=false },
	["Goblin_Axe_01"] = { weapon="Axe", rarity="epic", adsAllowed=false },
	["Goblin_Banner_01"] = { weapon="Banner", rarity="rare", adsAllowed=false },
	["Goblin_Bone_01"] = { weapon="Bone", rarity="common", adsAllowed=false },
	["Goblin_Bone_02"] = { weapon="Bone", rarity="common", adsAllowed=false },
	["Goblin_BrokenSword_01"] = { weapon="Sword", rarity="common", adsAllowed=false },
	["Goblin_Crystal_Halberd_01"] = { weapon="Halberd", rarity="epic", adsAllowed=false },
	["Goblin_Crystal_Axe_Large_01"] = { weapon="Axe", rarity="epic", adsAllowed=false },
	["Goblin_Crystal_Ornate_Straightsword_01"] = { weapon="Sword", rarity="rare", adsAllowed=false },
	["Goblin_Cutlass_01"] = { weapon="Cutlass", rarity="rare", adsAllowed=false },
	["Goblin_Goblin_Axe_Large_01"] = { weapon="Axe", rarity="epic", adsAllowed=false },
	["Goblin_Goblin_Bone_Axe_01"] = { weapon="Axe", rarity="epic", adsAllowed=false },
	["Goblin_Goblin_Gem_Hammer_01"] = { weapon="Hammer", rarity="epic", adsAllowed=false },
	["Goblin_Goblin_Shiv_Stone_01"] = { weapon="Shiv", rarity="common", adsAllowed=false },
	["Goblin_Goblin_Spear_01"] = { weapon="Spear", rarity="common", adsAllowed=false },
	["Goblin_GreatSword_01"] = { weapon="Greatsword", rarity="epic", adsAllowed=false },
	["Goblin_Greatsword_Round_01"] = { weapon="Greatsword", rarity="epic", adsAllowed=false },
	["Goblin_Halberd_06"] = { weapon="Halberd", rarity="rare", adsAllowed=false },
	["Goblin_Hammer_Large_Stone_01"] = { weapon="Hammer", rarity="epic", adsAllowed=false },
	["Goblin_Hammer_Large_Wood_01"] = { weapon="Hammer", rarity="epic", adsAllowed=false },
	["Goblin_Hammer_Mace_Sphere_01"] = { weapon="Hammer", rarity="rare", adsAllowed=false },
	["Goblin_Hammer_Mace_Spikes_01"] = { weapon="Hammer", rarity="epic", adsAllowed=false },
	["Goblin_Hammer_Small_01"] = { weapon="Hammer", rarity="rare", adsAllowed=false },
	["Goblin_HandAxe_01"] = { weapon="HandAxe", rarity="rare", adsAllowed=false },
	["Goblin_Ornate_Spear_01"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Goblin_Ornate_Spikes_01"] = { weapon="Spikes", rarity="rare", adsAllowed=false },
	["Goblin_Ornate_Spikes_Long_01"] = { weapon="Spikes", rarity="epic", adsAllowed=false },
	["Goblin_Ornate_Sword_01"] = { weapon="Sword", rarity="epic", adsAllowed=false },
	["Goblin_Ornate_Sword_02"] = { weapon="Sword", rarity="rare", adsAllowed=false },
	["Meshes/white tassel"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Meshes/gold tassel"] = { weapon="Spear", rarity="epic", adsAllowed=false },
	["Molecular Revolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true },
	["Monster"] = { weapon="Blade", rarity="mythic", adsAllowed=false },
	["Morgan"] = { weapon="Blade", rarity="epic", adsAllowed=false },
	["Nano"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Necromancer"] = { weapon="Blade", rarity="mythic", adsAllowed=false },
	["NightStalker Revolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true },
	["Original Revolver"] = { weapon="Revolver", rarity="common", adsAllowed=true },
	["Overseer Revolver"] = { weapon="Revolver", rarity="legendary", adsAllowed=true },
	["P99"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["PB"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["PKM"] = { weapon="LMG", rarity="common", adsAllowed=true },
	["PM"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["Phoenix"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Portal Revolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true },
	["Predator"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Pro"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["RPG-7"] = { weapon="Launcher", rarity="rare", adsAllowed=true },
	["RPK"] = { weapon="LMG", rarity="common", adsAllowed=true },
	["RPK - Fort Hope Elite"] = { weapon="LMG", rarity="rare", adsAllowed=true },
	["RPK - Winter Warfare"] = { weapon="LMG", rarity="rare", adsAllowed=true },
	["Rainbow Revolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true },
	["Ranch Rifle"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["Ranch Rifle - Laminated"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["Red Dragon"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Revolver of Destiny"] = { weapon="Revolver", rarity="rare", adsAllowed=true },
	["Rose Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true },
	["Ruger American"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["Ruger American - Heirloom"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["SCAR"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["SCAR - Bengal"] = { weapon="Rifle", rarity="rare", adsAllowed=true },
	["SCAR - Desert Classic"] = { weapon="Rifle", rarity="rare", adsAllowed=true },
	["SCAR - Fancicam"] = { weapon="Rifle", rarity="epic", adsAllowed=true },
	--["SKS Wood Large"] = { weapon="Rifle", rarity="rare", adsAllowed=true },
	--["SKS Wood"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	--["SKS Camo"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	--["SKS Dark Wood"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	--["SKS Camo Large"] = { weapon="Rifle", rarity="rare", adsAllowed=true },
	["SPAS"] = { weapon="Shotgun", rarity="common", adsAllowed=true },
	["SVD"] = { weapon="Sniper", rarity="common", adsAllowed=true },
	["SVU"] = { weapon="Sniper", rarity="rare", adsAllowed=true },
	["Samurai"] = { weapon="Blade", rarity="mythic", adsAllowed=false },
	["Sand Revolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true },
	["Scratch"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["SiG550"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["Sig220"] = { weapon="Pistol", rarity="common", adsAllowed=true },
	["SparkleTime Revolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true },
	["Speed"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Splitfire Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true },
	["Sport"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Sport V2"] = { weapon="Blade", rarity="mythic", adsAllowed=false },
	["StarPlayer Revolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true },
	["Super 90"] = { weapon="Shotgun", rarity="common", adsAllowed=true },
	["Super 90 - Festive Wrap"] = { weapon="Shotgun", rarity="epic", adsAllowed=true },
	["Super 90 - Hexed"] = { weapon="Shotgun", rarity="rare", adsAllowed=true },
	["TAC14"] = { weapon="Shotgun", rarity="common", adsAllowed=true },
	["TAC14 - Bengal"] = { weapon="Shotgun", rarity="rare", adsAllowed=true },
	["TAC14 - ODG"] = { weapon="Shotgun", rarity="common", adsAllowed=true },
	["TAC14 - Zombie Slayer"] = { weapon="Shotgun", rarity="epic", adsAllowed=true },
	["TEC-9"] = { weapon="SMG", rarity="common", adsAllowed=true },
	["TEC-9 - Bengal"] = { weapon="SMG", rarity="rare", adsAllowed=true },
	["TEC-9 - Killing You Softly"] = { weapon="SMG", rarity="rare", adsAllowed=true },
	["TOZ"] = { weapon="Rifle", rarity="rare", adsAllowed=true },
	["TRS-301"] = { weapon="Rifle", rarity="rare", adsAllowed=true },
	["The Belgian"] = { weapon="Shotgun", rarity="common", adsAllowed=true },
	["The Belgian - First Class"] = { weapon="Shotgun", rarity="rare", adsAllowed=true },
	["TheHyperLaser Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true },
	["Thunder"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Tiger"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Treasure Hunter"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Tunder S14"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["UMP-45"] = { weapon="SMG", rarity="common", adsAllowed=true },
	["UMP-45 - Festive Wrap"] = { weapon="SMG", rarity="epic", adsAllowed=true },
	["UMP-45 - Lava Lamp"] = { weapon="SMG", rarity="epic", adsAllowed=true },
	["United States Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true },
	["Uzi"] = { weapon="SMG", rarity="common", adsAllowed=true },
	["Uzi - Fort Hope Elite"] = { weapon="SMG", rarity="common", adsAllowed=true },
	["Uzi - Porcelain Vengeance"] = { weapon="SMG", rarity="epic", adsAllowed=true },
	["Vector"] = { weapon="SMG", rarity="common", adsAllowed=true },
	["Vector - Bengal"] = { weapon="SMG", rarity="rare", adsAllowed=true },
	["Vector - Circuit Breaker"] = { weapon="SMG", rarity="epic", adsAllowed=true },
	["Vintorez"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["Viper/Mp5"] = { weapon="SMG", rarity="common", adsAllowed=true },
	["Winner"] = { weapon="Blade", rarity="epic", adsAllowed=false },
	["Blizzard"] = { weapon="Blade", rarity="mythic", adsAllowed=false },
	["Winter Sport"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Wolf"] = { weapon="Blade", rarity="mythic", adsAllowed=false },
	["Worm"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["Power"] = { weapon="Blade", rarity="mythic", adsAllowed=false },
	["Ego"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["XM24A3"] = { weapon="Rifle", rarity="rare", adsAllowed=true },
	["Zoom"] = { weapon="Blade", rarity="legendary", adsAllowed=false },
	["ambassador"] = { weapon="Sniper", rarity="common", adsAllowed=true },
	["amp"] = { weapon="Misc", rarity="rare", adsAllowed=false },
	["backburner"] = { weapon="Flamethrower", rarity="rare", adsAllowed=false },
	["bazaar"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["beginner's protector"] = { weapon="Shield", rarity="common", adsAllowed=false },
	["beginner's protector 2"] = { weapon="Shield", rarity="common", adsAllowed=false },
	["carbine"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["classic"] = { weapon="Rifle", rarity="rare", adsAllowed=true },
	["crossbow"] = { weapon="Crossbow", rarity="common", adsAllowed=true },
	["diamondback"] = { weapon="Revolver", rarity="epic", adsAllowed=true },
	["enforcer"] = { weapon="Pistol", rarity="rare", adsAllowed=true },
	["flaregun"] = { weapon="Flaregun", rarity="epic", adsAllowed=true },
	["frontier"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["heatmaker"] = { weapon="Sniper", rarity="common", adsAllowed=true },
	["iRevolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true },
	["le'tranger"] = { weapon="Revolver", rarity="common", adsAllowed=true },
	["leechgun"] = { weapon="Medigun", rarity="common", adsAllowed=false },
	["machina"] = { weapon="Sniper", rarity="common", adsAllowed=true },
	["natach"] = { weapon="Minigun", rarity="epic", adsAllowed=false },
	["overuse"] = { weapon="Minigun", rarity="rare", adsAllowed=false },
	["quickfix"] = { weapon="Medigun", rarity="rare", adsAllowed=false },
	["sawn-off"] = { weapon="Shotgun", rarity="common", adsAllowed=true },
	["shiv"] = { weapon="Blade", rarity="common", adsAllowed=false },
	["shna"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["sleeper"] = { weapon="Sniper", rarity="common", adsAllowed=true },
	["tommy gun"] = { weapon="SMG", rarity="common", adsAllowed=true },
	["type 99"] = { weapon="Rifle", rarity="rare", adsAllowed=true },
	["ubersaw"] = { weapon="Melee", rarity="common", adsAllowed=false },
	["vac"] = { weapon="Medigun", rarity="common", adsAllowed=false },
	["vita"] = { weapon="Medigun", rarity="common", adsAllowed=false },
	["waka"] = { weapon="Rifle", rarity="common", adsAllowed=true },
	["wrangler"] = { weapon="Misc", rarity="common", adsAllowed=false },
}

-- SkinLibrary scanning functionality
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _scanned = false

-- Extract TextureId from a model
local function extractTextureId(model)
	if not model then return nil end
	
	-- Method 1: Check if model is a MeshPart with TextureId
	if model:IsA("MeshPart") and model.TextureId and model.TextureId ~= "" then
		return model.TextureId
	end
	
	-- Method 2: Look for MeshPart children with TextureId
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("MeshPart") and child.TextureId and child.TextureId ~= "" then
			return child.TextureId
		end
	end
	
	-- Method 3: Look for Parts with single Mesh child that has TextureId
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") then
			local mesh = child:FindFirstChildOfClass("SpecialMesh") or child:FindFirstChildOfClass("Mesh")
			if mesh and mesh.TextureId and mesh.TextureId ~= "" then
				return mesh.TextureId
			end
		end
	end
	
	-- Method 4: Recursive search through all descendants
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("MeshPart") and descendant.TextureId and descendant.TextureId ~= "" then
			return descendant.TextureId
		elseif descendant:IsA("SpecialMesh") or descendant:IsA("Mesh") then
			if descendant.TextureId and descendant.TextureId ~= "" then
				return descendant.TextureId
			end
		end
	end
	
	return nil
end

-- Determine weapon type from skin name
local function getWeaponFromName(skinName)
	local name = skinName:upper()
	if name:find("^M4") or name:find("M4A1") then
		return "M4"
	elseif name:find("^AK") then
		return "AK"
	elseif name:find("LUGER") or name:find("PISTOL") then
		return "Luger"
	elseif name:find("BLASTER") then
		return "Blaster"
	elseif name:find("AMERI") then
		return "Amerigun"
	elseif name:find("AXE") or name:find("BATTLE") then
		return "BattleAxe"
	else
		-- Try to guess from common prefixes
		if name:match("^%w+%-") then
			local prefix = name:match("^(%w+)%-")
			return prefix
		end
		return "Hand" -- Default fallback
	end
end

-- Guess rarity from skin name
local function guessRarity(skinName)
	local name = skinName:upper()
	
	-- Mythic indicators
	if name:find("DRAGON") or name:find("DEATH") or name:find("LEGENDARY") or name:find("MYTHIC") then
		return "mythic"
	end
	
	-- Legendary indicators  
	if name:find("CHAOS") or name:find("ELITE") or name:find("MASTER") or name:find("LEGEND") then
		return "legendary"
	end
	
	-- Epic indicators
	if name:find("FIRE") or name:find("MONSTER") or name:find("MIND") or name:find("EPIC") then
		return "epic"
	end
	
	-- Rare indicators
	if name:find("GOLD") or name:find("ICE") or name:find("CYBORG") or name:find("BLOOD") or name:find("RARE") then
		return "rare"
	end
	
	-- Common indicators
	if name:find("DEFAULT") or name:find("BASIC") or name:find("JUNGLE") or name:find("PUMPKIN") then
		return "common"
	end
	
	-- Default to common
	return "common"
end

-- Scan SkinLibrary and add new skins to SKINS table
local function scanSkinLibrary()
	if _scanned then return end
	
	local skinLibrary = ReplicatedStorage:FindFirstChild("SkinLibrary")
	if not skinLibrary then
		warn("[SkinConfig] SkinLibrary not found in ReplicatedStorage")
		_scanned = true
		return
	end
	
	local newSkinsCount = 0
	for _, model in ipairs(skinLibrary:GetChildren()) do
		if model:IsA("Model") or model:IsA("MeshPart") or model:IsA("BasePart") then
			local skinId = model.Name
			
			-- Skip if already exists in SKINS
			if not SKINS[skinId] then
				local textureId = extractTextureId(model)
				local weapon = getWeaponFromName(skinId)
				local rarity = guessRarity(skinId)
				
				SKINS[skinId] = {
					weapon = weapon,
					rarity = rarity,
					icon = textureId or DEFAULT_ICONS[weapon] or "rbxassetid://6764432243",
					textureId = textureId or DEFAULT_ICONS[weapon] or "rbxassetid://6764432243",
					adsAllowed = true, -- Default to true
				}
				
				newSkinsCount = newSkinsCount + 1
				print(string.format("[SkinConfig] Added skin: %s (weapon=%s, rarity=%s, textureId=%s)", 
					skinId, weapon, rarity, textureId or "fallback"))
			end
		end
	end
	
	local totalSkins = 0
	for _ in pairs(SKINS) do totalSkins = totalSkins + 1 end
	
	warn(string.format("[SkinConfig] Scan complete - Added %d new skins, total: %d", newSkinsCount, totalSkins))
	_scanned = true
end

local function normalizeWeaponName(w)
	if not w then return nil end
	local lw = w:lower()
	if lw == "ak" or lw == "ak47" then return "AK" end
	return w
end

local _poolsByRarity = nil
local function buildPools()
	local pools = { common={}, rare={}, epic={}, legendary={}, mythic={} }
	for skinId, meta in pairs(SKINS) do
		local r = (meta.rarity or "common"):lower()
		if not pools[r] then r = "common" end
		table.insert(pools[r], skinId)
	end
	_poolsByRarity = pools
end

function SkinConfig.GetSkinMeta(skinId) 
	-- Safely try to scan - don't fail if it doesn't work
	if not _scanned then
		local success, err = pcall(scanSkinLibrary)
		if not success then
			warn("[SkinConfig] Failed to scan skin library: " .. tostring(err))
		end
	end
	
	-- First try exact match
	if SKINS[skinId] then
		return SKINS[skinId]
	end
	
	-- Clean the skin name (trim spaces, normalize) and try again
	local cleanSkinId = skinId:gsub("^%s+", ""):gsub("%s+$", "") -- Trim leading/trailing whitespace
	if SKINS[cleanSkinId] then
		return SKINS[cleanSkinId]
	end
	
	-- Try case-insensitive match as final fallback
	local lowerSkinId = cleanSkinId:lower()
	for configSkinId, meta in pairs(SKINS) do
		if configSkinId:lower() == lowerSkinId then
			return meta
		end
	end
	
	return nil
end

function SkinConfig.GetWeaponForSkin(skinId) 
	local m = SkinConfig.GetSkinMeta(skinId)
	return m and m.weapon or nil 
end

function SkinConfig.GetRarity(skinId) 
	local m = SkinConfig.GetSkinMeta(skinId)
	return m and m.rarity or "common" 
end

function SkinConfig.GetPoolsByRarity()
	if not _poolsByRarity then buildPools() end
	return _poolsByRarity
end

function SkinConfig.GetAllSkinsForWeapon(weaponName)
	weaponName = normalizeWeaponName(weaponName)
	local out = {}
	for id, m in pairs(SKINS) do
		if m.weapon == weaponName then table.insert(out, id) end
	end
	table.sort(out)
	return out
end

function SkinConfig.HasSkin(playerDataTable, skinId)
	return playerDataTable and playerDataTable.skins and playerDataTable.skins[skinId] == true
end

function SkinConfig.GetSkinIcon(skinId, toolName)
	local meta = SKINS[skinId]
	if meta and meta.icon then return meta.icon end
	local weapon = meta and meta.weapon or normalizeWeaponName(toolName)
	return (weapon and DEFAULT_ICONS[weapon]) or "rbxassetid://6764432243"
end

function SkinConfig.GetSkinTextureId(skinId, toolName)
	local meta = SKINS[skinId]
	if meta and meta.textureId then return meta.textureId end
	if meta and meta.icon then return meta.icon end -- Fallback to icon
	local weapon = meta and meta.weapon or normalizeWeaponName(toolName)
	return (weapon and DEFAULT_ICONS[weapon]) or "rbxassetid://6764432243"
end

function SkinConfig.GetAllIconContentIds()
	local ids = {}
	for _, id in pairs(DEFAULT_ICONS) do table.insert(ids, id) end
	for _, m in pairs(SKINS) do if m.icon then table.insert(ids, m.icon) end end
	return ids
end

function SkinConfig.IsADSAllowed(toolName, skinId)
	local meta = SKINS[skinId]
	if meta and meta.adsAllowed ~= nil then return meta.adsAllowed end
	return true
end

function SkinConfig.GetADSGripForSkin(skinId, toolName)
	local meta = SKINS[skinId]
	if meta and meta.adsGrip then return meta.adsGrip end
	local weapon = meta and meta.weapon or normalizeWeaponName(toolName)
	return (weapon and DEFAULT_ADS.Grip[weapon]) or CFrame.new(0, -0.4, -1.0)
end

function SkinConfig.GetADSFOVForSkin(skinId, toolName)
	local meta = SKINS[skinId]
	if meta and meta.adsFov then return meta.adsFov end
	local weapon = meta and meta.weapon or normalizeWeaponName(toolName)
	return (weapon and DEFAULT_ADS.FOV[weapon]) or 55
end

function SkinConfig.GetAllSkins()
	scanSkinLibrary() -- Ensure scanned
	local out = {}
	for id, meta in pairs(SKINS) do
		out[#out+1] = {id=id, weapon=meta.weapon, rarity=meta.rarity, icon=meta.icon, textureId=meta.textureId}
	end
	table.sort(out, function(a,b)
		if a.weapon == b.weapon then
			local ra = SkinConfig.RARITY_ORDER[a.rarity] or 1
			local rb = SkinConfig.RARITY_ORDER[b.rarity] or 1
			if ra == rb then return a.id < b.id end
			return ra < rb
		end
		return a.weapon < b.weapon
	end)
	return out
end

-- Debug function to print all found skins
function SkinConfig.DebugPrintSkins()
	scanSkinLibrary()
	print("=== SkinConfig Debug - All Skins ===")
	local sortedSkins = {}
	for skinId, meta in pairs(SKINS) do
		table.insert(sortedSkins, {id = skinId, weapon = meta.weapon, rarity = meta.rarity, textureId = meta.textureId})
	end
	
	-- Sort alphabetically by skin ID
	table.sort(sortedSkins, function(a, b) return a.id < b.id end)
	
	for i, skin in ipairs(sortedSkins) do
		print(string.format("[%d] %s: weapon=%s, rarity=%s, textureId=%s", 
			i, skin.id, skin.weapon, skin.rarity, skin.textureId or "nil"))
	end
	print(string.format("Total skins found: %d", #sortedSkins))
end

-- Function to get all skin names for easy rarity assignment
function SkinConfig.GetAllSkinNames()
	-- Safely try to scan - don't fail if it doesn't work
	if not _scanned then
		local success, err = pcall(scanSkinLibrary)
		if not success then
			warn("[SkinConfig] Failed to scan skin library: " .. tostring(err))
		end
	end
	
       local names = {}
       for skinId, _ in pairs(SKINS) do
	       table.insert(names, skinId)
       end
       -- Don't sort here - let the inventory handle sorting based on user preference
       print("[SkinConfig] GetAllSkinNames returned " .. #names .. " skins (unsorted)")
       return names
end

-- Simple test function to verify module is working
function SkinConfig.IsLoaded()
	return true
end

-- Debug function to get some basic stats
function SkinConfig.GetStats()
	local configuredSkinsCount = 0
	for _ in pairs(SKINS) do
		configuredSkinsCount = configuredSkinsCount + 1
	end
	
	return {
		configuredSkins = configuredSkinsCount,
		scanned = _scanned,
		moduleLoaded = true
	}
end

-- Print load confirmation
warn("[SkinConfig] Module loaded successfully!")

return SkinConfig
