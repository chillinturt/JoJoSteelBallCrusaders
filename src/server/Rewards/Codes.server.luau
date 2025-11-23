local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- RemoteEvent for code submission
local codeEvent = Instance.new("RemoteEvent")
codeEvent.Name = "CodeSubmitted"
codeEvent.Parent = ReplicatedStorage

-- List of valid stands (your stand names)
local VALID_STAND_CODES = {
	["Star Purple"] = true,
	["Hierophant Grand"] = true,
	["Crazed Diamond"] = true,
	["King Carmine"] = true,
	["Gold Experiment"] = true,
	["Kaiser Queen"] = true,
	["Nuclear Rain"] = true,
	["That Hand"] = true,
	["Heavy Door"] = true,
	["White Sake"] = true,
	["Tusk Act 4"] = true,
	["Magicians Red"] = true,
	-- add more here
}

-- List of valid stands (your stand names)
local VALID_SPECIALTY_CODES = {
	["Vampirism"] = true,
	["Hamon"] = true,
}

local function trim(str)
	return str:match("^%s*(.-)%s*$")
end

-- When the player enters a code
codeEvent.OnServerEvent:Connect(function(player, typedCode)
	if typeof(typedCode) ~= "string" then
		return
	end

	typedCode = trim(typedCode)

	local powersFolder = player:FindFirstChild("Powers")
	local heroValue = powersFolder:FindFirstChild("Hero")
	if not heroValue then
		return
	end
	local specialtyValue = powersFolder:FindFirstChild("Specialty")
	if not specialtyValue then
		return
	end
	local raceValue = powersFolder:FindFirstChild("Race")
	if not raceValue then
		return
	end

	-- Validate the code
	if VALID_STAND_CODES[typedCode] then
		heroValue.Value = typedCode
		print(player.Name .. " successfully redeemed stand code:", typedCode)

		codeEvent:FireClient(player, true, typedCode) -- success reply
		return
	else
		codeEvent:FireClient(player, false) -- failure reply
	end

	if VALID_SPECIALTY_CODES[typedCode] then
		specialtyValue.Value = typedCode
		if typedCode == "Hamon" then
			raceValue.Value = "Human"
		end
		if typedCode == "Vampirism" then
			raceValue.Value = "Vampire"
		end
		print(player.Name .. " successfully redeemed specialty code:", typedCode)

		codeEvent:FireClient(player, true, typedCode) -- success reply
	else
		codeEvent:FireClient(player, false) -- failure reply
	end
end)
