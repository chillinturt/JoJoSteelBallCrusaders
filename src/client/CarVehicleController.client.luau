-- CarController (Client Input Handler)
-- Hold Space to engage the handbrake (locks rear grip for drifting/hard stops)
-- while seated in a car's DriverSeat. Steering/throttle/reverse use the seat's
-- native SteerFloat/ThrottleFloat, read directly by CarController on the
-- server -- no remote needed for those (mirrors HoverVehicleController).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local carHandbrakeRemote = ReplicatedStorage:WaitForChild("VehicleEvents"):WaitForChild("CarHandbrakeInput")

local inCarSeat = false

local function fireHandbrake(isActive)
	carHandbrakeRemote:FireServer(isActive)
end

local function onSeated(active, seatPart)
	local wasInCarSeat = inCarSeat
	inCarSeat = active and seatPart ~= nil and seatPart.Name == "DriverSeat" and seatPart:IsA("VehicleSeat")

	if wasInCarSeat and not inCarSeat then
		fireHandbrake(false)
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
	if gameProcessed or not inCarSeat then
		return
	end

	if input.KeyCode == Enum.KeyCode.Space then
		fireHandbrake(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not inCarSeat then
		return
	end

	if input.KeyCode == Enum.KeyCode.Space then
		fireHandbrake(false)
	end
end)
