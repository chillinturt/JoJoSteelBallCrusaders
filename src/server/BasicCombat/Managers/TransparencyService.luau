local TransparencyService = {}

-- Cache original visibility so we can restore perfectly
function TransparencyService.SetInvisible(character)
	local cache = {}

	for _, inst in ipairs(character:GetDescendants()) do
		if inst:IsA("BasePart") or inst:IsA("Decal") then
			cache[inst] = {
				Class = "Visual",
				Transparency = inst.Transparency,
			}

			inst.Transparency = 1
		elseif inst:IsA("ParticleEmitter") then
			cache[inst] = {
				Class = "Particle",
				Rate = inst.Rate,
				Enabled = inst.Enabled,
			}

			-- Fully hide particles
			inst.Rate = 0
			inst.Enabled = false
		end
	end

	return cache
end

function TransparencyService.Restore(character, cache)
	if not cache then
		return
	end

	for inst, data in pairs(cache) do
		if inst and inst.Parent then
			if data.Class == "Visual" then
				inst.Transparency = data.Transparency
			elseif data.Class == "Particle" then
				inst.Rate = data.Rate
				inst.Enabled = data.Enabled
			end
		end
	end
end

return TransparencyService
