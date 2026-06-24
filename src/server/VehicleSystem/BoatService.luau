local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CashSystem = require(game.ServerScriptService.DataSaving:WaitForChild("CashSystem"))
local BoatDefinitions = require(script.Parent.BoatDefinitions)
local BoatController = require(script.Parent.BoatController)
local WaveModule = require(ReplicatedStorage.Shared.Ocean.WaveModule)

local BoatService = {}

-- player → { Controller, Model, BoatId }
local activeBoats = {}

-- Folder for spawned boats in workspace
local vehicleFolder = Workspace:FindFirstChild("Vehicles") or (function()
	local f = Instance.new("Folder")
	f.Name = "Vehicles"
	f.Parent = Workspace
	return f
end)()

------------------------------------------------
-- Helpers
------------------------------------------------

local function getSpawnCFrame(npcModel)
	-- Prefer an explicit BoatSpawn part on the NPC model
	local anchor = npcModel:FindFirstChild("BoatSpawn")
	if anchor and anchor:IsA("BasePart") then
		return CFrame.new(anchor.Position.X, WaveModule.OCEAN_HEIGHT, anchor.Position.Z)
	end

	-- Fallback: 30 studs in front of the NPC at ocean height
	local root = npcModel.PrimaryPart or npcModel:FindFirstChildOfClass("BasePart")
	if root then
		local spawnPos = root.Position + root.CFrame.LookVector * 30
		return CFrame.new(spawnPos.X, WaveModule.OCEAN_HEIGHT, spawnPos.Z)
	end

	return CFrame.new(0, WaveModule.OCEAN_HEIGHT, 0)
end

------------------------------------------------
-- Public API
------------------------------------------------

function BoatService.GetBoatDefinition(boatId)
	return BoatDefinitions[boatId]
end

-- Returns a price-sorted list of { Id, Data } for boats sold by this NPC.
function BoatService.GetBoatsForDealer(dealerName)
	local boats = {}
	for boatId, def in pairs(BoatDefinitions) do
		if def.Dealer == dealerName then
			table.insert(boats, { Id = boatId, Data = def })
		end
	end
	table.sort(boats, function(a, b)
		return a.Data.Price < b.Data.Price
	end)
	return boats
end

function BoatService.IsBoatDealer(npcName)
	for _, def in pairs(BoatDefinitions) do
		if def.Dealer == npcName then
			return true
		end
	end
	return false
end

function BoatService.HasBoat(player)
	return activeBoats[player] ~= nil
end

-- Spawns a boat for the player near the given dealer NPC.
-- Returns: success (bool), message (string)
function BoatService.BuyBoat(player, boatId, npcModel)
	local def = BoatDefinitions[boatId]
	if not def then
		return false, "Unknown boat."
	end

	if activeBoats[player] then
		return false, "Despawn your current boat first."
	end

	if def.Price > 0 then
		if not CashSystem.SpendCash(player, def.Price) then
			return false, "You need $" .. def.Price .. " to buy a " .. def.Name .. "."
		end
	end

	local vehicles = ReplicatedStorage:FindFirstChild("Vehicles")
	local template = vehicles and vehicles:FindFirstChild(def.ModelName)
	if not template then
		warn("BoatService: model not found in ReplicatedStorage.Vehicles:", def.ModelName)
		if def.Price > 0 then
			CashSystem.AddCash(player, def.Price)
		end
		return false, "This boat isn't available yet."
	end

	local boatModel = template:Clone()
	boatModel:PivotTo(getSpawnCFrame(npcModel))
	boatModel.Parent = vehicleFolder

	local controller = BoatController.new(boatModel, def)
	activeBoats[player] = { Controller = controller, Model = boatModel, BoatId = boatId }

	return true, def.Name .. " spawned near the dock!"
end

-- Removes the player's current boat.
-- Returns: success (bool), message (string)
function BoatService.DespawnBoat(player)
	local entry = activeBoats[player]
	if not entry then
		return false, "You don't have a boat to despawn."
	end

	entry.Controller.Destroy()
	activeBoats[player] = nil
	return true, "Boat despawned."
end

------------------------------------------------
-- Lifecycle
------------------------------------------------

RunService.Heartbeat:Connect(function(dt)
	for _, entry in pairs(activeBoats) do
		entry.Controller.Update(dt)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if activeBoats[player] then
		activeBoats[player].Controller.Destroy()
		activeBoats[player] = nil
	end
end)

return BoatService
