local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- === Remote Event ===
local AbilityEvent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("StandAbilityEvent")

-- === Utilities ===
local StandUtils = require(ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))

-- === Ability Registry Loader ===
local StandModules = ServerScriptService.BasicCombat.StandModules

-- cooldowns[player][abilityId] = timestamp
local cooldowns = {}

---------------------------------------------------------------------
-- LOAD STAND-SPECIFIC ABILITY REGISTRY
---------------------------------------------------------------------
local function getAbilityRegistry(standName)
	local standFolder = StandModules:FindFirstChild(standName)
	if not standFolder then
		return nil
	end

	local registry = standFolder:FindFirstChild("AbilityRegistry")
	if not registry then
		return nil
	end

	return require(registry)
end

---------------------------------------------------------------------
--  MAIN SERVER HANDLER
---------------------------------------------------------------------
AbilityEvent.OnServerEvent:Connect(function(player, abilityId)
	if typeof(abilityId) ~= "number" then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	----------------------------------------------------------------
	-- HERO VALIDATION (prevents using abilities not belonged to)
	----------------------------------------------------------------
	local powers = player:FindFirstChild("Powers")
	local heroValue = powers and powers:FindFirstChild("Hero")
	if not heroValue or heroValue.Value == "" then
		warn("Player has no hero equipped:", player.Name)
		return
	end

	----------------------------------------------------------------
	-- DETECT STAND MODEL
	----------------------------------------------------------------
	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return
	end

	local standTag = standModel:FindFirstChild("StandTag")
	if not standTag then
		return
	end

	local standName = standTag.Value

	----------------------------------------------------------------
	-- STAND MUST MATCH HERO EQUIPPED
	----------------------------------------------------------------
	if standName ~= heroValue.Value then
		warn("Player tried to use ability for wrong stand:", player.Name)
		return
	end

	----------------------------------------------------------------
	-- LOAD STAND'S REGISTRY
	----------------------------------------------------------------
	local registry = getAbilityRegistry(standName)
	if not registry then
		warn("No AbilityRegistry found for stand:", standName)
		return
	end

	local abilityData = registry[abilityId]
	if not abilityData then
		warn("Invalid ability number:", abilityId, "for stand:", standName)
		return
	end

	----------------------------------------------------------------
	-- VALIDATION: stun state & action lock
	----------------------------------------------------------------
	if CombatUtils.GetStun(character) then
		return
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag.Value then
		return
	end

	----------------------------------------------------------------
	-- VALIDATION: cooldown
	----------------------------------------------------------------
	local now = tick()
	cooldowns[player] = cooldowns[player] or {}

	local lastUse = cooldowns[player][abilityId]
	if lastUse and now - lastUse < abilityData.Cooldown then
		return -- still on cooldown
	end

	cooldowns[player][abilityId] = now

	----------------------------------------------------------------
	-- EXECUTE ABILITY
	----------------------------------------------------------------
	local success = abilityData.Execute(standModel, player)

	----------------------------------------------------------------
	-- NOTIFY CLIENT OF COOLDOWN
	----------------------------------------------------------------
	local cooldownUIEvent = ReplicatedStorage.Shared.BasicCombat.UI:WaitForChild("CooldownUpdateEvent")
	cooldownUIEvent:FireClient(player, abilityId, abilityData.Cooldown)
end)
