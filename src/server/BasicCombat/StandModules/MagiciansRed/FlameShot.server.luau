local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local FlameShotEvent = Instance.new("RemoteFunction")
FlameShotEvent.Name = "FlameShot"
FlameShotEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("MagiciansRed")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local MagiciansRedModule =
	require(serverScriptService.BasicCombat.StandModules.MagiciansRed:WaitForChild("MagiciansRed"))

local COOLDOWN_TIME = 3

local lastFlameShotUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

FlameShotEvent.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end

	local standName = standModel:FindFirstChild("StandTag").Value
	if standName ~= "Magicians Red" then
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
	local lastFlameShot = lastFlameShotUseTime[player]
	if lastFlameShot and tick() - lastFlameShot < COOLDOWN_TIME then
		print("FlameShot on cooldown!")
		return false
	end

	lastFlameShotUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 1, COOLDOWN_TIME)

	local success = MagiciansRedModule.FlameShot(character)
	return success
end
