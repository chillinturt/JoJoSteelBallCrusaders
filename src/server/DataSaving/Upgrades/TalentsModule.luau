local ServerScriptService = game:GetService("ServerScriptService")
-- TalentsModule.lua
-- Fully dynamic talent system

local StaminaService = require(ServerScriptService.BasicCombat.Movement.StaminaService)
local XPSystem = require(game.ServerScriptService.DataSaving:WaitForChild("XPSystem"))
local CombatUtils = require(game.ServerScriptService.BasicCombat.CombatUtils)

---------------------------------------------------------------------
-- MODULE
---------------------------------------------------------------------

local TalentsModule = {}

---------------------------------------------------------------------
-- IN MEMORY STORAGE
---------------------------------------------------------------------

-- upgradeData[player.UserId] = {
--     Talents = {}
-- }

local upgradeData = {}

--constants
local BASE_HEALTH = 150
local HEALTH_PER_LEVEL = 15

local BASE_MOVE_SPEED = 24
local SPEED_PER_LEVEL = 0.6

local BASE_REGEN = 0.1
local REGEN_PER_LEVEL = 0.15

local BASE_BLOCK_HP = 50
local BLOCK_PER_LEVEL = 3

local regenRateByCharacter = {}

---------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------
local TALENTS = {

	Health = {
		Max = 25,

		apply = function(player, level)
			local char = player.Character
			if not char then
				return
			end

			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				return
			end

			local oldMaxHealth = humanoid.MaxHealth
			local newMaxHealth = BASE_HEALTH + (level * HEALTH_PER_LEVEL)

			humanoid.MaxHealth = newMaxHealth

			if humanoid.Health >= oldMaxHealth then
				humanoid.Health = newMaxHealth
			else
				humanoid.Health = math.min(humanoid.Health, newMaxHealth)
			end
		end,
	},

	Agility = {
		Max = 25,

		apply = function(player, level)
			local char = player.Character
			if not char then
				return
			end

			local newSpeed = BASE_MOVE_SPEED + (level * SPEED_PER_LEVEL)

			CombatUtils.SetMoveSpeed(char, newSpeed)
		end,
	},

	Vitality = {
		Max = 25,

		apply = function(player, level)
			local char = player.Character
			if not char then
				return
			end

			local regenRate = BASE_REGEN + (level * REGEN_PER_LEVEL)

			regenRateByCharacter[char] = regenRate
		end,
	},

	Power = {
		Max = 25,

		apply = function(player, level)
			CombatUtils.SetPower(player, level)
		end,
	},

	Dexterity = {
		Max = 5,

		apply = function(player, level)
			CombatUtils.SetDexterity(player, level)
		end,
	},

	Strength = {
		Max = 25,

		apply = function(player, level)
			CombatUtils.SetStrength(player, level)
		end,
	},

	Stamina = {
		Max = 3,

		apply = function(player, level)
			StaminaService.SetStamina(player, level)
			StaminaService.RefreshStamina(player)
		end,
	},

	Block = {

		Max = 25,

		apply = function(player, level)
			local char = player.Character
			if not char then
				return
			end

			local newBlockHP = BASE_BLOCK_HP + (level * BLOCK_PER_LEVEL)

			CombatUtils.SetBlockMaxHP(char, newBlockHP)
		end,
	},
}

local function ensure(player)
	if not upgradeData[player.UserId] then
		upgradeData[player.UserId] = {
			Talents = {},
		}
	end

	local data = upgradeData[player.UserId]

	for talentName, _ in pairs(TALENTS) do
		if data.Talents[talentName] == nil then
			data.Talents[talentName] = 0
		end
	end

	return data
end

local function buildClientData(player)
	local data = ensure(player)
	local ap = XPSystem.GetField(player, "TalentPoints") or 0

	return {
		TalentPoints = ap,
		Talents = data.Talents,
	}
end

local function applyTalentEffect(player, talentName, level)
	local talent = TALENTS[talentName]

	if not talent then
		warn("Unknown talent:", talentName)
		return
	end

	if talent.apply then
		talent.apply(player, level)
	end
end

---------------------------------------------------------------------
-- INIT / CLEANUP
---------------------------------------------------------------------

function TalentsModule.InitPlayer(player)
	ensure(player)
end

function TalentsModule.RemovePlayer(player)
	upgradeData[player.UserId] = nil
end

---------------------------------------------------------------------
-- APPLY UPGRADE
---------------------------------------------------------------------

function TalentsModule.ApplyUpgrade(player, talentName)
	local data = ensure(player)
	local ap = XPSystem.GetField(player, "TalentPoints") or 0

	print("Player AP:", ap)

	-- Validate talent exists
	if not TALENTS[talentName] then
		warn("Invalid talent:", talentName)
		return false, buildClientData(player)
	end

	-- Check ability points
	if ap <= 0 then
		return false, buildClientData(player)
	end

	local currentLevel = data.Talents[talentName] or 0
	local maxLevel = TALENTS[talentName].Max

	-- Check max level
	if currentLevel >= maxLevel then
		return false, buildClientData(player)
	end

	-- Spend ability point
	XPSystem.SetField(player, "TalentPoints", ap - 1)

	-- Apply upgrade
	data.Talents[talentName] = currentLevel + 1
	applyTalentEffect(player, talentName, data.Talents[talentName])

	return true, buildClientData(player)
end

---------------------------------------------------------------------
-- APPLY ALL TALENT EFFECTS (for respawns / character added)
---------------------------------------------------------------------
function TalentsModule.ApplyAllEffects(player)
	local data = ensure(player)

	if not data or not data.Talents then
		warn("Talents not ready for", player)
		return
	end

	for talentName, level in pairs(data.Talents) do
		if level > 0 then
			applyTalentEffect(player, talentName, level)
		end
	end
end

---------------------------------------------------------------------
-- SAVE / LOAD
---------------------------------------------------------------------
function TalentsModule.GetStats(player)
	local data = ensure(player)

	return {
		Talents = data.Talents,
	}
end

function TalentsModule.SetStats(player, savedData)
	upgradeData[player.UserId] = savedData or { Talents = {} }

	local data = ensure(player)
	data.Talents = data.Talents or {}
end

---------------------------------------------------------------------
-- RESET
---------------------------------------------------------------------

function TalentsModule.ResetPlayer(player)
	upgradeData[player.UserId] = {
		Talents = {},
	}
	StaminaService.SetStamina(player, 0)
	StaminaService.RefreshStamina(player)

	local char = player.Character
	if not char then
		return
	end

	local newSpeed = BASE_MOVE_SPEED + (0 * SPEED_PER_LEVEL)

	CombatUtils.SetMoveSpeed(char, newSpeed)
	local stats = XPSystem.GetStats(player)

	if stats then
		stats.TalentPoints = (stats.Level - 1) * 2
		XPSystem.SetStats(player, stats)
	end
end

task.spawn(function()
	while true do
		task.wait(1)

		for character, regen in pairs(regenRateByCharacter) do
			if character and character.Parent then
				local humanoid = character:FindFirstChildOfClass("Humanoid")

				if humanoid and humanoid.Health > 0 then
					humanoid.Health = math.min(humanoid.Health + regen, humanoid.MaxHealth)
				end
			else
				regenRateByCharacter[character] = nil
			end
		end
	end
end)

return TalentsModule
