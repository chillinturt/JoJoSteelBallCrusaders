local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local BubbleCutterEvent = Instance.new("RemoteFunction")
BubbleCutterEvent.Name = "BubbleCutter"
BubbleCutterEvent.Parent = ReplicatedStorage.Shared.BasicCombat.Hamon

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("SpecCooldownUpdateEvent")

local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local HamonModule = require(serverScriptService.BasicCombat.SpecailtyScripts.Hamon:WaitForChild("Hamon"))

local COOLDOWN_TIME = 8
local BUBBLE_CUTTER_COST = 10

local lastBubbleCutterUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

BubbleCutterEvent.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local hamonVal = HamonModule.getHamonValue(character)
	if not hamonVal or hamonVal.Value < BUBBLE_CUTTER_COST then
		return
	end

	local SpecName = Players:GetPlayerFromCharacter(character):FindFirstChild("Specialty").Value
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
	local lastBubbleCutter = lastBubbleCutterUseTime[player]
	if lastBubbleCutter and tick() - lastBubbleCutter < COOLDOWN_TIME then
		print("BubbleCutter on cooldown")
		return false
	end

	lastBubbleCutterUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 3, COOLDOWN_TIME) -- CD1, 8 seconds

	local success = HamonModule.BubbleCutter(character)
	return success
end
