local Players = game:GetService("Players")

local function stabilizeCharacter(character)
	local hrp = character:WaitForChild("HumanoidRootPart")

	-- Remove any existing gyros
	for _, obj in pairs(hrp:GetChildren()) do
		if obj:IsA("BodyGyro") then
			obj:Destroy()
		end
	end

	-- Add BodyGyro to lock tilt
	local gyro = Instance.new("BodyGyro")
	gyro.Name = "TiltLockGyro"
	gyro.D = 1000 -- damping, very high to resist tipping
	gyro.P = 20000 -- power, very strong to counter collisions
	gyro.MaxTorque = Vector3.new(400000, 0, 400000) -- lock X and Z only
	gyro.CFrame = CFrame.new(hrp.Position) -- initial orientation upright
	gyro.Parent = hrp
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(stabilizeCharacter)
end)
