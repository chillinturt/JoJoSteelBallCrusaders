local PlayerData = {}

PlayerData.DEFAULT_PLAYER_DATA = {
	Slots = {},
	CurrentSlot = "Slot1",

	Cash = 0,
	XP = 0,
	Level = 1,
	AbilityPoints = 0,
	MaxXP = 100,

	-- Powers
	Hero = "None",
	Race = "Human",
	Specialty = "None",

	-- Upgrades
	UpgradeData = {},

	-- Inventory
	-- inventory is a list of { Name = string, Amount = number }
	Inventory = {},

	-- Quests
	Quests = {}, -- active quests
	CompletedQuests = {}, -- completed ones

	CharacterUpgrades = {},

	DailyCodes = {
		LastReset = "",
		Redeemed = {},
	},
}

export type PlayerData = typeof(PlayerData.DEFAULT_PLAYER_DATA)

return PlayerData
