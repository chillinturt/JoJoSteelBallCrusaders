local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local StandBarrageToggle = Instance.new("RemoteFunction")
StandBarrageToggle.Name = "StandBarrageToggle"
StandBarrageToggle.Parent = replicatedStorage.Shared.BasicCombat

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local BasicStandAttacksModule = require(serverScriptService.BasicCombat:WaitForChild("BasicStandAttacks"))

local COOLDOWN_TIME = 5
local MAX_BARRAGE_DURATION = 4 -- seconds before auto-stop (optional)

local lastBarrageEndTime = {} -- player -> tick() timestamp
local activeBarrages = {} -- player -> true if currently barraging
local autoStopTasks = {} -- player -> task for auto-stop

StandBarrageToggle.OnServerInvoke = function(player, isStarting)
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end

	if isStarting then
		-- Prevent double start
		if activeBarrages[player] then
			return false
		end

		-- Cooldown check
		local lastEnd = lastBarrageEndTime[player]
		if lastEnd and tick() - lastEnd < COOLDOWN_TIME then
			print("Barrage on cooldown")
			return false
		end

		local success = BasicStandAttacksModule.StartBarrage(character)
		if success then
			activeBarrages[player] = true

			-- Start optional auto-stop timer
			if autoStopTasks[player] then
				task.cancel(autoStopTasks[player])
			end

			autoStopTasks[player] = task.delay(MAX_BARRAGE_DURATION, function()
				if activeBarrages[player] then
					BasicStandAttacksModule.StopBarrage(character)
					lastBarrageEndTime[player] = tick()
					activeBarrages[player] = nil
				end
				autoStopTasks[player] = nil
			end)
		end
		return success
	else
		-- Ignore Stop requests if barrage already ended (auto or manually)
		if not activeBarrages[player] then
			return false
		end

		-- Stop manually
		BasicStandAttacksModule.StopBarrage(character)
		lastBarrageEndTime[player] = tick()
		activeBarrages[player] = nil

		-- Cancel auto-stop if running
		if autoStopTasks[player] then
			task.cancel(autoStopTasks[player])
			autoStopTasks[player] = nil
		end

		return true
	end
end
