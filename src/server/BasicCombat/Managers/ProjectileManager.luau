-- ServerScriptService/ProjectileManager
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local TeamsModule =
	require(game.ServerScriptService:WaitForChild("BasicCombat"):WaitForChild("Managers"):WaitForChild("TeamsModule"))

-- ✅ Corrected ProjectileFolder setup
local ProjectileFolder = workspace:FindFirstChild("Projectiles")
if not ProjectileFolder then
	ProjectileFolder = Instance.new("Folder")
	ProjectileFolder.Name = "Projectiles"
	ProjectileFolder.Parent = workspace
end

local ActiveProjectiles = {} -- list of { hitbox = Part, direction = Vector3, speed = number, owner = Instance or id, createdAt, duration, params }

local function registerProjectile(entry)
	table.insert(ActiveProjectiles, entry)
end

-- central heartbeat
RunService.Heartbeat:Connect(function(dt)
	-- iterate backwards to allow removal
	for i = #ActiveProjectiles, 1, -1 do
		local ok, err = pcall(function()
			local p = ActiveProjectiles[i]
			if not (p.hitbox and p.hitbox.Parent) then
				table.remove(ActiveProjectiles, i)
				return
			end

			-- time check
			if tick() - p.createdAt > p.duration then
				p.hitbox:Destroy()
				table.remove(ActiveProjectiles, i)
				return
			end

			-- move
			p.hitbox.CFrame = p.hitbox.CFrame + p.direction * p.speed * dt

			-- overlap check (pcall)
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

						-- call the original hit handling (safely)
						if not p.hitPlayers[targetChar] then
							p.hitPlayers[targetChar] = true

							local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
							if not humanoid then
								local owner = targetChar.Parent
								if owner and owner:IsA("Model") then
									humanoid = owner:FindFirstChildOfClass("Humanoid")
									targetChar = owner
								end
							end

							if TeamsModule.AreTeammates(targetChar, p.character) then
								print("Both are on the same team. Not dealing damage")
								return
							end

							if humanoid and humanoid.Parent then
								-- damage & stun
								local newDamage = p.damageFunc and p.damageFunc(targetChar) or p.damage
								humanoid:TakeDamage(newDamage)

								if not p.getIsBlocking(targetChar).Value then
									p.applyStun(targetChar, p.stunDuration)
								end

								-- sound (non-blocking)
								p.playSound(targetChar, newDamage)
							end
						end
					end
				end
			end
		end)
		if not ok then
			warn("ProjectileManager error:", err)
			-- remove faulty projectile to avoid repeated errors
			if ActiveProjectiles[i] and ActiveProjectiles[i].hitbox then
				pcall(function()
					ActiveProjectiles[i].hitbox:Destroy()
				end)
			end
			table.remove(ActiveProjectiles, i)
		end
	end
end)

-- Expose API
return {
	Register = registerProjectile,
}
