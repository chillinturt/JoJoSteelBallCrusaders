local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local QuestEventsFolder = ReplicatedStorage:WaitForChild("QuestEvents")
local SetArrowTarget = QuestEventsFolder:WaitForChild("SetArrowTarget")
local QuestArrowToggle = QuestEventsFolder:WaitForChild("QuestArrowVisible")

local ArrowTemplate = ReplicatedStorage.Effects.QuestEffects:WaitForChild("ArrowModel")

local arrow
local connection
local currentTargetPosition -- Vector3 or nil, sent by server
local isQuestlogOpen = false

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

local function refreshArrowVisibility()
	if arrow then
		setArrowVisible(isQuestlogOpen and currentTargetPosition ~= nil)
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
	refreshArrowVisibility()

	connection = RunService.RenderStepped:Connect(function()
		if not arrow or not arrow.PrimaryPart then
			return
		end
		if not hrp.Parent then
			return
		end

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
	refreshArrowVisibility()
end)

-- UIController fires this when the Questlog is opened/closed
QuestArrowToggle.Event:Connect(function(isOpen)
	isQuestlogOpen = isOpen
	refreshArrowVisibility()
end)

if player.Character then
	attachArrow(player.Character)
end

player.CharacterAdded:Connect(function(character)
	attachArrow(character)
end)
