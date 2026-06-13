-- NPCFacingManager.lua
-- ServerScriptService/Utilities

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local NPCFacingManager = {}

local registeredNPCs = {}

local DEFAULT_CONFIG = {
	Range = 25,
	FaceSpeed = 8, -- higher = snappier turning
	UpdateRate = 0.1,
	OnlyWhenNearby = true,
	ResetToOriginalRotation = true,
}

local function lerpAngle(a, b, alpha)
	local diff = math.atan2(math.sin(b - a), math.cos(b - a))

	return a + diff * alpha
end

local function getNearestPlayer(hrp, range)
	local closestCharacter = nil
	local closestDistance = range

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")

			if humanoid and root and humanoid.Health > 0 then
				local distance = (root.Position - hrp.Position).Magnitude

				if distance < closestDistance then
					closestDistance = distance
					closestCharacter = character
				end
			end
		end
	end

	return closestCharacter
end

function NPCFacingManager:Register(npc, config)
	if not npc or registeredNPCs[npc] then
		return
	end

	config = config or {}

	local finalConfig = table.clone(DEFAULT_CONFIG)

	for key, value in pairs(config) do
		finalConfig[key] = value
	end

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local hrp = npc:FindFirstChild("HumanoidRootPart")

	if not humanoid or not hrp then
		warn(("NPCFacingManager: %s missing Humanoid or HRP"):format(npc.Name))
		return
	end

	-- Setup NPC
	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	-- Disable unwanted states
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

	-- Lock NPC in place
	for _, obj in ipairs(npc:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = false
		end
	end

	-- Anchor only the HRP
	hrp.Anchored = true

	for _, obj in ipairs(npc:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CanCollide = false
		end
	end

	-- Only torso collides
	local torso = npc:FindFirstChild("UpperTorso") or npc:FindFirstChild("Torso")

	if torso then
		torso.CanCollide = true
	end

	-- Store original position + rotation
	local originalPosition = hrp.Position
	local _, originalY, _ = hrp.CFrame:ToOrientation()

	registeredNPCs[npc] = {
		NPC = npc,
		Humanoid = humanoid,
		HRP = hrp,
		Config = finalConfig,
		OriginalPosition = originalPosition,
		OriginalY = originalY,
		LastUpdate = 0,
	}
end

function NPCFacingManager:Unregister(npc)
	registeredNPCs[npc] = nil
end

RunService.Heartbeat:Connect(function(deltaTime)
	for npc, data in pairs(registeredNPCs) do
		if not npc.Parent then
			registeredNPCs[npc] = nil
			continue
		end

		local hrp = data.HRP
		local config = data.Config

		data.LastUpdate += deltaTime

		if data.LastUpdate < config.UpdateRate then
			continue
		end

		data.LastUpdate = 0

		local targetCharacter = getNearestPlayer(hrp, config.Range)

		local desiredY

		if targetCharacter then
			local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")

			if targetRoot then
				local direction = targetRoot.Position - data.OriginalPosition

				desiredY = math.atan2(-direction.X, -direction.Z)
			end
		elseif config.ResetToOriginalRotation then
			desiredY = data.OriginalY
		end

		if desiredY then
			local _, currentY, _ = hrp.CFrame:ToOrientation()

			local smoothedY = lerpAngle(currentY, desiredY, math.clamp(config.FaceSpeed * config.UpdateRate, 0, 1))

			-- Lock position while rotating
			hrp.CFrame = CFrame.new(data.OriginalPosition) * CFrame.Angles(0, smoothedY, 0)
		else
			-- Stay perfectly locked
			hrp.CFrame = CFrame.new(data.OriginalPosition) * CFrame.Angles(0, select(2, hrp.CFrame:ToOrientation()), 0)
		end
	end
end)

return NPCFacingManager
