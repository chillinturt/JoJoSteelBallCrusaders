local KingCarmine = require(script.Parent:WaitForChild("KingCarmine"))

-- Ability Registry for King Carmine Stand
-- This defines cooldowns, names, and how to execute each ability.
-- No RemoteEvents belong here. No validation belongs here.
-- Only mappings from abilityNumber → execution function.

local AbilityRegistry = {
	------------------------------------------------------------------------
	-- Ability 1: Chop
	------------------------------------------------------------------------
	[1] = {
		Name = "Chop",
		Cooldown = 10,
		Execute = function(standModel, player)
			-- standModel is passed directly from the RemoteEvent handler
			KingCarmine.Chop(standModel)
		end,
	},

	------------------------------------------------------------------------
	-- Ability 2: Splatter
	------------------------------------------------------------------------
	[2] = {
		Name = "Splatter",
		Cooldown = 12,
		Execute = function(standModel, player)
			KingCarmine.Splatter(standModel)
		end,
	},

	------------------------------------------------------------------------
	-- Ability 3: Teleport
	------------------------------------------------------------------------
	[3] = {
		Name = "Teleport",
		Cooldown = 12,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				KingCarmine.Teleport(character)
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
			KingCarmine.TimeErase(standModel)
		end,
	},
}

return AbilityRegistry
