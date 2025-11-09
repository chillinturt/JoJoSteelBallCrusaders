local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local LifeOverflowEvent = Instance.new("RemoteFunction")
LifeOverflowEvent.Name = "LifeOverflow"
LifeOverflowEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("GoldExperiment")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local GoldExperimentModule =
	require(serverScriptService.BasicCombat.StandModules.GoldExperiment:WaitForChild("GoldExperiment"))

local COOLDOWN_TIME = 8

local lastLifeOverflowUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

LifeOverflowEvent.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end

	local standName = standModel:FindFirstChild("StandTag").Value
	if standName ~= "Gold Experiment" then
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
	local lastLifeOverflow = lastLifeOverflowUseTime[player]
	if lastLifeOverflow and tick() - lastLifeOverflow < COOLDOWN_TIME then
		print("LifeOverflow on cooldown!")
		return false
	end

	lastLifeOverflowUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 1, COOLDOWN_TIME)

	local success = GoldExperimentModule.LifeOverflow(standModel)
	return success
end
