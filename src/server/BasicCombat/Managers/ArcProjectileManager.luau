-- ServerScriptService/ArcProjectileManager
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local TeamsModule =
	require(game.ServerScriptService:WaitForChild("BasicCombat"):WaitForChild("Managers"):WaitForChild("TeamsModule"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))
local DamageNumberService = require(ServerScriptService.Utilities:WaitForChild("DamageNumberService"))

-- ✅ Folder setup
local ProjectileFolder = workspace:FindFirstChild("ArcProjectiles")
if not ProjectileFolder then
	ProjectileFolder = Instance.new("Folder")
	ProjectileFolder.Name = "ArcProjectiles"
	ProjectileFolder.Parent = workspace
end

local ActiveProjectiles = {}

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

local function registerProjectile(entry)
	table.insert(ActiveProjectiles, entry)
end

-- === Update Loop ===
RunService.Heartbeat:Connect(function(dt)
	for i = #ActiveProjectiles, 1, -1 do
		local ok, err = pcall(function()
			local p = ActiveProjectiles[i]
			if not (p.hitbox and p.hitbox.Parent) then
				table.remove(ActiveProjectiles, i)
				return
			end

			-- Lifetime check
			if tick() - p.createdAt > p.duration then
				p.hitbox:Destroy()
				table.remove(ActiveProjectiles, i)
				return
			end

			-- === Update motion ===
			p.velocity = p.velocity + (p.gravity or Vector3.new(0, -workspace.Gravity, 0)) * dt
			p.hitbox.CFrame = p.hitbox.CFrame + p.velocity * dt

			-- === Collision Detection with Hurtboxes ===
			local parts = workspace:GetPartBoundsInBox(p.hitbox.CFrame, p.hitbox.Size, p.paramsFilter)
			for _, other in ipairs(parts) do
				if other and other.Name == "Hurtbox" then
					local targetChar = other.Parent
					if targetChar and targetChar.Parent and targetChar ~= p.character then
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

							DamageNumberService.ShowDamage(targetChar, damage)

							-- Call the OnHit callback if provided
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

			-- === Optional Surface Detection ===
			if not p.destroyed and p.DetectSurface then
				local hitDetected, hitResult, distance = RaycastModule.CheckForNearbySurface(p.hitbox, 1)
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
		end)

		if not ok then
			warn("ArcProjectileManager error:", err)
			if ActiveProjectiles[i] and ActiveProjectiles[i].hitbox then
				pcall(function()
					ActiveProjectiles[i].hitbox:Destroy()
				end)
			end
			table.remove(ActiveProjectiles, i)
		end
	end
end)

return {
	Register = registerProjectile,
}
