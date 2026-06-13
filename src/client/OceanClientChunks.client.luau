local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local WaveModule = require(ReplicatedStorage.Shared.Ocean.WaveModule)

local OceanFolder = workspace:WaitForChild("OceanFolder")

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local CHUNK_SIZE = 512

local RENDER_RADIUS = 3

local UPDATE_INTERVAL = 1

--------------------------------------------------

local LoadedChunks = {}

local LastUpdate = 0

--------------------------------------------------
-- CHUNK CREATION
--------------------------------------------------

local function ChunkKey(x, z)
	return tostring(x) .. "," .. tostring(z)
end

local function CreateChunk(chunkX, chunkZ)
	local key = ChunkKey(chunkX, chunkZ)

	if LoadedChunks[key] then
		return
	end

	local oceanPart = Instance.new("Part")

	oceanPart.Name = key

	oceanPart.Anchored = true
	oceanPart.CanCollide = false

	oceanPart.Material = Enum.Material.Glass
	oceanPart.Transparency = 0.35

	oceanPart.Size = Vector3.new(CHUNK_SIZE, 1, CHUNK_SIZE)

	oceanPart.Position = Vector3.new(chunkX * CHUNK_SIZE, WaveModule.OCEAN_HEIGHT, chunkZ * CHUNK_SIZE)

	oceanPart.Parent = OceanFolder

	LoadedChunks[key] = oceanPart
end

--------------------------------------------------
-- CHUNK DESTRUCTION
--------------------------------------------------

local function DestroyChunk(chunkX, chunkZ)
	local key = ChunkKey(chunkX, chunkZ)

	local chunk = LoadedChunks[key]

	if chunk then
		chunk:Destroy()
		LoadedChunks[key] = nil
	end
end

--------------------------------------------------
-- UPDATE CHUNKS
--------------------------------------------------

local function UpdateChunks()
	local character = LocalPlayer.Character

	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	local centerChunkX = math.floor(root.Position.X / CHUNK_SIZE)

	local centerChunkZ = math.floor(root.Position.Z / CHUNK_SIZE)

	local needed = {}

	for x = -RENDER_RADIUS, RENDER_RADIUS do
		for z = -RENDER_RADIUS, RENDER_RADIUS do
			local chunkX = centerChunkX + x
			local chunkZ = centerChunkZ + z

			local key = ChunkKey(chunkX, chunkZ)

			needed[key] = true

			CreateChunk(chunkX, chunkZ)
		end
	end

	for key in pairs(LoadedChunks) do
		if not needed[key] then
			LoadedChunks[key]:Destroy()

			LoadedChunks[key] = nil
		end
	end
end

--------------------------------------------------
-- LOOP
--------------------------------------------------

RunService.RenderStepped:Connect(function()
	local now = tick()

	if now - LastUpdate >= UPDATE_INTERVAL then
		LastUpdate = now

		UpdateChunks()
	end
end)
