-- AbilityHandler ModuleScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AbilityHandler = {}

-- Modules
local StandUtils = require(ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)
local HeroGroups = require(ServerScriptService.BasicCombat.StandModules.Handlers:WaitForChild("HeroGroups"))
local XPSystem = require(game.ServerScriptService.DataSaving:WaitForChild("XPSystem"))

-- Where all stand modules live
local StandModules = ServerScriptService.BasicCombat.StandModules

local AbilityUnlocksEvent = Instance.new("RemoteEvent")
AbilityUnlocksEvent.Name = "AbilityUnlocksEvent"
AbilityUnlocksEvent.Parent = ReplicatedStorage.UIs:WaitForChild("RemoteEvents")

local UNLOCK_LEVELS = {
	[1] = 10,
	[2] = 25,
	[3] = 40,
	[4] = 50, -- ultimate
}

-- Cooldowns: cooldowns[player][abilityId] = timestamp
local cooldowns = {}

-- Track active hold abilities: activeHolds[player][abilityId] = true/false
local activeHolds = {}

local function getHeroGroup(heroName)
	return HeroGroups[heroName] or heroName
end

function AbilityHandler.TryUnlockAbility(player, abilityId)
	-- Already unlocked
	if AbilityHandler.IsAbilityUnlocked(player, abilityId) then
		return false, "AlreadyUnlocked"
	end

	local unlocked = AbilityHandler.GetUnlockedAbilities(player)

	-- Level requirement
	local requiredLevel = UNLOCK_LEVELS[abilityId]
	local playerLevel = XPSystem.GetField(player, "Level") or 0

	if playerLevel < requiredLevel then
		warn("Unlock failed: not high enough level")
		return false, "LevelTooLow"
	end

	-- Ultimate must be last
	if abilityId == 4 then
		if not (unlocked[1] and unlocked[2] and unlocked[3]) then
			warn("Unlock failed: ultimate locked")
			return false, "UltimateLocked"
		end
	end

	-- Optional: Ability points cost
	local points = XPSystem.GetField(player, "AbilityPoints") or 0
	local COST = 1

	if points < COST then
		warn("Unlock failed: not enough points")
		return false, "NoPoints"
	end

	-- Deduct points
	local data = XPSystem.GetField(player, "AbilityPoints")
	XPSystem.SetField(player, "AbilityPoints", data - COST)

	-- Unlock
	unlocked[abilityId] = true
	HeroManager.SetField(player, "UnlockedAbilities", unlocked)

	print("Unlocked ability:", abilityId)

	AbilityUnlocksEvent:FireClient(player, unlocked)

	return true, "Success"
end

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

function AbilityHandler.ResetCooldown(player, abilityId)
	if not cooldowns[player] then
		return
	end

	-- Remove cooldown entry
	cooldowns[player][abilityId] = nil

	-- Optional cleanup if player has no cooldowns left
	if next(cooldowns[player]) == nil then
		cooldowns[player] = nil
	end

	-- Tell client UI cooldown is finished
	local cooldownUIEvent = ReplicatedStorage.Shared.BasicCombat.UI:WaitForChild("CooldownUpdateEvent")
	cooldownUIEvent:FireClient(player, abilityId, 0)
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
	print("execute ability in handler started...")
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- ❌ Block abilities while dead
	if humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		print("Ability blocked: player is dead")
		return
	end

	if CombatUtils.IsBlocking(character) then
		print("isblocking")
		return
	end

	-- Validate stand ownership
	local heroValue = HeroManager.GetField(player, "Hero")
	if not heroValue or heroValue == "None" then
		return
	end

	-- Normalize hero (TuskActX → Tusk)
	local heroGroup = getHeroGroup(heroValue)

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return
	end

	local standTag = standModel:FindFirstChild("StandTag")
	if not standTag then
		return
	end

	-- Normalize stand tag too
	local standHeroGroup = getHeroGroup(standTag.Value)

	if standHeroGroup ~= heroGroup then
		print("Ability blocked: stand mismatch")
		return
	end

	-- Load registry
	local registry = loadAbilityRegistry(heroGroup)
	if not registry then
		return
	end

	local abilityData = registry[abilityId]
	if not abilityData then
		return
	end

	-- ❌ Block if not unlocked
	if not AbilityHandler.IsAbilityUnlocked(player, abilityId) then
		print("Ability blocked: not unlocked")
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
			if actionFlag then
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
			if CombatUtils.GetActionInProgress(character) and not abilityData.EndlagCancel then
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
	if actionFlag and not abilityData.EndlagCancel then
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

function AbilityHandler.GetUnlockedAbilities(player)
	return HeroManager.GetField(player, "UnlockedAbilities") or {}
end

function AbilityHandler.IsAbilityUnlocked(player, abilityId)
	local unlocked = AbilityHandler.GetUnlockedAbilities(player)
	return unlocked[abilityId] == true
end

function AbilityHandler.UnlockAbility(player, abilityId)
	local unlocked = AbilityHandler.GetUnlockedAbilities(player)

	-- Prevent unlocking ultimate early
	if abilityId == 4 then
		if not (unlocked[1] and unlocked[2] and unlocked[3]) then
			warn("Cannot unlock ultimate before other abilities")
			return false
		end
	end

	unlocked[abilityId] = true
	HeroManager.SetField(player, "UnlockedAbilities", unlocked)

	return true
end

return AbilityHandler
