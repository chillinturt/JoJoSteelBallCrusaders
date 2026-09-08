local HomeManager = {}

local playerHomes = {} -- [Player] = spawnName | nil

function HomeManager.SetHome(player: Player, spawnName: string?)
	playerHomes[player] = spawnName
end

function HomeManager.GetHome(player: Player): string?
	return playerHomes[player]
end

function HomeManager.ClearHome(player: Player)
	playerHomes[player] = nil
end

return HomeManager
