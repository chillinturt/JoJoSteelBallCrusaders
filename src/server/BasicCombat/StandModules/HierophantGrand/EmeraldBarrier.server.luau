local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local EmeraldBarrierEvent = Instance.new("RemoteFunction")
EmeraldBarrierEvent.Name = "EmeraldBarrier"
EmeraldBarrierEvent.Parent = ReplicatedStorage.Shared.BasicCombat.HierophantGrand

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local HierophantGrandModule =
	require(serverScriptService.BasicCombat.StandModules.HierophantGrand:WaitForChild("HierophantGrand"))

local COOLDOWN_TIME = 12

local lastBarrierUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

EmeraldBarrierEvent.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end
	local standName = standModel:FindFirstChild("StandTag").Value
	if standName ~= "Hierophant Grand" then
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
	local lastBarrier = lastBarrierUseTime[player]
	if lastBarrier and tick() - lastBarrier < COOLDOWN_TIME then
		print("Barrier on cooldown")
		return false
	end

	lastBarrierUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 3, COOLDOWN_TIME) -- CD3, 8 seconds

	local success = HierophantGrandModule.ActivateBarrier(standModel)
	return success
end
