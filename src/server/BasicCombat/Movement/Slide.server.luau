local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local StandSlideToggle = Instance.new("RemoteFunction")
StandSlideToggle.Name = "SlideToggle"
StandSlideToggle.Parent = replicatedStorage.Shared.BasicCombat

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))

local COOLDOWN_TIME = 0.5
local MAX_Slide_DURATION = 4 -- seconds before auto-stop (optional)

local lastSlideEndTime = {} -- player -> tick() timestamp
local activeSlides = {} -- player -> true if currently barraging
local autoStopTasks = {} -- player -> task for auto-stop

StandSlideToggle.OnServerInvoke = function(player, isStarting)
	local character = player.Character
	if not character then
		return false
	end

	if isStarting then
		-- Prevent double start
		if activeSlides[player] then
			return false
		end

		-- Cooldown check
		local lastEnd = lastSlideEndTime[player]
		if lastEnd and tick() - lastEnd < COOLDOWN_TIME then
			print("Slide on cooldown")
			return false
		end

		local success = CombatUtils.StartSlide(player)
		if success then
			activeSlides[player] = true

			-- Start optional auto-stop timer
			if autoStopTasks[player] then
				task.cancel(autoStopTasks[player])
			end

			autoStopTasks[player] = task.delay(MAX_Slide_DURATION, function()
				if activeSlides[player] then
					CombatUtils.StopSlide({
						player,
					})
					lastSlideEndTime[player] = tick()
					activeSlides[player] = nil
				end
				autoStopTasks[player] = nil
			end)
		end
		return success
	else
		-- Ignore Stop requests if Slide already ended (auto or manually)
		if not activeSlides[player] then
			return false
		end

		-- Stop manually
		CombatUtils.StopSlide(player)
		lastSlideEndTime[player] = tick()
		activeSlides[player] = nil

		-- Cancel auto-stop if running
		if autoStopTasks[player] then
			task.cancel(autoStopTasks[player])
			autoStopTasks[player] = nil
		end

		return true
	end
end
