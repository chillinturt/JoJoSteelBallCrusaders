-- CombatUtils.lua
local GeneralCombat = {}

local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local hitboxSpawner = require(game.ServerScriptService.BasicCombat:WaitForChild("HitboxSpawner"))
local standUitls = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local SoundUtils = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

-- Track combo index per character
local comboIndices = {}
local comboResetTimers = {}
local comboCooldowns = {}
local punchCooldowns = {}

local HITBOX_SIZE = Vector3.new(6, 8, 9)
local PILOT_PUNCH_ANIMATIONS = { "136847469830162", "116981576719265", "115059281874785" }

STAND_OFF_PUNCH_DAMAGE = 10

function GeneralCombat.StandOffPunch(character)
	local primaryParty = character:FindFirstChild("HumanoidRootPart")
	if not primaryParty or not character then
		return false
	end

	if standUitls.GetActiveStand(character) then
		return
	end

	-- Combo cooldown: prevent starting a new combo too soon
	if comboCooldowns[character] and tick() < comboCooldowns[character] then
		return false -- Still in combo cooldown
	end

	-- Check cooldown
	if punchCooldowns[character] and tick() < punchCooldowns[character] then
		return false -- Still on cooldown
	end
	punchCooldowns[character] = tick() + 0.4 -- Set new cooldown

	-- Initialize combo index if needed
	if not comboIndices[character] then
		comboIndices[character] = 1
	end
	local index = comboIndices[character]

	local hitboxOffset = CFrame.new(0, 0, -3)
	-- Stop idle and play punch animation
	AnimationModule.StopAllAnimations(character)
	AnimationModule.PlayAnimation(character, PILOT_PUNCH_ANIMATIONS[index], false, Enum.AnimationPriority.Action, 1.5)

	-- Advance combo index or finish combo
	if index == 3 then
		comboIndices[character] = 1
		comboCooldowns[character] = tick() + 3 -- 3 sec cooldown after full combo
	else
		comboIndices[character] = index + 1
	end

	-- Prepare for next combo punch
	comboIndices[character] = index % 3 + 1

	--play sound
	SoundUtils.PlaySound({
		Root = primaryParty,
		soundName = "StandOffPunchEffects",
		soundID = "9113305631",
		volume = 1,
		playbackSpeed = 2,
		looped = false,
		range = 160,
	})

	hitboxSpawner.spawnStandOffHitbox({
		Character = character,
		Damage = 10 or 0.1,
		Size = HITBOX_SIZE,
		Offset = hitboxOffset,
		Color = BrickColor.new("Bright red"),
		Duration = 0.3,
		StunDuration = 0.1,
		Transparency = 0.3,
		Name = "BasicPunchHitbox",
	})

	--reset index in 3 seconds if index == 1
	-- Reset combo after 3 seconds of inactivity if index == 2 (after punch 1)
	if comboResetTimers[character] then
		task.cancel(comboResetTimers[character])
	end
	comboResetTimers[character] = task.delay(3, function()
		comboIndices[character] = 1
	end)

	return true
end

return GeneralCombat
