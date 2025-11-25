local Tusk = require(script.Parent:WaitForChild("Tusk"))

-- Ability Registry for King Carmine Stand
-- This defines cooldowns, names, and how to execute each ability.
-- No RemoteEvents belong here. No validation belongs here.
-- Only mappings from abilityNumber → execution function.

local AbilityRegistry = {
	------------------------------------------------------------------------
	-- Ability 1: Chop
	------------------------------------------------------------------------
	[1] = {
		Name = "NailShot",
		Cooldown = 6,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				Tusk.NailShot(character)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 2: Splatter
	------------------------------------------------------------------------
	[2] = {
		Name = "GuidedNail",
		Cooldown = 6,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				Tusk.GuidedNail(character)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 3: Teleport
	------------------------------------------------------------------------
	[3] = {
		Name = "SpinWormhole",
		Cooldown = 6,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				Tusk.SpinWormhole(character)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 4: Time Erase
	------------------------------------------------------------------------
	[4] = {
		Name = "InfiniteRotation",
		Cooldown = 28,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				Tusk.InfiniteRotation(character)
			end
		end,
	},
}

return AbilityRegistry
