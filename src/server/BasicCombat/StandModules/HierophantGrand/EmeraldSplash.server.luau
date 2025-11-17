local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local EmeraldSplashToggle = Instance.new("RemoteFunction")
EmeraldSplashToggle.Name = "EmeraldSplashToggle"
EmeraldSplashToggle.Parent = ReplicatedStorage.Shared.BasicCombat.HierophantGrand

local StandUtils = require(ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local HierophantGrandModule =
	require(ServerScriptService.BasicCombat.StandModules.HierophantGrand:WaitForChild("HierophantGrand"))

local COOLDOWN_TIME = 10
local MAX_SPLASH_DURATION = 3

local lastSplashEndTime = {} -- player -> tick()
local splashActive = {} -- player -> true/false
local autoStopTasks = {} -- player -> task for auto-stop

EmeraldSplashToggle.OnServerInvoke = function(player, isStarting)
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end

	local standTag = standModel:FindFirstChild("StandTag")
	if not standTag or standTag.Value ~= "Hierophant Grand" then
		return false
	end

	if isStarting then
		-- Already active? ignore
		if splashActive[player] then
			return false
		end

		-- Cooldown check
		local lastEnd = lastSplashEndTime[player]
		if lastEnd and tick() - lastEnd < COOLDOWN_TIME then
			print("Splash on cooldown")
			return false
		end

		-- Block if stunned or busy
		local actionFlag = CombatUtils.GetActionInProgress(character)
		if actionFlag and actionFlag.Value then
			return false
		end
		if CombatUtils.GetStun(character) then
			return false
		end

		-- Start splash
		local success = HierophantGrandModule.StartSplash(character)
		if not success then
			return false
		end

		splashActive[player] = true

		-- Cancel any previous auto-stop
		if autoStopTasks[player] then
			task.cancel(autoStopTasks[player])
			autoStopTasks[player] = nil
		end

		-- Auto-stop after MAX_SPLASH_DURATION
		autoStopTasks[player] = task.delay(MAX_SPLASH_DURATION, function()
			if splashActive[player] then
				HierophantGrandModule.StopSplash(character)
				splashActive[player] = false
				lastSplashEndTime[player] = tick()
			end
			autoStopTasks[player] = nil
		end)

		return true
	else
		-- Manual stop
		if not splashActive[player] then
			-- It’s already auto-stopped; ignore
			return false
		end

		-- Stop manually
		HierophantGrandModule.StopSplash(character)
		splashActive[player] = false
		lastSplashEndTime[player] = tick()

		-- Cancel any pending auto-stop
		if autoStopTasks[player] then
			task.cancel(autoStopTasks[player])
			autoStopTasks[player] = nil
		end

		return true
	end
end

Players.PlayerAdded:Connect(function(player)
	lastSplashEndTime[player] = 0
	splashActive[player] = false
end)
