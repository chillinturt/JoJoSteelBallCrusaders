-- QuestDefinitions Module
local QuestDefinitions = {}

QuestDefinitions.TalkToGiorno1 = {
	Name = "Talk to Giorno",
	Description = "Find Giorno and talk to him.",
	Objectives = {
		{ Type = "Talk", Target = "Giorno", Completed = false },
	},
	Completed = false,
}

QuestDefinitions.TalkToJotaro1 = {
	Name = "Talk to Jotaro",
	Description = "Find Jotaro and talk to him.",
	Objectives = {
		{ Type = "Talk", Target = "Jotaro", Completed = false },
	},
	Completed = false,
	NextQuest = { "DefeatThugs1", "TalkToCrimeBoss" }, -- chain
	TurnInNpc = "Jotaro",
}

QuestDefinitions.TalkToCrimeBoss = {
	Name = "Talk to the Crime Boss",
	Objectives = {
		{ Type = "Talk", Target = "CrimeBoss", Completed = false },
	},
	RewardXP = 50,
	RewardItems = {},
	Completed = false,
	NextQuest = "DefeatCriminalStandUsers",
	TurnInNpc = "CrimeBoss",
}

QuestDefinitions.DefeatThugs1 = {
	Name = "Stop the Thugs",
	Description = "Defeat 5 thugs in the alley.",
	Objectives = {
		{ Type = "Defeat", Target = "Thug", Required = 5, Progress = 0, Completed = false },
	},
	Completed = false,
	TurnInNpc = "Jotaro", -- ✅ Must talk to Jotaro to finish
}

QuestDefinitions.DefeatCriminalStandUsers = {
	Name = "Defeat Criminal Stand Users",
	Objectives = {
		{ Type = "Defeat", Target = "Criminal Stand User", Required = 3, Progress = 0, Completed = false },
	},
	RewardXP = 100,
	RewardItems = {}, -- could add arrows, cash, etc.
	Completed = false,
	TurnInNpc = { "Jotaro", "CrimeBoss" }, -- ✅ Must talk to Jotaro to finish
}

RobROBank = {
	Title = "Rob the ROBank",
	Objectives = {
		{ Type = "Interact", Target = "ROBankVault", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 150,
	RewardItems = { "CashBundle" },
	Completed = false,
}

-- Add more quests here as needed

return QuestDefinitions
