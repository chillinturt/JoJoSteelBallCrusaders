local PlayerData = {}

PlayerData.DEFAULT_PLAYER_DATA = {
	Slots = {},
	CurrentSlot = "Slot1",

	Cash = 0,
	XP = 0,
	Level = 1,
	TalentPoints = 0,
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

	UnlockedAbilities = {
		[1] = false,
		[2] = false,
		[3] = false,
		[4] = false,
	},

	AbilityPoints = 0,

	-- Developer product XP boost: unix timestamp when the boost expires.
	-- Account-wide (not per-slot) and keeps counting down while offline.
	XPBoostExpiry = 0,

	-- Set of MarketplaceService PurchaseId -> true, used to make
	-- developer product grants idempotent across ProcessReceipt retries.
	PurchaseHistory = {},
}

export type PlayerData = typeof(PlayerData.DEFAULT_PLAYER_DATA)

return PlayerData
