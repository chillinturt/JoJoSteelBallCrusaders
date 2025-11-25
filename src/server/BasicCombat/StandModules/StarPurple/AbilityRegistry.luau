local StarPurple = require(script.Parent:WaitForChild("StarPurple"))

-- Ability Registry for King Carmine Stand
-- This defines cooldowns, names, and how to execute each ability.
-- No RemoteEvents belong here. No validation belongs here.
-- Only mappings from abilityNumber → execution function.

local AbilityRegistry = {
	------------------------------------------------------------------------
	-- Ability 1: EmeraldSplash
	------------------------------------------------------------------------
	[1] = {
		Name = "StarFinger",
		Cooldown = 12,
		Execute = function(standModel, player)
			StarPurple.StarFinger(standModel)
		end,
	},

	------------------------------------------------------------------------
	-- Ability 2: Splatter
	------------------------------------------------------------------------
	[2] = {
		Name = "MachOra",
		Cooldown = 10,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				StarPurple.onMachOraRequested(character)
				StarPurple.onMachOra2Requested(character)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 3: EmeraldBarrier
	------------------------------------------------------------------------
	[3] = {
		Name = "GroundPund",
		Cooldown = 12,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				StarPurple.GroundPound(standModel)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 4: TwentyMeterBarrier
	------------------------------------------------------------------------
	[4] = {
		Name = "TimeStop",
		Cooldown = 40,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				StarPurple.TimeStop(standModel)
			end
		end,
	},
}

return AbilityRegistry
