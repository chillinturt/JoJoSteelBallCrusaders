local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local WaveModule = require(ReplicatedStorage.Shared.Ocean.WaveModule)
local StandUtils = require(game.ServerScriptService.BasicCombat.StandUtils)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OceanFolder = Remotes:WaitForChild("Ocean")

local SwimmingState = OceanFolder:WaitForChild("SwimmingState")

local OceanService = {}

local SWIM_OFFSET = 0
local JUMP_REENTRY_DELAY = 1

OceanService.CharacterStates = {}

function OceanService:GetWaterHeight(position)
	return WaveModule:GetHeight(position.X, position.Z)
end

function OceanService:SetSwimming(character, value)
	local state = self.CharacterStates[character]

	if not state then
		return
	end

	if state.Swimming == value then
		return
	end

	state.Swimming = value

	if value then
		StandUtils.StartSwimmingCorrection(character)
	else
		StandUtils.StopSwimmingCorrection(character)
	end

	local player = Players:GetPlayerFromCharacter(character)

	if player then
		SwimmingState:FireClient(player, value)
	end

	if value then
		SoundModule.PlaySound({
			Root = character,
			soundName = "EnterWaterSfx",
			soundID = "124279162156159",
			volume = 2,
			playbackSpeed = 1,
			looped = false,
		})
	end

	print("[OceanService]", character.Name, "Swimming:", value)
end

function OceanService:IsSwimming(character)
	local state = self.CharacterStates[character]
	return state and state.Swimming or false
end

function OceanService:RegisterCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	self.CharacterStates[character] = {
		Swimming = false,
		PreviousWalkSpeed = humanoid.WalkSpeed,
		LastJumpTime = 0,
		LastLeaveWaterTime = 0,
	}

	humanoid.StateChanged:Connect(function(_, newState)
		local state = self.CharacterStates[character]

		if not state then
			return
		end

		if newState == Enum.HumanoidStateType.Jumping then
			state.LastJumpTime = tick()
			state.LastLeaveWaterTime = tick()

			state.PendingEnter = false

			OceanService:SetSwimming(character, false)
		end

		if newState == Enum.HumanoidStateType.Freefall then
			state.LastLeaveWaterTime = tick()
		end
	end)

	character.Destroying:Connect(function()
		self.CharacterStates[character] = nil
	end)
end

function OceanService:UpdateCharacter(character)
	local state = self.CharacterStates[character]
	if not state then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")

	if not root or not humanoid then
		return
	end

	local seatPart = humanoid.SeatPart

	if seatPart and seatPart:IsDescendantOf(workspace.Vehicles) then
		self:SetSwimming(character, false)
		return
	end

	local waterHeight = self:GetWaterHeight(root.Position)
	local inWater = root.Position.Y <= waterHeight + SWIM_OFFSET

	local now = tick()

	local recentlyJumped = now - state.LastJumpTime < JUMP_REENTRY_DELAY

	-- Only block on Jumping, not Freefall: a player who fell into water is
	-- in Freefall with no ground contact, and must still be allowed to swim.
	-- recentlyJumped already covers the case of jumping back out.
	local airborne = humanoid:GetState() == Enum.HumanoidStateType.Jumping

	local shouldSwim = state.PendingEnter and inWater and not recentlyJumped and not airborne

	if shouldSwim and not state.Swimming then
		self:SetSwimming(character, true)
	elseif not inWater then
		self:SetSwimming(character, false)
	end
end

local function OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		OceanService:RegisterCharacter(character)
	end)

	if player.Character then
		OceanService:RegisterCharacter(player.Character)
	end
end

for _, player in Players:GetPlayers() do
	OnPlayerAdded(player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)

RunService.Heartbeat:Connect(function()
	for character in pairs(OceanService.CharacterStates) do
		if character.Parent then
			OceanService:UpdateCharacter(character)
		end
	end
end)

SwimmingState.OnServerEvent:Connect(function(player, action)
	local character = player.Character
	if not character then
		return
	end

	local state = OceanService.CharacterStates[character]
	if not state then
		return
	end

	if action == "Enter" then
		state.PendingEnter = true

		-- IMPORTANT: immediate fallback safety
		state.LastLeaveWaterTime = 0
	elseif action == "Exit" then
		state.PendingEnter = false
		OceanService:SetSwimming(character, false)
	end
end)

return OceanService
