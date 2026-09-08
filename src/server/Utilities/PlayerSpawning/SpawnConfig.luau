local SpawnConfig = {}

-- Minimum level required to unlock each spawn
SpawnConfig.Spawns = {
	FirstIsland = 1,
	ShantySpawn = 10,
	BeachSpawn = 20,
	MansionSpawn = 35,
}

-- NPC names (NPCName StringValue) that are Innkeepers.
-- Each key must match a key in SpawnConfig.Spawns — the NPC name IS the spawn name.
SpawnConfig.InnkeeperNpcs = {
	FirstIsland = true,
	ShantySpawn = true,
	BeachSpawn = true,
	MansionSpawn = true,
}

return SpawnConfig
