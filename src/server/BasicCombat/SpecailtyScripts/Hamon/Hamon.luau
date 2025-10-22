-- ServerScriptService/HamonModule.lua
local HamonModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundUtils = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

-- CONFIGURATION
local MAX_HAMON = 100
local CHARGE_RATE = 15 -- units per second
local DRAIN_RATE = 5 -- units per second
local UPDATE_INTERVAL = 0.1 -- seconds

-- Internal tracking
local chargingFlags = {} -- [character] = true/false
local activeHamonValues = {} -- [character] = NumberValue

-- Utility: get or create HamonMeter NumberValue
local function getHamonValue(character)
	if not character then
		return
	end
	local val = character:FindFirstChild("HamonMeter")
	if not val then
		val = Instance.new("NumberValue")
		val.Name = "HamonMeter"
		val.Value = 0
		val.Parent = character
	end
	return val
end

-- Start or stop charging
function HamonModule.StartCharge(character)
	print("Hamon charge in module")
	if not character or not character.Parent then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	-- Prevent re-entry
	if chargingFlags[character] then
		-- Toggle off (stop charging)
		chargingFlags[character] = nil
		return
	end

	chargingFlags[character] = true

	local hamonValue = getHamonValue(character)
	activeHamonValues[character] = hamonValue

	-- Start charge loop
	task.spawn(function()
		while character.Parent and chargingFlags[character] do
			local dt = UPDATE_INTERVAL
			hamonValue.Value = math.clamp(hamonValue.Value + CHARGE_RATE * dt, 0, MAX_HAMON)
			task.wait(UPDATE_INTERVAL)
		end
	end)

	SoundUtils.PlaySound({
		Root = hrp,
		soundName = "ChargeHamon",
		soundID = "18421707745",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

function HamonModule.StopCharge(character)
	-- Clear barrage flag
	chargingFlags[character] = nil
	print("Charging stopped in module")
end

-- Constant drain when not charging
RunService.Heartbeat:Connect(function(dt)
	for char, hamonVal in pairs(activeHamonValues) do
		if char and char.Parent and not chargingFlags[char] then
			hamonVal.Value = math.clamp(hamonVal.Value - DRAIN_RATE * dt, 0, MAX_HAMON)
		end
	end
end)

-- Cleanup when character despawns
Players.PlayerRemoving:Connect(function(player)
	local char = player.Character
	if char then
		chargingFlags[char] = nil
		activeHamonValues[char] = nil
	end
end)

return HamonModule
