local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HeroManager = require(game.ServerScriptService.DataSaving:WaitForChild("HeroManager"))

local StandScripts = ReplicatedStorage.Shared:WaitForChild("StandLocalScripts")
local SpecScripts = ReplicatedStorage.Shared:WaitForChild("SpecialtyLocalScripts")

local function giveStandScripts(player, character)
	-- Clear old stand scripts
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("LocalScript") and child:GetAttribute("StandScript") then
			child:Destroy()
		end
	end

	local standName = HeroManager.GetField(player, "Hero")
	if not standName then
		return
	end

	local standFolder = StandScripts:FindFirstChild(standName)
	if not standFolder then
		--print("No stand folder found")
		return
	end

	-- Give all scripts from this stand folder
	for _, script in ipairs(standFolder:GetChildren()) do
		if script:IsA("LocalScript") then
			local clone = script:Clone()
			clone:SetAttribute("StandScript", true) -- mark it
			clone.Parent = character -- or player:WaitForChild("PlayerGui")
		end
	end
end

local function giveSpecScripts(player, character)
	-- Clear old spec scripts
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("LocalScript") and child:GetAttribute("SpecScript") then
			child:Destroy()
		end
	end

	local specName = HeroManager.GetField(player, "Specialty")
	if not specName then
		return
	end

	local specFolder = SpecScripts:FindFirstChild(specName)
	if not specFolder then
		--print("No spec folder found")
		return
	end

	-- Give all scripts from this spec folder
	for _, script in ipairs(specFolder:GetChildren()) do
		if script:IsA("LocalScript") then
			local clone = script:Clone()
			clone:SetAttribute("SpecScript", true) -- mark it
			clone.Parent = character -- or player:WaitForChild("PlayerGui")
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(1) -- wait for character load
		giveStandScripts(player, character)
		giveSpecScripts(player, character)
	end)
end)
