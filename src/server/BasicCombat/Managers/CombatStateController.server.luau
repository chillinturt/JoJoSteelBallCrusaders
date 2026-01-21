local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatUtils = require(ServerScriptService.BasicCombat.CombatUtils)
local BlockModule = require(ServerScriptService.BasicCombat.BlockModule)

-- Try to resume blocking if allowed
local function tryResumeBlock(character)
	if character and character.Parent then
		BlockModule.TryStartBlocking(character)
	end
end

-- Global combat event hooks (run ONCE)
CombatUtils.ActionEnded.Event:Connect(function(character)
	tryResumeBlock(character)
end)

CombatUtils.StunEnded.Event:Connect(function(character)
	tryResumeBlock(character)
end)

-- Character setup (no stun hooks needed anymore)
local function setupCharacter(character)
	-- Optional: attempt block on spawn
	task.defer(function()
		tryResumeBlock(character)
	end)
end

-- Player lifecycle
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(setupCharacter)
end)
