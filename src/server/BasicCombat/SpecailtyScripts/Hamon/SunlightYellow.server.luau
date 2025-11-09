local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local StandSunlightYellowToggle = Instance.new("RemoteFunction")
StandSunlightYellowToggle.Name = "SunlightYellowToggle"
StandSunlightYellowToggle.Parent = ReplicatedStorage.Shared.BasicCombat.Hamon

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("SpecCooldownUpdateEvent")

local HamonModule = require(serverScriptService.BasicCombat.SpecailtyScripts.Hamon:WaitForChild("Hamon"))

local COOLDOWN_TIME = 8
local MAX_SunlightYellow_DURATION = 4 -- seconds before auto-stop (optional)
local SUNLIGHT_YELLOW_COST = 1

local lastSunlightYellowEndTime = {} -- player -> tick() timestamp
local activeSunlightYellows = {} -- player -> true if currently barraging
local autoStopTasks = {} -- player -> task for auto-stop

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

StandSunlightYellowToggle.OnServerInvoke = function(player, isStarting)
	local character = player.Character
	if not character then
		return false
	end

	local hamonVal = HamonModule.getHamonValue(character)
	if not hamonVal or hamonVal.Value < SUNLIGHT_YELLOW_COST then
		return
	end

	local powersFolder = player:FindFirstChild("Powers")
	local SpecName = powersFolder:FindFirstChild("Specialty").Value
	if SpecName ~= "Hamon" then
		return
	end

	if isStarting then
		-- Prevent double start
		if activeSunlightYellows[player] then
			return false
		end

		-- Cooldown check
		local lastEnd = lastSunlightYellowEndTime[player]
		if lastEnd and tick() - lastEnd < COOLDOWN_TIME then
			print("SunlightYellow on cooldown")
			return false
		end

		local success = HamonModule.StartSunlightYellow(character)
		if success then
			activeSunlightYellows[player] = true

			-- Start optional auto-stop timer
			if autoStopTasks[player] then
				task.cancel(autoStopTasks[player])
			end

			autoStopTasks[player] = task.delay(MAX_SunlightYellow_DURATION, function()
				if activeSunlightYellows[player] then
					HamonModule.StopSunlightYellow(character)
					lastSunlightYellowEndTime[player] = tick()
					activeSunlightYellows[player] = nil
				end
				autoStopTasks[player] = nil
			end)
		end
		return success
	else
		-- Ignore Stop requests if SunlightYellow already ended (auto or manually)
		if not activeSunlightYellows[player] then
			return false
		end

		-- Stop manually
		HamonModule.StopSunlightYellow(character)
		lastSunlightYellowEndTime[player] = tick()
		activeSunlightYellows[player] = nil

		-- Cancel auto-stop if running
		if autoStopTasks[player] then
			task.cancel(autoStopTasks[player])
			autoStopTasks[player] = nil
		end

		startCooldown(player, 2, COOLDOWN_TIME) -- CD1, 8 seconds

		return true
	end
end
