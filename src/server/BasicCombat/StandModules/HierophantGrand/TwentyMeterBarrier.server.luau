local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local TwentyMeterBarrierEvent = Instance.new("RemoteFunction")
TwentyMeterBarrierEvent.Name = "TwentyMeterBarrier"
TwentyMeterBarrierEvent.Parent = ReplicatedStorage.Shared.BasicCombat.HierophantGrand

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local HierophantGrandModule =
	require(serverScriptService.BasicCombat.StandModules.HierophantGrand:WaitForChild("HierophantGrand"))

local COOLDOWN_TIME = 30

local lastBarrierUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

TwentyMeterBarrierEvent.OnServerInvoke = function(player)
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
	local lastTwentyMeterBarrier = lastBarrierUseTime[player]
	if lastTwentyMeterBarrier and tick() - lastTwentyMeterBarrier < COOLDOWN_TIME then
		print("Barrier on cooldown")
		return false
	end

	lastBarrierUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 4, COOLDOWN_TIME) -- CD3, 8 seconds

	local success = HierophantGrandModule.TwentyMeterBarrier(standModel)
	return success
end
