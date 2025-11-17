local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local TimeEraseEvent = Instance.new("RemoteFunction")
TimeEraseEvent.Name = "TimeErase"
TimeEraseEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("KingCarmine")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local KingCarmineModule = require(serverScriptService.BasicCombat.StandModules.KingCarmine:WaitForChild("KingCarmine"))

local COOLDOWN_TIME = 45

local lastTimeEraseUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

TimeEraseEvent.OnServerInvoke = function(player)
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

	-- Cooldown check
	local lastTimeErase = lastTimeEraseUseTime[player]
	if lastTimeErase and tick() - lastTimeErase < COOLDOWN_TIME then
		print("TimeErase on cooldown")
		return false
	end

	lastTimeEraseUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 4, COOLDOWN_TIME) -- CD3, 8 seconds

	local success = KingCarmineModule.TimeErase(standModel)
	return success
end
