local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local DivineDrinkEvent = Instance.new("RemoteFunction")
DivineDrinkEvent.Name = "DivineDrink"
DivineDrinkEvent.Parent = ReplicatedStorage.Shared.BasicCombat.Vampirism

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("SpecCooldownUpdateEvent")

local CombatUtils = require(serverScriptService.BasicCombat:WaitForChild("CombatUtils"))
local VampirismModule = require(serverScriptService.BasicCombat.SpecailtyScripts.Vampirism:WaitForChild("Vampirism"))

local COOLDOWN_TIME = 10

local lastDivineDrinkUseTime = {} -- player -> tick() timestamp

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

DivineDrinkEvent.OnServerInvoke = function(player)
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

	-- Cooldown check
	local lastDivineDrink = lastDivineDrinkUseTime[player]
	if lastDivineDrink and tick() - lastDivineDrink < COOLDOWN_TIME then
		print("DivineDrink on cooldown")
		return false
	end

	lastDivineDrinkUseTime[player] = tick() -- start cooldown timer

	startCooldown(player, 2, COOLDOWN_TIME) -- CD1, 8 seconds

	local success = VampirismModule.DivineDrink(character)
	return success
end
