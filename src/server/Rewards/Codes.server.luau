local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ItemUseManager = require(script.Parent.ItemUseManager)
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)
local InventoryManager = require(game.ServerScriptService.DataSaving:WaitForChild("InventoryManager"))

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
	["TheWorld"] = true,
	-- add more here
}

-- List of valid stands (your stand names)
local VALID_SPECIALTY_CODES = {
	["Vampirism"] = true,
	["Hamon"] = true,
}

local ITEM_CODES = {
	["rokapls"] = true,
}

local MODERATOR_LIST = {
	[9966064759] = true, -- johngalt14
	[85503513] = true, -- name420
	[38168465] = true, -- lemark23
	[4999829347] = true, -- ying (crazy d)
	[4735500462] = true, -- zeke (zadar)
	[412043782] = true, -- NotAndrew1234
}

local function IsModerator(player)
	return MODERATOR_LIST[player.UserId] == true
end

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

	-- 🔒 BLOCK NON-MODS FIRST
	if (VALID_STAND_CODES[typedCode] or VALID_SPECIALTY_CODES[typedCode]) and not IsModerator(player) then
		codeEvent:FireClient(player, false, "NoPermission")
		return
	end

	-- ✅ ITEM CODES (Everyone)
	if ITEM_CODES[typedCode] then
		if typedCode == "rokapls" then
			InventoryManager.AddItem(player, "Rokakaka", 5)
			InventoryManager.AddItem(player, "StandArrow", 5)
		end
		codeEvent:FireClient(player, true, typedCode)
		return
	end

	-- ✅ STAND CODES (MOD ONLY)
	if VALID_STAND_CODES[typedCode] then
		HeroManager.SetField(player, "Hero", typedCode)
		print(player.Name .. " redeemed stand:", typedCode)
		codeEvent:FireClient(player, true, typedCode)
		return
	end

	-- ✅ SPECIALTY CODES (MOD ONLY)
	if VALID_SPECIALTY_CODES[typedCode] then
		HeroManager.SetField(player, "Specialty", typedCode)

		if typedCode == "Hamon" then
			HeroManager.SetField(player, "Race", "Human")
		elseif typedCode == "Vampirism" then
			HeroManager.SetField(player, "Race", "Vampire")
		end

		print(player.Name .. " redeemed specialty:", typedCode)
		codeEvent:FireClient(player, true, typedCode)
		return
	end

	-- ❌ Invalid Code
	codeEvent:FireClient(player, false)
end)
