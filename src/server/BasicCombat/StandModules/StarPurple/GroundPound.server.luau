local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local GroundPoundEvent = Instance.new("RemoteFunction")
GroundPoundEvent.Name = "GroundPound"
GroundPoundEvent.Parent = ReplicatedStorage.Shared.BasicCombat.StarPurple

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local StarPurpleModule = require(serverScriptService.BasicCombat.StandModules.StarPurple:WaitForChild("StarPurple"))

local COOLDOWN_TIME = 12

local lastGroundPoundUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

GroundPoundEvent.OnServerInvoke = function(player)
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

	-- Cooldown check
	local lastGroundPound = lastGroundPoundUseTime[player]
	if lastGroundPound and tick() - lastGroundPound < COOLDOWN_TIME then
		print("GroundPound on cooldown")
		return false
	end

	lastGroundPoundUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 3, COOLDOWN_TIME) -- CD1, 8 seconds

	local success = StarPurpleModule.GroundPound(standModel)
	return success
end
