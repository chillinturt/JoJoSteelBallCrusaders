-- ServerScriptService/CombatManager
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local SlowingFieldRegistry = require(ServerScriptService.BasicCombat.Managers.SlowingFieldRegistry)

local ActiveStuns = {} -- [character] = { expiresAt = number }
local STUN_SPEED_MULT = 0.16
local EPSILON = 0.05

-- Add or refresh a stun
local function registerStun(character, duration)
	if not (character and character.Parent) then
		return
	end

	local now = tick()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local entry = ActiveStuns[character]
	if entry then
		-- Extend stun
		entry.expiresAt = math.max(entry.expiresAt, now + duration)
	else
		-- Create new stun entry
		ActiveStuns[character] = {
			expiresAt = now + duration,
		}

		-- Apply slowing effect
		SlowingFieldRegistry.SetSlow(character, "Stun", STUN_SPEED_MULT)

		local baseSpeed = character:FindFirstChild("MoveSpeed")
		if baseSpeed then
			-- Apply slowed speed
			local mult = SlowingFieldRegistry.GetFinalMultiplier(character)
			humanoid.WalkSpeed = baseSpeed.Value * mult
		end

		humanoid.JumpPower = 0
	end
end

-- Remove stun and restore normal stats
local function unregisterStun(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Parent then
		local baseSpeed = character:FindFirstChild("MoveSpeed")

		SlowingFieldRegistry.ClearSlow(character, "Stun")

		if baseSpeed then
			local mult = SlowingFieldRegistry.GetFinalMultiplier(character)
			humanoid.WalkSpeed = baseSpeed.Value * mult
		end
	end

	-- remove debug value
	local stunVal = character:FindFirstChild("Stun")
	if stunVal then
		stunVal:Destroy()
	end
	humanoid.JumpPower = character:FindFirstChild("JumpHeight").Value

	ActiveStuns[character] = nil
end

-- Update loop
RunService.Heartbeat:Connect(function()
	local now = tick()

	for character, data in pairs(ActiveStuns) do
		local ok, err = pcall(function()
			if not (character and character.Parent) then
				ActiveStuns[character] = nil
				return
			end

			local remaining = data.expiresAt - now

			-- Stun ended?
			if remaining <= EPSILON then
				unregisterStun(character)
				return
			end

			-- Update visible stun value (debug)
			local stunVal = character:FindFirstChild("Stun")
			if not stunVal then
				stunVal = Instance.new("NumberValue")
				stunVal.Name = "Stun"
				stunVal.Parent = character
			end

			stunVal.Value = remaining
		end)

		if not ok then
			warn("⚠️ CombatManager stun update error:", err)
		end
	end
end)

return {
	RegisterStun = registerStun,
	UnregisterStun = unregisterStun,
}
