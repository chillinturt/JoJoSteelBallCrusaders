local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local AnimationModule = require(ServerScriptService.BasicCombat.AnimationModule)

-- Example animation IDs (replace with your own)
local animations = {
	--96767618650505 old run anim
	Forward = "111996277762833",
	Backward = "74432122888392",
	Left = "127264779281230",
	Right = "137936019211555",
	Idle = "104714640622145",
	Fall = "80938111042689", -- ✅ falling anim
	Land = "74308587429244", -- ✅ landing anim
}

-- Track active animations
local activeTracks = {}
local lastDirection = {}

-- Decide movement direction relative to character facing
local function getMovementDirection(character, humanoid)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return "Idle"
	end

	-- ✅ Fall overrides everything
	if humanoid.FloorMaterial == Enum.Material.Air then
		return "Fall"
	end

	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude < 0.1 then
		return "Idle"
	end

	local forward = root.CFrame.LookVector
	local dot = forward:Dot(moveDir.Unit)
	local cross = forward:Cross(moveDir.Unit)

	if dot > 0.7 then
		return "Forward"
	elseif dot < -0.7 then
		return "Backward"
	elseif cross.Y > 0 then
		return "Left"
	elseif cross.Y < 0 then
		return "Right"
	else
		return "Idle"
	end
end

-- Play the correct animation when state changes
local function onStateChanged(player, humanoid, character)
	local direction = getMovementDirection(character, humanoid)
	local animId = animations[direction]

	-- Detect landing (Fall → Grounded)
	if lastDirection[player] == "Fall" and direction ~= "Fall" and humanoid.FloorMaterial ~= Enum.Material.Air then
		-- Stop falling anim
		if activeTracks[player] then
			AnimationModule.StopAnimation(activeTracks[player].track)
			activeTracks[player] = nil
		end

		-- Play landing anim once
		local landTrack =
			AnimationModule.PlayAnimation(character, animations.Land, false, Enum.AnimationPriority.Action, 1.5)
		if landTrack then
			-- When finished, go into the correct walk/idle
			landTrack.Stopped:Connect(function()
				onStateChanged(player, humanoid, character)
			end)
		end

		lastDirection[player] = direction
		return
	end

	-- If the new direction is the same, do nothing
	if activeTracks[player] and activeTracks[player].direction == direction then
		lastDirection[player] = direction
		return
	end

	-- Stop old track if any
	if activeTracks[player] then
		AnimationModule.StopAnimation(activeTracks[player].track)
		activeTracks[player] = nil
	end

	-- Play new animation (if not Idle)
	if direction ~= "Idle" then
		local track = AnimationModule.PlayAnimation(character, animId, true, Enum.AnimationPriority.Movement, 1)
		activeTracks[player] = { track = track, direction = direction }
	end

	lastDirection[player] = direction
end

-- Setup when player spawns
local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		-- Movement direction changed
		humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
			onStateChanged(player, humanoid, character)
		end)

		-- Air/ground state changed
		humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
			onStateChanged(player, humanoid, character)
		end)
	end
end

-- Setup for new players
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)
