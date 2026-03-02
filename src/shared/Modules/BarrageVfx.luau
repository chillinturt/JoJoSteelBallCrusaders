local BarrageVfx = {}

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

if not RunService:IsClient() then
	error("BarrageVfx must only be executed on the client")
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BarrageEffectsFolder = ReplicatedStorage.Effects.StandEffects:WaitForChild("BarrageEffects")

local function lerp(a, b, t)
	--a value is start position
	--b value is end position
	--t value is time

	return a + (b - a) * t
end

local ts = game:GetService("TweenService")

local function barrage(character, distance, speed, rate, armCopy)
	print("Barrage function called")
	task.spawn(function()
		local random = math.random(1, 100) / 100
		local xr = math.random(-6, 0) + random
		local yr = math.random(-5, 5) + random
		local zr = (distance * -1) / 2
		local startpoint = character["LeftHand"].Position
		local dis = distance * -1
		local endpoint = character.HumanoidRootPart.CFrame * CFrame.new(xr / 3, yr / 3, dis)
		local endp = endpoint.Position
		local curvepoint = character.HumanoidRootPart.CFrame * CFrame.new(xr, yr, zr)
		local curvep = curvepoint.Position

		local model = Instance.new("Model")
		model.Parent = workspace
		if character:FindFirstChild("Shirt") then
			local clothing = Instance.new("Shirt")
			clothing.ShirtTemplate = character.Shirt.ShirtTemplate
			clothing.Parent = model
		end

		local LeftArm = Instance.new("Part")
		LeftArm.Size = Vector3.new(1, 1.2, 1)
		LeftArm.Shape = Enum.PartType.Block
		LeftArm.Anchored = true
		LeftArm.CanCollide = false
		LeftArm.CanTouch = false
		LeftArm.CanQuery = false
		LeftArm.Massless = true
		LeftArm.Transparency = 0.5
		LeftArm.Name = "LeftHand"
		LeftArm.Parent = model
		LeftArm.Material = "SmoothPlastic"

		if armCopy then
			for i, v in pairs(character:GetChildren()) do
				if v:IsA("CharacterMesh") then
					if v.BodyPart == Enum.BodyPart.LeftArm then
						local mesh = v:Clone()
						mesh.Parent = model
					end
				end
			end
		end

		local att1 = Instance.new("Attachment")
		att1.CFrame = CFrame.new(0, -0.45, 0)
		local att2 = Instance.new("Attachment")
		att2.CFrame = CFrame.new(0, 0.45, 0)
		local trail = BarrageEffectsFolder.Trail:Clone()

		att1.Parent = LeftArm
		att2.Parent = LeftArm
		trail.Parent = LeftArm
		trail.Attachment1 = att1
		trail.Attachment0 = att2

		local trail2 = BarrageEffectsFolder.Trail2:Clone()

		trail2.Parent = LeftArm

		local att3 = Instance.new("Attachment")
		att3.CFrame = CFrame.new(0, -0.8, 0)
		local att4 = Instance.new("Attachment")
		att4.CFrame = CFrame.new(0, 0.8, 0)
		att3.Parent = LeftArm
		att4.Parent = LeftArm
		trail2.Attachment1 = att3
		trail2.Attachment0 = att4

		ts:Create(LeftArm, TweenInfo.new(0.4), { Transparency = 0 }):Play()

		game.Debris:AddItem(model, speed * 0.02)
		local i = 0
		local t = i / speed
		local l1 = lerp(startpoint, curvep, t)
		local l2 = lerp(curvep, endp, t)
		local last = lerp(l1, l2, t)

		for i = 0, speed, 1 do
			local t = i / speed

			local l1 = lerp(startpoint, curvep, t)
			local l2 = lerp(curvep, endp, t)

			--lerp1.Position = l1
			--lerp2.Position = l2

			local quad = lerp(l1, l2, t)

			LeftArm.CFrame = CFrame.lookAt(quad, last) * CFrame.Angles(math.rad(-90), 90, 0)
			RunService.RenderStepped:Wait()

			last = quad

			if (LeftArm.Position - endp).Magnitude < 0.1 then
				local biggersize = Vector3.new(1.196, 0.053, 1.196)
				local ring = BarrageEffectsFolder.PUNCHRING:Clone()
				ring.Transparency = 1
				ring.Parent = workspace.VFX
				ring.CanCollide = false
				ring.Anchored = true
				--ts:Create(ring, TweenInfo.new(0.1), {Transparency = 0.4}):Play()
				ts:Create(ring, TweenInfo.new(0.1), { Size = biggersize }):Play()
				ring.CFrame = LeftArm.CFrame
				ring.CFrame = endpoint * CFrame.new(0, 0, -1.5) * CFrame.Angles(math.rad(90), 90, 0)
				game.Debris:AddItem(ring, 0.3)

				for i, particle in pairs(game.Workspace.hit:GetChildren()) do
					local clone = particle:Clone()
					clone.Parent = ring
					clone:Emit(clone:GetAttribute("EmitCount"))
					game.Debris:AddItem(clone, 1)
				end
			end
		end
	end)
	task.wait(rate)
	task.spawn(function()
		local random = math.random(1, 100) / 100
		local xr = math.random(0, 6) + random
		local yr = math.random(-5, 5) + random
		local zr = (distance * -1) / 2
		local startpoint = character["RightHand"].Position
		local dis = distance * -1
		local endpoint = character.HumanoidRootPart.CFrame * CFrame.new(xr / 3, yr / 3, dis)
		local endp = endpoint.Position
		local curvepoint = character.HumanoidRootPart.CFrame * CFrame.new(xr, yr, zr)
		local curvep = curvepoint.Position

		local model = Instance.new("Model")
		model.Parent = workspace
		if character:FindFirstChild("Shirt") then
			local clothing = Instance.new("Shirt")
			clothing.ShirtTemplate = character.Shirt.ShirtTemplate
			clothing.Parent = model
		end

		local RightArm = Instance.new("Part")
		RightArm.Size = Vector3.new(0.3, 1.2, 0.3)
		RightArm.Shape = Enum.PartType.Cylinder
		RightArm.Anchored = true
		RightArm.CanCollide = false
		RightArm.CanTouch = false
		RightArm.CanQuery = false
		RightArm.Massless = true
		RightArm.Transparency = 0.5
		RightArm.Name = "RightHand"
		RightArm.Parent = model
		RightArm.Material = "SmoothPlastic"

		if armCopy then
			for i, v in pairs(character:GetChildren()) do
				if v:IsA("CharacterMesh") then
					if v.BodyPart == Enum.BodyPart.RightArm then
						local mesh = v:Clone()
						mesh.Parent = model
					end
				end
			end
		end

		local att1 = Instance.new("Attachment")
		att1.CFrame = CFrame.new(0, -0.45, 0)
		local att2 = Instance.new("Attachment")
		att2.CFrame = CFrame.new(0, 0.45, 0)
		local trail = BarrageEffectsFolder.Trail:Clone()

		att1.Parent = RightArm
		att2.Parent = RightArm
		trail.Parent = RightArm
		trail.Attachment1 = att1
		trail.Attachment0 = att2

		local trail2 = BarrageEffectsFolder.Trail2:Clone()

		trail2.Parent = RightArm

		local att3 = Instance.new("Attachment")
		att3.CFrame = CFrame.new(0, -0.8, 0)
		local att4 = Instance.new("Attachment")
		att4.CFrame = CFrame.new(0, 0.8, 0)
		att3.Parent = RightArm
		att4.Parent = RightArm
		trail2.Attachment1 = att3
		trail2.Attachment0 = att4

		ts:Create(RightArm, TweenInfo.new(0.4), { Transparency = 0 }):Play()

		game.Debris:AddItem(model, speed * 0.02)
		local i = 0
		local t = i / speed
		local l1 = lerp(startpoint, curvep, t)
		local l2 = lerp(curvep, endp, t)
		local last = lerp(l1, l2, t)

		for i = 0, speed, 1 do
			local t = i / speed

			local l1 = lerp(startpoint, curvep, t)
			local l2 = lerp(curvep, endp, t)

			--lerp1.Position = l1
			--lerp2.Position = l2

			local quad = lerp(l1, l2, t)

			RightArm.CFrame = CFrame.lookAt(quad, last) * CFrame.Angles(math.rad(-90), -90, 0)
			RunService.RenderStepped:Wait()

			last = quad

			if (RightArm.Position - endp).Magnitude < 0.1 then
				local biggersize = Vector3.new(1.196, 0.053, 1.196)
				local ring = BarrageEffectsFolder.PUNCHRING:Clone()
				ring.Transparency = 1
				ring.Parent = workspace.VFX
				ring.CanCollide = false
				ring.Anchored = true
				--ts:Create(ring, TweenInfo.new(0.1), {Transparency = 0.4}):Play()
				ts:Create(ring, TweenInfo.new(0.1), { Size = biggersize }):Play()
				ring.CFrame = RightArm.CFrame
				ring.CFrame = endpoint * CFrame.new(0, 0, -1.5) * CFrame.Angles(math.rad(90), 90, 0)
				game.Debris:AddItem(ring, 0.3)

				for i, particle in pairs(game.Workspace.hit:GetChildren()) do
					local clone = particle:Clone()
					clone.Parent = ring
					clone:Emit(clone:GetAttribute("EmitCount"))
					game.Debris:AddItem(clone, 1)
				end
			end
		end
	end)
end

function BarrageVfx.barragestart(char, distance, speed, rate, armCopy)
	print("barrage start called")
	if char:FindFirstChild("InBarrage") == nil then
		local check = Instance.new("IntValue")
		check.Parent = char
		check.Name = "InBarrage"

		Debris:AddItem(check, 5)

		local light = Instance.new("PointLight")
		light.Parent = char.HumanoidRootPart
		light.Name = "BarrageLight"
		light.Color = Color3.fromRGB(255, 255, 255)
		light.Range = 8
		light.Brightness = 1

		--[[
				char["LeftHand"].Transparency = 1
		char["LeftLowerArm"].Transparency = 1
		char["LeftUpperArm"].Transparency = 1
		char["RightHand"].Transparency = 1
		char["RightLowerArm"].Transparency = 1
		char["RightUpperArm"].Transparency = 1
		]]

		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://14514209255"

		anim.Parent = script

		local ATT = Instance.new("Attachment")
		ATT.Name = "BarrageAttachment"
		ATT.Parent = char.HumanoidRootPart
		local dis = distance * -1

		ATT.Position = Vector3.new(0, 0, dis)
		local smoke = BarrageEffectsFolder.HeavySmoke3:Clone()
		smoke.Parent = ATT
		smoke.Enabled = true

		repeat
			barrage(char, distance, speed, rate, armCopy)

			task.wait(rate)
		until char:FindFirstChild("InBarrage") == nil
	end
end

function BarrageVfx.barragend(char)
	print("barrage end called")
	if char:FindFirstChild("InBarrage") then
		char.InBarrage:Destroy()
	end
	if char.HumanoidRootPart:FindFirstChild("BarrageLight") then
		char.HumanoidRootPart.BarrageLight:Destroy()
	end
	if char.HumanoidRootPart:FindFirstChild("BarrageAttachment") then
		char.HumanoidRootPart.BarrageAttachment:Destroy()
	end

	--[[
		char["LeftHand"].Transparency = 0
	char["LeftLowerArm"].Transparency = 0
	char["LeftUpperArm"].Transparency = 0
	char["RightHand"].Transparency = 0
	char["RightLowerArm"].Transparency = 0
	char["RightUpperArm"].Transparency = 0
	]]
end

return BarrageVfx
