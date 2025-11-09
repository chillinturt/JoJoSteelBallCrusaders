local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local HeavyRaindropEvent = Instance.new("RemoteFunction")
HeavyRaindropEvent.Name = "HeavyRaindrop"
HeavyRaindropEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("NuclearRain")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local NuclearRainModule = require(serverScriptService.BasicCombat.StandModules.NuclearRain:WaitForChild("NuclearRain"))

local COOLDOWN_TIME = 8

local lastHeavyRaindropUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

HeavyRaindropEvent.OnServerInvoke = function(player)
	print("Heavy raindrop fired on server")
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end

	local standName = standModel:FindFirstChild("StandTag").Value
	if standName ~= "Nuclear Rain" then
		return
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag.Value then
		return
	end

	if CombatUtils.GetStun(character) then
		return
	end

	-- Cooldown check
	local lastHeavyRaindrop = lastHeavyRaindropUseTime[player]
	if lastHeavyRaindrop and tick() - lastHeavyRaindrop < COOLDOWN_TIME then
		print("HeavyRaindrop on cooldown!")
		return false
	end

	lastHeavyRaindropUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 1, COOLDOWN_TIME)

	local success = NuclearRainModule.HeavyRaindrop(character)
	return success
end
