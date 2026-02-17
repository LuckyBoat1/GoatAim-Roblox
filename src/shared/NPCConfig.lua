--[[
	NPCConfig - Define all NPC configurations here
	
	HITBOX-BASED DAMAGE SYSTEM:
	The damage system is now fully integrated into NPCConfig. Each attack can have multiple effects,
	and each effect can deal damage using Hitbox2 model cloning.
	
	HOW IT WORKS:
	1. When an effect triggers (on animation event, time marker, or attack start)
	2. If the effect has "damage" and "hitboxAttachment" fields configured
	3. A Hitbox2 model is cloned and positioned at the attachment
	4. The hitbox detects player collisions and applies damage
	5. Hitbox is cleaned up after "hitboxDuration" expires
	
	CONFIGURATION FIELDS FOR DAMAGE:
	- damage: Number - How much damage this effect deals (required for damage)
	- hitboxAttachment: String - Name of attachment where hitbox spawns (required for damage)
	- hitboxDuration: Number (optional) - How long hitbox stays active (default 0.5 seconds)
	
	EXAMPLE - Multiple punch attack with increasing damage:
	[1] = {
		type = "melee",
		animation = Animations.ComboAttack,
		effects = {
			-- First punch - Yellow VFX, 20 damage
			{
				trigger = "event",
				eventName = "Damage",
				eventOccurrence = 1,
				effectName = "Hits",
				effectChild = "Yellow",
				attachment = "LeftVfx",
				damage = 20,              -- FIRST HIT: 20 damage
				hitboxAttachment = "LeftHitbox",
				hitboxDuration = 0.3,
			},
			-- Second punch - Orange VFX, 25 damage
			{
				trigger = "event",
				eventName = "Damage",
				eventOccurrence = 2,
				effectName = "Hits",
				effectChild = "Orange",
				attachment = "LeftVfx",
				damage = 25,              -- SECOND HIT: 25 damage
				hitboxAttachment = "LeftHitbox",
				hitboxDuration = 0.3,
			},
			-- Third punch - Red VFX, 30 damage (finisher)
			{
				trigger = "event",
				eventName = "Damage",
				eventOccurrence = 3,
				effectName = "Hits",
				effectChild = "Red",
				attachment = "LeftVfx",
				damage = 30,              -- THIRD HIT: 30 damage
				hitboxAttachment = "LeftHitbox",
				hitboxDuration = 0.3,
			},
		},
	},
	
	MULTIPLE ATTACK SETUP:
	Each NPC can have up to 4 attacks:
	[1] = { ... }   -- Normal attack 1
	[2] = { ... }   -- Normal attack 2  
	[3] = { ... }   -- Normal attack 3
	[4] = { ... }   -- Ultimate (1/10 chance, isUlt = true)
	
	Each attack can have different damage values - customize per NPC and per attack!
]]
--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Animations = require(sharedFolder:WaitForChild("Animations"))

local NPCConfig = {}

-- ============================================================
-- END NPC CONFIGURATION
-- ============================================================
NPCConfig.End = {
	-- Model Settings
	modelName = "End",              -- Name in ReplicatedStorage.Npc
	spawnName = "EndSpawn",         -- Name of spawn model in Workspace
	npcCount = 1,                   -- How many to spawn
	
	-- Stats
	health = 5000,                  -- Boss health
	walkSpeed = 16,
	aggroRange = 100,               -- Detection range
	preferredDistance = 40,         -- Tries to stay this far (for ranged)
	damage = 10,
	attackCooldown = 2,             -- Seconds between attacks
	
	-- Idle/Wander Settings
	idleTime = {1, 2},              -- Min/max idle time
	walkTime = {3, 6},              -- Min/max walk time
	walkRadius = 100,               -- Wander radius from spawn
	
	-- Base Animations
	animIdle = 78973476418857,
	animWalk = 97383942534616,
	
	-- Dash Animations (used by melee attacks)
	animForwardDash = Animations.ForwardDash,
	animLeftDash = Animations.LeftDash,
	animRightDash = Animations.RightDash,
	
	-- Flight Animation (optional)
	animFlight = Animations.ForwardFlight,
	
	-- ATTACKS (1-3 are normal, 4 is ULT with 1/10 chance)
	attacks = {
		-- Attack 1: MELEE (dash + hammer smash)
		[1] = {
			type = "melee",
			animation = Animations.HammerSmash,
			dashAnimation = Animations.ForwardDash,
			targetDistance = 10,          -- Stop 10 studs from player
			dashMinDistance = 5,          -- Only dash if further than this
			dashMaxDistance = 50,         -- Max dash distance in studs
			
			-- Animation speed adjustments (optional)
			animSpeedStart = 0.5,         -- Speed at start
			animSpeedNormal = 1,          -- Normal speed
			animSpeedDelay = 0.5,         -- When to switch to normal speed
			--
			-- Effects to spawn
			effects = {
				-- On animation event "Cracks" - Deals 40 damage on impact
				{
					trigger = "event",
					eventName = "Cracks",
					effectName = "GroundSlamEffect",
					attachment = "Effect",
					duration = 3,
					useExactPosition = true,  -- Spawn at exact position, not following
					-- DAMAGE CONFIG
					damage = 40,                    -- Damage to deal
					hitboxAttachment = "Effect",   -- Where to spawn hitbox (same as attachment)
					hitboxDuration = 0.5,          -- How long hitbox stays active
				},
				-- Spawn immediately when attack starts
				{
					trigger = "start",
					effectName = "GroundSlamEffectEnergy",
					attachment = "Floor",
					duration = 2,
				},
				-- Trail during dash (no damage)
				{
					trigger = "dash",
					effectName = "Trail",
					attachment = "Trail",
					-- duration is set to dash animation length automatically
				},
			},
		},
		
		-- Attack 2: RANGED (LowMagic + beam) - Deals 35 damage
		[2] = {
			type = "ranged",
			animation = Animations.LowMagic,
			
			-- Pause animation at 98% and freeze NPC
			pauseAtPercent = 0.98,
			freezeDuration = 3,           -- How long to hold the pose
			
			-- Effects
			effects = {
				{
					trigger = "pause",        -- Spawn when animation pauses
					effectName = "Beam",
					attachment = "Effect",
					targetPlayer = true,      -- Beam targets player position
					duration = 3,
					-- DAMAGE CONFIG
					damage = 35,                    -- Damage from beam
					hitboxAttachment = "Effect",   -- Where beam hitbox spawns
					hitboxDuration = 3,            -- How long beam is active
				},
			},
		},
		
		-- Attack 3: RANGED (MagicCircle + beam) - Deals 30 damage
		[3] = {
			type = "ranged",
			animation = Animations.MagicCircle,
			
			pauseAtPercent = 0.98,
			freezeDuration = 3,
			
			effects = {
				{
					trigger = "pause",
					effectName = "Beam",
					attachment = "Effect",
					targetPlayer = true,
					duration = 3,
					-- DAMAGE CONFIG
					damage = 30,
					hitboxAttachment = "Effect",
					hitboxDuration = 3,
				},
			},
		},
		
		-- Attack 4: ULT (1/10 chance - GatherChargeBlast + Beam19) - Deals 60 damage
		[4] = {
			type = "ranged",
			animation = Animations.GatherChargeBlast,
			isUlt = true,                 -- 1/10 chance to trigger
			
			-- Pause on animation event instead of percent
			pauseOnEvent = "Ult",
			freezeDuration = 3,
			
			effects = {
				{
					trigger = "event",
					eventName = "Ult",
					effectName = "Beam19",
					attachment = "Effect",
					targetPlayer = true,
					duration = 3,
					-- DAMAGE CONFIG
					damage = 60,
					hitboxAttachment = "Effect",
					hitboxDuration = 3,
				},
			},
		},
	},
}

-- ============================================================
-- BEGINNING NPC CONFIGURATION (copy of End with different model)
-- ============================================================
NPCConfig.Beginning = {
	modelName = "Thebeginning",
	spawnName = "BeginningSpawn",
	npcCount = 1,
	
	health = 4000,                  -- Boss health
	walkSpeed = 16,
	aggroRange = 100,
	preferredDistance = 40,
	damage = 10,
	attackCooldown = 2,
	
	idleTime = {1, 2},
	walkTime = {3, 6},
	walkRadius = 100,
	
	animIdle = 78973476418857,
	animWalk = 97383942534616,
	
	animForwardDash = Animations.ForwardDash,
	animLeftDash = Animations.LeftDash,
	animRightDash = Animations.RightDash,
	animFlight = Animations.ForwardFlight,
	
	-- Beginning's custom attacks
	attacks = {
		[1] = {
			type = "melee",
			animation = Animations.DashPunch,
			dashAnimation = Animations.ForwardDash,
			targetDistance = 5,
			dashMinDistance = 5,
			dashMaxDistance = 50,
			animSpeedStart = 0.5,
			animSpeedNormal = 1,
			animSpeedDelay = 0.5,
			effects = {
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
				{ trigger = "event", eventName = "hit", effectName = "MoreHit1", attachment = "Vfx", duration = 2, damage = 35, hitboxAttachment = "Vfx", hitboxDuration = 0.5 },
			},
		},
		[2] = {
			type = "ranged",
			animation = Animations.ChargeMagicAttack,
			pauseAtPercent = 0.98,
			freezeDuration = 3,
			effects = {
				{ trigger = "event", eventName = "Fire", effectName = "GreenBlast", attachment = "Vfx", effectType = "projectile", targetPlayer = true, speed = 80, duration = 5, damage = 32, hitboxAttachment = "Vfx", hitboxDuration = 5 },
			},
		},
		[3] = {
			type = "melee",
			animation = Animations.ComboAndBlast,
			dashAnimation = Animations.ForwardDash,
			targetDistance = 5,
			dashMinDistance = 5,
			dashMaxDistance = 50,
			-- After dashing close, keep following while attacking
			chaseWhileAttacking = true,
			chaseSpeed = 24,
			stopChaseOnEvent = "stop",
			-- Pause and fire beam
			pauseOnEvent = "Fire",
			freezeDuration = 3,
			effects = {
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
				{ trigger = "event", eventName = "Fire", effectName = "Beam2", attachment = "Vfx", targetPlayer = true, duration = 3, damage = 40, hitboxAttachment = "Vfx", hitboxDuration = 3 },
			},
		},
		[4] = {
			type = "melee",
			animation = Animations.GroundFlip,
			isUlt = true,
			noDash = true,
			effects = {
				{ trigger = "event", eventName = "Flip", effectName = "GroundFlip", attachment = "HumanoidRootPart", effectType = "groundSpawn", spawnDistance = 50, duration = 5, damage = 50, hitboxAttachment = "HumanoidRootPart", hitboxDuration = 5 },
				{ trigger = "event", eventName = "Flip", effectName = "GroundFlipEffect", attachment = "HumanoidRootPart", effectType = "groundVFX", spawnDistance = 50, duration = 5 },
			},
		},
	},
}

-- ============================================================
-- WORLD BREAKER NPC CONFIGURATION
-- ============================================================
NPCConfig.WorldBreaker = {
	modelName = "World Breaker",
	spawnName = "World BreakerSpawn",
	npcCount = 1,
	
	health = 8000,                  -- Boss health
	walkSpeed = 16,
	aggroRange = 100,
	preferredDistance = 40,
	damage = 10,
	attackCooldown = 2,
	
	idleTime = {1, 2},
	walkTime = {3, 6},
	walkRadius = 100,
	
	animIdle = 78973476418857,
	animWalk = 97383942534616,
	
	animForwardDash = Animations.ForwardDash,
	animLeftDash = Animations.LeftDash,
	animRightDash = Animations.RightDash,
	animFlight = Animations.ForwardFlight,
	
	attacks = {
		-- Attack 1: Planting (ranged - spawns trees)
		[1] = {
			type = "ranged",
			animation = Animations.Planting,
			animSpeed = 0.5,
			effects = {
				{ trigger = "start", delay = 0.5, effectName = "Trees", attachment = "HumanoidRootPart", effectType = "treeSpawn", spawnDistance = 50, density = 2, spawnDuration = 5, duration = 10, damage = 45, hitboxAttachment = "HumanoidRootPart", hitboxDuration = 5 },
			},
		},
		-- Attack 2: GetOffMe (ranged - beam from BOTH hands)
		[2] = {
			type = "ranged",
			animation = Animations.GetOffMe,
			pauseAtPercent = 0.98,
			freezeDuration = 3,
			effects = {
				-- Beam from right hand (Effect attachment)
				{ trigger = "pause", effectName = "Beam10", attachment = "Effect", targetPlayer = true, duration = 3, damage = 50, hitboxAttachment = "Effect", hitboxDuration = 3 },
				-- Beam from left hand (EffectLeft attachment on left arm)
				{ trigger = "pause", effectName = "Beam10", attachment = "EffectLeft", targetPlayer = true, duration = 3, damage = 50, hitboxAttachment = "EffectLeft", hitboxDuration = 3 },
			},
		},
		-- Attack 3: ScanThenRighHandMagic (ranged with beam)
		[3] = {
			type = "ranged",
			animation = Animations.ScanThenRighHandMagic,
			pauseOnEvent = "beam",
			freezeDuration = 3,
			effects = {
				{ trigger = "event", eventName = "Beam", effectName = "Beam10", attachment = "Effect", targetPlayer = true, duration = 3, damage = 50, hitboxAttachment = "Effect", hitboxDuration = 3 },
			},
		},
		-- Attack 4: DoubleBackFlip (ULT - ranged, beam from Center attachment on right arm)
		[4] = {
			type = "ranged",
			animation = Animations.DoubleBackFlip,
			isUlt = true,
			pauseAtPercent = 0.98,
			freezeDuration = 3,
			effects = {
				{ trigger = "pause", effectName = "Beam9", attachment = "Center", targetPlayer = true, duration = 3, damage = 60, hitboxAttachment = "Center", hitboxDuration = 3 },
			},
		},
	},
}

-- ============================================================
-- THE WEEPING KING NPC CONFIGURATION
-- ============================================================
NPCConfig.TheWeepingKing = {
	modelName = "The Weeping King",
	spawnName = "The weeping KingSpawn",
	npcCount = 1,
	
	health = 10000,                 -- Boss health
	walkSpeed = 16,
	aggroRange = 100,
	preferredDistance = 40,
	damage = 10,
	attackCooldown = 2,
	
	idleTime = {1, 2},
	walkTime = {3, 6},
	walkRadius = 100,
	
	animIdle = 78973476418857,
	animWalk = 97383942534616,
	
	animForwardDash = Animations.ForwardDash,
	animLeftDash = Animations.LeftDash,
	animRightDash = Animations.RightDash,
	animFlight = Animations.ForwardFlight,
	
	attacks = {
		-- Attack 1: FeetStomp (melee)
		[1] = {
			type = "melee",
			animation = Animations.FeetStomp,
			dashAnimation = Animations.ForwardDash,
			targetDistance = 5,
			dashMinDistance = 5,
			dashMaxDistance = 50,
			effects = {
				{ trigger = "event", eventName = "stomp", effectName = "Smash", attachment = "Vfx", effectType = "smash", spawnOnFloor = true, duration = 2, damage = 40, hitboxAttachment = "Vfx", hitboxDuration = 1 },
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
			},
		},
		-- Attack 2: GrabPunchBackickCombo (melee)
		[2] = {
			type = "melee",
			animation = Animations.GrabPunchBackickCombo,
			dashAnimation = Animations.ForwardDash,
			targetDistance = 5,
			dashMinDistance = 5,
			dashMaxDistance = 50,
			effects = {
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
				-- Damage event hits (punches) - Yellow, Orange, Red on Left Arm
				{ trigger = "event", eventName = "Damage", eventOccurrence = 1, effectName = "Hits", effectChild = "Yellow", attachment = "LeftVfx", bodyPart = "Left Arm", effectType = "smash", duration = 1, damage = 30, hitboxAttachment = "LeftVfx", hitboxDuration = 0.5 },
				{ trigger = "event", eventName = "Damage", eventOccurrence = 2, effectName = "Hits", effectChild = "Orange", attachment = "LeftVfx", bodyPart = "Left Arm", effectType = "smash", duration = 1, damage = 32, hitboxAttachment = "LeftVfx", hitboxDuration = 0.5 },
				{ trigger = "event", eventName = "Damage", eventOccurrence = 3, effectName = "Hits", effectChild = "Red", attachment = "LeftVfx", bodyPart = "Left Arm", effectType = "smash", duration = 1, damage = 35, hitboxAttachment = "LeftVfx", hitboxDuration = 0.5 },
				-- Kick event - LightBlue and Pink
				{ trigger = "event", eventName = "Kick", eventOccurrence = 1, effectName = "Hits", effectChild = "LightBlue", attachment = "Vfx", effectType = "smash", duration = 1, damage = 35, hitboxAttachment = "Vfx", hitboxDuration = 0.5 },
				{ trigger = "event", eventName = "Kick", eventOccurrence = 1, effectName = "Hits", effectChild = "Pink", attachment = "Vfx", effectType = "smash", duration = 1, damage = 35, hitboxAttachment = "Vfx", hitboxDuration = 0.5 },
--
			},
		},
		-- Attack 3: BlackFlipGroundSlam (melee)
		[3] = {
			type = "melee",
			animation = Animations.BlackFlipGroundSlam,
			dashAnimation = Animations.ForwardDash,
			repositionDistance = 25,      -- Dash to exactly 25 studs away (toward OR away from player)
			moveToAnimationEnd = true,    -- Move NPC to where animation ends
			effects = {
				{ trigger = "start", effectName = "GroundSlamEffectEnergy", attachment = "Floor", duration = 2 },
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
				-- EleSmash on Smash event
				{ trigger = "event", eventName = "Smash", effectName = "EleSmash", effectChild = "Realistic", attachment = "Vfx", effectType = "smash", emitCount = 3, spawnOnFloor = true, duration = 2, damage = 45, hitboxAttachment = "Vfx", hitboxDuration = 2 },
				{ trigger = "event", eventName = "Smash", effectName = "EleSmash", effectChild = "smoke", attachment = "Vfx", effectType = "smash", emitCount = 1, spawnOnFloor = true, duration = 2 },
				{ trigger = "event", eventName = "Smash", effectName = "EleSmash", effectChild = "elec", attachment = "Vfx", effectType = "smash", enableOnly = true, spawnOnFloor = true, duration = 2 },
				{ trigger = "event", eventName = "Smash", effectName = "EleSmash", effectChild = "elec2", attachment = "Vfx", effectType = "smash", enableOnly = true, spawnOnFloor = true, duration = 2 },
				{ trigger = "event", eventName = "Smash", effectName = "EleSmash", effectChild = "elec3", attachment = "Vfx", effectType = "smash", enableOnly = true, spawnOnFloor = true, duration = 2 },
			},
		},
		-- Attack 4: Smooth1HandedMagic (ULT - ranged)
		[4] = {
			type = "ranged",
			animation = Animations.Smooth1HandedMagic,
			isUlt = true,
			pauseAtPercent = 0.98,
			freezeDuration = 3,
			effects = {
				{ trigger = "pause", effectName = "DarkBlast", effectChild = "MiscEffects", attachment = "Effect", effectType = "projectile", targetPlayer = true, speed = 80, duration = 5, damage = 65, hitboxAttachment = "Effect", hitboxDuration = 5 },
			},
		},
	},
}

-- ============================================================
-- TWO FACE NPC CONFIGURATION (copy of End)
-- ============================================================
NPCConfig.TwoFace = {
	modelName = "TwoFace",
	spawnName = "Two FaceSpawn",
	npcCount = 1,
	
	health = 6000,                  -- Boss health
	walkSpeed = 16,
	aggroRange = 100,
	preferredDistance = 40,
	damage = 10,
	attackCooldown = 2,
	
	idleTime = {1, 2},
	walkTime = {3, 6},
	walkRadius = 100,
	
	animIdle = 78973476418857,
	animWalk = 97383942534616,
	
	animForwardDash = Animations.ForwardDash,
	animLeftDash = Animations.LeftDash,
	animRightDash = Animations.RightDash,
	animFlight = Animations.ForwardFlight,
	
	attacks = {
		[1] = {
			type = "melee",
			animation = Animations.UpperCutFly,
			dashAnimation = Animations.ForwardDash,
			targetDistance = 5,
			dashMinDistance = 5,
			dashMaxDistance = 50,
			effects = {
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
				{ trigger = "start", effectName = "Wb3", attachment = "Effect", damage = 38, hitboxAttachment = "Effect", hitboxDuration = 0.5 },
			},
		},
		[2] = {
			type = "melee",
			animation = Animations.ComboAndFlip,
			dashAnimation = Animations.ForwardDash,
			targetDistance = 0.5,
			dashMinDistance = 0.5,
			dashMaxDistance = 50,
			effects = {
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
				{ trigger = "dash", effectName = "BlackWhite Tornado", attachment = "Vfx", bodyPart = "HumanoidRootPart", lockToPart = true, duration = 3 },
				-- Slide event: WBLightning on right arm Effect attachment (has Attachment and Black children)
				{ trigger = "event", eventName = "slide", effectName = "WBLightning", effectChild = "Attachment", attachment = "Effect", bodyPart = "Right Arm", effectType = "smash", emitCount = 1, duration = 2, damage = 35, hitboxAttachment = "Effect", hitboxDuration = 0.5 },
				{ trigger = "event", eventName = "slide", effectName = "WBLightning", effectChild = "Black", attachment = "Effect", bodyPart = "Right Arm", effectType = "smash", emitCount = 1, duration = 2 },
				-- hitone event: Wb1 on left arm Vfx attachment (has BlackSmoke, MIDDLE/STRIKES, White children)
				{ trigger = "event", eventName = "hitone", effectName = "Wb1", effectChild = "BlackSmoke", attachment = "Vfx", bodyPart = "Left Arm", effectType = "smash", emitCount = 1, duration = 1, damage = 32, hitboxAttachment = "Vfx", hitboxDuration = 0.5 },
				{ trigger = "event", eventName = "hitone", effectName = "Wb1", effectChild = "MIDDLE", attachment = "Vfx", bodyPart = "Left Arm", effectType = "smash", enableOnly = true, duration = 1 },
				{ trigger = "event", eventName = "hitone", effectName = "Wb1", effectChild = "White", attachment = "Vfx", bodyPart = "Left Arm", effectType = "smash", emitCount = 1, duration = 1 },
				-- hittwo event: Wb1 on right hand Effect attachment
				{ trigger = "event", eventName = "hittwo", effectName = "Wb1", effectChild = "BlackSmoke", attachment = "Effect", bodyPart = "Right Arm", effectType = "smash", emitCount = 1, duration = 1, damage = 33, hitboxAttachment = "Effect", hitboxDuration = 0.5 },
				{ trigger = "event", eventName = "hittwo", effectName = "Wb1", effectChild = "MIDDLE", attachment = "Effect", bodyPart = "Right Arm", effectType = "smash", enableOnly = true, duration = 1 },
				{ trigger = "event", eventName = "hittwo", effectName = "Wb1", effectChild = "White", attachment = "Effect", bodyPart = "Right Arm", effectType = "smash", emitCount = 1, duration = 1 },
				-- hitthree event: Wb1 on left arm Vfx attachment
				{ trigger = "event", eventName = "hitthree", effectName = "Wb1", effectChild = "BlackSmoke", attachment = "Vfx", bodyPart = "Left Arm", effectType = "smash", emitCount = 1, duration = 1, damage = 34, hitboxAttachment = "Vfx", hitboxDuration = 0.5 },
				{ trigger = "event", eventName = "hitthree", effectName = "Wb1", effectChild = "MIDDLE", attachment = "Vfx", bodyPart = "Left Arm", effectType = "smash", enableOnly = true, duration = 1 },
				{ trigger = "event", eventName = "hitthree", effectName = "Wb1", effectChild = "White", attachment = "Vfx", bodyPart = "Left Arm", effectType = "smash", emitCount = 1, duration = 1 },
				-- finalslam event: Wb2 on left hand Vfx attachment (has Attachment and Black children)
				{ trigger = "event", eventName = "finalslam", effectName = "Wb2", effectChild = "Attachment", attachment = "Vfx", bodyPart = "Left Arm", effectType = "smash", emitCount = 1, duration = 2, damage = 40, hitboxAttachment = "Vfx", hitboxDuration = 1 },
				{ trigger = "event", eventName = "finalslam", effectName = "Wb2", effectChild = "Black", attachment = "Vfx", bodyPart = "Left Arm", effectType = "smash", emitCount = 1, duration = 2 },
			},
		},
		[3] = {
			type = "melee",
			animation = Animations.SuperKarateCombo,
			noDash = true,
			targetDistance = 5,
			dashMinDistance = 5,
			dashMaxDistance = 50,
			effects = {
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
				-- Damage1 event: Random Wb1-Wb5 on right hand Effect attachment (fires every time)
				{ trigger = "event", eventName = "Damage1", randomEffects = {"Wb1", "Wb2", "Wb3", "Wb4", "Wb5"}, attachment = "Effect", bodyPart = "Right Arm", effectType = "smash", emitCount = 1, scale = 2, duration = 1, damage = 35, hitboxAttachment = "Effect", hitboxDuration = 0.5 },
				-- Damage2 event: Random Wb1-Wb5 on left hand Vfx attachment (fires every time)
				{ trigger = "event", eventName = "Damage2", randomEffects = {"Wb1", "Wb2", "Wb3", "Wb4", "Wb5"}, attachment = "Vfx", bodyPart = "Left Arm", effectType = "smash", emitCount = 1, scale = 2, duration = 1, damage = 36, hitboxAttachment = "Vfx", hitboxDuration = 0.5 },
				-- Damage3 event: Wb6 on left hand Vfx attachment
				{ trigger = "event", eventName = "Damage3", effectName = "Wb6", attachment = "Vfx", bodyPart = "Left Arm", effectType = "smash", emitCount = 1, scale = 2, duration = 1, damage = 38, hitboxAttachment = "Vfx", hitboxDuration = 0.5 },
			},
		},
		[4] = {
			type = "melee",
			animation = Animations.BarrageGroundSlam,
			isUlt = true,
			dashAnimation = Animations.ForwardDash,
			targetDistance = 5,
			dashMinDistance = 5,
			dashMaxDistance = 50,
			effects = {
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
				{ trigger = "start", effectName = "Wb5", attachment = "Vfx", spawnOnFloor = true, damage = 55, hitboxAttachment = "Vfx", hitboxDuration = 3 },
			},
		},
	},
}

-- ============================================================
-- DICE NPC CONFIGURATION
-- ============================================================
NPCConfig.Dice = {
	modelName = "Dice",
	spawnName = "DiceSpawn",
	npcCount = 1,
	
	health = 3000,                  -- Boss health
	walkSpeed = 16,
	aggroRange = 100,
	preferredDistance = 40,
	damage = 10,
	attackCooldown = 2,
	
	idleTime = {1, 2},
	walkTime = {3, 6},
	walkRadius = 100,
	
	animIdle = 78973476418857,
	animWalk = 97383942534616,
	
	animForwardDash = Animations.ForwardDash,
	animLeftDash = Animations.LeftDash,
	animRightDash = Animations.RightDash,
	animFlight = Animations.ForwardFlight,
	
	attacks = {
		-- Attack 1: RightUpSwordSlash (melee)
		[1] = {
			type = "melee",
			animation = Animations.RightUpSwordSlash,
			dashAnimation = Animations.ForwardDash,
			targetDistance = 10,
			dashMinDistance = 5,
			dashMaxDistance = 50,
			effects = {
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
				{ trigger = "start", effectName = "SwordSlash", attachment = "Effect", damage = 28, hitboxAttachment = "Effect", hitboxDuration = 0.5 },
			},
		},
		-- Attack 2: R6SwordSweep (melee)
		[2] = {
			type = "melee",
			animation = Animations.R6SwordSweep,
			dashAnimation = Animations.ForwardDash,
			targetDistance = 10,
			dashMinDistance = 5,
			dashMaxDistance = 50,
			effects = {
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
				{ trigger = "start", effectName = "SwordSweep", attachment = "Effect", damage = 30, hitboxAttachment = "Effect", hitboxDuration = 0.6 },
			},
		},
		-- Attack 3: SwordBackSpin (melee)
		[3] = {
			type = "melee",
			animation = Animations.SwordBackSpin,
			dashAnimation = Animations.ForwardDash,
			targetDistance = 10,
			dashMinDistance = 5,
			dashMaxDistance = 50,
			effects = {
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
				{ trigger = "start", effectName = "SwordSpin", attachment = "Effect", duration = 2, damage = 32, hitboxAttachment = "Effect", hitboxDuration = 1.5 },
			},
		},
		-- Attack 4: SwordComboKick (ULT - melee)
		[4] = {
			type = "melee",
			animation = Animations.SwordComboKick,
			isUlt = true,
			dashAnimation = Animations.ForwardDash,
			targetDistance = 10,
			dashMinDistance = 5,
			dashMaxDistance = 50,
			effects = {
				{ trigger = "dash", effectName = "Trail", attachment = "Trail" },
				{ trigger = "start", effectName = "SwordCombo", attachment = "Effect", damage = 50, hitboxAttachment = "Effect", hitboxDuration = 2 },
			},
		},
	},
}

-- ============================================================
-- TEMPLATE: Copy this for new NPCs
-- ============================================================
--[[
NPCConfig.YourNPCName = {
	modelName = "YourModel",          -- In ReplicatedStorage.Npc
	spawnName = "YourSpawn",          -- In Workspace
	npcCount = 1,
	
	walkSpeed = 16,
	aggroRange = 200,
	preferredDistance = 40,
	damage = 10,
	attackCooldown = 2,
	
	idleTime = {1, 2},
	walkTime = {3, 6},
	walkRadius = 100,
	
	animIdle = 78973476418857,
	animWalk = 97383942534616,
	
	animForwardDash = Animations.ForwardDash,
	
	attacks = {
		[1] = {
			type = "melee",  -- or "ranged"
			animation = Animations.SomeAnimation,
			-- ... add more settings
		},
		-- Add attacks 2, 3, 4 (ult) as needed
	},
}
]]

return NPCConfig
