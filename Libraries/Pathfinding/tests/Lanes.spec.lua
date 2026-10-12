local Pathfinding = require("../Pathfinding")
local T = require("./Framework")

local Lanes = Pathfinding.Lanes
local World = Pathfinding.Internal.World
local Reference = Pathfinding.Internal.Reference
local Surface = Pathfinding.Surface
local Cab = Pathfinding.Agent.BloxburgTaxi()

local function Line(Offset, Divider, From, To)
	return { Ax = From or -200, Az = Offset, Bx = To or 200, Bz = Offset, Y = 0.5, Divider = Divider }
end

local function Markings(List)
	local Lines = {}
	for _, Item in next, List do Lines[#Lines + 1] = Line(Item[1], Item[2]) end
	return Lines
end

local function Finder(Lines, Options)
	Options = Options or {}
	Options.Index = Lanes.Index(Lines)
	return Lanes.Finder(Options)
end

T.Case("two lane road puts the cab right of the double yellow", function()
	local Find = Finder(Markings({ { -0.57, true }, { -0.43, true }, { 0.43, true }, { 0.57, true }, { -18.82 }, { 18.82 } }))
	T.Near(Find(0, 3, 0, 1, 0), (0.57 + 18.82) / 2, 0.01, "heading +x")
	T.Near(Find(0, 3, 0, -1, 0), (0.57 + 18.82) / 2, 0.01, "heading -x keeps right of travel")
	local Left = Lanes.Finder({ Index = Lanes.Index(Markings({ { -0.5, true }, { 0.5, true }, { -18.8 }, { 18.8 } })), Side = -1 })
	T.Near(Left(0, 3, 0, 1, 0), -9.65, 0.01, "left hand traffic")
end)

T.Case("highway uses the inner lane beside the median", function()
	local Find = Finder(Markings({ { -9.69, true }, { 9.81, true }, { -28.44 }, { 28.56 }, { -47.2 }, { 47.31 } }))
	T.Near(Find(0, 3, 0, 1, 0), (9.81 + 28.56) / 2, 0.01, "inner lane")
end)

T.Case("centre turn lane is skipped", function()
	local Find = Finder(Markings({ { -9.47, true }, { 10.03, true }, { -28.97 }, { 29.53 } }))
	T.Near(Find(0, 3, 0, 1, 0), (10.03 + 29.53) / 2, 0.01, "lane right of the turn lane")
end)

T.Case("a path already in the lane needs almost no shift", function()
	local Find = Finder(Markings({ { -0.5, true }, { 0.5, true }, { -18.8 }, { 18.8 } }))
	T.Near(Find(0, 3, 9.65, 1, 0), 0, 0.01, "relative offset")
	T.Near(Find(0, 3, -9.65, 1, 0), 19.3, 0.01, "wrong side moves across")
end)

T.Case("lines on another level or across the road are ignored", function()
	local Lines = Markings({ { -0.5, true }, { 0.5, true }, { -18.8 }, { 18.8 } })
	Lines[#Lines + 1] = { Ax = 0, Az = -40, Bx = 0, Bz = 40, Y = 0.5, Divider = true }
	Lines[#Lines + 1] = { Ax = -200, Az = 5, Bx = 200, Bz = 5, Y = 30, Divider = true }
	local Find = Finder(Lines)
	T.Near(Find(0, 3, 0, 1, 0), 9.65, 0.01, "same answer")
end)

local function Street(Median)
	local Source = Pathfinding.ShapeSource.new()
	Source:Box(0, -0.5, 0, 400, 1, 200, Surface.Natural)
	Source:Box(0, 0.25, 0, 300, 0.5, 40, Surface.Road)
	for _, Side in next, { -1, 1 } do
		Source:Box(0, 0.5, Side * 20.5, 300, 1, 1, Surface.Curb)
		Source:Box(0, 0.5, Side * 25, 300, 1, 8, Surface.Pavement)
	end
	if Median then
		Source:Box(0, 0.5, 0, 300, 1, 14, Surface.Natural)
		Source:Box(0, 0.5, 7.5, 300, 1, 1, Surface.Curb)
		Source:Box(0, 0.5, -7.5, 300, 1, 1, Surface.Curb)
	end
	return World.new(Source, {})
end

local function Physical(Map)
	local Costs = Cab.CostArray
	local function Probe(X, Z, Y, Tolerance)
		local FloorY, Code = Map:FloorAt(X, Z, Y, Tolerance)
		if FloorY then return true, FloorY, Code end
		return nil
	end
	return Lanes.Finder({ Scanner = Lanes.Scanner(Probe, function(Code)
		return Costs[Code] <= 1
	end) })
end

T.Case("unmarked street lane comes from the curbs", function()
	local Find = Physical(Street(false))
	local Value = Find(0, 3, 0, 1, 0)
	T.True(Value and math.abs(Value - 10) < 1, `lane {Value}`)
end)

T.Case("street with a grass median uses the carriageway beside it", function()
	local Find = Physical(Street(true))
	local Value = Find(0, 3, 0, 1, 0)
	T.True(Value and math.abs(Value - 14) < 1, `lane {Value}`)
	local Back = Find(0, 3, 0, -1, 0)
	T.True(Back and math.abs(Back - 14) < 1, `other direction {Back}`)
end)

T.Case("profile fills gaps, smooths the change and tapers to the stop", function()
	local Points = { { X = 0, Y = 3, Z = 0 }, { X = 400, Y = 3, Z = 0 } }
	local Profile = Lanes.Profile(Points, function(X)
		if X < 150 then return 9.6 end
		if X < 190 then return nil end
		return 19.2
	end, { TaperFrom = 360 })
	local Values = Profile.Values
	T.Near(Values[1], 9.6, 1e-6, "start")
	T.Near(Values[60], 19.2, 1e-6, "after the change")
	T.Near(Values[#Values], 0, 1e-6, "tapered end")
	for Index = 2, #Values do
		T.True(math.abs(Values[Index] - Values[Index - 1]) < 2.1, `jump at {Index}`)
	end
end)

T.Case("kerb readings inside a short unpainted gap are bridged from the paint", function()
	local Points = { { X = 0, Y = 3, Z = 0 }, { X = 800, Y = 3, Z = 0 } }
	local Profile = Lanes.Profile(Points, function(X)
		if X < 100 or (X > 180 and X < 300) then return 9.6, true end
		if X < 300 then return 15, false end
		return 7, false
	end)
	T.Near(Profile.Values[36], 9.6, 1e-6, "intersection follows the paint")
	T.Near(Profile.Values[180], 7, 1e-6, "long unpainted street keeps its kerb lane")
	local Narrow = Lanes.Profile(Points, function(X)
		if X < 100 or X > 200 then return 9.6, true end
		return 5, false
	end)
	T.Near(Narrow.Values[38], 5, 1e-6, "a narrow bridge between painted roads narrows the lane")
end)

T.Case("laned reference turns right on the inside without folding", function()
	local Route = { { X = 0, Y = 0.5, Z = 0 }, { X = 200, Y = 0.5, Z = 0 }, { X = 200, Y = 0.5, Z = 30 }, { X = 400, Y = 0.5, Z = 30 } }
	for _, Lane in next, { 9.6, 19.8 } do
		local Profile = Lanes.Profile(Reference.Clean(Route), function()
			return Lane
		end)
		local Path = Reference.Build(Route, { LaneProfile = Profile, MinRadius = Cab.TurnRadius * 1.25, CornerRadius = 18 })
		local Tightest = math.huge
		for Index = 1, #Path.X - 1 do
			local Ahead = (Path.X[Index + 1] - Path.X[Index]) * math.cos(Path.H[Index]) + (Path.Z[Index + 1] - Path.Z[Index]) * math.sin(Path.H[Index])
			T.True(Ahead > 0, `fold at {Index} for lane {Lane}`)
			if math.abs(Path.K[Index]) > 1e-6 then Tightest = math.min(Tightest, 1 / math.abs(Path.K[Index])) end
		end
		T.True(Tightest >= Cab.TurnRadius * 1.25 * 0.9 - 1e-6, `tightest radius {Tightest} for lane {Lane}`)
		T.Near(Path.Z[1], Lane, 1e-6, "starts in the lane")
	end
end)

T.Case("pull over eases into the stop box only as far as needed", function()
	local Points = { { X = 0, Y = 3, Z = 0 }, { X = 400, Y = 3, Z = 0 } }
	local InLane = Lanes.Profile(Points, function() return 0 end, { EndRange = { 5, 19 } })
	T.Near(InLane.Values[#InLane.Values], 5, 1e-6, "moves to the near edge of the box")
	T.Near(InLane.Values[80], 0, 1e-6, "stays in lane until the pull in")
	local Wide = Lanes.Profile(Points, function() return 9.6 end, { EndRange = { 5, 19 } })
	T.Near(Wide.Values[#Wide.Values], 9.6, 1e-6, "already inside the box")
	for Index = 2, #InLane.Values do
		T.True(math.abs(InLane.Values[Index] - InLane.Values[Index - 1]) < 1.2, `pull in step at {Index}`)
	end
end)

T.Case("trim stops the route beside a kerbside stop", function()
	local Route = { { X = 0, Y = 3, Z = 0 }, { X = 300, Y = 3, Z = 0 } }
	local Trimmed, Done, Lateral = Reference.Trim(Route, 288, 12, { Reach = 24, Side = 1 })
	T.True(Done, "trimmed")
	T.Near(Lateral, 12, 1e-6, "stop is twelve to the right")
	T.Near(Trimmed[#Trimmed].X, 288, 1e-6, "ends level with the stop")
	local Kept, Other = Reference.Trim(Route, 288, -12, { Reach = 24, Side = 1 })
	T.True(not Other and #Kept == 2, "stop on the far side is left alone")
end)

T.Finish("Lanes")
