-- Safe helper
local function safeWaitForChild(parent, childName, timeout)
	local obj = parent:FindFirstChild(childName)
	if obj then
		return obj
	end
	local start = tick()
	while tick() - start < (timeout or 20) do
		obj = parent:FindFirstChild(childName)
		if obj then
			return obj
		end
		task.wait(0.1)
	end
	warn("safeWaitForChild timeout: " .. childName)
	return nil
end

-- LocalScript: StarterPlayerScripts/LocalMusicController
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- events
local MusicEvents = ReplicatedStorage:WaitForChild("MusicEvents")
local MusicSettingsEvent = MusicEvents:WaitForChild("MusicSettingsEvent")
local PlaySoundEvent = MusicEvents:WaitForChild("PlaySoundEvent")

-- ✅ Match your hierarchy
local regionsFolder = workspace:WaitForChild("Audio"):WaitForChild("MusicRegions")

-- ✅ Match your UI hierarchy
local gui = safeWaitForChild(player:WaitForChild("PlayerGui"), "SettingsGUI")
if not gui then
	return
end

local settingsWindow = gui:WaitForChild("SettingsWindow")
local scrollingFrame = settingsWindow:WaitForChild("ScrollingFrame")
local toggleButton = scrollingFrame:WaitForChild("MuteMusicButton")

-- === Config ===
local MUSIC_FADE_TIME = 2
local CHECK_INTERVAL = 0.5
local REGION_RANGE = 100
local DEFAULT_VOLUME = 0.7

-- === State ===
local musicEnabled = true
local currentMusic: Sound? = nil
local currentRegion: BasePart? = nil
local lastCheck = 0
local isSwitching = false
local switchCooldown = 1.5
local lastSwitchTime = 0
local HYSTERESIS_BUFFER = 10 -- must be this much closer before switching regions

-- === Default Ambient Music ===
local DEFAULT_MUSIC_IDS = {
	"rbxassetid://76338872803366", -- Deep In Abyss (Instrumental Version) [qigbBgDapTc]
	--"rbxassetid://98584102044368", -- it's going down now - Asset is not approved for the requester
	"rbxassetid://75680909936973", -- blitz (soul eater)
	--"rbxassetid://88437114656735", --funky dealer - Asset is not approved for the requester
	"rbxassetid://125979185781274", -- the first layer
	"rbxassetid://116561044403837", -- Traitor's requiem instrumental
}

local defaultMusicSound: Sound? = nil
local lastDefaultIndex = nil

-- Optional: cache sounds so they don’t recreate every time
local soundCache = {}

local function playLocalSound(soundId: string, volume: number?, pitch: number?)
	if not soundId or soundId == "" then
		return
	end

	local sound = soundCache[soundId]

	if not sound then
		sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Parent = player:WaitForChild("PlayerGui")
		soundCache[soundId] = sound
	end

	sound.Volume = volume or 1
	sound.PlaybackSpeed = pitch or 1
	sound.TimePosition = 0 -- restart cleanly
	sound:Play()
end

PlaySoundEvent.OnClientEvent:Connect(function(data)
	-- data = { id = "...", volume = 1, pitch = 1 }
	playLocalSound(data.id, data.volume, data.pitch)
end)

-- === Helper Functions ===
local function getPlayerPosition()
	local char = player.Character
	if not char then
		return nil
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position or nil
end

-- ✅ Uses region.Position safely (all are BaseParts)
local function getClosestRegion(pos: Vector3)
	local closest, closestDist = nil, math.huge
	for _, region in ipairs(regionsFolder:GetChildren()) do
		if region:IsA("BasePart") then
			local soundVal = region:FindFirstChild("SoundId")
			if soundVal and soundVal:IsA("StringValue") and soundVal.Value ~= "" then
				local dist = (pos - region.Position).Magnitude
				if dist <= REGION_RANGE and dist < closestDist then
					closest, closestDist = region, dist
				end
			end
		end
	end
	return closest
end

-- ✅ Tween sound volume safely
local function tweenVolume(sound: Sound, targetVolume: number, time: number)
	if not sound or not sound:IsDescendantOf(workspace) then
		return
	end
	local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(sound, tweenInfo, { Volume = targetVolume })
	tween:Play()
	return tween
end

-- === Music Helpers ===
local function stopCurrentMusic(force)
	if not currentMusic then
		return
	end
	local sound = currentMusic
	currentMusic, currentRegion = nil, nil

	if force then
		sound:Destroy()
		return
	end

	local tween = tweenVolume(sound, 0, MUSIC_FADE_TIME)
	if tween then
		tween.Completed:Connect(function()
			if sound then
				sound:Destroy()
			end
		end)
	else
		sound:Destroy()
	end
end

local function stopDefaultMusic(force)
	if not defaultMusicSound then
		return
	end

	local sound = defaultMusicSound
	defaultMusicSound = nil

	if force then
		sound:Destroy()
		return
	end

	local tween = tweenVolume(sound, 0, MUSIC_FADE_TIME)
	if tween then
		tween.Completed:Connect(function()
			if sound then
				sound:Destroy()
			end
		end)
	else
		sound:Destroy()
	end
end

local function playRegionMusic(region)
	if isSwitching then
		return
	end
	if not region or not musicEnabled then
		stopCurrentMusic()
		return
	end
	if region == currentRegion then
		return -- already playing this one
	end

	local now = os.clock()
	if now - lastSwitchTime < switchCooldown then
		return -- cooldown between switches
	end

	isSwitching = true
	lastSwitchTime = now

	local idVal = region:FindFirstChild("SoundId")
	if not idVal or idVal.Value == "" then
		stopCurrentMusic()
		isSwitching = false
		return
	end

	-- Stop current music safely
	stopCurrentMusic(true)

	local s = Instance.new("Sound")
	s.SoundId = idVal.Value
	s.Volume = 0
	s.Looped = true
	s.RollOffMode = Enum.RollOffMode.Linear
	s.Parent = workspace
	s:Play()

	tweenVolume(s, DEFAULT_VOLUME, MUSIC_FADE_TIME)
	currentMusic, currentRegion = s, region

	-- Stop default music when entering a region
	stopDefaultMusic(true)

	task.delay(MUSIC_FADE_TIME, function()
		isSwitching = false
	end)
end

-- === Button Handling ===
local function updateButtonText()
	toggleButton.Text = musicEnabled and "Music: ON" or "Music: OFF"
end

local function connectToggleButton()
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("SettingsGUI")
	local toggleButton =
		gui:WaitForChild("SettingsWindow"):WaitForChild("ScrollingFrame"):WaitForChild("MuteMusicButton")

	local function updateButtonText()
		toggleButton.Text = musicEnabled and "Music: ON" or "Music: OFF"
	end

	updateButtonText()

	toggleButton.MouseButton1Click:Connect(function()
		musicEnabled = not musicEnabled
		updateButtonText()

		-- 🔹 Save preference to server
		MusicSettingsEvent:FireServer(musicEnabled)

		if not musicEnabled then
			stopCurrentMusic()
			stopDefaultMusic(true)
		else
			local pos = getPlayerPosition()
			if pos then
				local nearest = getClosestRegion(pos)
				playRegionMusic(nearest)
			end
		end
	end)
end

local function getRandomDefaultTrack()
	if #DEFAULT_MUSIC_IDS == 0 then
		return nil
	end

	if #DEFAULT_MUSIC_IDS == 1 then
		return DEFAULT_MUSIC_IDS[1], 1
	end

	local index
	repeat
		index = math.random(1, #DEFAULT_MUSIC_IDS)
	until index ~= lastDefaultIndex

	lastDefaultIndex = index
	return DEFAULT_MUSIC_IDS[index], index
end

local function playDefaultMusic()
	if isSwitching or not musicEnabled then
		return
	end

	-- Already playing default music
	if defaultMusicSound then
		return
	end

	local id = getRandomDefaultTrack()
	if not id then
		return
	end

	-- Stop region music
	stopCurrentMusic(true)

	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = 0
	s.Looped = false -- important: we handle chaining manually
	s.RollOffMode = Enum.RollOffMode.Linear
	s.Parent = workspace
	s:Play()

	tweenVolume(s, DEFAULT_VOLUME, MUSIC_FADE_TIME)

	defaultMusicSound = s
	currentRegion = nil

	-- When song ends → play another random one
	s.Ended:Connect(function()
		if defaultMusicSound ~= s then
			return -- safety
		end

		defaultMusicSound = nil
		playDefaultMusic()
	end)
end

-- ⬇️ CLIENT receives saved setting here
MusicSettingsEvent.OnClientEvent:Connect(function(enabled)
	musicEnabled = enabled
	updateButtonText()

	if not musicEnabled then
		stopCurrentMusic()
		stopDefaultMusic(true)
	else
		local pos = getPlayerPosition()
		if pos then
			local nearest = getClosestRegion(pos)
			if nearest then
				playRegionMusic(nearest)
			else
				playDefaultMusic()
			end
		end
	end
end)

-- Initial connection
connectToggleButton()

-- Reconnect when GUI reloads after death
player.PlayerGui.ChildAdded:Connect(function(child)
	if child.Name == "SettingsGUI" then
		task.wait(1) -- Wait for the GUI to finish loading
		connectToggleButton()
	end
end)

updateButtonText()

-- === Main Loop ===
runService.Heartbeat:Connect(function(dt)
	lastCheck += dt
	if lastCheck < CHECK_INTERVAL then
		return
	end
	lastCheck = 0

	if not musicEnabled then
		return
	end

	local pos = getPlayerPosition()
	if not pos then
		return
	end

	local nearest = getClosestRegion(pos)
	if not nearest then
		stopCurrentMusic()
		playDefaultMusic()
		return
	else
		-- entering a region → stop default
		stopDefaultMusic(true)
	end

	-- Add hysteresis: only switch if much closer than current
	if currentRegion and currentRegion ~= nearest then
		local curDist = (pos - currentRegion.Position).Magnitude
		local newDist = (pos - nearest.Position).Magnitude
		if newDist > curDist - HYSTERESIS_BUFFER then
			return -- not enough improvement to switch
		end
	end

	playRegionMusic(nearest)
end)
