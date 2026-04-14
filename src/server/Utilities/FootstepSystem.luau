local FootstepSystem = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundUtils = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

-- === STATE ===
local footstepDisabledUntil = {}
local lastFootstep = {}
local connections = {}

-- === CONFIG ===
local STEP_INTERVAL = 10

local FootstepSounds = {
	Grass = "98069158661569",
	Concrete = "81623756670923",
	Wood = "87921439933530",
	Metal = "81623756670923",
	Default = "81623756670923",
}

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

-- === HELPERS ===

local function getMaterialUnderHumanoid(humanoid)
	local root = humanoid.RootPart
	if not root then
		return nil
	end

	raycastParams.FilterDescendantsInstances = { humanoid.Parent }

	local ray = workspace:Raycast(root.Position, Vector3.new(0, -5, 0), raycastParams)

	return ray and ray.Material.Name or nil
end

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
		range = 400,
	})
end

-- === CORE ===

function FootstepSystem.SetupCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")

	lastFootstep[player] = root.Position

	-- Cleanup old connection
	if connections[player] then
		connections[player]:Disconnect()
	end

	connections[player] = RunService.Heartbeat:Connect(function()
		-- Suppressed?
		if footstepDisabledUntil[player] and tick() < footstepDisabledUntil[player] then
			lastFootstep[player] = root.Position
			return
		end

		if humanoid.Health <= 0 then
			return
		end

		if humanoid.FloorMaterial ~= Enum.Material.Air then
			local dist = (root.Position - lastFootstep[player]).Magnitude
			if dist >= STEP_INTERVAL then
				playFootstep(player, humanoid)
				lastFootstep[player] = root.Position
			end
		end
	end)
end

-- === PUBLIC API ===

function FootstepSystem.Disable(player, duration)
	footstepDisabledUntil[player] = tick() + (duration or 0.3)
end

function FootstepSystem.Reset(player, character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		lastFootstep[player] = root.Position
	end
end

function FootstepSystem.Enable(player)
	footstepDisabledUntil[player] = nil
end

function FootstepSystem.Cleanup(player)
	if connections[player] then
		connections[player]:Disconnect()
		connections[player] = nil
	end
	lastFootstep[player] = nil
	footstepDisabledUntil[player] = nil
end

-- === PLAYER HOOKS ===

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		FootstepSystem.SetupCharacter(player, character)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		FootstepSystem.SetupCharacter(player, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		FootstepSystem.SetupCharacter(player, character)
	end)
end

return FootstepSystem
