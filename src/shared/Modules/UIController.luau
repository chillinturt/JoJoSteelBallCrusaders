local TweenService = game:GetService("TweenService")

local UIController = {}

local registered = {}
local currentOpen = nil
local isAnimating = false

local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestEventFolder = ReplicatedStorage:WaitForChild("QuestEvents")
local QuestArrowToggle = QuestEventFolder:WaitForChild("QuestArrowVisible")

function UIController.Register(name, frame, openPos, closedPos)
	registered[name] = {
		frame = frame,
		openPos = openPos,
		closedPos = closedPos,
	}

	frame.Position = closedPos
	frame.Visible = false -- 🔥 IMPORTANT CHANGE
end

local function tween(frame, goal, shouldShow)
	if shouldShow then
		frame.Visible = true
	end

	local t = TweenService:Create(frame, tweenInfo, goal)
	t:Play()
	t.Completed:Wait()

	-- HARD SNAP FIX (prevents ghost leaking)
	frame.Position = goal.Position

	if not shouldShow then
		frame.Visible = false
	end
end

function UIController.Open(name)
	print("Trying to open:", name)

	if isAnimating then
		print("Blocked: animating")
		return
	end
	local data = registered[name]
	if not data then
		warn("No registered UI:", name)
		return
	end

	isAnimating = true

	-- Close current
	if currentOpen and currentOpen ~= name then
		local currentData = registered[currentOpen]
		tween(currentData.frame, { Position = currentData.closedPos }, false)
	end

	-- Open new
	tween(data.frame, { Position = data.openPos }, true)

	currentOpen = name
	isAnimating = false

	if name == "Questlog" then
		QuestArrowToggle:Fire(true)
	else
		QuestArrowToggle:Fire(false)
	end
end

function UIController.Close(name)
	if isAnimating then
		return
	end

	local data = registered[name]
	if not data then
		return
	end

	isAnimating = true

	tween(data.frame, {
		Position = data.closedPos,
	}, false)

	if currentOpen == name then
		currentOpen = nil
	end

	isAnimating = false

	if name == "Questlog" then
		QuestArrowToggle:Fire(false)
	end
end

function UIController.Toggle(name)
	if currentOpen == name then
		UIController.CloseAll()
	else
		UIController.Open(name)
	end
end

function UIController.CloseAll()
	if isAnimating then
		return
	end
	isAnimating = true

	for _, data in pairs(registered) do
		tween(data.frame, { Position = data.closedPos }, false)
	end

	currentOpen = nil
	isAnimating = false
end

function UIController.Reset()
	registered = {}
	currentOpen = nil
	isAnimating = false
end

function UIController.ForceOpen(name)
	local data = registered[name]
	if not data then
		return
	end

	local frame = data.frame

	frame.Visible = true
	frame.Position = data.openPos

	currentOpen = name
end

return UIController
