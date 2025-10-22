local replicatedStorage = game:GetService("ReplicatedStorage")

local standPunch = Instance.new("RemoteFunction")
standPunch.Name = "StandPunch"
standPunch.Parent = replicatedStorage.Shared:WaitForChild("BasicCombat")

local standOffPunch = Instance.new("RemoteFunction")
standOffPunch.Name = "StandOffPunch"
standOffPunch.Parent = replicatedStorage.Shared:WaitForChild("BasicCombat")

local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local BasicStandAttacks = require(game.ServerScriptService.BasicCombat:WaitForChild("BasicStandAttacks"))
local GeneralCombat = require(game.ServerScriptService.BasicCombat.GeneralCombat)

standPunch.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
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

	BasicStandAttacks.BasicPunch(standModel)
end

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

	GeneralCombat.StandOffPunch(character)
end
