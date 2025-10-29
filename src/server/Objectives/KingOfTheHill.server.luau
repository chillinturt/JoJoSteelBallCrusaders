--// Partless Control Point Script with Timers + GUI
local TeamsModule = require(game.ServerScriptService.BasicCombat.Managers:WaitForChild("TeamsModule"))
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--// Config
local CAPTURE_SPEED = 100
local DECAY_SPEED = 5
local MAX_PROGRESS = 100
local HOLD_TIME_TO_WIN = 10

--// Virtual Control Point
local pointPosition = Vector3.new(16.87, 103.471, 728.915)
local pointSize = Vector3.new(50, 30, 50)
local captureProgress = 0
local controllingTeam = nil
local capturingTeam = nil
local teamTimers = { TeamA = HOLD_TIME_TO_WIN, TeamB = HOLD_TIME_TO_WIN }
local matchOver = false
local Overtime = false

--// BillboardGui in WorldModel
local worldModel = Instance.new("WorldModel")
worldModel.Parent = Workspace

local anchorAttachment = Instance.new("Attachment")
anchorAttachment.WorldPosition = pointPosition
anchorAttachment.Parent = worldModel

local billboard = Instance.new("BillboardGui")
billboard.Size = UDim2.new(0, 220, 0, 80)
billboard.Adornee = anchorAttachment
billboard.AlwaysOnTop = true
billboard.Parent = worldModel

-- === Progress Bar ===
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

-- === Text Labels ===
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 0.25, 0)
titleText.Position = UDim2.new(0, 0, 0, 0)
titleText.TextScaled = true
titleText.BackgroundTransparency = 1
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.SourceSansBold
titleText.Text = "Neutral"
titleText.Parent = billboard

-- Team A timer
local teamATimerLabel = Instance.new("TextLabel")
teamATimerLabel.Size = UDim2.new(0.5, -5, 0.25, 0)
teamATimerLabel.Position = UDim2.new(0, 0, 0.75, 0)
teamATimerLabel.TextScaled = true
teamATimerLabel.BackgroundTransparency = 1
teamATimerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
teamATimerLabel.Font = Enum.Font.SourceSansBold
teamATimerLabel.Text = "A: " .. HOLD_TIME_TO_WIN
teamATimerLabel.Parent = billboard

-- Team B timer
local teamBTimerLabel = Instance.new("TextLabel")
teamBTimerLabel.Size = UDim2.new(0.5, -5, 0.25, 0)
teamBTimerLabel.Position = UDim2.new(0.5, 5, 0.75, 0)
teamBTimerLabel.TextScaled = true
teamBTimerLabel.BackgroundTransparency = 1
teamBTimerLabel.TextColor3 = Color3.fromRGB(100, 100, 255)
teamBTimerLabel.Font = Enum.Font.SourceSansBold
teamBTimerLabel.Text = "B: " .. HOLD_TIME_TO_WIN
teamBTimerLabel.Parent = billboard

--// Helper: get players inside virtual box
local function getPlayersInBox()
	local playersOnPoint = {}
	for _, player in ipairs(game.Players:GetPlayers()) do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local hrp = character.HumanoidRootPart
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

--// Declare winner
local function declareWinner(team)
	matchOver = true
	titleText.Text = team .. " Wins!"
	print(team .. " wins the round!")
end

--// Main loop
RunService.Heartbeat:Connect(function(dt)
	if matchOver then
		return
	end

	local playersOnPoint = getPlayersInBox()
	local teamAPlayers = playersOnPoint["TeamA"] or {}
	local teamBPlayers = playersOnPoint["TeamB"] or {}
	local teamAOn = #teamAPlayers > 0
	local teamBOn = #teamBPlayers > 0
	local contested = teamAOn and teamBOn

	-- Capture logic
	local delta = 0
	if teamAOn and not teamBOn then
		capturingTeam = "TeamA"
		delta = CAPTURE_SPEED * #teamAPlayers * dt
	elseif teamBOn and not teamAOn then
		capturingTeam = "TeamB"
		delta = -CAPTURE_SPEED * #teamBPlayers * dt
	elseif contested then
		delta = 0
	else
		if controllingTeam == nil then
			if captureProgress > 0 then
				delta = -DECAY_SPEED * dt
			elseif captureProgress < 0 then
				delta = DECAY_SPEED * dt
			end
		end
	end
	captureProgress = math.clamp(captureProgress + delta, -MAX_PROGRESS, MAX_PROGRESS)

	-- Assign controlling team when fully captured
	if captureProgress >= MAX_PROGRESS then
		if controllingTeam ~= "TeamA" then
			controllingTeam = "TeamA"
		end
	elseif captureProgress <= -MAX_PROGRESS then
		if controllingTeam ~= "TeamB" then
			controllingTeam = "TeamB"
		end
	end

	-- Timer countdown (only if not contested)
	if not contested then
		if controllingTeam == "TeamA" then
			teamTimers.TeamA -= dt
		elseif controllingTeam == "TeamB" then
			teamTimers.TeamB -= dt
		end
	else
		-- Contested → pause timers
	end

	-- Win / Overtime handling
	if controllingTeam == "TeamA" then
		if teamTimers.TeamA <= 0 then
			if captureProgress >= MAX_PROGRESS and not contested then
				declareWinner("TeamA")
			else
				Overtime = true
			end
		end
	elseif controllingTeam == "TeamB" then
		if teamTimers.TeamB <= 0 then
			if captureProgress <= -MAX_PROGRESS and not contested then
				declareWinner("TeamB")
			else
				Overtime = true
			end
		end
	end

	-- Update display text
	if contested then
		titleText.Text = "Contested!"
	elseif matchOver then
		-- already declared winner
	elseif Overtime then
		titleText.Text = string.format("%s: Overtime!", controllingTeam)
	elseif controllingTeam then
		titleText.Text = string.format("%s Holding: %.1f", controllingTeam, teamTimers[controllingTeam])
	else
		titleText.Text = "Neutral"
	end

	-- Update progress bar
	local normalized = (captureProgress + MAX_PROGRESS) / (MAX_PROGRESS * 2)
	bar.Size = UDim2.new(normalized, 0, 1, 0)
	if controllingTeam == "TeamA" then
		bar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	elseif controllingTeam == "TeamB" then
		bar.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
	else
		bar.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	end

	-- Update timers visually
	teamATimerLabel.Text = string.format("A: %.1f", math.max(teamTimers.TeamA, 0))
	teamBTimerLabel.Text = string.format("B: %.1f", math.max(teamTimers.TeamB, 0))
end)
