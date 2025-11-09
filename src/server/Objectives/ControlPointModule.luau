-- ControlPointModule.lua
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local createEvent = Instance.new("RemoteEvent")
createEvent.Name = "ControlPointCreated"
createEvent.Parent = ReplicatedStorage

local TeamsModule = require(game.ServerScriptService.BasicCombat.Managers:WaitForChild("TeamsModule"))

local ControlPointModule = {}
local HttpService = game:GetService("HttpService")
ControlPointModule.ActivePoints = ControlPointModule.ActivePoints or {}

-- Default configuration
local DEFAULTS = {
	CAPTURE_SPEED = 10,
	DECAY_SPEED = 5,
	MAX_PROGRESS = 100,
	HOLD_TIME_TO_WIN = 10,
}

--// Helper: Get players inside a box region
local function getPlayersInBox(pointPosition, pointSize)
	local playersOnPoint = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local hrp = character and character:FindFirstChild("HumanoidRootPart")

		-- Skip if character is missing, dead, or lacks HRP
		if humanoid and humanoid.Health > 0 and hrp then
			local relativePos = hrp.Position - pointPosition
			if
				math.abs(relativePos.X) <= pointSize.X / 2
				and math.abs(relativePos.Y) <= pointSize.Y / 2
				and math.abs(relativePos.Z) <= pointSize.Z / 2
			then
				local team = TeamsModule.GetTeam(character)
				if team then
					playersOnPoint[team] = playersOnPoint[team] or {}
					table.insert(playersOnPoint[team], character)
				end
			end
		end
	end

	return playersOnPoint
end

--// Create GUI for one control point
local function createBillboard(pointPosition, holdTime, objectivePart)
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = objectivePart

	local anchorAttachment = Instance.new("Attachment")
	anchorAttachment.WorldPosition = pointPosition
	anchorAttachment.Parent = worldModel

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 220, 0, 80)
	billboard.Adornee = anchorAttachment
	billboard.AlwaysOnTop = true
	billboard.Parent = worldModel

	-- Progress Frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0.25, 0)
	frame.Position = UDim2.new(0, 0, 0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 0, 1, 0)
	bar.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	bar.BorderSizePixel = 0
	bar.Parent = frame

	-- Title
	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, 0, 0.25, 0)
	titleText.Position = UDim2.new(0, 0, 0, 0)
	titleText.TextScaled = true
	titleText.BackgroundTransparency = 1
	titleText.TextColor3 = Color3.new(1, 1, 1)
	titleText.Font = Enum.Font.SourceSansBold
	titleText.Text = "Neutral"
	titleText.Parent = billboard

	-- Team A
	local teamATimerLabel = Instance.new("TextLabel")
	teamATimerLabel.Size = UDim2.new(0.5, -5, 0.25, 0)
	teamATimerLabel.Position = UDim2.new(0, 0, 0.75, 0)
	teamATimerLabel.TextScaled = true
	teamATimerLabel.BackgroundTransparency = 1
	teamATimerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	teamATimerLabel.Font = Enum.Font.SourceSansBold
	teamATimerLabel.Text = "A: " .. holdTime
	teamATimerLabel.Parent = billboard

	-- Team B
	local teamBTimerLabel = Instance.new("TextLabel")
	teamBTimerLabel.Size = UDim2.new(0.5, -5, 0.25, 0)
	teamBTimerLabel.Position = UDim2.new(0.5, 5, 0.75, 0)
	teamBTimerLabel.TextScaled = true
	teamBTimerLabel.BackgroundTransparency = 1
	teamBTimerLabel.TextColor3 = Color3.fromRGB(100, 100, 255)
	teamBTimerLabel.Font = Enum.Font.SourceSansBold
	teamBTimerLabel.Text = "B: " .. holdTime
	teamBTimerLabel.Parent = billboard

	return {
		billboard = billboard,
		bar = bar,
		titleText = titleText,
		teamATimerLabel = teamATimerLabel,
		teamBTimerLabel = teamBTimerLabel,
	}
end

-- Helper: create billboard GUI for 3 teams
local function createBillboardThreeTeams(pointPosition, holdTime, objectivePart)
	-- Create invisible part to attach the GUI
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = objectivePart

	local anchorAttachment = Instance.new("Attachment")
	anchorAttachment.WorldPosition = pointPosition
	anchorAttachment.Parent = worldModel

	-- Billboard GUI
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 220, 0, 100)
	billboard.AlwaysOnTop = true
	billboard.Adornee = anchorAttachment
	billboard.Parent = worldModel

	-- Progress Frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0.25, 0)
	frame.Position = UDim2.new(0, 0, 0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 0, 1, 0)
	bar.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	bar.BorderSizePixel = 0
	bar.Parent = frame

	-- Title
	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, 0, 0.25, 0)
	titleText.Position = UDim2.new(0, 0, 0, 0)
	titleText.TextScaled = true
	titleText.BackgroundTransparency = 1
	titleText.TextColor3 = Color3.new(1, 1, 1)
	titleText.Font = Enum.Font.SourceSansBold
	titleText.Text = "Neutral"
	titleText.Parent = billboard

	-- Helper to create team labels
	local function createTeamLabel(position, color, text)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.33, -5, 0.25, 0)
		label.Position = position
		label.TextScaled = true
		label.BackgroundTransparency = 1
		label.TextColor3 = color
		label.Font = Enum.Font.SourceSansBold
		label.Text = text
		label.Parent = billboard
		return label
	end

	local teamATimerLabel = createTeamLabel(UDim2.new(0, 0, 0.75, 0), Color3.fromRGB(255, 100, 100), "A: " .. holdTime)
	local teamBTimerLabel =
		createTeamLabel(UDim2.new(0.33, 5, 0.75, 0), Color3.fromRGB(100, 100, 255), "B: " .. holdTime)
	local teamCTimerLabel =
		createTeamLabel(UDim2.new(0.66, 5, 0.75, 0), Color3.fromRGB(100, 255, 100), "C: " .. holdTime)

	return {
		billboard = billboard,
		bar = bar,
		titleText = titleText,
		teamATimerLabel = teamATimerLabel,
		teamBTimerLabel = teamBTimerLabel,
		teamCTimerLabel = teamCTimerLabel,
	}
end

--// Declare winner
local function declareWinner(pointData, team)
	pointData.matchOver = true
	pointData.gui.titleText.Text = team .. " Wins!"
	print(team .. " wins the round!")
end

--// Main spawn function
function ControlPointModule.SpawnControlPoint(position, size, captureSpeed, decaySpeed, holdTime, objectivePart)
	local id = HttpService:GenerateGUID(false)

	local cfg = {
		CAPTURE_SPEED = captureSpeed or DEFAULTS.CAPTURE_SPEED,
		DECAY_SPEED = decaySpeed or DEFAULTS.DECAY_SPEED,
		MAX_PROGRESS = DEFAULTS.MAX_PROGRESS,
		HOLD_TIME_TO_WIN = holdTime or DEFAULTS.HOLD_TIME_TO_WIN,
	}

	local point = {
		position = position,
		size = size,
		progress = 0,
		controlTeam = nil,
		captureTeam = nil,
		timers = { TeamA = cfg.HOLD_TIME_TO_WIN, TeamB = cfg.HOLD_TIME_TO_WIN },
		matchOver = false,
		overtime = false,
		objectivePart = objectivePart,
		gui = createBillboard(position, cfg.HOLD_TIME_TO_WIN, objectivePart),
		config = cfg,
		id = id,
	}

	RunService.Heartbeat:Connect(function(dt)
		if point.matchOver then
			return
		end

		local playersOnPoint = getPlayersInBox(point.position, point.size)
		local teamAPlayers = playersOnPoint["TeamA"] or {}
		local teamBPlayers = playersOnPoint["TeamB"] or {}
		local teamAOn, teamBOn = #teamAPlayers > 0, #teamBPlayers > 0
		local contested = teamAOn and teamBOn

		local delta = 0
		if teamAOn and not teamBOn then
			point.captureTeam = "TeamA"
			delta = cfg.CAPTURE_SPEED * #teamAPlayers * dt
		elseif teamBOn and not teamAOn then
			point.captureTeam = "TeamB"
			delta = -cfg.CAPTURE_SPEED * #teamBPlayers * dt
		elseif contested then
			delta = 0
		else
			-- decay back toward neutral when no one is on the point
			if point.controlTeam == nil then
				if point.progress > 0 then
					delta = -cfg.DECAY_SPEED * dt
				elseif point.progress < 0 then
					delta = cfg.DECAY_SPEED * dt
				end
			end
		end

		point.progress = math.clamp(point.progress + delta, -cfg.MAX_PROGRESS, cfg.MAX_PROGRESS)

		-- Assign controlling team when fully captured
		if point.progress >= cfg.MAX_PROGRESS then
			if point.controlTeam ~= "TeamA" then
				point.controlTeam = "TeamA"
				point.overtime = false
				point.progress = cfg.MAX_PROGRESS
			end
		elseif point.progress <= -cfg.MAX_PROGRESS then
			if point.controlTeam ~= "TeamB" then
				point.controlTeam = "TeamB"
				point.overtime = false
				point.progress = -cfg.MAX_PROGRESS
			end
		end

		if point.controlTeam == "TeamA" then
			point.timers.TeamA = math.max(point.timers.TeamA - dt, 0)
		elseif point.controlTeam == "TeamB" then
			point.timers.TeamB = math.max(point.timers.TeamB - dt, 0)
		end

		-- Win / Overtime handling
		if point.controlTeam == "TeamA" then
			if point.timers.TeamA <= 0 then
				if point.progress >= cfg.MAX_PROGRESS and not contested then
					declareWinner(point, "TeamA")
				else
					point.overtime = true
				end
			end
		elseif point.controlTeam == "TeamB" then
			if point.timers.TeamB <= 0 then
				if point.progress <= -cfg.MAX_PROGRESS and not contested then
					declareWinner(point, "TeamB")
				else
					point.overtime = true
				end
			end
		end

		-- GUI updates
		local gui = point.gui
		if contested then
			gui.titleText.Text = "Contested!"
		elseif point.matchOver then
		-- already declared winner
		elseif point.overtime then
			gui.titleText.Text = string.format("%s: Overtime!", point.controlTeam)
		elseif point.controlTeam then
			gui.titleText.Text = string.format("%s Holding: %.1f", point.controlTeam, point.timers[point.controlTeam])
		else
			gui.titleText.Text = "Neutral"
		end

		local normalized = (point.progress + cfg.MAX_PROGRESS) / (cfg.MAX_PROGRESS * 2)
		gui.bar.Size = UDim2.new(normalized, 0, 1, 0)

		if point.controlTeam == "TeamA" then
			gui.bar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		elseif point.controlTeam == "TeamB" then
			gui.bar.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
		else
			gui.bar.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		end

		gui.teamATimerLabel.Text = string.format("A: %.1f", point.timers.TeamA)
		gui.teamBTimerLabel.Text = string.format("B: %.1f", point.timers.TeamB)
	end)

	return point
end

-- Spawn function
function ControlPointModule.SpawnControlPointThreeTeams(position, size, speed, decay, holdTime, objectivePart)
	local id = HttpService:GenerateGUID(false)

	local cfg = {
		CAPTURE_SPEED = speed or DEFAULTS.CAPTURE_SPEED,
		DECAY_SPEED = decay or DEFAULTS.DECAY_SPEED,
		MAX_PROGRESS = DEFAULTS.MAX_PROGRESS,
		HOLD_TIME_TO_WIN = holdTime or DEFAULTS.HOLD_TIME_TO_WIN,
	}

	local point = {
		id = id,
		position = position,
		size = size,
		controlTeam = nil, -- currently holding team
		progress = 0, -- global progress
		teamProgress = { TeamA = 0, TeamB = 0, TeamC = 0 }, -- independent progress
		timers = { TeamA = cfg.HOLD_TIME_TO_WIN, TeamB = cfg.HOLD_TIME_TO_WIN, TeamC = cfg.HOLD_TIME_TO_WIN },
		matchOver = false,
		objectivePart = objectivePart,
		config = cfg,
		gui = createBillboardThreeTeams(position, cfg.HOLD_TIME_TO_WIN, objectivePart),
	}

	-- Main loop
	RunService.Heartbeat:Connect(function(dt)
		if point.matchOver then
			return
		end

		local playersOnPoint = getPlayersInBox(point.position, point.size)
		local count = {
			TeamA = #(playersOnPoint.TeamA or {}),
			TeamB = #(playersOnPoint.TeamB or {}),
			TeamC = #(playersOnPoint.TeamC or {}),
		}

		-- Determine if contested
		local teamsPresent = {}
		for team, c in pairs(count) do
			if c > 0 then
				table.insert(teamsPresent, team)
			end
		end
		local contested = #teamsPresent > 1

		-- Capture logic
		if not contested and #teamsPresent == 1 then
			local capturingTeam = teamsPresent[1]
			local delta = cfg.CAPTURE_SPEED * count[capturingTeam] * dt

			point.teamProgress[capturingTeam] = math.min(point.teamProgress[capturingTeam] + delta, cfg.MAX_PROGRESS)
			point.progress = point.teamProgress[capturingTeam] -- sync for GUI bar

			-- Assign control if fully captured
			if point.teamProgress[capturingTeam] >= cfg.MAX_PROGRESS then
				point.controlTeam = capturingTeam
			end
		end

		-- Decay logic for non-capturing teams
		for _, team in ipairs({ "TeamA", "TeamB", "TeamC" }) do
			if team ~= point.controlTeam and not table.find(teamsPresent, team) then
				point.teamProgress[team] = math.max(point.teamProgress[team] - cfg.DECAY_SPEED * dt, 0)
			end
		end

		-- Update timers for controlling team
		if point.controlTeam then
			point.timers[point.controlTeam] = math.max(point.timers[point.controlTeam] - dt, 0)
		end

		-- Win detection
		for _, team in ipairs({ "TeamA", "TeamB", "TeamC" }) do
			if point.timers[team] <= 0 then
				-- Declare winner (implement this function)
				point.matchOver = true
				point.gui.titleText.Text = team .. " Wins!"
			end
		end

		-- GUI update
		local gui = point.gui
		if contested then
			gui.titleText.Text = "Contested!"
		elseif point.matchOver then
			-- already declared winner
		elseif point.controlTeam then
			gui.titleText.Text = string.format("%s Holding: %.1f", point.controlTeam, point.timers[point.controlTeam])
		else
			gui.titleText.Text = "Neutral"
		end

		local normalized = point.progress / cfg.MAX_PROGRESS
		gui.bar.Size = UDim2.new(normalized, 0, 1, 0)

		-- Bar color
		if point.controlTeam == "TeamA" then
			gui.bar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		elseif point.controlTeam == "TeamB" then
			gui.bar.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
		elseif point.controlTeam == "TeamC" then
			gui.bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		else
			gui.bar.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		end

		-- Team timers
		gui.teamATimerLabel.Text = string.format("A: %.1f", point.timers.TeamA)
		gui.teamBTimerLabel.Text = string.format("B: %.1f", point.timers.TeamB)
		gui.teamCTimerLabel.Text = string.format("C: %.1f", point.timers.TeamC)
	end)

	return point
end

--// Remove a control point and its GUI
function ControlPointModule.RemoveControlPoint(pointData)
	if not pointData then
		return
	end

	-- Safely destroy GUI components
	if pointData.gui then
		if pointData.gui.billboard then
			pointData.gui.billboard.Parent:Destroy()
			--pointData.gui.billboard:Destroy()
		end
		pointData.gui = nil
	end

	-- Mark as inactive
	pointData.matchOver = true
	pointData.removed = true

	print("Removed control point at position:", pointData.position)
end

return ControlPointModule
