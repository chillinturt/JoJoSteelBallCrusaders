-- HoverVehicleController (Client Input Handler)
-- Hold E to ascend, Q to descend while seated in a hover vehicle's DriverSeat.
-- Horizontal movement/turning uses the seat's native SteerFloat/ThrottleFloat,
-- read directly by HoverController on the server -- no remote needed for that.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local hoverInputRemote = ReplicatedStorage:WaitForChild("VehicleEvents"):WaitForChild("HoverVerticalInput")

local inHoverSeat = false

local function fireInput(direction, isActive)
	hoverInputRemote:FireServer(direction, isActive)
end

local function onSeated(active, seatPart)
	local wasInHoverSeat = inHoverSeat
	inHoverSeat = active and seatPart ~= nil and seatPart.Name == "DriverSeat" and seatPart:IsA("VehicleSeat")

	if wasInHoverSeat and not inHoverSeat then
		fireInput("Ascend", false)
		fireInput("Descend", false)
	end
end

local function bindCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Seated:Connect(onSeated)
end

if player.Character then
	bindCharacter(player.Character)
end
player.CharacterAdded:Connect(bindCharacter)

------------------------------------------------
-- Input
------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not inHoverSeat then
		return
	end

	if input.KeyCode == Enum.KeyCode.E then
		fireInput("Ascend", true)
	elseif input.KeyCode == Enum.KeyCode.Q then
		fireInput("Descend", true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not inHoverSeat then
		return
	end

	if input.KeyCode == Enum.KeyCode.E then
		fireInput("Ascend", false)
	elseif input.KeyCode == Enum.KeyCode.Q then
		fireInput("Descend", false)
	end
end)
