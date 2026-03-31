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

	local lifetime = data.lifetime or math.huge
	local transparency = data.transparency
	local scale = data.scale
	local initialRotation = data.initialRotation or Vector3.zero

	-- Offset from attachment
	local offset = data.offset or CFrame.identity
	offset *= CFrame.fromOrientation(initialRotation.X, initialRotation.Y, initialRotation.Z)

	-----------------------------------------------------------------
	-- Handle BasePart vs Model
	-----------------------------------------------------------------
	local rootPart
	local scaleData

	if effect:IsA("BasePart") then
		rootPart = effect
	else
		if not effect.PrimaryPart then
			effect.PrimaryPart = effect:FindFirstChildWhichIsA("BasePart")
		end
		rootPart = effect.PrimaryPart
		scaleData = CacheModelScaleData(effect)
	end

	if not rootPart then
		warn("[VFX] No valid root part for effect")
		effect:Destroy()
		return
	end

	-----------------------------------------------------------------
	-- Initial positioning
	-----------------------------------------------------------------
	rootPart.CFrame = attachTo.CFrame * offset

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
	-- 🔥 WELD (NO RENDERSTEPPED)
	-----------------------------------------------------------------
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = attachTo
	weld.Parent = rootPart

	-----------------------------------------------------------------
	-- Safety: destroy if attachment is removed
	-----------------------------------------------------------------
	attachTo.Destroying:Once(function()
		if effect and effect.Parent then
			effect:Destroy()
		end
	end)

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
	end
end)
