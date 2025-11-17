--// BlockModule.lua
local BlockModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local CanBlockFunction = Instance.new("RemoteFunction")
CanBlockFunction.Name = "CanBlockFunction"
CanBlockFunction.Parent = ReplicatedStorage.Shared:WaitForChild("BasicCombat")

--// Constants
local BLOCK_ANIMATION_ID = "82125777884940" -- character loop
local STAND_BLOCK_ANIMATION = "133892948612008" -- Stand loop

local BLOCK_SLOW = 0.5

--// Services / Modules
local SlowingFieldRegistry = require(ServerScriptService.BasicCombat.Managers.SlowingFieldRegistry)
local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local PilotModule = require(game.ServerScriptService.BasicCombat:WaitForChild("PilotModule"))

--// Internal state
local activeAnimations = {} -- [character] = AnimationTrack

--=============================================================
--  Helper Functions
--=============================================================

local function stopBlockingAnimation(character)
	if activeAnimations[character] then
		activeAnimations[character]:Stop()
		activeAnimations[character] = nil
	end
end

local function freezeAnimation(track)
	if not track then
		return
	end

	task.defer(function()
		local duration = track.Length > 0 and track.Length or 1
		local freezeTime = math.max(duration - 0.1, 0)

		task.delay(freezeTime, function()
			if track and track.IsPlaying then
				track.TimePosition = duration - 0.1
				track:AdjustSpeed(0)
			end
		end)
	end)
end

--=============================================================
--  Core Functions
--=============================================================

function BlockModule.StartBlocking(character)
	if not character then
		print("no character found")
		return
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	local isBlocking = CombatUtils.GetIsBlocking(character)
	local stun = character:FindFirstChild("Stun")

	-- Prevent block during stun or conflicting actions
	if stun or actionFlag.Value or isBlocking.Value then
		print(" tried to block, but stunned or blocking or actionflag")
		return
	end

	local standModel = StandUtils.getStandModel(character)
	local entity = standModel or character
	local hum = character:FindFirstChild("Humanoid")
	local moveSpeed = character:FindFirstChild("MoveSpeed")

	-- Apply slow
	if hum and moveSpeed then
		SlowingFieldRegistry.SetSlow(character, "Block", BLOCK_SLOW)
		local baseSpeed = CombatUtils.GetMoveSpeed(character).Value
		local mult = CombatUtils.GetSlowMultiplier(character)
		hum.WalkSpeed = baseSpeed * mult
	end

	-- Set flags
	isBlocking.Value = true
	actionFlag.Value = true

	-- Stop previous animation
	stopBlockingAnimation(character)

	local player = Players:GetPlayerFromCharacter(character)
	local nonBlockStand = false
	if player then
		local powersFolder = player:FindFirstChild("Powers")
		local heroValue = powersFolder:FindFirstChild("Hero")
		if heroValue then
			if
				heroValue.Value == "Tusk Act 1"
				or heroValue.Value == "Tusk Act 2"
				or heroValue.Value == "Tusk Act 3"
				or heroValue.Value == "Nuclear Rain"
			then
				nonBlockStand = true
			end
		end
	end

	-- Choose correct animation
	local track
	if standModel and not nonBlockStand then
		if PilotModule.GetBoolPilotMode(character) then
			track = AnimationModule.PlayAnimation(entity, BLOCK_ANIMATION_ID, false, Enum.AnimationPriority.Action)
		else
			track = AnimationModule.PlayAnimation(entity, STAND_BLOCK_ANIMATION, false, Enum.AnimationPriority.Action)
		end
	else
		track = AnimationModule.PlayAnimation(character, BLOCK_ANIMATION_ID, false, Enum.AnimationPriority.Action)
	end

	if track then
		activeAnimations[character] = track
		freezeAnimation(track)
	end

	print(character.Name .. " started blocking!")
end

function BlockModule.StopBlocking(character)
	if not character then
		return
	end

	local isBlocking = CombatUtils.GetIsBlocking(character)
	local actionFlag = CombatUtils.GetActionInProgress(character)
	local hum = character:FindFirstChild("Humanoid")
	local moveSpeed = character:FindFirstChild("MoveSpeed")

	if not isBlocking.Value then
		return -- Already off, no double stop
	end

	-- Reset flags
	isBlocking.Value = false
	actionFlag.Value = false

	-- Restore movement
	if hum and moveSpeed then
		local baseSpeed = CombatUtils.GetMoveSpeed(character).Value
		SlowingFieldRegistry.ClearSlow(character, "Block")
		local mult = CombatUtils.GetSlowMultiplier(character)
		hum.WalkSpeed = baseSpeed * mult
	end

	stopBlockingAnimation(character)
	print(character.Name .. " stopped blocking!")
end

--=============================================================
--  Legacy Support (optional, for Time Erase etc.)
--=============================================================

function BlockModule.BlockOn(character)
	local isBlocking = CombatUtils.GetIsBlocking(character)
	isBlocking.Value = true

	local hum = character:FindFirstChild("Humanoid")
	local moveSpeed = character:FindFirstChild("MoveSpeed")
	-- Apply slow
	if hum and moveSpeed then
		SlowingFieldRegistry.SetSlow(character, "Block", BLOCK_SLOW)
		local baseSpeed = CombatUtils.GetMoveSpeed(character).Value
		local mult = CombatUtils.GetSlowMultiplier(character)
		hum.WalkSpeed = baseSpeed * mult
	end
end

function BlockModule.BlockOff(character)
	local isBlocking = CombatUtils.GetIsBlocking(character)
	isBlocking.Value = false

	local hum = character:FindFirstChild("Humanoid")
	local moveSpeed = character:FindFirstChild("MoveSpeed")
	-- Restore movement
	if hum and moveSpeed then
		local baseSpeed = CombatUtils.GetMoveSpeed(character).Value
		SlowingFieldRegistry.ClearSlow(character, "Block")
		local mult = CombatUtils.GetSlowMultiplier(character)
		hum.WalkSpeed = baseSpeed * mult
	end

end

--=============================================================
--  Validation Function
--=============================================================

CanBlockFunction.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	local blockValue = character:FindFirstChild("isBlocking")
	if blockValue and blockValue.Value then
		return false -- Already blocking
	end

	local actionFlag = character:FindFirstChild("ActionInProgress")
	if actionFlag and actionFlag.Value then
		return false -- Action in progress
	end

	local stun = character:FindFirstChild("Stun")
	if stun then
		return false -- Stunned
	end

	return true
end

return BlockModule
