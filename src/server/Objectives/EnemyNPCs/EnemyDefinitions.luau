local EnemyDefinitions = {

	Thug = {
		RespawnTime = 18,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	Vampire = {
		RespawnTime = 30,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	Bandit = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	Brute = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	DesertBandit = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	Gorilla = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	IceCaptain = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	LavaGolem = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	BlueSailor = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	Monkey = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	Pirate = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	StoneGolem = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	SnowBandit = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	SkyFighter = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	SkyBandit = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	RedSailor = {
		RespawnTime = 10,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	DIO = {
		RespawnTime = 180,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 1,
	},

	CriminalStandUser = {
		RespawnTime = 25,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 1.4,
	},

	AvdolFighter = {
		RespawnTime = 25,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 1.5,
	},

	Diavolo = {
		RespawnTime = 25,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 1.2,
	},

	Giorno = {
		RespawnTime = 25,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 1.1,
	},

	JotaroPart3 = {
		RespawnTime = 25,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 1.4,
	},

	KakyoinNoriaki = {
		RespawnTime = 25,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 2,
	},

	KiraYoshikage = {
		RespawnTime = 25,
		MaxDistance = 250,
		SpawnRadius = 5,

		ActivationRadius = 1500,

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	OkuyasuNijimura = {
		RespawnTime = 25, -- seconds before respawning
		MaxDistance = 250, -- maximum allowed distance from spawn before reset
		SpawnRadius = 5,

		ActivationRadius = 1500,
		-- random offset radius around the spawn

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 1.7,
	},

	RohanKishibe = {
		RespawnTime = 25, -- seconds before respawning
		MaxDistance = 250, -- maximum allowed distance from spawn before reset
		SpawnRadius = 5,

		ActivationRadius = 1500,
		-- random offset radius around the spawn

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 1.7,
	},

	CorruptCop = {
		RespawnTime = 18, -- seconds before respawning
		MaxDistance = 250, -- maximum allowed distance from spawn before reset
		SpawnRadius = 5,

		ActivationRadius = 1500,
		-- random offset radius around the spawn

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	EliteVampire = {
		RespawnTime = 18, -- seconds before respawning
		MaxDistance = 250, -- maximum allowed distance from spawn before reset
		SpawnRadius = 5,

		ActivationRadius = 1500,
		-- random offset radius around the spawn

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	EscapedConvict = {
		RespawnTime = 18, -- seconds before respawning
		MaxDistance = 250, -- maximum allowed distance from spawn before reset
		SpawnRadius = 5,

		ActivationRadius = 1500,
		-- random offset radius around the spawn

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},

	HamonUser = {
		RespawnTime = 25, -- seconds before respawning
		MaxDistance = 160, -- maximum allowed distance from spawn before reset
		SpawnRadius = 5,

		ActivationRadius = 1500,
		-- random offset radius around the spawn

		AGGRO_RADIUS = 30,
		PASSIVE_CHASE_RADIUS = 20,
		COMBAT_CHASE_RADIUS = 150,
		LEASH_DISTANCE = 200,
		RETURN_THRESHOLD = 5,
		REPATH_DISTANCE = 8,
		MAX_VISION_DISTANCE = 100,
		CHASE_SPEED = 14,
		WALK_SPEED = 10,
		ATTACK_INTERVAL = 0.4,
	},
}

return EnemyDefinitions
