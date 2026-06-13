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
function DamageNumberService.ShowDamage(targetCharacter, amount, damageType)
	if not targetCharacter then
		return
	end

	local roundedAmount = DamageNumberService.RoundDamage(amount)

	DamageEvent:FireAllClients({
		target = targetCharacter,
		amount = roundedAmount,
		type = damageType or "damage", -- "damage" or "heal"
	})
end

return DamageNumberService
