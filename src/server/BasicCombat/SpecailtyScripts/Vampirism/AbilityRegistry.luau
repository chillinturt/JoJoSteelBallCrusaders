local Vampirism = require(script.Parent:WaitForChild("Vampirism"))

local AbilityRegistry = {}

--------------------------------------------------------------------
-- Ability Types (Sent to Client)
-- Types: "Press", "Hold", "Toggle"
--------------------------------------------------------------------
AbilityRegistry.AbilityTypes = {
	[1] = "Press",
	[2] = "Press",
	[3] = "Press",
	[4] = "Press",
}

--------------------------------------------------------------------
-- Ability 1 - FlameShot (Press)
--------------------------------------------------------------------
AbilityRegistry[1] = {
	Name = "VaporizationFreeze",
	Type = "Press",
	Cooldown = 10,
	Execute = function(player)
		local character = player.Character
		if character then
			Vampirism.VaporizationFreeze(character)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 2 - RedBind (Press)
--------------------------------------------------------------------
AbilityRegistry[2] = {
	Name = "DivineDrink",
	Type = "Press",
	Cooldown = 8,
	Execute = function(player)
		local character = player.Character
		if character then
			Vampirism.DivineDrink(character)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 3 - CrossfireHurricane (Press)
--------------------------------------------------------------------
AbilityRegistry[3] = {
	Name = "SpaceRipperStingyEyes",
	Type = "Press",
	Cooldown = 8,
	Execute = function(player)
		local character = player.Character
		if character then
			Vampirism.SpaceRipperStingyEyes(character)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 4 - Hellfire (Press)
--------------------------------------------------------------------
AbilityRegistry[4] = {
	Name = "BloodRush",
	Type = "Press",
	Cooldown = 8,
	Execute = function(player)
		local character = player.Character
		if character then
			Vampirism.BloodRush(character)
		end
	end,
}

return AbilityRegistry
