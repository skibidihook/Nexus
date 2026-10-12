local Pathfinding = require("../Pathfinding")
local T = require("./Framework")

local World = Pathfinding.Internal.World
local CarPlanner = Pathfinding.Internal.CarPlanner
local Road = Pathfinding.Surface.Road

local Taxi = Pathfinding.Agent.Car({ Width = 8.2, Length = 19.3, Height = 7.8, TurnRadius = 14 })

local function Scene()
	local Source = Pathfinding.ShapeSource.new()
	Source:Box(0, -0.5, 0, 800, 1, 800, Road)
	return Source
end

local function Clearance(Map, X, Z, Y)
	local Cell, Size = Map.Cell, Map.Size
	local Cx, Cz = math.floor(X / Cell), math.floor(Z / Cell)
	local Tx, Tz = Cx // Size, Cz // Size
	local Tile, Data = Map:Ready(World.Key(Tx, Tz), Taxi.Profile)
	local Column = (Cz - Tz * Size) * Size + (Cx - Tx * Size) + 1
	local First = Tile.First[Column]
	local BestClear, BestGap = -1, math.huge
	for Span = First, First + Tile.Count[Column] - 1 do
		local Gap = math.abs(Tile.Floor[Span] - Y)
		if Gap < BestGap then BestClear, BestGap = Data.Clear[Span], Gap end
	end
	return BestClear
end

local function Validate(Map, Path)
	local Worst = math.huge
	for Index = 1, #Path.X do
		local X, Z, H, Y = Path.X[Index], Path.Z[Index], Path.H[Index], Path.Y[Index]
		local C, S = math.cos(H), math.sin(H)
		if Clearance(Map, X, Z, Y) < Taxi.OuterRadius then
			for _, Circle in next, Taxi.Circles do
				local Along, Across = Circle[1], Circle[2]
				local Value = Clearance(Map, X + Along * C - Across * S, Z + Along * S + Across * C, Y)
				if Value - Taxi.CircleRadius < Worst then Worst = Value - Taxi.CircleRadius end
			end
		end
	end
	return Worst
end

local function Reverses(Path)
	local Count = 0
	for Index = 1, #Path.D do
		if Path.D[Index] < 0 then Count += 1 end
	end
	return Count
end

local function Report(Name, Path)
	print(string.format("    %s: %s, %d expanded, %d points, analytic=%s, %.1f ms, %d reverse points",
		Name, Path.Status, Path.Expanded, #Path.X, tostring(Path.Analytic), Path.Time * 1000, Reverses(Path)))
end

T.Case("open road solves with one analytic curve", function()
	local Map = World.new(Scene(), {})
	local Path = CarPlanner.Plan(Map, Taxi, { X = 0, Y = 0, Z = 0, Heading = 0 }, { X = 90, Y = 0, Z = 12, Heading = 0 })
	Report("open road", Path)
	T.True(Path.Complete, "complete")
	T.True(Path.Analytic, "analytic")
	T.True(Path.Expanded <= 2, "no search needed")
	T.Equal(Reverses(Path), 0, "no reversing")
end)

T.Case("u-turn on a narrow road needs a reverse", function()
	local Source = Scene()
	Source:Box(0, 5, 15, 300, 10, 2)
	Source:Box(0, 5, -15, 300, 10, 2)
	local Map = World.new(Source, {})
	local Path = CarPlanner.Plan(Map, Taxi, { X = 0, Y = 0, Z = 0, Heading = 0 }, { X = -10, Y = 0, Z = 0, Heading = math.pi })
	Report("u-turn", Path)
	T.True(Path.Complete, "complete")
	T.True(Reverses(Path) > 0, "uses reverse")
	local Worst = Validate(Map, Path)
	T.True(Worst >= 0, `stays clear of walls, worst margin {Worst}`)
end)

T.Case("backs out of a boxed slot", function()
	local Source = Scene()
	Source:Box(13, 4, 0, 1, 8, 40)
	Source:Box(0, 3, 11, 19.3, 6, 8.2)
	Source:Box(0, 3, -11, 19.3, 6, 8.2)
	local Map = World.new(Source, {})
	local Path = CarPlanner.Plan(Map, Taxi, { X = 0, Y = 0, Z = 0, Heading = 0 }, { X = -40, Y = 0, Z = 45, Heading = math.pi / 2 })
	Report("boxed slot", Path)
	T.True(Path.Complete, "complete")
	T.Equal(Path.D[2], -1, "starts by reversing")
	local Worst = Validate(Map, Path)
	T.True(Worst >= 0, `stays clear of parked cars, worst margin {Worst}`)
end)

T.Case("stops inside a goal zone", function()
	local Map = World.new(Scene(), {})
	local Region = { X = 70, Z = 30, HalfX = 12, HalfZ = 5, Cos = 1, Sin = 0 }
	local Path = CarPlanner.Plan(Map, Taxi, { X = 0, Y = 0, Z = 0, Heading = 0 }, { X = 70, Y = 0, Z = 30, Heading = 0, Region = Region })
	Report("zone", Path)
	T.True(Path.Complete, "complete")
	local X, Z = Path.X[#Path.X], Path.Z[#Path.Z]
	T.True(math.abs(X - 70) <= 12 and math.abs(Z - 30) <= 5, `ends in zone at {X}, {Z}`)
end)

T.Case("routes around a wall that blocks the direct curve", function()
	local Source = Scene()
	Source:Box(40, 5, 10, 2, 10, 80)
	local Map = World.new(Source, {})
	local Path = CarPlanner.Plan(Map, Taxi, { X = 0, Y = 0, Z = 0, Heading = 0 }, { X = 80, Y = 0, Z = 0, Heading = 0 })
	Report("wall detour", Path)
	T.True(Path.Complete, "complete")
	local Worst = Validate(Map, Path)
	T.True(Worst >= 0, `stays clear of the wall, worst margin {Worst}`)
end)

T.Case("escapes a start pose that is already inside the safety margin", function()
	local Source = Scene()
	Source:Box(10.4, 4, 0, 1, 8, 30)
	local Map = World.new(Source, {})
	local Cab = Pathfinding.Agent.BloxburgTaxi()
	local Path = CarPlanner.Plan(Map, Cab, { X = 0, Y = 0, Z = 0, Heading = 0 }, { X = -40, Y = 0, Z = 30, Heading = math.pi / 2 })
	Report("escape", Path)
	T.True(Path.Complete, "complete")
	T.Equal(Path.D[2], -1, "backs away from the wall first")
end)

T.Finish("Car")
