local NuclearRain = require(script.Parent:WaitForChild("NuclearRain"))

local AbilityRegistry = {}

--------------------------------------------------------------------
-- Ability Types (Sent to Client)
-- Types: "Press", "Hold", "Toggle"
--------------------------------------------------------------------
AbilityRegistry.AbilityTypes = {
	[1] = "Toggle",
	[2] = "Press",
	[3] = "Press", -- unfinished
	[4] = "Press", -- unfinished
}

--------------------------------------------------------------------
-- Ability 1 - TorrentialDownpour (Toggle)
--------------------------------------------------------------------
AbilityRegistry[1] = {
	Name = "TorrentialDownpour",
	Type = "Toggle",
	EndlagCancel = true,
	Cooldown = 1,
	ExecuteStart = function(standModel, player)
		NuclearRain.StartTorrentialDownpour(standModel)
	end,
	ExecuteStop = function(standModel, player)
		NuclearRain.StopTorrentialDownpour(standModel)
	end,
}

--------------------------------------------------------------------
-- Ability 2 - HeavyRaindrop (Press)
--------------------------------------------------------------------
AbilityRegistry[2] = {
	Name = "HeavyRaindrop",
	Type = "Press",
	EndlagCancel = true,
	Cooldown = 8,
	Execute = function(standModel, player)
		local character = standModel.Parent
		if character then
			NuclearRain.HeavyRaindrop(character)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 3 & 4 - Unfinished
--------------------------------------------------------------------

AbilityRegistry[3] = {
	Name = "ExpelBarrier",
	Type = "Press",
	Cooldown = 8,
	Execute = function(standModel, player)
		local character = standModel.Parent
		if character then
			-- NuclearRain.HeavyRaindrop(standModel)
		end
	end,
}

AbilityRegistry[4] = {
	Name = "RainCage",
	Type = "Press",
	Cooldown = 20,
	Execute = function(standModel, player)
		-- NuclearRain.Hellfire(standModel)
	end,
}

return AbilityRegistry
