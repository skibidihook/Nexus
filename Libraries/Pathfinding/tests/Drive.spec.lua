local Pathfinding = require("../Pathfinding")
local T = require("./Framework")

local World = Pathfinding.Internal.World
local CarPlanner = Pathfinding.Internal.CarPlanner
local Controller = Pathfinding.Internal.Controller
local Road = Pathfinding.Surface.Road

local Taxi = Pathfinding.Agent.Car({ Width = 8.2, Length = 19.3, Height = 7.8, TurnRadius = 14, MaxSpeed = 48, ReverseSpeed = 25 })

local function Simulate(Path, Start, Options)
	Options = Options or {}
	local Drive = Controller.new(Path, Taxi, Options)
	local X, Z, Heading, Speed = Start.X, Start.Z, Start.Heading, 0
	local Dt = 1 / 60
	local Time = 0
	local WorstDeviation = 0
	local Lag = Options.Lag or 0
	local Queue = {}
	while Time < (Options.Limit or 60) do
		local Steer, Throttle, Status, Deviation = Drive:Update(X, Z, Heading, Speed)
		if Status == "Arrived" then return true, Time, WorstDeviation, X, Z, Heading end
		if Status == "Deviated" then return false, Time, Deviation, X, Z, Heading end
		if Deviation and Deviation > WorstDeviation then WorstDeviation = Deviation end
		Queue[#Queue + 1] = { Steer, Throttle }
		local Applied = Queue[1]
		if #Queue > Lag then table.remove(Queue, 1) end
		Steer, Throttle = Applied[1], Applied[2]
		local Target = Throttle >= 0 and Throttle * Taxi.MaxSpeed or Throttle * Taxi.ReverseSpeed
		if Target * Speed < 0 or math.abs(Target) < math.abs(Speed) then
			local Change = Taxi.Decel * Dt
			Speed = Speed > Target and math.max(Target, Speed - Change) or math.min(Target, Speed + Change)
		else
			local Change = Taxi.Accel * Dt
			Speed = Speed < Target and math.min(Target, Speed + Change) or math.max(Target, Speed - Change)
		end
		Heading += Speed * Steer / Taxi.TurnRadius * Dt
		X += math.cos(Heading) * Speed * Dt
		Z += math.sin(Heading) * Speed * Dt
		Time += Dt
	end
	return false, Time, WorstDeviation, X, Z, Heading
end

local Cab = Pathfinding.Agent.BloxburgTaxi()

local function SimulateBloxburg(Path, Start, Options)
	Options = Options or {}
	local Drive = Controller.new(Path, Cab, Options)
	local X, Z, Heading = Start.X, Start.Z, Start.Heading
	local Commanded, Velocity, Yaw = 0, 0, 0
	local Dt = 1 / 60
	local Time = 0
	local WorstDeviation = 0
	while Time < (Options.Limit or 60) do
		local Steer, Throttle, Status, Deviation = Drive:Update(X, Z, Heading, Velocity)
		if Status == "Arrived" then return true, Time, WorstDeviation, X, Z, Heading end
		if Status == "Deviated" then return false, Time, Deviation, X, Z, Heading end
		if Deviation and Deviation > WorstDeviation then WorstDeviation = Deviation end
		local Target = Throttle >= 0 and Throttle * Cab.MaxSpeed or Throttle * Cab.ReverseSpeed
		local Rate = math.abs(Throttle) > 0.02 and 1 or 0.6
		Commanded += (Target - Commanded) * Rate * Dt * 1.6
		Velocity += (Commanded - Velocity) * 10 * Dt
		local Sign = Commanded < 0 and -1 or 1
		local WantedYaw = Steer * Cab.YawRate(math.abs(Velocity)) * Sign
		Yaw += (WantedYaw - Yaw) * 8 * Dt
		Heading += Yaw * Dt
		X += math.cos(Heading) * Velocity * Dt
		Z += math.sin(Heading) * Velocity * Dt
		Time += Dt
	end
	return false, Time, WorstDeviation, X, Z, Heading
end

local function Scene()
	local Source = Pathfinding.ShapeSource.new()
	Source:Box(0, -0.5, 0, 900, 1, 900, Road)
	return Source
end

local function Plan(Source, Start, Goal)
	local Map = World.new(Source, {})
	local Path = CarPlanner.Plan(Map, Taxi, Start, Goal)
	T.True(Path.Complete, "plan complete")
	Controller.Profile(Path, Taxi)
	return Path
end

T.Case("follows a long curve at speed", function()
	local Start = { X = 0, Y = 0, Z = 0, Heading = 0 }
	local Path = Plan(Scene(), Start, { X = 150, Y = 0, Z = 60, Heading = math.pi / 2 })
	local Ok, Time, Worst, X, Z = Simulate(Path, Start)
	print(string.format("    curve: arrived=%s in %.1f s, worst deviation %.2f, length %.0f, end (%.1f, %.1f)", tostring(Ok), Time, Worst, Path.Length, X, Z))
	T.True(Ok, "arrived")
	T.True(Worst < 2, "tracks closely")
	T.True(Time < Path.Length / 20 + 4, "keeps a good pace")
end)

T.Case("executes a multi point u-turn", function()
	local Source = Scene()
	Source:Box(0, 5, 15, 300, 10, 2)
	Source:Box(0, 5, -15, 300, 10, 2)
	local Start = { X = 0, Y = 0, Z = 0, Heading = 0 }
	local Path = Plan(Source, Start, { X = -10, Y = 0, Z = 0, Heading = math.pi })
	local Ok, Time, Worst, X, Z, Heading = Simulate(Path, Start)
	print(string.format("    u-turn: arrived=%s in %.1f s, worst deviation %.2f, end (%.1f, %.1f) heading %.0f", tostring(Ok), Time, Worst, X, Z, math.deg(Heading) % 360))
	T.True(Ok, "arrived")
	T.True(Worst < 2, "tracks closely")
	T.True(math.abs(Z) < 8, "stays inside the road")
end)

T.Case("backs out of a slot and drives off", function()
	local Source = Scene()
	Source:Box(13, 4, 0, 1, 8, 40)
	Source:Box(0, 3, 11, 19.3, 6, 8.2)
	Source:Box(0, 3, -11, 19.3, 6, 8.2)
	local Start = { X = 0, Y = 0, Z = 0, Heading = 0 }
	local Path = Plan(Source, Start, { X = -40, Y = 0, Z = 45, Heading = math.pi / 2 })
	local Ok, Time, Worst = Simulate(Path, Start)
	print(string.format("    slot: arrived=%s in %.1f s, worst deviation %.2f", tostring(Ok), Time, Worst))
	T.True(Ok, "arrived")
	T.True(Worst < 2, "tracks closely")
end)

T.Case("survives input lag of three frames", function()
	local Start = { X = 0, Y = 0, Z = 0, Heading = 0 }
	local Path = Plan(Scene(), Start, { X = 120, Y = 0, Z = -50, Heading = -math.pi / 2 })
	local Ok, Time, Worst = Simulate(Path, Start, { Lag = 3 })
	print(string.format("    lag: arrived=%s in %.1f s, worst deviation %.2f", tostring(Ok), Time, Worst))
	T.True(Ok, "arrived")
	T.True(Worst < 3, "still tracks")
end)

local function PlanCab(Source, Start, Goal)
	local Map = World.new(Source, {})
	local Path = CarPlanner.Plan(Map, Cab, Start, Goal)
	T.True(Path.Complete, "plan complete")
	Controller.Profile(Path, Cab)
	return Path
end

T.Case("bloxburg cab model: radius comes from the yaw curve", function()
	print(string.format("    cab min radius %.2f, speed for r=10: %d, for r=20: %d, for r=60: %d", Cab.TurnRadius, Cab.SpeedLimit(1 / 10), Cab.SpeedLimit(1 / 20), Cab.SpeedLimit(1 / 60)))
	T.True(Cab.TurnRadius > 6.5 and Cab.TurnRadius < 8, "about 7 studs")
	T.True(Cab.SpeedLimit(1 / 60) >= 40, "gentle curves allow high speed")
end)

T.Case("bloxburg cab follows a long curve", function()
	local Start = { X = 0, Y = 0, Z = 0, Heading = 0 }
	local Path = PlanCab(Scene(), Start, { X = 150, Y = 0, Z = 60, Heading = math.pi / 2 })
	local Ok, Time, Worst = SimulateBloxburg(Path, Start)
	print(string.format("    cab curve: arrived=%s in %.1f s, worst deviation %.2f, length %.0f", tostring(Ok), Time, Worst, Path.Length))
	T.True(Ok, "arrived")
	T.True(Worst < 2.5, "tracks closely")
end)

T.Case("bloxburg cab u-turns on a narrow road", function()
	local Source = Scene()
	Source:Box(0, 5, 15, 300, 10, 2)
	Source:Box(0, 5, -15, 300, 10, 2)
	local Start = { X = 0, Y = 0, Z = 0, Heading = 0 }
	local Path = PlanCab(Source, Start, { X = -10, Y = 0, Z = 0, Heading = math.pi })
	local Ok, Time, Worst, X, Z = SimulateBloxburg(Path, Start)
	print(string.format("    cab u-turn: arrived=%s in %.1f s, worst deviation %.2f, end (%.1f, %.1f)", tostring(Ok), Time, Worst, X, Z))
	T.True(Ok, "arrived")
	T.True(Worst < 2.5, "tracks closely")
end)

T.Case("bloxburg cab backs out of a slot", function()
	local Source = Scene()
	Source:Box(13, 4, 0, 1, 8, 40)
	Source:Box(0, 3, 11, 19.3, 6, 8.2)
	Source:Box(0, 3, -11, 19.3, 6, 8.2)
	local Start = { X = 0, Y = 0, Z = 0, Heading = 0 }
	local Path = PlanCab(Source, Start, { X = -40, Y = 0, Z = 45, Heading = math.pi / 2 })
	local Ok, Time, Worst = SimulateBloxburg(Path, Start)
	print(string.format("    cab slot: arrived=%s in %.1f s, worst deviation %.2f", tostring(Ok), Time, Worst))
	T.True(Ok, "arrived")
	T.True(Worst < 2.5, "tracks closely")
end)

T.Finish("Drive")
