-- ServerScriptService/GuidedProjectileManager.lua
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeamsModule = require(game.ServerScriptService.BasicCombat.Managers.TeamsModule)
local RaycastModule = require(game.ServerScriptService.BasicCombat.RaycastModule)

-- ✅ Folder setup
local ProjectileFolder = workspace:FindFirstChild("GuidedProjectiles")
if not ProjectileFolder then
	ProjectileFolder = Instance.new("Folder")
	ProjectileFolder.Name = "GuidedProjectiles"
	ProjectileFolder.Parent = workspace
end

local ActiveProjectiles = {}

-- Helper to tag humanoid kills
local function tagHumanoid(humanoid, player)
	local tag = humanoid:FindFirstChild("creator")
	if tag then
		tag:Destroy()
	end

	local newTag = Instance.new("ObjectValue")
	newTag.Name = "creator"
	newTag.Value = player
	newTag.Parent = humanoid
	game.Debris:AddItem(newTag, 2)
end

-- ✅ Register projectile
local function registerProjectile(entry)
	table.insert(ActiveProjectiles, entry)
end

-- === Guided Movement Update ===
RunService.Heartbeat:Connect(function(dt)
	for i = #ActiveProjectiles, 1, -1 do
		local ok, err = pcall(function()
			local p = ActiveProjectiles[i]
			if not (p.hitbox and p.hitbox.Parent) then
				table.remove(ActiveProjectiles, i)
				return
			end

			-- Lifetime
			if tick() - p.createdAt > p.duration then
				p.hitbox:Destroy()
				table.remove(ActiveProjectiles, i)
				return
			end

			-- === Update Direction ===
			local targetPoint = RaycastModule.ReturnFacingPoint(p.character, p.maxDistance or 200)
			if not targetPoint then
				return
			end

			local currentPos = p.hitbox.Position
			local direction = (targetPoint - currentPos).Unit
			p.velocity = direction * (p.speed or 100)

			p.hitbox.CFrame = CFrame.new(currentPos + p.velocity * dt, currentPos + direction)

			-- === Optional Surface Detection ===
			if not p.destroyed and p.DetectSurface then
				local hitDetected, hitResult, distance = RaycastModule.CheckForNearbySurface(p.hitbox, 0.3)
				if hitDetected then
					p.destroyed = true -- ✅ Prevent double-trigger

					print(string.format("[GuidedProjectileManager] %s hit %s", p.hitbox.Name, hitResult.Instance.Name))

					-- When detecting surface hit
					local horizontalDirection = Vector3.new(p.velocity.X, 0, p.velocity.Z)
					if horizontalDirection.Magnitude > 0 then
						horizontalDirection = horizontalDirection.Unit
					else
						horizontalDirection = Vector3.new(0, 0, -1)
					end

					-- ✅ Call callback only once
					if p.OnSurfaceHit then
						task.spawn(function()
							p.OnSurfaceHit(p.hitbox, hitResult, horizontalDirection)
						end)
					end

					-- ✅ Deferred cleanup (safer than destroying inline)
					task.defer(function()
						if p.hitbox and p.hitbox.Parent then
							p.hitbox:Destroy()
						end
						table.remove(ActiveProjectiles, i)
					end)

					return
				end
			end

			-- === Collision Detection ===
			local parts = workspace:GetPartBoundsInBox(p.hitbox.CFrame, p.hitbox.Size, p.paramsFilter)
			for _, other in ipairs(parts) do
				if other.Name == "Hurtbox" then
					local targetChar = other.Parent
					if targetChar and targetChar ~= p.character then
						local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
						if not humanoid then
							local owner = targetChar.Parent
							if owner and owner:IsA("Model") then
								humanoid = owner:FindFirstChildOfClass("Humanoid")
								targetChar = owner
							end
						end

						if humanoid and humanoid.Parent and not p.hitPlayers[targetChar] then
							if TeamsModule.AreTeammates(targetChar, p.character) then
								return
							end

							p.hitPlayers[targetChar] = true

							local player = p.owner
							if player then
								tagHumanoid(humanoid, player)
							end

							local damage = p.damageFunc and p.damageFunc(targetChar) or p.damage
							humanoid:TakeDamage(damage)

							if p.onHit then
								p.onHit(targetChar, damage)
							end

							if p.CanBlock == false or not p.getIsBlocking(targetChar).Value then
								p.applyStun(targetChar, p.stunDuration)
							end

							p.playSound(targetChar, damage)
						end
					end
				end
			end
		end)

		if not ok then
			warn("GuidedProjectileManager error:", err)
			if ActiveProjectiles[i] and ActiveProjectiles[i].hitbox then
				pcall(function()
					ActiveProjectiles[i].hitbox:Destroy()
				end)
			end
			table.remove(ActiveProjectiles, i)
		end
	end
end)

-- === Public API ===
return {
	Register = registerProjectile,
}
