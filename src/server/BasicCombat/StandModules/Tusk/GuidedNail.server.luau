local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local GuidedNailEvent = Instance.new("RemoteFunction")
GuidedNailEvent.Name = "GuidedNail"
GuidedNailEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("Tusk")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local TuskModule = require(serverScriptService.BasicCombat.StandModules.Tusk:WaitForChild("Tusk"))

local COOLDOWN_TIME = 6

local lastGuidedNailUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

GuidedNailEvent.OnServerInvoke = function(player)
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
	local lastGuidedNail = lastGuidedNailUseTime[player]
	if lastGuidedNail and tick() - lastGuidedNail < COOLDOWN_TIME then
		print("GuidedNail on cooldown!")
		return false
	end

	lastGuidedNailUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 2, COOLDOWN_TIME)

	local success = TuskModule.GuidedNail(character)
	return success
end
