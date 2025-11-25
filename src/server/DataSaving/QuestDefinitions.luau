-- QuestDefinitions Module
local QuestDefinitions = {}

---------------------------------------------------------------------
-- 1. TALK TO GIORNO (Quest 1)
---------------------------------------------------------------------
QuestDefinitions.TalkToGiorno1 = {
	Name = "Talk to Giorno",
	Description = "Find Giorno and talk to him.",

	Giver = "Giorno",

	Objectives = {
		{ Type = "Talk", Target = "Giorno", Completed = false },
	},

	RewardXP = 50,
	TurnInNpc = nil,
	RewardItems = { "StandArrow" },
	RewardCash = 100,
	NextQuest = { "TalkToJotaro1" },

	Dialog = {
		Offer = {
			"Hey there… I’ve been keeping an eye on the city, and things are getting rough.",
			"Dangerous thugs have been showing up everywhere. Even I can’t handle all of them alone.",
			"You should go talk to Jotaro. He knows what's going on — and he’ll know what you should do next.",
			"And here… take this Stand Arrow. You’re going to need it.",
			"Hit Shift to dash! You'll get there faster that way.",
		},

		InProgress = {
			"This never triggers",
		},

		TurnIn = nil, -- No turn-in NPC
		Completed = {
			"You’ve already spoken to me. Jotaro is waiting.",
			"Hit Shift to dash! You'll get there faster that way.",
		},
	},
}

---------------------------------------------------------------------
-- 2. TALK TO JOTARO (Quest 2)
---------------------------------------------------------------------
QuestDefinitions.TalkToJotaro1 = {
	Name = "Talk to Jotaro",
	Description = "Find Jotaro and talk to him.",

	Giver = "Jotaro",

	Objectives = {
		{ Type = "Talk", Target = "Jotaro", Completed = false },
	},

	RewardXP = 50,
	TurnInNpc = nil,

	NextQuest = { "DefeatThugs1", "TalkToCrimeBoss" },

	Dialog = {
		Offer = {
			"So, Giorno sent you? Good… we’ve got a problem on our hands.",
			"The thugs we’ve seen around the city aren’t just random punks — someone is supplying them.",
			"I have a strong suspicion it’s the RO Bank, but I need proof.",
			"Head to the motor store and take out a few thugs. See if they’re carrying anything unusual.",
			"Dash and then hold CTRL to slide down this hill!",
		},

		InProgress = {
			"The thugs at the motor store should have something on them… if my hunch is right.",
		},

		TurnIn = {
			"The thugs at the motor store should have something on them… if my hunch is right.",
			"Dash and then hold CTRL to slide down this hill!",
		},

		Completed = {
			"You already spoke to me. Stay sharp.",
		},
	},
}

---------------------------------------------------------------------
-- 3. TALK TO THE CRIME BOSS (Quest 3)
---------------------------------------------------------------------
QuestDefinitions.TalkToCrimeBoss = {
	Name = "Talk to the Crime Boss",

	Giver = "CrimeBoss",

	Objectives = {
		{ Type = "Talk", Target = "CrimeBoss", Completed = false },
	},

	RewardXP = 50,
	NextQuest = "DefeatCriminalStandUsers",
	TurnInNpc = nil,

	Dialog = {
		Offer = {
			"So you’re the one who’s been taking out my men… bold.",
			"Yeah, we’re working with the RO Bank. They pay us, we cause chaos — simple business.",
			"But if you’re here looking for a fight… you’re gonna get one.",
		},

		InProgress = {
			"You’re either brave or stupid, kid. Either way… I respect it.",
		},

		TurnIn = {
			"Hmph. Fine. Take what you came for. Doesn’t matter.",
			"But you’ve painted a target on your back. RO Bank doesn't forgive anything.",
		},

		Completed = {
			"Get out of my sight before I change my mind.",
		},
	},
}

---------------------------------------------------------------------
-- 4. DEFEAT THUGS (Quest 4)
---------------------------------------------------------------------
QuestDefinitions.DefeatThugs1 = {
	Name = "Stop the Thugs",
	Description = "Defeat 5 thugs in the alley.",
	NextQuest = "RobROBank",
	RewardXP = 100,
	RewardCash = 100,

	Giver = "Jotaro",

	Objectives = {
		{ Type = "Defeat", Target = "Thug", Required = 5, Progress = 0, Completed = false },
	},

	TurnInNpc = "Jotaro",

	Dialog = {
		Offer = {
			"The thugs around the motor store have what we need — take down at least five.",
		},

		InProgress = {
			"Keep going. Take out a few more thugs — they should have what we’re looking for.",
		},

		TurnIn = {
			"That’s exactly what we needed. Nice work.",
			"If we’re right about the RO Bank… there’s only one way to expose them.",
			"Break into the vault. Get the evidence.",
			"Smash the doors blocking your way.",
			"I'm counting on you. You seem to be quite... reliable.",
		},

		Completed = {
			"You’ve already cleaned helped clean up the city. Good job.",
		},
	},
}

---------------------------------------------------------------------
-- 5. DEFEAT CRIMINAL STAND USERS (Quest 5)
---------------------------------------------------------------------
QuestDefinitions.DefeatCriminalStandUsers = {
	Name = "Defeat Criminal Stand Users",

	Giver = "CrimeBoss", -- or Jotaro, depends on story flow

	Objectives = {
		{ Type = "Defeat", Target = "Criminal Stand User", Required = 3, Progress = 0, Completed = false },
	},

	NextQuest = { "TalkToDioPB1" },

	RewardXP = 100,
	TurnInNpc = { "CrimeBoss" },

	Dialog = {
		Offer = {
			"These aren’t normal criminals… these ones have Stands.",
			"Defeating them won’t be easy — you're going down!",
		},

		InProgress = {
			"Those Stand Users are dangerous. Be careful.",
		},

		TurnIn = {
			"You defeated them?!? Impossible!",
			"Don't hurt me man! I was just following orders!",
			"Go talk to my boss across the street, he'll give you answers!",
		},

		Completed = {
			"My boss is in that building down the road. In the opposite direction of the treehouse.",
			"The building next to the two evergreen trees. If you hear creepy music, you're going the right way.",
		},
	},
}

---------------------------------------------------------------------
-- 6. ROB RO BANK (Quest 6)
---------------------------------------------------------------------
QuestDefinitions.RobROBank = {
	Name = "Rob the RO Bank",

	Giver = "Jotaro", -- or an NPC who instructs the robbery

	Objectives = {
		{ Type = "Interact", Target = "ROBankVault", Required = 1, Progress = 0, Completed = false },
	},

	RewardXP = 150,
	RewardCash = 20000,
	TurnInNpc = { "Jotaro" },
	NextQuest = "TalkToBaronZepelli1",

	Dialog = {
		Offer = {
			"If we’re right about the RO Bank… there’s only one way to expose them.",
			"Break into the vault. Get the evidence.",
			"Smash the door and get into that vault.",
		},

		InProgress = {
			"The vault should be inside the main lobby. Stay quiet… or don’t.",
			"Smash the door and get into that vault.",
		},

		TurnIn = {
			"You actually pulled it off… incredible.",
			"This is the proof we needed. The RO Bank’s corruption ends here.",
			"[This is the end of this branch of the main questline]",
			"[Great Job! More content is coming very soon! (written 21st of Nov 2025)]",
		},

		Completed = {
			"You’ve already robbed the bank. Stay low — they’re looking for you.",
		},
	},
}

---------------------------------------------------------------------
-- 7. TALK TO DIOPB (Quest 7)
---------------------------------------------------------------------
QuestDefinitions.TalkToDioPB1 = {
	Name = "Talk to Dio (Phantom Blood)",
	Description = "Find DioPB and speak with him.",

	Giver = "DioPB",

	Objectives = {
		{ Type = "Talk", Target = "DioPB", Completed = false },
	},

	-- No turn-in NPC → completes on first talk
	TurnInNpc = nil,

	NextQuest = { "DefeatVampires1" },

	Dialog = {
		Offer = {
			"So… you’ve crushed the Criminal Stand Users. Impressive.",
			"But raw strength means nothing without true resolve.",
			"If you wish to stand among the immortals… prove it.",
			"Hunt these wakling vampires in this very room. Survive… and you may earn my respect.",
		},

		InProgress = {
			"Prove your worth. Destroy the vampires.",
		},

		Completed = {
			"You've already spoken to me… Now show me your strength.",
		},
	},
}

---------------------------------------------------------------------
-- 8. DEFEAT VAMPIRES (Quest 8)
---------------------------------------------------------------------
QuestDefinitions.DefeatVampires1 = {
	Name = "Prove Yourself to Dio",
	Description = "Defeat 3 vampires to prove your strength to DioPB.",

	Giver = "DioPB",

	Objectives = {
		{ Type = "Defeat", Target = "Vampire", Required = 3, Progress = 0, Completed = false },
	},

	RewardXP = 100,
	RewardCash = 20000,
	NextQuest = "CheckVampirismSpecialty",

	TurnInNpc = "DioPB",
	RewardItems = { "Stone Mask" },

	Dialog = {
		Offer = {
			"The true test begins now. Vampires are far stronger than any thug you’ve faced.",
			"Defeat three of them… if you can.",
		},

		InProgress = {
			"Do not falter. Show me you are worthy.",
		},

		TurnIn = {
			"You survived… and triumphed.",
			"Perhaps you truly are worthy of the path of the immortal.",
			"Use this Stone Mask to become a Vampire!",
			"Then, return to me and talk to the Vampire Lady to learn your true potential...",
		},

		Completed = {
			"You’ve already proven yourself… for now.",
		},
	},
}

---------------------------------------------------------------------
-- 9. Advance your vampirism (Quest 9)
---------------------------------------------------------------------

QuestDefinitions.CheckVampirismSpecialty = {
	Name = "Prove Your Vampirism",
	Description = "Talk to DioPB once you have unlocked Vampirism.",

	Giver = "DioPB",

	Objectives = {
		{
			Type = "Specialty",
			Target = "Vampirism", -- Required specialty name
			Completed = false,
		},
	},

	RewardXP = 150,
	RewardItems = {},

	TurnInNPC = "DioPB",

	--NextQuest = { "SomeOtherQuest" },

	Dialog = {
		Offer = {
			"You seek power? Prove you have embraced the darkness.",
			"Talk to the Vampire Lady to advance your vampirism.",
		},

		InProgress = {
			"You do not yet possess the power of Vampirism. Return when your blood has changed.",
		},

		TurnIn = {
			"Ahh… yes. The taste of eternity flows in you now. Your transformation is complete.",
		},

		Completed = {
			"You have already proven your Vampirism.",
		},
	},
}

---------------------------------------------------------------------
-- 10. TALK TO BARON ZEPELLI (Quest 10)
---------------------------------------------------------------------
QuestDefinitions.TalkToBaronZepelli1 = {
	Name = "Talk to Baron Zepelli",
	Description = "Find Baron Zepelli and speak with him.",

	Giver = "BaronZepelli",

	Objectives = {
		{ Type = "Talk", Target = "BaronZepelli", Completed = false },
	},

	RewardXP = 75,
	TurnInNpc = nil, -- Talking to him completes the quest
	RewardItems = {},
	RewardCash = 150,
	NextQuest = nil, -- Or set to your next quest when ready

	Dialog = {
		Offer = {
			"Ah… you there. I sensed your presence approaching.",
			"My name is Baron Zepelli. I’ve studied the ancient art of Hamon for many years.",
			"There is much potential within you — potential you may not yet understand.",
			"Speak with me a moment. I have something important to share.",
		},

		InProgress = {
			"We’re already speaking… focus your breathing.",
		},

		TurnIn = nil,

		Completed = {
			"Our conversation is finished. Let your Hamon flow with purpose.",
		},
	},
}

QuestDefinitions.DefeatThugsRepeatable = {
	Name = "Stop the Thugs",
	Description = "Defeat 5 thugs at the Motor Store.",

	Repeatable = true, -- 🔹 NEW

	Giver = "Josuke",
	RewardCash = 100,
	RewardXP = 100,

	Objectives = {
		{ Type = "Defeat", Target = "Thug", Required = 5, Progress = 0, Completed = false },
	},

	TurnInNpc = "Josuke",

	Dialog = {
		Offer = {
			"These Thugs are crazy! Take out 5 of them for me and I'll give you a reward.",
		},

		InProgress = {
			"Keep going. Take out a few more thugs — I think I heard one make fun of my hair!",
		},

		TurnIn = {
			"Nice work. Let’s keep the alley clean.",
		},

		Completed = {
			"Ready for more work? These thugs always come back!",
		},
	},
}

return QuestDefinitions
