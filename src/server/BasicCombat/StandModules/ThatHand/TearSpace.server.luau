local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local TearSpaceEvent = Instance.new("RemoteFunction")
TearSpaceEvent.Name = "TearSpace"
TearSpaceEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("ThatHand")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local ThatHandModule = require(serverScriptService.BasicCombat.StandModules.ThatHand:WaitForChild("ThatHand"))

local COOLDOWN_TIME = 12

local lastTearSpaceUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

TearSpaceEvent.OnServerInvoke = function(player)
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

	if CombatUtils.GetStun(character) then
		return
	end

	-- Cooldown check
	local lastTearSpace = lastTearSpaceUseTime[player]
	if lastTearSpace and tick() - lastTearSpace < COOLDOWN_TIME then
		print("TearSpace on cooldown!")
		return false
	end

	lastTearSpaceUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 3, COOLDOWN_TIME) -- CD3, 8 seconds

	local success = ThatHandModule.TearSpace(standModel)
	return success
end
