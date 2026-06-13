local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BookMeterEvent = ReplicatedStorage.UIs.RemoteEvents:WaitForChild("BookMeterUpdate")

BookMeterEvent.OnClientEvent:Connect(function(target, value)
	if not target or not target.Parent then
		return
	end

	local head = target:FindFirstChild("Head")
	if not head then
		return
	end

	local gui = head:FindFirstChild("BookMeterGui")

	-- 🔥 REMOVE GUI IF ZERO
	if value <= 0 then
		if gui then
			gui:Destroy()
		end
		return
	end

	-- 🔥 CREATE IF MISSING
	if not gui then
		gui = ReplicatedStorage.Effects.StandEffects.BookMeterGui:Clone()
		gui.Name = "BookMeterGui"
		gui.Adornee = head
		gui.Parent = head
	end

	-- 🔥 UPDATE
	gui.Frame.BarBackground.Bar.Size = UDim2.new(value / 100, 0, 1, 0)
	gui.Frame.TextLabel.Text = tostring(math.floor(value))
end)
