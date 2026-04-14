local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DamageEvent = ReplicatedStorage.UIs.RemoteEvents:WaitForChild("DamageNumberEvent")

-- Format damage (removes .0 if whole number)
local function formatDamage(num)
	if num % 1 == 0 then
		return tostring(num)
	else
		return string.format("%.1f", num)
	end
end

DamageEvent.OnClientEvent:Connect(function(data)
	local character = data.target
	local damage = data.damage

	if not character then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	-- Create BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 100, 0, 50)
	gui.StudsOffset = Vector3.new(
		math.random(-1, 1), -- slight horizontal randomness
		3,
		math.random(-1, 1)
	)
	gui.AlwaysOnTop = false
	gui.Adornee = hrp
	gui.MaxDistance = 400

	-- Text label
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold

	-- Default color
	text.TextColor3 = Color3.new(1, 0, 0)

	-- Damage formatting
	text.Text = formatDamage(damage)

	-- Optional: color scaling
	if damage > 100 then
		text.TextColor3 = Color3.new(1, 1, 0) -- crit
	elseif damage > 50 then
		text.TextColor3 = Color3.new(1, 0.5, 0)
	end

	text.Parent = gui
	gui.Parent = workspace

	-- Animate upward
	local tween = TweenService:Create(
		gui,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffset = gui.StudsOffset + Vector3.new(0, 2, 0) }
	)

	tween:Play()

	-- Fade out
	task.spawn(function()
		for i = 1, 10 do
			text.TextTransparency = i / 10
			task.wait(0.05)
		end
		gui:Destroy()
	end)
end)
