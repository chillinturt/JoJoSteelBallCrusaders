local MagiciansRed = require(script.Parent:WaitForChild("MagiciansRed"))

-- Ability Registry for King Carmine Stand
-- This defines cooldowns, names, and how to execute each ability.
-- No RemoteEvents belong here. No validation belongs here.
-- Only mappings from abilityNumber → execution function.

local AbilityRegistry = {
	------------------------------------------------------------------------
	-- Ability 1: FlameShot
	------------------------------------------------------------------------
	[1] = {
		Name = "FlameShot",
		Cooldown = 3,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				MagiciansRed.FlameShot(character)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 2: RedBind
	------------------------------------------------------------------------
	[2] = {
		Name = "RedBind",
		Cooldown = 8,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				MagiciansRed.RedBind(standModel)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 2: CrossfireHurricane
	------------------------------------------------------------------------
	[3] = {
		Name = "CrossfireHurricane",
		Cooldown = 20,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				MagiciansRed.CrossfireHurricane(character)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 4: TwentyMeterBarrier
	------------------------------------------------------------------------
	[4] = {
		Name = "Hellfire",
		Cooldown = 25,
		Execute = function(standModel, player)
			MagiciansRed.Hellfire(standModel)
		end,
	},
}

return AbilityRegistry
