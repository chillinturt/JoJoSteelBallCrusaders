local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local NailShotEvent = Instance.new("RemoteFunction")
NailShotEvent.Name = "NailShot"
NailShotEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("Tusk")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local TuskModule = require(serverScriptService.BasicCombat.StandModules.Tusk:WaitForChild("Tusk"))

local COOLDOWN_TIME = 6

local lastNailShotUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

NailShotEvent.OnServerInvoke = function(player)
	print("Nail shot fired on server")
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end

	local standName = standModel:FindFirstChild("StandTag").Value
	if
		standName ~= "Tusk Act 1"
		and standName ~= "Tusk Act 2"
		and standName ~= "Tusk Act 3"
		and standName ~= "Tusk Act 4"
	then
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
	local lastNailShot = lastNailShotUseTime[player]
	if lastNailShot and tick() - lastNailShot < COOLDOWN_TIME then
		print("NailShot on cooldown!")
		return false
	end

	lastNailShotUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 1, COOLDOWN_TIME)

	local success = TuskModule.NailShot(character)
	return success
end
