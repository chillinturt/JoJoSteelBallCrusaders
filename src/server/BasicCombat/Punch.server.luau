local replicatedStorage = game:GetService("ReplicatedStorage")

local PunchEvent = Instance.new("RemoteEvent")
PunchEvent.Name = "PunchEvent"
PunchEvent.Parent = replicatedStorage.Shared:WaitForChild("BasicCombat")

local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local BasicStandAttacks = require(game.ServerScriptService.BasicCombat:WaitForChild("BasicStandAttacks"))
local GeneralCombat = require(game.ServerScriptService.BasicCombat.GeneralCombat)

PunchEvent.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then
		return false
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag.Value then
		return
	end

	local stun = character:FindFirstChild("Stun")
	if stun then
		return
	end

	local standModel = StandUtils.getStandModel(character)

	if standModel then
		BasicStandAttacks.BasicPunch(standModel)
	else
		GeneralCombat.StandOffPunch(character)
	end

	return true
end)

--[[
standOffPunch.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag.Value then
		return
	end

	local stun = character:FindFirstChild("Stun")
	if stun then
		return
	end

	--GeneralCombat.StandOffPunch(character)
end
]]
