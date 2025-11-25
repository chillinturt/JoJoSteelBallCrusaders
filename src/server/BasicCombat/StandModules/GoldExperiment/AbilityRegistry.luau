local GoldExperiment = require(script.Parent:WaitForChild("GoldExperiment"))

-- Ability Registry for King Carmine Stand
-- This defines cooldowns, names, and how to execute each ability.
-- No RemoteEvents belong here. No validation belongs here.
-- Only mappings from abilityNumber → execution function.

local AbilityRegistry = {
	------------------------------------------------------------------------
	-- Ability 1: Chop
	------------------------------------------------------------------------
	[1] = {
		Name = "LifeOverflow",
		Cooldown = 12,
		Execute = function(standModel, player)
			-- standModel is passed directly from the RemoteEvent handler
			GoldExperiment.LifeOverflow(standModel)
		end,
	},

	------------------------------------------------------------------------
	-- Ability 2: Splatter
	------------------------------------------------------------------------
	[2] = {
		Name = "TreeOfLife",
		Cooldown = 10,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				GoldExperiment.TreeOfLife(character)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 3: Teleport
	------------------------------------------------------------------------
	[3] = {
		Name = "EagleStrike",
		Cooldown = 10,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				GoldExperiment.EagleStrike(character)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 4: Time Erase
	------------------------------------------------------------------------
	[4] = {
		Name = "TimeErase",
		Cooldown = 45,
		Execute = function(standModel, player)
			--GoldExperiment.TimeErase(standModel)
		end,
	},
}

return AbilityRegistry
