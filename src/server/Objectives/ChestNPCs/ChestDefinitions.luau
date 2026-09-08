local ChestDefinitions = {

	Common = {
		RespawnTime = 60, -- seconds before this spawn point can roll another chest
		PickupRadius = 6, -- how close a player must be to collect it
		SpawnRadius = 0, -- random offset radius around the spawn point

		CashReward = { Min = 50, Max = 300 },

		ItemRewards = {
			{ Name = "StandArrow", Amount = 1, Chance = 0.08 },
			{ Name = "Rokakaka", Amount = 1, Chance = 0.05 },
		},
	},

	Uncommon = {
		RespawnTime = 60, -- seconds before this spawn point can roll another chest
		PickupRadius = 6, -- how close a player must be to collect it
		SpawnRadius = 0, -- random offset radius around the spawn point

		CashReward = { Min = 100, Max = 600 },

		ItemRewards = {
			{ Name = "StandArrow", Amount = 1, Chance = 0.1 },
			{ Name = "Rokakaka", Amount = 1, Chance = 0.08 },
			{ Name = "StoneMask", Amount = 1, Chance = 0.01 },
		},
	},

	Rare = {
		RespawnTime = 60,
		PickupRadius = 6,
		SpawnRadius = 0,

		CashReward = { Min = 120, Max = 1000 },

		ItemRewards = {
			{ Name = "StandArrow", Amount = 1, Chance = 0.16 },
			{ Name = "Rokakaka", Amount = 1, Chance = 0.12 },
			{ Name = "BlueRokakaka", Amount = 1, Chance = 0.01 },
		},
	},

	Mythic = {
		RespawnTime = 60,
		PickupRadius = 6,
		SpawnRadius = 0,

		CashReward = { Min = 400, Max = 2000 },

		ItemRewards = {
			{ Name = "StandArrow", Amount = 1, Chance = 0.3 },
			{ Name = "Rokakaka", Amount = 1, Chance = 0.2 },
			{ Name = "StoneMask", Amount = 1, Chance = 0.01 },
			{ Name = "BlueRokakaka", Amount = 1, Chance = 0.02 },
			{ Name = "PurpleRokakaka", Amount = 1, Chance = 0.01 },
		},
	},

	Legendary = {
		RespawnTime = 60,
		PickupRadius = 6,
		SpawnRadius = 0,

		CashReward = { Min = 800, Max = 4000 },

		ItemRewards = {
			{ Name = "StandArrow", Amount = 1, Chance = 0.45 },
			{ Name = "Rokakaka", Amount = 1, Chance = 0.45 },
			{ Name = "BlueRokakaka", Amount = 1, Chance = 0.03 },
			{ Name = "StoneMask", Amount = 1, Chance = 0.02 },
			{ Name = "PurpleRokakaka", Amount = 1, Chance = 0.05 },
		},
	},
}

return ChestDefinitions
