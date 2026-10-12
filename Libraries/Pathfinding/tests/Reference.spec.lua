local Pathfinding = require("../Pathfinding")
local T = require("./Framework")

local Reference = Pathfinding.Internal.Reference
local Controller = Pathfinding.Internal.Controller
local World = Pathfinding.Internal.World
local CarPlanner = Pathfinding.Internal.CarPlanner
local Cab = Pathfinding.Agent.BloxburgTaxi()

local function P(X, Z)
	return { X = X, Y = 0.5, Z = Z }
end

local function Wrap(Angle)
	return (Angle + math.pi) % (2 * math.pi) - math.pi
end

T.Case("corner becomes a smooth arc with the requested radius", function()
	local Path = Reference.Build({ P(0, 0), P(100, 0), P(100, 100) }, { CornerRadius = 18 })
	local MaxTurn, MaxCurvature = 0, 0
	for Index = 2, #Path.X do
		local Turn = math.abs(Wrap(Path.H[Index] - Path.H[Index - 1]))
		if Turn > MaxTurn then MaxTurn = Turn end
		if math.abs(Path.K[Index]) > MaxCurvature then MaxCurvature = math.abs(Path.K[Index]) end
		local Gap = math.sqrt((Path.X[Index] - Path.X[Index - 1]) ^ 2 + (Path.Z[Index] - Path.Z[Index - 1]) ^ 2)
		T.True(Gap < 1.2, `spacing {Gap} at {Index}`)
	end
	T.True(MaxTurn < 0.06, `no heading jumps, max {MaxTurn}`)
	T.Near(MaxCurvature, 1 / 18, 1e-6, "arc curvature")
	T.Near(Path.X[#Path.X], 100, 1e-6, "ends at the last point x")
	T.Near(Path.Z[#Path.Z], 100, 1e-6, "ends at the last point z")
end)

T.Case("lane offset keeps a constant distance to the right", function()
	local Base = Reference.Build({ P(0, 0), P(200, 0) }, {})
	local Lane = Reference.Build({ P(0, 0), P(200, 0) }, { LaneOffset = 9 })
	T.Near(Lane.Z[10] - Base.Z[10], 9, 1e-6, "offset to +z which is the right side when heading +x")
end)

T.Case("short segments shrink the fillet instead of overshooting", function()
	local Path = Reference.Build({ P(0, 0), P(10, 0), P(10, 10), P(20, 10) }, { CornerRadius = 18 })
	for Index = 1, #Path.X do
		T.True(Path.X[Index] >= -0.01 and Path.X[Index] <= 20.01 and Path.Z[Index] >= -0.01 and Path.Z[Index] <= 10.01, "stays inside the polyline hull")
	end
end)

local function Follow(Path)
	Path.EndSpeed = 0
	Controller.Profile(Path, Cab)
	local Drive = Controller.new(Path, Cab, { Arrive = 3 })
	local X, Z, Heading = Path.X[1], Path.Z[1], Path.H[1]
	local Commanded, Velocity, Yaw = 0, 0, 0
	local Dt, Time = 1 / 60, 0
	local Worst, Flips, LastSign, Travel = 0, 0, 0, 0
	while Time < 120 do
		local Steer, Throttle, Status, Deviation = Drive:Update(X, Z, Heading, Velocity)
		if Status == "Arrived" then break end
		if Status == "Deviated" then return false, Time, Deviation, Flips end
		if Deviation and Deviation > Worst then Worst = Deviation end
		if math.abs(Steer) > 0.15 then
			local Sign = Steer > 0 and 1 or -1
			if LastSign ~= 0 and Sign ~= LastSign then Flips += 1 end
			LastSign = Sign
		end
		local Target = Throttle >= 0 and Throttle * Cab.MaxSpeed or Throttle * Cab.ReverseSpeed
		Commanded += (Target - Commanded) * (math.abs(Throttle) > 0.02 and 1 or 0.6) * Dt * 1.6
		Velocity += (Commanded - Velocity) * 10 * Dt
		Yaw += (Steer * Cab.YawRate(math.abs(Velocity)) * (Commanded < 0 and -1 or 1) - Yaw) * 8 * Dt
		Heading += Yaw * Dt
		X += math.cos(Heading) * Velocity * Dt
		Z += math.sin(Heading) * Velocity * Dt
		Travel += math.abs(Velocity) * Dt
		Time += Dt
	end
	return true, Time, Worst, Flips, Travel
end

T.Case("cab holds a city route centred with no weaving", function()
	local Route = { P(0, 0), P(160, 0), P(160, 140), P(40, 140), P(40, 300), P(260, 300) }
	local Path = Reference.Build(Route, { CornerRadius = 18, MinRadius = Cab.TurnRadius * 1.25 })
	local Ok, Time, Worst, Flips, Travel = Follow(Path)
	print(string.format("    city: arrived=%s in %.1f s, length %.0f, avg %.1f studs/s, worst deviation %.2f, steering flips %d", tostring(Ok), Time, Path.Length, Travel / Time, Worst, Flips))
	T.True(Ok, "arrived")
	T.True(Worst < 1.5, "stays on the line")
	T.True(Flips <= 8, "no weaving")
end)

T.Case("reference validation finds a car parked on the line", function()
	local Source = Pathfinding.ShapeSource.new()
	Source:Box(0, -0.5, 0, 600, 1, 600, Pathfinding.Surface.Road)
	Source:Box(80, 3, 0, 19, 6, 8)
	local Map = World.new(Source, {})
	local Path = Reference.Build({ P(0, 0), P(200, 0) }, {})
	local Blocks = CarPlanner.Validate(Map, Cab, Path, 1, #Path.X)
	T.Equal(#Blocks, 1, "one blocked stretch")
	local From, To = Path.X[Blocks[1][1]], Path.X[Blocks[1][2]]
	T.True(From > 50 and From < 80 and To > 80 and To < 110, `blocked from {From} to {To}`)
end)

T.Case("validation flags a line that runs over a sidewalk", function()
	local Source = Pathfinding.ShapeSource.new()
	Source:Box(0, -0.5, 0, 600, 1, 600, Pathfinding.Surface.Road)
	Source:Box(100, 0.25, 0, 30, 0.5, 60, Pathfinding.Surface.Pavement)
	local Map = World.new(Source, {})
	local Path = Reference.Build({ P(0, 0), P(200, 0) }, {})
	local Blocks = CarPlanner.Validate(Map, Cab, Path, 1, #Path.X)
	T.Equal(#Blocks, 1, "sidewalk stretch is rough")
end)

T.Finish("Reference")
