local TheWorld = require(script.Parent:WaitForChild("TheWorld"))

local AbilityRegistry = {}

--------------------------------------------------------------------
-- Ability Types (sent to the client)
-- All of these abilities are "Press"
--------------------------------------------------------------------
AbilityRegistry.AbilityTypes = {
	[1] = "Press",
	[2] = "Press",
	[3] = "Press",
	[4] = "Press",
}

--------------------------------------------------------------------
-- Ability 1 - Erase
--------------------------------------------------------------------
AbilityRegistry[1] = {
	Name = "ThrowKnives",
	Type = "Press",
	Cooldown = 7,
	Execute = function(standModel, player)
		TheWorld.ThrowKnives(standModel)
	end,
}

--------------------------------------------------------------------
-- Ability 2 - VoidShielding
--------------------------------------------------------------------
AbilityRegistry[2] = {
	Name = "BlazingStrike",
	Type = "Press",
	Cooldown = 9,
	Execute = function(standModel, player)
		TheWorld.BlazingStrike(standModel)
	end,
}

--------------------------------------------------------------------
-- Ability 3 - TearSpace
--------------------------------------------------------------------
AbilityRegistry[3] = {
	Name = "KickBarrage",
	Type = "Press",
	Cooldown = 10,
	Execute = function(standModel, player)
		TheWorld.KickBarrage(standModel)
	end,
}

--------------------------------------------------------------------
-- Ability 4 - LastStand
--------------------------------------------------------------------
AbilityRegistry[4] = {
	Name = "TimeStop",
	Type = "Press",
	Cooldown = 35,
	Execute = function(standModel, player)
		local character = standModel.Parent
		if character then
			TheWorld.TimeStop(character)
		end
	end,
}

return AbilityRegistry
