local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local StarFingerEvent = Instance.new("RemoteFunction")
StarFingerEvent.Name = "StarFinger"
StarFingerEvent.Parent = ReplicatedStorage.Shared.BasicCombat.StarPurple

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local StarPurpleModule = require(serverScriptService.BasicCombat.StandModules.StarPurple:WaitForChild("StarPurple"))

local COOLDOWN_TIME = 8

local lastStarFingerUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

StarFingerEvent.OnServerInvoke = function(player)
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
	local lastStarFinger = lastStarFingerUseTime[player]
	if lastStarFinger and tick() - lastStarFinger < COOLDOWN_TIME then
		print("StarFinger on cooldown")
		return false
	end

	lastStarFingerUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 1, COOLDOWN_TIME) -- CD1, 8 seconds

	local success = StarPurpleModule.StarFinger(standModel)
	return success
end
