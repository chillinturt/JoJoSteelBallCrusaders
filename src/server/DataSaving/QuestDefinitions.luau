-- QuestDefinitions Module
local QuestDefinitions = {}

---------------------------------------------------------------------
-- 1. TALK TO GIORNO (Quest 1)
---------------------------------------------------------------------
QuestDefinitions.TalkToGiorno1 = {
	Name = "Talk to Giorno",
	Description = "Find Giorno and talk to him.",

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
			"And here… take this STAND ARROW. Open your inventory to use the ARROW! (bottom right menu button)",
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

	Objectives = {
		{ Type = "Talk", Target = "CrimeBoss", Completed = false },
	},

	RewardXP = 100,
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
	RewardXP = 300,
	RewardCash = 100,

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

	--Giver = "CrimeBoss",

	Objectives = {
		{ Type = "Defeat", Target = "Criminal Stand User", Required = 3, Progress = 0, Completed = false },
	},

	NextQuest = { "TalkToDioPB1" },

	RewardXP = 500,
	TurnInNpc = "CrimeBoss",

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

	RewardXP = 500,
	RewardCash = 20000,
	TurnInNpc = "Jotaro",
	NextQuest = "TalkToSpeedwagon1",

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

	RewardXP = 500,

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

	--Giver = "DioPB",

	Objectives = {
		{ Type = "Defeat", Target = "Vampire", Required = 3, Progress = 0, Completed = false },
	},

	RewardXP = 700,
	RewardCash = 20000,
	NextQuest = "CheckVampirismSpecialty",

	TurnInNpc = "DioPB",
	RewardItems = { "StoneMask" },

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
			Type = "CheckPowers",
			Target = "Specialty", -- Required specialty name
			Value = "Vampirism",
			Completed = false,
		},
	},

	RewardXP = 1000,
	RewardItems = {},
	TurnInNPC = "DioPB",
	NextQuest = { "DefeatAvdol1" },

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

QuestDefinitions.DefeatPlayers1 = {
	Name = "Hunt for players",
	Description = "Defeat 3 players to prove your strength to DioPB.",

	Objectives = {
		{ Type = "Defeat", Target = "Player", Required = 3, Progress = 0, Completed = false },
	},

	RewardXP = 500,
	RewardCash = 500,
	NextQuest = nil,

	TurnInNpc = nil,

	Dialog = {
		Offer = {
			"Now you're ready to battle anyone! Use your new powers to slay other players!",
			"Talk to the Vampire Lady when you're done.",
		},

		InProgress = {
			"Do not falter. Show me you are worthy.",
		},

		TurnIn = {
			"You survived… and triumphed.",
		},

		Completed = {
			"You’ve already proven yourself… for now.",
		},
	},
}

---------------------------------------------------------------------
-- 10. TALK TO BARON ZEPELLI (Quest 10)
---------------------------------------------------------------------
---------------------------------------------------------------------
-- TALK TO SPEEDWAGON (Refactored Quest)
---------------------------------------------------------------------
QuestDefinitions.TalkToSpeedwagon1 = {
	Name = "Talk to Speedwagon",
	Description = "Find Speedwagon and speak with him.",
	Giver = "Speedwagon",
	Objectives = {
		{ Type = "Talk", Target = "Speedwagon", Completed = false },
	},
	RewardXP = 400,
	TurnInNpc = "Speedwagon", -- Talking to him completes the quest
	RewardItems = {},
	RewardCash = 150,
	NextQuest = "CheckHamonSpecialty1", -- Or set to your next quest when ready
	Dialog = {
		Offer = {
			"Oi, you there! I saw ya takin' down those blokes from a mile away!",
			"Name's Robert E. O. Speedwagon – ex-thug turned Joestar ally.",
			"You've got the fire of a proper fighter. Joestars could use someone like you.",
			"Stick around, chap. I've got the lowdown on vampires and worse lurkin' about.",
			"You'll need the ripple to defeat them! Talk to Baron Zeppeli to optain Hamon!",
		},
		InProgress = {
			"We're chattin' now, ain't we? Keep yer eyes peeled!",
		},
		TurnIn = nil,
		Completed = {
			"Right-o! You're in the fold now. Head out and smash those undead scum.",
			"Watch yer back – and give 'em hell for the Joestars!",
		},
	},
}

QuestDefinitions.CheckHamonSpecialty1 = {
	Name = "Awaken Your Hamon",
	Description = "Return to Baron Zeppeli once you've unlocked the Hamon specialty.",
	Giver = "Speedwagon",
	Objectives = {
		{
			Type = "CheckPowers",
			Target = "Specialty",
			Value = "Hamon",
			Completed = false,
		},
	},
	RewardXP = 1200,
	RewardCash = 300,
	TurnInNpc = "Speedwagon",
	NextQuest = { "DefeatVampires2" },
	Dialog = {
		Offer = {
			"To proceed, you must fully awaken your Hamon. Talk to Baron Zeppeli to learn the breathing technique.",
			"Return when the ripple courses through your veins.",
		},
		InProgress = {
			"Your Hamon is not yet awakened. Focus and try again.",
		},
		TurnIn = {
			"Yes! The ripple is strong in you now.",
			"Use this power wisely – it's a weapon against the darkness.",
			"Now, test it against those corrupted by evil Stands.",
		},
		Completed = {
			"Your Hamon is unlocked. Carry the legacy forward.",
		},
	},
}

QuestDefinitions.DefeatVampires2 = {
	Name = "Prove Your Resolve",
	Description = "Defeat 5 Vampires lurking near the training grounds to show Baron Zeppeli your determination.",
	Giver = "Speedwagon",
	Objectives = {
		{ Type = "Defeat", Target = "Vampire", Required = 5, Progress = 0, Completed = false },
	},
	RewardXP = 2500,
	RewardCash = 200,
	TurnInNpc = nil,
	NextQuest = "DefeatKiraYoshikage1",
	Dialog = {
		Offer = {
			"To master Hamon, you must first prove your resolve against the undead.",
			"Defeat 5 vampires in the nearby ruins. Only then can we begin your training.",
			"Remember, control your breathing – it's the key to everything.",
		},
		InProgress = {
			"The vampires won't wait. Focus your energy and strike true.",
		},
		TurnIn = {
			"Impressive! You've shown the fire in your spirit.",
			"Now, let's harness that with proper Hamon technique.",
			"Head to the sacred fountain and perform the breathing exercise.",
		},
		Completed = {
			"You've cleared the vampires... for now. The path of Hamon awaits.",
		},
	},
}

QuestDefinitions.DefeatKiraYoshikage1 = {
	Name = "Defeat Kira Yoshikage",
	Description = "Defeat Kira Yoshikage and his explosive Stand, Killer Queen.",
	Objectives = {
		{ Type = "Defeat", Target = "KiraYoshikage", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 5000,
	RewardCash = 600,
	TurnInNpc = nil, -- Auto-completes on defeat
	NextQuest = "DefeatDiavolo1", -- Leads directly into Diavolo quest
	Dialog = {
		Offer = {
			"So you believe your power is sufficient to challenge the elite?",
			"Very well… Kira Yoshikage hides among the quiet lives, his Killer Queen turns all to bombs.",
			"Seek him out and defeat him. I sense that he is at the 24/7 Supermarket right now...",
			"Prove to me that you are worthy of standing in my presence.",
			"Do not disappoint me...",
		},
		InProgress = {
			"Kira's bombs erase all traces. Detonate his facade before he collects another hand!",
			"Return only when you have tasted victory.",
		},
		-- No TurnIn dialog (auto-complete)
		Completed = {
			"You have returned victorious... Impressive.",
			"Kira is no weakling, yet you felled him. Your power grows.",
			"A greater shadow looms – Diavolo awaits your blade.",
		},
	},
}

---------------------------------------------------------------------
-- DEFEAT DIAVOLO (Follow-up Quest)
---------------------------------------------------------------------
QuestDefinitions.DefeatDiavolo1 = {
	Name = "Defeat Diavolo",
	Description = "Defeat Diavolo, the boss of Passione, and his time-erasing King Crimson.",
	Objectives = {
		{ Type = "Defeat", Target = "Diavolo", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 20000,
	RewardCash = 900,
	TurnInNpc = nil, -- Auto-completes on defeat
	NextQuest = "TalkToEmporio1", -- End of this branch or link to more later
	Dialog = {
		Offer = {
			"Diavolo rules from the shadows, his King Crimson erases time itself.",
			"No secret can hide from you now. Hunt him down.",
			"Crush his erased fate. Leave no epoch unscarred.",
			"End him, and the path to true dominion clears.",
		},
		InProgress = {
			"King Crimson's skips are illusions. Predict and strike through the void!",
			"His arrows point to nothing – make yours fatal.",
		},
		-- No TurnIn dialog (auto-complete)
		Completed = {
			"Diavolo's time has ended... Magnificent.",
			"Passione crumbles without its boss. Eternity bends to the strong.",
			"Your legend swells. More foes await in the darkness.",
		},
	},
}

QuestDefinitions.TalkToEmporio1 = {
	Name = "Talk to Emporio",
	Description = "Find Emporio and speak with him.",
	Giver = "Emporio",
	Objectives = {
		{ Type = "Talk", Target = "Emporio", Completed = false },
	},
	RewardXP = 10000,
	TurnInNpc = nil, -- Auto-completes on talk
	RewardItems = {},
	RewardCash = 150,
	NextQuest = "DefeatEscapedConvicts1", -- Leads to defeating convicts
	Dialog = {
		Offer = {
			"H-Hi... I'm Emporio. Please, you have to help!",
			"Jolyne-san is locked up in prison... but these escaped convicts are everywhere!",
			"They're too dangerous. We can't break her out until the area is clear.",
			"Please defeat 8 of them first. I'll be hiding nearby!",
			"(Convicts quest will release soon)",
		},
		InProgress = {
			"This never triggers",
		},
		TurnIn = nil,
		Completed = {
			"Thank you for listening... Now go stop those convicts!",
			"Jolyne-san's counting on us!",
			"(Convicts quest will release soon)",
		},
	},
}

---------------------------------------------------------------------
-- DEFEAT ESCAPED CONVICTS (Follow-up Quest)
---------------------------------------------------------------------
QuestDefinitions.DefeatEscapedConvicts1 = {
	Name = "Clear the Escaped Convicts",
	Description = "Defeat 8 escaped convicts to secure the area for Jolyne's breakout.",
	Giver = "Emporio",
	Objectives = {
		{ Type = "Defeat", Target = "EscapedConvict", Required = 8, Progress = 0, Completed = false },
	},
	RewardXP = 15000,
	RewardCash = 400,
	TurnInNpc = nil, -- Auto-completes on defeating the 8th convict
	NextQuest = nil, -- End of this segment or link to Jolyne breakout quest later
	Dialog = {
		Offer = {
			"The convicts are armed and crazy! They've escaped from the prison.",
			"Defeat 8 of them so we can get close without trouble.",
			"They're scattered around the prison yard and walls. Be careful!",
			"Once they're gone, we can focus on freeing Jolyne-san!",
		},
		InProgress = {
			"You're doing great! Just a few more convicts...",
			"Stay hidden like I do – surprise them!",
		},
		-- No TurnIn dialog (auto-complete)
		Completed = {
			"You got them all! The path is clear now.",
			"Thank you... Jolyne-san will be so happy.",
			"Next, we break her out for real!",
		},
	},
}

--beginning of new quests:
QuestDefinitions.DefeatAvdol1 = {
	Name = "Challenge Avdol",
	Description = "Defeat Avdol in a fierce duel to test your newfound power against his fiery Stand.",
	Objectives = {
		{ Type = "Defeat", Target = "AvdolFighter", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 1000,
	RewardCash = 600,
	RewardItems = nil, -- Optional unique item
	TurnInNpc = nil, -- No turn-in required → Auto completes on defeat (thanks to your current CheckCompletion logic)
	NextQuest = "TalkToPucci1", -- End of branch or link to more later (e.g., "TalkToJoseph1")
	Dialog = {
		Offer = {
			"So you believe your power is sufficient to challenge the elite?",
			"Very well… Avdol wields Magician's Red, a Stand of scorching flames.",
			"Seek him out and defeat him. I sense that he is at the 24/7 Supermarket right now...",
			"Prove to me that you are worthy of standing in my presence.",
			"Do not disappoint me...",
		},
		InProgress = {
			"Avdol's flames burn hotter than the sun. Crush him quickly.",
			"Return only when you have tasted victory.",
		},
		-- TurnIn is omitted on purpose since there's no NPC to turn in to
		-- The quest will auto-complete and give rewards immediately upon defeating Avdol
		Completed = {
			"You have returned victorious... Impressive.",
			"Avdol is no weakling, yet you felled him. Your power grows.",
			"Continue down your path. Destiny awaits.",
		},
	},
}

---------------------------------------------------------------------
-- 11. TALK TO PUCCI (Quest 11)
---------------------------------------------------------------------
QuestDefinitions.TalkToPucci1 = {
	Name = "Talk to Pucci",
	Description = "Find Pucci and speak with him about the path to Heaven.",
	Giver = "Pucci",
	Objectives = {
		{ Type = "Talk", Target = "Pucci", Completed = false },
	},
	RewardXP = 1000,
	TurnInNpc = "Pucci", -- Auto-completes on talk
	RewardCash = 200,
	NextQuest = "DefeatHamonUsers1",
	Dialog = {
		Offer = {
			"You... I sense the will of my lord Dio within you.",
			"I am Enrico Pucci, priest of the new world – the world of Heaven.",
			"To ascend, all obstacles must be crushed. Jotaro Kujo andh is allies stand in our way.",
			"Seek them out and defeat them. Prove your devotion to the plan.",
			"His Star Platinum will test you... but Heaven awaits the worthy.",
		},
		InProgress = {
			"This never triggers",
		},
		TurnIn = "Pucci",
		Completed = {
			"Our paths align. Jotaro must fall for Heaven to rise.",
			"Find him near Old Town Road. Do not fail.",
		},
	},
}

---------------------------------------------------------------------
-- DEFEAT HAMON USERS (Refactored Quest)
---------------------------------------------------------------------
QuestDefinitions.DefeatHamonUsers1 = {
	Name = "Purge the Hamon Users",
	Description = "Defeat 3 Hamon users to eliminate threats to the Heaven plan.",
	Giver = "Pucci",
	Objectives = {
		{ Type = "Defeat", Target = "HamonUser", Required = 3, Progress = 0, Completed = false },
	},
	RewardXP = 3000,
	RewardCash = 800,
	RewardItems = { "Rokakaka" }, -- Unique JoJo-themed item
	TurnInNpc = nil, -- Auto-completes on defeat
	NextQuest = "DefeatRohanKishibe1", -- Leads directly into the next quest
	Dialog = {
		Offer = {
			"The ripple of Hamon is a vile force that once opposed Lord Dio.",
			"These Hamon users still lurk, clinging to their outdated breathing techniques.",
			"Hunt down and defeat three of them. Leave no trace of their light.",
			"Their energy will be extinguished before Heaven's gravity.",
			"Go now. Mercy is for the weak.",
		},
		InProgress = {
			"Their Hamon surges like sunlight. Crush it beneath your will!",
			"Two more remain... Do not falter.",
		},
		-- No TurnIn dialog (auto-complete)
		Completed = {
			"The Hamon users have been silenced... Well done.",
			"Their light fades, making way for true destiny.",
			"A new challenge awaits. Seek out the one called Rohan Kishibe.",
		},
	},
}

---------------------------------------------------------------------
-- DEFEAT ROHAN KISHIBE (New Follow-up Quest)
---------------------------------------------------------------------
QuestDefinitions.DefeatRohanKishibe1 = {
	Name = "Defeat Rohan Kishibe",
	Description = "Defeat the mangaka Rohan Kishibe and his dangerous Stand, Heaven's Door.",
	Objectives = {
		{ Type = "Defeat", Target = "RohanKishibe", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 3000,
	RewardCash = 1000,
	RewardItems = nil, -- Unique collectible item
	TurnInNpc = nil, -- Auto-completes on defeat
	NextQuest = "DefeatKakyoin1", -- End of this mini-branch or link to more later
	Dialog = {
		Offer = {
			"Rohan Kishibe possesses Heaven's Door – a Stand that can rewrite reality itself.",
			"He is a wild card who pries into matters he should not.",
			"Find him in Morioh's outskirts and defeat him utterly.",
			"Do not let him open his book on you. End him swiftly.",
		},
		InProgress = {
			"Heaven's Door reveals all secrets. Do not let him read you!",
			"Strike fast – his pen is mightier than most swords.",
		},
		-- No TurnIn dialog (auto-complete)
		Completed = {
			"Rohan Kishibe has been defeated. His stories end here.",
			"No one will document your path now. Heaven grows nearer.",
			"You have proven yourself once more.",
		},
	},
}

QuestDefinitions.DefeatKakyoin1 = {
	Name = "Defeat Kakyoin Noriaki",
	Description = "Defeat the Kakyoin and hius Hierophant.",
	Objectives = {
		{ Type = "Defeat", Target = "KakyoinNoriaki", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 5000,
	RewardCash = 500,
	RewardItems = nil, -- Unique collectible item
	TurnInNpc = nil, -- Auto-completes on defeat
	NextQuest = "DefeatOkuyasu1", -- End of this mini-branch or link to more later
	Dialog = {
		Offer = {
			"Rohan Kishibe possesses Heaven's Door – a Stand that can rewrite reality itself.",
			"He is a wild card who pries into matters he should not.",
			"Find him in Morioh's outskirts and defeat him utterly.",
			"Do not let him open his book on you. End him swiftly.",
		},
		InProgress = {
			"Heaven's Door reveals all secrets. Do not let him read you!",
			"Strike fast – his pen is mightier than most swords.",
		},
		-- No TurnIn dialog (auto-complete)
		Completed = {
			"Rohan Kishibe has been defeated. His stories end here.",
			"No one will document your path now. Heaven grows nearer.",
			"You have proven yourself once more.",
		},
	},
}

QuestDefinitions.DefeatOkuyasu1 = {
	Name = "Defeat Kakyoin Noriaki",
	Description = "Defeat the Kakyoin and hius Hierophant.",
	Objectives = {
		{ Type = "Defeat", Target = "OkuyasuNijimura", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 5000,
	RewardCash = 500,
	RewardItems = nil, -- Unique collectible item
	TurnInNpc = nil, -- Auto-completes on defeat
	NextQuest = "DefeatJotaro1", -- End of this mini-branch or link to more later
	Dialog = {
		Offer = {
			"Rohan Kishibe possesses Heaven's Door – a Stand that can rewrite reality itself.",
			"He is a wild card who pries into matters he should not.",
			"Find him in Morioh's outskirts and defeat him utterly.",
			"Do not let him open his book on you. End him swiftly.",
		},
		InProgress = {
			"Heaven's Door reveals all secrets. Do not let him read you!",
			"Strike fast – his pen is mightier than most swords.",
		},
		-- No TurnIn dialog (auto-complete)
		Completed = {
			"Rohan Kishibe has been defeated. His stories end here.",
			"No one will document your path now. Heaven grows nearer.",
			"You have proven yourself once more.",
		},
	},
}

---------------------------------------------------------------------
-- 12. DEFEAT JOTARO (Quest 12)
---------------------------------------------------------------------
QuestDefinitions.DefeatJotaro1 = {
	Name = "Defeat Jotaro Kujo",
	Description = "Defeat Jotaro in combat to pave the way for Heaven.",
	Objectives = {
		{ Type = "Defeat", Target = "JotaroPart3", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 15000,
	RewardCash = 10000,
	RewardItems = { "Rokakaka" }, -- Unique JoJo-themed item
	TurnInNpc = nil, -- Auto-completes on defeat
	NextQuest = "TalkToFunnyValentine1", -- End of this branch or link to more (e.g., "TalkToDio1")
	Dialog = {
		Offer = {
			"Jotaro Kujo... the man who stopped Dio once.",
			"His Stand, Star Platinum, wields immense power – but so do you.",
			"Crush him utterly. Ora ora means nothing before Heaven's gravity.",
			"He's waiting at Old Town Road. Strike without mercy!",
		},
		InProgress = {
			"Jotaro's punches are like time itself stopping. Endure and counter!",
		},
		-- No TurnIn dialog (auto-complete)
		Completed = {
			"Jotaro has fallen... Excellent.",
			"You are one step closer to the ultimate destiny.",
			"Return if you seek further enlightenment.",
		},
	},
}

---------------------------------------------------------------------
-- TALK TO FUNNY VALENTINE (New Quest)
---------------------------------------------------------------------
QuestDefinitions.TalkToFunnyValentine1 = {
	Name = "Talk to Funny Valentine",
	Description = "Find President Funny Valentine and speak with him.",
	Objectives = {
		{ Type = "Talk", Target = "FunnyValentine", Completed = false },
	},
	RewardXP = 12000,
	TurnInNpc = "FunnyValentine", -- Auto-completes on talk
	RewardItems = {},
	RewardCash = 10000,
	NextQuest = nil, -- Set to your next quest in the Steel Ball Run / D4C branch when ready (e.g., "DefeatGyro1" or "CollectCorpseParts1")
	Dialog = {
		Offer = {
			"You stand before the President of the United States, Funny Valentine.",
			"I seek only what is right for this nation... for its people.",
			"The path to true prosperity lies ahead, guarded by the sacred Corpse.",
			"If you possess the resolve, prove it. Stand with America.",
			"Napkin in hand, I ask: will you take the first step?",
		},
		InProgress = {
			"This never triggers",
		},
		TurnIn = nil,
		Completed = {
			"Your patriotism is noted.",
			"The flag waves for those who act. Return when you are ready for greater duty.",
			"Do not waver. America will be first... always.",
		},
	},
}

--end of new quests

QuestDefinitions.DefeatThugsRepeatable = {
	Name = "Stop the Thugs",
	Description = "Defeat 5 thugs at the Motor Store.",

	Repeatable = true, -- 🔹 NEW

	Giver = "Josuke",
	RewardCash = 1500,
	RewardXP = 300,

	Objectives = {
		{ Type = "Defeat", Target = "Thug", Required = 5, Progress = 0, Completed = false },
	},

	--TurnInNpc = "Josuke",

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

QuestDefinitions.DefeatCriminalsStandUsersRepeatable = {
	Name = "Criminal Stand Users",
	Description = "Defeat 3 Criminal Stand Users at the treehouse.",

	Repeatable = true, -- 🔹 NEW

	Giver = "Kakyoin",
	RewardCash = 1500,
	RewardXP = 200,

	Objectives = {
		{ Type = "Defeat", Target = "Criminal Stand User", Required = 3, Progress = 0, Completed = false },
	},

	--TurnInNpc = "Kakyoin",

	Dialog = {
		Offer = {
			"Careful, these crimnals have a powerful STAND ability! Take them out!",
		},

		InProgress = {
			"Careful, these crimnals have a powerful STAND ability! Take them out!",
		},

		TurnIn = {
			"You got them! Well done indeed!",
		},

		Completed = {
			"Ready for more work? These criminals always come back!",
		},
	},
}

QuestDefinitions.DefeatVampiresRepeatable = {
	Name = "Slay Vampires",
	Description = "Defeat 3 Vampires",

	Repeatable = true, -- 🔹 NEW

	Giver = "Caesar",
	RewardCash = 300,
	RewardXP = 2000,

	Objectives = {
		{ Type = "Defeat", Target = "Vampire", Required = 3, Progress = 0, Completed = false },
	},

	--TurnInNpc = "Caesar",

	Dialog = {
		Offer = {
			"We have to destroy these vampires! Help me get 3 of them.",
		},

		InProgress = {
			"We have to destroy these vampires! Help me get 3 of them.",
		},

		TurnIn = {
			"You got them! Well done indeed!",
		},

		Completed = {
			"Ready for more work? These vampires always come back!",
		},
	},
}

return QuestDefinitions
