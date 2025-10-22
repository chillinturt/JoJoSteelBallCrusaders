local Players = game:GetService("Players")

local HURTBOX_SIZE = Vector3.new(4, 6, 4) -- Adjust size as needed

-- Function to create a hurtbox
local function createHurtbox(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	-- Check if hurtbox already exists
	if character:FindFirstChild("Hurtbox") then
		return
	end

	-- Create the hurtbox part
	local hurtbox = Instance.new("Part")
	hurtbox.Name = "Hurtbox"
	hurtbox.Size = HURTBOX_SIZE
	hurtbox.Transparency = 1
	hurtbox.CanCollide = false
	hurtbox.Massless = true
	hurtbox.Anchored = false
	hurtbox.Color = Color3.fromRGB(255, 0, 0) -- Red for debugging (can be made invisible later)
	hurtbox.Position = rootPart.CFrame.Position
	hurtbox.CFrame = character:WaitForChild("HumanoidRootPart").CFrame

	-- Parent to character
	hurtbox.Parent = character

	-- Weld hurtbox to HumanoidRootPart
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = hurtbox
	weld.Parent = hurtbox
end

-- Function to add hurtbox when player spawns
local function onCharacterAdded(character)
	task.wait(0.1) -- Small delay to ensure character loads properly
	createHurtbox(character)
end

-- Listen for new players joining
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)

-- Add hurtboxes to already spawned players (if script is reloaded)
for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		onCharacterAdded(player.Character)
	end
end
