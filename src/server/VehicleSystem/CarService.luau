local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CashSystem = require(game.ServerScriptService.DataSaving:WaitForChild("CashSystem"))
local CarDefinitions = require(script.Parent.CarDefinitions)
local CarController = require(script.Parent.CarController)

local CarService = {}

-- player → { Controller, Model, CarId }
local activeCars = {}

-- Folder for spawned vehicles in workspace (shared with BoatService/HoverService).
local vehicleFolder = Workspace:FindFirstChild("Vehicles") or (function()
	local f = Instance.new("Folder")
	f.Name = "Vehicles"
	f.Parent = Workspace
	return f
end)()

local vehicleEvents = ReplicatedStorage:FindFirstChild("VehicleEvents") or (function()
	local f = Instance.new("Folder")
	f.Name = "VehicleEvents"
	f.Parent = ReplicatedStorage
	return f
end)()

local carHandbrakeRemote = vehicleEvents:FindFirstChild("CarHandbrakeInput") or (function()
	local e = Instance.new("RemoteEvent")
	e.Name = "CarHandbrakeInput"
	e.Parent = vehicleEvents
	return e
end)()

------------------------------------------------
-- Helpers
------------------------------------------------

local function getSpawnCFrame(npcModel)
	-- Prefer an explicit CarSpawn part on the NPC model. Spawned a couple
	-- studs above it since cars are real physics bodies now (unlike the
	-- kinematic boats/hovers) -- letting it drop a little avoids clipping
	-- into whatever the anchor part is sitting on.
	local anchor = npcModel:FindFirstChild("CarSpawn")
	if anchor and anchor:IsA("BasePart") then
		return anchor.CFrame + Vector3.new(0, 2, 0)
	end

	-- Fallback: 30 studs in front of the NPC.
	local root = npcModel.PrimaryPart or npcModel:FindFirstChildOfClass("BasePart")
	if root then
		local spawnPos = root.Position + root.CFrame.LookVector * 30
		return CFrame.new(spawnPos.X, root.Position.Y + 2, spawnPos.Z)
	end

	return CFrame.new(0, 10, 0)
end

------------------------------------------------
-- Public API
------------------------------------------------

function CarService.GetCarDefinition(carId)
	return CarDefinitions[carId]
end

-- Returns a price-sorted list of { Id, Data } for cars sold by this NPC.
function CarService.GetCarsForDealer(dealerName)
	local cars = {}
	for carId, def in pairs(CarDefinitions) do
		if def.Dealer == dealerName then
			table.insert(cars, { Id = carId, Data = def })
		end
	end
	table.sort(cars, function(a, b)
		return a.Data.Price < b.Data.Price
	end)
	return cars
end

function CarService.IsCarDealer(npcName)
	for _, def in pairs(CarDefinitions) do
		if def.Dealer == npcName then
			return true
		end
	end
	return false
end

function CarService.HasCar(player)
	return activeCars[player] ~= nil
end

-- Spawns a car for the player near the given dealer NPC.
-- Returns: success (bool), message (string)
function CarService.BuyCar(player, carId, npcModel)
	local def = CarDefinitions[carId]
	if not def then
		return false, "Unknown car."
	end

	if activeCars[player] then
		return false, "Despawn your current car first."
	end

	if def.Price > 0 then
		if not CashSystem.SpendCash(player, def.Price) then
			return false, "You need $" .. def.Price .. " to buy a " .. def.Name .. "."
		end
	end

	local vehicles = ReplicatedStorage:FindFirstChild("Vehicles")
	local template = vehicles and vehicles:FindFirstChild(def.ModelName)
	if not template then
		warn("CarService: model not found in ReplicatedStorage.Vehicles:", def.ModelName)
		if def.Price > 0 then
			CashSystem.AddCash(player, def.Price)
		end
		return false, "This car isn't available yet."
	end

	local carModel = template:Clone()
	carModel:PivotTo(getSpawnCFrame(npcModel))
	carModel.Parent = vehicleFolder

	local controller = CarController.new(carModel, def)
	activeCars[player] = { Controller = controller, Model = carModel, CarId = carId }

	return true, def.Name .. " spawned!"
end

-- Removes the player's current car.
-- Returns: success (bool), message (string)
function CarService.DespawnCar(player)
	local entry = activeCars[player]
	if not entry then
		return false, "You don't have a car to despawn."
	end

	entry.Controller.Destroy()
	activeCars[player] = nil
	return true, "Car despawned."
end

------------------------------------------------
-- Handbrake input (held while turning to drift)
------------------------------------------------

-- Not keyed off activeCars[player]: the sender may be riding someone else's
-- car. Each controller validates the sender is its own seat's occupant, so
-- broadcasting is safe -- only the car they're actually sitting in reacts.
carHandbrakeRemote.OnServerEvent:Connect(function(player, isActive)
	for _, entry in pairs(activeCars) do
		entry.Controller.SetHandbrake(player, isActive == true)
	end
end)

------------------------------------------------
-- Lifecycle
------------------------------------------------

RunService.Heartbeat:Connect(function(dt)
	for _, entry in pairs(activeCars) do
		entry.Controller.Update(dt)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if activeCars[player] then
		activeCars[player].Controller.Destroy()
		activeCars[player] = nil
	end
end)

return CarService
