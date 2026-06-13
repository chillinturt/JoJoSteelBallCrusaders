local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local activeProjectiles = {} -- map: id -> { projectile, conn }

local SpawnVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")
local StandEffectsFolder = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("StandEffects")
local BarrageVfx = require(game.ReplicatedStorage.Shared.Modules:WaitForChild("BarrageVfx"))

-- Client
local VfxRootsById = {} -- [vfxId] = BasePart

local ActiveEmojis = {} -- character → BillboardGui
local ActiveOverhead = {} -- character -> instance
local EmojiFolder = ReplicatedStorage.Effects:WaitForChild("Emojis")

local function TryRegisterVfxRoot(inst)
	if inst:IsA("BasePart") then
		local id = inst:GetAttribute("VFX_ID")
		if id then
			VfxRootsById[id] = inst

			-- Auto-cleanup
			inst.Destroying:Once(function()
				VfxRootsById[id] = nil
			end)
		end
	end
end

-- Register already-existing parts
for _, inst in ipairs(workspace:GetDescendants()) do
	TryRegisterVfxRoot(inst)
end

-- Register future parts
workspace.DescendantAdded:Connect(TryRegisterVfxRoot)

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

local function CloneParticleEffect(template)
	local host = Instance.new("Part")
	host.Name = "ParticleHost"
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.Transparency = 1
	host.Size = Vector3.one * 0.1

	local attachment = template:Clone()
	attachment.Parent = host

	return host, attachment
end

local function ConfigureParticleEmitter(emitter, data)
	if data.speedMultiplier then
		emitter.Speed =
			NumberRange.new(emitter.Speed.Min * data.speedMultiplier, emitter.Speed.Max * data.speedMultiplier)
	end

	if data.scale then
		local newKeys = {}

		for _, key in ipairs(emitter.Size.Keypoints) do
			table.insert(newKeys, NumberSequenceKeypoint.new(key.Time, key.Value * data.scale))
		end

		emitter.Size = NumberSequence.new(newKeys)
	end

	if data.color then
		emitter.Color = data.color
	end

	if data.transparency then
		emitter.Transparency = data.transparency
	end

	if data.rate then
		emitter.Rate = data.rate
	end

	if data.lifetimeMultiplier then
		emitter.Lifetime = NumberRange.new(
			emitter.Lifetime.Min * data.lifetimeMultiplier,
			emitter.Lifetime.Max * data.lifetimeMultiplier
		)
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
	local primary = model.PrimaryPart

	for part, info in pairs(scaleData) do
		part.Size = info.size * scale

		part.CFrame = primary.CFrame
			* CFrame.new(info.offset.Position * scale)
			* CFrame.fromOrientation(info.offset:ToEulerAnglesXYZ())
	end
end

-- Finds an effect model by name across all stands
local function FindEffect(effectName)
	for _, standFolder in ipairs(StandEffectsFolder:GetChildren()) do
		local effect = standFolder:FindFirstChild(effectName)
		if effect then
			return effect
		end
	end
	return nil
end

local function DeleteProjectileVFX(id)
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
	local originalSize

	local currentScale = scale or 1
	local scaleData

	if effect:IsA("BasePart") then
		effect.CFrame = baseCFrame
		originalSize = effect.Size
	else
		if not effect.PrimaryPart then
			effect.PrimaryPart = effect:FindFirstChildWhichIsA("BasePart")
		end

		-- 🔥 IMPORTANT: place model FIRST
		effect:SetPrimaryPartCFrame(baseCFrame)

		-- 🔥 Cache per-part scale data (this IS the "original size")
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

		if expand and expandRate then
			local nextScale = currentScale + expandRate * dt

			if maxScale then
				if expandRate > 0 then
					-- growing
					currentScale = math.min(nextScale, maxScale)
				else
					-- shrinking
					currentScale = math.max(nextScale, maxScale)
				end
			else
				currentScale = nextScale
			end

			if effect:IsA("BasePart") then
				effect.Size = originalSize * currentScale
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

local function FindHitboxById(vfxId)
	return VfxRootsById[vfxId]
end

local function SpawnParticleVFX(template, data)
	if not template then
		return
	end

	-------------------------------------------------
	-- Clone host + attachment
	-------------------------------------------------
	local host, attachment = CloneParticleEffect(template)
	host.Parent = workspace

	local lifetime = data.lifetime or 3
	local offset = data.offset or CFrame.identity
	local initialRotation = data.initialRotation or Vector3.zero

	offset *= CFrame.fromOrientation(initialRotation.X, initialRotation.Y, initialRotation.Z)

	-------------------------------------------------
	-- Resolve attachment target
	-------------------------------------------------
	local attachTo = data.attachTo

	if not attachTo and data.attachId then
		local startTime = os.clock()
		local timeout = 2

		repeat
			attachTo = FindHitboxById(data.attachId)
			task.wait()
		until attachTo or os.clock() - startTime > timeout
	end

	-------------------------------------------------
	-- ATTACHED MODE (Motor6D)
	-------------------------------------------------
	if attachTo and attachTo:IsA("BasePart") then
		-- Prevent physics weirdness
		host.Anchored = true
		host.CanCollide = false
		host.Massless = true

		-- Force position FIRST
		local targetCF = attachTo.CFrame * offset
		host.CFrame = targetCF

		-- Force attachment world update
		for _, att in ipairs(host:GetDescendants()) do
			if att:IsA("Attachment") then
				att.WorldCFrame = att.WorldCFrame
			end
		end

		-- Attach using Motor6D
		local motor = Instance.new("Motor6D")
		motor.Name = "ParticleMotor"
		motor.Part0 = attachTo
		motor.Part1 = host
		motor.C0 = offset
		motor.Parent = attachTo

		-- Unanchor AFTER motor is created
		host.Anchored = false

		-- Safety cleanup
		attachTo.Destroying:Once(function()
			if host and host.Parent then
				host:Destroy()
			end
		end)
	else
		-------------------------------------------------
		-- STATIONARY MODE
		-------------------------------------------------
		local cf = data.cframe or CFrame.new()

		if typeof(cf) == "Vector3" then
			host.Position = cf
		else
			host.CFrame = cf * offset
		end
	end

	-------------------------------------------------
	-- CONFIGURE + PLAY
	-------------------------------------------------
	local longestLifetime = 0

	for _, obj in ipairs(attachment:GetDescendants()) do
		if obj:IsA("ParticleEmitter") then
			ConfigureParticleEmitter(obj, data)

			longestLifetime = math.max(longestLifetime, obj.Lifetime.Max)

			-- Burst
			if data.emitCount then
				obj:Emit(data.emitCount)
			else
				-- Continuous
				obj.Enabled = true
			end
		end
	end

	-------------------------------------------------
	-- CLEANUP
	-------------------------------------------------
	local cleanupTime = math.max(lifetime, longestLifetime + 0.25)

	task.delay(cleanupTime, function()
		if not host or not host.Parent then
			return
		end

		-- Disable looping emitters first
		for _, obj in ipairs(host:GetDescendants()) do
			if obj:IsA("ParticleEmitter") then
				obj.Enabled = false
			end
		end

		task.delay(longestLifetime, function()
			if host and host.Parent then
				host:Destroy()
			end
		end)
	end)

	return host
end

local function WeldEffect(effect, attachTo, offset)
	if effect:IsA("BasePart") then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = effect
		weld.Part1 = attachTo
		weld.Parent = effect

		effect.CFrame = attachTo.CFrame * offset
	else
		local root = effect.PrimaryPart
		root.CFrame = attachTo.CFrame * offset

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = attachTo
		weld.Parent = root
	end
end

-- 🌟 ATTACHED EFFECT SPAWNER (WELD-BASED, NO FRAME LOOPS)
local function SpawnAttachedVFX(template, data)
	if not template or not data then
		warn("[VFX] Missing template or data")
		return
	end

	-----------------------------------------------------------------
	-- Resolve attachment target
	-----------------------------------------------------------------
	local attachTo = data.attachTo

	if not attachTo and data.attachId then
		local startTime = os.clock()
		local timeout = 2

		repeat
			attachTo = FindHitboxById(data.attachId)
			task.wait()
		until attachTo or os.clock() - startTime > timeout
	end

	if not attachTo or not attachTo:IsA("BasePart") then
		warn("[VFX] attachTo missing or invalid")
		return
	end

	-----------------------------------------------------------------
	-- Clone & setup effect
	-----------------------------------------------------------------
	local effect = template:Clone()
	effect.Parent = workspace

	-- Disable physics
	for _, part in ipairs(effect:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Massless = true
			part.Anchored = true -- 🔥 IMPORTANT: prevent physics snap
		end
	end

	local lifetime = data.lifetime or 2
	local transparency = data.transparency
	local scale = data.scale
	local initialRotation = data.initialRotation or Vector3.zero

	-- Offset
	local offset = data.offset or CFrame.identity
	offset *= CFrame.fromOrientation(initialRotation.X, initialRotation.Y, initialRotation.Z)

	-----------------------------------------------------------------
	-- Resolve root
	-----------------------------------------------------------------
	local rootPart

	if effect:IsA("BasePart") then
		rootPart = effect
	else
		if not effect.PrimaryPart then
			effect.PrimaryPart = effect:FindFirstChildWhichIsA("BasePart")
		end
		rootPart = effect.PrimaryPart
	end

	if not rootPart then
		warn("[VFX] No valid root part")
		effect:Destroy()
		return
	end

	-----------------------------------------------------------------
	-- Disable Trails FIRST (CRITICAL)
	-----------------------------------------------------------------
	local trails = {}
	for _, obj in ipairs(effect:GetDescendants()) do
		if obj:IsA("Trail") then
			obj.Enabled = false
			obj:Clear()
			table.insert(trails, obj)
		end
	end

	-----------------------------------------------------------------
	-- FORCE POSITION MODEL BEFORE ANYTHING ELSE
	-----------------------------------------------------------------
	local targetCF = attachTo.CFrame * offset

	if effect:IsA("Model") then
		effect:PivotTo(targetCF)
	else
		rootPart.CFrame = targetCF
	end

	-----------------------------------------------------------------
	-- FORCE ATTACHMENTS TO UPDATE (CRITICAL FIX)
	-----------------------------------------------------------------
	for _, att in ipairs(effect:GetDescendants()) do
		if att:IsA("Attachment") then
			att.WorldCFrame = att.WorldCFrame
		end
	end

	-----------------------------------------------------------------
	-- Apply visual modifiers
	-----------------------------------------------------------------
	if transparency then
		if effect:IsA("BasePart") then
			effect.Transparency = transparency
		else
			SetTransparency(effect, transparency)
		end
	end

	if scale then
		if effect:IsA("BasePart") then
			if typeof(scale) == "Vector3" then
				effect.Size = scale
			else
				effect.Size *= scale
			end
		else
			ScaleModel(effect, scale)
		end
	end

	-----------------------------------------------------------------
	-- Attach using Motor6D
	-----------------------------------------------------------------
	local motor = Instance.new("Motor6D")
	motor.Name = "VFXMotor"
	motor.Part0 = attachTo
	motor.Part1 = rootPart
	motor.C0 = offset
	motor.Parent = attachTo

	-- Unanchor AFTER welding
	for _, part in ipairs(effect:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end

	-----------------------------------------------------------------
	-- ENABLE TRAILS AFTER 1 FRAME (FINAL FIX)
	-----------------------------------------------------------------
	task.defer(function()
		for _, trail in ipairs(trails) do
			if trail and trail.Parent then
				trail:Clear()
				trail.Enabled = true
			end
		end
	end)

	-----------------------------------------------------------------
	-- Safety cleanup
	-----------------------------------------------------------------
	attachTo.Destroying:Once(function()
		if effect and effect.Parent then
			effect:Destroy()
		end
	end)

	-----------------------------------------------------------------
	-- Lifetime with fade
	-----------------------------------------------------------------
	if lifetime ~= math.huge then
		task.delay(lifetime, function()
			if not effect or not effect.Parent then
				return
			end

			local fadeTime = 0.2

			for _, obj in ipairs(effect:GetDescendants()) do
				if obj:IsA("BasePart") then
					TweenService:Create(obj, TweenInfo.new(fadeTime), {
						Transparency = 1,
					}):Play()
				elseif obj:IsA("Trail") then
					obj.Enabled = false
				end
			end

			task.delay(fadeTime, function()
				if effect and effect.Parent then
					effect:Destroy()
				end
			end)
		end)
	end

	return effect
end

local function ShowEmoji(data)
	local character = data.character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	-- Remove existing emoji on this character
	if ActiveEmojis[character] then
		ActiveEmojis[character]:Destroy()
		ActiveEmojis[character] = nil
	end

	-- Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Emoji"
	billboard.Adornee = head
	billboard.Size = data.size or UDim2.fromScale(2, 2)
	billboard.StudsOffset = data.offset or Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	-- Head image
	local headImage = Instance.new("ImageLabel")
	headImage.Size = UDim2.fromScale(1, 1)
	headImage.BackgroundTransparency = 1
	headImage.Image = data.headImage
	headImage.Parent = billboard

	-- Face image
	local faceImage = Instance.new("ImageLabel")
	faceImage.Size = UDim2.fromScale(1, 1)
	faceImage.BackgroundTransparency = 1
	faceImage.Image = data.faceImage
	faceImage.Parent = billboard

	ActiveEmojis[character] = billboard

	-- Optional pop-in animation
	headImage.ImageTransparency = 1
	faceImage.ImageTransparency = 1

	TweenService
		:Create(
			headImage,
			TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ ImageTransparency = 0 }
		)
		:Play()

	TweenService
		:Create(
			faceImage,
			TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ ImageTransparency = 0 }
		)
		:Play()

	-- Auto cleanup
	task.delay(data.duration or 2, function()
		if ActiveEmojis[character] == billboard then
			billboard:Destroy()
			ActiveEmojis[character] = nil
		end
	end)
end

local function ShowOverheadVFX(template, data)
	local character = data.target
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	-- Remove existing overhead effect
	if ActiveOverhead[character] then
		ActiveOverhead[character]:Destroy()
		ActiveOverhead[character] = nil
	end

	local lifetime = data.lifetime or 2

	-------------------------------------------------
	-- OPTION 1: Billboard GUI (UI-style)
	-------------------------------------------------
	if template:IsA("BillboardGui") then
		local gui = template:Clone()
		gui.Adornee = head
		gui.Parent = head

		if data.offset then
			gui.StudsOffset = data.offset
		else
			gui.StudsOffset = Vector3.new(0, 3, 0)
		end

		ActiveOverhead[character] = gui

		-- Fade in
		for _, obj in ipairs(gui:GetDescendants()) do
			if obj:IsA("ImageLabel") or obj:IsA("TextLabel") then
				obj.ImageTransparency = 1
				obj.TextTransparency = 1

				TweenService:Create(obj, TweenInfo.new(0.2), {
					ImageTransparency = 0,
					TextTransparency = 0,
				}):Play()
			end
		end

		task.delay(lifetime, function()
			if ActiveOverhead[character] == gui then
				gui:Destroy()
				ActiveOverhead[character] = nil
			end
		end)

		return
	end

	-------------------------------------------------
	-- OPTION 2: 3D MODEL (world VFX)
	-------------------------------------------------
	local effect = template:Clone()
	effect.Parent = workspace

	-- Setup root
	if not effect.PrimaryPart then
		effect.PrimaryPart = effect:FindFirstChildWhichIsA("BasePart")
	end

	if not effect.PrimaryPart then
		warn("[VFX] Overhead effect missing PrimaryPart")
		effect:Destroy()
		return
	end

	-- Position above head
	local offset = data.offset or Vector3.new(0, 3, 0)
	effect:SetPrimaryPartCFrame(head.CFrame + offset)

	-- Weld using Motor6D (same pattern as attached)
	local motor = Instance.new("Motor6D")
	motor.Part0 = head
	motor.Part1 = effect.PrimaryPart
	motor.C0 = CFrame.new(offset)
	motor.Parent = head

	ActiveOverhead[character] = effect

	-- Optional scale
	if data.scale then
		ScaleModel(effect, data.scale)
	end

	-- Optional transparency
	if data.transparency then
		SetTransparency(effect, data.transparency)
	end

	-- Cleanup
	task.delay(lifetime, function()
		if ActiveOverhead[character] == effect then
			effect:Destroy()
			ActiveOverhead[character] = nil
		end
	end)
end

local function SpawnAttachedTextBurst(data)
	if not data then
		return
	end

	local attachTo = data.attachTo

	if not attachTo and data.attachId then
		local startTime = os.clock()
		local timeout = 2

		repeat
			attachTo = FindHitboxById(data.attachId)
			task.wait()
		until attachTo or os.clock() - startTime > timeout
	end

	if not attachTo or not attachTo:IsA("BasePart") then
		warn("[TextBurst] Invalid attachment")
		return
	end

	local template = ReplicatedStorage.Effects.StandEffects.HeavensDoor:FindFirstChild("TextBurstGui")
	if not template then
		warn("Missing TextBurstGui")
		return
	end

	local Styles = {}

	-- 🟢 DEFAULT (Page Slash)
	Styles.Default = {
		color = Color3.fromRGB(255, 255, 255),
		stroke = Color3.fromRGB(0, 0, 0),
		size = 1,
		popScale = 1.2,
		drift = Vector3.new(3, 5, 3),
		rotation = 25,
		font = Enum.Font.SourceSansBold,
		countMultiplier = 1,
	}

	-- 📖 FORCE READ (dramatic, "opening a book")
	Styles.WriteCommand = {
		color = Color3.fromRGB(255, 230, 120), -- warm yellow
		stroke = Color3.fromRGB(80, 0, 120), -- purple tint
		size = 1.3,
		popScale = 1.6,
		drift = Vector3.new(2, 8, 2), -- more vertical
		rotation = 10,
		font = Enum.Font.GothamBlack,
		countMultiplier = 1.5,
	}

	-- 🔥 MEMORY BURN (INSANE)
	Styles.MemoryBurn = {
		color = Color3.fromRGB(255, 80, 80), -- red
		stroke = Color3.fromRGB(0, 0, 0),
		size = 2,
		popScale = 2.5,
		drift = Vector3.new(6, 10, 6), -- explosive spread
		rotation = 45,
		font = Enum.Font.Arcade,
		countMultiplier = 2.5,
	}

	-- 🔥 STYLE
	local style = Styles[data.style or "Default"] or Styles.Default

	local baseCount = data.count or 8
	local count = math.floor(baseCount * style.countMultiplier)

	local lifetime = data.lifetime or 1.2
	local textPool = data.textPool or { "ド", "ラ", "ッ" }
	local baseOffset = data.offset or Vector3.new(0, 3, 0)

	for i = 1, count do
		local gui = template:Clone()
		gui.Parent = attachTo
		gui.Adornee = attachTo
		gui.AlwaysOnTop = true

		local label = gui:FindFirstChildWhichIsA("TextLabel")
		if not label then
			gui:Destroy()
			continue
		end

		-- TEXT
		label.Text = textPool[math.random(1, #textPool)]
		label.Font = style.font

		label.TextColor3 = style.color
		label.TextStrokeColor3 = style.stroke
		label.TextStrokeTransparency = 0

		label.TextTransparency = 1

		-- SCALE
		label.Size = UDim2.fromScale(0.3 * style.size, 0.3 * style.size)

		-- ROTATION
		label.Rotation = math.random(-style.rotation, style.rotation)

		-- POSITION
		local randomOffset = baseOffset
			+ Vector3.new(
				math.random(-style.drift.X, style.drift.X),
				math.random(0, 2),
				math.random(-style.drift.Z, style.drift.Z)
			)

		gui.StudsOffset = randomOffset

		-- 🔥 POP
		TweenService:Create(label, TweenInfo.new(0.12, Enum.EasingStyle.Back), {
			TextTransparency = 0,
			Size = UDim2.fromScale(style.popScale, style.popScale),
		}):Play()

		task.delay(0.12, function()
			if label then
				TweenService:Create(label, TweenInfo.new(0.1), {
					Size = UDim2.fromScale(style.size, style.size),
				}):Play()
			end
		end)

		-- 🔥 DRIFT
		local drift = Vector3.new(
			math.random(-style.drift.X, style.drift.X),
			style.drift.Y,
			math.random(-style.drift.Z, style.drift.Z)
		)

		TweenService:Create(gui, TweenInfo.new(lifetime, Enum.EasingStyle.Quad), {
			StudsOffset = randomOffset + drift,
		}):Play()

		-- 🔥 FADE
		task.delay(0.2, function()
			if label then
				TweenService:Create(label, TweenInfo.new(lifetime * 0.8), {
					TextTransparency = 1,
				}):Play()
			end
		end)

		-- CLEANUP
		task.delay(lifetime, function()
			if gui then
				gui:Destroy()
			end
		end)
	end
end

SpawnVfx.OnClientEvent:Connect(function(data)
	if data.type == "Projectile" and data.deleteId then
		DeleteProjectileVFX(data.deleteId)
		return
	end

	if not data or not data.type then
		return
	end

	-- 🔥 BARRAGE HANDLER
	if data.type == "Barrage" then
		if data.action == "Start" then
			BarrageVfx.barragestart(data.character, data.distance, data.speed, data.rate, data.armCopy)
		elseif data.action == "End" then
			BarrageVfx.barragend(data.character)
		end
		return
	end

	if data.type == "Emoji" then
		ShowEmoji(data)
		return
	end

	if data.type == "TextBurst" then
		SpawnAttachedTextBurst(data)
		return
	end

	-- All other VFX
	if not data.effectName then
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
	elseif data.type == "Particle" then
		SpawnParticleVFX(template, data)
	end

	if data.type == "Particle" then
		SpawnParticleVFX(template, data)
		return
	end

	if data.type == "Overhead" then
		if not data.effectName then
			return
		end

		--local template = FindEffect(data.effectName)
		if not template then
			warn("[VFX] Missing overhead effect:", data.effectName)
			return
		end

		ShowOverheadVFX(template, data)
		return
	end
end)
