local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local TearSpaceEvent = Instance.new("RemoteFunction")
TearSpaceEvent.Name = "TearSpace"
TearSpaceEvent.Parent = replicatedStorage.Shared.BasicCombat:WaitForChild("ThatHand")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local ThatHandModule = require(serverScriptService.BasicCombat.StandModules.ThatHand:WaitForChild("ThatHand"))

local COOLDOWN_TIME = 8

local lastTearSpaceUseTime = {} -- player -> tick() timestamp

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

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag.Value then
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

	local success = ThatHandModule.TearSpace(standModel)
	return success
end
