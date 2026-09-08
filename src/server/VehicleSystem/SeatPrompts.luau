-- SeatPrompts.luau
-- Attaches a ProximityPrompt to a Seat/VehicleSeat so players sit via
-- interaction instead of walking/clicking into the seat. Disables the
-- seat's default touch/click-to-sit behavior so the prompt is the only way in.

local SeatPrompts = {}

local DEFAULT_MAX_DISTANCE = 10

-- Attaches a prompt to `seat`. Returns a cleanup function.
function SeatPrompts.Attach(seat: Instance, actionText: string, objectText: string?)
	seat.Disabled = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText or ""
	prompt.MaxActivationDistance = DEFAULT_MAX_DISTANCE
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat

	local function updateVisibility()
		prompt.Enabled = seat.Occupant == nil
	end
	updateVisibility()

	local occupantConn = seat:GetPropertyChangedSignal("Occupant"):Connect(updateVisibility)

	local triggerConn = prompt.Triggered:Connect(function(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and seat.Occupant == nil then
			seat:Sit(humanoid)
		end
	end)

	return function()
		occupantConn:Disconnect()
		triggerConn:Disconnect()
		if prompt.Parent then
			prompt:Destroy()
		end
	end
end

-- Any Seat/VehicleSeat under `model` other than `excludeSeat` is treated as a
-- passenger seat -- vehicle models are Studio-only assets (not in this repo),
-- so seating is discovered by class rather than a hardcoded name list.
function SeatPrompts.FindPassengerSeats(model: Instance, excludeSeat: Instance)
	local passengerSeats = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant ~= excludeSeat and (descendant:IsA("VehicleSeat") or descendant:IsA("Seat")) then
			table.insert(passengerSeats, descendant)
		end
	end
	return passengerSeats
end

return SeatPrompts
