-- Keyed by the name of the zone folder inside workspace.ChestZones
local ChestZoneDefinitions = {

	StarterIslandChests = {
		MaxChests = 5, -- max chests allowed to be active at once in this zone
		ChestTypes = { "Common", "Common", "Common", "Uncommon" }, -- randomly chosen from this list when a chest spawns. weighted by repetition
	},

	JungleChests = {
		MaxChests = 8,
		ChestTypes = { "Common", "Common", "Uncommon", "Uncommon", "Rare" },
	},

	PirateChests = {
		MaxChests = 8,
		ChestTypes = { "Common", "Uncommon", "Uncommon", "Rare" },
	},

	DesertChests = {
		MaxChests = 8,
		ChestTypes = { "Common", "Uncommon", "Uncommon", "Rare", "Rare", "Mythic" },
	},

	SnowChests = {
		MaxChests = 8,
		ChestTypes = { "Uncommon", "Rare", "Rare", "Mythic" },
	},

	VolcanoChests = {
		MaxChests = 8,
		ChestTypes = { "Rare", "Rare", "Rare", "Mythic", "Legendary" },
	},

	MiddleChests = {
		MaxChests = 8,
		ChestTypes = { "Mythic", "Mythic", "Legendary" },
	},

	SkyChests = {
		MaxChests = 8,
		ChestTypes = { "Mythic", "Legendary" },
	},
}

return ChestZoneDefinitions
