-- SkinConfig.lua: Skins + rarity + icons + ADS settings
-- 5-tier rarity: common < rare < epic < legendary < mythic

local SkinConfig = {}

SkinConfig.RARITY_ORDER = { common=1, rare=2, epic=3, legendary=4, mythic=5 }

-- Default icons per base weapon
local DEFAULT_ICONS = {
	M4        = "rbxassetid://6047992706",
	AK        = "rbxassetid://6048009712",
	Luger     = "rbxassetid://6764432243",
	BattleAxe = "rbxassetid://6764432243",
}
--
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
	["LMG AE"] = { weapon="Launcher", rarity="common", adsAllowed=true },       -- OLD: ["20MM L39"]
	["357 Magnum"] = { weapon="Revolver", rarity="common", adsAllowed=true },       -- OLD: ["357 Magnum"]
	["357 Magnum - Desert"] = { weapon="Revolver", rarity="common", adsAllowed=true },       -- OLD: ["357 Magnum - Artisan"]
	["357 Magnum - Ice"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["357 Magnum - Ice Capped"]
	["870 Express"] = { weapon="Shotgun", rarity="common", adsAllowed=true },       -- OLD: ["870 Express"]
	["870 Express - Carbon"] = { weapon="Shotgun", rarity="rare", adsAllowed=true },       -- OLD: ["870 Express - Fort Hope Elite"]
	["870 Express - White"] = { weapon="Shotgun", rarity="common", adsAllowed=true },       -- OLD: ["870 Express - Marine Mag"]
	["870 Express - Sakura"] = { weapon="Shotgun", rarity="rare", adsAllowed=true },       -- OLD: ["870 Express - Pink Sunset"]
	["AA12"] = { weapon="Shotgun", rarity="common", adsAllowed=true },       -- OLD: ["AA12"]
	["AA12 - Brown"] = { weapon="Shotgun", rarity="common", adsAllowed=true },       -- OLD: ["AA12 - Digicam"]
	["AA12 - Amas"] = { weapon="Shotgun", rarity="epic", adsAllowed=true },       -- OLD: ["AA12 - Festive Wrap"]
	["AK47"] = { weapon="AK", rarity="common", adsAllowed=true },       -- OLD: ["AK47"]
	["Almost Goldie"] = { weapon="AK", rarity="rare", adsAllowed=true },       -- OLD: ["AK47 - Gold Lord"]
	["Skeleton"] = { weapon="AK", rarity="epic", adsAllowed=true },       -- OLD: ["AK47 - Tracksuit Life"]
	["AK74"] = { weapon="AK", rarity="rare", adsAllowed=true },       -- OLD: ["AK74"]
	["AKS-74U"] = { weapon="AK", rarity="common", adsAllowed=true },       -- OLD: ["AKS-74U"]
	["AKS-74U (SoC)"] = { weapon="AK", rarity="rare", adsAllowed=true },       -- OLD: ["AKS-74U (SoC)"]
	["AK-Chaos"] = { weapon="AK", rarity="mythic", adsAllowed=true },       -- OLD: ["AK-Chaos"]
	["Sea Bone"] = { weapon="AK", rarity="epic", adsAllowed=true },       -- OLD: ["AK-Ice"]
	["AK-Jungle"] = { weapon="AK", rarity="mythic", adsAllowed=true },       -- OLD: ["AK-Jungle"]
	["Gold"] = { weapon="AK", rarity="legendary", adsAllowed=true },       -- OLD: ["Gold"]
	["Money"] = { weapon="Sniper", rarity="legendary", adsAllowed=true },       -- OLD: ["Money"]
	["AS-VAL"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["AS-VAL"]
	["Abakan/AC-96"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["Abakan/AC-96"]
	["Blood&Bones"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },       -- OLD: ["Blood&Bones"]
	["Cyborg"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },       -- OLD: ["Cyborg"]
	["Fear"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },       -- OLD: ["Death"]
	["Leviathan"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },       -- OLD: ["Leviathan"]
	["Sun"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },       -- OLD: ["Sun"]
	["Surf"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Ace"]
	["Fire Touch"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["Adurite Revolver"]
	["Alpha Sapphire"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["AlphaSapphire Revolver"]
	["Copper"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["Ambassador Revolver"]
	["Apple"] = { weapon="Revolver", rarity="common", adsAllowed=true, faceLeft=true },       -- OLD: ["AppleShooter Revolver"]
	["Bubble"] = { weapon="Revolver", rarity="common", adsAllowed=true, faceLeft=true },       -- OLD: ["Aqua Revolver"]
	["Barrett M95"] = { weapon="Sniper", rarity="common", adsAllowed=true },       -- OLD: ["Barrett M95"]
	["Grey"] = { weapon="Sniper", rarity="rare", adsAllowed=true },       -- OLD: ["Barrett M95 - Damascus"]
	["Barrett M95 - Sand Cannon"] = { weapon="Sniper", rarity="rare", adsAllowed=true },       -- OLD: ["Barrett M95 - Sand Cannon"]
	["Beretta M9"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["Beretta M9"]
	["Beretta M9 - Chrome"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["Beretta M9 - Chrome"]
	["Beretta M9 - Combat Pro"] = { weapon="Pistol", rarity="rare", adsAllowed=true },       -- OLD: ["Beretta M9 - Combat Pro"]
	["Black kite"] = { weapon="Blade", rarity="common", adsAllowed=false },       -- OLD: ["Black kite"]
	["BlackIron Revolver"] = { weapon="Revolver", rarity="common", adsAllowed=true, faceLeft=true },       -- OLD: ["BlackIron Revolver"]
	["Blood"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Blood"]
	["Cheese"] = { weapon="Revolver", rarity="epic", adsAllowed=true, faceLeft=true },       -- OLD: ["Bluesteel Revolver"]
	["Carbon Ruby"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Carbon"]
	["Chaser"] = { weapon="Blade", rarity="common", adsAllowed=false },       -- OLD: ["Chaser"]
	["Zone"] = { weapon="Revolver", rarity="rare", adsAllowed=true, faceLeft=true },       -- OLD: ["ComputerBlaster Revolver"]
	["Cube Squared"] = { weapon="Revolver", rarity="common", adsAllowed=true, faceLeft=true },       -- OLD: ["CyanMissingTexture Revolver"]
	["Desert Eagle"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["Desert Eagle"]
	["Desert Eagle - Bengal Bling"] = { weapon="Pistol", rarity="rare", adsAllowed=true },       -- OLD: ["Desert Eagle - Bengal Bling"]
	["Desert Eagle - Dead Red"] = { weapon="Pistol", rarity="epic", adsAllowed=true },       -- OLD: ["Desert Eagle - Dead Red"]
	["Spoon"] = { weapon="Revolver", rarity="common", adsAllowed=true, faceLeft=true },       -- OLD: ["Donkey Revolver"]
	["Flame"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Flame"]
	["Heat"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },       -- OLD: ["Heat"]
	["Black Frost"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Dragon Glass"]
	["Dreams of Gold"] = { weapon="Revolver", rarity="rare", adsAllowed=true, faceLeft=true },       -- OLD: ["Dreams of Revolvers"]
	["Just give me my money"] = { weapon="Revolver", rarity="epic", adsAllowed=true },       -- OLD: ["Elite Revolver"]
	["Illusion"] = { weapon="Rifle", rarity="legendary", adsAllowed=true },       -- OLD: ["Illusion"]
	["Enfield Bren"] = { weapon="LMG", rarity="common", adsAllowed=true },       -- OLD: ["Enfield Bren"]
	["Engraved Revolver"] = { weapon="Revolver", rarity="common", adsAllowed=true, faceLeft=true },       -- OLD: ["Engraved Revolver"]
	["FN2000"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["FN2000"]
	["Drip"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Fabric Storm"]
	["Fabulous Revolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true, faceLeft=true },       -- OLD: ["Fabulous Revolver"]
	["Fort"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["Fort"]
	["G36"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["G36"]
	["Neon Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true, faceLeft=true },       -- OLD: ["Galactic Revolver"]
	["Grill"] = { weapon="Rifle", rarity="epic", adsAllowed=true },       -- OLD: ["Gauss rifle"]
	["Hot Cheetoz"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Gear"]
	["Genesis"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Genesis"]
	["Glock 23"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["Glock 23"]
	["Glock 23 - Bengal"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["Glock 23 - Bengal"]
	["Glock 23 - Cake"] = { weapon="Pistol", rarity="rare", adsAllowed=true },       -- OLD: ["Glock 23 - Homeland"]
	["Glock 23 - FireFly"] = { weapon="Pistol", rarity="epic", adsAllowed=true },       -- OLD: ["Glock 23 - Packin' Heat"]
	["Gold Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true },       -- OLD: ["Gold Revolver"]
	["Basic Camo"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Grand Prix"]
	["HyperRed Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true },       -- OLD: ["HyperRed Revolver"]
	["Infiltrator Revolver"] = { weapon="Revolver", rarity="common", adsAllowed=true },       -- OLD: ["Infiltrator Revolver"]
	["Knife"] = { weapon="Blade", rarity="common", adsAllowed=false },       -- OLD: ["Knife"]
	["Cash"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Kypto"]
	["Sharp"] = { weapon="Blade", rarity="common", adsAllowed=false },       -- OLD: ["Linked"]
	["Whity"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Missing"]
	["Sight"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Vision"]
	["Jaz"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Rainbow"]
	["Somber"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Slate"]
	["Cool"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Sparkles"]
	["Poison"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Spectum"]
	["Shade"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Stalker"]
	["Sugar Swag"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Swag"]
	["L85"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["L85"]
	["Lizard"] = { weapon="Rifle", rarity="legendary", adsAllowed=false },       -- OLD: ["Lizard"]
	["Sky"] = { weapon="Rifle", rarity="legendary", adsAllowed=false },       -- OLD: ["Sky"]
	["M16"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["M16"]
	["M16 - Green Envy"] = { weapon="Rifle", rarity="epic", adsAllowed=true },       -- OLD: ["M16 - Green Envy"]
	["M1911"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["M1911"]
	["M1911 - Earthy"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["M1911 - Earthy"]
	["M1911 - Star-Spangled"] = { weapon="Pistol", rarity="epic", adsAllowed=true },       -- OLD: ["M1911 - Star-Spangled"]
	["M1A"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["M1A"]
	["M1A - Flammo"] = { weapon="Rifle", rarity="rare", adsAllowed=true },       -- OLD: ["M1A - Flammo"]
	["M1A - Wood Classic"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["M1A - Wood Classic"]
	["M249"] = { weapon="LMG", rarity="common", adsAllowed=true },       -- OLD: ["M249"]
	["M249 - Festive Wrap"] = { weapon="LMG", rarity="epic", adsAllowed=true },       -- OLD: ["M249 - Festive Wrap"]
	["M249 - Mojave"] = { weapon="LMG", rarity="rare", adsAllowed=true },       -- OLD: ["M249 - Mojave"]
	["M249 - Plastic"] = { weapon="LMG", rarity="legendary", adsAllowed=true },       -- OLD: ["M249 - Plastic"]
	["M4 Black"] = { weapon="M4", rarity="epic", adsAllowed=true },       -- OLD: ["M4 Black"]
	["M4 Carbine"] = { weapon="M4", rarity="common", adsAllowed=true },       -- OLD: ["M4 Carbine"]
	["M4 Carbine - Bengal"] = { weapon="M4", rarity="epic", adsAllowed=true },       -- OLD: ["M4 Carbine - Bengal"]
	["M4 Carbine - Fort Hope Elite"] = { weapon="M4", rarity="common", adsAllowed=true },       -- OLD: ["M4 Carbine - Fort Hope Elite"]
	["M4 Carbine - Golden Death"] = { weapon="M4", rarity="rare", adsAllowed=true },       -- OLD: ["M4 Carbine - Golden Death"]
	["MP5"] = { weapon="SMG", rarity="common", adsAllowed=true },       -- OLD: ["MP5"]
	["MP5 - Copperhead"] = { weapon="SMG", rarity="rare", adsAllowed=true },       -- OLD: ["MP5 - Copperhead"]
	["MP5 - Festive Wrap"] = { weapon="SMG", rarity="epic", adsAllowed=true },       -- OLD: ["MP5 - Festive Wrap"]
	["MP5 - Purple People Eater"] = { weapon="SMG", rarity="epic", adsAllowed=true },       -- OLD: ["MP5 - Purple People Eater"]
	["MS Revolver"] = { weapon="Revolver", rarity="epic", adsAllowed=true },       -- OLD: ["MS Revolver"]
	["Makarov"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["Makarov"]
	["McDonald Revolver"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["McDonald Revolver"]
	["Dark Cliff"] = { weapon="Spear", rarity="legendary", adsAllowed=false },       -- OLD: ["Meshes/Blackcliff Pole"]
	["Ribbon Lance"] = { weapon="Spear", rarity="common", adsAllowed=false },       -- OLD: ["Meshes/tassel"]
	["Dark Ribbon"] = { weapon="Spear", rarity="rare", adsAllowed=false },       -- OLD: ["Meshes/black tassel"]
	["Mountain Piercer"] = { weapon="Spear", rarity="legendary", adsAllowed=false },       -- OLD: ["Mountain Piercer"]
	["Damage"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Damage"]
	["Disaster Strike"] = { weapon="Spear", rarity="legendary", adsAllowed=false },       -- OLD: ["Meshes/calamity queller"]
	["Moon Pike"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Meshes/crescent pike"]
	["Dragon's Teeth"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Dragon's Teeth"]
	["Deathmatch"] = { weapon="Spear", rarity="legendary", adsAllowed=false },       -- OLD: ["Deathmatch"]
	["Mini Dragooon"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Mini Dragooon"]
	["Dragon's Bane"] = { weapon="Spear", rarity="legendary", adsAllowed=false },       -- OLD: ["Dragon's Bane"]
	["Hydra"] = { weapon="Spear", rarity="mythic", adsAllowed=false },       -- OLD: ["Hydra"]
	["Wind Lance"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Meshes/favonius lance"]
	["Knight's Lance"] = { weapon="Spear", rarity="rare", adsAllowed=false },       -- OLD: ["Meshes/lance"]
	["Battle Pike"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Meshes/halberd"]
	["Blood Iron"] = { weapon="Spear", rarity="legendary", adsAllowed=false },       -- OLD: ["Meshes/iron blood"]
	["Iron Stick"] = { weapon="Spear", rarity="common", adsAllowed=false },       -- OLD: ["Meshes/iron"]
	["Sharp Iron"] = { weapon="Spear", rarity="rare", adsAllowed=false },       -- OLD: ["Meshes/iron point"]
	["Cross Pike"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Meshes/kitain cross spear"]
	["Stone Spear"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Meshes/lithic spear"]
	["Zoro"] = { weapon="Spear", rarity="mythic", adsAllowed=false },       -- OLD: ["Meshes/primordial jade winged-spear"]
	["Revenge"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Meshes/prototype grudge"]
	["King Slayer"] = { weapon="Spear", rarity="legendary", adsAllowed=false },       -- OLD: ["Meshes/regicide"]
	["Royal Pike"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Meshes/royal spear"]
	["Blue"] = { weapon="Spear", rarity="legendary", adsAllowed=false },       -- OLD: ["Blue"]
	["Dragon Spine"] = { weapon="Spear", rarity="mythic", adsAllowed=false },       -- OLD: ["Meshes/dragonspine"]
	["Lava Flow"] = { weapon="Spear", rarity="mythic", adsAllowed=false },       -- OLD: ["Meshes/magma"]
	["Sky Piercer"] = { weapon="Spear", rarity="legendary", adsAllowed=false },       -- OLD: ["Meshes/skyward spine"]
	["Fish Spear"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Meshes/the catch"]
	["Tornado"] = { weapon="Spear", rarity="legendary", adsAllowed=false },       -- OLD: ["Meshes/vortex vanquisher"]
	["Storm"] = { weapon="Spear", rarity="mythic", adsAllowed=false },       -- OLD: ["Storm"]
	["Wave Fin"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Meshes/wavebreaker's fin"]
	["Grout"] = { weapon="Axe", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Axe_Nature_01"]
	["Rune eye"] = { weapon="Axe", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Axe_Rune_01"]
	["Red Falcon"] = { weapon="Axe", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Crystal_Axe_01"]
	["Blood Hungry"] = { weapon="Sword", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Crystal_DoubleSword_01"]
	["Jaw Breaker"] = { weapon="Axe", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Axe_01"]
	["Saber-Tooth"] = { weapon="Axe", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Axe_Spikes_01"]
	["Spiked Club"] = { weapon="Club", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Club_01"]
	["Pokey"] = { weapon="Halberd", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Halberd_01"]
	["End"] = { weapon="Mace", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Mace_01"]
	["Shark Eye"] = { weapon="Machete", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Machete_01"]
	["Hunter's sword"] = { weapon="Machete", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Machete_Spikes_01"]
	["Boneless"] = { weapon="Shiv", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Shiv_Bone_01"]
	["Dark Hope"] = { weapon="Staff", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Staff_01"]
	["Mid"] = { weapon="Greatsword", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Greatsword_Straight_01"]
	["Halk Smash"] = { weapon="Hammer", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Hammer_Large_Metal_01"]
	["Skull Disintigrator"] = { weapon="Hammer", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Hammer_Large_Metal_010"]
	["Stone Hammer"] = { weapon="Hammer", rarity="common", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Hammer_Mace_Stone_01"]
	["Stone Crusher"] = { weapon="Hammer", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Hammer_Small_02"]
	["Metal bar"] = { weapon="Handle", rarity="common", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Handle_Metal_01"]
	["Weak bat"] = { weapon="Handle", rarity="common", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Handle_Wood_01"]
	["Destroyer"] = { weapon="Mace", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Mace_Blades_01"]
	["Slicer"] = { weapon="Axe", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Ornate_Axe_02"]
	["Axe of Wealth "] = { weapon="GreatAxe", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Ornate_GreatAxe_01"]
	["Wooden Spear"] = { weapon="Spear", rarity="common", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Spear_01"]
	["Iron Spear"] = { weapon="Spear", rarity="common", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Spear_02"]
	["Twin Blade Staff"] = { weapon="Staff", rarity="common", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Staff_DoubleBlade_01"]
	["Gem Staff"] = { weapon="Staff", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Staff_Gem_01"]
	["Straight Sword"] = { weapon="Sword", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Straightsword_01"]
	["Helm Axe"] = { weapon="Axe", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Axe_01"]
	["ToothPick"] = { weapon="Banner", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Banner_01"]
	["Q Bone"] = { weapon="Bone", rarity="common", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Bone_01"]
	["Dog Bone"] = { weapon="Bone", rarity="common", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Bone_02"]
	["Broken Hope"] = { weapon="Sword", rarity="common", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_BrokenSword_01"]
	["Ruby Halberd"] = { weapon="Halberd", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Crystal_Halberd_01"]
	["HamAxe"] = { weapon="Axe", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Crystal_Axe_Large_01"]
	["Bitter Sweet"] = { weapon="Sword", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Crystal_Ornate_Straightsword_01"]
	["Dagestan"] = { weapon="Cutlass", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Cutlass_01"]
	["Skull Collector"] = { weapon="Axe", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Axe_Large_01"]
	["Anarchy"] = { weapon="Axe", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Bone_Axe_01"]
	["Gem Hammer"] = { weapon="Hammer", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Gem_Hammer_01"]
	["Bone arrow"] = { weapon="Shiv", rarity="common", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Shiv_Stone_01"]
	["Sharp Stick"] = { weapon="Spear", rarity="common", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Goblin_Spear_01"]
	["GreatSword"] = { weapon="Greatsword", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_GreatSword_01"]
	["Huge Spoon"] = { weapon="Greatsword", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Greatsword_Round_01"]
	["Good boy"] = { weapon="Halberd", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Halberd_06"]
	["Stone Edge"] = { weapon="Hammer", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Hammer_Large_Stone_01"]
	["The Log"] = { weapon="Hammer", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Hammer_Large_Wood_01"]
	["Rock Head"] = { weapon="Hammer", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Hammer_Mace_Sphere_01"]
	["Spiky"] = { weapon="Hammer", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Hammer_Mace_Spikes_01"]
	["Small Hammer"] = { weapon="Hammer", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Hammer_Small_01"]
	["Small axe"] = { weapon="HandAxe", rarity="common", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_HandAxe_01"]
	["ThornPiercer"] = { weapon="Spear", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Ornate_Spear_01"]
	["Impulse"] = { weapon="Spikes", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Ornate_Spikes_01"]
	["Venom Spikes"] = { weapon="Spikes", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Ornate_Spikes_Long_01"]
	["Royal Edge"] = { weapon="Sword", rarity="epic", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Ornate_Sword_01"]
	["Noble Strike"] = { weapon="Sword", rarity="rare", adsAllowed=false, isGoblin=true },       -- OLD: ["Goblin_Ornate_Sword_02"]
	["Cloud Piercer"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Meshes/white tassel"]
	["Golden Lnace"] = { weapon="Spear", rarity="epic", adsAllowed=false },       -- OLD: ["Meshes/gold tassel"]
	["Atomic Shot"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["Molecular Revolver"]
	["Monster"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Monster"]
	["Pirate's Curse"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Morgan"]
	["Microchip"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Nano"]
	["Death"] = { weapon="Rifle", rarity="mythic", adsAllowed=false },       -- OLD: ["Necromancer"]
	["Moon Hunter"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["NightStalker Revolver"]
	["First Shot"] = { weapon="Revolver", rarity="common", adsAllowed=true },       -- OLD: ["Original Revolver"]
	["All Seeing"] = { weapon="Revolver", rarity="legendary", adsAllowed=true },       -- OLD: ["Overseer Revolver"]
	["Compact Nine"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["P99"]
	["Pocket Blast"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["PB"]
	["Heavy Storm"] = { weapon="LMG", rarity="common", adsAllowed=true },       -- OLD: ["PKM"]
	["Pocket Mag"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["PM"]
	["Firebird"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Phoenix"]
	["Warp Shot"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["Portal Revolver"]
	["Apex"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Predator"]
	["Champion"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Pro"]
	["Rocket Rain"] = { weapon="Launcher", rarity="rare", adsAllowed=true },       -- OLD: ["RPG-7"]
	["Support Fire"] = { weapon="LMG", rarity="common", adsAllowed=true },       -- OLD: ["RPK"]
	["Elite Support"] = { weapon="LMG", rarity="rare", adsAllowed=true },       -- OLD: ["RPK - Fort Hope Elite"]
	["Frost Support"] = { weapon="LMG", rarity="rare", adsAllowed=true },       -- OLD: ["RPK - Winter Warfare"]
	["Spectrum Six"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["Rainbow Revolver"]
	["Cowboy"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["Ranch Rifle"]
	["Cowboy Elite"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["Ranch Rifle - Laminated"]
	["Crimson Drake"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Red Dragon"]
	["Fate Shot"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["Revolver of Destiny"]
	["Thorn Blossom"] = { weapon="Revolver", rarity="epic", adsAllowed=true },       -- OLD: ["Rose Revolver"]
	["Liberty"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["Ruger American"]
	["Heritage"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["Ruger American - Heirloom"]
	["Battle Rifle"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["SCAR"]
	["Tiger Strike"] = { weapon="Rifle", rarity="rare", adsAllowed=true },       -- OLD: ["SCAR - Bengal"]
	["Sand Strike"] = { weapon="Rifle", rarity="rare", adsAllowed=true },       -- OLD: ["SCAR - Desert Classic"]
	["Camo King"] = { weapon="Rifle", rarity="epic", adsAllowed=true },       -- OLD: ["SCAR - Fancicam"]
	["Tactical Boom"] = { weapon="Shotgun", rarity="common", adsAllowed=true },       -- OLD: ["SPAS"]
	["Marksman"] = { weapon="Sniper", rarity="common", adsAllowed=true },       -- OLD: ["SVD"]
	["Elite Marksman"] = { weapon="Sniper", rarity="rare", adsAllowed=true },       -- OLD: ["SVU"]
	["Shogun"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Samurai"]
	["Desert Wind"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["Sand Revolver"]
	["Claw Strike"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Scratch"]
	["Swiss Guard"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["SiG550"]
	["Alpine"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["Sig220"]
	["Glitter Blast"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["SparkleTime Revolver"]
	["Lightning Rush"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Speed"]
	["Double Tap"] = { weapon="Revolver", rarity="epic", adsAllowed=true },       -- OLD: ["Splitfire Revolver"]
	["Arena Star"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Sport"]
	["Arena Legend"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Sport V2"]
	["MVP"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["StarPlayer Revolver"]
	["Close Range"] = { weapon="Shotgun", rarity="common", adsAllowed=true },       -- OLD: ["Super 90"]
	["Holiday Blast"] = { weapon="Shotgun", rarity="epic", adsAllowed=true },       -- OLD: ["Super 90 - Festive Wrap"]
	["Cursed Blast"] = { weapon="Shotgun", rarity="rare", adsAllowed=true },       -- OLD: ["Super 90 - Hexed"]
	["Shorty"] = { weapon="Shotgun", rarity="common", adsAllowed=true },       -- OLD: ["TAC14"]
	["Tiger Shorty"] = { weapon="Shotgun", rarity="rare", adsAllowed=true },       -- OLD: ["TAC14 - Bengal"]
	["Forest Shorty"] = { weapon="Shotgun", rarity="common", adsAllowed=true },       -- OLD: ["TAC14 - ODG"]
	["Undead Hunter"] = { weapon="Shotgun", rarity="epic", adsAllowed=true },       -- OLD: ["TAC14 - Zombie Slayer"]
	["Street Spray"] = { weapon="SMG", rarity="common", adsAllowed=true },       -- OLD: ["TEC-9"]
	["Tiger Spray"] = { weapon="SMG", rarity="rare", adsAllowed=true },       -- OLD: ["TEC-9 - Bengal"]
	["Silent Death"] = { weapon="SMG", rarity="rare", adsAllowed=true },       -- OLD: ["TEC-9 - Killing You Softly"]
	["Soviet Classic"] = { weapon="Rifle", rarity="rare", adsAllowed=true },       -- OLD: ["TOZ"]
	["Tactical Three"] = { weapon="Rifle", rarity="rare", adsAllowed=true },       -- OLD: ["TRS-301"]
	["Double Trouble"] = { weapon="Shotgun", rarity="common", adsAllowed=true },       -- OLD: ["The Belgian"]
	["Elegant Double"] = { weapon="Shotgun", rarity="rare", adsAllowed=true },       -- OLD: ["The Belgian - First Class"]
	["Laser Beam"] = { weapon="Revolver", rarity="epic", adsAllowed=true },       -- OLD: ["TheHyperLaser Revolver"]
	["Storm Strike"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Thunder"]
	["Striped Fury"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Tiger"]
	["Gold Digger"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Treasure Hunter"]
	["Thunder Bolt"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["Tunder S14"]
	["Tactical Sub"] = { weapon="SMG", rarity="common", adsAllowed=true },       -- OLD: ["UMP-45"]
	["Holiday Sub"] = { weapon="SMG", rarity="epic", adsAllowed=true },       -- OLD: ["UMP-45 - Festive Wrap"]
	["Magma Flow"] = { weapon="SMG", rarity="epic", adsAllowed=true },       -- OLD: ["UMP-45 - Lava Lamp"]
	["Liberty Six"] = { weapon="Revolver", rarity="epic", adsAllowed=true },       -- OLD: ["United States Revolver"]
	["Rapid Fire"] = { weapon="SMG", rarity="common", adsAllowed=true },       -- OLD: ["Uzi"]
	["Elite Rapid"] = { weapon="SMG", rarity="common", adsAllowed=true },       -- OLD: ["Uzi - Fort Hope Elite"]
	["China Fury"] = { weapon="SMG", rarity="epic", adsAllowed=true },       -- OLD: ["Uzi - Porcelain Vengeance"]
	["Vector"] = { weapon="SMG", rarity="common", adsAllowed=true },       -- OLD: ["Vector"]
	["Zap"] = { weapon="SMG", rarity="rare", adsAllowed=true },       -- OLD: ["Vector - Bengal"]
	["Electric Shock"] = { weapon="SMG", rarity="epic", adsAllowed=true },       -- OLD: ["Vector - Circuit Breaker"]
	["Whisper"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["Vintorez"]
	["Serpent"] = { weapon="SMG", rarity="common", adsAllowed=true },       -- OLD: ["Viper/Mp5"]
	["Victory"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Winner"]
	["Blizzard"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Blizzard"]
	["Frost Champion"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Winter Sport"]
	["Flash"] = { weapon="Rifle", rarity="mythic", adsAllowed=true },       -- OLD: ["Zeus"]
	["Crawler"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Worm"]
	["Power"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Power"]
	["Ego"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Ego"]
	["Prototype X"] = { weapon="Rifle", rarity="rare", adsAllowed=true },       -- OLD: ["XM24A3"]
	["Speed Blur"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Zoom"]
	["Diplomat"] = { weapon="Sniper", rarity="common", adsAllowed=true },       -- OLD: ["ambassador"]
	["Med Saw"] = { weapon="Misc", rarity="rare", adsAllowed=false },       -- OLD: ["amp"]
	["Pyranna"] = { weapon="Flamethrower", rarity="rare", adsAllowed=false },       -- OLD: ["backburner"]
	["Fishing Rod"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["bazaar"]
	["Starter Guard"] = { weapon="Shield", rarity="common", adsAllowed=false },       -- OLD: ["beginner's protector"]
	["Desert Guard"] = { weapon="Shield", rarity="common", adsAllowed=false },       -- OLD: ["beginner's protector 2"]
	["Light Rifle"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["carbine"]
	["Hardscope"] = { weapon="Rifle", rarity="rare", adsAllowed=true },       -- OLD: ["classic"]
	["Arrow Launcher"] = { weapon="Crossbow", rarity="common", adsAllowed=true },       -- OLD: ["crossbow"]
	["Diamond Six"] = { weapon="Revolver", rarity="epic", adsAllowed=true },       -- OLD: ["diamondback"]
	["Law Bringer"] = { weapon="Pistol", rarity="rare", adsAllowed=true },       -- OLD: ["enforcer"]
	["Signal Blast"] = { weapon="Flaregun", rarity="epic", adsAllowed=true },       -- OLD: ["flaregun"]
	["Wild West"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["frontier"]
	["Hot Shot"] = { weapon="Sniper", rarity="common", adsAllowed=true },       -- OLD: ["heatmaker"]
	["Tech Six"] = { weapon="Revolver", rarity="rare", adsAllowed=true },       -- OLD: ["iRevolver"]
	["Stranger"] = { weapon="Revolver", rarity="common", adsAllowed=true },       -- OLD: ["le'tranger"]
	["Life Drain"] = { weapon="Medigun", rarity="common", adsAllowed=false },       -- OLD: ["leechgun"]
	["Machine Snipe"] = { weapon="Sniper", rarity="common", adsAllowed=true },       -- OLD: ["machina"]
	["Heavy Spin"] = { weapon="Minigun", rarity="epic", adsAllowed=false },       -- OLD: ["natach"]
	["Overheater"] = { weapon="Minigun", rarity="rare", adsAllowed=false },       -- OLD: ["overuse"]
	["Fast Heal"] = { weapon="Medigun", rarity="rare", adsAllowed=false },       -- OLD: ["quickfix"]
	["Short Barrel"] = { weapon="Shotgun", rarity="common", adsAllowed=true },       -- OLD: ["sawn-off"]
	["Sharp Point"] = { weapon="Blade", rarity="common", adsAllowed=false },       -- OLD: ["shiv"]
	["Classic Shot"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["shna"]
	["Silent Scope"] = { weapon="Sniper", rarity="common", adsAllowed=true },       -- OLD: ["sleeper"]
	["Gangster"] = { weapon="SMG", rarity="common", adsAllowed=true },       -- OLD: ["tommy gun"]
	["Imperial"] = { weapon="Rifle", rarity="rare", adsAllowed=true },       -- OLD: ["type 99"]
	["Super Saw"] = { weapon="Melee", rarity="common", adsAllowed=false },       -- OLD: ["ubersaw"]
	["Vacuum"] = { weapon="Medigun", rarity="common", adsAllowed=false },       -- OLD: ["vac"]
	["Stinger"] = { weapon="Medigun", rarity="common", adsAllowed=false },       -- OLD: ["vita"]
	["Rapid Shot"] = { weapon="Rifle", rarity="common", adsAllowed=true },       -- OLD: ["waka"]

	["Retro Pixel"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["8Bit"]
["UltraZooka"] = { weapon="Launcher", rarity="epic", adsAllowed=true },       -- OLD: ["airstrike"]
["Rocket Launcher"] = { weapon="Launcher", rarity="common", adsAllowed=true },       -- OLD: ["sc"]
["Hotdog"] = { weapon="Flamethrower", rarity="rare", adsAllowed=false },       -- OLD: ["atomizor"]
["Pow"] = { weapon="SMG", rarity="rare", adsAllowed=true },       -- OLD: ["babyface"]
["casoh"] = { weapon="Launcher", rarity="epic", adsAllowed=true },       -- OLD: ["backbox"]
["Back Blast"] = { weapon="Shotgun", rarity="rare", adsAllowed=true },       -- OLD: ["backscatter"]
["Sphere Strike"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Ball"]
["Skull Basher"] = { weapon="Melee", rarity="common", adsAllowed=false },       -- OLD: ["basher"]
["Bye"] = { weapon="Launcher", rarity="epic", adsAllowed=true },       -- OLD: ["beggers"]
["Blood Rush"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Bleed"]
["Default"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Borders"]
["Piano"] = { weapon="Misc", rarity="common", adsAllowed=false },       -- OLD: ["bugle"]
["Caveman"] = { weapon="Melee", rarity="epic", adsAllowed=false },       -- OLD: ["caber"]
["Caveman Gone Wrong"] = { weapon="Melee", rarity="common", adsAllowed=false },       -- OLD: ["caberboom"]
["Walking Stick"] = { weapon="Melee", rarity="common", adsAllowed=false },       -- OLD: ["cane"]
["Warning Strike"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Caution"]
["Bull Rush"] = { weapon="Melee", rarity="rare", adsAllowed=false },       -- OLD: ["chargin"]
["Mac Attack"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Cheesy"]
["Rainbow Bite"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Chroma Fang"]
["Highland"] = { weapon="Melee", rarity="rare", adsAllowed=false },       -- OLD: ["claid"]
["Handgun"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Pistol"]
["Vintage AK"] = { weapon="AK", rarity="epic", adsAllowed=true },       -- OLD: ["Classic Ak"]
["Butcher"] = { weapon="Melee", rarity="common", adsAllowed=false },       -- OLD: ["cleaver"]
["Astroid"] = { weapon="Launcher", rarity="epic", adsAllowed=true },       -- OLD: ["cowmangler"]
["Prism Edge"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Crystal"]
["Demon"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Demon"]
["Biggie"] = { weapon="Launcher", rarity="epic", adsAllowed=true },       -- OLD: ["directhit"]
["Doom"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Doom"]
["Twin Boom"] = { weapon="Shotgun", rarity="epic", adsAllowed=true },       -- OLD: ["DoubleTrouble"]
["Balanced"] = { weapon="Melee", rarity="common", adsAllowed=false },       -- OLD: ["equil"]
["Quick Exit"] = { weapon="Launcher", rarity="rare", adsAllowed=true },       -- OLD: ["escape"]
["Medievel Sword"] = { weapon="Melee", rarity="epic", adsAllowed=false },       -- OLD: ["eyelander"]
["Bulky"] = { weapon="Melee", rarity="common", adsAllowed=false },       -- OLD: ["fan"]
["Viper Tooth"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Fang"]
["Shovel"] = { weapon="Melee", rarity="common", adsAllowed=false },       -- OLD: ["gardener"]
["Amethyst"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Gemstone"]
["Hook"] = { weapon="Greatsword", rarity="epic", adsAllowed=false },       -- OLD: ["Goblin_Greatsword_Curved_01"]
["Mini Axe"] = { weapon="Axe", rarity="rare", adsAllowed=false },       -- OLD: ["Goblin_Ornate_Axe_01"]
["Titan Smash"] = { weapon="Hammer", rarity="epic", adsAllowed=false },       -- OLD: ["Hammer"]
["Wolf Cry"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Howl"]
["Tracker"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Hunt"]
["Archer"] = { weapon="Bow", rarity="common", adsAllowed=true },       -- OLD: ["huntsman"]
["Grenade"] = { weapon="Launcher", rarity="rare", adsAllowed=true },       -- OLD: ["ironbomb"]
["Sky Rocket"] = { weapon="Launcher", rarity="epic", adsAllowed=true },       -- OLD: ["jumpernew"]
["Classic Jumper"] = { weapon="Launcher", rarity="rare", adsAllowed=true },       -- OLD: ["jumperold"]
["Freedom"] = { weapon="Launcher", rarity="epic", adsAllowed=true },       -- OLD: ["liberty"]
["Bolt Strike"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Lightning"]
["Cannon Ball"] = { weapon="Launcher", rarity="epic", adsAllowed=true },       -- OLD: ["lochnload"]
["Wild Shot"] = { weapon="Launcher", rarity="rare", adsAllowed=true },       -- OLD: ["loosecannon"]
["Medium Edge"] = { weapon="Sword", rarity="epic", adsAllowed=false },       -- OLD: ["Mid Sword"]
["Omega"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Omega"]
["Classic Rocket"] = { weapon="Launcher", rarity="rare", adsAllowed=true },       -- OLD: ["original"]
["Panic Button"] = { weapon="Misc", rarity="rare", adsAllowed=false },       -- OLD: ["panic"]
["Royal Guard"] = { weapon="Melee", rarity="epic", adsAllowed=false },       -- OLD: ["persian"]
["Pop Shot"] = { weapon="SMG", rarity="rare", adsAllowed=true },       -- OLD: ["popper"]
["Pretty Gun"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["prettyboys"]
["Backup"] = { weapon="Minigun", rarity="common", adsAllowed=false },       -- OLD: ["reserve"]
["Red Jewel"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Ruby"]
["Desert Fury"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Sandstorm"]
["Razor Edge"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Sharpness"]
["Guard"] = { weapon="Shield", rarity="common", adsAllowed=false },       -- OLD: ["shield"]
["Quick Shot"] = { weapon="Rifle", rarity="rare", adsAllowed=true },       -- OLD: ["shortstop"]
["Bone Slicer"] = { weapon="Melee", rarity="rare", adsAllowed=false },       -- OLD: ["skullcutter"]
["Holy Fire"] = { weapon="Flamethrower", rarity="epic", adsAllowed=false },       -- OLD: ["solemn"]
["Grand Strike"] = { weapon="Melee", rarity="rare", adsAllowed=false },       -- OLD: ["splended"]
["Solar Staff"] = { weapon="Melee", rarity="rare", adsAllowed=false },       -- OLD: ["sunstick"]
["Wave Changer"] = { weapon="Melee", rarity="rare", adsAllowed=false },       -- OLD: ["tideturn"]
["Volcano"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Volcan"]
["War"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["War"]
["Lash"] = { weapon="Melee", rarity="rare", adsAllowed=false },       -- OLD: ["whip"]
["Side Arm"] = { weapon="Pistol", rarity="rare", adsAllowed=true },       -- OLD: ["winger"]
["Burner"] = { weapon="Flamethrower", rarity="common", adsAllowed=false },       -- OLD: ["wrap"]
["Controller"] = { weapon="Misc", rarity="common", adsAllowed=false },       -- OLD: ["wrangler"]
["Dark Samurai"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Zamatsu"]
["Shadow Strike"] = { weapon="Melee", rarity="rare", adsAllowed=false },       -- OLD: ["zato"]

-- ========================================
-- ADDITIONAL ITEMS FROM SKINLIBRARY (111 PREFIX)
-- These items exist in-game but haven't been fully configured yet
-- Default rarity is "common" - update as needed
-- ========================================
["trump"] = { weapon="Pistol", rarity="epic", adsAllowed=true },       -- OLD: ["Amerigun"]
["Raven"] = { weapon="Axe", rarity="epic", adsAllowed=false },       -- OLD: ["BattleAxeII"]
["Power Shot"] = { weapon="Pistol", rarity="epic", adsAllowed=true },       -- OLD: ["Blaster"]
["Cyan"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Blue Candy"]
["Blueberry"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Blue Seer"]
["Snow Blaster!"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Blue Sugar"]
["Shark Bite"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Boneblade"]
["Sweet Strike"] = { weapon="Blade", rarity="common", adsAllowed=false },       -- OLD: ["Candy"]
["Frozen Touch"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Chill"]
["Black Matter"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Chroma Boneblade"]
["Happy Hour"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Chroma Gingerblade"]
["Work"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Clockwork"]
["Pointy"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Deathshard"]
["Forever Edge"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Eternal"]
["Infinite Power"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Eternal II"]
["Crystal Cold"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Frostsaber"]
["Ginger Man"] = { weapon="Pistol", rarity="epic", adsAllowed=true },       -- OLD: ["Ginger Luger"]
["Cookie Cutter"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Gingerblade"]
["Golden Sweet"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Gold Sugar"]
["Lime Shot"] = { weapon="Pistol", rarity="common", adsAllowed=true },       -- OLD: ["Green Luger"]
["Spooky Edge"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Hallow's Blade"]
["Ghost Blade"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Hallow's Edge"]
["Carpenter"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Hand Saw"]
["Frost Fury"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Ice Dragon"]
["Frozen Fang"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Ice Shard"]
["Light Beam"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Laser"]
["Classic Gun"] = { weapon="Pistol", rarity="rare", adsAllowed=true },       -- OLD: ["Luger"]
["Midnight"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Nightblade"]
["Patriot"] = { weapon="Blade", rarity="rare", adsAllowed=false },       -- OLD: ["Old Glory"]
["Sunset Vision"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Orange Seer"]
["Pixel"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Pixel"]
["Halloween King"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Pumpking"]
["Mystic Vision"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Purple Seer"]
["Crimson Ghost"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Red Hallow "]
["Scarlet Shot"] = { weapon="Pistol", rarity="rare", adsAllowed=true },       -- OLD: ["Red Luger"]
["Blood Vision"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Red Seer"]
["Buzz Cut"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Saw"]
["Vision Blade"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Seer"]
["Ocean Hunter"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Shark"]
["Horror"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Slasher"]
["Winter Crystal"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Snowflake"]
["Web Weaver"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Spider"]
["Sweet Tooth"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Sugar"]
["Ocean Wave"] = { weapon="Blade", rarity="legendary", adsAllowed=false },       -- OLD: ["Tides"]
["Cyber Strike"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Virtual"]
["Ultimate Frost"] = { weapon="Blade", rarity="mythic", adsAllowed=false },       -- OLD: ["Winter's Edge"]
["Holiday Cheer"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Xmas"]
["Golden Vision"] = { weapon="Blade", rarity="epic", adsAllowed=false },       -- OLD: ["Yellow Seer"]
["Quick Escape"] = { weapon="Launcher", rarity="common", adsAllowed=true },       -- OLD: ["escape"]
}

-- SkinLibrary scanning functionality
	-- SkinLibrary scanning functionality

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _scanned = false

-- Extract TextureId from a model
local function extractTextureId(model)
	if not model then return nil end
	
	-- Method 1: Check if model is a MeshPart with TextureId (safe check)
	if model:IsA("MeshPart") then
		local success, textureId = pcall(function()
			return model.TextureId
		end)
		if success and textureId and textureId ~= "" then
			return textureId
		end
	end
	
	-- Method 2: Look for MeshPart children with TextureId
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("MeshPart") then
			local success, textureId = pcall(function()
				return child.TextureId
			end)
			if success and textureId and textureId ~= "" then
				return textureId
			end
		end
	end
	
	-- Method 3: Look for Parts with single Mesh child that has TextureId
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") then
			local mesh = child:FindFirstChildOfClass("SpecialMesh") or child:FindFirstChildOfClass("Mesh")
			if mesh then
				local success, textureId = pcall(function()
					return mesh.TextureId
				end)
				if success and textureId and textureId ~= "" then
					return textureId
				end
			end
		end
	end
	
	-- Method 4: Recursive search through all descendants
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("MeshPart") then
			local success, textureId = pcall(function()
				return descendant.TextureId
			end)
			if success and textureId and textureId ~= "" then
				return textureId
			end
		elseif descendant:IsA("SpecialMesh") or descendant:IsA("Mesh") then
			local success, textureId = pcall(function()
				return descendant.TextureId
			end)
			if success and textureId and textureId ~= "" then
				return textureId
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
			-- Only update metadata for skins that are explicitly declared in the SKINS table.
			-- This prevents models present in ReplicatedStorage.SkinLibrary from being
			-- automatically added to the configured SKINS list. If a skin is already
			-- declared in SKINS we will fill in any missing icon/texture metadata.
			local textureId = extractTextureId(model)
			if SKINS[skinId] then
				local meta = SKINS[skinId]
				meta.icon = meta.icon or textureId or DEFAULT_ICONS[meta.weapon] or "rbxassetid://6764432243"
				meta.textureId = meta.textureId or textureId or meta.icon
			end
		end
	end
	
	local totalSkins = 0
	for _ in pairs(SKINS) do totalSkins = totalSkins + 1 end
	
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
	return (weapon and DEFAULT_ADS.Grip[weapon]) or CFrame.new(0, 0, -0.2)
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

return SkinConfig


