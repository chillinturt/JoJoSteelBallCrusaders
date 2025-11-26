local ReplicatedStorage = game:GetService("ReplicatedStorage")

local machOraEvent = Instance.new("RemoteFunction")
machOraEvent.Name = "MachOra"
machOraEvent.Parent = ReplicatedStorage.Shared.BasicCombat.StarPurple

local machOra2Event = Instance.new("RemoteFunction")
machOra2Event.Name = "MachOra2"
machOra2Event.Parent = ReplicatedStorage.Shared.BasicCombat.StarPurple

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local StarPurpleModule =
	require(game.ServerScriptService.BasicCombat.StandModules.StarPurple:WaitForChild("StarPurple"))

local COOLDOWN_TIME = 10
local lastMachOraUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

-- Connect the summon event
machOraEvent.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end

	if CombatUtils.GetStun(character) then
		return
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag.Value then
		return
	end

	-- Cooldown check
	local lastMachOra = lastMachOraUseTime[player]
	if lastMachOra and tick() - lastMachOra < COOLDOWN_TIME then
		print("MachOra on cooldown")
		return false
	end

	lastMachOraUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 2, COOLDOWN_TIME) -- CD3, 8 seconds

	StarPurpleModule.onMachOraRequested(character)
end

machOra2Event.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end

	StarPurpleModule.onMachOra2Requested(character)
end
