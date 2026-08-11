local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

----------------------------------------------------------------------
-- REMOTE
----------------------------------------------------------------------

local events = ReplicatedStorage:WaitForChild("ShopEvents")
local confirmTeleportEvent = events:WaitForChild("ConfirmTeleport")
local requestLocations = events:WaitForChild("RequestTeleportLocations")

--home variables
local HomeManager = require(game.ServerScriptService.Utilities.PlayerSpawning:WaitForChild("HomeManager"))
local HomeTeleportEvent = ReplicatedStorage.Remotes:WaitForChild("HomeTeleportEvent")

local HOME_CHANNEL_TIME = 5
local MOVE_DISTANCE = 3 -- studs

local activeTeleports = {}

----------------------------------------------------------------------
-- TELEPORT FUNCTION (Your Working Logic)
----------------------------------------------------------------------

local function TeleportPlayerToPart(player, part)
	if not player.Character then
		return
	end

	local character = player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")

	if humanoid then
		-- Force unsit
		humanoid.Sit = false

		-- Break any active seat welds
		local seatPart = humanoid.SeatPart
		if seatPart then
			local weld = seatPart:FindFirstChild("SeatWeld")
			if weld then
				weld:Destroy()
			end
		end
	end

	-- Small delay ensures physics settles
	task.wait()

	if hrp and part then
		hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
	end
end

local function FindHomePart(homeName)
	local spawnFolder = Workspace.Teleports:FindFirstChild("SpawnLocations")
	if not spawnFolder then
		return nil
	end

	for _, part in ipairs(spawnFolder:GetChildren()) do
		if part:IsA("BasePart") and part.Name == homeName then
			return part
		end
	end

	return nil
end

HomeTeleportEvent.OnServerEvent:Connect(function(player)
	if activeTeleports[player] then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not hrp or not humanoid then
		return
	end

	local homeName = HomeManager.GetHome(player)
	if not homeName then
		return
	end

	local homePart = FindHomePart(homeName)
	if not homePart then
		warn(player.Name .. " has invalid home " .. homeName)
		return
	end

	activeTeleports[player] = true

	local startPosition = hrp.Position

	local elapsed = 0
	while elapsed < HOME_CHANNEL_TIME do
		task.wait(0.1)
		elapsed += 0.1

		if not player.Character or humanoid.Health <= 0 then
			activeTeleports[player] = nil
			return
		end

		if (hrp.Position - startPosition).Magnitude > MOVE_DISTANCE then
			-- Player moved too far.
			activeTeleports[player] = nil
			return
		end
	end

	TeleportPlayerToPart(player, homePart)

	activeTeleports[player] = nil
end)

----------------------------------------------------------------------
-- FIND VALID TELEPORT PART BY NAME (SERVER AUTHORITY)
----------------------------------------------------------------------

local function FindTeleportPartByName(locationName)
	local teleportsFolder = Workspace:FindFirstChild("Teleports")
	if not teleportsFolder then
		return nil
	end

	local spawnFolder = teleportsFolder:FindFirstChild("SpawnLocations")
	local shopsFolder = teleportsFolder:FindFirstChild("Shops")

	-- 1️⃣ Check SpawnLocations
	if spawnFolder then
		for _, obj in ipairs(spawnFolder:GetChildren()) do
			if obj:IsA("BasePart") and obj.Name == locationName then
				return obj
			end
		end
	end

	-- 2️⃣ Check Shops (any Teleport part inside Shops folder)
	if shopsFolder then
		for _, obj in ipairs(shopsFolder:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name == "Teleport" then
				local shopModel = obj:FindFirstAncestorOfClass("Model")
				if shopModel and shopModel.Name == locationName then
					return obj
				end
			end
		end
	end

	print("Searching for:", locationName)

	for _, obj in ipairs(Workspace.Teleports.Shops:GetDescendants()) do
		if obj.Name == "GardenShop" then
			print("Found GardenShop instance:", obj:GetFullName())
		end
	end

	return nil
end

----------------------------------------------------------------------
-- OPTIONAL: SIMPLE TELEPORT COOLDOWN (ANTI-SPAM)
----------------------------------------------------------------------

local teleportCooldown = {}
local TELEPORT_DELAY = 1.5

local function CanTeleport(player)
	local lastTime = teleportCooldown[player]
	if not lastTime then
		return true
	end

	return (tick() - lastTime) >= TELEPORT_DELAY
end

----------------------------------------------------------------------
-- REMOTE CONNECTION
----------------------------------------------------------------------

confirmTeleportEvent.OnServerEvent:Connect(function(player, locationName)
	-- Validate input type
	if typeof(locationName) ~= "string" then
		warn("Teleport exploit attempt: invalid type from", player.Name)
		return
	end

	-- Anti-spam
	if not CanTeleport(player) then
		return
	end

	-- Find location securely on server
	local teleportPart = FindTeleportPartByName(locationName)

	if not teleportPart then
		warn("Teleport exploit attempt: invalid location from", player.Name)
		return
	end

	-- Update cooldown
	teleportCooldown[player] = tick()

	-- Teleport player
	TeleportPlayerToPart(player, teleportPart)
end)

requestLocations.OnServerInvoke = function(player)
	local teleportLocations = {}
	local shopsFolder = Workspace.Teleports.Shops
	local spawnFolder = Workspace.Teleports.SpawnLocations

	-- Spawn points
	for _, obj in ipairs(spawnFolder:GetChildren()) do
		if obj:IsA("BasePart") then
			table.insert(teleportLocations, obj.Name)
		end
	end

	-- Shops (recursive safe)
	for _, obj in ipairs(shopsFolder:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "Teleport" then
			local shopModel = obj:FindFirstAncestorOfClass("Model")
			if shopModel then
				table.insert(teleportLocations, shopModel.Name)
			end
		end
	end

	table.sort(teleportLocations)

	return teleportLocations
end

----------------------------------------------------------------------
-- CLEANUP WHEN PLAYER LEAVES
----------------------------------------------------------------------

Players.PlayerRemoving:Connect(function(player)
	teleportCooldown[player] = nil
end)
