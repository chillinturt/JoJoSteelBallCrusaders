local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CashSystem = require(game.ServerScriptService.DataSaving:WaitForChild("CashSystem"))
local HoverDefinitions = require(script.Parent.HoverDefinitions)
local HoverController = require(script.Parent.HoverController)
local WaveModule = require(ReplicatedStorage.Shared.Ocean.WaveModule)

local HoverService = {}

-- player → { Controller, Model, HoverId }
local activeHovers = {}

-- Folder for spawned vehicles in workspace (shared with BoatService).
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

local hoverInputRemote = vehicleEvents:FindFirstChild("HoverVerticalInput") or (function()
	local e = Instance.new("RemoteEvent")
	e.Name = "HoverVerticalInput"
	e.Parent = vehicleEvents
	return e
end)()

------------------------------------------------
-- Helpers
------------------------------------------------

local function getSpawnCFrame(npcModel)
	local anchor = npcModel:FindFirstChild("HoverSpawn")
	if anchor and anchor:IsA("BasePart") then
		return CFrame.new(anchor.Position.X, WaveModule.OCEAN_HEIGHT + 10, anchor.Position.Z)
	end

	-- Fallback: 30 studs in front of the NPC, above ocean height so the
	-- vehicle doesn't spawn submerged before its first Update tick.
	local root = npcModel.PrimaryPart or npcModel:FindFirstChildOfClass("BasePart")
	if root then
		local spawnPos = root.Position + root.CFrame.LookVector * 30
		return CFrame.new(spawnPos.X, WaveModule.OCEAN_HEIGHT + 10, spawnPos.Z)
	end

	return CFrame.new(0, WaveModule.OCEAN_HEIGHT + 10, 0)
end

------------------------------------------------
-- Public API
------------------------------------------------

function HoverService.GetHoverDefinition(hoverId)
	return HoverDefinitions[hoverId]
end

-- Returns a price-sorted list of { Id, Data } for hover vehicles sold by this NPC.
function HoverService.GetHoversForDealer(dealerName)
	local hovers = {}
	for hoverId, def in pairs(HoverDefinitions) do
		if def.Dealer == dealerName then
			table.insert(hovers, { Id = hoverId, Data = def })
		end
	end
	table.sort(hovers, function(a, b)
		return a.Data.Price < b.Data.Price
	end)
	return hovers
end

function HoverService.IsHoverDealer(npcName)
	for _, def in pairs(HoverDefinitions) do
		if def.Dealer == npcName then
			return true
		end
	end
	return false
end

function HoverService.HasHover(player)
	return activeHovers[player] ~= nil
end

-- Spawns a hover vehicle for the player near the given dealer NPC.
-- Returns: success (bool), message (string)
function HoverService.BuyHover(player, hoverId, npcModel)
	local def = HoverDefinitions[hoverId]
	if not def then
		return false, "Unknown vehicle."
	end

	if activeHovers[player] then
		return false, "Despawn your current vehicle first."
	end

	if def.Price > 0 then
		if not CashSystem.SpendCash(player, def.Price) then
			return false, "You need $" .. def.Price .. " to buy a " .. def.Name .. "."
		end
	end

	local vehicles = ReplicatedStorage:FindFirstChild("Vehicles")
	local template = vehicles and vehicles:FindFirstChild(def.ModelName)
	if not template then
		warn("HoverService: model not found in ReplicatedStorage.Vehicles:", def.ModelName)
		if def.Price > 0 then
			CashSystem.AddCash(player, def.Price)
		end
		return false, "This vehicle isn't available yet."
	end

	local hoverModel = template:Clone()
	hoverModel:PivotTo(getSpawnCFrame(npcModel))
	hoverModel.Parent = vehicleFolder

	local controller = HoverController.new(hoverModel, def)
	activeHovers[player] = { Controller = controller, Model = hoverModel, HoverId = hoverId }

	return true, def.Name .. " spawned!"
end

-- Removes the player's current hover vehicle.
-- Returns: success (bool), message (string)
function HoverService.DespawnHover(player)
	local entry = activeHovers[player]
	if not entry then
		return false, "You don't have a vehicle to despawn."
	end

	entry.Controller.Destroy()
	activeHovers[player] = nil
	return true, "Vehicle despawned."
end

------------------------------------------------
-- Vertical input (hold E to ascend, Q to descend)
------------------------------------------------

-- Not keyed off activeHovers[player]: the sender may be riding someone
-- else's vehicle. Each controller validates the sender is its own seat's
-- occupant, so broadcasting is safe -- only the vehicle they're actually
-- sitting in will act on it.
hoverInputRemote.OnServerEvent:Connect(function(player, direction, isActive)
	if direction ~= "Ascend" and direction ~= "Descend" then
		return
	end

	for _, entry in pairs(activeHovers) do
		entry.Controller.SetVerticalInput(player, direction, isActive == true)
	end
end)

------------------------------------------------
-- Lifecycle
------------------------------------------------

RunService.Heartbeat:Connect(function(dt)
	for _, entry in pairs(activeHovers) do
		entry.Controller.Update(dt)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if activeHovers[player] then
		activeHovers[player].Controller.Destroy()
		activeHovers[player] = nil
	end
end)

return HoverService
