local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local ChargeHamonToggle = Instance.new("RemoteFunction")
ChargeHamonToggle.Name = "ChargeHamonToggle"
ChargeHamonToggle.Parent = replicatedStorage.Shared.BasicCombat.Hamon

local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local HamonModule = require(serverScriptService.BasicCombat.SpecailtyScripts.Hamon:WaitForChild("Hamon"))

local COOLDOWN_TIME = 1
local lastChargeEndTime = {} -- [player] = tick()
local isCharging = {} -- [player] = bool

ChargeHamonToggle.OnServerInvoke = function(player, isStarting)
	local character = player.Character
	if not character then
		return false
	end

	local spec = player:FindFirstChild("Specialty")
	if not spec or spec.Value ~= "Hamon" then
		return false
	end

	-- Cooldown enforcement (always check before starting)
	if isStarting then
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

		if CombatUtils.GetStun(character) then
			return false
		end

		-- Start charging
		local success = HamonModule.StartCharge(character)
		if success ~= false then
			isCharging[player] = true
			print(player.Name .. " started Hamon charge")
			return true
		end
	else
		-- Stop charging
		if isCharging[player] then
			HamonModule.StopCharge(character)
			lastChargeEndTime[player] = tick() -- start cooldown
			isCharging[player] = nil
			print(player.Name .. " stopped charging — cooldown started")
			return true
		else
			print(player.Name .. " tried to stop charge, but was not charging")
			return false
		end
	end
end
