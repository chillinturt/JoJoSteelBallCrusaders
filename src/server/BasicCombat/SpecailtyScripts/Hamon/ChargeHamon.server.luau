local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local ChargeHamonToggle = Instance.new("RemoteFunction")
ChargeHamonToggle.Name = "ChargeHamonToggle"
ChargeHamonToggle.Parent = replicatedStorage.Shared.BasicCombat.Hamon

local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local HamonModule = require(serverScriptService.BasicCombat.SpecailtyScripts.Hamon:WaitForChild("Hamon"))
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)

local COOLDOWN_TIME = 0.2
local lastChargeEndTime = {} -- [player] = tick()
local isCharging = {} -- [player] = bool
local deathConnections = {} -- [player] = RBXScriptConnection

ChargeHamonToggle.OnServerInvoke = function(player, isStarting)
	local character = player.Character
	if not character then
		return false
	end

	local spec = HeroManager.GetField(player, "Specialty")
	if not spec or spec ~= "Hamon" then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	-- === START CHARGING ===
	if isStarting then
		-- Cooldown check
		local lastEnd = lastChargeEndTime[player]
		if lastEnd and tick() - lastEnd < COOLDOWN_TIME then
			local remaining = math.ceil(COOLDOWN_TIME - (tick() - lastEnd))
			print(player.Name .. " tried to charge but cooldown active (" .. remaining .. "s left)")
			return false
		end

		-- Prevent double-starts
		if isCharging[player] then
			print(player.Name .. " already charging")
			return false
		end

		-- Cannot charge if stunned
		if CombatUtils.GetStun(character) then
			return false
		end

		-- Start charging
		local success = HamonModule.StartCharge(character)
		if success ~= false then
			isCharging[player] = true
			print(player.Name .. " started Hamon charge")

			-- Disconnect any old death connection first
			if deathConnections[player] then
				deathConnections[player]:Disconnect()
			end

			-- Stop charging automatically on death
			deathConnections[player] = humanoid.Died:Connect(function()
				if isCharging[player] then
					HamonModule.StopCharge(character)
					isCharging[player] = nil
					lastChargeEndTime[player] = tick()
					print(player.Name .. " died — Hamon charge stopped automatically")
				end
			end)

			return true
		end

		return false
	else
		-- === STOP CHARGING ===
		if isCharging[player] then
			HamonModule.StopCharge(character)
			lastChargeEndTime[player] = tick()
			isCharging[player] = nil
			print(player.Name .. " stopped charging — cooldown started")

			-- Clean up death connection
			if deathConnections[player] then
				deathConnections[player]:Disconnect()
				deathConnections[player] = nil
			end

			return true
		else
			print(player.Name .. " tried to stop charge, but was not charging")
			return false
		end
	end
end
