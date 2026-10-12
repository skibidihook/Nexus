local Pathfinding = require("../Pathfinding")
local T = require("./Framework")

local ReedsShepp = Pathfinding.Internal.ReedsShepp

local Seed = 987654
local function Random()
	Seed = (Seed * 1103515245 + 12345) % 2147483648
	return Seed / 2147483648
end

local function AngleError(A, B)
	return math.abs(ReedsShepp.Mod2Pi(A - B))
end

T.Case("random paths end exactly on the goal pose", function()
	local Worst, WorstAngle = 0, 0
	for _ = 1, 2000 do
		local X0, Z0, T0 = Random() * 100 - 50, Random() * 100 - 50, Random() * math.pi * 2
		local X1, Z1, T1 = Random() * 100 - 50, Random() * 100 - 50, Random() * math.pi * 2
		local Radius = 4 + Random() * 20
		local Path = ReedsShepp.Path(X0, Z0, T0, X1, Z1, T1, Radius)
		T.True(Path ~= nil, "path exists")
		local Lx, Lz, Lt = X0, Z0, T0
		ReedsShepp.Sample(Path, X0, Z0, T0, 0.5, function(X, Z, Theta)
			Lx, Lz, Lt = X, Z, Theta
		end)
		local Error = math.sqrt((Lx - X1) ^ 2 + (Lz - Z1) ^ 2)
		if Error > Worst then Worst = Error end
		local Angle = AngleError(Lt, T1)
		if Angle > WorstAngle then WorstAngle = Angle end
		T.True(Path.Length + 1e-6 >= math.sqrt((X1 - X0) ^ 2 + (Z1 - Z0) ^ 2), "never shorter than a straight line")
	end
	T.True(Worst < 1e-6, `worst position error {Worst}`)
	T.True(WorstAngle < 1e-6, `worst heading error {WorstAngle}`)
end)

T.Case("straight ahead is a single forward segment", function()
	local Path = ReedsShepp.Path(0, 0, 0, 50, 0, 0, 14)
	T.Near(Path.Length, 50, 1e-6, "length")
end)

T.Case("goal directly behind is reached by reversing", function()
	local Path = ReedsShepp.Path(0, 0, 0, -20, 0, 0, 14)
	T.Near(Path.Length, 20, 1e-6, "length")
	local Reverse = true
	ReedsShepp.Sample(Path, 0, 0, 0, 1, function(_, _, _, Direction)
		if Direction > 0 then Reverse = false end
	end)
	T.True(Reverse, "only reverse motion")
end)

T.Case("ten thousand solves are fast", function()
	local Start = os.clock()
	for Index = 1, 10000 do
		ReedsShepp.Length(0, 0, 0, (Index % 97) - 48, (Index % 89) - 44, Index * 0.37, 14)
	end
	local PerSolve = (os.clock() - Start) / 10000 * 1e6
	print(string.format("    %.2f us per solve", PerSolve))
	T.True(PerSolve < 200, "under 200 us")
end)

T.Finish("ReedsShepp")
