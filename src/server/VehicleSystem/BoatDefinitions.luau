local BoatDefinitions = {}

-- Dealer: matches the NPCName StringValue on the boat-selling NPC model.
-- ModelName: name of the model under ReplicatedStorage.Vehicles.

BoatDefinitions.WoodenBoat = {
	Name = "Wooden Boat",
	Description = "A sturdy vessel for any sailor. Gets the job done.",
	Dealer = "BoatDealer",
	Price = 0,
	ModelName = "WoodenBoat",
	MaxSpeed = 60,
	Acceleration = 50,
	Deceleration = 30,
	TurnSpeed = math.rad(90),
	BoatLength = 30.5,
	BoatWidth = 12,
}

BoatDefinitions.SpeedBoat = {
	Name = "Speed Boat",
	Description = "Built for speed. Cuts through waves like a knife.",
	Dealer = "BoatDealer",
	Price = 5000,
	ModelName = "SpeedBoat",
	MaxSpeed = 120,
	Acceleration = 80,
	Deceleration = 50,
	TurnSpeed = math.rad(120),
	BoatLength = 25,
	BoatWidth = 8,
}

return BoatDefinitions
