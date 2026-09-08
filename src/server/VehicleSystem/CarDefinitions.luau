local CarDefinitions = {}

-- Dealer: matches the NPCName StringValue on the car-selling NPC model.
-- ModelName: name of the model under ReplicatedStorage.Vehicles.
--
-- Units: MaxSpeed/MaxReverseSpeed/Acceleration/etc. are studs/sec (and studs/sec^2)
-- to match BoatDefinitions/HoverDefinitions -- CarController scales every force by
-- the chassis's AssemblyMass, so these numbers behave the same regardless of how
-- the physical car model is built (see CarController for the F = m*a math).
--
-- MaxSteerAngle: how far the front wheels turn, in radians (visual + grip axis).
-- TurnSpeed: max yaw rate (rad/s) the car can turn at once moving -- reached
-- gradually via YawAccel, and scaled down at high speed by HighSpeedSteerFactor
-- (mirrors Jailbreak's real cars, which get twitchier/harder to aim near top speed).
-- TireGrip: lateral traction, higher = less sliding. DriftGrip: lateral traction
-- applied to the REAR wheels only while the handbrake is held -- lower than
-- TireGrip so the back end steps out for a drift while the front still bites.

CarDefinitions.StarterSedan = {
	Name = "Starter Sedan",
	Description = "Reliable, unglamorous, and free. Gets you off the sidewalk.",
	Dealer = "CarDealer",
	Price = 0,
	ModelName = "StarterSedan",

	MaxSpeed = 85,
	MaxReverseSpeed = 35,
	Acceleration = 34,
	ReverseAcceleration = 24,
	BrakeForce = 60,
	Deceleration = 18,

	MaxSteerAngle = math.rad(32),
	TurnSpeed = math.rad(110),
	SteerSpeed = math.rad(220),
	YawAccel = math.rad(300),
	HighSpeedSteerFactor = 0.35,

	SuspensionLength = 2.4,
	SuspensionStiffness = 550,
	SuspensionDamping = 45,

	TireGrip = 16,
	DriftGrip = 7,
	Downforce = 0.015,

	Wheelbase = 8,
	TrackWidth = 5.5,
}

CarDefinitions.DriftCoupe = {
	Name = "Drift Coupe",
	Description = "Loose in the back on purpose. Built for tight corners and tire smoke.",
	Dealer = "CarDealer",
	Price = 12000,
	ModelName = "DriftCoupe",

	MaxSpeed = 130,
	MaxReverseSpeed = 45,
	Acceleration = 55,
	ReverseAcceleration = 32,
	BrakeForce = 85,
	Deceleration = 22,

	MaxSteerAngle = math.rad(40),
	TurnSpeed = math.rad(170),
	SteerSpeed = math.rad(300),
	YawAccel = math.rad(420),
	HighSpeedSteerFactor = 0.25,

	SuspensionLength = 2.1,
	SuspensionStiffness = 480,
	SuspensionDamping = 34,

	TireGrip = 13,
	DriftGrip = 3.5,
	Downforce = 0.02,

	Wheelbase = 7.5,
	TrackWidth = 5.5,
}

CarDefinitions.Concept = {
	Name = "Concept",
	Description = "A hypercar prototype. Blistering top speed, and the reverse launch hits even harder.",
	Dealer = "CarDealer",
	Price = 65000,
	ModelName = "Concept",

	MaxSpeed = 205,
	MaxReverseSpeed = 95,
	Acceleration = 62,
	-- Reverse launch is deliberately stronger than forward accel -- matches the
	-- real Concept's handling notes (its reverse acceleration/launch outpaces
	-- its forward acceleration).
	ReverseAcceleration = 78,
	BrakeForce = 130,
	Deceleration = 26,

	MaxSteerAngle = math.rad(28),
	TurnSpeed = math.rad(140),
	SteerSpeed = math.rad(260),
	YawAccel = math.rad(360),
	-- Twitchy and prone to "flinging" at high speed, per the wiki -- steering
	-- authority drops off hard as it nears top speed.
	HighSpeedSteerFactor = 0.55,

	SuspensionLength = 1.9,
	SuspensionStiffness = 620,
	SuspensionDamping = 50,

	TireGrip = 15,
	DriftGrip = 5,
	Downforce = 0.03,

	Wheelbase = 9,
	TrackWidth = 6,
}

return CarDefinitions
