local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Remote for client-server communication
local TorrentialDownpourToggle = Instance.new("RemoteFunction")
TorrentialDownpourToggle.Name = "TorrentialDownpourToggle"
TorrentialDownpourToggle.Parent = ReplicatedStorage.Shared.BasicCombat.NuclearRain

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

-- Dependencies
local StandUtils = require(ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local NuclearRainModule = require(ServerScriptService.BasicCombat.StandModules.NuclearRain:WaitForChild("NuclearRain"))

-- Config
local COOLDOWN_TIME = 1
local MAX_DOWNPOUR_DURATION = 10 -- failsafe (ends if it somehow keeps going indefinitely)

-- State tracking
local lastDownpourEndTime = {} -- player -> tick()
local downpourActive = {} -- player -> bool
local autoStopTasks = {} -- player -> task ref

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

-- === Main toggle handler ===
TorrentialDownpourToggle.OnServerInvoke = function(player)
	print("[Server] Torrential Downpour toggle requested by", player.Name)

	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end

	local standTag = standModel:FindFirstChild("StandTag")
	if not standTag or standTag.Value ~= "Nuclear Rain" then
		return false
	end

	-- Determine whether we are turning ON or OFF
	local isActive = downpourActive[player]
	local lastEnd = lastDownpourEndTime[player]

	startCooldown(player, 2, COOLDOWN_TIME)

	-- === TURN OFF if currently active ===
	if isActive then
		print("[Server] Stopping downpour for", player.Name)

		NuclearRainModule.StopTorrentialDownpour(standModel)
		downpourActive[player] = false
		lastDownpourEndTime[player] = tick()

		-- Cancel pending stop task
		if autoStopTasks[player] then
			task.cancel(autoStopTasks[player])
			autoStopTasks[player] = nil
		end

		return true
	end

	-- === TURN ON if not active ===

	-- Cooldown check
	if lastEnd and tick() - lastEnd < COOLDOWN_TIME then
		print("[Server] Downpour on cooldown for", player.Name)
		return false
	end

	-- Prevent activation while stunned or busy
	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag and actionFlag.Value then
		return false
	end
	if CombatUtils.GetStun(character) then
		return false
	end

	print("[Server] Starting downpour for", player.Name)
	NuclearRainModule.StartTorrentialDownpour(standModel)
	downpourActive[player] = true

	-- Cancel any old stop task
	if autoStopTasks[player] then
		task.cancel(autoStopTasks[player])
		autoStopTasks[player] = nil
	end

	-- Auto-stop failsafe
	autoStopTasks[player] = task.delay(MAX_DOWNPOUR_DURATION, function()
		if downpourActive[player] then
			print("[Server] Auto-stopping downpour for", player.Name)
			NuclearRainModule.StopTorrentialDownpour(standModel)
			downpourActive[player] = false
			lastDownpourEndTime[player] = tick()
		end
		autoStopTasks[player] = nil
	end)

	return true
end

-- === Initialize player state ===
Players.PlayerAdded:Connect(function(player)
	lastDownpourEndTime[player] = 0
	downpourActive[player] = false
end)

Players.PlayerRemoving:Connect(function(player)
	lastDownpourEndTime[player] = nil
	downpourActive[player] = nil
	if autoStopTasks[player] then
		task.cancel(autoStopTasks[player])
		autoStopTasks[player] = nil
	end
end)
