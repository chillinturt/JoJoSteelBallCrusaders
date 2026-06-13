local HERO_GROUPS = {
	-- Only define exceptions / shared groups
	TuskAct1 = "Tusk",
	TuskAct2 = "Tusk",
	TuskAct3 = "Tusk",
	TuskAct4 = "Tusk",
}

-- Helper function to resolve group
local function GetHeroGroup(heroName)
	return HERO_GROUPS[heroName] or heroName
end

return {
	Groups = HERO_GROUPS,
	GetHeroGroup = GetHeroGroup,
}
