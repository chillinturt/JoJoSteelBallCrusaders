local ThatHand = require(script.Parent:WaitForChild("ThatHand"))

-- Ability Registry for King Carmine Stand
-- This defines cooldowns, names, and how to execute each ability.
-- No RemoteEvents belong here. No validation belongs here.
-- Only mappings from abilityNumber → execution function.

local AbilityRegistry = {
	------------------------------------------------------------------------
	-- Ability 1: Chop
	------------------------------------------------------------------------
	[1] = {
		Name = "Erase",
		Cooldown = 8,
		Execute = function(standModel, player)
			-- standModel is passed directly from the RemoteEvent handler
			ThatHand.Erase(standModel)
		end,
	},

	------------------------------------------------------------------------
	-- Ability 2: Splatter
	------------------------------------------------------------------------
	[2] = {
		Name = "VoidShielding",
		Cooldown = 16,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				ThatHand.VoidShielding(character)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 3: Teleport
	------------------------------------------------------------------------
	[3] = {
		Name = "TearSpace",
		Cooldown = 12,
		Execute = function(standModel, player)
			ThatHand.TearSpace(standModel)
		end,
	},

	------------------------------------------------------------------------
	-- Ability 4: Time Erase
	------------------------------------------------------------------------
	[4] = {
		Name = "LastStand",
		Cooldown = 28,
		Execute = function(standModel, player)
			ThatHand.LastStand(standModel)
		end,
	},
}

return AbilityRegistry
