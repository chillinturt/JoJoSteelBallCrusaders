local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local RedBindEvent = Instance.new("RemoteFunction")
RedBindEvent.Name = "RedBind"
RedBindEvent.Parent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("MagiciansRed")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

local StandUtils = require(serverScriptService:WaitForChild("BasicCombat"):WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local MagiciansRedModule =
	require(serverScriptService.BasicCombat.StandModules.MagiciansRed:WaitForChild("MagiciansRed"))

local COOLDOWN_TIME = 8

local lastRedBindUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

RedBindEvent.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return false
	end

	local standName = standModel:FindFirstChild("StandTag").Value
	if standName ~= "Magicians Red" then
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
	local lastRedBind = lastRedBindUseTime[player]
	if lastRedBind and tick() - lastRedBind < COOLDOWN_TIME then
		print("RedBind on cooldown!")
		return false
	end

	lastRedBindUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 2, COOLDOWN_TIME)

	local success = MagiciansRedModule.RedBind(standModel)
	return success
end
