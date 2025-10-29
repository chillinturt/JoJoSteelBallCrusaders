local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local LifeForceAuraEvent = Instance.new("RemoteFunction")
LifeForceAuraEvent.Name = "LifeForceAura"
LifeForceAuraEvent.Parent = ReplicatedStorage.Shared.BasicCombat.Hamon

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("SpecCooldownUpdateEvent")

local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local HamonModule = require(serverScriptService.BasicCombat.SpecailtyScripts.Hamon:WaitForChild("Hamon"))

local COOLDOWN_TIME = 8
local LIFEFORCEAURA_COST = 10

local lastLifeForceAuraUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

LifeForceAuraEvent.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local hamonVal = HamonModule.getHamonValue(character)
	if not hamonVal or hamonVal.Value < LIFEFORCEAURA_COST then
		return
	end

	local SpecName = Players:GetPlayerFromCharacter(character):FindFirstChild("Specialty").Value
	if SpecName ~= "Hamon" then
		return
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag.Value then
		return
	end

	if CombatUtils.GetStun(character) then
		return
	end

	-- Cooldown check
	local lastLifeForceAura = lastLifeForceAuraUseTime[player]
	if lastLifeForceAura and tick() - lastLifeForceAura < COOLDOWN_TIME then
		print("LifeForceAura on cooldown")
		return false
	end

	lastLifeForceAuraUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 4, COOLDOWN_TIME) -- CD1, 8 seconds

	local success = HamonModule.LifeForceAura(character)
	return success
end
