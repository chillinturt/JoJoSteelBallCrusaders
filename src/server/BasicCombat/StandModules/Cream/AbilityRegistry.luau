local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cream = require(script.Parent:WaitForChild("Cream"))
local CooldownUpdateEvent = ReplicatedStorage.Shared.BasicCombat.UI:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))

-- ====================================================================
-- EagleStrike custom state
-- ====================================================================
local COOLDOWN_TIME = 10

local lastEagleUse = {} -- player → tick() of launch OR redirect
local eagleFollowup = {} -- player → tick() when redirect expires

-- ====================================================================
-- Registry
-- ====================================================================
local AbilityRegistry = {}

--------------------------------------------------------------------
-- Ability Types (all Press)
--------------------------------------------------------------------
AbilityRegistry.AbilityTypes = {
	[1] = "Press",
	[2] = "Press",
	[3] = "Press", -- EagleStrike 2-stage
	[4] = "Press",
}

--------------------------------------------------------------------
-- Ability 1 - LifeOverflow
--------------------------------------------------------------------
AbilityRegistry[1] = {
	Name = "VoidLeap",
	Type = "Press",
	Cooldown = 12,
	Execute = function(standModel, player)
		Cream.LifeOverflow(standModel)
	end,
}

--------------------------------------------------------------------
-- Ability 2 - VoidDive
--------------------------------------------------------------------
AbilityRegistry[2] = {
	Name = "VoidRush",
	Type = "Press",
	Cooldown = 10,
	Execute = function(standModel, player)
		local char = standModel.Parent
		if char then
			Cream.VoidDive(char)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 3 - EagleStrike (Launch → Redirect)
--------------------------------------------------------------------
AbilityRegistry[3] = {
	Name = "Erasing",
	Type = "Press",
	Cooldown = 10,
	Execute = function(standModel, player)
		local char = standModel.Parent
		if char then
			Cream.VoidDive(char)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 4 - TimeErase
--------------------------------------------------------------------
AbilityRegistry[4] = {
	Name = "CarnivorousTrap",
	Type = "Press",
	Cooldown = 23,
	Execute = function(standModel, player)
		local char = standModel.Parent
		if char then
			Cream.CarnivorousTrap(char)
		end
	end,
}

return AbilityRegistry
