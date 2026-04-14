--[[ dayLength defines how long, in minutes, a day in your game is.
local dayLength = 8

local cycleTime = dayLength * 60
local minutesInADay = 24 * 60

local lighting = game:GetService("Lighting")

-- ⭐ Recommended defaults
lighting.ExposureCompensation = 0 -- baseline

local startTime = tick() - (lighting:GetMinutesAfterMidnight() / minutesInADay) * cycleTime
local endTime = startTime + cycleTime

local timeRatio = minutesInADay / cycleTime

if dayLength == 0 then
	dayLength = 1
end

repeat
	local currentTime = tick()

	if currentTime > endTime then
		startTime = endTime
		endTime = startTime + cycleTime
	end

	-- Update clock
	local minutes = (currentTime - startTime) * timeRatio
	lighting:SetMinutesAfterMidnight(minutes)

	-- 🌙 NIGHT EXPOSURE LOGIC (Hard jump to 1 at 18:00)
	local clockTime = lighting.ClockTime

	local nightStart = 18
	local nightEnd = 6

	-- Default daytime exposure
	lighting.ExposureCompensation = 0

	if clockTime >= nightStart or clockTime < nightEnd then
		-- Convert night time into 0 → 1 range
		local nightProgress

		if clockTime >= nightStart then
			-- 18 → 24
			nightProgress = (clockTime - nightStart) / (24 - nightStart)
		else
			-- 0 → 6
			nightProgress = (clockTime + (24 - nightStart)) / (24 - nightStart + nightEnd)
		end

		-- Midnight should be brighter than 18:00
		local maxExtraBoost = 0.5 -- increase for brighter midnight

		-- Exposure starts at 1 and scales upward
		lighting.ExposureCompensation = 1 + (nightProgress * maxExtraBoost)
	end

	wait(1 / 15)
until false
]]
