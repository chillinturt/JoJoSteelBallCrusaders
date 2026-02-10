local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Remote = ReplicatedStorage.UIs.RemoteEvents.ScreenColorVfx

-- Create effects once
local color = Instance.new("ColorCorrectionEffect")
color.Name = "TimeStopColor"
color.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Name = "TimeStopBloom"
bloom.Intensity = 0
bloom.Parent = Lighting

local timeEraseColor = Instance.new("ColorCorrectionEffect")
timeEraseColor.Name = "TimeEraseColor"
timeEraseColor.Enabled = false
timeEraseColor.Parent = Lighting

local timeEraseBloom = Instance.new("BloomEffect")
timeEraseBloom.Name = "TimeEraseBloom"
timeEraseBloom.Intensity = 0
timeEraseBloom.Enabled = false
timeEraseBloom.Parent = Lighting

local hueConnection
local active = false

local function startTimeStop(duration)
	if active then
		return
	end
	active = true

	-- Initial vibrant state
	color.Saturation = 1.5
	color.Contrast = 0.3
	color.TintColor = Color3.fromRGB(255, 200, 255)
	bloom.Intensity = 1.2

	-- Hue shift loop (1 second)
	local startTime = os.clock()
	hueConnection = game:GetService("RunService").RenderStepped:Connect(function()
		local t = os.clock() - startTime
		if t >= 1 then
			return
		end
		local hue = (t * 0.4) % 1
		color.TintColor = Color3.fromHSV(hue, 0.4, 1)
	end)

	-- Fade to grayscale
	task.delay(1, function()
		if hueConnection then
			hueConnection:Disconnect()
			hueConnection = nil
		end

		TweenService:Create(color, TweenInfo.new(0.5), {
			Saturation = -1,
			Contrast = 0.1,
			TintColor = Color3.new(1, 1, 1),
		}):Play()

		TweenService:Create(bloom, TweenInfo.new(0.5), {
			Intensity = 0.3,
		}):Play()
	end)
end

local function endTimeStop()
	if not active then
		return
	end
	active = false

	if hueConnection then
		hueConnection:Disconnect()
		hueConnection = nil
	end

	-- Restore camera
	TweenService:Create(color, TweenInfo.new(0.4), {
		Saturation = 0,
		Contrast = 0,
		TintColor = Color3.new(1, 1, 1),
	}):Play()

	TweenService:Create(bloom, TweenInfo.new(0.4), {
		Intensity = 0,
	}):Play()
end

local function startTimeErase()
	timeEraseColor.Enabled = true
	timeEraseBloom.Enabled = true

	-- Strong red shift
	timeEraseColor.Saturation = 0.3
	timeEraseColor.Contrast = 0.4
	timeEraseColor.TintColor = Color3.fromRGB(255, 80, 80)

	timeEraseBloom.Intensity = 0.6
	timeEraseBloom.Size = 32

	TweenService:Create(timeEraseColor, TweenInfo.new(0.25), {
		Saturation = 0.6,
		Contrast = 0.6,
		TintColor = Color3.fromRGB(255, 60, 60),
	}):Play()
end

local function endTimeErase()
	TweenService:Create(timeEraseColor, TweenInfo.new(0.25), {
		Saturation = 0,
		Contrast = 0,
		TintColor = Color3.new(1, 1, 1),
	}):Play()

	TweenService:Create(timeEraseBloom, TweenInfo.new(0.25), {
		Intensity = 0,
	}):Play()

	task.delay(0.25, function()
		timeEraseColor.Enabled = false
		timeEraseBloom.Enabled = false
	end)
end

Remote.OnClientEvent:Connect(function(action, ...)
	if action == "TimeStop.Start" then
		startTimeStop(...)
	elseif action == "TimeStop.End" then
		endTimeStop()
	elseif action == "TimeErase.Start" then
		startTimeErase()
	elseif action == "TimeErase.End" then
		endTimeErase()
	end
end)
