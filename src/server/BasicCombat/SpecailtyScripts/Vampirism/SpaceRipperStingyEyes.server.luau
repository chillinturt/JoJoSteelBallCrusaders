local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local SpaceRipperStingyEyesEvent = Instance.new("RemoteFunction")
SpaceRipperStingyEyesEvent.Name = "SpaceRipperStingyEyes"
SpaceRipperStingyEyesEvent.Parent = ReplicatedStorage.Shared.BasicCombat.Vampirism

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("SpecCooldownUpdateEvent")

local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local VampirismModule = require(serverScriptService.BasicCombat.SpecailtyScripts.Vampirism:WaitForChild("Vampirism"))
local VampireModule = require(serverScriptService.BasicCombat.RaceScripts:WaitForChild("Vampire"))

local COOLDOWN_TIME = 8
local SPACE_RIPPER_STINGY_EYES_COST = 10

local lastSpaceRipperStingyEyesUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

SpaceRipperStingyEyesEvent.OnServerInvoke = function(player)
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
	if not bloodVal or bloodVal.Value < SPACE_RIPPER_STINGY_EYES_COST then
		return
	end

	-- Cooldown check
	local lastSpaceRipperStingyEyes = lastSpaceRipperStingyEyesUseTime[player]
	if lastSpaceRipperStingyEyes and tick() - lastSpaceRipperStingyEyes < COOLDOWN_TIME then
		print("SpaceRipperStingyEyes on cooldown")
		return false
	end

	lastSpaceRipperStingyEyesUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 3, COOLDOWN_TIME) -- CD1, 8 seconds

	local success = VampirismModule.SpaceRipperStingyEyes(character)
	return success
end
