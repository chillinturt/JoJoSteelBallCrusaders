-- PlayerProfile.lua
local PlayerProfile = {}

function PlayerProfile.New()
	return {
		Slots = {},
		CurrentSlot = "Slot1",

		Inventory = {},
		Hero = "None",
		Specialty = "None",
		Race = "Human",
		XP = 0,
		Level = 1,
		TalentPoints = 0,
		MaxXP = 100,
		Cash = 0,
		Quests = { "TalkToGiorno1" },
		CompletedQuests = {},
		UpgradeData = {},

		UnlockedAbilities = {
			[1] = false,
			[2] = false,
			[3] = false,
			[4] = false,
		},

		AbilityPoints = 0,
	}
end

return PlayerProfile
