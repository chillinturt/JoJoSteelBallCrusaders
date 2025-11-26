local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StarPurple = require(script.Parent:WaitForChild("StarPurple"))
local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")
local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))

-- Track MachOra cooldown & 2-second follow-up window
local lastMachOraUseTime = {} -- player -> tick()
local recentMachOra = {} -- player -> tick() + 2 seconds

local COOLDOWN_TIME = 10
local FOLLOWUP_WINDOW = 2
local AbilityRegistry = {}

--------------------------------------------------------------------
-- Ability Types (Sent to Client)
-- Types: "Press", "Hold", "Toggle"
--------------------------------------------------------------------
AbilityRegistry.AbilityTypes = {
	[1] = "Press",
	[2] = "Press",
	[3] = "Press",
	[4] = "Press",
}

--------------------------------------------------------------------
-- Ability 1 - StarFinger (Press)
--------------------------------------------------------------------
AbilityRegistry[1] = {
	Name = "StarFinger",
	Type = "Press",
	Cooldown = 12,
	Execute = function(standModel, player)
		StarPurple.StarFinger(standModel)
	end,
}

--------------------------------------------------------------------
-- Ability 2 - MachOra (Press, with MachOra2 follow-up)
--------------------------------------------------------------------
AbilityRegistry[2] = {
	Name = "MachOra",
	Type = "Press",
	Cooldown = COOLDOWN_TIME,

	-- 🔥 tell AbilityHandler NOT to block this ability
	BypassGlobalCooldown = true,

	Execute = function(standModel, player)
		local character = standModel.Parent
		if not character then
			return
		end

		local now = tick()
		local lastUse = lastMachOraUseTime[player] or 0
		local followupExpiry = recentMachOra[player] or 0

		-- MachOra2 follow-up (bypass stun, cooldown, action restrictions)
		if now <= followupExpiry then
			StarPurple.onMachOra2Requested(character)
			recentMachOra[player] = nil
			return
		end

		-- MachOra1 (normal use)
		-- obey stun & action
		if CombatUtils.GetStun(character) then
			return
		end
		if CombatUtils.GetActionInProgress(character).Value then
			return
		end

		if now - lastUse < COOLDOWN_TIME then
			return -- still on cooldown
		end

		-- Perform MachOra1
		StarPurple.onMachOraRequested(character)

		-- Start cooldown manually
		lastMachOraUseTime[player] = now
		CooldownUpdateEvent:FireClient(player, 2, COOLDOWN_TIME)

		-- Allow MachOra2 for 2 seconds
		recentMachOra[player] = now + FOLLOWUP_WINDOW
	end,
}

--------------------------------------------------------------------
-- Ability 3 - GroundPound (Press)
--------------------------------------------------------------------
AbilityRegistry[3] = {
	Name = "GroundPound",
	Type = "Press",
	Cooldown = 12,
	Execute = function(standModel, player)
		local character = standModel.Parent
		if character then
			StarPurple.GroundPound(standModel)
		end
	end,
}

--------------------------------------------------------------------
-- Ability 4 - TimeStop (Press)
--------------------------------------------------------------------
AbilityRegistry[4] = {
	Name = "TimeStop",
	Type = "Press",
	Cooldown = 40,
	Execute = function(standModel, player)
		local character = standModel.Parent
		if character then
			StarPurple.TimeStop(character)
		end
	end,
}

return AbilityRegistry
