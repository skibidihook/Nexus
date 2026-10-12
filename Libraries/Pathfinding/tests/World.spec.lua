local Pathfinding = require("../Pathfinding")
local T = require("./Framework")

local World = Pathfinding.Internal.World

local function Build()
	local Source = Pathfinding.ShapeSource.new()
	Source:Box(0, -0.5, 0, 200, 1, 200, Pathfinding.Surface.Pavement)
	Source:Box(20.5, 5, 16, 1, 10, 32)
	Source:Box(-16, 10.5, 12, 32, 1, 4)
	return World.new(Source, {}), Source
end

local Walker = Pathfinding.Agent.Walker({ Radius = 1.5, Height = 5 })

local function SpanAt(Map, X, Z)
	local Cell, Size = Map.Cell, Map.Size
	local Cx, Cz = math.floor(X / Cell), math.floor(Z / Cell)
	local Tx, Tz = Cx // Size, Cz // Size
	local Key = World.Key(Tx, Tz)
	local Tile, Data = Map:Ready(Key, Walker.Profile)
	local Column = (Cz - Tz * Size) * Size + (Cx - Tx * Size) + 1
	return Tile, Data, Column
end

T.Case("keys round trip", function()
	for _, Pair in next, { { 0, 0 }, { -1, 5 }, { 300, -200 }, { -32768, 32767 } } do
		local Tx, Tz = World.Unkey(World.Key(Pair[1], Pair[2]))
		T.Equal(Tx, Pair[1], "tx")
		T.Equal(Tz, Pair[2], "tz")
	end
end)

T.Case("ground column has one open floor", function()
	local Map = Build()
	local Tile, _, Column = SpanAt(Map, 5.5, 5.5)
	T.Equal(Tile.Count[Column], 1, "one span")
	local Span = Tile.First[Column]
	T.Near(Tile.Floor[Span], 0, 1e-6, "floor at 0")
	T.Equal(Tile.Ceil[Span], math.huge, "open sky")
	T.Equal(Tile.Surface[Span], Pathfinding.Surface.Pavement, "surface")
end)

T.Case("wall column floor is the wall top", function()
	local Map = Build()
	local Tile, _, Column = SpanAt(Map, 20.5, 10.5)
	T.Equal(Tile.Count[Column], 1, "merged with ground")
	T.Near(Tile.Floor[Tile.First[Column]], 10, 1e-6, "wall top")
end)

T.Case("clearance grows away from the wall", function()
	local Map = Build()
	local Expected = { [19.5] = 0.5, [18.5] = 1.5, [17.5] = 2.5, [16.5] = 3.5 }
	for X, Value in next, Expected do
		local Tile, Data, Column = SpanAt(Map, X, 10.5)
		T.Near(Data.Clear[Tile.First[Column]], math.min(Value, Walker.Profile.Cap), 1e-6, `clearance at x={X}`)
	end
end)

T.Case("bridge column has two floors", function()
	local Map = Build()
	local Tile, Data, Column = SpanAt(Map, -16.5, 12.5)
	T.Equal(Tile.Count[Column], 2, "two spans")
	local First = Tile.First[Column]
	T.Near(Tile.Floor[First], 0, 1e-6, "ground under bridge")
	T.Near(Tile.Ceil[First], 10, 1e-6, "bridge underside")
	T.Near(Tile.Floor[First + 1], 11, 1e-6, "bridge deck")
	T.True(Data.Clear[First] >= 0, "walkable under the bridge")
end)

T.Case("profile goes stale when a neighbour tile changes", function()
	local Map, Source = Build()
	local Tile, Data = SpanAt(Map, 5.5, 5.5)
	T.True(Map:Fresh(Tile, Data), "fresh after build")
	Source:Box(33.5, 2, 5, 1, 4, 1)
	Map:Sample(1, 0)
	T.True(not Map:Fresh(Tile, Data), "stale after neighbour changed")
	local Again = Map:Sample(1, 0)
	T.True(Again == Map.Tiles[World.Key(1, 0)], "identical resample keeps the tile")
end)

T.Case("invalidated tiles are resampled when next used", function()
	local Map, Source = Build()
	local Floor, Code = Map:FloorAt(-40.5, -40.5, 0, 2)
	T.Near(Floor, 0, 1e-6, "ground floor")
	T.Equal(Code, Pathfinding.Surface.Pavement, "ground surface")
	Source:Box(-40, 0.5, -40, 6, 1, 6, Pathfinding.Surface.Road)
	T.Near(Map:FloorAt(-40.5, -40.5, 0, 2), 0, 1e-6, "cached until invalidated")
	Map:Invalidate(-44, -44, -36, -36)
	local Raised, Surface = Map:FloorAt(-40.5, -40.5, 0, 2)
	T.Near(Raised, 1, 1e-6, "new box top")
	T.Equal(Surface, Pathfinding.Surface.Road, "new surface")
	local _, Data = SpanAt(Map, -40.5, -40.5)
	T.True(Data ~= nil, "profile rebuilds on the new tile")
end)

T.Finish("World")
