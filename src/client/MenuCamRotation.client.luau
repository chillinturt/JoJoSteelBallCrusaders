-- MenuCameraController (LocalScript)
-- Handles rotating main menu camera and reopening

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local MenuState = require(player:WaitForChild("PlayerScripts"):WaitForChild("MenuState"))

-------------------------------------------------
-- Bindables
-------------------------------------------------
local exitMenuEvent = ReplicatedStorage:WaitForChild("Bindables"):WaitForChild("ExitMainMenu")
local openMenuEvent = ReplicatedStorage:WaitForChild("Bindables"):WaitForChild("OpenMainMenu")

-------------------------------------------------
-- Camera Assets
-------------------------------------------------
local camAssets = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("Camera")
local camModelTemplate = camAssets:WaitForChild("MainMenuCamModel")
local focusPartTemplate = camAssets:WaitForChild("MainMenuCamFocus")

-------------------------------------------------
-- Camera State
-------------------------------------------------
local camModel
local focusPart
local running = false
local connection
local rotationSpeed = math.rad(8)
local angle = 0
local camY = 0
local radius = 0

-------------------------------------------------
-- Function: Initialize & run menu camera
-------------------------------------------------
local function startMenuCamera()
	if running then
		return
	end
	running = true

	-- Clone camera assets
	camModel = camModelTemplate:Clone()
	focusPart = focusPartTemplate:Clone()
	camModel.Parent = workspace
	focusPart.Parent = workspace

	-- Force scriptable camera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = nil

	-- Orbit setup
	angle = 0
	local pivotCF = camModel:GetPivot()
	camY = pivotCF.Position.Y
	local offset = pivotCF.Position - focusPart.Position
	radius = Vector3.new(offset.X, 0, offset.Z).Magnitude

	-- Run camera loop
	connection = RunService.RenderStepped:Connect(function(dt)
		if not running then
			return
		end

		angle += rotationSpeed * dt
		local x = focusPart.Position.X + math.cos(angle) * radius
		local z = focusPart.Position.Z + math.sin(angle) * radius
		local newPos = Vector3.new(x, camY, z)
		local cf = CFrame.lookAt(newPos, focusPart.Position)

		camModel:PivotTo(cf)
		camera.CFrame = cf
	end)
end

-------------------------------------------------
-- Function: Cleanup and restore player camera
-------------------------------------------------
local function stopMenuCamera()
	if not running then
		return
	end
	running = false

	if connection then
		connection:Disconnect()
		connection = nil
	end

	-- Release camera control to Roblox
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = nil
	RunService.RenderStepped:Wait()

	-- Restore player camera
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	camera.CameraSubject = humanoid
	camera.CameraType = Enum.CameraType.Custom
	RunService.RenderStepped:Wait()

	-- Cleanup camera objects
	if camModel then
		camModel:Destroy()
	end
	if focusPart then
		focusPart:Destroy()
	end
end

-------------------------------------------------
-- Initial menu camera (first join)
-------------------------------------------------
startMenuCamera()

-------------------------------------------------
-- Exit menu handler
-------------------------------------------------
exitMenuEvent.Event:Connect(function()
	print("EXIT MENU EVENT FIRED")
	stopMenuCamera()
	MenuState.MenuOpen = false
end)

-------------------------------------------------
-- Open menu handler
-------------------------------------------------
openMenuEvent.Event:Connect(function()
	print("Open menu event received")
	if MenuState.MenuOpen then
		print("Menu is already open!")
		return
	end

	MenuState.MenuOpen = true
	startMenuCamera()
end)
