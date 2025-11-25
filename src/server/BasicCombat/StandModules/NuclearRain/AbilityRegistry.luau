local NuclearRain = require(script.Parent:WaitForChild("NuclearRain"))

-- Ability Registry for King Carmine Stand
-- This defines cooldowns, names, and how to execute each ability.
-- No RemoteEvents belong here. No validation belongs here.
-- Only mappings from abilityNumber → execution function.

local AbilityRegistry = {
	------------------------------------------------------------------------
	-- Ability 1: EmeraldSplash
	------------------------------------------------------------------------
	[1] = {
		Name = "TorrentialDownpour",
		Cooldown = 1,
		Execute = function(standModel, player)
			NuclearRain.StartTorrentialDownpour(standModel)
		end,
	},

	------------------------------------------------------------------------
	-- Ability 2: Splatter
	------------------------------------------------------------------------
	[2] = {
		Name = "HeavyRaindrop",
		Cooldown = 8,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				NuclearRain.HeavyRaindrop(character)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 3: EmeraldBarrier
	------------------------------------------------------------------------
	[3] = {
		Name = "HeavyRaindrop",
		Cooldown = 8,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				--NuclearRain.HeavyRaindrop(standModel)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 4: TwentyMeterBarrier
	------------------------------------------------------------------------
	[4] = {
		Name = "Hellfire",
		Cooldown = 20,
		Execute = function(standModel, player)
			--NuclearRain.Hellfire(standModel)
		end,
	},
}

return AbilityRegistry
