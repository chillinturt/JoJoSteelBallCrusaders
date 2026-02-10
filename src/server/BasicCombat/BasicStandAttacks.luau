local BasicStandAttacks = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local IDLE_ANIM_ID = 89452205434139
--local PUNCH_ANIMATIONS = {"93085018014908", "103624770697086", "134941790648824"}  -- Animation IDs
local PUNCH_ANIMATIONS = { "90498591949232", "86291795389163", "88632829279678" } -- Animation IDs
local PILOT_PUNCH_ANIMATIONS = { "136847469830162", "116981576719265", "115059281874785" }

local HITBOX_SIZE = Vector3.new(6, 8, 9)
local BARRAGE_INTERVAL = 0.15
local MAX_BARRAGE_DURATION = 3 -- seconds

local PUNCH_COMBO_COOLDOWN = 2.5

local originalC0s = {}
local barragingFlags = {}

local StandUtils = require(script.Parent.StandUtils)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local hitboxSpawner = require(game.ServerScriptService.BasicCombat:WaitForChild("HitboxSpawner"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local PilotModule = require(game.ServerScriptService.BasicCombat:WaitForChild("PilotModule"))
local SoundUtils = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)

-- Track combo index per stand
local comboIndices = {}
local comboResetTimers = {}
local comboCooldowns = {}
local punchCooldowns = {}

local PUNCH_DAMAGE = {
	["StarPurple"] = 5,
	["HierophantGrand"] = 4,
	["CrazedDiamond"] = 5,
	["KingCarmine"] = 4.5,
	["GoldExperiment"] = 4.5,
	["KaiserQueen"] = 4.5,
	["NuclearRain"] = 4,
	["ThatHand"] = 4.5,
	["HeavyDoor"] = 4.5,
	["WhiteSake"] = 4.5,
	["TuskAct4"] = 5,
	["MagiciansRed"] = 4.5,
	["TheWorld"] = 5,
	["Metallica"] = 4,
	["Cream"] = 4.5,
	["StoneFree"] = 5,
}

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")

local function resetStandRig(standModel)
	local motor = standModel.PrimaryPart:FindFirstChild("StandMotor", true)
	if not motor then
		return
	end

	-- Reset offsets
	motor.Transform = CFrame.identity
	motor.C0 = motor:GetAttribute("DefaultC0") or motor.C0
end

function BasicStandAttacks.BasicPunch(standModel)
	print("Basic punch in module")
	local primaryPart = standModel.PrimaryPart
	local character = standModel.Parent
	if not primaryPart or not character then
		return false
	end

	if CombatUtils.IsBlocking(character) then
		print("isblocking")
		return
	end

	if CombatUtils.GetStun(character) then
		return
	end

	local standTag = standModel:FindFirstChild("StandTag")
	if not standTag then
		return false
	end

	-- Combo cooldown: prevent starting a new combo too soon
	if comboCooldowns[character] and tick() < comboCooldowns[character] then
		return false -- Still in combo cooldown
	end

	-- Check cooldown
	if punchCooldowns[standModel] and tick() < punchCooldowns[standModel] then
		return false -- Still on cooldown
	end
	punchCooldowns[standModel] = tick() + 0.4 -- Set new cooldown

	-- Initialize combo index if needed
	if not comboIndices[character] then
		comboIndices[character] = 1
	end
	local index = comboIndices[character]

	local player = Players:GetPlayerFromCharacter(character)
	local powersFolder
	local heroValue
	if player then
		heroValue = HeroManager.GetField(player, "Hero")
		powersFolder = player:FindFirstChild("Powers")
	else
		powersFolder = character:FindFirstChild("Powers")
		heroValue = powersFolder:FindFirstChild("Hero").Value
	end

	local hitboxOffset = CFrame.new(2, 0, -8)
	local rotation = CFrame.Angles(0, 0, 0)
	-- Stop idle and play punch animation
	AnimationModule.StopAllAnimations(standModel)
	if PilotModule.GetBoolPilotMode(character) then
		AnimationModule.PlayAnimation(
			standModel,
			PILOT_PUNCH_ANIMATIONS[index],
			false,
			Enum.AnimationPriority.Action,
			1.5
		)
		hitboxOffset = CFrame.new(0, 0, -3)
	else
		if heroValue == "NuclearRain" then
			AnimationModule.PlayAnimation(
				character,
				PILOT_PUNCH_ANIMATIONS[index],
				false,
				Enum.AnimationPriority.Action,
				1.5
			)
			rotation = CFrame.Angles(0, math.rad(90), 0)
			hitboxOffset = CFrame.new(2, 0, 0)
		else
			AnimationModule.PlayAnimationThenIdle(
				standModel,
				PUNCH_ANIMATIONS[index],
				false,
				Enum.AnimationPriority.Action,
				1.5
			)
		end
	end

	-- Advance combo index or finish combo
	if index == 3 then
		comboIndices[character] = 1
		comboCooldowns[character] = tick() + PUNCH_COMBO_COOLDOWN -- sec cooldown after full combo
	else
		comboIndices[character] = index + 1
	end

	-- Prepare for next combo punch
	comboIndices[character] = index % 3 + 1

	--play sound
	SoundUtils.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "PunchEffects",
		soundID = "9113305631",
		volume = 1.25,
		playbackSpeed = 2,
		looped = false,
		range = 160,
	})

	hitboxSpawner.spawnHitbox({
		Character = character,
		Damage = PUNCH_DAMAGE[standTag.Value] or 0.1,
		Size = HITBOX_SIZE,
		Offset = hitboxOffset,
		Color = BrickColor.new("Bright red"),
		Duration = 0.1,
		Transparency = 1,
		Name = "BasicPunchHitbox",
		Rotation = rotation,
	})

	--reset index in 3 seconds if index == 1
	-- Reset combo after 3 seconds of inactivity if index == 2 (after punch 1)
	if comboResetTimers[character] then
		task.cancel(comboResetTimers[character])
	end
	comboResetTimers[character] = task.delay(3, function()
		comboIndices[character] = 1
		--AnimationModule.PlayAnimation(standModel, IDLE_ANIM_ID, true, Enum.AnimationPriority.Action, 1)
	end)

	return true
end

function BasicStandAttacks.StartBarrage(character)
	print("Barrage called on module")
	local standModel = StandUtils.getStandModel(character)

	if not standModel then
		return false
	end

	local primaryPart = standModel.PrimaryPart
	if not primaryPart or not character then
		print("no primary part or no character")
		return false
	end
	local motor = primaryPart:FindFirstChild("StandMotor", true)

	local standTag = standModel:FindFirstChild("StandTag")
	if not standTag then
		print("no standtag")
		return false
	end

	if CombatUtils.IsBlocking(character) then
		print("isblocking")
		return
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag then
		print("actionflag")
		return
	end
	CombatUtils.SetActionInProgress(character, MAX_BARRAGE_DURATION)

	print("checks passed")

	local player = Players:GetPlayerFromCharacter(character)
	local heroValue
	local powersFolder
	if player then
		heroValue = HeroManager.GetField(player, "Hero")
	else
		powersFolder = character:FindFirstChild("Powers")
		heroValue = powersFolder:FindFirstChild("Hero").Value
	end

	if heroValue == "TuskAct1" or heroValue == "TuskAct2" or heroValue == "TuskAct3" then
		if player then
			if heroValue then
				HeroManager.SetField(player, "Hero", "TuskAct4")
				heroValue = HeroManager.GetField(player, "Hero")
				print(player.Name .. " is now Tusk Act 4!")
			end

			StandUtils.RemoveStand(character)
			standModel = StandUtils.SummonStand(character, "TuskAct4")

			-- Wait one frame for joints + animator
			task.wait()

			-- Reset rig state completely
			resetStandRig(standModel)

			-- Stop ANY lingering animations
			AnimationModule.StopAllAnimations(standModel)

			motor = standModel.PrimaryPart:WaitForChild("StandMotor", 2)
		end
	end

	-- Cache original motor position
	local defaultC0 = motor:GetAttribute("DefaultC0") or motor.C0
	motor:SetAttribute("DefaultC0", defaultC0)

	local STAND_BARRAGE_ANIMID = 103626308901658
	local AnimSpeed = 1.5
	local hitBoxOffset = CFrame.new(0, 0, -8)

	-- Shift forward for barrage
	if PilotModule.GetBoolPilotMode(character) then
		STAND_BARRAGE_ANIMID = 127837357946102
		AnimSpeed = 2
		hitBoxOffset = CFrame.new(0, 0, -3)
		-- Keep original orientation, only shift relative position
		--PilotModule.SetPoseOffset(character, CFrame.new(1.5, 0, 0))
	else
		if heroValue == "NuclearRain" then
			motor:SetAttribute("DefaultC0", defaultC0)
		else
			motor.C0 = defaultC0 * CFrame.new(2, 0, 0)
		end
	end

	-- Stop idle and play barrage animation
	AnimationModule.StopAllAnimations(standModel)
	local rotation = CFrame.Angles(0, 0, 0)
	if heroValue == "NuclearRain" then
		STAND_BARRAGE_ANIMID = 127837357946102 -- pilot mode / character barrage
		AnimationModule.PlayAnimation(character, STAND_BARRAGE_ANIMID, false, Enum.AnimationPriority.Action, AnimSpeed)
		rotation = CFrame.Angles(0, math.rad(90), 0)
		hitBoxOffset = CFrame.new(2, 0, 0)
	else
		AnimationModule.PlayAnimation(standModel, STAND_BARRAGE_ANIMID, false, Enum.AnimationPriority.Action, AnimSpeed)
	end

	-- Set barrage flag
	barragingFlags[character] = true

	-- Auto-stop barrage after max duration
	task.delay(MAX_BARRAGE_DURATION, function()
		if barragingFlags[character] then
			BasicStandAttacks.StopBarrage(character)
		end
	end)

	--play sound
	SoundUtils.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "BarrageEffects",
		soundID = "129949908820890",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	-- Start spawning hitboxes
	task.spawn(function()
		while barragingFlags[character] do
			hitboxSpawner.spawnHitbox({
				Character = character,
				Damage = PUNCH_DAMAGE[heroValue] / 4.5,
				Size = HITBOX_SIZE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = 0.4,
				StunDuration = 0.4,
				Transparency = 1,
				Name = "BarragePunchHitbox",
				Rotation = rotation,
				RemoveOnStun = false,
			})
			task.wait(BARRAGE_INTERVAL)
		end
	end)

	local distance = 15
	local speed = 8
	local rate = 0.05 --delay between punches

	SpawnClientVfx:FireAllClients({
		type = "Barrage",
		action = "Start",
		character = standModel,
		distance = distance,
		speed = speed,
		rate = rate,
		armCopy = true,
	})

	print("this is where I expect it to  fail")

	local conn
	conn = standModel.AncestryChanged:Connect(function(_, parent)
		if not parent then -- stand got removed from workspace
			BasicStandAttacks.StopBarrage(character)
			if conn then
				conn:Disconnect()
			end
		end
	end)

	return true
end

function BasicStandAttacks.StopBarrage(character)
	local standModel = StandUtils.getStandModel(character)

	barragingFlags[character] = false

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag then
		CombatUtils.SetActionInProgress(character, 0)
	end
	if not standModel then
		CombatUtils.SetActionInProgress(character, 0)
		return true
	end

	local motor = standModel:FindFirstChild("StandMotor", true)
	if motor and motor:IsA("Motor6D") then
		local defaultC0 = motor:GetAttribute("DefaultC0")
		if defaultC0 then
			motor.C0 = defaultC0
		end
		motor.Transform = CFrame.identity
	end

	-- Clear barrage flag
	barragingFlags[character] = nil

	local player = Players:GetPlayerFromCharacter(character)
	local powersFolder
	local heroValue
	if player then
		heroValue = HeroManager.GetField(player, "Hero")
		powersFolder = player:FindFirstChild("Powers")
	else
		powersFolder = character:FindFirstChild("Powers")
		heroValue = powersFolder:FindFirstChild("Hero")
	end

	-- Reset animation
	if heroValue == "NuclearRain" then
		AnimationModule.StopAllAnimations(character)
	else
		AnimationModule.StopAllAnimations(standModel)
	end
	AnimationModule.PlayAnimation(standModel, IDLE_ANIM_ID, true, Enum.AnimationPriority.Idle, 1)

	SoundUtils.StopSound(standModel.PrimaryPart, "BarrageEffects")
	SpawnClientVfx:FireAllClients({
		type = "Barrage",
		action = "End",
		character = standModel,
	})

	return true
end

return BasicStandAttacks
