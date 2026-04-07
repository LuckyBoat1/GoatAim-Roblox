-- InventoryRotationMap.lua
-- Complete mapping of every item name to its effective CFrame.Angles rotation
-- as applied in Inventory.client.luau's setupViewport function.
--
-- When an item appears in multiple lists, the FIRST matching elseif branch wins.
-- Priority order: test4 → test5 → test44 → test45 → test46 → test47 → test48 →
--   test49 → test50 → test6 → test7 → test8 → test15 → test16 → test17 → test18 →
--   test19 → test20 → chaser → test21 → test22 → test23 → test24 → test25 →
--   test26 → test27 → test28 → test29 → test30 → test31 → test32 → test33 →
--   test34 → test35 → test36 → test37 → test39 → test40 → test41 → test42 →
--   test43 → leftRotation → testRotation → test2Rotation → specialY → specialXZ →
--   goblin → meshes → else (no rotation)

local InventoryRotationMap = {
	----------------------------------------------------------------------
	-- test4: CFrame.Angles(math.rad(90), math.rad(0), math.rad(270))
	----------------------------------------------------------------------
	["FN2000"]                 = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["Compact Nine"]           = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["Alpine"]                 = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["Black kite"]             = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),

	----------------------------------------------------------------------
	-- test5: CFrame.Angles(math.rad(180), math.rad(0), math.rad(90))
	----------------------------------------------------------------------
	["AS-VAL"]                 = CFrame.Angles(math.rad(180), math.rad(0), math.rad(90)),

	----------------------------------------------------------------------
	-- test44: CFrame.Angles(math.rad(90), math.rad(-90), math.rad(90))
	-- Note: "Patriot" also in test41 — test44 wins (higher priority)
	----------------------------------------------------------------------
	["Ocean Wave"]             = CFrame.Angles(math.rad(90), math.rad(-90), math.rad(90)),
	["Frozen Fang"]            = CFrame.Angles(math.rad(90), math.rad(-90), math.rad(90)),
	["Frost Fury"]             = CFrame.Angles(math.rad(90), math.rad(-90), math.rad(90)),
	["Patriot"]                = CFrame.Angles(math.rad(90), math.rad(-90), math.rad(90)), -- also in test41

	----------------------------------------------------------------------
	-- test45: CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))
	-- Note: "Quick Exit" also in test41 — test45 wins (higher priority)
	----------------------------------------------------------------------
	["Quick Exit"]             = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)), -- also in test41

	----------------------------------------------------------------------
	-- test46: CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))
	----------------------------------------------------------------------
	["Carpenter"]              = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),

	----------------------------------------------------------------------
	-- test47: CFrame.Angles(math.rad(0), math.rad(0), math.rad(270))
	----------------------------------------------------------------------
	["Flame"]                  = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270)),

	----------------------------------------------------------------------
	-- test48: CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))
	----------------------------------------------------------------------
	["Bull Rush"]              = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Grand Strike"]           = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),

	----------------------------------------------------------------------
	-- test49: CFrame.Angles(math.rad(180), math.rad(0), math.rad(180))
	----------------------------------------------------------------------
	["Holy Fire"]              = CFrame.Angles(math.rad(180), math.rad(0), math.rad(180)),

	----------------------------------------------------------------------
	-- test50: CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))
	----------------------------------------------------------------------
	["Viper Tooth"]            = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Rainbow Bite"]           = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),

	----------------------------------------------------------------------
	-- test6: CFrame.Angles(math.rad(0), math.rad(90), math.rad(270))
	-- (empty — items were moved to test23)
	----------------------------------------------------------------------

	----------------------------------------------------------------------
	-- test7: CFrame.Angles(math.rad(0), math.rad(0), math.rad(270))
	-- (also applies CFrame.new(0, 1, 0) positional offset)
	----------------------------------------------------------------------
	["Blizzard"]               = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270)),
	["Power"]                  = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270)),
	["Ego"]                    = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270)),

	----------------------------------------------------------------------
	-- test8: CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))
	-- Note: Blood&Bones, Cyborg, Death, Leviathan, Sun also in testItems — test8 wins
	----------------------------------------------------------------------
	["Blood&Bones"]            = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)), -- also in testItems
	["Cyborg"]                 = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)), -- also in testItems
	["Death"]                  = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)), -- also in testItems
	["Leviathan"]              = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)), -- also in testItems
	["Sun"]                    = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)), -- also in testItems
	["Monster"]                = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Heat"]                   = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),

	----------------------------------------------------------------------
	-- test15: CFrame.Angles(math.rad(90), math.rad(0), math.rad(270))
	-- Note: all items also in testItems — test15 wins
	----------------------------------------------------------------------
	["Thunder Bolt"]           = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)), -- also in testItems
	["Swiss Guard"]            = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)), -- also in testItems
	["Short Barrel"]           = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)), -- also in testItems
	["Pocket Blast"]           = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)), -- also in testItems
	["Makarov"]                = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)), -- also in testItems
	["L85"]                    = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)), -- also in testItems
	["Soviet Classic"]         = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)), -- also in testItems
	["Elite Marksman"]         = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)), -- also in testItems

	----------------------------------------------------------------------
	-- test16: CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
	-- Note: all items also in test2Items — test16 wins
	----------------------------------------------------------------------
	["Pocket Mag"]             = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)), -- also in test2Items
	["Tactical Boom"]          = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)), -- also in test2Items
	["Marksman"]               = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)), -- also in test2Items
	["Fort"]                   = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)), -- also in test2Items

	----------------------------------------------------------------------
	-- test17: CFrame.Angles(math.rad(0), math.rad(0), math.rad(90))
	----------------------------------------------------------------------
	["Just give me my money"]  = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),

	----------------------------------------------------------------------
	-- test18: CFrame.Angles(math.rad(360), math.rad(0), math.rad(-90))
	-- Note: "Rocket Rain" also in test2Items — test18 wins
	----------------------------------------------------------------------
	["Rocket Rain"]            = CFrame.Angles(math.rad(360), math.rad(0), math.rad(-90)), -- also in test2Items

	----------------------------------------------------------------------
	-- test19: CFrame.Angles(math.rad(-90), math.rad(0), math.rad(90))
	----------------------------------------------------------------------
	["Emergency Surgery"]      = CFrame.Angles(math.rad(-90), math.rad(0), math.rad(90)),

	----------------------------------------------------------------------
	-- test20: CFrame.Angles(math.rad(0), math.rad(0), math.rad(360))
	-- Note: "Gangster" also in itemsToRotateLeft — test20 wins
	----------------------------------------------------------------------
	["Gangster"]               = CFrame.Angles(math.rad(0), math.rad(0), math.rad(360)), -- also in itemsToRotateLeft

	----------------------------------------------------------------------
	-- Chaser: CFrame.Angles(math.rad(90), math.rad(180), math.rad(90))
	----------------------------------------------------------------------
	["Chaser"]                 = CFrame.Angles(math.rad(90), math.rad(180), math.rad(90)),

	----------------------------------------------------------------------
	-- test21: CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))
	-- Note: "Prism Edge" also in test40, "Walking Stick"/"Butcher" also in test39 — test21 wins
	----------------------------------------------------------------------
	["Retro Pixel"]            = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Sphere Strike"]          = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Default"]                = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Warning Strike"]         = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Mac Attack"]             = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Chroma"]                 = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Prism Edge"]             = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)), -- also in test40
	["Cash"]                   = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Sharp"]                  = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Whity"]                  = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Sight"]                  = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Jaz"]                    = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Somber"]                 = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Cool"]                   = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Poison"]                 = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Shade"]                  = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Sugar Swag"]             = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Walking Stick"]          = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)), -- also in test39
	["Butcher"]                = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)), -- also in test39
	["SAPPHIRE"]               = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["RUBY"]                   = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Sapphire"]               = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Ruby"]                   = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),

	----------------------------------------------------------------------
	-- test22: CFrame.Angles(math.rad(0), math.rad(0), math.rad(-90))
	----------------------------------------------------------------------
	["Knife"]                  = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-90)),

	----------------------------------------------------------------------
	-- test23: CFrame.Angles(math.rad(0), math.rad(0), math.rad(360))
	----------------------------------------------------------------------
	["MP5"]                    = CFrame.Angles(math.rad(0), math.rad(0), math.rad(360)),

	----------------------------------------------------------------------
	-- test24: CFrame.Angles(math.rad(-90), math.rad(0), math.rad(90))
	----------------------------------------------------------------------
	["Med Saw"]                = CFrame.Angles(math.rad(-90), math.rad(0), math.rad(90)),

	----------------------------------------------------------------------
	-- test25: CFrame.Angles(math.rad(30), math.rad(0), math.rad(0))
	-- (empty — LMG AE was removed from this list)
	----------------------------------------------------------------------

	----------------------------------------------------------------------
	-- test26: CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
	----------------------------------------------------------------------
	["Classic Shot"]           = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)),

	----------------------------------------------------------------------
	-- test27: CFrame.Angles(math.rad(0), math.rad(0), math.rad(-90))
	----------------------------------------------------------------------
	["Tactical Three"]         = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-90)),

	----------------------------------------------------------------------
	-- test28: CFrame.Angles(math.rad(180), math.rad(0), math.rad(180))
	----------------------------------------------------------------------
	["Prototype X"]            = CFrame.Angles(math.rad(180), math.rad(0), math.rad(180)),

	----------------------------------------------------------------------
	-- test29: CFrame.Angles(math.rad(360), math.rad(180), math.rad(30))
	----------------------------------------------------------------------
	["Imperial"]               = CFrame.Angles(math.rad(360), math.rad(180), math.rad(30)),

	----------------------------------------------------------------------
	-- test30: CFrame.Angles(math.rad(360), math.rad(0), math.rad(90))
	----------------------------------------------------------------------
	["Heavy Storm"]            = CFrame.Angles(math.rad(360), math.rad(0), math.rad(90)),

	----------------------------------------------------------------------
	-- test31: CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))
	----------------------------------------------------------------------
	["Sharp Point"]            = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),

	----------------------------------------------------------------------
	-- test32: CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
	-- (empty)
	----------------------------------------------------------------------

	----------------------------------------------------------------------
	-- test33: CFrame.Angles(math.rad(0), math.rad(0), math.rad(270))
	----------------------------------------------------------------------
	["Whisper"]                = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270)),

	----------------------------------------------------------------------
	-- test34: CFrame.Angles(math.rad(90), math.rad(0), math.rad(-90))
	-- Note: "Serpent" also in testItems — test34 wins
	----------------------------------------------------------------------
	["Serpent"]                = CFrame.Angles(math.rad(90), math.rad(0), math.rad(-90)), -- also in testItems

	----------------------------------------------------------------------
	-- test35: CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
	----------------------------------------------------------------------
	["Stinger"]                = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)),

	----------------------------------------------------------------------
	-- test36: CFrame.Angles(math.rad(90), math.rad(0), math.rad(90))
	----------------------------------------------------------------------
	["Rapid Shot"]             = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)),

	----------------------------------------------------------------------
	-- test37: CFrame.Angles(math.rad(15), math.rad(90), math.rad(180))
	-- (empty)
	----------------------------------------------------------------------

	----------------------------------------------------------------------
	-- test39: CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))
	-- Note: "Butcher" & "Walking Stick" already claimed by test21,
	--       "Controller" also in test2Items — test39 wins for Controller
	----------------------------------------------------------------------
	["UltraZooka"]             = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Pow"]                    = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["casoh"]                  = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Back Blast"]             = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Bye"]                    = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Astroid"]                = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Biggie"]                 = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	-- ["Butcher"] already mapped above (test21 wins)
	["Medievel Sword"]         = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Bulky"]                  = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Grenade"]                = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Sky Rocket"]             = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Classic Jumper"]         = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Freedom"]                = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Wild Shot"]              = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Classic Rocket"]         = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Panic Button"]           = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Pretty Gun"]             = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Backup"]                 = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Rocket Launcher"]        = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Quick Shot"]             = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Guard"]                  = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Controller"]             = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)), -- also in test2Items; test39 wins
	["Side Arm"]               = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	-- ["Walking Stick"] already mapped above (test21 wins)

	----------------------------------------------------------------------
	-- test40: CFrame.Angles(math.rad(0), math.rad(0), math.rad(90))
	-- Note: "Prism Edge" already claimed by test21
	----------------------------------------------------------------------
	-- ["Prism Edge"] already mapped above (test21 wins)
	["Cannon Ball"]            = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),

	----------------------------------------------------------------------
	-- test41: CFrame.Angles(math.rad(0), math.rad(0), math.rad(90))
	-- Note: "Patriot" already claimed by test44, "Quick Exit" by test45
	----------------------------------------------------------------------
	["trump"]                  = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Power Shot"]             = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Cyan"]                   = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Sweet Strike"]           = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Ginger Man"]             = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Lime Shot"]              = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Knife Box 2 Kit"]        = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Light Beam"]             = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Classic Gun"]            = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	-- ["Patriot"] already mapped above (test44 wins)
	["Scarlet Shot"]           = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Ocean Hunter"]           = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Winter Crystal"]         = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	-- ["Quick Exit"] already mapped above (test45 wins)

	----------------------------------------------------------------------
	-- test42: CFrame.Angles(math.rad(0), math.rad(180), math.rad(90))
	----------------------------------------------------------------------
	["Raven"]                  = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Blueberry"]              = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Snow Blaster!"]          = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Shark Bite"]             = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Frozen Touch"]           = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Black Matter"]           = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Happy Hour"]             = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Forever Edge"]           = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Infinite Power"]         = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Cookie Cutter"]          = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Spooky Edge"]            = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Ghost Blade"]            = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Golden Sweet"]           = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Midnight"]               = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Sunset Vision"]          = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Halloween King"]         = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Mystic Vision"]          = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Crimson Ghost"]          = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Blood Vision"]           = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Buzz Cut"]               = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Vision Blade"]           = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Horror"]                 = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Sweet Tooth"]            = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Cyber Strike"]           = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Golden Vision"]          = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),

	----------------------------------------------------------------------
	-- test43: CFrame.Angles(math.rad(0), math.rad(90), math.rad(180))
	----------------------------------------------------------------------
	["Work"]                   = CFrame.Angles(math.rad(0), math.rad(90), math.rad(180)),
	["Crystal Cold"]           = CFrame.Angles(math.rad(0), math.rad(90), math.rad(180)),
	["Pixel"]                  = CFrame.Angles(math.rad(0), math.rad(90), math.rad(180)),
	["Web Weaver"]             = CFrame.Angles(math.rad(0), math.rad(90), math.rad(180)),
	["Holiday Cheer"]          = CFrame.Angles(math.rad(0), math.rad(90), math.rad(180)),

	----------------------------------------------------------------------
	-- leftRotation (itemsToRotateLeft): CFrame.Angles(math.rad(0), math.rad(0), math.rad(90))
	-- Note: "Copper" also in test2Items — leftRotation wins
	-- Note: "Gangster" already claimed by test20
	----------------------------------------------------------------------
	["Fire Touch"]             = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Alpha Sapphire"]         = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Copper"]                 = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)), -- also in test2Items; leftRotation wins
	["Apple"]                  = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Bubble"]                 = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["BlackIron Revolver"]     = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Cheese"]                 = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Zone"]                   = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Cube Squared"]           = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Spoon"]                  = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Dreams of Gold"]         = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Engraved Revolver"]      = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Fabulous Revolver"]      = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Neon Revolver"]          = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Gold Revolver"]          = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["HyperRed Revolver"]      = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Infiltrator Revolver"]   = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["MS Revolver"]            = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["McDonald Revolver"]      = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Atomic Shot"]            = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["All Seeing"]             = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["First Shot"]             = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Moon Hunter"]            = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Warp Shot"]              = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Spectrum Six"]           = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Thorn Blossom"]          = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Fate Shot"]              = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Desert Wind"]            = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Glitter Blast"]          = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["MVP"]                    = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Double Tap"]             = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Laser Beam"]             = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Liberty Six"]            = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Tech Six"]               = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	-- ["Gangster"] already mapped above (test20 wins)

	----------------------------------------------------------------------
	-- testRotation (testItems): CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))
	-- Note: Many items already claimed by test8/test15/test34
	----------------------------------------------------------------------
	["AK-Chaos"]               = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Sea Bone"]               = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["AK-Jungle"]              = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	-- ["L85"] already mapped above (test15 wins)
	-- ["Makarov"] already mapped above (test15 wins)
	-- ["Pocket Blast"] already mapped above (test15 wins)
	-- ["Elite Marksman"] already mapped above (test15 wins)
	-- ["Swiss Guard"] already mapped above (test15 wins)
	-- ["Soviet Classic"] already mapped above (test15 wins)
	-- ["Serpent"] already mapped above (test34 wins)
	-- ["Thunder Bolt"] already mapped above (test15 wins)
	-- ["Short Barrel"] already mapped above (test15 wins)
	-- ["Blood&Bones"] already mapped above (test8 wins)
	-- ["Cyborg"] already mapped above (test8 wins)
	-- ["Death"] already mapped above (test8 wins)
	-- ["Leviathan"] already mapped above (test8 wins)
	-- ["Sun"] already mapped above (test8 wins)

	----------------------------------------------------------------------
	-- test2Rotation (test2Items): CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))
	-- Note: Fort/Pocket Mag/Tactical Boom/Marksman claimed by test16,
	--       Rocket Rain by test18, Copper by leftRotation, Controller by test39
	----------------------------------------------------------------------
	-- ["Fort"] already mapped above (test16 wins)
	["Handgun"]                = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	-- ["Pocket Mag"] already mapped above (test16 wins)
	-- ["Rocket Rain"] already mapped above (test18 wins)
	-- ["Marksman"] already mapped above (test16 wins)
	-- ["Tactical Boom"] already mapped above (test16 wins)
	-- ["Copper"] already mapped above (leftRotation wins)
	["Pyranna"]                = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Fishing Rod"]            = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Light Rifle"]            = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Hardscope"]              = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Arrow Launcher"]         = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Diamond Six"]            = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Law Bringer"]            = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Signal Blast"]           = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Wild West"]              = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Hot Shot"]               = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Stranger"]               = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Life Drain"]             = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Machine Snipe"]          = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Heavy Spin"]             = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Overheater"]             = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Fast Heal"]              = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Silent Scope"]           = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Vacuum"]                 = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	-- ["Controller"] already mapped above (test39 wins)

	----------------------------------------------------------------------
	-- specialY (specialYRotationItems): CFrame.Angles(math.rad(360), math.rad(0), math.rad(0))
	----------------------------------------------------------------------
	["LMG AE"]                 = CFrame.Angles(math.rad(360), math.rad(0), math.rad(0)),

	----------------------------------------------------------------------
	-- specialXZ (specialXZRotationItems): CFrame.Angles(math.rad(0), math.rad(0), math.rad(360))
	----------------------------------------------------------------------
	["Enfield Bren"]           = CFrame.Angles(math.rad(0), math.rad(0), math.rad(360)),

	----------------------------------------------------------------------
	-- DYNAMIC FALLBACKS (not item-name-based; applied by category checks):
	--
	-- Goblin items (isGoblinItem):
	--   CFrame.Angles(math.rad(0), math.rad(0), math.rad(180))
	--
	-- Meshes / Spear items (isOtherMeshesItem):
	--   CFrame.Angles(math.rad(90), 0, 0)
	--
	-- Everything else: no rotation (CFrame.new())
	----------------------------------------------------------------------
}

return InventoryRotationMap
