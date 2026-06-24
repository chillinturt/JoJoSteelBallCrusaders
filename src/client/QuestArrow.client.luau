local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local QuestEventsFolder = ReplicatedStorage:WaitForChild("QuestEvents")
local SetArrowTarget = QuestEventsFolder:WaitForChild("SetArrowTarget")

local ArrowTemplate = ReplicatedStorage.Effects.QuestEffects:WaitForChild("ArrowModel")

local arrow
local connection
local currentTargetPosition -- Vector3 or nil, sent by server

local function setArrowVisible(state)
	for _, obj in ipairs(arrow:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name ~= "MainPart" then
			obj.Transparency = state and 0 or 1
		elseif obj:IsA("BillboardGui") then
			obj.Enabled = state
		end
	end
end

local function makeModelNonPhysical(model)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
			obj.Massless = true
		end
	end
end

local function attachArrow(character)
	local hrp = character:WaitForChild("HumanoidRootPart")

	if connection then
		connection:Disconnect()
		connection = nil
	end

	if arrow then
		arrow:Destroy()
		arrow = nil
	end

	arrow = ArrowTemplate:Clone()
	arrow.Name = "QuestArrow"
	arrow.Parent = character

	makeModelNonPhysical(arrow)
	setArrowVisible(false)

	connection = RunService.RenderStepped:Connect(function()
		if not arrow or not arrow.PrimaryPart then return end
		if not hrp.Parent then return end

		local arrowPosition = hrp.Position

		if currentTargetPosition then
			arrow:SetPrimaryPartCFrame(CFrame.lookAt(arrowPosition, currentTargetPosition))
		else
			local currentCFrame = arrow.PrimaryPart.CFrame
			arrow:SetPrimaryPartCFrame(CFrame.new(arrowPosition) * (currentCFrame - currentCFrame.Position))
		end
	end)
end

-- Server pushes a Vector3 target position (or nil) every 0.5 seconds
SetArrowTarget.OnClientEvent:Connect(function(position)
	currentTargetPosition = position
	if arrow then
		setArrowVisible(position ~= nil)
	end
end)

if player.Character then
	attachArrow(player.Character)
end

player.CharacterAdded:Connect(function(character)
	attachArrow(character)
end)
