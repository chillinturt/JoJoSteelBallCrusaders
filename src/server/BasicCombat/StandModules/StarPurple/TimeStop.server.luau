local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local TimeStopEvent = Instance.new("RemoteFunction")
TimeStopEvent.Name = "TimeStop"
TimeStopEvent.Parent = ReplicatedStorage.Shared.BasicCombat.StarPurple

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local StarPurpleModule = require(serverScriptService.BasicCombat.StandModules.StarPurple:WaitForChild("StarPurple"))

local COOLDOWN_TIME = 40

local lastTimeStopUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

TimeStopEvent.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end
	local standName = standModel:FindFirstChild("StandTag").Value
	if standName ~= "Star Purple" then
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
	local lastTimeStop = lastTimeStopUseTime[player]
	if lastTimeStop and tick() - lastTimeStop < COOLDOWN_TIME then
		print("TimeStop on cooldown")
		return false
	end

	lastTimeStopUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 4, COOLDOWN_TIME) -- CD1, 8 seconds

	local success = StarPurpleModule.TimeStop(character)
	return success
end
