local StandManager = {}

local possibleStands = {
	"Star Platinum",
	"The World",
	"Crazy Diamond",
	"Golden Experience",
	"Killer Queen",
}

function StandManager.GetRandomStand()
	return possibleStands[math.random(1, #possibleStands)]
end

return StandManager
