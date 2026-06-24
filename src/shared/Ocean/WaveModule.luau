local WaveModule = {}

WaveModule.OCEAN_HEIGHT = 47

function WaveModule:GetHeight(x, z)
	return self.OCEAN_HEIGHT
end

function WaveModule:IsUnderwater(position)
	local waterHeight = self:GetHeight(position.X, position.Z)

	return position.Y <= waterHeight
end

return WaveModule
