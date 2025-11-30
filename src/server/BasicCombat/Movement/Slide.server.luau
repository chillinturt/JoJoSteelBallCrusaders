local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local StandSlideToggle = Instance.new("RemoteEvent")
StandSlideToggle.Name = "SlideToggle"
StandSlideToggle.Parent = replicatedStorage.Shared.BasicCombat

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))

local COOLDOWN_TIME = 0.5
local MAX_Slide_DURATION = 4 -- seconds before auto-stop (optional)

local lastSlideEndTime = {} -- player -> tick() timestamp
local activeSlides = {} -- player -> true if currently barraging
local autoStopTasks = {} -- player -> task for auto-stop

StandSlideToggle.OnServerEvent:Connect(function(player, action)
	if action == "Begin" then
		if activeSlides[player] then
			return
		end

		local lastEnd = lastSlideEndTime[player]
		if lastEnd and tick() - lastEnd < COOLDOWN_TIME then
			return -- simply deny silently
		end

		local success = CombatUtils.StartSlide(player)
		if success then
			activeSlides[player] = true
			lastSlideEndTime[player] = tick()

			-- auto-stop logic...
			if autoStopTasks[player] then
				task.cancel(autoStopTasks[player])
			end
			autoStopTasks[player] = task.delay(MAX_Slide_DURATION, function()
				if activeSlides[player] then
					CombatUtils.StopSlide(player)
					activeSlides[player] = nil
				end
			end)
		end
	elseif action == "End" then
		if activeSlides[player] then
			CombatUtils.StopSlide(player)
			activeSlides[player] = nil
			lastSlideEndTime[player] = tick()
		end
	end
end)
