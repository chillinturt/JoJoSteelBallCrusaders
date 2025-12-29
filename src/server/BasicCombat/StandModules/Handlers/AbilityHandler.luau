-- AbilityHandler ModuleScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AbilityHandler = {}

-- Modules
local StandUtils = require(ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)

-- Where all stand modules live
local StandModules = ServerScriptService.BasicCombat.StandModules

-- Cooldowns: cooldowns[player][abilityId] = timestamp
local cooldowns = {}

-- Track active hold abilities: activeHolds[player][abilityId] = true/false
local activeHolds = {}

---------------------------------------------------------------------
-- Load a stand's AbilityRegistry
---------------------------------------------------------------------
local function loadAbilityRegistry(standName)
	local standFolder = StandModules:FindFirstChild(standName)
	if not standFolder then
		return nil
	end

	local registryScript = standFolder:FindFirstChild("AbilityRegistry")
	if not registryScript then
		return nil
	end

	return require(registryScript)
end

---------------------------------------------------------------------
-- Send ability types to client
-- StandRegistry.AbilityTypes should exist
---------------------------------------------------------------------
function AbilityHandler.SendAbilityTypes(player, standName)
	local registry = loadAbilityRegistry(standName)
	if not registry then
		return
	end

	local types = registry.AbilityTypes or {}

	local AbilityTypesRemote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("StandAbilityTypes")
	AbilityTypesRemote:FireClient(player, types)
end

-- Apply a cooldown for a player+abilityId (seconds)
function AbilityHandler.ApplyCooldown(player, abilityId, duration)
	cooldowns[player] = cooldowns[player] or {}
	cooldowns[player][abilityId] = tick()
	-- fire UI for client
	local cooldownUIEvent = ReplicatedStorage.Shared.BasicCombat.UI:WaitForChild("CooldownUpdateEvent")
	cooldownUIEvent:FireClient(player, abilityId, duration or 0)
end

-- Check if player is currently on cooldown for abilityId. Returns remaining time or 0.
function AbilityHandler.IsOnCooldown(player, abilityId)
	local playerCDs = cooldowns[player]
	if not playerCDs or not playerCDs[abilityId] then
		return 0
	end
	local last = playerCDs[abilityId]
	-- if registry cooldown unknown here, caller can pass the cooldown to compute remaining
	return tick() - last
end

---------------------------------------------------------------------
-- Execute an ability request from client
-- Arguments:
--    abilityId: number
--    state: string or nil ("Start", "Stop", "Toggle", nil)
---------------------------------------------------------------------
function AbilityHandler.ExecuteAbility(player, abilityId, state)
	local character = player.Character
	if not character then
		return
	end

	-- Validate stand ownership
	local heroValue = HeroManager.GetField(player, "Hero")
	if not heroValue or heroValue == "None" then
		return
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return
	end

	local standTag = standModel:FindFirstChild("StandTag")
	if not standTag or standTag.Value ~= heroValue then
		return
	end

	-- Load registry
	local registry = loadAbilityRegistry(standTag.Value)
	if not registry then
		return
	end

	local abilityData = registry[abilityId]
	if not abilityData then
		return
	end

	local abilityType = registry.AbilityTypes[abilityId] or "Press"
	local cooldown = abilityData.Cooldown or 0

	-- Setup tracking
	cooldowns[player] = cooldowns[player] or {}
	activeHolds[player] = activeHolds[player] or {}
	local lastUse = cooldowns[player][abilityId]
	local isActive = activeHolds[player][abilityId] == true

	--------------------------------------------------
	-- HOLD ABILITY LOGIC
	--------------------------------------------------
	if abilityType == "Hold" then
		-- STOP cannot run unless ability is active
		if state == "Stop" then
			if not isActive then
				return -- ❗ prevent StopSplash from firing
			end

			-- Execute Stop
			if abilityData.ExecuteStop then
				abilityData.ExecuteStop(standModel, player)
			end

			-- Mark inactive
			activeHolds[player][abilityId] = false

			-- Apply cooldown (only now)
			if cooldown > 0 then
				cooldowns[player][abilityId] = tick()
				local cooldownUIEvent = ReplicatedStorage.Shared.BasicCombat.UI:WaitForChild("CooldownUpdateEvent")
				cooldownUIEvent:FireClient(player, abilityId, cooldown)
			end

			return
		end

		-- START logic
		if state == "Start" then
			-- Reject Start if on cooldown
			if lastUse and tick() - lastUse < cooldown then
				return
			end

			-- Action lock & stun (Start only)
			if CombatUtils.GetStun(character) then
				return
			end
			local actionFlag = CombatUtils.GetActionInProgress(character)
			if actionFlag.Value then
				return
			end

			-- Execute Start
			if abilityData.ExecuteStart then
				abilityData.ExecuteStart(standModel, player)
			end

			-- Mark active
			activeHolds[player][abilityId] = true

			return
		end

		return
	end

	--------------------------------------------------
	-- TOGGLE ABILITY LOGIC
	--------------------------------------------------
	if abilityType == "Toggle" then
		if activeHolds[player][abilityId] then
			if abilityData.ExecuteStop then
				abilityData.ExecuteStop(standModel, player)
			end
			activeHolds[player][abilityId] = false
		else
			if lastUse and tick() - lastUse < cooldown then
				return
			end
			if CombatUtils.GetStun(character) then
				return
			end
			if CombatUtils.GetActionInProgress(character).Value and not abilityData.EndlagCancel then
				return
			end

			if abilityData.ExecuteStart then
				abilityData.ExecuteStart(standModel, player)
			end
			activeHolds[player][abilityId] = true

			if cooldown > 0 then
				cooldowns[player][abilityId] = tick()
				local cooldownUIEvent = ReplicatedStorage.Shared.BasicCombat.UI:WaitForChild("CooldownUpdateEvent")
				cooldownUIEvent:FireClient(player, abilityId, cooldown)
			end
		end
		return
	end

	--------------------------------------------------
	-- PRESS ABILITY LOGIC
	--------------------------------------------------
	if not abilityData.BypassGlobalCooldown then
		if lastUse and tick() - lastUse < cooldown then
			return
		end
	end
	if abilityData.Hyperarmor ~= true then
		if CombatUtils.GetStun(character) then
			return
		end
	end
	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag.Value and not abilityData.EndlagCancel then
		return
	end

	cooldowns[player][abilityId] = tick()
	if abilityData.Execute then
		abilityData.Execute(standModel, player, state)
	end

	if not abilityData.BypassGlobalCooldown then
		local cooldownUIEvent = ReplicatedStorage.Shared.BasicCombat.UI:WaitForChild("CooldownUpdateEvent")
		cooldownUIEvent:FireClient(player, abilityId, cooldown)
	end
end

return AbilityHandler
