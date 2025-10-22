-- ServerScript: FootstepSystem
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundUtils = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

-- Configure sounds per material
local FootstepSounds = {
	Grass = "98069158661569",
	Concrete = "81623756670923",
	Wood = "87921439933530",
	Metal = "81623756670923",
	Default = "81623756670923",
}

-- Distance between footsteps in studs
local STEP_INTERVAL = 10 -- Adjust to your liking

-- Track last footstep position for each player
local lastFootstep = {}

-- Raycast parameters
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

-- Helper: detect material under character
local function getMaterialUnderHumanoid(humanoid)
	local root = humanoid.RootPart
	if not root then
		return nil
	end

	local origin = root.Position
	local direction = Vector3.new(0, -5, 0) -- cast downward
	raycastParams.FilterDescendantsInstances = { humanoid.Parent }

	local ray = workspace:Raycast(origin, direction, raycastParams)
	if ray and ray.Instance then
		return ray.Material.Name
	end
	return nil
end

-- Helper: play footstep sound
local function playFootstep(player, humanoid)
	local root = humanoid.RootPart
	if not root then
		return
	end

	local material = getMaterialUnderHumanoid(humanoid) or "Default"
	local soundId = FootstepSounds[material] or FootstepSounds.Default

	SoundUtils.PlaySound({
		Root = root,
		soundName = "Footstep",
		soundID = soundId,
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 100,
	})
end

-- Setup footstep tracking for a player
local function setupFootsteps(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")

	lastFootstep[player] = root.Position

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not humanoid or humanoid.Health <= 0 then
			if connection then
				connection:Disconnect()
			end
			lastFootstep[player] = nil
			return
		end

		-- Only play footsteps if touching the ground
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			local dist = (root.Position - lastFootstep[player]).Magnitude
			if dist >= STEP_INTERVAL then
				playFootstep(player, humanoid)
				lastFootstep[player] = root.Position
			end
		end
	end)
end

-- Connect for new characters
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		setupFootsteps(player, character)
	end)
end)

-- Connect existing players
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		setupFootsteps(player, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		setupFootsteps(player, character)
	end)
end
