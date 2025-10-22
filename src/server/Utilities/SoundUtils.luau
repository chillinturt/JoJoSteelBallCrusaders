local SoundUtils = {}

-- sounds
function SoundUtils.PlaySound(params)
	local root = params.Root
	local soundName = params.soundName
	local soundId = params.soundID
	local volume = params.volume or 1
	local playbackSpeed = params.playbackSpeed
	local looped = params.looped
	local range = params.range
	local pitch = params.pitch or 1

	if not root then
		warn("⚠️ No root provided for PlaySound")
		return
	end

	-- Defaults
	volume = volume or 1
	playbackSpeed = playbackSpeed or 1
	looped = looped or false

	-- Check for existing sound
	local sound = root:FindFirstChild(soundName)

	-- If not found, create a new one
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = soundName
		sound.Parent = root
	end
	sound.SoundId = "rbxassetid://" .. soundId
	sound.Volume = volume
	if pitch then
		sound.PlaybackSpeed = playbackSpeed * pitch
	else
		sound.PlaybackSpeed = playbackSpeed
	end

	sound.Looped = looped
	sound.RollOffMaxDistance = range

	-- Play the sound
	sound:Play()
end

function SoundUtils.StopSound(Root: Instance, soundName: string)
	if not Root then
		--warn("⚠️ No root provided for StopSound")
		return
	end

	local sound = Root:FindFirstChild(soundName)
	if sound and sound:IsA("Sound") then
		sound:Stop()
	else
		warn("⚠️ Sound '" .. soundName .. "' not found on root")
	end
end

return SoundUtils
