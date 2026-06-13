local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DamageEvent = ReplicatedStorage.UIs.RemoteEvents:WaitForChild("DamageNumberEvent")

local function formatNumber(num)
	if num % 1 == 0 then
		return tostring(num)
	else
		return string.format("%.1f", num)
	end
end

local function randFloat(min, max)
	return min + math.random() * (max - min)
end

DamageEvent.OnClientEvent:Connect(function(data)
	local character = data.target
	local amount = data.amount or data.damage
	local type = data.type or "damage"

	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local offset = Vector3.new(randFloat(-2, 2), randFloat(2.5, 3.5), randFloat(-2, 2))

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 100, 0, 50)
	gui.StudsOffset = offset
	gui.AlwaysOnTop = true
	gui.Adornee = hrp
	gui.MaxDistance = 400

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold

	-- ✅ OUTLINE
	text.TextStrokeTransparency = 0.25
	text.TextStrokeColor3 = Color3.new(0, 0, 0)

	local displayText = formatNumber(amount)

	local isCrit = false

	if type == "heal" then
		text.TextColor3 = Color3.fromRGB(80, 255, 120)
		displayText = "+" .. displayText
	else
		if amount > 100 then
			text.TextColor3 = Color3.new(1, 1, 0)
			isCrit = true
		elseif amount > 50 then
			text.TextColor3 = Color3.new(1, 0.5, 0)
		else
			text.TextColor3 = Color3.new(1, 0, 0)
		end
	end

	text.Text = displayText

	-- Base size
	local baseSize = randFloat(0.9, 1.2)
	text.TextSize = 24 * baseSize

	text.Parent = gui
	gui.Parent = workspace

	--------------------------------------------------
	-- 💥 CRIT POP EFFECT
	--------------------------------------------------
	if isCrit then
		text.TextSize = text.TextSize * 1.6

		local popTween = TweenService:Create(
			text,
			TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ TextSize = text.TextSize * 1.15 }
		)

		popTween:Play()
	end

	--------------------------------------------------
	-- Float Animation
	--------------------------------------------------
	local drift = Vector3.new(randFloat(-0.5, 0.5), randFloat(2, 3), randFloat(-0.5, 0.5))

	local floatTween = TweenService:Create(
		gui,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffset = gui.StudsOffset + drift }
	)

	floatTween:Play()

	--------------------------------------------------
	-- Fade Out
	--------------------------------------------------
	task.spawn(function()
		for i = 1, 10 do
			local alpha = i / 10
			text.TextTransparency = alpha
			text.TextStrokeTransparency = 0.25 + (alpha * 0.75)
			task.wait(0.05)
		end
		gui:Destroy()
	end)
end)
