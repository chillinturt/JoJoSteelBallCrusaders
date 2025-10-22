local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local ChopEvent = Instance.new("RemoteFunction")
ChopEvent.Name = "Chop"
ChopEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("KingCarmine")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local KingCarmineModule = require(serverScriptService.BasicCombat.StandModules.KingCarmine:WaitForChild("KingCarmine"))

local COOLDOWN_TIME = 8

local lastChopUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

ChopEvent.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end

	local standName = standModel:FindFirstChild("StandTag").Value
	if standName ~= "King Carmine" then
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
	local lastChop = lastChopUseTime[player]
	if lastChop and tick() - lastChop < COOLDOWN_TIME then
		print("Chop on cooldown!")
		return false
	end

	lastChopUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 1, COOLDOWN_TIME)

	local success = KingCarmineModule.Chop(standModel)
	return success
end
