local PilotMode = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local pilotMovementEvent = Instance.new("RemoteEvent")
pilotMovementEvent.Name = "PilotMovement"
pilotMovementEvent.Parent = replicatedStorage.Shared.BasicCombat

local exitPilotEvent = Instance.new("BindableEvent")
exitPilotEvent.Name = "ExitPilotMode"
exitPilotEvent.Parent = replicatedStorage.Shared.BasicCombat

local CameraEvent = Instance.new("RemoteEvent")
CameraEvent.Name = "PilotCameraEvent"
CameraEvent.Parent = replicatedStorage.Shared:WaitForChild("BasicCombat")

local pilotData = {} -- player => { motor, originalC0, targetPos, facingCF, maxDistance, pilotMode }
local pilotConnections = {} -- stands -> connection

local CombatUtils = require(script.Parent.CombatUtils)
local StandUtils = require(serverScriptService.BasicCombat:WaitForChild("StandUtils"))

function PilotMode.EnterPilotMode(character, stand)
	local canPilotMode = stand:FindFirstChild("CanPilotMode")
	if not canPilotMode then
		return
	end

	print("entered pillot mode called")
	local standRoot = stand.PrimaryPart
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not standRoot or not playerRoot then
		return
	end

	print("roots found")

	-- Clear old data/connections
	if pilotConnections[character] then
		pilotConnections[character]:Disconnect()
	end
	pilotConnections[character] = nil
	pilotData[character] = nil

	-- Find Motor6D
	local motor = standRoot:FindFirstChildWhichIsA("Motor6D", true)
	if not motor then
		return
	end

	-- Position stand initially
	stand:SetPrimaryPartCFrame(playerRoot.CFrame * CFrame.new(-2, 1, 3))

	-- Save motor info
	pilotData[character] = {
		stand = stand,
		originalMotor = motor,
		originalC0 = motor.C0,
		originalC1 = motor.C1,
		motorParent = motor.Parent,
		pilotMode = true,
		targetCF = standRoot.CFrame,
		standTag = stand:FindFirstChild("StandTag").Value,
		poseOffset = CFrame.identity,
	}

	-- Remove Motor6D so stand is free
	motor.Part0 = stand:FindFirstChild("Collision")

	-- Force network ownership to server
	standRoot:SetNetworkOwner(nil)

	-- Turn off collisions instead of anchoring
	for _, part in ipairs(stand:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false -- so animations still work
			part.CanCollide = false -- prevents pushing player
			part.CanTouch = false
			part.CanQuery = true
		end
	end

	-- Disable player movement
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	local player = Players:GetPlayerFromCharacter(character)
	local pilotCameraOrigin = stand:FindFirstChild("PilotCameraOrigin")
	if player then
		-- Tell client camera to follow stand
		CameraEvent:FireClient(player, "follow", pilotCameraOrigin)
	end

	pilotConnections[character] = RunService.Heartbeat:Connect(function()
		local data = pilotData[character]
		if not data or not data.pilotMode then
			return
		end

		humanoid.WalkSpeed = 0

		-- Reapply safety every frame
		for _, part in ipairs(data.stand:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				--part.CanTouch = true
				--part.CanQuery = false
				if part.Name == "ProjectileSpawnPoint" then
					part.Anchored = true
				end
			end
			if part.Name == "Hurtbox" then
				part.CanTouch = false
				part.CanQuery = true
			end
		end

		-- Move the stand
		data.stand:PivotTo(data.targetCF * (data.poseOffset or CFrame.identity))
		data.poseOffset = CFrame.identity -- reset pose
	end)
end

function PilotMode.ExitPilotMode(character)
	-- Stop movement loop
	if pilotConnections[character] then
		pilotConnections[character]:Disconnect()
		pilotConnections[character] = nil
	end

	local data = pilotData[character]
	if not data or not data.stand or not data.originalMotor then
		pilotData[character] = nil -- fully clear it anyway
		return
	end

	-- Restore stand
	StandUtils.RemoveStand(character)
	StandUtils.SummonStand(character, data.standTag)

	-- Restore player movement
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = CombatUtils.GetMoveSpeed(character).Value
		humanoid.JumpPower = CombatUtils.GetJumpHeight(character).Value
	end

	-- Remove data entirely
	pilotData[character] = nil

	--restore cam
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		-- Tell client camera to follow stand
		CameraEvent:FireClient(player, "reset")
	end
end

-- this event is used for when the player desummons their pilot mode stand in StandUtils
exitPilotEvent.Event:Connect(function(character)
	-- Stop movement loop
	if pilotConnections[character] then
		pilotConnections[character]:Disconnect()
		pilotConnections[character] = nil
	end

	local data = pilotData[character]
	if not data or not data.stand or not data.originalMotor then
		pilotData[character] = nil -- fully clear it anyway
		return
	end

	-- Restore stand
	StandUtils.RemoveStand(character)
	StandUtils.SummonStand(character, data.standTag)

	-- Restore player movement
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = CombatUtils.GetMoveSpeed(character).Value
		humanoid.JumpPower = CombatUtils.GetJumpHeight(character).Value
	end

	-- Remove data entirely
	pilotData[character] = nil

	--restore cam
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		-- Tell client camera to follow stand
		CameraEvent:FireClient(player, "reset")
	end
end)

function PilotMode.SetPoseOffset(character, offsetCF)
	local d = pilotData[character]
	if d and d.pilotMode then
		d.poseOffset = offsetCF or CFrame.identity
	end
end

function PilotMode.ClearPoseOffset(character)
	local d = pilotData[character]
	if d then
		d.poseOffset = CFrame.identity
	end
end

function PilotMode.GetBoolPilotMode(character)
	local data = pilotData[character]
	if not data then
		return false
	end
	return data.pilotMode
end

game.Players.PlayerRemoving:Connect(function(player)
	local character = player.Character
	if pilotConnections[character] then
		pilotConnections[character]:Disconnect()
		pilotConnections[character] = nil
	end
	if pilotData[character] then
		pilotData[character] = nil
	end
end)

-- Movement updates from client
pilotMovementEvent.OnServerEvent:Connect(function(player, moveDir, facingDir)
	local data = pilotData[player.Character]
	if not data or not data.pilotMode then
		return
	end

	local standRoot = data.stand.PrimaryPart
	if not standRoot then
		return
	end

	local baseCF = CFrame.lookAt(standRoot.Position, standRoot.Position + facingDir)
	local speed = 1
	local moveOffset = Vector3.zero

	if moveDir.Magnitude > 0 then
		moveOffset = baseCF:VectorToWorldSpace(moveDir) * speed

		-- Raycast to check for walls
		local rayOrigin = standRoot.Position
		local rayDirection = moveOffset
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { data.stand, player.Character } -- ignore stand & player
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
		if result then
			-- Hit a wall, move only up to hit point (with a small buffer)
			local hitPos = result.Position
			local directionUnit = moveOffset.Unit
			local distance = (hitPos - rayOrigin).Magnitude - 0.1
			if distance < 0 then
				distance = 0
			end
			moveOffset = directionUnit * distance
		end
	end

	data.targetCF = baseCF + moveOffset
end)

return PilotMode
