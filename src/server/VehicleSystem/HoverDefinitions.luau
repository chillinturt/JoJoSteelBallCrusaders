local HoverDefinitions = {}

-- Dealer: matches the NPCName StringValue on the hover-vehicle-selling NPC model.
-- ModelName: name of the model under ReplicatedStorage.Vehicles.
-- MinHoverHeight/MaxHoverHeight: clamp (studs) for how far above the ground/water
-- surface the vehicle can hover. Ascend (E) and Descend (Q) move within this range.

HoverDefinitions.HoverBike = {
	Name = "Hover Bike",
	Description = "Skims above the ground and waves alike. Hold E to rise, Q to drop.",
	Dealer = "HoverDealer",
	Price = 8000,
	ModelName = "HoverBike",
	MaxSpeed = 90,
	Acceleration = 70,
	Deceleration = 45,
	TurnSpeed = math.rad(150),
	MinHoverHeight = 3,
	MaxHoverHeight = 40,
	VerticalSpeed = 20,
	HoverLength = 8,
}

return HoverDefinitions
