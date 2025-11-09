local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local ZoomPunchEvent = Instance.new("RemoteFunction")
ZoomPunchEvent.Name = "ZoomPunch"
ZoomPunchEvent.Parent = ReplicatedStorage.Shared.BasicCombat.Hamon

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("SpecCooldownUpdateEvent")

local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local HamonModule = require(serverScriptService.BasicCombat.SpecailtyScripts.Hamon:WaitForChild("Hamon"))

local COOLDOWN_TIME = 8
local ZOOM_PUNCH_COST = 10

local lastZoomPunchUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

ZoomPunchEvent.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local hamonVal = HamonModule.getHamonValue(character)
	if not hamonVal or hamonVal.Value < ZOOM_PUNCH_COST then
		return
	end

	local powersFolder = player:FindFirstChild("Powers")
	local SpecName = powersFolder:FindFirstChild("Specialty").Value
	if SpecName ~= "Hamon" then
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
	local lastZoomPunch = lastZoomPunchUseTime[player]
	if lastZoomPunch and tick() - lastZoomPunch < COOLDOWN_TIME then
		print("ZoomPunch on cooldown")
		return false
	end

	lastZoomPunchUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 1, COOLDOWN_TIME) -- CD1, 8 seconds

	local success = HamonModule.ZoomPunch(character)
	return success
end
