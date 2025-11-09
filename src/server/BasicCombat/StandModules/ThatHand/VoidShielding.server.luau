local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local VoidShieldingEvent = Instance.new("RemoteFunction")
VoidShieldingEvent.Name = "VoidShielding"
VoidShieldingEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("ThatHand")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local ThatHandModule = require(serverScriptService.BasicCombat.StandModules.ThatHand:WaitForChild("ThatHand"))

local COOLDOWN_TIME = 20

local lastVoidShieldingUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

VoidShieldingEvent.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end

	local standName = standModel:FindFirstChild("StandTag").Value
	if standName ~= "That Hand" then
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
	local lastVoidShielding = lastVoidShieldingUseTime[player]
	if lastVoidShielding and tick() - lastVoidShielding < COOLDOWN_TIME then
		print("VoidShielding on cooldown!")
		return false
	end

	lastVoidShieldingUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 2, COOLDOWN_TIME) -- CD3, 8 seconds

	local success = ThatHandModule.VoidShielding(character)
	return success
end
