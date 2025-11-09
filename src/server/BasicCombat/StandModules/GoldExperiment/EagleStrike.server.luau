local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local EagleStrikeEvent = Instance.new("RemoteFunction")
EagleStrikeEvent.Name = "EagleStrike"
EagleStrikeEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("GoldExperiment")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local GoldExperimentModule =
	require(serverScriptService.BasicCombat.StandModules.GoldExperiment:WaitForChild("GoldExperiment"))

local COOLDOWN_TIME = 8

-- Track usage state per player
local lastEagleStrikeUseTime = {} -- player -> tick()
local eagleStrikeStage = {} -- player -> "ready" | "first" | "cooldown"

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

EagleStrikeEvent.OnServerInvoke = function(player)
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
		return false
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag.Value then
		return false
	end

	if CombatUtils.GetStun(character) then
		return false
	end

	local currentStage = eagleStrikeStage[player]
	local lastUse = lastEagleStrikeUseTime[player]

	-- Cooldown enforcement
	if currentStage == "cooldown" and lastUse and tick() - lastUse < COOLDOWN_TIME then
		print("EagleStrike on cooldown!")
		return false
	end

	-- === Ability logic ===
	local success, stageType = GoldExperimentModule.EagleStrike(character)
	if not success then
		return false
	end

	if stageType == "launch" then
		-- === First use ===
		eagleStrikeStage[player] = "first"
		lastEagleStrikeUseTime[player] = tick()
		startCooldown(player, 2, COOLDOWN_TIME)
	elseif stageType == "redirect" then
		-- === Redirect ===
		eagleStrikeStage[player] = "cooldown"
		lastEagleStrikeUseTime[player] = tick()
	end

	-- ✅ Only start reset timer after a successful *redirect* (proper use)
	if stageType == "redirect" then
		task.delay(COOLDOWN_TIME, function()
			if player and player.Parent and eagleStrikeStage[player] == "cooldown" then
				eagleStrikeStage[player] = "ready"
			end
		end)
	end

	return true
end
