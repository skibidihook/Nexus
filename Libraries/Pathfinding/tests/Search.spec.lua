local Pathfinding = require("../Pathfinding")
local T = require("./Framework")

local World = Pathfinding.Internal.World
local GridSearch = Pathfinding.Internal.GridSearch
local Walker = Pathfinding.Agent.Walker({ Radius = 1.5, Height = 5 })

local function Ground(Source)
	Source:Box(0, -0.5, 0, 400, 1, 400)
end

local function Point(X, Y, Z)
	return { X = X, Y = Y, Z = Z }
end

local function Find(Source, From, To, Options)
	local Map = World.new(Source, {})
	return GridSearch.Find(Map, Walker, From, To, Options), Map
end

local function Clearance(Map, Result)
	local Lowest = math.huge
	for Index = 1, #Result.Points - 1 do
		local A, B = Result.Points[Index], Result.Points[Index + 1]
		local Steps = math.max(1, math.ceil(vector.magnitude(B - A)))
		for Step = 0, Steps do
			local P = A + (B - A) * (Step / Steps)
			local Key, Span = Map:Locate(P.X, P.Y + 1, P.Z, Walker.Profile)
			if Key then
				local Tile = Map.Tiles[Key]
				local Value = Tile.Profiles[Walker.Profile.Key].Clear[Span]
				if Value < Lowest then Lowest = Value end
			end
		end
	end
	return Lowest
end

T.Case("open field is a straight line", function()
	local Source = Pathfinding.ShapeSource.new()
	Ground(Source)
	local Result = Find(Source, Point(5.5, 0, 5.5), Point(60.5, 0, 50.5))
	T.True(Result.Complete, "complete")
	T.Equal(#Result.Points, 2, "two points")
	T.Near(Result.Points[2].X, 60.5, 1e-6, "ends on goal x")
end)

T.Case("goes through a door in a wall", function()
	local Source = Pathfinding.ShapeSource.new()
	Ground(Source)
	Source:Box(30.5, 5, -20, 1, 10, 60)
	Source:Box(30.5, 5, 30, 1, 10, 30)
	local Result, Map = Find(Source, Point(10.5, 0, 0.5), Point(50.5, 0, 0.5))
	T.True(Result.Complete, "complete")
	local Crossed = false
	for Index = 1, #Result.Points - 1 do
		local A, B = Result.Points[Index], Result.Points[Index + 1]
		if (A.X - 30.5) * (B.X - 30.5) <= 0 then
			local Ratio = (30.5 - A.X) / (B.X - A.X)
			local Z = A.Z + (B.Z - A.Z) * Ratio
			T.True(Z > 10 and Z < 15, `crosses inside the door gap, z={Z}`)
			Crossed = true
		end
	end
	T.True(Crossed, "crossed the wall line")
	T.True(Clearance(Map, Result) >= 1.5 - 1e-6, "keeps the radius from walls")
end)

T.Case("escapes a U shaped trap", function()
	local Source = Pathfinding.ShapeSource.new()
	Ground(Source)
	Source:Box(20.5, 5, 0, 1, 10, 30)
	Source:Box(10, 5, 15.5, 20, 10, 1)
	Source:Box(10, 5, -15.5, 20, 10, 1)
	local Result = Find(Source, Point(10.5, 0, 0.5), Point(40.5, 0, 0.5))
	T.True(Result.Complete, "complete")
	T.True(#Result.Points >= 3, "needs corners")
end)

T.Case("climbs stairs to a platform", function()
	local Source = Pathfinding.ShapeSource.new()
	Ground(Source)
	for Step = 1, 8 do
		Source:Box(10 + Step * 2, Step * 0.5, 0, 2, Step, 10)
	end
	Source:Box(33, 4, 0, 12, 8, 10)
	local Result = Find(Source, Point(2.5, 0, 0.5), Point(36.5, 8, 0.5))
	T.True(Result.Complete, "complete")
	T.Near(Result.Points[#Result.Points].Y, 8, 1e-6, "ends on the platform")
end)

T.Case("unreachable goal returns the closest partial path", function()
	local Source = Pathfinding.ShapeSource.new()
	Ground(Source)
	Source:Box(50.5, 5, 0, 1, 10, 21)
	Source:Box(69.5, 5, 0, 1, 10, 21)
	Source:Box(60, 5, 10.5, 20, 10, 1)
	Source:Box(60, 5, -10.5, 20, 10, 1)
	local Result = Find(Source, Point(10.5, 0, 0.5), Point(60.5, 0, 0.5), { MaxNodes = 40000 })
	T.True(not Result.Complete, "not complete")
	T.True(Result.Distance <= 11, `stops next to the box, distance {Result.Distance}`)
end)

T.Case("goal inside a solid block is relocated next to it", function()
	local Source = Pathfinding.ShapeSource.new()
	Ground(Source)
	Source:Box(40, 2, 0, 6, 4, 6)
	local Result = Find(Source, Point(5.5, 0, 0.5), Point(40, 2, 0))
	T.True(Result.Complete, "complete")
	T.Equal(Result.Status, "Relocated", "status")
	T.True(Result.Relocated and Result.Relocated < 6.5, `relocated distance {Result.Relocated}`)
end)

T.Case("enclosed goal fails fast through the region graph", function()
	local Source = Pathfinding.ShapeSource.new()
	Ground(Source)
	Source:Box(50.5, 5, 0, 1, 10, 21)
	Source:Box(69.5, 5, 0, 1, 10, 21)
	Source:Box(60, 5, 10.5, 20, 10, 1)
	Source:Box(60, 5, -10.5, 20, 10, 1)
	local Result = Find(Source, Point(10.5, 0, 0.5), Point(60.5, 0, 0.5))
	T.Equal(Result.Status, "Unreachable", "status")
	T.True(Result.Expanded < 20000, `expanded {Result.Expanded}`)
	T.True(Result.Distance <= 12, `ends next to the box, distance {Result.Distance}`)
end)

T.Case("island across water is unreachable", function()
	local Source = Pathfinding.ShapeSource.new()
	Source:Box(0, -0.5, 0, 400, 1, 400, Pathfinding.Surface.Water)
	Source:Box(-40, 0, 0, 60, 1, 60)
	Source:Box(60, 0, 0, 20, 1, 20)
	local Result = Find(Source, Point(-40.5, 1, 0.5), Point(60.5, 1, 0.5))
	T.Equal(Result.Status, "Unreachable", "status")
	T.True(Result.Expanded < 20000, `expanded {Result.Expanded}`)
end)

T.Case("crosses many tiles including negative ones", function()
	local Source = Pathfinding.ShapeSource.new()
	Ground(Source)
	Source:Box(0.5, 5, 0, 1, 10, 120)
	local Result = Find(Source, Point(-90.5, 0, -0.5), Point(90.5, 0, 0.5))
	T.True(Result.Complete, "complete")
	T.True(Result.Length > 181, "goes around the wall")
end)

T.Case("random maze performance", function()
	local Source = Pathfinding.ShapeSource.new()
	Ground(Source)
	local Seed = 12345
	local function Random()
		Seed = (Seed * 1103515245 + 12345) % 2147483648
		return Seed / 2147483648
	end
	for _ = 1, 260 do
		local X, Z = Random() * 180 - 90, Random() * 180 - 90
		if math.abs(X + 85) > 6 or math.abs(Z + 85) > 6 then
			Source:Box(X, 3, Z, 2 + Random() * 6, 6, 2 + Random() * 6, 1, Random() * math.pi)
		end
	end
	local Result, Map = Find(Source, Point(-85.5, 0, -85.5), Point(85.5, 0, 85.5))
	print(string.format("    maze: %s, %d expanded, %d nodes -> %d points, %.1f ms total, %d tiles (%.1f ms sampling, %.1f ms profiles)",
		Result.Status, Result.Expanded, Result.Nodes, #Result.Points, Result.Time * 1000, Map.Stats.Sampled, Map.Stats.SampleTime * 1000, Map.Stats.ProfileTime * 1000))
	T.True(Result.Complete or Result.Distance < 20, "reaches or nearly reaches the goal")
end)

T.Finish("Search")
