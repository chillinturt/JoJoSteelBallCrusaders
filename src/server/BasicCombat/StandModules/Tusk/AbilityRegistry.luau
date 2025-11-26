local Tusk = require(script.Parent:WaitForChild("Tusk"))

local AbilityRegistry = {}

--------------------------------------------------------------------
-- Ability Types (sent to client)
-- All abilities are Press type
--------------------------------------------------------------------
AbilityRegistry.AbilityTypes = {
	[1] = "Press",
	[2] = "Press",
	[3] = "Press",
	[4] = "Press",
}

--------------------------------------------------------------------
-- Ability 1 - NailShot
--------------------------------------------------------------------
AbilityRegistry[1] = {
	Name = "NailShot",
	Type = "Press",
	Cooldown = 6,
	Execute = function(standModel, player)
		local character = standModel.Parent
		if character then
			Tusk.NailShot(character)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 2 - GuidedNail
--------------------------------------------------------------------
AbilityRegistry[2] = {
	Name = "GuidedNail",
	Type = "Press",
	Cooldown = 6,
	Execute = function(standModel, player)
		local character = standModel.Parent
		if character then
			Tusk.GuidedNail(character)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 3 - SpinWormhole
--------------------------------------------------------------------
AbilityRegistry[3] = {
	Name = "SpinWormhole",
	Type = "Press",
	Cooldown = 6,
	Execute = function(standModel, player)
		local character = standModel.Parent
		if character then
			Tusk.SpinWormhole(character)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 4 - InfiniteRotation
--------------------------------------------------------------------
AbilityRegistry[4] = {
	Name = "InfiniteRotation",
	Type = "Press",
	Cooldown = 28,
	Execute = function(standModel, player)
		local character = standModel.Parent
		if character then
			Tusk.InfiniteRotation(character)
		end
	end,
}

return AbilityRegistry
