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
		AbilityPoints = 0,
		MaxXP = 100,
		Cash = 0,
		Quests = { "TalkToGiorno1" },
		CompletedQuests = {},
		UpgradeData = {},
	}
end

return PlayerProfile
