local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local TreeOfLifeEvent = Instance.new("RemoteFunction")
TreeOfLifeEvent.Name = "TreeOfLife"
TreeOfLifeEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("GoldExperiment")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local GoldExperimentModule =
	require(serverScriptService.BasicCombat.StandModules.GoldExperiment:WaitForChild("GoldExperiment"))

local COOLDOWN_TIME = 10

local lastTreeOfLifeUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

TreeOfLifeEvent.OnServerInvoke = function(player)
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
	local lastTreeOfLife = lastTreeOfLifeUseTime[player]
	if lastTreeOfLife and tick() - lastTreeOfLife < COOLDOWN_TIME then
		print("TreeOfLife on cooldown!")
		return false
	end

	lastTreeOfLifeUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 2, COOLDOWN_TIME)

	local success = GoldExperimentModule.TreeOfLife(character)
	return success
end
