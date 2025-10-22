-- ServerScriptService/CombatManager
local RunService = game:GetService("RunService")

local ActiveStuns = {} -- [character] = { expiresAt = number, originalSpeed = number, originalJump = number }
local STUN_SPEED = 4
local EPSILON = 0.05 -- tolerance for cleanup timing errors

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

	-- Fetch or create entry
	local entry = ActiveStuns[character]
	if entry then
		-- Extend stun duration if the new one lasts longer
		entry.expiresAt = math.max(entry.expiresAt, now + duration)
	else
		-- New stun → record original stats
		local moveStat = character:FindFirstChild("MoveSpeed")
		local jumpStat = character:FindFirstChild("JumpHeight")

		local originalSpeed = (moveStat and moveStat.Value) or humanoid.WalkSpeed or 16
		local originalJump = (jumpStat and jumpStat.Value) or humanoid.JumpPower or 50

		ActiveStuns[character] = {
			expiresAt = now + duration,
			originalSpeed = originalSpeed,
			originalJump = originalJump,
		}

		-- Apply stun effect immediately
		humanoid.WalkSpeed = STUN_SPEED
		humanoid.JumpPower = 0
	end
end

-- Remove stun and restore stats
local function unregisterStun(character)
	local entry = ActiveStuns[character]
	if not entry then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Parent then
		humanoid.WalkSpeed = entry.originalSpeed
		humanoid.JumpPower = entry.originalJump
	end

	local stunVal = character:FindFirstChild("Stun")
	if stunVal then
		stunVal:Destroy()
	end

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

			-- If stun expired, clean up
			if remaining <= EPSILON then
				unregisterStun(character)
				return
			end

			-- Update visible stun value (for debug/UI)
			local stunVal = character:FindFirstChild("Stun")
			if not stunVal then
				stunVal = Instance.new("NumberValue")
				stunVal.Name = "Stun"
				stunVal.Parent = character
			end
			stunVal.Value = math.max(0, remaining)
		end)
		if not ok then
			warn("⚠️ CombatManager stun update error:", err)
		end
	end
end)

-- Expose API
return {
	RegisterStun = registerStun,
	UnregisterStun = unregisterStun,
}
