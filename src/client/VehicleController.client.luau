-- VehicleController (Client Input Handler)
-- Replaces old LocalCarScript cloning system

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local currentSeat = nil
local vehicle = nil

local movement = Vector2.zero

------------------------------------------------
-- INPUT HANDLING
------------------------------------------------

local function updateMovement()
	local forward = 0
	local strafe = 0

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		forward += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		forward -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		strafe += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		strafe -= 1
	end

	movement = Vector2.new(strafe, forward)
end

------------------------------------------------
-- SEAT DETECTION
------------------------------------------------

local function onSeated(active, seatPart)
	if active and seatPart and seatPart:IsA("VehicleSeat") then
		currentSeat = seatPart
		vehicle = seatPart:FindFirstAncestorOfClass("Model")
	else
		currentSeat = nil
		vehicle = nil
		movement = Vector2.zero
	end
end

humanoid.Seated:Connect(onSeated)

------------------------------------------------
-- MAIN LOOP
------------------------------------------------

RunService.RenderStepped:Connect(function()
	if not currentSeat then
		return
	end

	updateMovement()

	-- Send input to server via seat properties (simple Phase 1 system)
	currentSeat:SetAttribute("SteerInput", movement.X)
	currentSeat:SetAttribute("ThrottleInput", movement.Y)
end)
