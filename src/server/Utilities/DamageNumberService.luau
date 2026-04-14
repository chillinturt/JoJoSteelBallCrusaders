local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DamageEvent = ReplicatedStorage.UIs.RemoteEvents:FindFirstChild("DamageNumberEvent")
if not DamageEvent then
	DamageEvent = Instance.new("RemoteEvent")
	DamageEvent.Parent = ReplicatedStorage.UIs.RemoteEvents
	DamageEvent.Name = "DamageNumberEvent"
end

local DamageNumberService = {}

-- Round to 1 decimal
function DamageNumberService.RoundDamage(num)
	return math.floor(num * 10 + 0.5) / 10
end

-- Send damage to clients
function DamageNumberService.ShowDamage(targetCharacter, damage)
	if not targetCharacter then
		return
	end

	local roundedDamage = DamageNumberService.RoundDamage(damage)

	DamageEvent:FireAllClients({
		target = targetCharacter,
		damage = roundedDamage,
	})
end

return DamageNumberService
