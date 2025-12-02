-- PlayerProfile.lua
local PlayerProfile = {}

function PlayerProfile.New()
	return {
		Inventory = {},
		Hero = "",
		Specialty = "",
		Race = "Human",
		XP = 0,
		Level = 1,
		AbilityPoints = 0,
		MaxXP = 100,
		Cash = 0,
		Quests = {},
		CompletedQuests = {},
		UpgradeData = {},
	}
end

return PlayerProfile
