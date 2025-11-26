local KingCarmine = require(script.Parent:WaitForChild("KingCarmine"))

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
-- Ability 1 - Chop (Press)
--------------------------------------------------------------------
AbilityRegistry[1] = {
	Name = "Chop",
	Type = "Press",
	Cooldown = 10,
	Execute = function(standModel, player)
		KingCarmine.Chop(standModel)
	end,
}

--------------------------------------------------------------------
-- Ability 2 - Splatter (Press)
--------------------------------------------------------------------
AbilityRegistry[2] = {
	Name = "Splatter",
	Type = "Press",
	Cooldown = 12,
	Execute = function(standModel, player)
		KingCarmine.Splatter(standModel)
	end,
}

--------------------------------------------------------------------
-- Ability 3 - Teleport (Press)
--------------------------------------------------------------------
AbilityRegistry[3] = {
	Name = "Teleport",
	Type = "Press",
	Cooldown = 12,
	Execute = function(standModel, player)
		local character = standModel.Parent
		if character then
			KingCarmine.Teleport(character)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 4 - TimeErase (Press)
--------------------------------------------------------------------
AbilityRegistry[4] = {
	Name = "TimeErase",
	Type = "Press",
	Cooldown = 45,
	Execute = function(standModel, player)
		KingCarmine.TimeErase(standModel)
	end,
}

return AbilityRegistry
