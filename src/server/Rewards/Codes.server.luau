local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)
local Players = game:GetService("Players")

-- RemoteEvent for code submission
local codeEvent = Instance.new("RemoteEvent")
codeEvent.Name = "CodeSubmitted"
codeEvent.Parent = ReplicatedStorage

-- List of valid stands (your stand names)
local VALID_STAND_CODES = {
	["StarPurple"] = true,
	["HierophantGrand"] = true,
	["CrazedDiamond"] = true,
	["KingCarmine"] = true,
	["GoldExperiment"] = true,
	["KaiserQueen"] = true,
	["NuclearRain"] = true,
	["ThatHand"] = true,
	["HeavyDoor"] = true,
	["WhiteSake"] = true,
	["TuskAct4"] = true,
	["MagiciansRed"] = true,
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

	local heroValue = HeroManager.GetField(player, "Hero")
	if not heroValue then
		return
	end
	local specialtyValue = HeroManager.GetField(player, "Specialty")
	if not specialtyValue then
		return
	end
	local raceValue = HeroManager.GetField(player, "Race")
	if not raceValue then
		return
	end

	-- Validate the code
	if VALID_STAND_CODES[typedCode] then
		HeroManager.SetField(player, "Hero", typedCode)
		print(player.Name .. " successfully redeemed stand code:", typedCode)

		codeEvent:FireClient(player, true, typedCode) -- success reply
		return
	else
		codeEvent:FireClient(player, false) -- failure reply
	end

	if VALID_SPECIALTY_CODES[typedCode] then
		HeroManager.SetField(player, "Specialty", typedCode)
		if typedCode == "Hamon" then
			HeroManager.SetField(player, "Race", "Human")
		end
		if typedCode == "Vampirism" then
			HeroManager.SetField(player, "Race", "Vampire")
		end
		print(player.Name .. " successfully redeemed specialty code:", typedCode)

		codeEvent:FireClient(player, true, typedCode) -- success reply
	else
		codeEvent:FireClient(player, false) -- failure reply
	end
end)
