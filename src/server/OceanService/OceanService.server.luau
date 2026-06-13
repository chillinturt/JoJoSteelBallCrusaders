local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WaveModule = require(ReplicatedStorage.Shared.Ocean.WaveModule)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OceanFolder = Remotes:WaitForChild("Ocean")

local SwimmingState = OceanFolder:WaitForChild("SwimmingState")

local OceanService = {}

local SWIM_OFFSET = 3
local EXIT_HEIGHT = 6
local JUMP_REENTRY_DELAY = 0.8

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

	local player = Players:GetPlayerFromCharacter(character)

	if player then
		SwimmingState:FireClient(player, value)
	end

	print("[OceanService]", character.Name, "Swimming:", value)
end

function OceanService:SnapToSurface(character, root, waterHeight)
	local state = self.CharacterStates[character]
	if not state then
		return
	end

	local surfaceY = waterHeight + SWIM_OFFSET

	root.CFrame = CFrame.new(root.Position.X, surfaceY, root.Position.Z)
		* CFrame.fromMatrix(Vector3.zero, root.CFrame.XVector, root.CFrame.YVector, root.CFrame.ZVector)

	root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
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

	local waterHeight = self:GetWaterHeight(root.Position)
	local inWater = root.Position.Y <= waterHeight - 1

	local now = tick()

	local recentlyJumped = now - state.LastJumpTime < JUMP_REENTRY_DELAY

	local airborne = humanoid:GetState() == Enum.HumanoidStateType.Freefall
		or humanoid:GetState() == Enum.HumanoidStateType.Jumping

	-- HARD RULE: do NOT allow swimming while airborne
	local canSwim = not airborne and not recentlyJumped

	local shouldSwim = state.PendingEnter and inWater and not recentlyJumped and not airborne

	if shouldSwim and not state.Swimming then
		self:SnapToSurface(character, root, waterHeight)
		print("START SWIM", character.Name, humanoid:GetState())
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
