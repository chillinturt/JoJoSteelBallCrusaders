local Hamon = require(script.Parent:WaitForChild("Hamon"))

local AbilityRegistry = {}

--------------------------------------------------------------------
-- Ability Types (Sent to Client)
-- Types: "Press", "Hold", "Toggle"
--------------------------------------------------------------------
AbilityRegistry.AbilityTypes = {
	[1] = "Hold",
	[2] = "Press",
	[3] = "Press",
	[4] = "Press",
}

--------------------------------------------------------------------
-- Ability 1 - FlameShot (Press)
--------------------------------------------------------------------
AbilityRegistry[1] = {
	Name = "SunlightYellow",
	Type = "Hold", -- << Add this
	Cooldown = 10, -- handled internally
	ExecuteStart = function(player)
		local character = player.Character
		if character then
			Hamon.StartSunlightYellow(character)
		end
	end,
	ExecuteStop = function(player)
		local character = player.Character
		if character then
			Hamon.StopSunlightYellow(character)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 2 - RedBind (Press)
--------------------------------------------------------------------
AbilityRegistry[2] = {
	Name = "DivineDrink",
	Type = "Press",
	Cooldown = 8,
	Execute = function(player)
		local character = player.Character
		if character then
			Hamon.ZoomPunch(character)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 3 - CrossfireHurricane (Press)
--------------------------------------------------------------------
AbilityRegistry[3] = {
	Name = "SpaceRipperStingyEyes",
	Type = "Press",
	Cooldown = 8,
	Execute = function(player)
		local character = player.Character
		if character then
			Hamon.BubbleCutter(character)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 4 - Hellfire (Press)
--------------------------------------------------------------------
AbilityRegistry[4] = {
	Name = "BloodRush",
	Type = "Press",
	Cooldown = 8,
	Execute = function(player)
		local character = player.Character
		if character then
			Hamon.LifeForceAura(character)
		end
	end,
}

return AbilityRegistry
