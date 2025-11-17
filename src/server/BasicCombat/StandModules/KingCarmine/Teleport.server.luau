local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local TeleportEvent = Instance.new("RemoteFunction")
TeleportEvent.Name = "Teleport"
TeleportEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("KingCarmine")

local RequestTeleportTarget = Instance.new("RemoteFunction")
RequestTeleportTarget.Name = "RequestTeleportTarget"
RequestTeleportTarget.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("KingCarmine")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local KingCarmineModule = require(serverScriptService.BasicCombat.StandModules.KingCarmine:WaitForChild("KingCarmine"))

local COOLDOWN_TIME = 12

local lastTeleportUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

TeleportEvent.OnServerInvoke = function(player)
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
	if CombatUtils.GetStun(character) then
		return
	end

	-- Cooldown check
	local lastTeleport = lastTeleportUseTime[player]
	if lastTeleport and tick() - lastTeleport < COOLDOWN_TIME then
		print("Teleport on cooldown")
		return false
	end

	lastTeleportUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 3, COOLDOWN_TIME) -- CD3, 8 seconds

	local success = KingCarmineModule.Teleport(character)
	return success
end
