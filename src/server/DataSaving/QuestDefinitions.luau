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
			"I sense great potential within you.",
			"I am Girono Giorvana and I have a dream to keep this city safe. Crime is running rampant and that's no coincidence.",
			"Take this STAND ARROW. Open your INVENTORY to use it.",
			"Go talk to Jotaro. He knows what needs to be done. (Hit SHIFT to DASH!)",
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

	RewardXP = 150,
	RewardItems = { "Rokakaka" },
	TurnInNpc = nil,

	NextQuest = { "DefeatThugs1", "TalkToCrimeBoss" },

	Dialog = {
		Offer = {
			"So, Giorno sent you? Good… we’ve got a problem on our hands.",
			"The thugs we’ve seen around the city aren’t just random punks — someone is supplying them.",
			"I have a strong suspicion it’s the RO Bank, but I need proof.",
			"Head to the motor store and take out a few thugs. Then, interogate their boss to get the information we need.",
			"(DASH with SHIFT and then hold CONTROL to SLIDE down this hill!)",
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
	RewardItems = { "StandArrow" },
	TurnInNpc = nil,

	Dialog = {
		Offer = {
			"So you’re the one who’s been taking out my men… bold.",
			"Yeah, we’re working with the RO Bank. They pay us, we cause chaos — simple business.",
			"But if you’re here looking for a fight… you’re gonna get one.",
			"My men are stand users! You'll never defeat them in a million years!",
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
	RewardXP = 400,
	RewardItems = { "StandArrow" },
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
			"If we’re right about the RO Bank… there’s only one way to take them down.",
			"Break into the vault. Take their source of power - their gold.",
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
		{ Type = "Defeat", Target = "CriminalStandUser", Required = 3, Progress = 0, Completed = false },
	},

	NextQuest = { "TalkToDioPB1" },

	RewardXP = 1000,
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

	RewardXP = 1000,
	RewardCash = 20000,
	TurnInNpc = "Jotaro",
	NextQuest = "TalkToSpeedwagon1",
	RewardItems = { "StandArrow" },

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
			"Prove your worthiness to me. Defeat three of them… if you can.",
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
	TurnInNpc = "DioPB",
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
-- TALK TO SPEEDWAGON (Refactored Quest 10)
---------------------------------------------------------------------
QuestDefinitions.TalkToSpeedwagon1 = {
	Name = "Talk to Speedwagon",
	Description = "Find Speedwagon and speak with him.",
	Giver = "Speedwagon",
	Objectives = {
		{ Type = "Talk", Target = "Speedwagon", Completed = false },
	},
	RewardXP = 600,
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
	RewardXP = 1500,
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
	RewardXP = 3500,
	RewardCash = 200,
	TurnInNpc = "Speedwagon",
	NextQuest = "DefeatKiraYoshikage1",
	Dialog = {
		Offer = {
			"Oi, listen 'ere, lad!",
			"If you wanna get stronger and learn to fight like a proper Joestar ally, you’ve gotta prove your resolve!",
			"There’s a pack of filthy vampires lurkin’ 'round the city.",
			"I want you to take down at least 5 of 'em! Smash 'em good!",
			"Remember — control your breathin'! That’s the key to Hamon, ya hear?",
			"Now go on and give those bloodsuckers a right proper thrashin'!",
		},
		InProgress = {
			"Keep at it, chap! Those vampires won’t wait around for ya!",
			"Focus your energy and strike true — don’t let 'em sink their teeth in!",
		},
		TurnIn = {
			"Blimey! You really did it! That’s the spirit!",
			"I can see the fire burnin’ bright in you, kid. Well done indeed!",
			"Now then… there’s a nasty villain runnin’ loose in this city.",
			"A dangerous Stand user by the name of Kira Yoshikage. Proper evil bloke, he is.",
			"Take him out and keep the good people of this city safe!",
			"Hard times make strong men, remember that! Like Baron Zeppeli says, the north wind made the Vikings!",
		},
		Completed = {
			"You’ve already cleared out those vampires. Good show!",
			"Rest up, lad. There’s still plenty of fightin' left to do!",
		},
	},
}

QuestDefinitions.DefeatKiraYoshikage1 = {
	Name = "Defeat Kira Yoshikage",
	Description = "Defeat Kira Yoshikage and his explosive Stand, Killer Queen.",
	Objectives = {
		{ Type = "Defeat", Target = "KiraYoshikage", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 7000,
	RewardCash = 600,
	RewardItems = { "PurpleRokakaka" },
	TurnInNpc = "Speedwagon",
	NextQuest = "DefeatDiavolo1", -- Leads directly into Diavolo quest
	Dialog = {
		Offer = {
			"Oi! Listen up, lad!",
			"There's a dangerous bloke named Kira Yoshikage runnin' around Morioh.",
			"He's a right nasty piece of work — his Stand, Killer Queen, can turn anything into a bomb!",
			"He's been livin' a quiet life while blowin' people up left and right. Unforgivable!",
			"I need you to find him and take him down for good!",
			"Give 'im hell, ya hear? For the sake of all the innocent folks he's hurt!",
		},
		InProgress = {
			"That Killer Queen is no joke! Watch out for his bombs — one touch and you're done!",
			"Keep fightin', chap! Don't let him blow you to bits!",
		},
		TurnIn = {
			"Blimey! You actually did it!",
			"Kira Yoshikage is finished! You’ve saved a lot of lives today, kid.",
			"That was some fine work. I knew you had the guts for it!",
			"Here’s your reward. Now rest up — there’s an even bigger threat waitin’ ahead.",
		},
		Completed = {
			"Kira’s already been dealt with. Good on ya!",
			"You’re becoming quite the fighter. Keep it up!",
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
	RewardItems = { "StandArrow", "PurpleRokakaka" },
	TurnInNpc = "Speedwagon", -- no longer auto completes
	NextQuest = "TalkToEmporio1", -- End of this branch or link to more later
	Dialog = {
		Offer = {
			"Oi, buckle up lad, this one's a proper monster!",
			"Diavolo is the boss of a nasty gang called Passione. A right shadowy devil, he is.",
			"His Stand, King Crimson, can erase time itself — skips right over moments like they never happened!",
			"I need you to hunt him down and give him a good old-fashioned thrashin'!",
			"Don't let his time tricks fool ya. Smash through 'em and end this madness once and for all!",
		},
		InProgress = {
			"Watch yourself, chap! King Crimson is slippery as an eel.",
			"If time suddenly skips, stay sharp and hit him with everything you've got!",
			"You can do it, lad! I believe in ya!",
		},
		TurnIn = {
			"Blimey! You actually beat Diavolo?!",
			"That was one of the toughest blokes we've faced yet! Well done, my boy!",
			"Passione's boss is finished thanks to you. The city's a safer place now.",
			"Here’s your well-earned reward. You've earned every penny and then some!",
			"Rest up — there's still more trouble brewin' ahead.",
		},
		Completed = {
			"Diavolo's already been taken care of. Good show!",
			"You're turning into a real legend, ya know that?",
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
	TurnInNpc = "Emporio",
	NextQuest = "TalkToWarden1", -- End of this segment or link to Jolyne breakout quest later
	Dialog = {
		Offer = {
			"The convicts are strong... and they're not thinking straight.",
			"They broke out during the chaos—now the whole yard is dangerous.",
			"If we try to move like this, we'll get caught for sure.",
			"Can you defeat 8 of them? Then we’ll have a clear path to Jolyne-san.",
		},

		InProgress = {
			"I can hear fighting out there... stay careful!",
			"You're doing great! Just a few more...",
			"Try to strike fast before they notice you—like a ghost.",
		},

		TurnIn = {
			"You’re back...! Did you handle them?",
			"...You did?! I knew I could count on you!",
			"The area feels a lot safer now… we can finally move without drawing attention.",
			"This is our chance. Jolyne-san is waiting.",
		},

		Completed = {
			"You got them all! The path is clear now.",
			"Thank you... Jolyne-san will be so happy.",
			"We're one step closer to breaking her out.",
			"Let’s not waste any time.",
		},
	},
}

QuestDefinitions.TalkToWarden1 = {
	Name = "Talk to the Warden",
	Description = "Speak with the Warden to advance Jolyne's breakout plan.",
	Giver = "Emporio",
	Objectives = {
		{ Type = "Talk", Target = "Warden", Completed = false },
	},
	RewardXP = 10000,
	RewardCash = 150,
	RewardItems = {},
	TurnInNpc = nil, -- Auto-completes on talk
	NextQuest = nil, -- Leads to Jolyne breakout quest or end of segment
	Dialog = {
		Offer = {
			"Y-You did it! The convicts are gone... the yard is safe now!",
			"The warden holds the keys – and maybe more secrets.",
			"Talk to him in his office. Convince him... or distract him!",
			"We need his help to free Jolyne-san!",
			"(Breakout quest coming soon)",
		},
		InProgress = {
			"This never triggers",
		},
		TurnIn = nil,
		Completed = {
			"You spoke to the warden... Great job!",
			"Jolyne-san's freedom is within reach now.",
			"(Breakout quest will release soon)",
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
	TurnInNpc = "DioPB", -- No turn-in required → Auto completes on defeat (thanks to your current CheckCompletion logic)
	NextQuest = "TalkToPucci1", -- End of branch or link to more later (e.g., "TalkToJoseph1")
	Dialog = {
		Offer = {
			"Hmph... So you think yourself worthy of standing beside me?",
			"Avdol, that pathetic fortune teller, dares to oppose my will with his Magician's Red.",
			"His flames are nothing but a flickering candle before my power.",
			"Prove to me that you are not mere fodder. Do not disappoint me... or face my wrath.",
		},
		InProgress = {
			"Avdol's flames burn hot, but they are weak compared to a true vampire's might.",
			"Extinguish his fire and return to me victorious.",
		},
		TurnIn = {
			"Well... it seems you are not completely useless after all.",
			"Avdol has fallen. His flames have been quenched by your hand.",
			"You have taken another step toward true power.",
		},
		Completed = {
			"Avdol has already been defeated.",
			"Do not waste my time with trivialities.",
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
			"To ascend, all obstacles must be crushed. Jotaro Kujo and his allies stand in our way.",
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
	TurnInNpc = "Pucci", -- Auto-completes on defeat
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
	TurnInNpc = "Pucci", -- Auto-completes on defeat
	NextQuest = "DefeatKakyoin1", -- End of this mini-branch or link to more later
	Dialog = {
		Offer = {
			"Rohan Kishibe possesses Heaven's Door – a Stand that can rewrite reality itself.",
			"He is a wild card who pries into matters he should not.",
			"Find him and defeat him utterly.",
			"Do not let him open his book on you. End him swiftly.",
		},
		InProgress = {
			"Heaven's Door reveals all secrets. Do not let him read you!",
			"Strike fast – his pen is mightier than most swords.",
		},
		TurnIn = {
			"Excellent... Rohan Kishibe has been silenced.",
			"No more will his Stand rewrite the pages of fate.",
			"You have removed another obstacle standing in the way of Heaven.",
			"Your devotion serves the greater plan well.",
		},
		Completed = {
			"Rohan has already been defeated.",
			"His stories are over. Heaven draws ever closer.",
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
	TurnInNpc = "Pucci", -- Auto-completes on defeat
	NextQuest = "DefeatOkuyasu1", -- End of this mini-branch or link to more later
	Dialog = {
		Offer = {
			"Kakyoin Noriaki... that loyal dog who once served Jotaro.",
			"His Hierophant Green is a versatile long-range Stand with deadly precision.",
			"He still clings to the old bonds of friendship. Such weakness.",
			"Find him and crush him. Leave no trace of his emerald splash.",
		},
		InProgress = {
			"Hierophant Green can attack from a distance. Stay alert and close the gap.",
			"Do not underestimate him — finish the job quickly.",
		},
		TurnIn = {
			"Well done. Kakyoin has fallen.",
			"One more thread of Jotaro's past has been severed.",
			"Continue proving your worth to the cause of Heaven.",
		},
		Completed = {
			"Kakyoin has already been defeated.",
			"Your service to the greater plan is remembered.",
		},
	},
}

QuestDefinitions.DefeatOkuyasu1 = {
	Name = "Defeat Okuyasu",
	Description = "Defeat the Kakyoin and hius Hierophant.",
	Objectives = {
		{ Type = "Defeat", Target = "OkuyasuNijimura", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 5000,
	RewardCash = 500,
	RewardItems = { "StandArrow" }, -- Unique collectible item
	TurnInNpc = "Pucci", -- Auto-completes on defeat
	NextQuest = "DefeatJotaro1", -- End of this mini-branch or link to more later
	Dialog = {
		Offer = {
			"Okuyasu Nijimura... a simple-minded fool with terrifying power.",
			"His Stand, The Hand, can erase anything it touches — space itself vanishes before it.",
			"He and his friend Josuke continue to interfere with our plans.",
			"Find him and defeat him. Do not allow his erasure to touch you.",
		},
		InProgress = {
			"Be extremely careful. One wrong move and The Hand will erase you from existence.",
			"Strike decisively before he can use his ability.",
		},
		TurnIn = {
			"Well done. Okuyasu has been eliminated.",
			"Another piece of Josuke's little gang has been removed.",
			"With every fallen ally, Jotaro grows more isolated.",
			"You continue to serve the path to Heaven faithfully.",
		},
		Completed = {
			"Okuyasu has already been dealt with.",
			"His erasure could not save him in the end.",
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
	RewardItems = { "PurpleRokakaka", "StandArrow", "Rokakaka" }, -- Unique JoJo-themed item
	TurnInNpc = "Pucci", -- Auto-completes on defeat
	NextQuest = "TalkToFunnyValentine1", -- End of this branch or link to more (e.g., "TalkToDio1")
	Dialog = {
		Offer = {
			"Jotaro Kujo... the man who once stopped Lord Dio.",
			"His Stand, Star Platinum, possesses immense strength and can stop time itself.",
			"He is the greatest obstacle remaining from the old world.",
			"Find him and crush him utterly. Ora ora will not save him this time.",
			"Strike without mercy. Heaven demands his end.",
		},
		InProgress = {
			"Star Platinum's power is overwhelming. Endure his barrage and counter with everything you have.",
			"Do not falter — the fate of Heaven rests on this victory.",
		},
		TurnIn = {
			"At last... Jotaro Kujo has fallen.",
			"The final thread connecting the old Joestar bloodline has been severed.",
			"You have done what even Dio could not fully accomplish.",
			"Your service brings us one step closer to the birth of a new Heaven.",
			"Well done, my faithful servant.",
		},
		Completed = {
			"Jotaro has already been defeated.",
			"The path to Heaven is clearer thanks to your efforts.",
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
	NextQuest = "DefeatGiorno1", -- Set to your next quest in the Steel Ball Run / D4C branch when ready (e.g., "DefeatGyro1" or "CollectCorpseParts1")
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

QuestDefinitions.DefeatGiorno1 = {
	Name = "Defeat Giorno Giovanna",
	Description = "Defeat Giorno in combat to pave the way for Heaven.",
	Objectives = {
		{ Type = "Defeat", Target = "Giorno", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 15000,
	RewardCash = 10000,
	RewardItems = { "PurpleRokakaka" }, -- Unique JoJo-themed item
	TurnInNpc = "FunnyValentine", -- Auto-completes on defeat
	NextQuest = "FindFreddy1", -- End of this branch or link to more (e.g., "TalkToDio1")
	Dialog = {
		Offer = {
			"Giorno Giovanna... Dio's son, wielder of Gold Experience.",
			"He stands in our way, but he is a good kid. His life-giving power means nothing before true destiny.",
			"Strike him down, but do not eliminate him. He may be of use later.",
		},
		InProgress = {
			"Giorno's Requiem resets reality itself. Endure and impose Heaven's order!",
		},
		-- No TurnIn dialog (auto-complete)
		Completed = {
			"Giorno has been defeated... Excellent.",
			"You are one step closer to the ultimate destiny.",
			"Return if you seek further enlightenment.",
		},
	},
}

QuestDefinitions.FindFreddy1 = {
	Name = "Find Freddy",
	Giver = "FunnyValentine",
	Objectives = {
		{ Type = "Interact", Target = "Freddy", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 16000,
	RewardCash = 1000,
	TurnInNpc = "FunnyValentine",
	NextQuest = "ValentinesGold1",
	RewardItems = { "PurpleRokakaka" }, -- Unique JoJo-themed item
	Dialog = {
		Offer = {
			"This bar... Freddy's Bar. Its name troubles me.",
			"I suspect a secret reason behind it. A hidden truth.",
			"Find Freddy. Uncover why this place bears his name.",
		},
		InProgress = {
			"Freddy hides within his own bar. Search every corner.",
			"The truth awaits in the shadows of Freddy's domain.",
		},
		TurnIn = {
			"You've found him... Good. But this revelation stirs more questions.",
			"Freddy knows of my gold. It must be recovered.",
		},
		Completed = {
			"Freddy's secret is yours. But my gold remains lost.",
		},
	},
}

QuestDefinitions.ValentinesGold1 = {
	Name = "Valentine's Gold",
	Giver = "FunnyValentine",
	Objectives = {
		{ Type = "Interact", Target = "ValentinesGold", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 20000,
	RewardCash = 20000,
	TurnInNpc = "FunnyValentine",
	RewardItems = { "PurpleRokakaka" }, -- Unique JoJo-themed item
	NextQuest = "DefeatPolice1", -- End of chain or link to next
	Dialog = {
		Offer = {
			"Freddy's words confirm it – my gold is hidden nearby.",
			"The spoils of Heaven's path cannot be left to thieves.",
			"Retrieve my gold. Bring it to me at once.",
		},
		InProgress = {
			"The gold gleams with destiny's light. It calls to the worthy.",
			"Search the bar's depths. Claim what is mine.",
		},
		TurnIn = {
			"The gold... returned to its rightful owner.",
			"Excellent work. You serve the path to Heaven well.",
		},
		Completed = {
			"My gold is secure. Your service is noted.",
		},
	},
}

QuestDefinitions.DefeatPolice1 = {
	Name = "Purge the Corrupt Cops",
	Description = "Defeat 8 Corrupt Cops in Shanty Town to eliminate threats after recovering the gold.",
	Giver = "FunnyValentine",
	Objectives = {
		{ Type = "Defeat", Target = "CorruptCop", Required = 8, Progress = 0, Completed = false },
	},
	RewardXP = 17000,
	RewardCash = 800,
	RewardItems = { "PurpleRokakaka" }, -- Unique JoJo-themed item
	TurnInNpc = "FunnyValentine",
	NextQuest = "TalkToPucci2", -- End of chain or link to next
	Dialog = {
		Offer = {
			"These Shanty Town police... corrupt dogs of a false justice.",
			"They hunt the gold I've reclaimed – my own private property!",
			"The founders of this great nation would scorn these theives!",
			"Hunt them down and defeat eight. By the hand of fate you will shatter their badges.",
			"Their false law crumbles before true patriotism.",
			"Go now. America will see true justice!",
		},
		InProgress = {
			"The police wield guns and false authority. Crush them beneath your Stand!",
			"Two more remain... Do not falter on the path to Heaven.",
		},
		-- No TurnIn dialog (auto-complete)
		Completed = {
			"The corrupt police lie broken in Shanty Town... Excellent.",
			"Their corrupt light fades, securing the gold for destiny.",
			"You serve America well. Greater trials await.",
		},
	},
}

QuestDefinitions.TalkToPucci2 = {
	Name = "Talk to Pucci",
	Description = "Find Pucci and speak with him about the path to Heaven.",
	Giver = "Pucci",
	Objectives = {
		{ Type = "Talk", Target = "Pucci2", Completed = false },
	},
	RewardXP = 1000,
	TurnInNpc = "Pucci", -- Auto-completes on talk
	RewardCash = 200,
	NextQuest = nil,
	Dialog = {
		Offer = {
			"You have served America well thus far.",
			"There is one more individual I wish for you to speak to now — a man of great faith and vision.",
			"His name is Enrico Pucci. A priest who understands the true weight of destiny.",
			"Seek him out. He awaits your arrival and has important words regarding the future of this nation.",
			"Remember... the eyes of America are upon you. Do not waver.",
		},
		InProgress = {
			"This never triggers",
		},
		TurnIn = nil,
		Completed = {
			"You have spoken with Pucci. Excellent.",
			"The pieces are slowly falling into place.",
			"Greater trials lie ahead. Steel your resolve for the sake of our great country.",
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
		{ Type = "Defeat", Target = "CriminalStandUser", Required = 3, Progress = 0, Completed = false },
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

QuestDefinitions.DefeatHamonUsersRepeatable = {
	Name = "Defeat Hamon Users",
	Description = "Defeat 3 Hamon Users",

	Repeatable = true, -- 🔹 NEW

	Giver = "Esidisi",
	RewardCash = 5000,
	RewardXP = 3000,

	Objectives = {
		{ Type = "Defeat", Target = "HamonUser", Required = 3, Progress = 0, Completed = false },
	},

	--TurnInNpc = "Caesar",

	Dialog = {
		Offer = {
			"The Hamon clan has been a thorn in our side for far too long!",
			"Help me eliminate them to ensure the dominance of the pillar men.",
		},

		InProgress = {
			"The Hamon clan has been a thorn in our side for far too long!",
			"Help me eliminate them to ensure the dominance of the pillar men.",
		},

		TurnIn = {
			"You got them! Well done indeed!",
		},

		Completed = {
			"Ready for more work?",
		},
	},
}

return QuestDefinitions
