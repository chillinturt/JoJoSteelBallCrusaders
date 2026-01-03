local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)
local InventoryManager = require(game.ServerScriptService.DataSaving:WaitForChild("InventoryManager"))
local PlayerData = require(game.ServerScriptService.DataSaving:WaitForChild("PlayerData"))

local TP_AREAS = {
	["1v1Spawn1"] = game.Workspace.Arena1.Model:WaitForChild("1v1Spawn1"),
	["1v1Spawn2"] = game.Workspace.Arena1.Model:WaitForChild("1v1Spawn2"),
	["Arena1"] = true,
}

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
	["Metallica"] = true,
	["Cream"] = true,
	["StoneFree"] = true,
	-- add more here
}

-- List of valid stands (your stand names)
local VALID_SPECIALTY_CODES = {
	["Vampirism"] = true,
	["Hamon"] = true,
}

local ITEM_CODES = {
	["rokapls"] = "MOD_ONLY",
}

local DAILY_CODES = {
	["dailyarrows"] = {
		Item = "StandArrow",
		Amount = 5,
	},
	["dailyrokas"] = {
		Item = "Rokakaka",
		Amount = 5,
	},
}

local MODERATOR_LIST = {
	[9966064759] = true, -- johngalt14
	[85503513] = true, -- name420
	[38168465] = true, -- lemark23
	[4999829347] = true, -- ying (crazy d)
	[4735500462] = true, -- zeke (zadar)
	[412043782] = true, -- NotAndrew1234
	[7150098622] = true, -- Vyl1t
	--4155032061] = true, -- diego
}

local function IsModerator(player)
	return MODERATOR_LIST[player.UserId] == true
end

local function trim(str)
	return str:match("^%s*(.-)%s*$")
end

local function GetTodayKey()
	return os.date("!%Y-%m-%d") -- UTC day
end

local function GetSecondsUntilReset()
	local now = os.time()
	local utc = os.date("!*t", now)

	utc.hour = 24
	utc.min = 0
	utc.sec = 0

	return os.time(utc) - now
end

local function GetDailyData(player)
	local data = PlayerData.GetData(player)
	if not data then
		return nil
	end

	data.DailyCodes = data.DailyCodes or {
		LastReset = "",
		Redeemed = {},
	}

	-- 🔄 Auto reset on new day
	local today = GetTodayKey()
	if data.DailyCodes.LastReset ~= today then
		data.DailyCodes.LastReset = today
		data.DailyCodes.Redeemed = {}
	end

	return data.DailyCodes
end

local function HasRedeemedDaily(player, code)
	local daily = GetDailyData(player)
	return daily and daily.Redeemed[code] == true
end

local function MarkRedeemedDaily(player, code)
	local daily = GetDailyData(player)
	if daily then
		daily.Redeemed[code] = true
	end
end

local function FormatTime(seconds)
	local hrs = math.floor(seconds / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	return string.format("%02dh %02dm %02ds", hrs, mins, secs)
end

local function GetPlayerByName(name)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower() == name:lower() then
			return plr
		end
	end
	return nil
end

local function TeleportPlayerToPart(player, part)
	if not player.Character then
		return
	end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if hrp and part then
		hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
	end
end

-- When the player enters a code
codeEvent.OnServerEvent:Connect(function(player, typedCode)
	if typeof(typedCode) ~= "string" then
		return
	end

	typedCode = trim(typedCode)

	local args = string.split(typedCode, " ")

	-- 🛑 ADMIN TP COMMAND
	if args[1]:lower() == "tp" then
		if not IsModerator(player) then
			codeEvent:FireClient(player, false, "NoPermission")
			return
		end

		-- tp Arena1 p1 p2
		if args[2] == "Arena1" and #args == 4 then
			local p1 = GetPlayerByName(args[3])
			local p2 = GetPlayerByName(args[4])

			if p1 and p2 then
				TeleportPlayerToPart(p1, TP_AREAS["1v1Spawn1"])
				TeleportPlayerToPart(p2, TP_AREAS["1v1Spawn2"])
				codeEvent:FireClient(player, true, "ArenaTP")
			else
				codeEvent:FireClient(player, false, "InvalidPlayer")
			end
			return
		end

		-- tp player location
		if #args == 3 and TP_AREAS[args[3]] then
			local targetPlayer = GetPlayerByName(args[2])
			if targetPlayer then
				TeleportPlayerToPart(targetPlayer, TP_AREAS[args[3]])
				codeEvent:FireClient(player, true, "TP")
			else
				codeEvent:FireClient(player, false, "InvalidPlayer")
			end
			return
		end

		-- tp player1 player2
		if #args == 3 then
			local p1 = GetPlayerByName(args[2])
			local p2 = GetPlayerByName(args[3])

			if p1 and p2 and p2.Character then
				local hrp = p2.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					TeleportPlayerToPart(p1, hrp)
					codeEvent:FireClient(player, true, "TP")
				end
			else
				codeEvent:FireClient(player, false, "InvalidPlayer")
			end
			return
		end

		codeEvent:FireClient(player, false, "InvalidTPCommand")
		return
	end

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

	-- ✅ DAILY CODES (Once per day, per account)
	if DAILY_CODES[typedCode] then
		if HasRedeemedDaily(player, typedCode) then
			local remaining = GetSecondsUntilReset()
			warn("SERVER remaining seconds:", remaining, typeof(remaining))
			codeEvent:FireClient(player, false, "DailyAlreadyRedeemed", remaining)
			return
		end

		local info = DAILY_CODES[typedCode]
		InventoryManager.AddItem(player, info.Item, info.Amount)
		MarkRedeemedDaily(player, typedCode)

		codeEvent:FireClient(player, true, "DailyRedeemed")
		return
	end

	-- 🔒 BLOCK NON-MODS FIRST
	if (VALID_STAND_CODES[typedCode] or VALID_SPECIALTY_CODES[typedCode]) and not IsModerator(player) then
		codeEvent:FireClient(player, false, "NoPermission")
		return
	end

	-- ✅ ITEM CODES
	if ITEM_CODES[typedCode] then
		if typedCode == "rokapls" and not IsModerator(player) then
			codeEvent:FireClient(player, false, "NoPermission")
			return
		end

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
	codeEvent:FireClient(player, false, "InvalidCode")
end)
