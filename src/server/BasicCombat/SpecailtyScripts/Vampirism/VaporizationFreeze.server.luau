local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local VaporizationFreezeEvent = Instance.new("RemoteFunction")
VaporizationFreezeEvent.Name = "VaporizationFreeze"
VaporizationFreezeEvent.Parent = ReplicatedStorage.Shared.BasicCombat.Vampirism

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("SpecCooldownUpdateEvent")

local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local VampirismModule = require(serverScriptService.BasicCombat.SpecailtyScripts.Vampirism:WaitForChild("Vampirism"))

local COOLDOWN_TIME = 8

local lastVaporizationFreezeUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

VaporizationFreezeEvent.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local powersFolder = player:FindFirstChild("Powers")
	local SpecName = powersFolder:FindFirstChild("Specialty").Value
	if SpecName ~= "Vampirism" then
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
	local lastVaporizationFreeze = lastVaporizationFreezeUseTime[player]
	if lastVaporizationFreeze and tick() - lastVaporizationFreeze < COOLDOWN_TIME then
		print("VaporizationFreeze on cooldown")
		return false
	end

	lastVaporizationFreezeUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 1, COOLDOWN_TIME) -- CD1, 8 seconds

	local success = VampirismModule.VaporizationFreeze(character)
	return success
end
