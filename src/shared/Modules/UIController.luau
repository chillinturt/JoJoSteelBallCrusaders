local TweenService = game:GetService("TweenService")

local UIController = {}

local registered = {}
local currentOpen = nil
local isAnimating = false

-- UIs in this set never have their Frame.Visible toggled off; closing them
-- only tweens them to their closedPos.
local AlwaysVisible = {
	Questlog = true,
}

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
	frame.Visible = AlwaysVisible[name] or false -- 🔥 IMPORTANT CHANGE
end

local function tween(frame, goal, shouldShow, keepVisible)
	if shouldShow then
		frame.Visible = true
	end

	local t = TweenService:Create(frame, tweenInfo, goal)
	t:Play()
	t.Completed:Wait()

	-- HARD SNAP FIX (prevents ghost leaking)
	frame.Position = goal.Position

	if not shouldShow and not keepVisible then
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
		tween(currentData.frame, { Position = currentData.closedPos }, false, AlwaysVisible[currentOpen])
	end

	-- Open new
	tween(data.frame, { Position = data.openPos }, true)

	currentOpen = name
	isAnimating = false

	QuestArrowToggle:Fire(name == "Questlog")
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
	}, false, AlwaysVisible[name])

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

	local wasQuestlogOpen = currentOpen == "Questlog"

	for name, data in pairs(registered) do
		tween(data.frame, { Position = data.closedPos }, false, AlwaysVisible[name])
	end

	currentOpen = nil
	isAnimating = false

	if wasQuestlogOpen then
		QuestArrowToggle:Fire(false)
	end
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

	QuestArrowToggle:Fire(name == "Questlog")
end

return UIController
