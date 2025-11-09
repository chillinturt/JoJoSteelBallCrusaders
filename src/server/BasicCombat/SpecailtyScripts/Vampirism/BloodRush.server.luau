local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local BloodRushEvent = Instance.new("RemoteFunction")
BloodRushEvent.Name = "BloodRush"
BloodRushEvent.Parent = ReplicatedStorage.Shared.BasicCombat.Vampirism

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("SpecCooldownUpdateEvent")

local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local VampirismModule = require(serverScriptService.BasicCombat.SpecailtyScripts.Vampirism:WaitForChild("Vampirism"))
local VampireModule = require(serverScriptService.BasicCombat.RaceScripts:WaitForChild("Vampire"))

local COOLDOWN_TIME = 8
local BLOOD_RUSH_COST = 20

local lastBloodRushUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

BloodRushEvent.OnServerInvoke = function(player)
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

	local bloodVal = VampireModule.getBloodValue(character)
	if not bloodVal or bloodVal.Value < BLOOD_RUSH_COST then
		return
	end

	-- Cooldown check
	local lastBloodRush = lastBloodRushUseTime[player]
	if lastBloodRush and tick() - lastBloodRush < COOLDOWN_TIME then
		print("BloodRush on cooldown")
		return false
	end

	lastBloodRushUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 4, COOLDOWN_TIME) -- CD1, 8 seconds

	local success = VampirismModule.BloodRush(character)
	return success
end
