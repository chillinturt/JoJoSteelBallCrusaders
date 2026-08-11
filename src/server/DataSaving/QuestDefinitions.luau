-- QuestDefinitions Module
local QuestDefinitions = {}

QuestDefinitions.DashTutorial = {
	Name = "Learn to Dash",
	Description = "Press SHIFT to Dash",

	Manual = true, -- 🔥 THIS is the key

	Objectives = {}, -- No objectives needed

	RewardXP = 25,
	NextQuest = "SlideTutorial",

	Dialog = {
		Offer = {
			"Movement is key in combat.",
			"Press Shift to Dash.",
		},
	},
}

QuestDefinitions.SlideTutorial = {
	Name = "Learn to Slide",
	Description = "Hold CTRL to slide",

	Manual = true, -- 🔥 THIS is the key

	Objectives = {}, -- No objectives needed

	RewardXP = 25,
	NextQuest = "BlockTutorial",

	Dialog = {
		Offer = {
			"Movement is key in combat.",
			"Press CTRL to SLIDE.",
		},
	},
}

QuestDefinitions.BlockTutorial = {
	Name = "Learn to Block",
	Description = "Hold F to Block",

	Manual = true, -- 🔥 THIS is the key

	Objectives = {}, -- No objectives needed

	RewardXP = 25,
	NextQuest = "ShiftLockTutorial",

	Dialog = {
		Offer = {
			"Movement is key in combat.",
			"Press F to Block.",
		},
	},
}

QuestDefinitions.ShiftLockTutorial = {
	Name = "Learn to ShiftLock",
	Description = "Press Alt to ShiftLock",

	Manual = true, -- 🔥 THIS is the key

	Objectives = {}, -- No objectives needed

	RewardXP = 25,
	NextQuest = "UseStandArrowTutorial",

	Dialog = {
		Offer = {
			"Movement is key in combat.",
			"Press F to Block.",
		},
	},
}

QuestDefinitions.UseStandArrowTutorial = {
	Name = "Use Stand Arrow",
	Description = "Open inventory and use the Stand Arrow",

	Manual = true, -- 🔥 THIS is the key

	Objectives = {}, -- No objectives needed

	RewardXP = 25,
	NextQuest = "SummonStandTutorial",

	Dialog = {
		Offer = {
			"Open your inventory and use the stand arrow.",
		},
	},
}

QuestDefinitions.SummonStandTutorial = {
	Name = "Summon your Stand",
	Description = "Press Q to summon your stand",

	Manual = true, -- 🔥 THIS is the key

	Objectives = {}, -- No objectives needed

	RewardXP = 25,
	NextQuest = "StandBarrageTutorial",

	Dialog = {
		Offer = {
			"Press Q to summon your stand.",
		},
	},
}

QuestDefinitions.StandBarrageTutorial = {
	Name = "Barrage with your stand",
	Description = "While you stand is summoned, Hold E to barrage",

	Manual = true, -- 🔥 THIS is the key

	Objectives = {}, -- No objectives needed

	RewardXP = 25,
	NextQuest = "TalentTutorial",

	Dialog = {
		Offer = {
			"While you stand is summoned, Hold E to barrage.",
		},
	},
}

QuestDefinitions.TalentTutorial = {
	Name = "Spend talent points",
	Description = "Open the menu in the bottom right and select Talents. Upgrade any talent from either of the 3 tabs.",

	Manual = true, -- 🔥 THIS is the key

	Objectives = {}, -- No objectives needed

	RewardXP = 25,
	NextQuest = "DoubleJumpTutorial",

	Dialog = {
		Offer = {
			"While you stand is summoned, Hold E to barrage.",
		},
	},
}

QuestDefinitions.DoubleJumpTutorial = {
	Name = "Use double jump",
	Description = "Press jump while in the air to double jump.",

	Manual = true, -- 🔥 THIS is the key

	Objectives = {}, -- No objectives needed

	RewardXP = 25,
	NextQuest = "WallJumpTutorial",

	Dialog = {
		Offer = {
			"Press jump while in the air to double jump.",
		},
	},
}

QuestDefinitions.WallJumpTutorial = {
	Name = "Use wall jump",
	Description = "Press jump while in the air AND next to a wall to wall jump.",

	Manual = true, -- 🔥 THIS is the key

	Objectives = {}, -- No objectives needed

	RewardXP = 25,
	NextQuest = nil,

	Dialog = {
		Offer = {
			"Press jump while in the air AND next to a wall to wall jump.",
		},
	},
}

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
	NextQuest = { "DefeatThugs1" },

	Dialog = {
		Offer = {
			"I am Girono Giorvana and I have a dream to keep this city safe.",
			"Crime is running rampant and even I can't stop it all. Will you help me?",
			"My Stand Arrow is attracted to you, as if it senses your worthiness... Here, take it. Tust your best judgement...",
		},

		InProgress = {
			"This never triggers",
		},

		TurnIn = nil, -- No turn-in NPC
		Completed = {
			"You’ve already spoken to me. The mission is waiting.",
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

	RewardXP = 20000,
	RewardItems = { "Rokakaka" },
	TurnInNpc = nil,

	NextQuest = "DefeatDIO",

	Dialog = {
		Offer = {
			"So you made it this far...",
			"DIO's not like the others. You already know that.",
			"He'll keep coming until someone puts him down for good.",
			"All that fighting you've done... it led you here.",
			"Don't hold back. End this.",
		},
		InProgress = {
			"Stay sharp.",
			"DIO won't give you an opening twice.",
		},
		TurnIn = {
			"...You actually did it.",
			"DIO's finished.",
			"...Good.",
			"You did what had to be done.",
		},
		Completed = {
			"You've freed us all from DIO's Vampiric influence. You truely are a reliable guy.",
			"But DIO is still out there plotting his revenge. Take him out - leave no trace of him remaining.",
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
	NextQuest = "TalkToCrimeBoss",
	RewardXP = 400,
	RewardItems = { "StandArrow" },
	RewardCash = 100,

	Objectives = {
		{ Type = "Defeat", Target = "Thug", Required = 5, Progress = 0, Completed = false },
	},

	TurnInNpc = "Giorno",

	Dialog = {
		Offer = {
			"These thugs — take down at least five.",
		},

		InProgress = {
			"Keep going. Take out a few more thugs — they should have what we’re looking for.",
		},

		TurnIn = {
			"You’ve helped clean up the city. Good job.",
			"Go Interogate the Thug's boss. Find his leader and go undercover. You'll do more good from within the gang.",
		},

		Completed = {
			"You’ve helped clean up the city. Good job.",
			"Go Interogate the Thug's boss. Find his leader and go undercover. You'll do more good from within the gang.",
		},
	},
}

---------------------------------------------------------------------
-- 5. DEFEAT CRIMINAL STAND USERS (Quest 5)
---------------------------------------------------------------------
QuestDefinitions.DefeatCriminalStandUsers = {
	Name = "Defeat Criminal Stand Users",

	Objectives = {
		{ Type = "Defeat", Target = "CriminalStandUser", Required = 3, Progress = 0, Completed = false },
	},

	NextQuest = { "TalkToDioPB1" },

	RewardXP = 4000,
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
--[[
QuestDefinitions.RobROBank = {
	Name = "Rob the RO Bank",

	Giver = "Jotaro", -- or an NPC who instructs the robbery

	Objectives = {
		{
			Type = "Interact",
			Target = "ROBankVault",
			Required = 1,
			Progress = 0,
			Completed = false,
			Text = "Steal the gold inside the vault",
		},
	},

	RewardXP = 3000,
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
]]

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
			"Hunt these wakling vampires in this very room. I have no use for them. Survive… and you may earn my respect.",
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

	Objectives = {
		{ Type = "Defeat", Target = "Vampire", Required = 3, Progress = 0, Completed = false },
	},

	RewardXP = 700,
	RewardCash = 20000,
	NextQuest = "DefeatAvdol1",

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
			"You're ready for the next stage of your initiation. Go talk to my loyal servant Avdol.",
			"He has sworn fealty to me, a completely loyal servant. You can learn much from him...",
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

	RewardXP = 10000,
	RewardItems = {},
	TurnInNpc = "DioPB",
	NextQuest = nil,

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

	RewardXP = 100000,
	RewardCash = 1000,
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
	Objectives = {
		{ Type = "Talk", Target = "Speedwagon", Completed = false },
	},
	RewardXP = 6000,
	TurnInNpc = "Speedwagon", -- Talking to him completes the quest
	RewardItems = {},
	RewardCash = 150,
	NextQuest = "DefeatVampires2", -- Or set to your next quest when ready
	Dialog = {
		Offer = {
			"Oi, you there! I saw ya infultrate DIO's gang and free my allies from a mile away!",
			"Name's Robert E. O. Speedwagon – ex-thug turned Joestar ally.",
			"You've got the fire of a proper fighter. The Joestars and I are glad to have someone like you on our side.",
			"Now it's time to turn the tables, chap. I've got the lowdown on vampires and worse lurkin' about.",
			"Defeat them and soon we'll bring DIO to justice once and for all!",
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
	RewardXP = 4000,
	RewardCash = 300,
	TurnInNpc = "Speedwagon",
	NextQuest = { "DefeatVampires2" },
	Dialog = {
		Offer = {
			"To proceed, you must fully awaken your Hamon. Talk to Baron Zeppeli to learn the breathing technique.",
			"Return when the ripple courses through your veins.",
		},
		InProgress = {
			"Talk to Baron Zeppeli to learn the breathing technique.",
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
	Objectives = {
		{ Type = "Defeat", Target = "EliteVampire", Required = 5, Progress = 0, Completed = false },
	},
	RewardXP = 5000,
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
	RewardXP = 22000,
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
	RewardXP = 35000,
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
	Objectives = {
		{ Type = "Talk", Target = "Emporio", Completed = false },
	},
	RewardXP = 12000,
	TurnInNpc = nil, -- Auto-completes on talk
	RewardItems = {},
	RewardCash = 150,
	NextQuest = "DefeatEscapedConvicts1", -- Leads to defeating convicts
	Dialog = {
		Offer = {
			"H-Hi... I'm Emporio. Thank you for freeing the Joestars and their allies. Perhaps it's not too late to defeat DIO afterall!",
			"Dangerous criminals have escaped the prison... these escaped convicts are everywhere!",
			"They're too dangerous. To let run free, but these corrupt cops won't do anything to stop it!",
			"Please defeat 8 of the convicts. I'll be hiding nearby!",
		},
		InProgress = {
			"This never triggers",
		},
		TurnIn = nil,
		Completed = {
			"Thank you for listening... Now go stop those convicts!",
			"Jolyne-san and the others are counting on us!",
		},
	},
}

---------------------------------------------------------------------
-- DEFEAT ESCAPED CONVICTS (Follow-up Quest)
---------------------------------------------------------------------
QuestDefinitions.DefeatEscapedConvicts1 = {
	Name = "Clear the Escaped Convicts",
	Description = "Defeat 8 escaped convicts to secure the area for Jolyne's breakout.",
	Objectives = {
		{ Type = "Defeat", Target = "EscapedConvict", Required = 8, Progress = 0, Completed = false },
	},
	RewardXP = 37000,
	RewardCash = 400,
	TurnInNpc = "Emporio",
	NextQuest = "TalkToJotaro1", -- End of this segment or link to Jolyne breakout quest later
	Dialog = {
		Offer = {
			"The convicts are strong... and they're not thinking straight.",
			"They broke out during the chaos—now the whole yard is dangerous.",
			"If we try to move like this, we'll get caught for sure.",
			"Can you defeat 8 of them? Then we'll be one step closer to keeping this city safe.",
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
			"Thank you for all the good work. By the way, Jotaro wanted to talk to you. It sounds serious.",
			"Go meet with him now - he's got a job for you.",
		},

		Completed = {
			"You got them all! The path is clear now.",
			"Thank you... People will be able to walk the streets safely thanks to you.",
		},
	},
}

QuestDefinitions.DefeatDIO = {
	Name = "End DIO's Reign",
	Description = "Face DIO and put an end to his tyranny once and for all. The fate of the world rests on this final battle.",
	Objectives = {
		{ Type = "Defeat", Target = "DIO", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 100000,
	RewardCash = 25000,
	RewardItems = "PurpleRokakaka",

	TurnInNpc = "Jotaro",

	NextQuest = nil, -- Final quest in the arc

	Dialog = {
		Offer = {
			"You freed us all from DIO's vampiric influence. You truely are a reliable guy.",
			"DIO's not like the others. You already know that.",
			"He'll keep coming until someone puts him down for good.",
			"All that fighting you've done... it led you here.",
			"Don't hold back. End this.",
		},
		InProgress = {
			"Stay sharp.",
			"DIO won't give you an opening twice.",
		},
		TurnIn = {
			"...You actually did it.",
			"DIO's finished.",
			"...Good.",
			"You did what had to be done.",
		},
		Completed = {
			"It's over.",
			"DIO's gone. That's all that matters.",
		},
	},
}

--[[
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
]]

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
			"You stand before me seeking purpose... and I may grant it.",
			"Avdol now serves under my will, his mind bound and his flames bent to me.",
			"Go to him. Observe him. Ensure that his loyalty remains... absolute.",
			"A servant who exists under my control has no room for doubt. Remember that.",
		},
		InProgress = {
			"Avdol is mine. His will, his power, his very soul.",
			"See that nothing disturbs that truth.",
		},
		TurnIn = {
			"You have returned.",
			"I trust Avdol carried out his role without issue. Of course... he would not dare fail me.",
			"You have done well to confirm what I already knew.",
			"Now, there is another I wish you to meet—Enrico Pucci.",
			"He is far more... enlightened than the others. Speak with him, and continue your service to me.",
		},
		Completed = {
			"Why do you linger?",
			"Enrico Pucci awaits you. Do not test my patience.",
		},
	},
}

---------------------------------------------------------------------
-- 11. TALK TO PUCCI (Quest 11)
---------------------------------------------------------------------
QuestDefinitions.TalkToPucci1 = {
	Name = "Talk to Pucci",
	Description = "Find Pucci and speak with him about the path to Heaven.",
	Objectives = {
		{ Type = "Talk", Target = "Pucci", Completed = false },
	},
	RewardXP = 1000,
	TurnInNpc = "Pucci", -- Auto-completes on talk
	RewardCash = 200,
	NextQuest = "DefeatHamonUsers1",
	Dialog = {
		Offer = {
			"So... you are the one Lord Dio has taken interest in.",
			"I am Enrico Pucci. I walk the path toward Heaven alongside him.",
			"There are those who cling to the light... practitioners of Hamon.",
			"They believe their sunlight-born power can oppose destiny itself.",
			"In truth, they are merely remnants of a fading era.",
			"Seek them out. Erase them. Let their final breaths affirm your devotion to Dio's will.",
		},
		InProgress = {
			"The light of Hamon is fleeting.",
			"Only those who embrace darkness will witness Heaven.",
		},
		TurnIn = {
			"I can feel it... the disturbance has quieted.",
			"The Hamon users have been silenced, just as fate intended.",
			"You act without hesitation. That is... reassuring.",
			"Continue down this path, and you may yet glimpse Heaven itself.",
		},
		Completed = {
			"Our path is absolute.",
			"Return to Lord Dio when you are ready to proceed further.",
		},
	},
}

---------------------------------------------------------------------
-- DEFEAT HAMON USERS (Refactored Quest)
---------------------------------------------------------------------
QuestDefinitions.DefeatHamonUsers1 = {
	Name = "Purge the Hamon Users",
	Description = "Defeat 3 Hamon users to eliminate threats to the Heaven plan.",
	Objectives = {
		{ Type = "Defeat", Target = "HamonUser", Required = 3, Progress = 0, Completed = false },
	},
	RewardXP = 12000,
	RewardCash = 800,
	RewardItems = { "Rokakaka" }, -- Unique JoJo-themed item
	TurnInNpc = "Pucci", -- Auto-completes on defeat
	NextQuest = "DefeatRohanKishibe1", -- Leads directly into the next quest
	Dialog = {
		Offer = {
			"There is a powerful clan of Hamon users who I wish for you to defeat.",
			"Do NOT train with them and learn their ways. However tempting their power may seem, it lies in the way of Lord DIO's plan.",
			"Remove them from the picutre, leaving no obstacle in our path.",
		},
		InProgress = {
			"This hamon clan is no laughing matter. They once nearly defeated Lord DIO himself.",
			"Without the ripple, the Joestars and their allies are reduced in power significantly.",
			"See that this truth remains intact.",
		},
		-- No TurnIn dialog (auto-complete)
		Completed = {
			"Good, the Hamon clan is defeated.",
			"All who oppose Lord Dio's influence will serve their role in the path to Heaven.",
			"You have done well to witness this for yourself.",
			"Continue forward. Destiny is already guiding your steps.",
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
	RewardXP = 15000,
	RewardCash = 1000,
	RewardItems = nil, -- Unique collectible item
	TurnInNpc = "Pucci", -- Auto-completes on defeat
	NextQuest = "DefeatKakyoin1", -- End of this mini-branch or link to more later
	Dialog = {
		Offer = {
			"You return... and I can sense your resolve has deepened.",
			"The path to Heaven demands more than strength—it requires understanding of those who stand before us.",
			"There is a man I wish for you to meet... Rohan Kishibe.",
			"A curious individual. His mind has already been brought under Lord Dio's influence.",
			"Go to him. Observe him closely, and ensure his devotion remains... undisturbed.",
			"Those touched by Dio's will must never stray from their purpose.",
		},
		InProgress = {
			"Rohan Kishibe is not like the others.",
			"Even so, a soul bound to Dio cannot escape its fate.",
			"See that this truth remains intact.",
		},
		TurnIn = {
			"You have returned.",
			"I trust Rohan remains aligned with Lord Dio's will.",
			"Good... everything proceeds exactly as it must.",
			"You continue to prove yourself reliable.",
			"Remain on this path, and you will come ever closer to understanding Heaven.",
			"Now, I'd like you to meet a man by the name of Kakyoin Noriaki... Seek him out and train alongside him.",
		},
		Completed = {
			"You have returned.",
			"I trust Rohan remains aligned with Lord Dio's will.",
			"Good... everything proceeds exactly as it must.",
			"You continue to prove yourself reliable.",
			"Remain on this path, and you will come ever closer to understanding Heaven.",
			"Now, I'd like you to meet a man by the name of Kakyoin Noriaki... Seek him out and train alongside him.",
		},
	},
}

QuestDefinitions.DefeatKakyoin1 = {
	Name = "Defeat Kakyoin Noriaki",
	Description = "Defeat the Kakyoin and hius Hierophant.",
	Objectives = {
		{ Type = "Defeat", Target = "KakyoinNoriaki", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 13000,
	RewardCash = 500,
	RewardItems = nil, -- Unique collectible item
	TurnInNpc = "Pucci", -- Auto-completes on defeat
	NextQuest = "DefeatOkuyasu1", -- End of this mini-branch or link to more later
	Dialog = {
		Offer = {
			"You continue to walk this path without hesitation... good.",
			"There is another servant of Lord Dio I wish for you to meet—Noriaki Kakyoin.",
			"His Stand is precise, calculated... a reflection of his mind.",
			"He, too, has been guided under Dio's will.",
			"Go to him. Observe his state, and ensure his loyalty remains unwavering.",
			"A servant must never drift from the gravity of Heaven.",
			"You continue to act in accordance with Lord Dio's will... admirable.",
		},
		InProgress = {
			"Kakyoin's resolve should be absolute.",
			"A will bound to Dio does not falter.",
			"See that nothing has... changed.",
		},
		TurnIn = {
			"You have returned.",
			"I trust Kakyoin remains as he should be—devoted, unquestioning.",
			"Good... everything continues to align with fate.",
			"You carry out your role with consistency. That is... valuable.",
			"Ensure that our friend Okuyasu remains on the righteous path as well.",
		},
		Completed = {
			"Kakyoin has already been accounted for.",
			"Do not lose focus. Our path cannot be delayed.",
		},
	},
}

QuestDefinitions.DefeatOkuyasu1 = {
	Name = "Defeat Okuyasu",
	Description = "Defeat the Kakyoin and hius Hierophant.",
	Objectives = {
		{ Type = "Defeat", Target = "OkuyasuNijimura", Required = 1, Progress = 0, Completed = false },
	},
	RewardXP = 14000,
	RewardCash = 500,
	RewardItems = { "StandArrow" }, -- Unique collectible item
	TurnInNpc = "Pucci", -- Auto-completes on defeat
	NextQuest = "DefeatJotaro1", -- End of this mini-branch or link to more later
	Dialog = {
		Offer = {
			"There is another I wish for you to meet—Okuyasu Nijimura.",
			"His power is... crude, yet undeniably destructive.",
			"He has been brought under Dio's influence, his strength now serving a higher purpose.",
			"Go to him. Observe his condition, and ensure his loyalty remains intact.",
			"Even the simplest mind must not stray once it has been bound to destiny.",
		},
		InProgress = {
			"Okuyasu's power is absolute when guided.",
			"A servant of Dio does not question—he obeys.",
			"See that his path remains unchanged.",
		},
		TurnIn = {
			"Welcome back my ally. I trust that Okuyasu is still in line.",
			"You continue to serve the path to Heaven faithfully.",
			"Now, the pawn lord DIO values the most... Jotaro Kujo. Go to him and your training will be complete.",
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
			"At last... we come to one of great importance.",
			"Jotaro Kujo—the one who once opposed Lord Dio—now stands beneath his will.",
			"Such a powerful soul, bent to a greater purpose... it is almost poetic.",
			"You will go to him.",
			"Observe him carefully, and ensure his loyalty remains absolute.",
			"A being of his strength must never be allowed to stray, even for a moment.",
		},
		InProgress = {
			"Jotaro Kujo's will was once unbreakable.",
			"Now, it exists only to serve.",
			"See that this truth has not changed.",
		},
		TurnIn = {
			"You have returned.",
			"I trust Jotaro remains bound, his power fully aligned with Lord Dio's will.",
			"Good... then even the strongest of the old world has accepted his place.",
			"You have done well to confirm this.",
			"There are still matters that require your attention. Seek out my associate—he will guide you further.",
		},
		Completed = {
			"Jotaro Kujo has already been accounted for.",
			"Do not linger. Our path toward Heaven continues.",
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
			"So you are DIO's new acolyte? I hope you are a fellow patriot.",
			"Yes? Very good. DIO has recently captured a new assistant whom you have yet to meet. Further your training and seek him out.",
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
	RewardXP = 18000,
	RewardCash = 10000,
	RewardItems = { "PurpleRokakaka" }, -- Unique JoJo-themed item
	TurnInNpc = "FunnyValentine", -- Auto-completes on defeat
	NextQuest = "DefeatPolice1", -- End of this branch or link to more (e.g., "TalkToDio1")
	Dialog = {
		Offer = {
			"You stand before the President of the United States... Funny Valentine.",
			"I act not for personal gain, but for the absolute prosperity of this nation.",
			"There are individuals who now stand under Lord Dio's influence—key assets in the unfolding order.",
			"One in particular is called Giorno Giovanna.",
			"A young man of unusual potential... now aligned with forces beyond his understanding.",
			"Go to him. Observe his condition, and ensure his alignment with this greater direction.",
			"Every piece must remain in its rightful place for the good of America... and the world.",
		},
		InProgress = {
			"Giorno Giovanna is no ordinary individual.",
			"Even so, he now serves a purpose greater than himself.",
			"Confirm that this remains true.",
		},
		TurnIn = {
			"You have returned.",
			"So Giorno continues to move as expected under Lord Dio's influence... good.",
			"Everything proceeds according to a larger design.",
			"You have proven yourself capable of handling matters of national importance.",
			"Continue forward. There are greater alignments yet to be secured.",
		},
		Completed = {
			"Giorno Giovanna has already been accounted for.",
			"America's path remains unchanged. Stay the course.",
		},
	},
}

--[[
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
]]

QuestDefinitions.DefeatPolice1 = {
	Name = "Purge the Corrupt Cops",
	Description = "Defeat 8 Corrupt Cops in Shanty Town to eliminate threats after recovering the gold.",
	Objectives = {
		{ Type = "Defeat", Target = "CorruptCop", Required = 8, Progress = 0, Completed = false },
	},
	RewardXP = 35000,
	RewardCash = 800,
	RewardItems = { "PurpleRokakaka" }, -- Unique JoJo-themed item
	TurnInNpc = "FunnyValentine",
	NextQuest = "TalkToSpeedwagon1", -- End of chain or link to next
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

--[[
QuestDefinitions.TalkToPucci2 = {
	Name = "Talk to Pucci",
	Description = "Find Pucci and speak with him about the path to Heaven.",
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
]]

--end of new quests
QuestDefinitions.DefeatThugsRepeatable = {
	Name = "Stop the Thugs",
	Description = "Defeat 5 thugs",

	Repeatable = true, -- 🔹 NEW

	Giver = "Josuke",
	RewardCash = 1500,
	RewardXP = 6000,

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
	RewardXP = 8000,

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
	RewardXP = 40000,

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
	RewardXP = 60000,

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

--new islands quests
QuestDefinitions.DefeatBanditsRepeatable = {
	Name = "Bandits",
	Description = "Defeat 5 Bandits",

	Repeatable = true, -- 🔹 NEW

	Giver = "Josuke2",
	RewardCash = 300,
	RewardXP = 1500,
	MinimumLevel = 1,

	Objectives = {
		{ Type = "Defeat", Target = "Bandit", Required = 5, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatMonkeysRepeatable = {
	Name = "Monkeys",
	Description = "Defeat 5 Monkeys",

	Repeatable = true, -- 🔹 NEW

	Giver = "Jotaro2",
	RewardCash = 500,
	RewardXP = 2000,
	MinimumLevel = 10,

	Objectives = {
		{ Type = "Defeat", Target = "Monkey", Required = 5, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatGorillasRepeatable = {
	Name = "Gorillas",
	Description = "Defeat 8 Gorillas",

	Repeatable = true, -- 🔹 NEW

	Giver = "Jotaro2",
	RewardCash = 1000,
	RewardXP = 3000,
	MinimumLevel = 20,

	Objectives = {
		{ Type = "Defeat", Target = "Gorilla", Required = 8, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatAvdolRepeatable = {
	Name = "Avdol",
	Description = "Defeat Avdol",

	Repeatable = true, -- 🔹 NEW

	Giver = "Jotaro2",
	RewardCash = 2000,
	RewardXP = 7000,
	MinimumLevel = 25,

	Objectives = {
		{ Type = "Defeat", Target = "AvdolFighter", Required = 1, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatPirateRepeatable = {
	Name = "Pirate",
	Description = "Defeat 5 Pirates",

	Repeatable = true, -- 🔹 NEW

	Giver = "Giorno2",
	RewardCash = 1000,
	RewardXP = 3000,
	MinimumLevel = 30,

	Objectives = {
		{ Type = "Defeat", Target = "Pirate", Required = 5, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatBruteRepeatable = {
	Name = "Brute",
	Description = "Defeat 8 Brutes",

	Repeatable = true, -- 🔹 NEW

	Giver = "Giorno2",
	RewardCash = 1700,
	RewardXP = 5000,
	MinimumLevel = 35,

	Objectives = {
		{ Type = "Defeat", Target = "Brute", Required = 8, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatRohanRepeatable = {
	Name = "Rohan",
	Description = "Defeat Rohan",

	Repeatable = true, -- 🔹 NEW

	Giver = "Giorno2",
	RewardCash = 2200,
	RewardXP = 6000,
	MinimumLevel = 40,

	Objectives = {
		{ Type = "Defeat", Target = "RohanKishibe", Required = 1, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatDesertBanditRepeatable = {
	Name = "DesertBandit",
	Description = "Defeat 5 Desert Bandits",

	Repeatable = true, -- 🔹 NEW

	Giver = "Jolyne2",
	RewardCash = 1700,
	RewardXP = 8000,
	MinimumLevel = 45,

	Objectives = {
		{ Type = "Defeat", Target = "DesertBandit", Required = 5, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatDesertRaiderRepeatable = {
	Name = "DesertRaider",
	Description = "Defeat 8 Desert Raiders",

	Repeatable = true, -- 🔹 NEW

	Giver = "Jolyne2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 50,

	Objectives = {
		{ Type = "Defeat", Target = "DesertRaider", Required = 8, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatKakyoinRepeatable = {
	Name = "Avdol",
	Description = "Defeat Avdol",

	Repeatable = true, -- 🔹 NEW

	Giver = "Jolyne2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 55,

	Objectives = {
		{ Type = "Defeat", Target = "KakyoinNoriaki", Required = 1, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatSnowBanditRepeatable = {
	Name = "Snow Bandit",
	Description = "Defeat 5 Snow Bandits",

	Repeatable = true, -- 🔹 NEW

	Giver = "Kakyoin2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 60,

	Objectives = {
		{ Type = "Defeat", Target = "SnowBandit", Required = 5, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatIceCaptainRepeatable = {
	Name = "Ice Captain",
	Description = "Defeat 8 Ice Captains",

	Repeatable = true, -- 🔹 NEW

	Giver = "Kakyoin2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 65,

	Objectives = {
		{ Type = "Defeat", Target = "IceCaptain", Required = 8, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatOkuyasuRepeatable = {
	Name = "Okuyasu",
	Description = "Defeat Okuyasu",

	Repeatable = true, -- 🔹 NEW

	Giver = "Kakyoin2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 70,

	Objectives = {
		{ Type = "Defeat", Target = "OkuyasuNijimura", Required = 1, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatStoneGolemRepeatable = {
	Name = "Stone Golem",
	Description = "Defeat 5 Stone Golems",

	Repeatable = true, -- 🔹 NEW

	Giver = "FunnyValentine2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 75,

	Objectives = {
		{ Type = "Defeat", Target = "StoneGolem", Required = 5, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatLavaGolemRepeatable = {
	Name = "Lava Golem",
	Description = "Defeat 8 Lava Golem",

	Repeatable = true, -- 🔹 NEW

	Giver = "FunnyValentine2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 80,

	Objectives = {
		{ Type = "Defeat", Target = "LavaGolem", Required = 8, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatDiavoloRepeatable = {
	Name = "Diavolo",
	Description = "Defeat Diavolo",

	Repeatable = true, -- 🔹 NEW

	Giver = "FunnyValentine2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 85,

	Objectives = {
		{ Type = "Defeat", Target = "Diavolo", Required = 1, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatRedSailorRepeatable = {
	Name = "Red Sailor",
	Description = "Defeat 5 Red Sailor",

	Repeatable = true, -- 🔹 NEW

	Giver = "Pucci2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 90,

	Objectives = {
		{ Type = "Defeat", Target = "RedSailor", Required = 5, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatBlueSailorRepeatable = {
	Name = "Blue Sailor",
	Description = "Defeat 8 Blue Sailors",

	Repeatable = true, -- 🔹 NEW

	Giver = "Pucci2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 95,

	Objectives = {
		{ Type = "Defeat", Target = "BlueSailor", Required = 8, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatGiornoRepeatable = {
	Name = "Giorno",
	Description = "Defeat Giorno",

	Repeatable = true, -- 🔹 NEW

	Giver = "Pucci2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 100,

	Objectives = {
		{ Type = "Defeat", Target = "Giorno", Required = 1, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatSkyBanditRepeatable = {
	Name = "Sky Bandit",
	Description = "Defeat 5 Sky Bandits",

	Repeatable = true, -- 🔹 NEW

	Giver = "Speedwagon2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 105,

	Objectives = {
		{ Type = "Defeat", Target = "SkyBandit", Required = 5, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatSkyFighterRepeatable = {
	Name = "Sky fighter",
	Description = "Defeat 8 Sky Fighters",

	Repeatable = true, -- 🔹 NEW

	Giver = "Speedwagon2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 110,

	Objectives = {
		{ Type = "Defeat", Target = "SkyFighter", Required = 8, Progress = 0, Completed = false },
	},
}

QuestDefinitions.DefeatDIORepeatable = {
	Name = "DIO",
	Description = "Defeat DIO",

	Repeatable = true, -- 🔹 NEW

	Giver = "Speedwagon2",
	RewardCash = 1500,
	RewardXP = 2000,
	MinimumLevel = 115,

	Objectives = {
		{ Type = "Defeat", Target = "DIO", Required = 1, Progress = 0, Completed = false },
	},
}

-- Auto-generate a one-time "Talk to NPC" unlock quest for every NPC that has at
-- least one Repeatable quest with a MinimumLevel. The quest is given to a player
-- the first time their level reaches that threshold, directing them to the NPC.
-- Only one unlock quest is created per NPC (keyed to the lowest MinimumLevel among
-- that NPC's repeatable quests).
do
	local npcMinLevel = {}
	for _, def in pairs(QuestDefinitions) do
		if def.Repeatable and def.MinimumLevel and def.Giver then
			local current = npcMinLevel[def.Giver]
			if not current or def.MinimumLevel < current then
				npcMinLevel[def.Giver] = def.MinimumLevel
			end
		end
	end

	for npcName, minLevel in pairs(npcMinLevel) do
		QuestDefinitions["Unlock_" .. npcName] = {
			Name = "Talk to " .. npcName,
			Description = npcName .. " has new quests available.",
			Giver = npcName,
			MinimumLevel = minLevel,
			_isUnlockQuest = true,
			Objectives = {
				{ Type = "Talk", Target = npcName, Completed = false },
			},
			Dialog = {
				Offer = { npcName .. " has new quests available for you!" },
				InProgress = { "I've got work for you — come find me!" },
			},
		}
	end
end

return QuestDefinitions
