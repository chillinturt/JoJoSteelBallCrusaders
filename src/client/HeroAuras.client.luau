local ReplicatedStorage = game:GetService("ReplicatedStorage")

local standAurasEvent = ReplicatedStorage.Shared.Events:WaitForChild("StandAurasEvent")
local AuraFolder = ReplicatedStorage.StandModels:WaitForChild("HeroAuras")

-- Track active auras per character
local activeAuras = {}

local function removeAura(character)
	if activeAuras[character] then
		activeAuras[character]:Destroy()
		activeAuras[character] = nil
	end
end

standAurasEvent.OnClientEvent:Connect(function(character, standTag, enabled)
	print("[AuraClient] Event received:", character, standTag, enabled)

	if not character or not character:IsA("Model") then
		return
	end

	-- Wait for HRP
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		warn("[AuraClient] HRP not found for", character:GetFullName())
		return
	end

	-- Normalize stand tags
	if standTag:match("^TuskAct") then
		standTag = "Tusk"
	end

	local auraTemplate = AuraFolder:FindFirstChild(standTag)
	if not auraTemplate then
		warn("[AuraClient] No aura found for", standTag)
		return
	end

	if not enabled then
		removeAura(character)
		return
	end

	-- Remove any existing aura
	removeAura(character)

	-- Clone aura
	local aura = auraTemplate:Clone()
	aura.Name = "ClientAura"
	aura.Parent = character -- parent to character, like a stand

	-- Set offset & rotation (you can tweak)
	local rotation = CFrame.Angles(0, 0, 0)
	local offset = CFrame.new(0, 0, 0) -- default above HRP
	offset = offset * rotation

	-- Weld to HRP (like server does with Motor6D)
	if aura.PrimaryPart then
		local weld = Instance.new("Motor6D")
		weld.Part0 = hrp
		weld.Part1 = aura.PrimaryPart
		weld.C0 = offset
		weld.Name = "AuraMotor"
		weld.Parent = aura.PrimaryPart
	end

	-- Visual-only setup
	for _, obj in ipairs(aura:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = false -- must be false for Motor6D to move it
			obj.CanCollide = false
			obj.Massless = true
			obj.CanTouch = false
			obj.CanQuery = false
			obj.LocalTransparencyModifier = 0
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
			obj.Enabled = true
			if obj:IsA("Beam") then
				if not obj.Attachment0 then
					local att0 = Instance.new("Attachment")
					att0.Parent = aura.PrimaryPart
					obj.Attachment0 = att0
				end
				if not obj.Attachment1 then
					local att1 = Instance.new("Attachment")
					att1.Parent = aura.PrimaryPart
					obj.Attachment1 = att1
				end
			end
		end
	end

	activeAuras[character] = aura
end)
