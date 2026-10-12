local Pathfinding = require("../Pathfinding")
local T = require("./Framework")

local Geometry = Pathfinding.Geometry
local Heap = Pathfinding.Internal.Heap

local function Shape(Kind, Sx, Sy, Sz, Yaw)
	local R00, R01, R02, R10, R11, R12, R20, R21, R22 = Geometry.Rotation(Yaw or 0)
	return Geometry.Shape(Kind, 0, 0, 0, R00, R01, R02, R10, R11, R12, R20, R21, R22, Sx, Sy, Sz, 1)
end

local function Top(S, X, Z)
	local _, High = Geometry.VerticalRange(S, X, Z)
	return High
end

T.Case("heap pops keys in order", function()
	local H = Heap.new()
	local Keys = {}
	for Index = 1, 500 do
		local Key = (Index * 7919) % 1009
		Keys[#Keys + 1] = Key
		H.Push(Index, Key)
	end
	table.sort(Keys)
	for Index = 1, #Keys do
		local _, Key = H.Pop()
		T.Equal(Key, Keys[Index], "heap order")
	end
	T.Equal(H.Pop(), nil, "empty heap")
end)

T.Case("wedge matches live probe", function()
	local S = Shape(Geometry.Wedge, 4, 4, 8)
	T.Near(Top(S, 0, -3), -1.5, 1e-6, "front")
	T.Near(Top(S, 0, 0), 0, 1e-6, "middle")
	T.Near(Top(S, 0, 3), 1.5, 1e-6, "back")
end)

T.Case("corner wedge matches live probe", function()
	local S = Shape(Geometry.CornerWedge, 8, 4, 8)
	local Expected = {
		{ -3, -3, -1.5 }, { -3, 0, -1.5 }, { -3, 3, -1.5 },
		{ 0, -3, 0 }, { 0, 0, 0 }, { 0, 3, -1.5 },
		{ 3, -3, 1.5 }, { 3, 0, 0 }, { 3, 3, -1.5 },
	}
	for _, Row in next, Expected do
		T.Near(Top(S, Row[1], Row[2]), Row[3], 1e-6, `corner wedge at {Row[1]},{Row[2]}`)
	end
end)

T.Case("cylinder matches live probe", function()
	local S = Shape(Geometry.Cylinder, 6, 2, 2)
	T.Near(Top(S, 0, 0), 1, 1e-6, "center")
	T.Near(Top(S, 0, 0.9), 0.4359, 1e-3, "offset z")
	T.Near(Top(S, 2.8, 0), 1, 1e-6, "near cap")
	T.Equal(Top(S, 3.2, 0), nil, "past cap")
end)

T.Case("ball matches live probe", function()
	local S = Shape(Geometry.Ball, 4, 6, 8)
	T.Near(Top(S, 0, 0), 2, 1e-6, "center")
	T.Near(Top(S, 1.9, 0), 0.6245, 1e-3, "offset")
	T.Equal(Top(S, 2.5, 0), nil, "outside")
end)

T.Case("rotated block footprint covers the right cells", function()
	local Source = Pathfinding.ShapeSource.new()
	Source:Box(16, 1, 16, 2, 2, 20, 1, math.rad(45))
	local Covered = {}
	local Info = { X0 = 0, Z0 = 0, Size = 32, Cell = 1, MinY = -100, MaxY = 100 }
	Source:Sample(Info, function(Index)
		Covered[Index] = true
	end)
	T.True(Covered[16 * 32 + 16 + 1], "center cell covered")
	T.True(not Covered[16 * 32 + 25 + 1], "cell off the diagonal is free")
	T.True(Covered[(16 + 6) * 32 + (16 + 6) + 1], "cell along the diagonal is covered")
end)

T.Finish("Geometry")
