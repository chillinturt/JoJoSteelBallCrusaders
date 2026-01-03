local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local activeProjectiles = {} -- map: id -> { projectile, conn }

local SpawnVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")
local StandEffectsFolder = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("StandEffects")

local function WeldModel(model)
	if not model:IsA("Model") then
		return
	end

	local primary = model.PrimaryPart
	if not primary then
		warn("[VFX] Model has no PrimaryPart:", model.Name)
		return
	end

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= primary then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = primary
			weld.Part1 = part
			weld.Parent = primary
		end
	end
end

local function CacheOffsets(model)
	local primary = model.PrimaryPart
	local offsets = {}

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			offsets[part] = primary.CFrame:ToObjectSpace(part.CFrame)
		end
	end

	return offsets
end

local function CacheModelScaleData(model)
	local primary = model.PrimaryPart
	local data = {}

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			data[part] = {
				size = part.Size,
				offset = primary.CFrame:ToObjectSpace(part.CFrame),
			}
		end
	end

	return data
end

local function ApplyModelScale(model, scaleData, scale)
	print("applying model scale")
	local primary = model.PrimaryPart

	for part, info in pairs(scaleData) do
		part.Size = info.size * scale

		part.CFrame = primary.CFrame
			* CFrame.new(info.offset.Position * scale)
			* CFrame.fromOrientation(info.offset:ToEulerAnglesXYZ())
	end
end

-- Makes any effect visual-only
local function MakeVisualOnly(instance)
	for _, obj in ipairs(instance:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
			obj.Massless = true
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
			obj.AssemblyLinearVelocity = Vector3.zero
			obj.AssemblyAngularVelocity = Vector3.zero
			obj.LocalTransparencyModifier = 0
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
			obj.Enabled = true
		end
	end
end

-- Finds an effect model by name across all stands
local function FindEffect(effectName)
	for _, standFolder in ipairs(StandEffectsFolder:GetChildren()) do
		print("[VFX] Checking stand folder:", standFolder.Name)
		local effect = standFolder:FindFirstChild(effectName)
		if effect then
			return effect
		end
	end
	return nil
end

local function DeleteProjectileVFX(id)
	print("Delete projectile called on client")
	local data = activeProjectiles[id]
	if data then
		if data.conn then
			data.conn:Disconnect()
		end
		if data.projectile then
			data.projectile:Destroy()
		end
		activeProjectiles[id] = nil
	else
		warn("no data found on deletion vfx!")
	end
end

local function SpawnProjectileVFX(template, data)
	local projectile = template:Clone()
	projectile.Parent = workspace

	MakeVisualOnly(projectile)

	-- Assign unique ID
	local id = data.id or HttpService:GenerateGUID(false)
	projectile:SetAttribute("VFX_ID", id)

	local lifetime = data.lifetime or 5
	local startTime = os.clock()

	local velocity
	local gravity = data.gravity or Vector3.zero
	local arc = data.arc == true

	if arc then
		velocity = data.initialVelocity
		assert(velocity, "[VFX] Arc projectile requires initialVelocity")
	else
		local direction = data.direction.Unit
		velocity = direction * data.speed
	end

	local baseCFrame = data.cframe or CFrame.new(data.origin, data.origin + velocity)

	if data.initialRotation then
		baseCFrame *= CFrame.fromOrientation(data.initialRotation.X, data.initialRotation.Y, data.initialRotation.Z)
	end

	local conn
	if projectile:IsA("BasePart") then
		projectile.CFrame = baseCFrame
		conn = RunService.RenderStepped:Connect(function(dt)
			velocity += gravity * dt
			baseCFrame += velocity * dt
			projectile.CFrame = baseCFrame

			if os.clock() - startTime >= lifetime then
				conn:Disconnect()
				projectile:Destroy()
				activeProjectiles[id] = nil
			end
		end)
	else
		if not projectile.PrimaryPart then
			projectile.PrimaryPart = projectile:FindFirstChildWhichIsA("BasePart")
		end
		projectile:SetPrimaryPartCFrame(baseCFrame)
		conn = RunService.RenderStepped:Connect(function(dt)
			velocity += gravity * dt
			baseCFrame += velocity * dt
			projectile:SetPrimaryPartCFrame(baseCFrame)

			if os.clock() - startTime >= lifetime then
				conn:Disconnect()
				projectile:Destroy()
				activeProjectiles[id] = nil
			end
		end)
	end

	activeProjectiles[id] = { projectile = projectile, conn = conn }
	return projectile, id
end

local function SetTransparency(instance, value)
	for _, obj in ipairs(instance:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Transparency = value
		end
	end
end

local function ScaleModel(model, scale)
	local primary = model.PrimaryPart
	if not primary then
		return
	end

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local offset = primary.CFrame:ToObjectSpace(part.CFrame)
			part.Size *= scale
			part.CFrame = primary.CFrame
				* CFrame.new(offset.Position * scale)
				* CFrame.fromOrientation(offset:ToEulerAnglesXYZ())
		end
	end
end

-- 🌟 STATIONARY EFFECT SPAWNER
local function SpawnStationaryEffect(params)
	local effect = params.template:Clone()
	effect.Parent = workspace

	MakeVisualOnly(effect)

	local lifetime = params.lifetime or math.huge
	local rotationSpeed = params.rotationSpeed or Vector3.zero
	local transparency = params.transparency
	local scale = params.scale
	local maxScale = params.maxScale
	local onUpdate = params.onUpdate

	local startTime = os.clock()

	local expand = params.expand
	local expandRate = params.expandRate or 0
	local initialRotation = params.initialRotation or Vector3.zero
	local baseCFrame = params.cframe * CFrame.fromOrientation(initialRotation.X, initialRotation.Y, initialRotation.Z)

	local currentScale = scale or 1
	local scaleData
	-- Handle BasePart vs Model
	if effect:IsA("BasePart") then
		effect.CFrame = baseCFrame
	else
		if not effect.PrimaryPart then
			effect.PrimaryPart = effect:FindFirstChildWhichIsA("BasePart")
		end

		-- 🔥 IMPORTANT: place model FIRST
		effect:SetPrimaryPartCFrame(baseCFrame)

		-- 🔥 THEN cache offsets / sizes
		scaleData = CacheModelScaleData(effect)
	end

	-- Handle BasePart vs Model
	if effect:IsA("BasePart") then
		effect.CFrame = baseCFrame
		if transparency then
			effect.Transparency = transparency
		end
		if scale then
			effect.Size *= scale
		end
	else
		if not effect.PrimaryPart then
			effect.PrimaryPart = effect:FindFirstChildWhichIsA("BasePart")
		end

		if transparency then
			SetTransparency(effect, transparency)
		end
		if scale then
			ScaleModel(effect, scale)
		end
	end

	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local elapsed = os.clock() - startTime

		-- Rotate
		if rotationSpeed.Magnitude > 0 then
			baseCFrame *= CFrame.fromOrientation(rotationSpeed.X * dt, rotationSpeed.Y * dt, rotationSpeed.Z * dt)

			if effect:IsA("BasePart") then
				effect.CFrame = baseCFrame
			else
				effect:SetPrimaryPartCFrame(baseCFrame)
			end
		end

		-- Expansion (MODEL-SAFE + CLAMPED)
		if expand and expandRate > 0 then
			local nextScale = currentScale + expandRate * dt

			if maxScale then
				currentScale = math.min(nextScale, maxScale)
			else
				currentScale = nextScale
			end

			if effect:IsA("BasePart") then
				effect.Size = effect.Size.Unit * currentScale
			else
				ApplyModelScale(effect, scaleData, currentScale)
			end
		end

		-- User update hook
		if onUpdate then
			onUpdate(effect, dt, elapsed)
		end

		if elapsed >= lifetime then
			conn:Disconnect()
			effect:Destroy()
		end
	end)

	return effect
end

local function FindHitboxById(id, character)
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("VFX_ID") == id then
			return obj
		end
	end
	return nil
end

-- 🌟 ATTACHED EFFECT SPAWNER
local function SpawnAttachedVFX(template, data)
	if not template or not data then
		print("no template or data or attachto found")
		return
	end

	local attachTo = data.attachTo

	-- If attachTo is missing, try resolving by attachId
	if not attachTo and data.attachId then
		local startTime = os.clock()
		local timeout = 2
		repeat
			local player = Players.LocalPlayer
			local character = player.Character
			attachTo = FindHitboxById(data.attachId, character)
			task.wait()
		until attachTo or os.clock() - startTime > timeout
	end

	if not attachTo or not attachTo:IsA("BasePart") then
		warn("[VFX] attachTo missing or invalid")
		return
	end

	-- Clone effect
	local effect = template:Clone()
	effect.Parent = workspace

	MakeVisualOnly(effect)

	local lifetime = data.lifetime or math.huge
	local rotationSpeed = data.rotationSpeed or Vector3.zero
	local transparency = data.transparency
	local scale = data.scale
	local initialRotation = data.initialRotation or Vector3.zero
	local onUpdate = data.onUpdate

	local startTime = os.clock()

	-- Initial offset from attachment part
	local offset = data.offset or CFrame.identity
	offset *= CFrame.fromOrientation(initialRotation.X, initialRotation.Y, initialRotation.Z)

	-- Handle BasePart vs Model
	local scaleData
	if effect:IsA("BasePart") then
		effect.CFrame = attachTo.CFrame * offset
	else
		if not effect.PrimaryPart then
			effect.PrimaryPart = effect:FindFirstChildWhichIsA("BasePart")
		end

		effect:SetPrimaryPartCFrame(attachTo.CFrame * offset)
		scaleData = CacheModelScaleData(effect)
	end

	-- Apply visual modifiers
	if transparency then
		if effect:IsA("BasePart") then
			effect.Transparency = transparency
		else
			SetTransparency(effect, transparency)
		end
	end

	if scale then
		if effect:IsA("BasePart") then
			effect.Size *= scale
		else
			ScaleModel(effect, scale)
		end
	end

	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		-- Attachment destroyed → cleanup
		if not attachTo.Parent then
			conn:Disconnect()
			effect:Destroy()
			return
		end

		local elapsed = os.clock() - startTime
		if elapsed >= lifetime then
			conn:Disconnect()
			effect:Destroy()
			return
		end

		-- Follow attached part
		local cf = attachTo.CFrame * offset

		-- Optional rotation
		if rotationSpeed.Magnitude > 0 then
			offset *= CFrame.fromOrientation(rotationSpeed.X * dt, rotationSpeed.Y * dt, rotationSpeed.Z * dt)
			cf = attachTo.CFrame * offset
		end

		if effect:IsA("BasePart") then
			effect.CFrame = cf
		else
			effect:SetPrimaryPartCFrame(cf)
		end

		-- User hook
		if onUpdate then
			onUpdate(effect, dt, elapsed)
		end
	end)

	-- Safety: destroy effect if attached part is explicitly destroyed
	attachTo.Destroying:Once(function()
		if conn then
			conn:Disconnect()
		end
		if effect then
			effect:Destroy()
		end
	end)

	return effect
end

SpawnVfx.OnClientEvent:Connect(function(data)
	if data.type == "Projectile" and data.deleteId then
		DeleteProjectileVFX(data.deleteId)
		print("Projectile vfx called for deletion!")
		return
	end

	if not data or not data.type or not data.effectName then
		return
	end

	local template = FindEffect(data.effectName)
	if not template then
		warn("[VFX] Missing effect template:", data.effectName)
		return
	end

	if data.type == "Projectile" then
		SpawnProjectileVFX(template, data)
	elseif data.type == "Stationary" then
		SpawnStationaryEffect({
			template = template,
			cframe = data.cframe,
			lifetime = data.lifetime,
			rotationSpeed = data.rotationSpeed,
			transparency = data.transparency,
			scale = data.scale,
			maxScale = data.maxScale,
			expand = data.expand,
			expandRate = data.expandRate,
			initialRotation = data.initialRotation,
		})
	elseif data.type == "Attached" then
		SpawnAttachedVFX(template, data)
	end
end)
