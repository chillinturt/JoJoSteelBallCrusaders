local PlayerData = {}

PlayerData.DEFAULT_PLAYER_DATA = {
	Cash = 0,
	XP = 0,
	Level = 1,
	AbilityPoints = 0,
	MaxXP = 100,

	-- Powers
	Hero = "",
	Race = "Human",
	Specialty = "",

	-- Upgrades
	UpgradeData = {},

	-- Inventory
	-- inventory is a list of { Name = string, Amount = number }
	Inventory = {},

	-- Quests
	Quests = {}, -- active quests
	CompletedQuests = {}, -- completed ones
}

export type PlayerData = typeof(PlayerData.DEFAULT_PLAYER_DATA)

return PlayerData
