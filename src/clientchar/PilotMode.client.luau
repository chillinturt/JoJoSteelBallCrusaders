local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local pilotEvent = replicatedStorage.Shared.BasicCombat:WaitForChild("PilotMode")
local pilotMovementEvent = replicatedStorage.Shared.BasicCombat:WaitForChild("PilotMovement")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local inPilotMode = false
local cooldown = false
local activeKeys = {}

--camera vars
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cameraEvent = replicatedStorage.Shared.BasicCombat:WaitForChild("PilotCameraEvent")
local defaultSubject = nil

-- Key handling
userInputService.InputBegan:Connect(function(input, processed)
	if processed or cooldown then
		return
	end

	if input.KeyCode == Enum.KeyCode.W then
		activeKeys.W = true
	end
	if input.KeyCode == Enum.KeyCode.A then
		activeKeys.A = true
	end
	if input.KeyCode == Enum.KeyCode.S then
		activeKeys.S = true
	end
	if input.KeyCode == Enum.KeyCode.D then
		activeKeys.D = true
	end

	if input.KeyCode == Enum.KeyCode.H then
		local char = player.Character
		if not char then
			return
		end

		-- Toggle pilot mode
		inPilotMode = not inPilotMode
		pilotEvent:FireServer(inPilotMode)

		cooldown = true
		task.wait(0.5)
		cooldown = false
	end
end)

userInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		activeKeys.W = false
	end
	if input.KeyCode == Enum.KeyCode.A then
		activeKeys.A = false
	end
	if input.KeyCode == Enum.KeyCode.S then
		activeKeys.S = false
	end
	if input.KeyCode == Enum.KeyCode.D then
		activeKeys.D = false
	end
end)

-- Send movement + facing direction
runService.Heartbeat:Connect(function()
	if inPilotMode then
		local moveDir = Vector3.zero
		if activeKeys.W then
			moveDir += Vector3.new(0, 0, -1)
		end
		if activeKeys.S then
			moveDir += Vector3.new(0, 0, 1)
		end
		if activeKeys.A then
			moveDir += Vector3.new(-1, 0, 0)
		end
		if activeKeys.D then
			moveDir += Vector3.new(1, 0, 0)
		end

		if moveDir.Magnitude > 0 then
			moveDir = moveDir.Unit
		end

		local facingDir = camera.CFrame.LookVector
		pilotMovementEvent:FireServer(moveDir, facingDir)
	end
end)

cameraEvent.OnClientEvent:Connect(function(action, target)
	if action == "follow" and target then
		defaultSubject = camera.CameraSubject
		camera.CameraSubject = target
		camera.CameraType = Enum.CameraType.Custom -- or Scriptable if you want to customize more
	elseif action == "reset" then
		if defaultSubject then
			camera.CameraSubject = defaultSubject
		else
			-- fallback to player's humanoid
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					camera.CameraSubject = humanoid
				end
			end
		end
		camera.CameraType = Enum.CameraType.Custom
	end
end)
