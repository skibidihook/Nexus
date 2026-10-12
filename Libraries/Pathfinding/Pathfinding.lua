--!nocheck
--!nolint UnknownGlobal, DeprecatedGlobal, BuiltinGlobalWrite
--!optimize 2
local Modules, Loaded = {}, {}
local function Require(Name)
	local Value = Loaded[Name]
	if Value == nil then
		Value = Modules[Name](Require)
		Loaded[Name] = Value
	end
	return Value
end
Modules.Agent = function(Require)
local Surface = Require("Surface")

local Agent = {}

local Huge, Sqrt, Max, Ceil, Floor, Abs = math.huge, math.sqrt, math.max, math.ceil, math.floor, math.abs

local WalkerCosts = {
	Default = 1,
	Road = 1,
	Pavement = 1,
	Natural = 1.1,
	Water = Huge,
	Wood = 1,
	Curb = 1,
	Ice = 1.3,
}

local CarCosts = {
	Default = 3,
	Road = 1,
	Pavement = 5,
	Natural = 6,
	Water = Huge,
	Wood = 12,
	Curb = 20,
	Ice = 3,
}

local function Round(Value)
	return Floor(Value * 100 + 0.5) / 100
end

local function Profile(Height, Step, Cap)
	return { Key = `{Round(Height)}|{Round(Step)}|{Round(Cap)}`, Height = Height, Step = Step, Cap = Cap }
end

function Agent.Walker(Options)
	Options = Options or {}
	local Radius = Options.Radius or 1.5
	local Height = Options.Height or 5
	local Step = Options.StepHeight or 2.1
	local Costs = Surface.CostArray(WalkerCosts, Options.Costs)
	if Options.CanSwim then Costs[Surface.Water] = Options.SwimCost or 3 end
	return {
		Kind = "Walker",
		Radius = Radius,
		Height = Height,
		StepHeight = Step,
		CostArray = Costs,
		Profile = Profile(Height, Step, Max(Radius + 2, 3)),
	}
end

function Agent.Car(Options)
	Options = Options or {}
	local Width = Options.Width or 8
	local Length = Options.Length or 18
	local Height = Options.Height or 7
	local Step = Options.StepHeight or 1.2
	local Margin = Options.Margin or 0.5
	local Half = Width * 0.5
	local Rows = Options.CircleRows or 2
	local Columns = Options.CircleColumns or 5
	local CellAlong, CellAcross = Length / Columns, Width / Rows
	local CircleRadius = Sqrt((CellAlong * 0.5) ^ 2 + (CellAcross * 0.5) ^ 2)
	local OuterRadius = Sqrt(Half * Half + (Length * 0.5) ^ 2)
	local Circles = {}
	for Column = 1, Columns do
		for Row = 1, Rows do
			Circles[#Circles + 1] = { (Column - 0.5) * CellAlong - Length * 0.5, (Row - 0.5) * CellAcross - Half }
		end
	end
	table.sort(Circles, function(A, B)
		local Ea, Eb = Abs(A[1]) + Abs(A[2]), Abs(B[1]) + Abs(B[2])
		if Ea ~= Eb then return Ea > Eb end
		return A[1] < B[1] or (A[1] == B[1] and A[2] < B[2])
	end)
	local MaxSpeed = Options.MaxSpeed or 40
	local YawRate = Options.YawRate
	local TurnRadius = Options.TurnRadius
	local Reserve = Options.SteerReserve or 0.85
	local SpeedLimit
	if YawRate then
		local Speeds, Curvatures = {}, {}
		local Tightest, TightestSpeed = 0, 1
		for Speed = 1, Ceil(MaxSpeed) do
			local Curvature = YawRate(Speed) / Speed
			Speeds[#Speeds + 1] = Speed
			Curvatures[#Curvatures + 1] = Curvature
			if Curvature > Tightest then Tightest, TightestSpeed = Curvature, Speed end
		end
		TurnRadius = TurnRadius or 1 / Tightest
		SpeedLimit = function(Curvature)
			local Need = Abs(Curvature) / Reserve
			for Index = #Speeds, 1, -1 do
				if Curvatures[Index] >= Need then return Speeds[Index] end
				if Speeds[Index] <= TightestSpeed then break end
			end
			return TightestSpeed
		end
	end
	return {
		Kind = "Car",
		Width = Width,
		Length = Length,
		Height = Height,
		StepHeight = Step,
		Margin = Margin,
		Radius = Half + Margin,
		InnerRadius = Half,
		CircleRadius = CircleRadius,
		OuterRadius = OuterRadius,
		Circles = Circles,
		TurnRadius = TurnRadius or 14,
		ReversePenalty = Options.ReversePenalty,
		MaxReverse = Options.MaxReverse,
		ShortcutCost = Options.ShortcutCost,
		YawRate = YawRate,
		SpeedLimit = SpeedLimit,
		MaxSpeed = MaxSpeed,
		ReverseSpeed = Options.ReverseSpeed or 20,
		LateralAccel = Options.LateralAccel or 30,
		Accel = Options.Accel or 18,
		Decel = Options.Decel or 30,
		CostArray = Surface.CostArray(CarCosts, Options.Costs),
		Profile = Profile(Height, Step, Ceil(OuterRadius + Margin + 1)),
	}
end

function Agent.BloxburgYaw(MaxYaw)
	MaxYaw = MaxYaw or 1.85
	local Cos, Pi = math.cos, math.pi
	return function(Speed)
		Speed = Abs(Speed)
		if Speed < 0.1 then return 0 end
		if Speed <= 15 then return MaxYaw * (Cos(Pi * (Speed - 15) / 15) + 1) * 0.5 end
		return MaxYaw * (Cos(0.023271056693257727 * (Speed - 15)) * 0.5 + 1.5) * 0.5
	end
end

function Agent.BloxburgTaxi(Options)
	Options = Options or {}
	return Agent.Car({
		Width = Options.Width or 8.2,
		Length = Options.Length or 19.3,
		Height = Options.Height or 7.8,
		StepHeight = Options.StepHeight or 1.2,
		MaxSpeed = Options.MaxSpeed or 48,
		ReverseSpeed = Options.ReverseSpeed or 25,
		YawRate = Options.YawRate or Agent.BloxburgYaw(Options.MaxYaw),
		Accel = Options.Accel or 22,
		Decel = Options.Decel or 28,
		LateralAccel = Options.LateralAccel or 80,
		ReversePenalty = Options.ReversePenalty or 3,
		MaxReverse = Options.MaxReverse or 40,
		ShortcutCost = Options.ShortcutCost or 4,
		Costs = Options.Costs,
	})
end

return Agent
end
Modules.CarPlanner = function(Require)
local Heap = Require("Heap")
local ReedsShepp = Require("ReedsShepp")

local CarPlanner = {}

local Sin, Cos, Sqrt, Abs, Floor, Ceil, Min, Max, Huge, Atan2 = math.sin, math.cos, math.sqrt, math.abs, math.floor, math.ceil, math.min, math.max, math.huge, math.atan2
local Pi, TwoPi = math.pi, math.pi * 2
local Shift = 65536
local Steers = { -2, -1, 0, 1, 2 }

local function Wrap(Angle)
	Angle = (Angle + Pi) % TwoPi - Pi
	return Angle
end
CarPlanner.Wrap = Wrap

local function Primitives(Bins, Radius, Offset, AllowReverse)
	local Delta = TwoPi / Bins
	local Length = 2 * Delta * Radius
	local List = table.create(Bins)
	for Bin = 0, Bins - 1 do
		local Theta = Offset + Bin * Delta
		local Entries = {}
		for Pass = 1, AllowReverse and 2 or 1 do
			local Dir = Pass == 1 and 1 or -1
			for Index = 1, 5 do
				local Steer = Steers[Index]
				local Kappa = Steer / (2 * Radius)
				local Dx, Dz = CarPlanner.Arc(0, 0, Theta, Kappa, Dir * Length)
				local Mx, Mz, Mt = CarPlanner.Arc(0, 0, Theta, Kappa, Dir * Length * 0.5)
				Entries[#Entries + 1] = { Dx, Dz, (Bin + Dir * Steer) % Bins, Dir, Steer, Kappa, Mx, Mz, Cos(Mt), Sin(Mt) }
			end
		end
		List[Bin + 1] = Entries
	end
	return List, Length, Delta
end

function CarPlanner.Arc(X, Z, Theta, Kappa, Distance)
	if Abs(Kappa) < 1e-9 then
		return X + Distance * Cos(Theta), Z + Distance * Sin(Theta), Theta
	end
	local After = Theta + Kappa * Distance
	return X + (Sin(After) - Sin(Theta)) / Kappa, Z - (Cos(After) - Cos(Theta)) / Kappa, After
end

function CarPlanner.Collider(Map, Car, Options, Yield)
	Options = Options or {}
	local Profile = Car.Profile
	local Size, Cell = Map.Size, Map.Cell
	local Step = Car.StepHeight
	local Margin = Options.Margin or Car.Margin
	local NeedOuter = Car.OuterRadius + Margin
	local NeedCircle = Car.CircleRadius + Margin
	local Circles = Car.Circles
	local Costs = Car.CostArray
	local Blocked = Options.Blocked
	local Entries = {}

	local function Load(Key)
		local Entry = Entries[Key]
		if not Entry then
			local Tile, Data = Map:Ready(Key, Profile, Yield)
			Entry = { Tile, Data }
			Entries[Key] = Entry
		end
		return Entry
	end

	local MemoClear, MemoFloor, MemoCode = {}, {}, {}

	local function Lookup(Cx, Cz, Y, Tolerance)
		local Tx, Tz = Cx // Size, Cz // Size
		local Key = (Tx + 32768) * Shift + (Tz + 32768)
		local Entry = Entries[Key] or Load(Key)
		local Tile = Entry[1]
		local Column = (Cz - Tz * Size) * Size + (Cx - Tx * Size) + 1
		local N = Tile.Count[Column]
		if N == 0 then return nil end
		local First = Tile.First[Column]
		local Best, BestGap = 0, Huge
		local Floors = Tile.Floor
		for Span = First, First + N - 1 do
			local Gap = Abs(Floors[Span] - Y)
			if Gap < BestGap then Best, BestGap = Span, Gap end
		end
		if BestGap > Tolerance then return nil end
		local Clear = Entry[2].Clear[Best]
		if Clear < 0 then return nil end
		if Blocked and Blocked[(Cx + 1048576) * 2097152 + Cz + 1048576] then return nil end
		return Clear, Floors[Best], Tile.Surface[Best]
	end

	local function Probe(X, Z, Y, Tolerance)
		local Cx, Cz = Floor(X / Cell), Floor(Z / Cell)
		local Index = (Cx + 1048576) * 2097152 + Cz + 1048576
		local Level = MemoFloor[Index]
		if Level and (Level - Y <= Tolerance and Y - Level <= Tolerance) then
			local Clear = MemoClear[Index]
			if Clear < 0 then return nil end
			return Clear, Level, MemoCode[Index]
		end
		local Clear, FloorY, Code = Lookup(Cx, Cz, Y, Tolerance)
		if Clear then
			MemoClear[Index], MemoFloor[Index], MemoCode[Index] = Clear, FloorY, Code
		elseif not Level then
			MemoClear[Index], MemoFloor[Index], MemoCode[Index] = -1, Y, 0
		end
		return Clear, FloorY, Code
	end

	local CenterTolerance = Step + 0.5
	local Reject = Car.InnerRadius - 0.5 + Min(0, Margin - Car.Margin)
	local CircleCount = #Circles

	local function Gap(X, Z, C, S, Y)
		local Clear, FloorY = Probe(X, Z, Y, CenterTolerance)
		if not Clear then return -Huge end
		local Worst = Clear - Car.InnerRadius
		for Index = 1, CircleCount do
			local Circle = Circles[Index]
			local Along, Across = Circle[1], Circle[2]
			local Other = Probe(X + Along * C - Across * S, Z + Along * S + Across * C, FloorY, Step + Abs(Along) * 0.6 + 0.5)
			if not Other then return -Huge end
			if Other - Car.CircleRadius < Worst then Worst = Other - Car.CircleRadius end
		end
		return Worst, FloorY
	end

	local function Free(X, Z, C, S, Y)
		local Clear, FloorY, Code = Probe(X, Z, Y, CenterTolerance)
		if not Clear or Costs[Code] == Huge or Clear < Reject then return false end
		if Clear >= NeedOuter and not Blocked then return true, FloorY, Code, Clear end
		for Index = 1, CircleCount do
			local Circle = Circles[Index]
			local Along, Across = Circle[1], Circle[2]
			local Other = Probe(X + Along * C - Across * S, Z + Along * S + Across * C, FloorY, Step + Abs(Along) * 0.6 + 0.5)
			if not Other or Other < NeedCircle then return false end
		end
		return true, FloorY, Code, Clear
	end

	return { Probe = Probe, Free = Free, Gap = Gap, Load = Load }
end

function CarPlanner.Validate(Map, Car, Path, From, To, Options, Yield)
	Options = Options or {}
	local Collide = CarPlanner.Collider(Map, Car, Options, Yield)
	local Free, Probe = Collide.Free, Collide.Probe
	local Costs = Car.CostArray
	local Rough = Options.RoughCost or Car.ShortcutCost or 4
	local Stride = Options.Stride or 2
	local Xs, Zs, Hs, Ys = Path.X, Path.Z, Path.H, Path.Y
	local Y = Ys[From]
	local _, Settled = Probe(Xs[From], Zs[From], Y, 6)
	if Settled then Y = Settled end
	local Blocked = {}
	local Open, OpenHit
	local Index = From
	while true do
		local Ok, Level, Code = Free(Xs[Index], Zs[Index], Cos(Hs[Index]), Sin(Hs[Index]), Y)
		if Ok then
			Y = Level
		else
			local _, Again = Probe(Xs[Index], Zs[Index], Y, 3)
			if Again then Y = Again end
		end
		local Bad = not Ok or Costs[Code] > Rough
		for Fill = Max(From, Index - Stride + 1), Index do Ys[Fill] = Y end
		if Bad then
			Open = Open or Index
			OpenHit = OpenHit or not Ok
		elseif Open then
			Blocked[#Blocked + 1] = { Open, Index, Hit = OpenHit == true }
			Open, OpenHit = nil, nil
		end
		if Index >= To then break end
		Index = Min(To, Index + Stride)
		if Yield and Index % 48 < Stride then Yield() end
	end
	if Open then Blocked[#Blocked + 1] = { Open, To, Hit = OpenHit == true, Open = true } end
	return Blocked
end

function CarPlanner.Plan(Map, Car, Start, Goal, Options, Yield)
	Options = Options or {}
	local Clock = Map.Clock
	local Started = Clock()
	local Cell = Map.Cell
	local Bins = Options.Bins or 48
	local Radius = Options.TurnRadius or Car.TurnRadius * (Options.RadiusFactor or Car.PlanFactor or 1.15)
	local AllowReverse = Options.Reverse ~= false
	local StartX, StartY, StartZ, StartT = Start.X, Start.Y, Start.Z, Start.Heading
	local Prims, Length, Delta = Primitives(Bins, Radius, StartT, AllowReverse)
	local HalfStep = Length * 0.5 + 0.1
	local Step = Car.StepHeight
	local Margin = Options.Margin or Car.Margin
	local NeedOuter = Car.OuterRadius + Margin
	local Costs = Car.CostArray
	local ReversePenalty = Options.ReversePenalty or Car.ReversePenalty or 1.5
	local SwitchPenalty = Options.SwitchPenalty or 4
	local SteerPenalty = Options.SteerPenalty or 0.1
	local SteerChangePenalty = Options.SteerChangePenalty or 0.4
	local ClearWeight = Options.ClearanceWeight or 0.5
	local ClearBand = Options.ClearanceBand or (Car.OuterRadius + 2)
	local MaxNodes = Options.MaxNodes or 20000
	local Weight = Options.Weight or 2
	local Gentle = Car.YawRate ~= nil and Options.Gentle ~= false
	local StartMoving = Start.Moving == true
	local MinCusp = Options.MinCuspSegment or 7
	local MaxReverse = Options.AnalyticMaxReverse or Car.MaxReverse or 40
	local Lane = Options.Lane
	local GoalX, GoalY, GoalZ = Goal.X, Goal.Y, Goal.Z
	local GoalT = Goal.Heading
	local PositionTolerance = Goal.Tolerance or 2
	local HeadingTolerance = Goal.HeadingTolerance or math.rad(12)
	local Region = Goal.Region
	local WindowPad = Options.WindowPad or 48
	local MinX = Options.MinX or Min(StartX, GoalX) - WindowPad
	local MaxX = Options.MaxX or Max(StartX, GoalX) + WindowPad
	local MinZ = Options.MinZ or Min(StartZ, GoalZ) - WindowPad
	local MaxZ = Options.MaxZ or Max(StartZ, GoalZ) + WindowPad

	local Collide = CarPlanner.Collider(Map, Car, Options, Yield)
	local Probe, Unbounded = Collide.Probe, Collide.Free
	local function Free(X, Z, C, S, Y)
		if X < MinX or X > MaxX or Z < MinZ or Z > MaxZ then return false end
		return Unbounded(X, Z, C, S, Y)
	end
	local ShortcutCost = Options.ShortcutCost or Car.ShortcutCost or Huge
	do
		local _, _, StartCode = Probe(StartX, StartZ, StartY, 4)
		local _, _, GoalCode = Probe(GoalX, GoalZ, GoalY, 4)
		if StartCode and Costs[StartCode] > ShortcutCost then ShortcutCost = Costs[StartCode] end
		if GoalCode and Costs[GoalCode] > ShortcutCost then ShortcutCost = Costs[GoalCode] end
	end

	local function LaneCost(X, Z, Theta)
		if not Lane then return 0 end
		local Points = Lane.Points
		local Best, BestDistance, BestSide = 0, Huge, 0
		for Index = 1, #Points - 1 do
			local A, B = Points[Index], Points[Index + 1]
			local Ax, Az, Bx, Bz = A.X, A.Z, B.X, B.Z
			local Ex, Ez = Bx - Ax, Bz - Az
			local LengthSq = Ex * Ex + Ez * Ez
			if LengthSq > 1e-6 then
				local T = ((X - Ax) * Ex + (Z - Az) * Ez) / LengthSq
				T = T < 0 and 0 or (T > 1 and 1 or T)
				local Px, Pz = Ax + Ex * T - X, Az + Ez * T - Z
				local Distance = Px * Px + Pz * Pz
				if Distance < BestDistance then
					BestDistance = Distance
					local Inverse = 1 / Sqrt(LengthSq)
					BestSide = ((X - Ax) * -Ez + (Z - Az) * Ex) * Inverse
					Best = Ex * Inverse * Cos(Theta) + Ez * Inverse * Sin(Theta)
				end
			end
		end
		if BestDistance == Huge then return 0 end
		local Wanted = Best >= 0 and Lane.Offset or -Lane.Offset
		local Error = BestSide - Wanted
		return Abs(Error) * (Lane.Weight or 0.05)
	end

	local NX, NY, NZ, NB, ND, NS, NG, NP, NK = {}, {}, {}, {}, {}, {}, {}, {}, {}
	local Closed = {}
	local Best = {}
	local Count = 0
	local Open = Heap.new()
	local Push, Pop, OpenSize = Open.Push, Open.Pop, Open.Size

	local Holonomic
	local RSRange = Options.ReedsSheppRange or 80

	local function Heuristic(X, Z, Bin, Precise)
		local Dx, Dz = GoalX - X, GoalZ - Z
		local Euclid = Sqrt(Dx * Dx + Dz * Dz)
		local H = Euclid
		if Holonomic then
			local Value = Holonomic(X, Z)
			if Value > H then H = Value end
		end
		if Precise and GoalT and Euclid < RSRange then
			local Value = ReedsShepp.Length(X, Z, StartT + Bin * Delta, GoalX, GoalZ, GoalT, Radius)
			if Value > H then H = Value end
		end
		return H * Weight
	end

	local function StateKey(X, Z, Bin)
		return ((Floor(X / Cell) + 1048576) * 2097152 + Floor(Z / Cell) + 1048576) * 128 + Bin
	end

	local function AtGoal(X, Z, Theta)
		if Region then
			local Dx, Dz = X - Region.X, Z - Region.Z
			local Along = Dx * Region.Cos + Dz * Region.Sin
			local Across = -Dx * Region.Sin + Dz * Region.Cos
			if Abs(Along) > Region.HalfX or Abs(Across) > Region.HalfZ then return false end
		else
			local Dx, Dz = X - GoalX, Z - GoalZ
			if Dx * Dx + Dz * Dz > PositionTolerance * PositionTolerance then return false end
		end
		return not GoalT or Abs(Wrap(Theta - GoalT)) <= HeadingTolerance
	end

	local Ok, FloorY = Free(StartX, StartZ, Cos(StartT), Sin(StartT), StartY)
	local Escape
	local EscapeRadius = Options.EscapeRadius or 9
	if not Ok then
		local StartGap = Collide.Gap(StartX, StartZ, Cos(StartT), Sin(StartT), StartY)
		if StartGap == -Huge then
			local _, Level = Probe(StartX, StartZ, StartY, 4)
			if Level then StartGap = Collide.Gap(StartX, StartZ, Cos(StartT), Sin(StartT), Level) end
		end
		if StartGap > -Huge and StartGap - 0.15 < Margin then
			local Relaxed = CarPlanner.Collider(Map, Car, { Margin = StartGap - 0.15, Blocked = Options.Blocked }, Yield).Free
			Escape = function(X, Z, C, S, Y)
				if X < MinX or X > MaxX or Z < MinZ or Z > MaxZ then return false end
				return Relaxed(X, Z, C, S, Y)
			end
		end
	end
	if not Ok then
		local Probed
		Probed, FloorY = Probe(StartX, StartZ, StartY, 4)
		if not Probed then
			return { Status = "NoStart", Complete = false, Expanded = 0, Time = Clock() - Started }
		end
	end
	if GoalT and not Region and Options.CheckGoal ~= false then
		local _, Level = Probe(GoalX, GoalZ, GoalY, 4)
		if not Level or not Free(GoalX, GoalZ, Cos(GoalT), Sin(GoalT), Level) then
			return { Status = "BadGoal", Complete = false, Expanded = 0, Time = Clock() - Started }
		end
	end
	Count = 1
	NX[1], NY[1], NZ[1], NB[1], ND[1], NS[1], NG[1], NP[1], NK[1] = StartX, FloorY, StartZ, 0, Start.Direction or 1, 0, 0, nil, 0
	Best[StateKey(StartX, StartZ, 0)] = 1
	Push(1, Heuristic(StartX, StartZ, 0))

	local Tries, TooLong, Shaped, Hit = 0, 0, 0, 0
	local AnalyticRange = Options.AnalyticRange or 260

	local function TryAnalytic(Node)
		if not GoalT then return nil end
		Tries += 1
		local X, Z, Theta = NX[Node], NZ[Node], StartT + NB[Node] * Delta
		local Path = ReedsShepp.Path(X, Z, Theta, GoalX, GoalZ, GoalT, Radius)
		if not Path or Path.Length > AnalyticRange then
			TooLong += 1
			return nil
		end
		local Previous, Backward, First = 0, 0, 0
		for Index = 1, 5 do
			local Value = Path.Lengths[Index] * Radius
			if Value ~= 0 then
				if Value < 0 then Backward -= Value end
				if First == 0 then First = Value > 0 and 1 or -1 end
				if Gentle and Previous ~= 0 and (Value > 0) ~= (Previous > 0) and (Abs(Value) < MinCusp or Abs(Previous) < MinCusp) then
					Shaped += 1
					return nil
				end
				Previous = Value
			end
		end
		if Backward > MaxReverse or (Gentle and First ~= ND[Node] and (Node ~= 1 or StartMoving)) then
			Shaped += 1
			return nil
		end
		Hit += 1
		local Y = NY[Node]
		local Fine = ReedsShepp.Sample(Path, X, Z, Theta, Options.AnalyticSpacing or 0.7, function(Px, Pz, Pt)
			local Clean, Level, Code = Free(Px, Pz, Cos(Pt), Sin(Pt), Y)
			if not Clean or Costs[Code] > ShortcutCost then return false end
			Y = Level
			return true
		end)
		if Fine then return Path end
		return nil
	end

	local function BuildHolonomic()
		local Need = Car.Width * 0.5 + Margin
		local Values = {}
		local GoalClear, GoalFloor = Probe(GoalX, GoalZ, GoalY, 4)
		if not GoalClear then return nil end
		local Queue = Heap.new()
		local QPush, QPop, QSize = Queue.Push, Queue.Pop, Queue.Size
		local Res = Options.HolonomicResolution or 2
		local function Index(I, J)
			return (I + 1048576) * 2097152 + J + 1048576
		end
		local Floors = {}
		local GoalI, GoalJ = Floor(GoalX / Res), Floor(GoalZ / Res)
		local Seed = Index(GoalI, GoalJ)
		Values[Seed] = 0
		Floors[Seed] = GoalFloor
		QPush(Seed, 0)
		local StartI, StartJ = Floor(StartX / Res), Floor(StartZ / Res)
		local Stop = Huge
		local Expanded = 0
		local Diagonal = Res * math.sqrt(2)
		while QSize() > 0 do
			local Node, Value = QPop()
			if Value <= Values[Node] then
				if Value > Stop then break end
				Expanded += 1
				if Expanded % 64 == 0 and Yield then Yield() end
				local I = Node // 2097152 - 1048576
				local J = Node - (I + 1048576) * 2097152 - 1048576
				if I == StartI and J == StartJ and Stop == Huge then Stop = Value * 1.6 + 40 end
				local Y = Floors[Node]
				for Di = -1, 1 do
					for Dj = -1, 1 do
						if Di ~= 0 or Dj ~= 0 then
							local Ni, Nj = I + Di, J + Dj
							local Px, Pz = (Ni + 0.5) * Res, (Nj + 0.5) * Res
							if Px >= MinX and Px <= MaxX and Pz >= MinZ and Pz <= MaxZ then
								local NClear, NFloor, NCode = Probe(Px, Pz, Y, Step + Res * 0.6 + 0.5)
								if NClear and NClear >= Need and Costs[NCode] < Huge then
									local Next = Index(Ni, Nj)
									local Cost = Value + (Di ~= 0 and Dj ~= 0 and Diagonal or Res) * Costs[NCode]
									local Old = Values[Next]
									if not Old or Cost < Old then
										Values[Next] = Cost
										Floors[Next] = NFloor
										QPush(Next, Cost)
									end
								end
							end
						end
					end
				end
			end
		end
		return function(X, Z)
			return Values[Index(Floor(X / Res), Floor(Z / Res))] or 0
		end
	end

	local Found, FoundPath
	local BestNode, BestH = 1, Huge
	local Expanded = 0
	local Stopped
	local HolonomicAfter = Options.HolonomicAfter or 300
	local NextAnalytic = 0
	local Interval = 2
	local Refined = {}

	local RestStart = Gentle and not StartMoving
	if GoalT and not RestStart then
		FoundPath = TryAnalytic(1)
		if FoundPath then Found = 1 end
	elseif AtGoal(StartX, StartZ, StartT) then
		Found = 1
	end

	while not Found and OpenSize() > 0 do
		local Node, Priority = Pop()
		if not Closed[Node] and not Refined[Node] and GoalT then
			Refined[Node] = true
			local Better = NG[Node] + Heuristic(NX[Node], NZ[Node], NB[Node], true)
			if Better > Priority + 1e-6 then
				Push(Node, Better)
				continue
			end
		end
		if not Closed[Node] then
			Closed[Node] = true
			Expanded += 1
			if Expanded % 32 == 0 and Yield and not Yield() then
				Stopped = "Timeout"
				break
			end
			if Expanded > MaxNodes then
				Stopped = "Limit"
				break
			end
			if Expanded == HolonomicAfter and Options.Holonomic ~= false then
				Holonomic = BuildHolonomic()
				if Holonomic then
					table.clear(Refined)
					local Pending = {}
					while OpenSize() > 0 do
						local Item = Pop()
						if not Closed[Item] then Pending[#Pending + 1] = Item end
					end
					for Index = 1, #Pending do
						local Item = Pending[Index]
						Push(Item, NG[Item] + Heuristic(NX[Item], NZ[Item], NB[Item]))
					end
				end
			end
			local X, Z, Bin = NX[Node], NZ[Node], NB[Node]
			local Theta = StartT + Bin * Delta
			if AtGoal(X, Z, Theta) then
				Found = Node
				break
			end
			local H = Heuristic(X, Z, Bin, true)
			if H < BestH then
				BestNode, BestH = Node, H
				Interval = Max(2, Interval * 0.5)
			end
			if Expanded >= NextAnalytic and not (RestStart and Node == 1) then
				FoundPath = TryAnalytic(Node)
				if FoundPath then
					Found = Node
					break
				end
				NextAnalytic = Expanded + Floor(Interval)
				Interval = Min(Interval * 1.5, 48)
			end
			local Base, Dir, Steer, Y = NG[Node], ND[Node], NS[Node], NY[Node]
			local List = Prims[Bin + 1]
			for Index = 1, #List do
				local P = List[Index]
				local Px, Pz = X + P[1], Z + P[2]
				local PBin = P[3]
				local K = StateKey(Px, Pz, PBin)
				local Existing = Best[K]
				local Allowed = true
				if Gentle then
					local PSteer = P[5]
					local Switching = P[4] ~= Dir and Node ~= 1
					if ((Node == 1 and not StartMoving) or Switching) and (PSteer > 1 or PSteer < -1) then Allowed = false end
					if Switching and (Steer > 1 or Steer < -1) then Allowed = false end
				end
				if Allowed and not (Existing and Closed[Existing]) then
					local PTheta = StartT + PBin * Delta
					local C, S = Cos(PTheta), Sin(PTheta)
					local Check = Free
					if Escape and (Px - StartX) ^ 2 + (Pz - StartZ) ^ 2 < EscapeRadius * EscapeRadius then Check = Escape end
					local Fine, PFloor, PCode, PClear = Check(Px, Pz, C, S, Y)
					if Fine and PClear < NeedOuter + HalfStep then Fine = Check(X + P[7], Z + P[8], P[9], P[10], Y) end
					if Fine then
						local PDir, PSteer = P[4], P[5]
						local Cost = Base + Length * (PDir > 0 and 1 or ReversePenalty) * Costs[PCode]
						if PDir ~= Dir and Node ~= 1 then Cost += SwitchPenalty end
						if PSteer ~= 0 then Cost += Abs(PSteer) * SteerPenalty * Length end
						if PSteer ~= Steer then Cost += SteerChangePenalty end
						if PClear < ClearBand then Cost += (ClearBand - PClear) / ClearBand * ClearWeight * Length end
						if Lane then Cost += LaneCost(Px, Pz, PTheta) * Length end
						if not Existing or Cost < NG[Existing] then
							local Target = Existing
							if not Target then
								Count += 1
								Target = Count
								Best[K] = Target
							end
							NX[Target], NY[Target], NZ[Target], NB[Target] = Px, PFloor, Pz, PBin
							ND[Target], NS[Target], NG[Target], NP[Target], NK[Target] = PDir, PSteer, Cost, Node, P[6]
							Push(Target, Cost + Heuristic(Px, Pz, PBin))
						end
					end
				end
			end
		end
	end

	local Final = Found or BestNode
	local Chain = {}
	local Node = Final
	while Node do
		Chain[#Chain + 1] = Node
		Node = NP[Node]
	end

	local Xs, Ys, Zs, Hs, Ds, Ks = {}, {}, {}, {}, {}, {}
	local function Add(X, Y, Z, H, D, K)
		local N = #Xs + 1
		Xs[N], Ys[N], Zs[N], Hs[N], Ds[N], Ks[N] = X, Y, Z, H, D, K
	end
	local FirstDir = #Chain >= 2 and ND[Chain[#Chain - 1]] or 1
	Add(StartX, NY[1], StartZ, StartT, FirstDir, 0)
	local Spacing = Options.Spacing or 0.8
	local Pieces = Max(1, Ceil(Length / Spacing))
	for Index = #Chain - 1, 1, -1 do
		local Child = Chain[Index]
		local Parent = Chain[Index + 1]
		local Px, Pz, Pt = NX[Parent], NZ[Parent], StartT + NB[Parent] * Delta
		local Dir, Kappa = ND[Child], NK[Child]
		for Piece = 1, Pieces do
			local X, Z, H = CarPlanner.Arc(Px, Pz, Pt, Kappa, Dir * Length * Piece / Pieces)
			Add(X, NY[Child], Z, H, Dir, Kappa)
		end
	end
	if FoundPath then
		local Last = Chain[1]
		local Y = NY[Last]
		ReedsShepp.Sample(FoundPath, NX[Last], NZ[Last], StartT + NB[Last] * Delta, Spacing, function(X, Z, H, D, K)
			local _, FloorValue = Probe(X, Z, Y, Step + 1)
			if FloorValue then Y = FloorValue end
			Add(X, Y, Z, H, D, K)
		end)
	end
	if #Ds >= 2 then Ds[1] = Ds[2] end

	local Points = #Xs
	if Options.Smooth ~= false and Points >= 5 then
		local Pull = Options.SmoothPull or 0.45
		for _ = 1, Options.SmoothRounds or 16 do
			for Index = 2, Points - 1 do
				local Dir = Ds[Index]
				if Ds[Index - 1] == Dir and Ds[Index + 1] == Dir then
					local Px, Pz, Nx, Nz = Xs[Index - 1], Zs[Index - 1], Xs[Index + 1], Zs[Index + 1]
					local X = Xs[Index] + Pull * ((Px + Nx) * 0.5 - Xs[Index])
					local Z = Zs[Index] + Pull * ((Pz + Nz) * 0.5 - Zs[Index])
					local Heading = Atan2(Nz - Pz, Nx - Px) + (Dir < 0 and Pi or 0)
					if Free(X, Z, Cos(Heading), Sin(Heading), Ys[Index]) then
						Xs[Index], Zs[Index], Hs[Index] = X, Z, Heading
					end
				end
			end
			if Yield then Yield() end
		end
		for Index = 1, Points do
			local A, C = Max(1, Index - 3), Min(Points, Index + 3)
			local Dir = Ds[Index]
			if Ds[A] == Dir and Ds[C] == Dir and C - A >= 2 then
				local Ux, Uz = Xs[Index] - Xs[A], Zs[Index] - Zs[A]
				local Vx, Vz = Xs[C] - Xs[Index], Zs[C] - Zs[Index]
				local Wx, Wz = Xs[C] - Xs[A], Zs[C] - Zs[A]
				local Product = Sqrt((Ux * Ux + Uz * Uz) * (Vx * Vx + Vz * Vz) * (Wx * Wx + Wz * Wz))
				Ks[Index] = Product > 1e-6 and 2 * (Ux * Vz - Uz * Vx) / Product or 0
			end
		end
	end

	return {
		Status = Found and "Complete" or (Stopped or "Partial"),
		Complete = Found ~= nil,
		X = Xs,
		Y = Ys,
		Z = Zs,
		H = Hs,
		D = Ds,
		K = Ks,
		Expanded = Expanded,
		Nodes = Count,
		Analytic = FoundPath ~= nil,
		Time = Clock() - Started,
		Diagnostics = `tries={Tries} long={TooLong} shape={Shaped} blocked={Hit - (FoundPath and 1 or 0)} holonomic={Holonomic ~= nil}`,
	}
end

return CarPlanner
end
Modules.Controller = function(Require)
local Controller = {}
Controller.__index = Controller

local Sin, Cos, Sqrt, Abs, Min, Max, Atan2, Huge = math.sin, math.cos, math.sqrt, math.abs, math.min, math.max, math.atan2, math.huge
local Pi, TwoPi = math.pi, math.pi * 2

local function Wrap(Angle)
	return (Angle + Pi) % TwoPi - Pi
end

function Controller.Profile(Path, Car, Options)
	Options = Options or {}
	local Xs, Zs, Ds, Ks = Path.X, Path.Z, Path.D, Path.K
	local Count = #Xs
	local S = table.create(Count, 0)
	for Index = 2, Count do
		local Dx, Dz = Xs[Index] - Xs[Index - 1], Zs[Index] - Zs[Index - 1]
		S[Index] = S[Index - 1] + Sqrt(Dx * Dx + Dz * Dz)
	end
	local Lateral = Options.LateralAccel or Car.LateralAccel
	local Accel = Options.Accel or Car.Accel
	local Decel = Options.Decel or Car.Decel
	local Forward = Options.MaxSpeed or Car.MaxSpeed
	local Backward = Options.ReverseSpeed or Car.ReverseSpeed
	local Creep = Options.CreepSpeed or 6
	local V = table.create(Count, 0)
	local SpeedLimit = Car.SpeedLimit
	local Caps = Path.Cap
	for Index = 1, Count do
		local Limit = Ds[Index] > 0 and Forward or Backward
		local Curvature = Abs(Ks[Index] or 0)
		if Curvature > 1e-4 then
			Limit = Min(Limit, SpeedLimit and SpeedLimit(Curvature) or Max(Creep, Sqrt(Lateral / Curvature)))
		end
		local Cap = Caps and Caps[Index]
		if Cap and Cap < Limit then Limit = Cap end
		V[Index] = Limit
	end
	for Index = 1, Count - 1 do
		if Ds[Index + 1] ~= Ds[Index] then V[Index] = 0 end
	end
	V[Count] = Path.EndSpeed or 0
	V[1] = Min(V[1], Options.StartSpeed or Huge)
	for Index = 2, Count do
		local Reach = Sqrt(V[Index - 1] ^ 2 + 2 * Accel * (S[Index] - S[Index - 1]))
		if V[Index - 1] < 0.5 then Reach = Max(Reach, Creep) end
		if V[Index] > Reach then V[Index] = Reach end
	end
	for Index = Count - 1, 1, -1 do
		local Reach = Sqrt(V[Index + 1] ^ 2 + 2 * Decel * (S[Index + 1] - S[Index]))
		if V[Index] > Reach then V[Index] = Reach end
	end
	Path.S = S
	Path.V = V
	Path.Length = S[Count]
	return Path
end

function Controller.new(Path, Car, Options)
	Options = Options or {}
	if not Path.V then Controller.Profile(Path, Car, Options) end
	local Segments = {}
	local Ds = Path.D
	local First, Dir = 1, Ds[1]
	for Index = 2, #Ds do
		if Ds[Index] ~= Dir then
			Segments[#Segments + 1] = { First, Index - 1, Dir }
			First, Dir = Index - 1, Ds[Index]
		end
	end
	Segments[#Segments + 1] = { First, #Ds, Dir }
	return setmetatable({
		Path = Path,
		Car = Car,
		Segments = Segments,
		Segment = 1,
		Index = 1,
		Options = Options,
		TurnRadius = Options.TurnRadius or Car.TurnRadius,
		Lookahead = Options.Lookahead or 0.55,
		MinLookahead = Options.MinLookahead or 5,
		MaxLookahead = Options.MaxLookahead or 22,
		Arrive = Options.Arrive or 2.5,
		ArriveSpeed = Options.ArriveSpeed or 2,
		CuspDistance = Options.CuspDistance or 1.5,
		MaxDeviation = Options.MaxDeviation or 7,
		Gain = Options.SpeedGain or 0.12,
	}, Controller)
end

function Controller:Closest(X, Z)
	local Path = self.Path
	local Xs, Zs = Path.X, Path.Z
	local Segment = self.Segments[self.Segment]
	local Best, BestDistance = self.Index, Huge
	local Last = Min(Segment[2], self.Index + 60)
	for Index = Max(self.Index, Segment[1]), Last do
		local Dx, Dz = Xs[Index] - X, Zs[Index] - Z
		local Distance = Dx * Dx + Dz * Dz
		if Distance < BestDistance then Best, BestDistance = Index, Distance end
	end
	return Best, Sqrt(BestDistance)
end

function Controller:Update(X, Z, Heading, Speed)
	local Path = self.Path
	local Xs, Zs, Ss, Vs = Path.X, Path.Z, Path.S, Path.V
	local Segment = self.Segments[self.Segment]
	local Index, Deviation = self:Closest(X, Z)
	self.Index = Index
	local Last, Dir = Segment[2], Segment[3]
	local Final = self.Segment == #self.Segments

	local Ex, Ez = Xs[Last] - X, Zs[Last] - Z
	local ToEnd = Sqrt(Ex * Ex + Ez * Ez)
	local Remaining = Ss[Last] - Ss[Index]
	if Index >= Last - 1 then
		local EndHeading = Path.H[Last]
		Remaining = (Ex * Cos(EndHeading) + Ez * Sin(EndHeading)) * Dir
	end
	if not Final and (ToEnd <= self.CuspDistance or Remaining <= 0.3) and Abs(Speed) < 3 then
		self.Segment += 1
		self.Index = Last
		return self:Update(X, Z, Heading, Speed)
	end
	if Final and ToEnd <= self.Arrive and Abs(Speed) <= self.ArriveSpeed then
		return 0, 0, "Arrived", Deviation
	end
	if Deviation > self.MaxDeviation then
		return 0, 0, "Deviated", Deviation
	end

	local Lookahead = Min(self.MaxLookahead, Max(self.MinLookahead, Abs(Speed) * self.Lookahead))
	local Goal = Ss[Index] + Lookahead
	local Target = Index
	while Target < Last and Ss[Target] < Goal do Target += 1 end
	local Tx, Tz = Xs[Target], Zs[Target]
	local Extra = Goal - Ss[Target]
	if Target == Last and Extra > 0 then
		local Pt = Path.H[Last]
		local Sign = Dir
		Tx += Cos(Pt) * Extra * Sign
		Tz += Sin(Pt) * Extra * Sign
	end

	local Travel = Dir > 0 and Heading or Heading + Pi
	local Dx, Dz = Tx - X, Tz - Z
	local Distance = Sqrt(Dx * Dx + Dz * Dz)
	local Alpha = Wrap(Atan2(Dz, Dx) - Travel)
	local Curvature = Distance > 1e-3 and 2 * Sin(Alpha) / Distance or 0
	local SteerCurvature = Dir > 0 and Curvature or -Curvature
	local Steer
	local YawRate = self.Car.YawRate
	if YawRate then
		local Moving = Max(Abs(Speed), 1.5)
		local Capacity = YawRate(Moving)
		Steer = Capacity > 1e-3 and SteerCurvature * Moving / Capacity or (SteerCurvature >= 0 and 1 or -1)
	else
		Steer = SteerCurvature * self.TurnRadius
	end
	if Steer > 1 then Steer = 1 elseif Steer < -1 then Steer = -1 end

	local Horizon = Ss[Index] + Abs(Speed) * (self.Options.Latency or 0.2)
	local Probe = Index
	while Probe < Last and Ss[Probe + 1] <= Horizon do Probe += 1 end
	local Wanted = Vs[Probe]
	local EndSpeed = Final and (Path.EndSpeed or 0) or 0
	local Stop = Max(0, (Final and ToEnd or Remaining) - 0.3)
	local Brake = Sqrt(EndSpeed * EndSpeed + 2 * (self.Options.Decel or self.Car.Decel) * Stop)
	if Brake < Wanted then Wanted = Brake end
	if Wanted < 1.5 and Stop > (Final and self.Arrive * 0.5 or 0.2) then Wanted = 1.5 end

	local Along = Speed * Dir
	local Top = Dir > 0 and self.Car.MaxSpeed or self.Car.ReverseSpeed
	local Throttle = Wanted / Top + (Wanted - Along) * self.Gain
	if Along > Wanted + 2 then Throttle = -(Along - Wanted) * self.Gain * 2 end
	if Throttle > 1 then Throttle = 1 elseif Throttle < -1 then Throttle = -1 end
	return Steer, Throttle * Dir, "Driving", Deviation, Wanted
end

return Controller
end
Modules.Driver = function(Require)
local CarPlanner = Require("CarPlanner")
local Controller = Require("Controller")
local Reference = Require("Reference")
local LaneModule = Require("Lanes")

local Driver = {}

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Sqrt, Atan2, Abs, Max, Min, Cos, Sin, Floor, Pi = math.sqrt, math.atan2, math.abs, math.max, math.min, math.cos, math.sin, math.floor, math.pi

local function Resolve(Value)
	if type(Value) == "function" then return Value() end
	return Value
end

local function Wrap(Angle)
	return (Angle + Pi) % (2 * Pi) - Pi
end

function Driver.Region(Value)
	if not Value then return nil end
	local CF, Size = Value.CFrame, Value.Size
	local Right = CF.RightVector
	local Angle = Atan2(Right.Z, Right.X)
	return { X = CF.Position.X, Y = CF.Position.Y, Z = CF.Position.Z, HalfX = Size.X * 0.5, HalfZ = Size.Z * 0.5, Cos = Cos(Angle), Sin = Sin(Angle) }
end

function Driver.Blocked(Map, MinX, MinZ, MaxX, MaxZ, Y, Height, Inflate, Ignore, Into, Self)
	local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = Ignore or {}
	Params.RespectCanCollide = true
	local Center = CFrame.new((MinX + MaxX) * 0.5, Y + Height * 0.5, (MinZ + MaxZ) * 0.5)
	local Parts = Workspace:GetPartBoundsInBox(Center, Vector3.new(MaxX - MinX, Height, MaxZ - MinZ), Params)
	local Blocked = Into or {}
	local Cell = Map.Cell
	local Marked = 0
	local SelfRoot = Self and Self.AssemblyRootPart
	for Index = 1, #Parts do
		local Part = Parts[Index]
		if not Part.Anchored and not Part:IsGrounded() and (not SelfRoot or Part.AssemblyRootPart ~= SelfRoot) then
			local Position, Size = Part.Position, Part.Size
			local Model = Part:FindFirstAncestorOfClass("Model")
			local Person = Model ~= nil and Model:FindFirstChildOfClass("Humanoid") ~= nil
			local Reach = Sqrt(Size.X * Size.X + Size.Z * Size.Z) * 0.5 + (Person and Inflate * 0.4 or Inflate)
			for Cx = Floor((Position.X - Reach) / Cell), Floor((Position.X + Reach) / Cell) do
				for Cz = Floor((Position.Z - Reach) / Cell), Floor((Position.Z + Reach) / Cell) do
					Blocked[(Cx + 1048576) * 2097152 + Cz + 1048576] = true
					Marked += 1
				end
			end
		end
	end
	return Blocked, Marked
end

function Driver.Drive(Pathfinding, Map, Car, Options)
	local Scheduler = Pathfinding.Scheduler
	local Input = Options.Input
	local Region = Driver.Region(Options.Region)
	local RoutePoints = Options.Route
	local GoalValue = Options.Goal
	local GoalPosition, GoalHeading
	if typeof(GoalValue) == "CFrame" then
		GoalPosition = GoalValue.Position
		local Look = GoalValue.LookVector
		GoalHeading = Options.GoalHeading ~= false and Atan2(Look.Z, Look.X) or nil
	elseif typeof(GoalValue) == "Vector3" then
		GoalPosition = GoalValue
	elseif Region then
		GoalPosition = Vector3.new(Region.X, Region.Y, Region.Z)
	elseif RoutePoints and #RoutePoints > 0 then
		GoalPosition = RoutePoints[#RoutePoints]
	end
	local Arrive = Options.Arrive or 4
	local Ignore = Options.Ignore or {}
	local Budget = Options.Budget or 0.004
	local Lanes = Options.Lanes
	local LaneSide = type(Lanes) == "table" and Lanes.Side or 1
	local Fallback = Options.LaneOffset or 0
	local Laned = Lanes ~= nil or Fallback ~= 0
	local RoughTrust = Options.RoughTrust or 30
	local CautionSpeed = Options.CautionSpeed or 10
	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude
	RayParams.FilterDescendantsInstances = Ignore

	local function Run(Handle)
		if not GoalPosition then Handle:Finish("Failed", nil, "NoGoal"); return end
		if not Input.Begin() then Handle:Finish("Failed", nil, "NoInput"); return end
		local Started = os.clock()
		local Status = "Starting"
		local Speed, History = 0, {}
		local Ref, Cursor, Validated, Validation = nil, 1, 0, nil
		local Blocks = {}
		local Plan, PlanRef, Drive
		local Pending, PendingInfo, RouteJob, Connect
		local LaneJob, LanePoints, LaneOptions
		local Failures, Stucks, Reach, Parks = 0, 0, 0, 0
		local StuckSince
		local RetryAt = 0
		local Dynamic, DynamicUntil = {}, 0
		Handle.PlanLog = {}
		Handle.Blocks = Blocks

		local function Report(Text)
			if Text ~= Status then
				Status = Text
				Handle.Phase = Text
				if Options.OnStatus then pcall(Options.OnStatus, Text) end
			end
		end

		local function Ground(Position)
			local Hit = Workspace:Raycast(Position + Vector3.new(0, 2, 0), Vector3.new(0, -30, 0), RayParams)
			return Hit and Hit.Position.Y or Position.Y - Car.Height * 0.5
		end

		local function Finalize(Profile)
			Ref = Reference.Build(LanePoints, {
				CornerRadius = Options.CornerRadius or 18,
				LaneOffset = Fallback,
				LaneProfile = Profile,
				MinRadius = Car.TurnRadius * 1.25,
				Spacing = 0.8,
			})
			Handle.Reference = Ref
			Handle.Lanes = Profile
			Cursor, Validated = 1, 1
		end

		local function Constant()
			return Fallback
		end

		local function BuildReference(Points)
			local Trimmed, Lateral, Ux, Uz = false, 0, 1, 0
			if Laned and Options.TrimGoal ~= false then
				Points, Trimmed, Lateral, Ux, Uz = Reference.Trim(Points, GoalPosition.X, GoalPosition.Z, { Reach = Options.TrimReach or 24, Side = LaneSide })
			end
			if not Trimmed then
				local Last = Points[#Points]
				if not Last or (Last.X - GoalPosition.X) ^ 2 + (Last.Z - GoalPosition.Z) ^ 2 > 1 then
					Points = table.clone(Points)
					Points[#Points + 1] = GoalPosition
				end
			end
			Handle.Trimmed = Trimmed
			LanePoints = Reference.Clean(Points)
			local Count = #LanePoints
			if not Laned or Count < 2 then
				Finalize(nil)
				return
			end
			local Taper
			if not Trimmed then
				local Total = 0
				for Index = 2, Count do
					local A, B = LanePoints[Index - 1], LanePoints[Index]
					Total += Sqrt((B.X - A.X) ^ 2 + (B.Z - A.Z) ^ 2)
				end
				local A, B = LanePoints[Count - 1], LanePoints[Count]
				Taper = Total - Sqrt((B.X - A.X) ^ 2 + (B.Z - A.Z) ^ 2)
			end
			LaneOptions = { Step = Options.LaneStep or 4, Fallback = Fallback, TaperFrom = Taper, PullIn = Options.PullIn }
			if Trimmed then
				if Region then
					local End = LanePoints[Count]
					local Nx, Nz = -Uz, Ux
					local Lo, Hi = math.huge, -math.huge
					for _, Along in next, { -Region.HalfX, Region.HalfX } do
						for _, Across in next, { -Region.HalfZ, Region.HalfZ } do
							local Px = Region.X + Along * Region.Cos - Across * Region.Sin
							local Pz = Region.Z + Along * Region.Sin + Across * Region.Cos
							local Value = (Px - End.X) * Nx + (Pz - End.Z) * Nz
							Lo, Hi = Min(Lo, Value), Max(Hi, Value)
						end
					end
					local Inset = Min(3, (Hi - Lo) * 0.25)
					LaneOptions.EndRange = { Lo + Inset, Hi - Inset }
				else
					LaneOptions.EndOffset = Lateral
				end
			end
			if not Lanes then
				Finalize(LaneModule.Profile(LanePoints, Constant, LaneOptions))
				return
			end
			Report("Laning")
			LaneJob = Scheduler:Spawn(function(Job)
				local Finder = Lanes
				if type(Lanes) == "table" then
					local Config = table.clone(Lanes)
					if Lanes.Physical ~= false then
						local Costs, RoadCost, Yield = Car.CostArray, Lanes.RoadCost or 1, Job.Yield
						Config.Scanner = LaneModule.Scanner(function(X, Z, Y, Tolerance)
							local FloorY, Code = Map:FloorAt(X, Z, Y, Tolerance, Yield)
							if FloorY then return true, FloorY, Code end
							return nil
						end, function(Code)
							return Costs[Code] <= RoadCost
						end, Lanes)
					end
					Finder = LaneModule.Finder(Config)
				end
				return LaneModule.Profile(LanePoints, Finder, LaneOptions, Job.Yield)
			end, Options.LaneTimeout or 8)
			LaneJob.Budget = Options.LaneBudget or Budget
		end

		local function Search(A, B)
			Report("Routing")
			local Agent = { Kind = "Route", Radius = Car.Width * 0.5 + Car.Margin + (Options.RoutePadding or 1.5), Profile = Car.Profile, CostArray = Car.CostArray }
			local Job = Pathfinding.FindPath(Map, Agent, Vector3.new(A.X, Ground(A), A.Z), B, { Timeout = Options.RouteTimeout or 25, Budget = Budget, MaxNodes = 250000, Tolerance = 12 })
			return Job
		end

		local function Inside(X, Z)
			if not Region then return false end
			local Dx, Dz = X - Region.X, Z - Region.Z
			return Abs(Dx * Region.Cos + Dz * Region.Sin) <= Region.HalfX and Abs(-Dx * Region.Sin + Dz * Region.Cos) <= Region.HalfZ
		end

		local function GoalFor(Index)
			if Index >= #Ref.X then
				return { X = GoalPosition.X, Y = Ref.Y[#Ref.Y], Z = GoalPosition.Z, Heading = GoalHeading, Region = Region, Tolerance = Arrive * 0.75 }, true
			end
			return { X = Ref.X[Index], Y = Ref.Y[Index], Z = Ref.Z[Index], Heading = Ref.H[Index], Tolerance = 2.5, HeadingTolerance = math.rad(15) }, false
		end

		local function LaneNear(From, To)
			local Points = {}
			for Index = Max(1, From), Min(#Ref.X, To), 5 do
				Points[#Points + 1] = { X = Ref.X[Index], Z = Ref.Z[Index] }
			end
			if #Points < 2 then return nil end
			return { Points = Points, Offset = 0, Weight = Options.LaneWeight or 0.12 }
		end

		local function PastBlocks(Target)
			for _, Block in next, Blocks do
				if Block.Outcome ~= "Trusted" and Target >= Block[1] - 8 and Target <= Block[2] then return Reference.Ahead(Ref, Block[2], 25 + (Block.Extra or 0)) end
			end
			return Target
		end

		local function Rejoin(Start, Target, Prefix, Block)
			Target = PastBlocks(Target)
			local Goal, IsFinal = GoalFor(Target)
			if os.clock() > DynamicUntil then table.clear(Dynamic) end
			local Pad = 50
			Driver.Blocked(Map, Min(Start.X, Goal.X) - Pad, Min(Start.Z, Goal.Z) - Pad, Max(Start.X, Goal.X) + Pad, Max(Start.Z, Goal.Z) + Pad, Start.Y, Car.Height + 4, Car.CircleRadius + Car.Margin, Ignore, Dynamic, Resolve(Options.Body))
			local Relax = Block ~= nil and Block.Relax == true
			local PlanOptions = {
				Lane = LaneNear(Cursor, Target + 10),
				Blocked = next(Dynamic) and Dynamic or nil,
				MaxNodes = (Options.MaxNodes or 12000) * (Relax and 2 or 1),
				Margin = Relax and Min(Car.Margin, 0.25) or nil,
			}
			Pending = Scheduler:Spawn(function(Job)
				return CarPlanner.Plan(Map, Car, Start, Goal, PlanOptions, Job.Yield)
			end, Options.PlanTimeout or 6)
			Pending.Budget = Budget
			PendingInfo = { Target = Target, Prefix = Prefix, Final = IsFinal, Block = Block }
			Handle.Plans = (Handle.Plans or 0) + 1
			Report((Prefix or Block) and "Detouring" or "Joining")
		end

		local function Caution(Path, Sources)
			local Caps
			for _, Block in next, Blocks do
				if Block.Outcome == "Caution" then
					for Index = 1, #Path.X do
						local Source = Sources[Index]
						if Source and Source >= Block[1] - 12 and Source <= Block[2] + 4 then
							Caps = Caps or {}
							Caps[Index] = CautionSpeed
						end
					end
				end
			end
			Path.Cap = Caps
		end

		local function Compose(Joined, Info, CurrentSpeed)
			local Path = { X = {}, Y = {}, Z = {}, H = {}, D = {}, K = {} }
			local Sources = {}
			local function Push(X, Y, Z, H, D, K, Source)
				local N = #Path.X + 1
				Path.X[N], Path.Y[N], Path.Z[N], Path.H[N], Path.D[N], Path.K[N] = X, Y, Z, H, D, K
				Sources[N] = Source
			end
			if Info.Prefix and Plan then
				for Index = Info.Prefix[1], Info.Prefix[2] do
					Push(Plan.X[Index], Plan.Y[Index], Plan.Z[Index], Plan.H[Index], Plan.D[Index], Plan.K[Index], PlanRef[Index])
				end
			end
			for Index = #Path.X > 0 and 2 or 1, #Joined.X do
				Push(Joined.X[Index], Joined.Y[Index], Joined.Z[Index], Joined.H[Index], Joined.D[Index], Joined.K[Index], 0)
			end
			if not Info.Final then
				for Index = Info.Target + 1, #Ref.X do
					Push(Ref.X[Index], Ref.Y[Index], Ref.Z[Index], Ref.H[Index], 1, Ref.K[Index], Index)
				end
			end
			Path.EndSpeed = 0
			Caution(Path, Sources)
			Controller.Profile(Path, Car, { StartSpeed = Max(Abs(CurrentSpeed), 4) })
			Plan, PlanRef = Path, Sources
			Drive = Controller.new(Path, Car, { Arrive = Arrive, Decel = Options.Decel })
			Report("Driving")
		end

		local function Remaining(Points, X, Z)
			if #Points < 2 then return table.clone(Points), Sqrt((Points[1].X - X) ^ 2 + (Points[1].Z - Z) ^ 2) end
			local BestIndex, BestT, Best = 1, 0, math.huge
			for Index = 1, #Points - 1 do
				local A, B = Points[Index], Points[Index + 1]
				local Ex, Ez = B.X - A.X, B.Z - A.Z
				local LengthSq = Ex * Ex + Ez * Ez
				local T = LengthSq > 1e-6 and math.clamp(((X - A.X) * Ex + (Z - A.Z) * Ez) / LengthSq, 0, 1) or 0
				local Distance = (X - A.X - Ex * T) ^ 2 + (Z - A.Z - Ez * T) ^ 2
				if Distance < Best then BestIndex, BestT, Best = Index, T, Distance end
			end
			local A, B = Points[BestIndex], Points[BestIndex + 1]
			local Out = { Vector3.new(A.X + (B.X - A.X) * BestT, A.Y + (B.Y - A.Y) * BestT, A.Z + (B.Z - A.Z) * BestT) }
			for Index = BestIndex + 1, #Points do Out[#Out + 1] = Points[Index] end
			return Out, Sqrt(Best)
		end

		local Origin = Resolve(Options.Body)
		if not Origin then Handle:Finish("Failed", nil, "NoBody"); return end
		local From = Origin.Position
		if RoutePoints and #RoutePoints >= 1 then
			local Points, Gap = Remaining(RoutePoints, From.X, From.Z)
			if Gap > 40 and Options.GlobalRoute ~= false then
				Connect = Points
				RouteJob = Search(From, Points[1])
			else
				BuildReference(Points)
			end
		elseif (GoalPosition.X - From.X) ^ 2 + (GoalPosition.Z - From.Z) ^ 2 > 40 * 40 and Options.GlobalRoute ~= false then
			RouteJob = Search(From, GoalPosition)
		else
			BuildReference({ From })
		end

		while Handle.Status == "Running" do
			RunService.Heartbeat:Wait()
			local Now = os.clock()
			if Options.Alive and not Options.Alive() then Handle:Finish("Cancelled"); return end
			if Now - Started > (Options.Timeout or 240) then Handle:Finish("Failed", Plan, "Timeout"); return end
			local Body = Resolve(Options.Body)
			if not (Body and Body.Parent) then Handle:Finish("Failed", nil, "NoBody"); return end
			local Frame = Body.CFrame
			local Position = Frame.Position
			local Look = Frame.LookVector
			local Heading = Atan2(Look.Z, Look.X)
			History[#History + 1] = { Now, Position.X, Position.Z }
			while #History > 2 and Now - History[2][1] >= 0.12 do table.remove(History, 1) end
			local Oldest = History[1]
			if Oldest and Now - Oldest[1] > 0.02 then
				Speed = ((Position.X - Oldest[2]) * Cos(Heading) + (Position.Z - Oldest[3]) * Sin(Heading)) / (Now - Oldest[1])
			end
			Handle.Speed = Speed
			if Options.Telemetry then
				local Log = Options.Telemetry
				Log[#Log + 1] = { Now - Started, Position.X, Position.Z, Heading, Speed, Input.Steer or 0, Input.Throttle or 0, Status }
			end

			local function Hold()
				Input.Set(0, Abs(Speed) > 1 and (Speed > 0 and -0.6 or 0.6) or 0)
			end

			local Near = (Position.X - GoalPosition.X) ^ 2 + (Position.Z - GoalPosition.Z) ^ 2
			if Abs(Speed) < 2.5 and (Inside(Position.X, Position.Z) or Near <= Arrive * Arrive) and Now - Started > 1 then
				Input.Set(0, 0)
				Handle:Finish("Done", Plan)
				return
			end

			if RouteJob then
				if RouteJob.Status == "Running" then
					Hold()
					continue
				end
				local Found = RouteJob.Result
				Handle.Route = Found
				RouteJob = nil
				local Points = (Found and Found.Points and #Found.Points >= 2) and table.clone(Found.Points) or { Position }
				if Connect then
					local Start = (Points[#Points] - Connect[1]).Magnitude < 4 and 2 or 1
					for Index = Start, #Connect do Points[#Points + 1] = Connect[Index] end
					Connect = nil
				end
				BuildReference(Points)
			end

			if LaneJob then
				if LaneJob.Status == "Running" then
					Hold()
					continue
				end
				local Profile = LaneJob.Status == "Done" and LaneJob.Result or LaneModule.Profile(LanePoints, Constant, LaneOptions)
				Handle.LaneCpu = LaneJob.Cpu
				Handle.LaneError = LaneJob.Error
				LaneJob = nil
				Finalize(Profile)
			end
			if not Ref then
				Hold()
				continue
			end

			if Validation and Validation.Status ~= "Running" then
				local First = Validation.Range[1]
				local Tail = Blocks[#Blocks]
				local Continued = false
				for _, Found in next, Validation.Result or {} do
					if Tail and Tail.Open and not Continued and Found[1] <= First then
						Tail[2] = Found[2]
						Tail.Hit = Tail.Hit or Found.Hit
						Tail.Open = Found.Open
						Continued = true
					else
						Blocks[#Blocks + 1] = { Found[1], Found[2], Hit = Found.Hit, Open = Found.Open }
					end
				end
				if Tail and Tail.Open and not Continued then Tail.Open = nil end
				Validated = Validation.Range[2]
				Validation = nil
				local Last = #Ref.X
				for _, Block in next, Blocks do
					if Validated >= Last then Block.Open = nil end
					if not Block.Open and not Block.Hit and not Block.Outcome and Ref.S[Block[2]] - Ref.S[Block[1]] >= RoughTrust then
						Block.Outcome = "Trusted"
						Block.Handled = true
					end
				end
			end
			local Count = #Ref.X
			if not Validation and Validated < Count and Ref.S[Validated] - Ref.S[Cursor] < (Options.ValidateAhead or 260) then
				local First = Validated
				local Last = Reference.Ahead(Ref, First, Options.ValidateChunk or 160)
				local CheckOptions = { Blocked = next(Dynamic) and Dynamic or nil }
				Validation = Scheduler:Spawn(function(Job)
					return CarPlanner.Validate(Map, Car, Ref, First, Last, CheckOptions, Job.Yield)
				end, 10)
				Validation.Budget = Budget
				Validation.Range = { First, Last }
			end

			Cursor = Reference.Nearest(Ref, Position.X, Position.Z, Max(1, Cursor - 25), Min(Count, Cursor + 300))

			if Pending and Pending.Status ~= "Running" then
				local Finished, Info = Pending, PendingInfo
				local Result = Finished.Result
				Pending, PendingInfo = nil, nil
				Handle.PlanCpu = (Handle.PlanCpu or 0) + Finished.Cpu
				local Block = Info.Block
				table.insert(Handle.PlanLog, string.format("%s %s exp=%d pts=%d %s", (Info.Prefix or Block) and "detour" or "join", Result and Result.Status or "Failed", Result and Result.Expanded or 0, Result and Result.X and #Result.X or 0, Result and Result.Diagnostics or ""))
				if Result and Result.Complete and Result.X and #Result.X < 2 and Info.Final then
					Input.Set(0, 0)
					Handle:Finish("Done", Plan)
					return
				elseif Result and Result.Complete and Result.X and #Result.X >= 1 then
					Failures, Reach = 0, 0
					if Block then Block.Outcome = "Detoured" end
					Compose(Result, Info, Speed)
				elseif Block and Drive then
					if Result and Result.Status == "BadGoal" and (Block.Extra or 0) < 75 then
						Block.Extra = (Block.Extra or 0) + 25
						Block.Handled = nil
					elseif Block.Hit and not Block.Relax then
						Block.Relax = true
						Block.Handled = nil
					else
						Block.Outcome = Block.Hit and "Caution" or "Accepted"
						if Block.Hit then
							Caution(Plan, PlanRef)
							Controller.Profile(Plan, Car, { StartSpeed = Plan.V[1] })
						end
					end
					Report("Driving")
				else
					Failures += 1
					Reach += 25
					RetryAt = Now + 0.6
					if Failures >= (Options.MaxFailures or 8) then Handle:Finish("Failed", Result, Result and Result.Status or "PlanFailed"); return end
					if not Info.Prefix then Drive, Plan = nil, nil end
				end
			end

			if not Drive then
				if not Pending and Now >= RetryAt and Validated >= Min(Count, Reference.Ahead(Ref, Cursor, 50)) then
					local Target = Reference.Ahead(Ref, Cursor, 30 + Abs(Speed) * 0.6 + Reach)
					local Offset = Sqrt((Ref.X[Cursor] - Position.X) ^ 2 + (Ref.Z[Cursor] - Position.Z) ^ 2)
					if Offset < 2 and Abs(Wrap(Heading - Ref.H[Cursor])) < 0.35 and Speed > -1 and Reach == 0 then
						Compose({ X = { Position.X }, Y = { Ref.Y[Cursor] }, Z = { Position.Z }, H = { Heading }, D = { 1 }, K = { 0 } }, { Target = Cursor }, Speed)
					else
						Rejoin({ X = Position.X, Y = Ground(Position), Z = Position.Z, Heading = Heading, Direction = Speed < -1 and -1 or 1, Moving = Abs(Speed) > 4 }, Target, nil)
					end
				end
				if not Drive then
					Hold()
					continue
				end
			end

			if not Pending then
				for _, Block in next, Blocks do
					if not Block.Handled and not Block.Open and Block[2] >= Cursor then
						local Gap = Ref.S[Max(Block[1], Cursor)] - Ref.S[Cursor]
						if Gap < Max(70, Abs(Speed) * 2.5) then
							Block.Handled = true
							Block.Attempts = (Block.Attempts or 0) + 1
							local Beyond = Reference.Ahead(Ref, Block[2], 25 + (Block.Extra or 0))
							local Ahead = Plan.S[Drive.Index] + Max(8, Abs(Speed) * 0.9)
							local Splice = Drive.Index
							while Splice < #Plan.X and Plan.S[Splice] < Ahead do Splice += 1 end
							local SpliceRef = PlanRef[Splice] or 0
							if Gap > 25 and SpliceRef > 0 and SpliceRef < Block[1] then
								local Start = { X = Plan.X[Splice], Y = Plan.Y[Splice], Z = Plan.Z[Splice], Heading = Plan.H[Splice], Direction = Plan.D[Splice], Moving = (Plan.V[Splice] or 0) > 4 }
								Rejoin(Start, Beyond, { Drive.Index, Splice }, Block)
							else
								Rejoin({ X = Position.X, Y = Ground(Position), Z = Position.Z, Heading = Heading, Direction = Speed < -1 and -1 or 1, Moving = Abs(Speed) > 4 }, Beyond, nil, Block)
							end
							break
						end
					end
				end
			end

			local Steer, Throttle, State = Drive:Update(Position.X, Position.Z, Heading, Speed)
			if State == "Arrived" then
				if Region and not Inside(Position.X, Position.Z) and Parks < (Options.MaxParks or 2) then
					Parks += 1
					if Pending then Pending:Cancel() end
					Drive, Plan = nil, nil
					Rejoin({ X = Position.X, Y = Ground(Position), Z = Position.Z, Heading = Heading, Direction = 1, Moving = false }, #Ref.X, nil)
					Report("Parking")
					continue
				end
				Input.Set(0, 0)
				Handle:Finish("Done", Plan)
				return
			elseif State == "Deviated" then
				Drive, Plan = nil, nil
				Report("Recovering")
				continue
			end

			local Dir = Throttle >= 0 and 1 or -1
			if Abs(Speed) > 2 then Dir = Speed > 0 and 1 or -1 end
			local Brake = Speed * Speed / (2 * Car.Decel) + 4
			local Forward = Vector3.new(Cos(Heading), 0, Sin(Heading))
			local Eye = Position + Vector3.new(0, 1, 0)
			local Hit = Workspace:Blockcast(CFrame.lookAt(Eye, Eye + Forward * Dir), Vector3.new(Car.Width - 1, Max(1, Car.Height - Car.StepHeight - 2.5), 2), Forward * Dir * (Car.Length * 0.5 + Brake), RayParams)
			if Hit and Hit.Instance and not Hit.Instance.Anchored and not Hit.Instance:IsGrounded() and Hit.Instance.AssemblyRootPart ~= Body.AssemblyRootPart then
				Throttle = -Dir * Min(1, Abs(Speed) / 10 + 0.2)
				Steer = 0
				if Abs(Speed) < 1.5 then
					local Spot = Hit.Instance.Position
					local Spread = Car.CircleRadius + Car.Margin + Hit.Instance.Size.Magnitude * 0.5
					for Cx = Floor((Spot.X - Spread) / Map.Cell), Floor((Spot.X + Spread) / Map.Cell) do
						for Cz = Floor((Spot.Z - Spread) / Map.Cell), Floor((Spot.Z + Spread) / Map.Cell) do
							Dynamic[(Cx + 1048576) * 2097152 + Cz + 1048576] = true
						end
					end
					DynamicUntil = os.clock() + 6
					Drive, Plan = nil, nil
					Reach += 30
					Report("Blocked")
				end
			end

			if Abs(Throttle) > 0.3 and Abs(Speed) < 0.8 then
				StuckSince = StuckSince or Now
				if Now - StuckSince > (Options.StuckTime or 2) then
					StuckSince = nil
					if Near <= (Arrive * 3) ^ 2 then
						Input.Set(0, 0)
						Handle:Finish("Done", Plan)
						return
					end
					Stucks += 1
					if Stucks >= (Options.MaxStucks or 5) then Handle:Finish("Failed", Plan, "Stuck"); return end
					Map:Invalidate(Position.X - 40, Position.Z - 40, Position.X + 40, Position.Z + 40)
					Drive, Plan = nil, nil
					Report("Unsticking")
				end
			else
				StuckSince = nil
			end

			if Drive then Input.Set(Steer, Throttle) end
		end
	end

	return Pathfinding.Spawn(function(Handle)
		local Ok, Err = pcall(Run, Handle)
		Input.Finish()
		if not Ok then Handle:Finish("Failed", nil, Err) end
	end)
end

return Driver
end
Modules.FixtureSource = function(Require)
local FixtureSource = {}
FixtureSource.__index = FixtureSource

function FixtureSource.new(Data)
	return setmetatable({ Data = Data }, FixtureSource)
end

function FixtureSource:Sample(Info, Emit)
	local Tile = self.Data.Tiles[`{Info.Tx},{Info.Tz}`]
	if not Tile then return end
	for Column, List in next, Tile do
		for Index = 1, #List, 3 do
			Emit(Column, List[Index], List[Index + 1], List[Index + 2])
		end
	end
end

function FixtureSource.Capture(Source, Map, MinX, MinZ, MaxX, MaxZ, Yield)
	local Ax, Az = Map:TileOf(MinX, MinZ)
	local Bx, Bz = Map:TileOf(MaxX, MaxZ)
	local Size, Cell = Map.Size, Map.Cell
	local Tiles = {}
	for Tz = Az, Bz do
		for Tx = Ax, Bx do
			local Columns = {}
			local Info = { Tx = Tx, Tz = Tz, X0 = Tx * Size * Cell, Z0 = Tz * Size * Cell, Size = Size, Cell = Cell, MinY = Map.MinY, MaxY = Map.MaxY }
			Source:Sample(Info, function(Column, Bottom, Top, Code)
				local List = Columns[Column]
				if not List then
					List = {}
					Columns[Column] = List
				end
				List[#List + 1] = Bottom
				List[#List + 1] = Top
				List[#List + 1] = Code
			end, Yield)
			Tiles[`{Tx},{Tz}`] = Columns
		end
	end
	return { Cell = Cell, Size = Size, Tiles = Tiles }
end

local function Number(Value)
	if Value == math.huge then return "math.huge" end
	if Value == -math.huge then return "-math.huge" end
	return string.format("%.3f", Value):gsub("%.?0+$", "")
end

function FixtureSource.Serialize(Data)
	local Parts = { "return { Cell = ", tostring(Data.Cell), ", Size = ", tostring(Data.Size), ", Tiles = {\n" }
	for Key, Columns in next, Data.Tiles do
		Parts[#Parts + 1] = `["{Key}"] = \{`
		for Column, List in next, Columns do
			local Values = table.create(#List)
			for Index = 1, #List do Values[Index] = Number(List[Index]) end
			Parts[#Parts + 1] = `[{Column}] = \{{table.concat(Values, ",")}},`
		end
		Parts[#Parts + 1] = "},\n"
	end
	Parts[#Parts + 1] = "} }\n"
	return table.concat(Parts)
end

return FixtureSource
end
Modules.Geometry = function(Require)
local Geometry = {}

local Abs, Min, Max, Sqrt, Huge = math.abs, math.min, math.max, math.sqrt, math.huge
local Epsilon = 1e-9

Geometry.Block = 1
Geometry.Wedge = 2
Geometry.CornerWedge = 3
Geometry.Cylinder = 4
Geometry.Ball = 5
Geometry.Mesh = 6

function Geometry.Shape(Kind, X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22, Sx, Sy, Sz, Surface)
	local Hx, Hy, Hz = Sx * 0.5, Sy * 0.5, Sz * 0.5
	local Ex, Ey, Ez
	if Kind == 5 then
		local Radius = Min(Hx, Hy, Hz)
		Ex, Ey, Ez = Radius, Radius, Radius
	else
		Ex = Abs(R00) * Hx + Abs(R01) * Hy + Abs(R02) * Hz
		Ey = Abs(R10) * Hx + Abs(R11) * Hy + Abs(R12) * Hz
		Ez = Abs(R20) * Hx + Abs(R21) * Hy + Abs(R22) * Hz
	end
	return {
		Kind = Kind,
		X = X,
		Y = Y,
		Z = Z,
		R00 = R00,
		R01 = R01,
		R02 = R02,
		R10 = R10,
		R11 = R11,
		R12 = R12,
		R20 = R20,
		R21 = R21,
		R22 = R22,
		Hx = Hx,
		Hy = Hy,
		Hz = Hz,
		MinX = X - Ex,
		MaxX = X + Ex,
		MinY = Y - Ey,
		MaxY = Y + Ey,
		MinZ = Z - Ez,
		MaxZ = Z + Ez,
		Upright = Abs(R11) > 0.9999,
		Surface = Surface,
	}
end

local function Slab(L0, U, H, Lo, Hi)
	if U > Epsilon or U < -Epsilon then
		local A, B = (-H - L0) / U, (H - L0) / U
		if A > B then A, B = B, A end
		if A > Lo then Lo = A end
		if B < Hi then Hi = B end
		return Lo, Hi
	end
	if L0 < -H or L0 > H then return 1, 0 end
	return Lo, Hi
end

local function HalfSpace(C0, C1, Lo, Hi)
	if C1 > Epsilon then
		local Limit = -C0 / C1
		if Limit < Hi then Hi = Limit end
	elseif C1 < -Epsilon then
		local Limit = -C0 / C1
		if Limit > Lo then Lo = Limit end
	elseif C0 > 0 then
		return 1, 0
	end
	return Lo, Hi
end

function Geometry.VerticalRange(S, Px, Pz)
	local Dx, Dz = Px - S.X, Pz - S.Z
	local Lx = S.R00 * Dx + S.R20 * Dz
	local Ly = S.R01 * Dx + S.R21 * Dz
	local Lz = S.R02 * Dx + S.R22 * Dz
	local Ux, Uy, Uz = S.R10, S.R11, S.R12
	local Kind = S.Kind
	local Lo, Hi = -Huge, Huge
	if Kind == 4 then
		Lo, Hi = Slab(Lx, Ux, S.Hx, Lo, Hi)
		if Lo > Hi then return nil end
		local Radius = Min(S.Hy, S.Hz)
		local A = Uy * Uy + Uz * Uz
		local C = Ly * Ly + Lz * Lz - Radius * Radius
		if A < Epsilon then
			if C > 0 then return nil end
		else
			local B = 2 * (Ly * Uy + Lz * Uz)
			local D = B * B - 4 * A * C
			if D < 0 then return nil end
			local Root = Sqrt(D)
			local S1, S2 = (-B - Root) / (2 * A), (-B + Root) / (2 * A)
			if S1 > Lo then Lo = S1 end
			if S2 < Hi then Hi = S2 end
		end
	elseif Kind == 5 then
		local Radius = Min(S.Hx, S.Hy, S.Hz)
		local B = 2 * (Lx * Ux + Ly * Uy + Lz * Uz)
		local C = Lx * Lx + Ly * Ly + Lz * Lz - Radius * Radius
		local D = B * B - 4 * C
		if D < 0 then return nil end
		local Root = Sqrt(D)
		Lo, Hi = (-B - Root) * 0.5, (-B + Root) * 0.5
	else
		local Hx, Hy, Hz = S.Hx, S.Hy, S.Hz
		Lo, Hi = Slab(Lx, Ux, Hx, Lo, Hi)
		Lo, Hi = Slab(Ly, Uy, Hy, Lo, Hi)
		Lo, Hi = Slab(Lz, Uz, Hz, Lo, Hi)
		if Lo > Hi then return nil end
		if Kind == 2 then
			Lo, Hi = HalfSpace(Ly * Hz - Lz * Hy, Uy * Hz - Uz * Hy, Lo, Hi)
		elseif Kind == 3 then
			Lo, Hi = HalfSpace(Ly * Hx - Lx * Hy, Uy * Hx - Ux * Hy, Lo, Hi)
			Lo, Hi = HalfSpace(Ly * Hz + Lz * Hy, Uy * Hz + Uz * Hy, Lo, Hi)
		end
	end
	if Lo > Hi then return nil end
	return S.Y + Lo, S.Y + Hi
end

local function Cross(Ox, Oz, Ax, Az, Bx, Bz)
	return (Ax - Ox) * (Bz - Oz) - (Az - Oz) * (Bx - Ox)
end

function Geometry.Footprint(S)
	local Xs, Zs = {}, {}
	if S.Kind == 5 then
		local Radius = S.MaxX - S.X
		Xs[1], Zs[1] = S.X - Radius, S.Z - Radius
		Xs[2], Zs[2] = S.X + Radius, S.Z - Radius
		Xs[3], Zs[3] = S.X + Radius, S.Z + Radius
		Xs[4], Zs[4] = S.X - Radius, S.Z + Radius
		return Xs, Zs, 4
	end
	local Ax, Az = S.R00 * S.Hx, S.R20 * S.Hx
	local Bx, Bz = S.R01 * S.Hy, S.R21 * S.Hy
	local Cx, Cz = S.R02 * S.Hz, S.R22 * S.Hz
	if S.Upright then
		local X, Z = S.X, S.Z
		Xs[1], Zs[1] = X + Ax + Cx, Z + Az + Cz
		Xs[2], Zs[2] = X - Ax + Cx, Z - Az + Cz
		Xs[3], Zs[3] = X - Ax - Cx, Z - Az - Cz
		Xs[4], Zs[4] = X + Ax - Cx, Z + Az - Cz
		return Xs, Zs, 4
	end
	local Px, Pz = table.create(8), table.create(8)
	local Count = 0
	for Sa = -1, 1, 2 do
		for Sb = -1, 1, 2 do
			for Sc = -1, 1, 2 do
				Count += 1
				Px[Count] = S.X + Sa * Ax + Sb * Bx + Sc * Cx
				Pz[Count] = S.Z + Sa * Az + Sb * Bz + Sc * Cz
			end
		end
	end
	local Order = table.create(8)
	for I = 1, 8 do Order[I] = I end
	table.sort(Order, function(A, B)
		if Px[A] ~= Px[B] then return Px[A] < Px[B] end
		return Pz[A] < Pz[B]
	end)
	local Hull = {}
	local Size = 0
	for I = 1, 8 do
		local Index = Order[I]
		while Size >= 2 and Cross(Px[Hull[Size - 1]], Pz[Hull[Size - 1]], Px[Hull[Size]], Pz[Hull[Size]], Px[Index], Pz[Index]) <= 0 do
			Hull[Size] = nil
			Size -= 1
		end
		Size += 1
		Hull[Size] = Index
	end
	local Lower = Size + 1
	for I = 7, 1, -1 do
		local Index = Order[I]
		while Size >= Lower and Cross(Px[Hull[Size - 1]], Pz[Hull[Size - 1]], Px[Hull[Size]], Pz[Hull[Size]], Px[Index], Pz[Index]) <= 0 do
			Hull[Size] = nil
			Size -= 1
		end
		Size += 1
		Hull[Size] = Index
	end
	Size -= 1
	if Size < 3 then
		Xs[1], Zs[1] = S.MinX, S.MinZ
		Xs[2], Zs[2] = S.MaxX, S.MinZ
		Xs[3], Zs[3] = S.MaxX, S.MaxZ
		Xs[4], Zs[4] = S.MinX, S.MaxZ
		return Xs, Zs, 4
	end
	for I = 1, Size do
		Xs[I], Zs[I] = Px[Hull[I]], Pz[Hull[I]]
	end
	return Xs, Zs, Size
end

function Geometry.RowSpan(Xs, Zs, Count, ZLow, ZHigh)
	local MinX, MaxX = Huge, -Huge
	for I = 1, Count do
		local J = I == Count and 1 or I + 1
		local Ax, Az, Bx, Bz = Xs[I], Zs[I], Xs[J], Zs[J]
		if Az > Bz then
			Ax, Az, Bx, Bz = Bx, Bz, Ax, Az
		end
		if Bz >= ZLow and Az <= ZHigh then
			local Dz = Bz - Az
			local X1, X2
			if Dz < Epsilon then
				X1, X2 = Ax, Bx
			else
				local Slope = (Bx - Ax) / Dz
				X1 = Ax + (Max(Az, ZLow) - Az) * Slope
				X2 = Ax + (Min(Bz, ZHigh) - Az) * Slope
			end
			if X1 < MinX then MinX = X1 end
			if X1 > MaxX then MaxX = X1 end
			if X2 < MinX then MinX = X2 end
			if X2 > MaxX then MaxX = X2 end
		end
	end
	if MinX > MaxX then return nil end
	return MinX, MaxX
end

function Geometry.IsThin(S, Limit)
	if S.Kind == 5 then return (S.MaxX - S.X) * 2 < Limit end
	return (S.Hx * 2 < Limit and Abs(S.R10) < 0.7) or (S.Hy * 2 < Limit and Abs(S.R11) < 0.7) or (S.Hz * 2 < Limit and Abs(S.R12) < 0.7)
end

function Geometry.Rotation(Yaw)
	local C, S = math.cos(Yaw), math.sin(Yaw)
	return C, 0, S, 0, 1, 0, -S, 0, C
end

return Geometry
end
Modules.GridSearch = function(Require)
local Heap = Require("Heap")
local Regions = Require("Regions")

local GridSearch = {}

local Abs, Sqrt, Floor, Ceil, Min, Max, Huge = math.abs, math.sqrt, math.floor, math.ceil, math.min, math.max, math.huge
local Shift = 65536
local Root2 = math.sqrt(2)
local Octile = Root2 - 1
local MakeVector = (vector and vector.create) or (Vector3 and Vector3.new)

function GridSearch.Context(Map, Agent, Options, Yield)
	Options = Options or {}
	local Profile = Agent.Profile
	local Size, Cell = Map.Size, Map.Cell
	local Radius = Options.Radius or Agent.Radius
	local Costs = Agent.CostArray
	local Blocked = Options.Blocked
	local Entries = {}
	local Context = {
		Map = Map,
		Agent = Agent,
		Size = Size,
		Cell = Cell,
		Radius = Radius,
		Costs = Costs,
		Entries = Entries,
		Yield = Yield,
		Blocked = Blocked,
	}

	local function Load(Key)
		local Entry = Entries[Key]
		if not Entry then
			local Tile, Data = Map:Ready(Key, Profile, Yield)
			Entry = { Tile, Data }
			Entries[Key] = Entry
		end
		return Entry
	end

	local function Step(Key, Tile, Data, Span, Dir)
		local Column = Tile.Column[Span] - 1
		local Lz = Column // Size
		local Lx = Column - Lz * Size
		local N
		if Dir == 1 then
			N = Data.E[Span]
			if N ~= 0 and Lx == Size - 1 then return Key + Shift, N end
		elseif Dir == 2 then
			N = Data.W[Span]
			if N ~= 0 and Lx == 0 then return Key - Shift, N end
		elseif Dir == 3 then
			N = Data.S[Span]
			if N ~= 0 and Lz == Size - 1 then return Key + 1, N end
		else
			N = Data.N[Span]
			if N ~= 0 and Lz == 0 then return Key - 1, N end
		end
		return Key, N
	end

	local function Cells(Tile, Span)
		local Column = Tile.Column[Span] - 1
		local Lz = Column // Size
		return Tile.Tx * Size + Column - Lz * Size, Tile.Tz * Size + Lz
	end

	local function IsBlocked(Cx, Cz)
		return Blocked ~= nil and Blocked[(Cx + 1048576) * 2097152 + Cz + 1048576] == true
	end

	local function Usable(Key, Span, Need)
		local Entry = Entries[Key] or Load(Key)
		local Tile = Entry[1]
		if Entry[2].Clear[Span] < Need then return false end
		if Costs[Tile.Surface[Span]] == Huge then return false end
		if Blocked then
			local Cx, Cz = Cells(Tile, Span)
			if IsBlocked(Cx, Cz) then return false end
		end
		return true
	end

	local function Nearest(X, Y, Z, Below, Above, Limit)
		local Key, Span = Map:Locate(X, Y, Z, Profile, Yield, Below, Above)
		if not Key then return nil end
		if Usable(Key, Span, Radius) then return Key, Span end
		local First = Key * Shift + Span
		local Queue, Seen = { First }, { [First] = true }
		local Head = 1
		while Head <= #Queue and Head <= (Limit or 600) do
			local Node = Queue[Head]
			Head += 1
			local K = Node // Shift
			local S = Node - K * Shift
			if Usable(K, S, Radius) then return K, S end
			local Entry = Entries[K] or Load(K)
			for Dir = 1, 4 do
				local NK, NS = Step(K, Entry[1], Entry[2], S, Dir)
				if NS ~= 0 then
					local Next = NK * Shift + NS
					if not Seen[Next] then
						Seen[Next] = true
						Queue[#Queue + 1] = Next
					end
				end
			end
		end
		return nil
	end

	local function Relocate(X, Y, Z, Reach, Below, Above)
		local Cx0, Cz0 = Floor(X / Cell), Floor(Z / Cell)
		local Rings = Ceil(Reach / Cell)
		local Upper, Lower = Y + (Above or 1.5), Y - (Below or 10)
		local BestKey, BestSpan, BestDistance = nil, nil, Huge
		for Ring = 0, Rings do
			if BestKey and BestDistance <= (Ring - 0.5) * Cell then break end
			if Yield then Yield() end
			for Dz = -Ring, Ring do
				local Edge = Dz == -Ring or Dz == Ring
				local Dx = -Ring
				while Dx <= Ring do
					local Cx, Cz = Cx0 + Dx, Cz0 + Dz
					local Tx, Tz = Cx // Size, Cz // Size
					local Key = (Tx + 32768) * Shift + (Tz + 32768)
					local Entry = Entries[Key] or Load(Key)
					local Tile = Entry[1]
					local Column = (Cz - Tz * Size) * Size + (Cx - Tx * Size) + 1
					local Count = Tile.Count[Column]
					if Count > 0 then
						local First = Tile.First[Column]
						for Span = First, First + Count - 1 do
							local Value = Tile.Floor[Span]
							if Value <= Upper and Value >= Lower and Usable(Key, Span, Radius) then
								local Px, Pz = (Cx + 0.5) * Cell - X, (Cz + 0.5) * Cell - Z
								local Distance = Sqrt(Px * Px + Pz * Pz)
								if Distance < BestDistance then BestKey, BestSpan, BestDistance = Key, Span, Distance end
							end
						end
					end
					if Edge or Ring == 0 then
						Dx += 1
					else
						Dx += 2 * Ring
					end
				end
			end
		end
		return BestKey, BestSpan, BestDistance
	end

	local function Visible(A, B, CostLimit, Margin, Slack)
		local KeyA = A // Shift
		local SpanA = A - KeyA * Shift
		local KeyB = B // Shift
		local SpanB = B - KeyB * Shift
		local EntryA = Entries[KeyA] or Load(KeyA)
		local EntryB = Entries[KeyB] or Load(KeyB)
		local Ax, Az = Cells(EntryA[1], SpanA)
		local Bx, Bz = Cells(EntryB[1], SpanB)
		local Ya, Yb = EntryA[1].Floor[SpanA], EntryB[1].Floor[SpanB]
		local Dx, Dz = Bx - Ax, Bz - Az
		local DirX = Dx > 0 and 1 or 2
		local DirZ = Dz > 0 and 3 or 4
		local Nx, Nz = Abs(Dx), Abs(Dz)
		local Total = Nx + Nz
		local Need = Radius + Margin
		local Ix, Iz = 0, 0
		local Key, Span, Entry = KeyA, SpanA, EntryA
		while Ix < Nx or Iz < Nz do
			local Lhs, Rhs = (1 + 2 * Ix) * Nz, (1 + 2 * Iz) * Nx
			if Lhs < Rhs then
				Key, Span = Step(Key, Entry[1], Entry[2], Span, DirX)
				Ix += 1
			elseif Lhs > Rhs then
				Key, Span = Step(Key, Entry[1], Entry[2], Span, DirZ)
				Iz += 1
			else
				local K1, S1 = Step(Key, Entry[1], Entry[2], Span, DirX)
				local K2, S2 = Step(Key, Entry[1], Entry[2], Span, DirZ)
				if S1 == 0 or S2 == 0 then return false end
				local E1, E2 = Entries[K1] or Load(K1), Entries[K2] or Load(K2)
				if E1[2].Clear[S1] < Need or E2[2].Clear[S2] < Need then return false end
				local K3, S3 = Step(K1, E1[1], E1[2], S1, DirZ)
				local K4, S4 = Step(K2, E2[1], E2[2], S2, DirX)
				if S3 == 0 or K3 ~= K4 or S3 ~= S4 then return false end
				Key, Span = K3, S3
				Ix += 1
				Iz += 1
			end
			if Span == 0 then return false end
			Entry = Entries[Key] or Load(Key)
			local Tile = Entry[1]
			if Entry[2].Clear[Span] < Need then return false end
			if Costs[Tile.Surface[Span]] > CostLimit then return false end
			if Abs(Tile.Floor[Span] - (Ya + (Yb - Ya) * (Ix + Iz) / Total)) > Slack then return false end
			if Blocked then
				local Cx, Cz = Cells(Tile, Span)
				if IsBlocked(Cx, Cz) then return false end
			end
		end
		return Key == KeyB and Span == SpanB
	end

	Context.Load = Load
	Context.Step = Step
	Context.Cells = Cells
	Context.Usable = Usable
	Context.Nearest = Nearest
	Context.Relocate = Relocate
	Context.Visible = Visible
	Context.IsBlocked = IsBlocked
	return Context
end

function GridSearch.Find(Map, Agent, From, To, Options, Yield)
	Options = Options or {}
	local Started = Map.Clock()
	local Context = GridSearch.Context(Map, Agent, Options, Yield)
	local Load, Step, Nearest, Visible, Entries = Context.Load, Context.Step, Context.Nearest, Context.Visible, Context.Entries
	local Size, Cell, Radius, Costs, Blocked = Context.Size, Context.Cell, Context.Radius, Context.Costs, Context.Blocked
	local MaxNodes = Options.MaxNodes or 60000
	local Weight = Options.Weight or 1
	local Comfort = Options.Comfort or 1
	local ProximityWeight = Options.ProximityWeight or 2
	local ClimbWeight = Options.ClimbWeight or 0.5
	local Tolerance = Options.Tolerance or Radius + 2
	local VerticalTolerance = Options.VerticalTolerance or 5

	local SKey, SSpan = Nearest(From.X, From.Y, From.Z, Options.Below, Options.Above)
	if not SKey then
		return { Status = "NoStart", Complete = false, Points = {}, Expanded = 0, Time = Map.Clock() - Started }
	end

	local GoalX, GoalY, GoalZ = To.X, To.Y, To.Z
	local TargetX, TargetZ = GoalX, GoalZ
	local GoalNode, Relocated
	do
		local GKey, GSpan = Map:Locate(GoalX, GoalY, GoalZ, Agent.Profile, Yield, Options.Below, Options.Above)
		if GKey and Context.Usable(GKey, GSpan, Radius) then
			GoalNode = GKey * Shift + GSpan
		elseif Options.Relocate ~= false then
			local Distance
			GKey, GSpan, Distance = Context.Relocate(GoalX, GoalY, GoalZ, Options.RelocateRadius or 24, Options.Below, Options.Above)
			if GKey then
				GoalNode = GKey * Shift + GSpan
				Relocated = Distance
				local X, _, Z = Map:Position(Entries[GKey][1], GSpan)
				TargetX, TargetZ = X, Z
			end
		end
	end

	local Corridor, Unreachable, Abstract
	if not GoalNode then
		MaxNodes = Min(MaxNodes, Options.ClosestNodes or 15000)
		Weight = Max(Weight, 1.5)
	end

	local MinCost = Huge
	for Index = 1, #Costs do
		if Costs[Index] < MinCost then MinCost = Costs[Index] end
	end
	local Scale = MinCost * Weight

	local Open = Heap.new()
	local Push, Pop, OpenSize = Open.Push, Open.Pop, Open.Size
	local G, Parent, Closed = {}, {}, {}

	local CurrentNode, CurrentBase, CurrentCost, CurrentY = 0, 0, 0, 0
	local BMinX, BMaxX, BMinZ, BMaxZ = -Huge, Huge, -Huge, Huge
	local Clipped = false

	local function Consider(NKey, NSpan, Unit)
		if Corridor and not Corridor[NKey] then
			Clipped = true
			return
		end
		local Entry = Entries[NKey] or Load(NKey)
		local NTile, NData = Entry[1], Entry[2]
		local Clear = NData.Clear[NSpan]
		if Clear < Radius then return end
		local NNode = NKey * Shift + NSpan
		if Closed[NNode] then return end
		local NCost = Costs[NTile.Surface[NSpan]]
		if NCost == Huge then return end
		local Column = NTile.Column[NSpan] - 1
		local Lz = Column // Size
		local Cx, Cz = NTile.Tx * Size + Column - Lz * Size, NTile.Tz * Size + Lz
		if Cx < BMinX or Cx > BMaxX or Cz < BMinZ or Cz > BMaxZ then
			Clipped = true
			return
		end
		if Blocked and Blocked[(Cx + 1048576) * 2097152 + Cz + 1048576] then return end
		local NY = NTile.Floor[NSpan]
		local Cost = CurrentBase + Unit * Cell * (CurrentCost + NCost) * 0.5 + Abs(NY - CurrentY) * ClimbWeight
		if Clear < Radius + Comfort then Cost += (Radius + Comfort - Clear) * ProximityWeight * Unit end
		local Old = G[NNode]
		if Old and Old <= Cost then return end
		G[NNode] = Cost
		Parent[NNode] = CurrentNode
		local Dx, Dz = Abs((Cx + 0.5) * Cell - TargetX), Abs((Cz + 0.5) * Cell - TargetZ)
		if Dx > Dz then
			Push(NNode, Cost + (Dx + Octile * Dz) * Scale)
		else
			Push(NNode, Cost + (Dz + Octile * Dx) * Scale)
		end
	end

	local Start = SKey * Shift + SSpan
	local BestNode, BestDistance = Start, Huge
	local Found
	local Expanded = 0
	local Stopped
	local StartX, _, StartZ = Map:Position((Entries[SKey] or Load(SKey))[1], SSpan)
	local Margin = Options.Margin or Max(48, Sqrt((StartX - TargetX) ^ 2 + (StartZ - TargetZ) ^ 2) * 0.75)
	local MaxMargin = Options.MaxMargin or 1536
	if not GoalNode then MaxMargin = Margin end

	local function Bound()
		if Margin < Huge then
			BMinX = (Min(StartX, TargetX) - Margin) // Cell
			BMaxX = (Max(StartX, TargetX) + Margin) // Cell
			BMinZ = (Min(StartZ, TargetZ) - Margin) // Cell
			BMaxZ = (Max(StartZ, TargetZ) + Margin) // Cell
		else
			BMinX, BMaxX, BMinZ, BMaxZ = -Huge, Huge, -Huge, Huge
		end
		Clipped = false
		BestNode, BestDistance = Start, Huge
		Open.Clear()
		table.clear(G)
		table.clear(Parent)
		table.clear(Closed)
		G[Start] = 0
		Push(Start, 0)
	end

	local function Run(Budget)
		local Used = 0
		while true do
			if OpenSize() == 0 then
				if Corridor and not Unreachable and Clipped then
					Corridor = nil
					Margin = Max(48, Sqrt((StartX - TargetX) ^ 2 + (StartZ - TargetZ) ^ 2) * 0.75)
					MaxMargin = Options.MaxMargin or 1536
					Bound()
				elseif Clipped and not Corridor and Margin < MaxMargin then
					Margin = Min(MaxMargin, Margin * 3)
					Bound()
				else
					if not Clipped then Unreachable = true end
					return "Exhausted"
				end
			end
			if Used >= Budget then return "Budget" end
			local Node = Pop()
			if not Closed[Node] then
				Closed[Node] = true
				Expanded += 1
				Used += 1
				if Expanded % 128 == 0 and Yield and not Yield() then
					Stopped = "Timeout"
					return "Stopped"
				end
				if Expanded > MaxNodes then
					Stopped = "Limit"
					return "Stopped"
				end
				local Key = Node // Shift
				local Span = Node - Key * Shift
				local Entry = Entries[Key] or Load(Key)
				local Tile, Data = Entry[1], Entry[2]
				local Column = Tile.Column[Span] - 1
				local Lz = Column // Size
				local X = (Tile.Tx * Size + Column - Lz * Size + 0.5) * Cell
				local Z = (Tile.Tz * Size + Lz + 0.5) * Cell
				local Y = Tile.Floor[Span]
				local Dx, Dz = X - GoalX, Z - GoalZ
				local Planar = Sqrt(Dx * Dx + Dz * Dz)
				if Planar < BestDistance then BestNode, BestDistance = Node, Planar end
				if Node == GoalNode or (not GoalNode and Planar <= Tolerance and Abs(Y - GoalY) <= VerticalTolerance) then
					Found = Node
					return "Found"
				end
				CurrentNode, CurrentBase, CurrentCost, CurrentY = Node, G[Node], Costs[Tile.Surface[Span]], Y
				local EK, ES = Step(Key, Tile, Data, Span, 1)
				local WK, WS = Step(Key, Tile, Data, Span, 2)
				local SK, SS = Step(Key, Tile, Data, Span, 3)
				local NK, NS = Step(Key, Tile, Data, Span, 4)
				local EOk = ES ~= 0 and (not Corridor or Corridor[EK]) and (Entries[EK] or Load(EK))[2].Clear[ES] >= Radius
				local WOk = WS ~= 0 and (not Corridor or Corridor[WK]) and (Entries[WK] or Load(WK))[2].Clear[WS] >= Radius
				local SOk = SS ~= 0 and (not Corridor or Corridor[SK]) and (Entries[SK] or Load(SK))[2].Clear[SS] >= Radius
				local NOk = NS ~= 0 and (not Corridor or Corridor[NK]) and (Entries[NK] or Load(NK))[2].Clear[NS] >= Radius
				if EOk then Consider(EK, ES, 1) end
				if WOk then Consider(WK, WS, 1) end
				if SOk then Consider(SK, SS, 1) end
				if NOk then Consider(NK, NS, 1) end
				if EOk and SOk then
					local E1, E2 = Entries[EK], Entries[SK]
					local K1, S1 = Step(EK, E1[1], E1[2], ES, 3)
					local K2, S2 = Step(SK, E2[1], E2[2], SS, 1)
					if S1 ~= 0 and K1 == K2 and S1 == S2 then Consider(K1, S1, Root2) end
				end
				if EOk and NOk then
					local E1, E2 = Entries[EK], Entries[NK]
					local K1, S1 = Step(EK, E1[1], E1[2], ES, 4)
					local K2, S2 = Step(NK, E2[1], E2[2], NS, 1)
					if S1 ~= 0 and K1 == K2 and S1 == S2 then Consider(K1, S1, Root2) end
				end
				if WOk and SOk then
					local E1, E2 = Entries[WK], Entries[SK]
					local K1, S1 = Step(WK, E1[1], E1[2], WS, 3)
					local K2, S2 = Step(SK, E2[1], E2[2], SS, 2)
					if S1 ~= 0 and K1 == K2 and S1 == S2 then Consider(K1, S1, Root2) end
				end
				if WOk and NOk then
					local E1, E2 = Entries[WK], Entries[NK]
					local K1, S1 = Step(WK, E1[1], E1[2], WS, 4)
					local K2, S2 = Step(NK, E2[1], E2[2], NS, 2)
					if S1 ~= 0 and K1 == K2 and S1 == S2 then Consider(K1, S1, Root2) end
				end
			end
		end
	end

	Bound()
	local Direct = false
	if GoalNode and Options.Direct ~= false then
		local GoalKey = GoalNode // Shift
		local StartCost = Costs[(Entries[SKey] or Load(SKey))[1].Surface[SSpan]]
		local GoalCost = Costs[(Entries[GoalKey] or Load(GoalKey))[1].Surface[GoalNode - GoalKey * Shift]]
		if Visible(Start, GoalNode, Max(StartCost, GoalCost) * (Options.SmoothCostSlack or 1.3) + 1e-6, Options.SmoothMargin or Cell * 0.5, Options.VerticalSlack or 1) then
			Found = GoalNode
			Parent[GoalNode] = Start
			Direct = true
		end
	end

	local function GiveUpOnGoal()
		Unreachable = true
		GoalNode = nil
		TargetX, TargetZ = GoalX, GoalZ
	end

	if not Found then
		if GoalNode and Options.Hierarchical ~= false then
			local GoalKey = GoalNode // Shift
			local GoalSpan = GoalNode - GoalKey * Shift
			if Run(Options.QuickNodes or 4000) == "Budget" then
				Abstract = Regions.Flood(Context, GoalKey, GoalSpan, SKey, SSpan, Options.ProbeRegions or 12)
				if Abstract == "Exhausted" then
					GiveUpOnGoal()
					MaxMargin = Margin
					Bound()
					Run(Huge)
				elseif Run(Options.SlowNodes or 30000) == "Budget" then
					local Value, Status, Extra = Regions.Corridor(Context, SKey, SSpan, GoalKey, GoalSpan, Options)
					Abstract = Status
					if Status == "Found" then
						Corridor = Value
					elseif Status == "Unreachable" then
						Corridor = Extra
						GiveUpOnGoal()
					end
					if Corridor then
						Margin, MaxMargin = Huge, Huge
						Bound()
					end
					Run(Huge)
				end
			end
		else
			Run(Huge)
		end
	end

	local Target = Found or BestNode
	local Chain = {}
	local Node = Target
	while Node do
		Chain[#Chain + 1] = Node
		Node = Parent[Node]
	end
	local Count = #Chain
	for Index = 1, Count // 2 do
		Chain[Index], Chain[Count - Index + 1] = Chain[Count - Index + 1], Chain[Index]
	end

	local NodeCost = table.create(Count)
	for Index = 1, Count do
		local K = Chain[Index] // Shift
		local Entry = Entries[K] or Load(K)
		NodeCost[Index] = Costs[Entry[1].Surface[Chain[Index] - K * Shift]]
	end

	local Kept = { 1 }
	if Options.Smooth ~= false and Count > 2 then
		local SmoothMargin = Options.SmoothMargin or Cell * 0.5
		local Slack = Options.VerticalSlack or 1
		local CostSlack = Options.SmoothCostSlack or 1.3
		local function Limit(A, B)
			local Value = 0
			for Index = A, B do
				if NodeCost[Index] > Value then Value = NodeCost[Index] end
			end
			return Value * CostSlack + 1e-6
		end
		local Anchor = 1
		while Anchor < Count do
			local Good, Bad = Anchor + 1, nil
			local Stride = 2
			while true do
				local Probe = Min(Anchor + Stride, Count)
				if Probe <= Good then break end
				if Visible(Chain[Anchor], Chain[Probe], Limit(Anchor, Probe), SmoothMargin, Slack) then
					Good = Probe
					if Probe == Count then break end
					Stride *= 2
				else
					Bad = Probe
					break
				end
			end
			if Bad then
				while Bad - Good > 1 do
					local Middle = (Good + Bad) // 2
					if Visible(Chain[Anchor], Chain[Middle], Limit(Anchor, Middle), SmoothMargin, Slack) then
						Good = Middle
					else
						Bad = Middle
					end
				end
			end
			Kept[#Kept + 1] = Good
			Anchor = Good
			if Yield then Yield() end
		end
	else
		for Index = 2, Count do Kept[Index] = Index end
	end

	local Points = table.create(#Kept)
	local Length = 0
	local LastX, LastY, LastZ
	for Index = 1, #Kept do
		local Chosen = Chain[Kept[Index]]
		local K = Chosen // Shift
		local Entry = Entries[K] or Load(K)
		local X, Y, Z = Map:Position(Entry[1], Chosen - K * Shift)
		if Index == 1 and Abs(From.X - X) <= Cell * 0.5 and Abs(From.Z - Z) <= Cell * 0.5 then
			X, Z = From.X, From.Z
		elseif Index == #Kept and Found and not Relocated and Abs(GoalX - X) <= Cell * 0.5 and Abs(GoalZ - Z) <= Cell * 0.5 then
			X, Z = GoalX, GoalZ
		end
		if LastX then
			local Dx, Dy, Dz = X - LastX, Y - LastY, Z - LastZ
			Length += Sqrt(Dx * Dx + Dy * Dy + Dz * Dz)
		end
		LastX, LastY, LastZ = X, Y, Z
		Points[Index] = MakeVector(X, Y, Z)
	end

	local Status = "Complete"
	if not Found then
		Status = Stopped or (Unreachable and "Unreachable") or "Partial"
	elseif Relocated then
		Status = "Relocated"
	end
	return {
		Status = Status,
		Complete = Found ~= nil,
		Points = Points,
		Length = Length,
		Nodes = Count,
		Expanded = Expanded,
		Time = Map.Clock() - Started,
		Distance = Found and (Relocated or 0) or BestDistance,
		Relocated = Relocated,
		Abstract = Abstract,
		Direct = Direct,
	}
end

return GridSearch
end
Modules.Heap = function(Require)
local Heap = {}

function Heap.new()
	local Items, Keys, Size = {}, {}, 0
	local Object = {}

	function Object.Push(Item, Key)
		Size += 1
		local Index = Size
		while Index > 1 do
			local Parent = Index // 2
			local ParentKey = Keys[Parent]
			if ParentKey <= Key then break end
			Items[Index] = Items[Parent]
			Keys[Index] = ParentKey
			Index = Parent
		end
		Items[Index] = Item
		Keys[Index] = Key
	end

	function Object.Pop()
		if Size == 0 then return nil end
		local Top, TopKey = Items[1], Keys[1]
		local LastItem, LastKey = Items[Size], Keys[Size]
		Size -= 1
		if Size > 0 then
			local Index = 1
			while true do
				local Child = Index * 2
				if Child > Size then break end
				local ChildKey = Keys[Child]
				if Child < Size then
					local RightKey = Keys[Child + 1]
					if RightKey < ChildKey then
						Child += 1
						ChildKey = RightKey
					end
				end
				if ChildKey >= LastKey then break end
				Items[Index] = Items[Child]
				Keys[Index] = ChildKey
				Index = Child
			end
			Items[Index] = LastItem
			Keys[Index] = LastKey
		end
		return Top, TopKey
	end

	function Object.Size()
		return Size
	end

	function Object.TopKey()
		return Size > 0 and Keys[1] or nil
	end

	function Object.Clear()
		Size = 0
		table.clear(Items)
		table.clear(Keys)
	end

	return Object
end

return Heap
end
Modules.Init = function(Require)
local Surface = Require("Surface")
local Geometry = Require("Geometry")
local Agent = Require("Agent")
local World = Require("World")
local GridSearch = Require("GridSearch")
local SchedulerModule = Require("Scheduler")
local ShapeSource = Require("ShapeSource")

local IsRoblox = typeof ~= nil and game ~= nil and typeof(game) == "Instance"

local Pathfinding = {
	Version = "0.1.0",
	IsRoblox = IsRoblox,
	Surface = Surface,
	Geometry = Geometry,
	Agent = Agent,
	ShapeSource = ShapeSource,
	FixtureSource = Require("FixtureSource"),
	Lanes = Require("Lanes"),
	Internal = {
		Heap = Require("Heap"),
		Raster = Require("Raster"),
		Spans = Require("Spans"),
		World = World,
		GridSearch = GridSearch,
		Scheduler = SchedulerModule,
		Regions = Require("Regions"),
		ReedsShepp = Require("ReedsShepp"),
		CarPlanner = Require("CarPlanner"),
		Controller = Require("Controller"),
		Reference = Require("Reference"),
	},
}

local Scheduler = SchedulerModule.new({ Waiter = IsRoblox and task.wait or nil })
Pathfinding.Scheduler = Scheduler

Pathfinding.World = {}

local Watched = {}

function Pathfinding.Watch(Map, Root)
	local function Touch(Item)
		if Item:IsA("BasePart") and Item.CanCollide then
			local Position = Item.Position
			local Reach = Item.Size.Magnitude * 0.5 + 2
			Map:Invalidate(Position.X - Reach, Position.Z - Reach, Position.X + Reach, Position.Z + Reach)
		end
	end
	Root = Root or workspace
	Map.Connections = { Root.DescendantAdded:Connect(Touch), Root.DescendantRemoving:Connect(Touch) }
	Watched[#Watched + 1] = Map
	return Map
end

function Pathfinding.Unwatch(Map)
	for _, Connection in next, Map.Connections or {} do Connection:Disconnect() end
	Map.Connections = nil
	local Index = table.find(Watched, Map)
	if Index then table.remove(Watched, Index) end
end

function Pathfinding.World.new(Options)
	Options = Options or {}
	local Source = Options.Source
	if not Source and IsRoblox then Source = Require("RobloxSource").new(Options) end
	local Map = World.new(Source, Options)
	if IsRoblox and not Options.Source and Options.Watch ~= false then Pathfinding.Watch(Map) end
	return Map
end

function Pathfinding.FindPath(Map, Who, From, To, Options)
	Options = Options or {}
	local Job = Scheduler:Spawn(function(Job)
		local Reach = Map.Size * Map.Cell
		Map:Refresh(From.X - Reach, From.Z - Reach, From.X + Reach, From.Z + Reach, Job.Yield)
		Map:Refresh(To.X - Reach, To.Z - Reach, To.X + Reach, To.Z + Reach, Job.Yield)
		return GridSearch.Find(Map, Who, From, To, Options, Job.Yield)
	end, Options.Timeout or 10)
	Job.Budget = Options.Budget
	return Job
end

function Pathfinding.PlanCar(Map, Car, Start, Goal, Options)
	Options = Options or {}
	local CarPlanner = Require("CarPlanner")
	local Job = Scheduler:Spawn(function(Job)
		return CarPlanner.Plan(Map, Car, Start, Goal, Options, Job.Yield)
	end, Options.Timeout or 8)
	Job.Budget = Options.Budget
	return Job
end

function Pathfinding.Prepare(Map, Who, Center, Radius, Options)
	Options = Options or {}
	local Job = Scheduler:Spawn(function(Job)
		local Size = Map.Size * Map.Cell
		local Ax, Az = Map:TileOf(Center.X - Radius, Center.Z - Radius)
		local Bx, Bz = Map:TileOf(Center.X + Radius, Center.Z + Radius)
		local Count = 0
		for Tz = Az, Bz do
			for Tx = Ax, Bx do
				local Dx = Center.X - math.clamp(Center.X, Tx * Size, (Tx + 1) * Size)
				local Dz = Center.Z - math.clamp(Center.Z, Tz * Size, (Tz + 1) * Size)
				if Dx * Dx + Dz * Dz <= Radius * Radius then
					Map:Ready(World.Key(Tx, Tz), Who.Profile, Job.Yield)
					Count += 1
					if not Job:Check() then return Count end
				end
			end
		end
		return Count
	end, Options.Timeout or 30)
	Job.Budget = Options.Budget
	return Job
end

local Tasks = {}

function Pathfinding.Destroy()
	if Pathfinding.Connection then
		Pathfinding.Connection:Disconnect()
		Pathfinding.Connection = nil
	end
	Scheduler:Cancel()
	for Handle in next, Tasks do Handle:Cancel() end
	table.clear(Tasks)
	for _, Map in next, table.clone(Watched) do Pathfinding.Unwatch(Map) end
	if Pathfinding.Overlay then pcall(Pathfinding.Overlay.Destroy) end
end

if IsRoblox then
	local TaskModule = Require("Task")
	local Movers = Require("Movers")
	local Driver = Require("Driver")
	Pathfinding.Movers = Movers
	Pathfinding.Overlay = Require("Overlay")
	Pathfinding.Inputs = Require("Inputs")
	Pathfinding.Driver = Driver
	Pathfinding.Internal.RobloxSource = Require("RobloxSource")

	local function Resolve(Value)
		if type(Value) == "function" then return Value() end
		return Value
	end

	local function Spawn(Body)
		local Handle = TaskModule.new(os.clock, task.wait)
		Tasks[Handle] = true
		task.spawn(function()
			local Ok, Err = pcall(Body, Handle)
			if not Ok then Handle:Finish("Failed", nil, Err) end
			if Handle.Status == "Running" then Handle:Finish("Done") end
			Tasks[Handle] = nil
		end)
		return Handle
	end
	Pathfinding.Spawn = Spawn

	function Pathfinding.Walk(Map, Who, Options)
		Options = Options or {}
		local Mover = Options.Mover or Movers.Lerp({ Root = Options.Root, Speed = Options.Speed })
		return Spawn(function(Handle)
			local Attempts = 0
			while Handle.Status == "Running" do
				Attempts += 1
				local Root = Resolve(Options.Root)
				local From = Options.From and Resolve(Options.From) or (Root and Root.Position)
				if not From then Handle:Finish("Failed", nil, "NoRoot"); return end
				local Goal = Resolve(Options.Goal)
				local Request = Pathfinding.FindPath(Map, Who, From, Goal, Options)
				Handle.Inner = Request
				local Path = Request:Await(Options.PlanTimeout or 15)
				Handle.Inner = nil
				if Handle.Status ~= "Running" then return end
				if not Path or #Path.Points == 0 then Handle:Finish("Failed", Path, Path and Path.Status or "PlanFailed"); return end
				Handle.Path = Path
				if Options.OnPath then pcall(Options.OnPath, Path) end
				local Outcome = Mover(Path.Points, Handle)
				if Handle.Status ~= "Running" then return end
				if Outcome == "Arrived" and Path.Complete then Handle:Finish("Done", Path); return end
				if Outcome == "Arrived" and Path.Status == "Unreachable" then Handle:Finish("Unreachable", Path); return end
				if Outcome == "NoRoot" or Attempts >= (Options.Attempts or 4) then
					Handle:Finish(Outcome == "Arrived" and "Partial" or "Failed", Path, Outcome)
					return
				end
				if Outcome == "Stuck" then
					local Here = Resolve(Options.Root)
					if Here then
						local P = Here.Position
						Map:Invalidate(P.X - 24, P.Z - 24, P.X + 24, P.Z + 24)
					end
				end
			end
		end)
	end

	function Pathfinding.Drive(Map, Car, Options)
		return Driver.Drive(Pathfinding, Map, Car, Options)
	end

	Pathfinding.Connection = game:GetService("RunService").Heartbeat:Connect(function()
		pcall(Scheduler.Step, Scheduler)
	end)
end

return Pathfinding
end
Modules.Inputs = function(Require)
local Inputs = {}

local Sqrt, Abs = math.sqrt, math.abs
local Zero = Vector3.zero

local function Edge(Steer, Throttle, SignS, SignT)
	local Sx, Cz
	if Throttle >= 0.98 then
		Sx = Steer > 0.02 and 0.05 + 0.6 * Steer or 0
		Cz = Sqrt(1 - Sx * Sx)
	else
		Cz = Throttle > 0.02 and 0.05 + 0.6 * Throttle or 0
		Sx = Sqrt(1 - Cz * Cz)
	end
	return Vector3.new(SignS * Sx, 0, -SignT * Cz)
end

function Inputs.MoveVector(Controls, Options)
	Options = Options or {}
	local Adapter = { Steer = 0, Throttle = 0, Accumulator = 0, Active = false }
	local Saved

	function Adapter.Vector()
		local Steer, Throttle = Adapter.Steer, Adapter.Throttle
		local A, B = Abs(Steer), Abs(Throttle)
		if A < 0.02 and B < 0.02 then return Zero end
		local SignS = Steer >= 0 and 1 or -1
		local SignT = Throttle >= 0 and 1 or -1
		if B >= 0.98 or A >= 0.98 then
			return Edge(A, B, SignS, SignT)
		end
		local Weight, EdgeS, EdgeT
		if A <= B then
			Weight, EdgeS, EdgeT = B, A / B, 1
		else
			Weight, EdgeS, EdgeT = A, 1, B / A
		end
		Adapter.Accumulator += Weight
		if Adapter.Accumulator >= 1 then
			Adapter.Accumulator -= 1
			return Edge(EdgeS, EdgeT, SignS, SignT)
		end
		return Zero
	end

	local Override = function()
		return Adapter.Vector()
	end

	function Adapter.Begin()
		if Adapter.Active then return true end
		local Target = type(Controls) == "function" and Controls() or Controls
		if not Target then return false end
		Adapter.Target = Target
		Saved = rawget(Target, "GetMoveVector")
		rawset(Target, "GetMoveVector", Override)
		Adapter.Active = true
		return true
	end

	function Adapter.Set(Steer, Throttle)
		Adapter.Steer = Steer
		Adapter.Throttle = Throttle
	end

	function Adapter.Finish()
		Adapter.Steer, Adapter.Throttle = 0, 0
		if Adapter.Active and Adapter.Target then
			if rawget(Adapter.Target, "GetMoveVector") == Override then rawset(Adapter.Target, "GetMoveVector", Saved) end
		end
		Adapter.Active = false
	end

	return Adapter
end

function Inputs.PlayerControls()
	local Players = game:GetService("Players")
	local PlayerScripts = Players.LocalPlayer:FindFirstChild("PlayerScripts")
	local Module = PlayerScripts and PlayerScripts:FindFirstChild("PlayerModule")
	if not Module then return nil end
	local Ok, Loaded = pcall(require, Module)
	if not (Ok and type(Loaded) == "table") then return nil end
	local Fine, Controls = pcall(Loaded.GetControls, Loaded)
	return Fine and Controls or nil
end

function Inputs.VehicleSeat(Seat)
	local Adapter = { Active = false }
	function Adapter.Begin()
		Adapter.Active = true
		return true
	end
	function Adapter.Set(Steer, Throttle)
		local Target = type(Seat) == "function" and Seat() or Seat
		if not Target then return end
		pcall(function()
			Target.ThrottleFloat = Throttle
			Target.SteerFloat = Steer
			Target.Throttle = Throttle > 0.1 and 1 or (Throttle < -0.1 and -1 or 0)
			Target.Steer = Steer > 0.1 and 1 or (Steer < -0.1 and -1 or 0)
		end)
	end
	function Adapter.Finish()
		Adapter.Set(0, 0)
		Adapter.Active = false
	end
	return Adapter
end

function Inputs.Callback(Fn)
	local Adapter = { Active = false }
	function Adapter.Begin()
		Adapter.Active = true
		return true
	end
	function Adapter.Set(Steer, Throttle)
		Fn(Steer, Throttle)
	end
	function Adapter.Finish()
		Fn(0, 0)
		Adapter.Active = false
	end
	return Adapter
end

return Inputs
end
Modules.Lanes = function(Require)
local Lanes = {}

local Sqrt, Abs, Min, Max, Floor, Ceil = math.sqrt, math.abs, math.min, math.max, math.floor, math.ceil
local Offset, Shift = 32768, 65536

local function Key(Cx, Cz)
	return (Cx + Offset) * Shift + (Cz + Offset)
end

function Lanes.Index(Lines, Options)
	Options = Options or {}
	local Cell = Options.Cell or 32
	local Buckets = {}
	local Kept = {}
	for Index = 1, #Lines do
		local Line = Lines[Index]
		local Dx, Dz = Line.Bx - Line.Ax, Line.Bz - Line.Az
		local Length = Sqrt(Dx * Dx + Dz * Dz)
		if Length > 0.5 then
			Line.Ux, Line.Uz, Line.Length, Line.Stamp = Dx / Length, Dz / Length, Length, 0
			Kept[#Kept + 1] = Line
			local Pieces = Max(1, Ceil(Length / (Cell * 0.5)))
			local Last
			for Piece = 0, Pieces do
				local T = Piece / Pieces
				local Slot = Key(Floor((Line.Ax + Dx * T) / Cell), Floor((Line.Az + Dz * T) / Cell))
				if Slot ~= Last then
					local Bucket = Buckets[Slot]
					if not Bucket then
						Bucket = {}
						Buckets[Slot] = Bucket
					end
					if Bucket[#Bucket] ~= Line then Bucket[#Bucket + 1] = Line end
					Last = Slot
				end
			end
		end
	end
	return { Cell = Cell, Buckets = Buckets, Lines = Kept, Stamp = 0 }
end

function Lanes.Near(Index, X, Y, Z, Ux, Uz, Options, Into)
	local Reach = Options.Reach or 30
	local Parallel = Options.Parallel or 0.966
	local Slack = Options.Slack or 6
	local Rise = Options.Rise or 8
	local Cell = Index.Cell
	local Buckets = Index.Buckets
	Index.Stamp += 1
	local Stamp = Index.Stamp
	local Nx, Nz = -Uz, Ux
	local Pad = Reach + Cell * 0.5
	local Count = 0
	for Cx = Floor((X - Pad) / Cell), Floor((X + Pad) / Cell) do
		for Cz = Floor((Z - Pad) / Cell), Floor((Z + Pad) / Cell) do
			local Bucket = Buckets[Key(Cx, Cz)]
			if Bucket then
				for Slot = 1, #Bucket do
					local Line = Bucket[Slot]
					if Line.Stamp ~= Stamp then
						Line.Stamp = Stamp
						local Dot = Ux * Line.Ux + Uz * Line.Uz
						if Dot >= Parallel or Dot <= -Parallel then
							local T = (X - Line.Ax) * Line.Ux + (Z - Line.Az) * Line.Uz
							local Level = Line.Ay and Line.Ay + (Line.By - Line.Ay) * Min(1, Max(0, T / Line.Length)) or Line.Y
							if T >= -Slack and T <= Line.Length + Slack and (not Y or not Level or Abs(Level - Y) <= Rise) then
								local Lateral = (Line.Ax + Line.Ux * T - X) * Nx + (Line.Az + Line.Uz * T - Z) * Nz
								if Lateral >= -Reach and Lateral <= Reach then
									Count += 1
									local Item = Into[Count]
									if Item then
										Item.Offset, Item.Divider = Lateral, Line.Divider == true
									else
										Into[Count] = { Offset = Lateral, Divider = Line.Divider == true }
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return Count
end

function Lanes.Scanner(Probe, IsRoad, Options)
	Options = Options or {}
	local Reach = Options.ScanReach or 30
	local Tolerance = Options.ScanTolerance or 1.7
	local Settle = Options.Settle or 6
	return function(X, Y, Z, Ux, Uz, From)
		local Nx, Nz = -Uz, Ux
		local _, Settled = Probe(X, Z, Y, Settle)
		local Level = Settled or Y
		local function Road(Lateral)
			local Clear, FloorY, Code = Probe(X + Nx * Lateral, Z + Nz * Lateral, Level, Tolerance)
			if Clear and IsRoad(Code) then
				Level = FloorY
				return true
			end
			return false
		end
		if From then
			local Lateral = Ceil(From)
			while Lateral <= Reach and not Road(Lateral) do Lateral += 1 end
			if Lateral > Reach then return nil end
			while Lateral <= Reach and Road(Lateral) do Lateral += 1 end
			return Lateral <= Reach and Lateral - 0.5 or nil
		end
		local Base = Level
		if Road(0) then
			local Right = 1
			while Right <= Reach and Road(Right) do Right += 1 end
			Level = Base
			local Left = 1
			while Left <= Reach and Road(-Left) do Left += 1 end
			return true, Left <= Reach and 0.5 - Left or nil, Right <= Reach and Right - 0.5 or nil
		end
		local Start = 1
		while Start <= Reach and not Road(Start) do Start += 1 end
		if Start > Reach then return false end
		local Finish = Start + 1
		while Finish <= Reach and Road(Finish) do Finish += 1 end
		return false, Start - 0.5, Finish <= Reach and Finish - 0.5 or nil
	end
end

function Lanes.Pick(Found, Count, Scan, Options)
	local MinLane = Options.MinLane or 6
	local MaxHalf = Options.MaxHalf or 13
	local DividerReach = Options.DividerReach or 20
	local MaxRoad = Options.MaxRoad or 48
	local Inner, Outer
	local Painted = true
	for Index = 1, Count do
		local Item = Found[Index]
		local Value = Item.Offset
		if Item.Divider and Value >= -DividerReach and Value <= DividerReach and (not Inner or Value > Inner) then Inner = Value end
	end
	if Inner then
		for Index = 1, Count do
			local Value = Found[Index].Offset
			if Value >= Inner + MinLane and (not Outer or Value < Outer) then Outer = Value end
		end
		if not Outer and Scan then
			local Edge = Scan(Inner + 0.5)
			if Edge and Edge >= Inner + MinLane then Outer = Edge end
			Painted = false
		end
	elseif Scan then
		Painted = false
		local CenterRoad, A, B = Scan()
		if CenterRoad then
			if A and B and B - A <= MaxRoad then Inner, Outer = (A + B) * 0.5, B end
		elseif A and B and B - A <= MaxRoad * 0.5 then
			Inner, Outer = A, B
		end
		if Inner then
			for Index = 1, Count do
				local Value = Found[Index].Offset
				if Value >= Inner + MinLane and Value < Outer then Outer = Value end
			end
		end
	end
	if not (Inner and Outer) or Outer - Inner < MinLane then return nil end
	return Inner + Min((Outer - Inner) * 0.5, MaxHalf), Painted
end

function Lanes.Finder(Options)
	Options = Options or {}
	local Index = Options.Index
	local Scanner = Options.Scanner
	local Side = Options.Side or 1
	local MaxShift = Options.MaxShift or 24
	local Found = {}
	return function(X, Y, Z, Ux, Uz)
		if Side < 0 then Ux, Uz = -Ux, -Uz end
		local Count = Index and Lanes.Near(Index, X, Y, Z, Ux, Uz, Options, Found) or 0
		local Scan
		if Scanner then
			Scan = function(From)
				return Scanner(X, Y, Z, Ux, Uz, From)
			end
		end
		local Value, Painted = Lanes.Pick(Found, Count, Scan, Options)
		if not Value or Abs(Value) > MaxShift then return nil end
		return Value * Side, Painted
	end
end

function Lanes.Profile(Points, Finder, Options, Yield)
	Options = Options or {}
	local Step = Options.Step or 4
	local Count = #Points
	local Cumulative = table.create(Count, 0)
	for Index = 2, Count do
		local A, B = Points[Index - 1], Points[Index]
		Cumulative[Index] = Cumulative[Index - 1] + Sqrt((B.X - A.X) ^ 2 + (B.Z - A.Z) ^ 2)
	end
	local Total = Cumulative[Count] or 0
	local Samples = Floor(Total / Step) + 1
	local Raw = table.create(Samples, false)
	local Painted = table.create(Samples, false)
	local Owner = table.create(Samples, 0)
	local Segment = 1
	for Sample = 1, Samples do
		local S = (Sample - 1) * Step
		while Segment < Count - 1 and Cumulative[Segment + 1] < S do Segment += 1 end
		Owner[Sample] = Segment
		local A, B = Points[Segment], Points[Segment + 1]
		if A and B then
			local Length = Cumulative[Segment + 1] - Cumulative[Segment]
			if Length > 1e-6 then
				local T = Min(1, Max(0, (S - Cumulative[Segment]) / Length))
				local Ux, Uz = (B.X - A.X) / Length, (B.Z - A.Z) / Length
				local Value, FromPaint = Finder(A.X + (B.X - A.X) * T, A.Y + (B.Y - A.Y) * T, A.Z + (B.Z - A.Z) * T, Ux, Uz)
				if Value then
					Raw[Sample] = Value
					Painted[Sample] = FromPaint ~= false
				end
			end
		end
		if Yield and Sample % 8 == 0 and Yield() == false then break end
	end

	local Bridge = Floor((Options.Bridge or 160) / Step)
	local Narrower = Options.Narrower or 1.5
	local LastPaint
	for Sample = 1, Samples do
		if Raw[Sample] and Painted[Sample] then
			if LastPaint and Sample - LastPaint > 1 and Sample - LastPaint - 1 <= Bridge then
				local From, To = Raw[LastPaint], Raw[Sample]
				for Gap = LastPaint + 1, Sample - 1 do
					local Expected = From + (To - From) * (Gap - LastPaint) / (Sample - LastPaint)
					local Value = Raw[Gap]
					if not (Value and Abs(Value) < Abs(Expected) - Narrower) then Raw[Gap] = false end
				end
			end
			LastPaint = Sample
		end
	end

	local MinReadings = Options.MinReadings or 3
	local Group = {}
	local First = 1
	while First <= Samples do
		if Raw[First] and Painted[First] then
			First += 1
		else
			local Last = First
			while Last < Samples and Owner[Last + 1] == Owner[First] and not (Raw[Last + 1] and Painted[Last + 1]) do Last += 1 end
			table.clear(Group)
			for Sample = First, Last do
				if Raw[Sample] then Group[#Group + 1] = Raw[Sample] end
			end
			local Value = false
			if #Group >= MinReadings then
				table.sort(Group)
				Value = Group[(#Group + 1) // 2]
			end
			for Sample = First, Last do Raw[Sample] = Value end
			First = Last + 1
		end
	end

	local Known = 0
	for Sample = 1, Samples do
		if Raw[Sample] then Known += 1 end
	end

	local Values = table.create(Samples, 0)
	local Fallback = Options.Fallback or 0
	if Known == 0 then
		for Sample = 1, Samples do Values[Sample] = Fallback end
	else
		local Median = Options.Median or 2
		local Window = {}
		for Sample = 1, Samples do
			if Raw[Sample] then
				table.clear(Window)
				for Near = Max(1, Sample - Median), Min(Samples, Sample + Median) do
					if Raw[Near] then Window[#Window + 1] = Raw[Near] end
				end
				table.sort(Window)
				Values[Sample] = Window[(#Window + 1) // 2]
			end
		end
		local Previous
		for Sample = 1, Samples do
			if Raw[Sample] then
				if Previous and Sample - Previous > 1 then
					local From, To = Values[Previous], Values[Sample]
					for Gap = Previous + 1, Sample - 1 do
						Values[Gap] = From + (To - From) * (Gap - Previous) / (Sample - Previous)
					end
				elseif not Previous then
					for Gap = 1, Sample - 1 do Values[Gap] = Values[Sample] end
				end
				Previous = Sample
			end
		end
		for Gap = Previous + 1, Samples do Values[Gap] = Values[Previous] end
	end

	local Radius = Options.Smooth or 5
	local Buffer = table.create(Samples, 0)
	for _ = 1, 2 do
		for Sample = 1, Samples do
			local Sum, Weight = 0, 0
			for Near = Max(1, Sample - Radius), Min(Samples, Sample + Radius) do
				Sum += Values[Near]
				Weight += 1
			end
			Buffer[Sample] = Sum / Weight
		end
		Values, Buffer = Buffer, Values
	end

	local Taper = Options.TaperFrom
	if Taper and Taper < Total then
		for Sample = 1, Samples do
			local S = (Sample - 1) * Step
			if S > Taper then Values[Sample] *= Max(0, 1 - (S - Taper) / (Total - Taper)) end
		end
	end

	local Target = Options.EndOffset
	local Range = Options.EndRange
	if not Target and Range then Target = Min(Range[2], Max(Range[1], Values[Samples])) end
	if Target and Samples > 1 then
		local Shift = Abs(Target - Values[Samples])
		local PullIn = Max(Options.PullIn or 40, Shift * (Options.PullInRatio or 4))
		local Begin = Max(1, Samples - Floor(PullIn / Step))
		local From = Values[Begin]
		local Span = Max(1, Samples - Begin)
		for Sample = Begin, Samples do
			local T = (Sample - Begin) / Span
			Values[Sample] = From + (Target - From) * T * T * (3 - 2 * T)
		end
	end
	return { Step = Step, Values = Values, Known = Known, Samples = Samples, Length = Total, End = Target }
end

function Lanes.Collect(Roots, Options, Yield)
	Options = Options or {}
	local Patterns = Options.Patterns or { "line" }
	local MinLength = Options.MinLength or 2
	local MaxWidth = Options.MaxWidth or 2
	local MaxThickness = Options.MaxThickness or 0.6
	local Lines = {}
	local Seen = 0
	for _, Root in next, Roots do
		for _, Item in next, Root:GetDescendants() do
			Seen += 1
			if Yield and Seen % 600 == 0 then Yield() end
			if Item:IsA("BasePart") then
				local Lower = string.lower(Item.Name)
				local Match = false
				for _, Pattern in next, Patterns do
					if string.find(Lower, string.lower(Pattern), 1, true) then
						Match = true
						break
					end
				end
				if Match then
					local Frame, Size = Item.CFrame, Item.Size
					local Axes = { { Frame.RightVector, Size.X }, { Frame.UpVector, Size.Y }, { Frame.LookVector, Size.Z } }
					local Up, UpDot = 1, -1
					for Slot = 1, 3 do
						local Dot = Abs(Axes[Slot][1].Y)
						if Dot > UpDot then Up, UpDot = Slot, Dot end
					end
					local Long, Wide
					for Slot = 1, 3 do
						if Slot ~= Up then
							if not Long or Axes[Slot][2] > Long[2] then
								Wide = Long
								Long = Axes[Slot]
							else
								Wide = Axes[Slot]
							end
						end
					end
					if Long[2] >= MinLength and Wide[2] <= MaxWidth and Axes[Up][2] <= MaxThickness then
						local Center = Frame.Position
						local Axis = Long[1]
						if Axis.X * Axis.X + Axis.Z * Axis.Z > 0.25 then
							local Half = Long[2] * 0.5
							local Ax, Ay, Az = Axis.X * Half, Axis.Y * Half, Axis.Z * Half
							local Color = Item.Color
							local Divider = string.find(Lower, "yellow", 1, true) ~= nil or (Color.R > 0.7 and Color.G > 0.5 and Color.B < 0.35)
							Lines[#Lines + 1] = { Ax = Center.X - Ax, Az = Center.Z - Az, Bx = Center.X + Ax, Bz = Center.Z + Az, Ay = Center.Y - Ay, By = Center.Y + Ay, Y = Center.Y, Divider = Divider }
						end
					end
				end
			end
		end
	end
	return Lanes.Index(Lines, Options)
end

return Lanes
end
Modules.Movers = function(Require)
local Movers = {}

local RunService = game:GetService("RunService")

local function Resolve(Value)
	if type(Value) == "function" then return Value() end
	return Value
end

function Movers.RootOffset(Character)
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	local Root = Character and Character:FindFirstChild("HumanoidRootPart")
	if not (Humanoid and Root) then return 3 end
	if Humanoid.RigType == Enum.HumanoidRigType.R15 then return Humanoid.HipHeight + Root.Size.Y * 0.5 end
	return Root.Size.Y * 0.5 + 2
end

function Movers.Lerp(Options)
	Options = Options or {}
	return function(Points, Handle)
		local Root = Resolve(Options.Root)
		if not (Root and Root.Parent) then return "NoRoot" end
		local Offset = Options.Offset or Movers.RootOffset(Root.Parent)
		local Speed = Options.Speed or 20
		local Current = Root.Position
		for Index = 2, #Points do
			local Target = Points[Index] + Vector3.new(0, Offset, 0)
			local Start = Index == 2 and Current or Points[Index - 1] + Vector3.new(0, Offset, 0)
			local Delta = Target - Start
			local Distance = Delta.Magnitude
			if Distance > 0.05 then
				local Flat = Vector3.new(Delta.X, 0, Delta.Z)
				local Rotation = Flat.Magnitude > 0.1 and CFrame.lookAt(Vector3.zero, Flat).Rotation or Root.CFrame.Rotation
				local Duration = Distance / Resolve(Speed)
				local Elapsed = 0
				while Elapsed < Duration do
					Elapsed += RunService.Heartbeat:Wait()
					if Handle.Status ~= "Running" then return "Cancelled" end
					Root = Resolve(Options.Root)
					if not (Root and Root.Parent) then return "NoRoot" end
					Root.CFrame = CFrame.new(Start:Lerp(Target, math.min(Elapsed / Duration, 1))) * Rotation
					Root.AssemblyLinearVelocity = Vector3.zero
				end
			end
			Handle.Progress = Index
		end
		return "Arrived"
	end
end

function Movers.Humanoid(Options)
	Options = Options or {}
	return function(Points, Handle)
		local Humanoid = Resolve(Options.Humanoid)
		local Root = Humanoid and Humanoid.Parent and Humanoid.Parent:FindFirstChild("HumanoidRootPart")
		if not (Humanoid and Root) then return "NoRoot" end
		local Reach = Options.Reach or 1.5
		local StuckTime = Options.StuckTime or 1.2
		for Index = 2, #Points do
			local Target = Points[Index]
			local Last, LastMoved = Root.Position, os.clock()
			local Deadline = os.clock() + (Target - Root.Position).Magnitude / math.max(Humanoid.WalkSpeed, 1) * 2 + 2
			Humanoid:MoveTo(Target)
			while true do
				RunService.Heartbeat:Wait()
				if Handle.Status ~= "Running" then
					Humanoid:Move(Vector3.zero)
					return "Cancelled"
				end
				if not Root.Parent or Humanoid.Health <= 0 then return "NoRoot" end
				local Position = Root.Position
				local Flat = Vector3.new(Target.X - Position.X, 0, Target.Z - Position.Z)
				if Flat.Magnitude <= Reach then break end
				if (Position - Last).Magnitude > 0.5 then
					Last, LastMoved = Position, os.clock()
				elseif os.clock() - LastMoved > StuckTime then
					return "Stuck"
				end
				if os.clock() > Deadline then return "Stuck" end
				Humanoid:MoveTo(Target)
			end
			Handle.Progress = Index
		end
		return "Arrived"
	end
end

function Movers.Callback(Fn)
	return function(Points, Handle)
		return Fn(Points, Handle) or "Arrived"
	end
end

return Movers
end
Modules.Overlay = function(Require)
local Overlay = {}

local Container
local Drawn = {}

local function Folder()
	if Container and Container.Parent then return Container end
	local Parent = (gethui and gethui()) or game:GetService("CoreGui")
	Container = Instance.new("Folder")
	Container.Name = "PathfindingOverlay"
	Container.Parent = Parent
	return Container
end

local function Segment(A, B, Color, Width)
	local Delta = B - A
	local Length = Delta.Magnitude
	if Length < 0.01 then return end
	local Box = Instance.new("BoxHandleAdornment")
	Box.Adornee = workspace.Terrain
	Box.AlwaysOnTop = true
	Box.ZIndex = 5
	Box.Color3 = Color
	Box.Transparency = 0.15
	Box.Size = Vector3.new(Width, Width, Length)
	Box.CFrame = CFrame.lookAt(A + Delta * 0.5, B)
	Box.Parent = Folder()
	Drawn[#Drawn + 1] = Box
	return Box
end

function Overlay.Path(Points, Color, Lift)
	local Offset = Vector3.new(0, Lift or 0.5, 0)
	local Made = {}
	for Index = 1, #Points - 1 do
		Made[#Made + 1] = Segment(Points[Index] + Offset, Points[Index + 1] + Offset, Color or Color3.fromRGB(0, 255, 140), 0.35)
	end
	for Index = 1, #Points do
		local Dot = Instance.new("SphereHandleAdornment")
		Dot.Adornee = workspace.Terrain
		Dot.AlwaysOnTop = true
		Dot.ZIndex = 6
		Dot.Radius = 0.45
		Dot.Color3 = Index == #Points and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
		Dot.CFrame = CFrame.new(Points[Index] + Offset)
		Dot.Parent = Folder()
		Drawn[#Drawn + 1] = Dot
		Made[#Made + 1] = Dot
	end
	return Made
end

function Overlay.Cells(Map, Profile, Center, Radius, Need)
	local Cell, Size = Map.Cell, Map.Size
	local Count = 0
	for X = math.floor((Center.X - Radius) / Cell), math.floor((Center.X + Radius) / Cell) do
		for Z = math.floor((Center.Z - Radius) / Cell), math.floor((Center.Z + Radius) / Cell) do
			local Tx, Tz = X // Size, Z // Size
			local Key = (Tx + 32768) * 65536 + (Tz + 32768)
			local Tile, Data = Map:Ready(Key, Profile)
			local Column = (Z - Tz * Size) * Size + (X - Tx * Size) + 1
			local First = Tile.First[Column]
			for Span = First, First + Tile.Count[Column] - 1 do
				local FloorY = Tile.Floor[Span]
				if math.abs(FloorY - Center.Y) < 12 then
					local Clear = Data.Clear[Span]
					local Box = Instance.new("BoxHandleAdornment")
					Box.Adornee = workspace.Terrain
					Box.AlwaysOnTop = false
					Box.Size = Vector3.new(Cell * 0.9, 0.1, Cell * 0.9)
					Box.CFrame = CFrame.new((X + 0.5) * Cell, FloorY + 0.08, (Z + 0.5) * Cell)
					Box.Transparency = 0.45
					if Clear < 0 then
						Box.Color3 = Color3.fromRGB(90, 90, 90)
					elseif Clear < (Need or 1.5) then
						Box.Color3 = Color3.fromRGB(255, 60, 60)
					else
						Box.Color3 = Color3.fromRGB(60, 120 + math.min(Clear, 8) * 16, 255)
					end
					Box.Parent = Folder()
					Drawn[#Drawn + 1] = Box
					Count += 1
				end
			end
		end
	end
	return Count
end

function Overlay.Clear()
	for Index = 1, #Drawn do
		local Item = Drawn[Index]
		if Item.Parent then Item:Destroy() end
	end
	table.clear(Drawn)
end

function Overlay.Destroy()
	Overlay.Clear()
	if Container then
		Container:Destroy()
		Container = nil
	end
end

return Overlay
end
Modules.Raster = function(Require)
local Geometry = Require("Geometry")

local Raster = {}

local Floor, Min, Max, Huge = math.floor, math.min, math.max, math.huge
local VerticalRange, Footprint, RowSpan, IsThin = Geometry.VerticalRange, Geometry.Footprint, Geometry.RowSpan, Geometry.IsThin
local Edge = 1e-4

local function Sampled(S, Cx, Cz, Inset)
	local Bottom, Top = Huge, -Huge
	local B, T = VerticalRange(S, Cx, Cz)
	if B then Bottom, Top = B, T end
	B, T = VerticalRange(S, Cx - Inset, Cz - Inset)
	if B then
		if B < Bottom then Bottom = B end
		if T > Top then Top = T end
	end
	B, T = VerticalRange(S, Cx + Inset, Cz - Inset)
	if B then
		if B < Bottom then Bottom = B end
		if T > Top then Top = T end
	end
	B, T = VerticalRange(S, Cx - Inset, Cz + Inset)
	if B then
		if B < Bottom then Bottom = B end
		if T > Top then Top = T end
	end
	B, T = VerticalRange(S, Cx + Inset, Cz + Inset)
	if B then
		if B < Bottom then Bottom = B end
		if T > Top then Top = T end
	end
	return Bottom, Top
end

function Raster.Shape(S, Info, Emit, Sampler)
	local Cell, Size, X0, Z0 = Info.Cell, Info.Size, Info.X0, Info.Z0
	if S.MaxX <= X0 or S.MinX >= X0 + Size * Cell or S.MaxZ <= Z0 or S.MinZ >= Z0 + Size * Cell then return end
	if S.MaxY < Info.MinY or S.MinY > Info.MaxY then return end
	local Xs, Zs, Count = Footprint(S)
	local RowFirst = Max(0, Floor((S.MinZ - Z0) / Cell + Edge))
	local RowLast = Min(Size - 1, Floor((S.MaxZ - Z0) / Cell - Edge))
	local Constant = S.Upright and S.Kind == 1
	local Thin = IsThin(S, Cell * 1.5)
	local Inset = Cell * 0.45
	local Half = Cell * 0.5
	local MinY, MaxY, Code = S.MinY, S.MaxY, S.Surface
	for Row = RowFirst, RowLast do
		local ZLow = Z0 + Row * Cell
		local MinX, MaxX = RowSpan(Xs, Zs, Count, ZLow + Edge, ZLow + Cell - Edge)
		if MinX then
			local First = Max(0, Floor((MinX - X0) / Cell + Edge))
			local Last = Min(Size - 1, Floor((MaxX - X0) / Cell - Edge))
			if Last < First and First <= Size - 1 then Last = First end
			local Base = Row * Size + 1
			local Cz = ZLow + Half
			for Column = First, Last do
				if Constant then
					Emit(Base + Column, MinY, MaxY, Code)
				elseif Sampler then
					Sampler(S, X0 + Column * Cell + Half, Cz, Base + Column, Emit, Thin)
				else
					local Bottom, Top = Sampled(S, X0 + Column * Cell + Half, Cz, Inset)
					if Bottom <= Top then
						Emit(Base + Column, Bottom, Top, Code)
					elseif Thin then
						Emit(Base + Column, MinY, MaxY, Code)
					end
				end
			end
		end
	end
end

return Raster
end
Modules.ReedsShepp = function(Require)
local ReedsShepp = {}

local Sin, Cos, Sqrt, Atan2, Asin, Acos, Abs, Fmod, Ceil, Max, Huge = math.sin, math.cos, math.sqrt, math.atan2, math.asin, math.acos, math.abs, math.fmod, math.ceil, math.max, math.huge
local Pi = math.pi
local TwoPi = Pi * 2
local Half = Pi * 0.5
local Zero = 1e-10

local Types = {
	[0] = { 1, -1, 1, nil, nil },
	{ -1, 1, -1, nil, nil },
	{ 1, -1, 1, -1, nil },
	{ -1, 1, -1, 1, nil },
	{ 1, -1, 0, 1, nil },
	{ -1, 1, 0, -1, nil },
	{ 1, 0, -1, 1, nil },
	{ -1, 0, 1, -1, nil },
	{ 1, -1, 0, -1, nil },
	{ -1, 1, 0, 1, nil },
	{ -1, 0, -1, 1, nil },
	{ 1, 0, 1, -1, nil },
	{ 1, 0, -1, nil, nil },
	{ -1, 0, 1, nil, nil },
	{ 1, 0, 1, nil, nil },
	{ -1, 0, -1, nil, nil },
	{ 1, -1, 0, 1, -1 },
	{ -1, 1, 0, -1, 1 },
}
ReedsShepp.Types = Types

local function Mod2Pi(X)
	local V = Fmod(X, TwoPi)
	if V < -Pi then
		V += TwoPi
	elseif V > Pi then
		V -= TwoPi
	end
	return V
end
ReedsShepp.Mod2Pi = Mod2Pi

local function Polar(X, Y)
	return Sqrt(X * X + Y * Y), Atan2(Y, X)
end

local function TauOmega(U, V, Xi, Eta, Phi)
	local Delta = Mod2Pi(U - V)
	local A = Sin(U) - Sin(Delta)
	local B = Cos(U) - Cos(Delta) - 1
	local T1 = Atan2(Eta * A - Xi * B, Xi * A + Eta * B)
	local T2 = 2 * (Cos(Delta) - Cos(V) - Cos(U)) + 3
	local Tau = T2 < 0 and Mod2Pi(T1 + Pi) or Mod2Pi(T1)
	return Tau, Mod2Pi(Tau - U + V - Phi)
end

local function LpSpLp(X, Y, Phi)
	local U, T = Polar(X - Sin(Phi), Y - 1 + Cos(Phi))
	if T >= -Zero then
		local V = Mod2Pi(Phi - T)
		if V >= -Zero then return true, T, U, V end
	end
	return false
end

local function LpSpRp(X, Y, Phi)
	local U1, T1 = Polar(X + Sin(Phi), Y - 1 - Cos(Phi))
	U1 = U1 * U1
	if U1 >= 4 then
		local U = Sqrt(U1 - 4)
		local T = Mod2Pi(T1 + Atan2(2, U))
		local V = Mod2Pi(T - Phi)
		return T >= -Zero and V >= -Zero, T, U, V
	end
	return false
end

local function LpRmL(X, Y, Phi)
	local U1, Theta = Polar(X - Sin(Phi), Y - 1 + Cos(Phi))
	if U1 <= 4 then
		local U = -2 * Asin(0.25 * U1)
		local T = Mod2Pi(Theta + 0.5 * U + Pi)
		local V = Mod2Pi(Phi - T + U)
		return T >= -Zero and U <= Zero, T, U, V
	end
	return false
end

local function LpRupLumRm(X, Y, Phi)
	local Xi, Eta = X + Sin(Phi), Y - 1 - Cos(Phi)
	local Rho = 0.25 * (2 + Sqrt(Xi * Xi + Eta * Eta))
	if Rho <= 1 then
		local U = Acos(Rho)
		local T, V = TauOmega(U, -U, Xi, Eta, Phi)
		return T >= -Zero and V <= Zero, T, U, V
	end
	return false
end

local function LpRumLumRp(X, Y, Phi)
	local Xi, Eta = X + Sin(Phi), Y - 1 - Cos(Phi)
	local Rho = (20 - Xi * Xi - Eta * Eta) / 16
	if Rho >= 0 and Rho <= 1 then
		local U = -Acos(Rho)
		if U >= -Half then
			local T, V = TauOmega(U, U, Xi, Eta, Phi)
			return T >= -Zero and V >= -Zero, T, U, V
		end
	end
	return false
end

local function LpRmSmLm(X, Y, Phi)
	local Rho, Theta = Polar(X - Sin(Phi), Y - 1 + Cos(Phi))
	if Rho >= 2 then
		local R = Sqrt(Rho * Rho - 4)
		local U = 2 - R
		local T = Mod2Pi(Theta + Atan2(R, -2))
		local V = Mod2Pi(Phi - Half - T)
		return T >= -Zero and U <= Zero and V <= Zero, T, U, V
	end
	return false
end

local function LpRmSmRm(X, Y, Phi)
	local Xi, Eta = X + Sin(Phi), Y - 1 - Cos(Phi)
	local Rho, Theta = Polar(-Eta, Xi)
	if Rho >= 2 then
		local T = Theta
		local U = 2 - Rho
		local V = Mod2Pi(T + Half - Phi)
		return T >= -Zero and U <= Zero and V <= Zero, T, U, V
	end
	return false
end

local function LpRmSLmRp(X, Y, Phi)
	local Xi, Eta = X + Sin(Phi), Y - 1 - Cos(Phi)
	local Rho = Sqrt(Xi * Xi + Eta * Eta)
	if Rho >= 2 then
		local U = 4 - Sqrt(Rho * Rho - 4)
		if U <= Zero then
			local T = Mod2Pi(Atan2((4 - U) * Xi - 2 * Eta, -2 * Xi + (U - 4) * Eta))
			local V = Mod2Pi(T - Phi)
			return T >= -Zero and V >= -Zero, T, U, V
		end
	end
	return false
end

local function Solve(X, Y, Phi)
	local BestType, BestTotal = nil, Huge
	local L1, L2, L3, L4, L5 = 0, 0, 0, 0, 0
	local function Take(Type, A, B, C, D, E)
		D, E = D or 0, E or 0
		local Total = Abs(A) + Abs(B) + Abs(C) + Abs(D) + Abs(E)
		if Total < BestTotal then
			BestType, BestTotal = Type, Total
			L1, L2, L3, L4, L5 = A, B, C, D, E
		end
	end

	local Ok, T, U, V = LpSpLp(X, Y, Phi)
	if Ok then Take(14, T, U, V) end
	Ok, T, U, V = LpSpLp(-X, Y, -Phi)
	if Ok then Take(14, -T, -U, -V) end
	Ok, T, U, V = LpSpLp(X, -Y, -Phi)
	if Ok then Take(15, T, U, V) end
	Ok, T, U, V = LpSpLp(-X, -Y, Phi)
	if Ok then Take(15, -T, -U, -V) end
	Ok, T, U, V = LpSpRp(X, Y, Phi)
	if Ok then Take(12, T, U, V) end
	Ok, T, U, V = LpSpRp(-X, Y, -Phi)
	if Ok then Take(12, -T, -U, -V) end
	Ok, T, U, V = LpSpRp(X, -Y, -Phi)
	if Ok then Take(13, T, U, V) end
	Ok, T, U, V = LpSpRp(-X, -Y, Phi)
	if Ok then Take(13, -T, -U, -V) end

	local Xb = X * Cos(Phi) + Y * Sin(Phi)
	local Yb = X * Sin(Phi) - Y * Cos(Phi)

	Ok, T, U, V = LpRmL(X, Y, Phi)
	if Ok then Take(0, T, U, V) end
	Ok, T, U, V = LpRmL(-X, Y, -Phi)
	if Ok then Take(0, -T, -U, -V) end
	Ok, T, U, V = LpRmL(X, -Y, -Phi)
	if Ok then Take(1, T, U, V) end
	Ok, T, U, V = LpRmL(-X, -Y, Phi)
	if Ok then Take(1, -T, -U, -V) end
	Ok, T, U, V = LpRmL(Xb, Yb, Phi)
	if Ok then Take(0, V, U, T) end
	Ok, T, U, V = LpRmL(-Xb, Yb, -Phi)
	if Ok then Take(0, -V, -U, -T) end
	Ok, T, U, V = LpRmL(Xb, -Yb, -Phi)
	if Ok then Take(1, V, U, T) end
	Ok, T, U, V = LpRmL(-Xb, -Yb, Phi)
	if Ok then Take(1, -V, -U, -T) end

	Ok, T, U, V = LpRupLumRm(X, Y, Phi)
	if Ok then Take(2, T, U, -U, V) end
	Ok, T, U, V = LpRupLumRm(-X, Y, -Phi)
	if Ok then Take(2, -T, -U, U, -V) end
	Ok, T, U, V = LpRupLumRm(X, -Y, -Phi)
	if Ok then Take(3, T, U, -U, V) end
	Ok, T, U, V = LpRupLumRm(-X, -Y, Phi)
	if Ok then Take(3, -T, -U, U, -V) end
	Ok, T, U, V = LpRumLumRp(X, Y, Phi)
	if Ok then Take(2, T, U, U, V) end
	Ok, T, U, V = LpRumLumRp(-X, Y, -Phi)
	if Ok then Take(2, -T, -U, -U, -V) end
	Ok, T, U, V = LpRumLumRp(X, -Y, -Phi)
	if Ok then Take(3, T, U, U, V) end
	Ok, T, U, V = LpRumLumRp(-X, -Y, Phi)
	if Ok then Take(3, -T, -U, -U, -V) end

	Ok, T, U, V = LpRmSmLm(X, Y, Phi)
	if Ok then Take(4, T, -Half, U, V) end
	Ok, T, U, V = LpRmSmLm(-X, Y, -Phi)
	if Ok then Take(4, -T, Half, -U, -V) end
	Ok, T, U, V = LpRmSmLm(X, -Y, -Phi)
	if Ok then Take(5, T, -Half, U, V) end
	Ok, T, U, V = LpRmSmLm(-X, -Y, Phi)
	if Ok then Take(5, -T, Half, -U, -V) end
	Ok, T, U, V = LpRmSmRm(X, Y, Phi)
	if Ok then Take(8, T, -Half, U, V) end
	Ok, T, U, V = LpRmSmRm(-X, Y, -Phi)
	if Ok then Take(8, -T, Half, -U, -V) end
	Ok, T, U, V = LpRmSmRm(X, -Y, -Phi)
	if Ok then Take(9, T, -Half, U, V) end
	Ok, T, U, V = LpRmSmRm(-X, -Y, Phi)
	if Ok then Take(9, -T, Half, -U, -V) end
	Ok, T, U, V = LpRmSmLm(Xb, Yb, Phi)
	if Ok then Take(6, V, U, -Half, T) end
	Ok, T, U, V = LpRmSmLm(-Xb, Yb, -Phi)
	if Ok then Take(6, -V, -U, Half, -T) end
	Ok, T, U, V = LpRmSmLm(Xb, -Yb, -Phi)
	if Ok then Take(7, V, U, -Half, T) end
	Ok, T, U, V = LpRmSmLm(-Xb, -Yb, Phi)
	if Ok then Take(7, -V, -U, Half, -T) end
	Ok, T, U, V = LpRmSmRm(Xb, Yb, Phi)
	if Ok then Take(10, V, U, -Half, T) end
	Ok, T, U, V = LpRmSmRm(-Xb, Yb, -Phi)
	if Ok then Take(10, -V, -U, Half, -T) end
	Ok, T, U, V = LpRmSmRm(Xb, -Yb, -Phi)
	if Ok then Take(11, V, U, -Half, T) end
	Ok, T, U, V = LpRmSmRm(-Xb, -Yb, Phi)
	if Ok then Take(11, -V, -U, Half, -T) end

	Ok, T, U, V = LpRmSLmRp(X, Y, Phi)
	if Ok then Take(16, T, -Half, U, -Half, V) end
	Ok, T, U, V = LpRmSLmRp(-X, Y, -Phi)
	if Ok then Take(16, -T, Half, -U, Half, -V) end
	Ok, T, U, V = LpRmSLmRp(X, -Y, -Phi)
	if Ok then Take(17, T, -Half, U, -Half, V) end
	Ok, T, U, V = LpRmSLmRp(-X, -Y, Phi)
	if Ok then Take(17, -T, Half, -U, Half, -V) end

	return BestType, BestTotal, L1, L2, L3, L4, L5
end

function ReedsShepp.Path(X0, Z0, T0, X1, Z1, T1, Radius)
	local Dx, Dz = X1 - X0, Z1 - Z0
	local C, S = Cos(T0), Sin(T0)
	local Type, Total, L1, L2, L3, L4, L5 = Solve((C * Dx + S * Dz) / Radius, (-S * Dx + C * Dz) / Radius, T1 - T0)
	if not Type then return nil end
	return { Type = Type, Length = Total * Radius, Radius = Radius, Lengths = { L1, L2, L3, L4, L5 } }
end

function ReedsShepp.Length(X0, Z0, T0, X1, Z1, T1, Radius)
	local Dx, Dz = X1 - X0, Z1 - Z0
	local C, S = Cos(T0), Sin(T0)
	local Type, Total = Solve((C * Dx + S * Dz) / Radius, (-S * Dx + C * Dz) / Radius, T1 - T0)
	return Type and Total * Radius or Huge
end

function ReedsShepp.Sample(Path, X0, Z0, T0, Spacing, Visit)
	local Radius = Path.Radius
	local Segments = Types[Path.Type]
	local X, Z, T = 0, 0, T0
	local Count = 0
	for Index = 1, 5 do
		local Kind = Segments[Index]
		local Length = Path.Lengths[Index]
		if Kind == nil or Length == 0 then continue end
		local Steps = Max(1, Ceil(Abs(Length) * Radius / Spacing))
		local Direction = Length > 0 and 1 or -1
		local Bx, Bz, Bt = X, Z, T
		for Step = 1, Steps do
			local V = Length * Step / Steps
			if Kind == 1 then
				X = Bx + Sin(Bt + V) - Sin(Bt)
				Z = Bz - Cos(Bt + V) + Cos(Bt)
				T = Bt + V
			elseif Kind == -1 then
				X = Bx - Sin(Bt - V) + Sin(Bt)
				Z = Bz + Cos(Bt - V) - Cos(Bt)
				T = Bt - V
			else
				X = Bx + V * Cos(Bt)
				Z = Bz + V * Sin(Bt)
			end
			Count += 1
			if Visit(X0 + X * Radius, Z0 + Z * Radius, T, Direction, Kind / Radius) == false then return false, Count end
		end
	end
	return true, Count
end

return ReedsShepp
end
Modules.Reference = function(Require)
local Reference = {}

local Sqrt, Atan2, Cos, Sin, Tan, Acos, Abs, Min, Max, Ceil, Floor, Huge = math.sqrt, math.atan2, math.cos, math.sin, math.tan, math.acos, math.abs, math.min, math.max, math.ceil, math.floor, math.huge

local function Clean(Points)
	local Out = {}
	for Index = 1, #Points do
		local Point = Points[Index]
		local Last = Out[#Out]
		if not Last or (Point.X - Last.X) ^ 2 + (Point.Z - Last.Z) ^ 2 > 0.25 then
			Out[#Out + 1] = { X = Point.X, Y = Point.Y, Z = Point.Z }
		end
	end
	local Index = 2
	while Index < #Out do
		local A, B, C = Out[Index - 1], Out[Index], Out[Index + 1]
		local Ax, Az, Bx, Bz = B.X - A.X, B.Z - A.Z, C.X - B.X, C.Z - B.Z
		local La, Lb = Sqrt(Ax * Ax + Az * Az), Sqrt(Bx * Bx + Bz * Bz)
		local Bend = Abs((B.Y - A.Y) / La - (C.Y - B.Y) / Lb)
		if Abs(Ax * Bz - Az * Bx) / (La * Lb) < 0.004 and Ax * Bx + Az * Bz > 0 and Bend < 0.02 then
			table.remove(Out, Index)
		else
			Index += 1
		end
	end
	return Out
end
Reference.Clean = Clean

function Reference.Trim(Points, X, Z, Options)
	Options = Options or {}
	local Reach = Options.Reach or 24
	local Side = Options.Side or 1
	local MinSide = Options.MinSide or 2
	for Index = #Points - 1, 1, -1 do
		local A, B = Points[Index], Points[Index + 1]
		local Ex, Ez = B.X - A.X, B.Z - A.Z
		local LengthSq = Ex * Ex + Ez * Ez
		if LengthSq > 1e-6 then
			local T = ((X - A.X) * Ex + (Z - A.Z) * Ez) / LengthSq
			T = T < 0 and 0 or (T > 1 and 1 or T)
			local Px, Pz = A.X + Ex * T, A.Z + Ez * T
			local Length = Sqrt(LengthSq)
			local Lateral = ((X - A.X) * -Ez + (Z - A.Z) * Ex) / Length
			if (X - Px) ^ 2 + (Z - Pz) ^ 2 <= Reach * Reach and Lateral * Side >= MinSide then
				local Out = table.create(Index + 1)
				for Keep = 1, Index do Out[Keep] = Points[Keep] end
				Out[Index + 1] = { X = Px, Y = A.Y + (B.Y - A.Y) * T, Z = Pz }
				return Out, true, Lateral, Ex / Length, Ez / Length
			end
		end
	end
	return Points, false
end

function Reference.Build(Points, Options)
	Options = Options or {}
	local Radius = Options.CornerRadius or 18
	local Spacing = Options.Spacing or 0.8
	local MinRadius = Options.MinRadius or 8
	local Lane = Options.LaneOffset or 0
	local Profile = Options.LaneProfile
	local Slope = Options.LaneSlope or 0.2
	local P = Clean(Points)
	local Count = #P
	local Xs, Ys, Zs, Hs, Ks, Ds, Os = {}, {}, {}, {}, {}, {}, {}
	if Count < 2 then
		if Count == 1 then
			Xs[1], Ys[1], Zs[1], Hs[1], Ks[1], Ds[1] = P[1].X, P[1].Y, P[1].Z, 0, 0, 1
		end
		return { X = Xs, Y = Ys, Z = Zs, H = Hs, K = Ks, D = Ds, S = { 0 }, Source = Os, Length = 0 }
	end

	local Lengths, Ux, Uz = {}, {}, {}
	local Cumulative = table.create(Count, 0)
	for Index = 1, Count - 1 do
		local Dx, Dz = P[Index + 1].X - P[Index].X, P[Index + 1].Z - P[Index].Z
		local Length = Sqrt(Dx * Dx + Dz * Dz)
		Lengths[Index], Ux[Index], Uz[Index] = Length, Dx / Length, Dz / Length
		Cumulative[Index + 1] = Cumulative[Index] + Length
	end

	local LaneAt
	if Profile then
		local Values, Step = Profile.Values, Profile.Step
		local Last = #Values
		LaneAt = function(S)
			local Position = S / Step + 1
			if Position <= 1 then return Values[1] end
			if Position >= Last then return Values[Last] end
			local Low = Floor(Position)
			local T = Position - Low
			return Values[Low] + (Values[Low + 1] - Values[Low]) * T
		end
	else
		LaneAt = function()
			return Lane
		end
	end

	local Corners = {}
	for Index = 2, Count - 1 do
		local Ax, Az, Bx, Bz = Ux[Index - 1], Uz[Index - 1], Ux[Index], Uz[Index]
		local Dot = Ax * Bx + Az * Bz
		Dot = Dot > 1 and 1 or (Dot < -1 and -1 or Dot)
		local Turn = Acos(Dot)
		if Turn > 0.015 then
			local Sign = Ax * Bz - Az * Bx > 0 and 1 or -1
			local Half = Tan(Turn * 0.5)
			local Center = Cumulative[Index]
			local Inside = Sign * LaneAt(Center)
			local Wanted = Max(Radius, MinRadius + Inside)
			local Span = Wanted * Half + 10
			for Offset = -Span, Span, 4 do
				local Value = Sign * LaneAt(Center + Offset)
				if Value > Inside then Inside = Value end
			end
			Wanted = Max(Radius, MinRadius + Inside)
			local Room = Min(Lengths[Index - 1], Lengths[Index]) * 0.5
			local Reach = Wanted * Half
			if Reach > Room then
				Reach = Room
				Wanted = Room / Half
			end
			Corners[Index] = { Reach = Reach, Radius = Wanted, Sign = Sign, Turn = Turn }
		end
	end

	local Along = {}
	local function Emit(X, Y, Z, H, K, Source, S)
		local N = #Xs + 1
		Xs[N], Ys[N], Zs[N], Hs[N], Ks[N], Ds[N], Os[N], Along[N] = X, Y, Z, H, K, 1, Source, S
	end

	local function Straight(Index, From, To)
		local Length = To - From
		if Length <= 1e-6 then return end
		local A, B = P[Index], P[Index + 1]
		local Pieces = Max(1, Ceil(Length / Spacing))
		local Heading = Atan2(Uz[Index], Ux[Index])
		for Piece = 0, Pieces - 1 do
			local Distance = From + Length * Piece / Pieces
			local T = Distance / Lengths[Index]
			Emit(A.X + Ux[Index] * Distance, A.Y + (B.Y - A.Y) * T, A.Z + Uz[Index] * Distance, Heading, 0, Index, Cumulative[Index] + Distance)
		end
	end

	local function Arc(Index)
		local Corner = Corners[Index]
		local Vertex = P[Index]
		local Ax, Az = Ux[Index - 1], Uz[Index - 1]
		local Sx, Sz = Vertex.X - Ax * Corner.Reach, Vertex.Z - Az * Corner.Reach
		local Sign, R = Corner.Sign, Corner.Radius
		local Cx, Cz = Sx + -Az * R * Sign, Sz + Ax * R * Sign
		local Heading = Atan2(Az, Ax)
		local Pieces = Max(2, Ceil(Corner.Turn * R / Spacing))
		local From = Cumulative[Index] - Corner.Reach
		for Piece = 0, Pieces - 1 do
			local Fraction = Piece / Pieces
			local H = Heading + Sign * Corner.Turn * Fraction
			Emit(Cx + Sin(H) * R * Sign, Vertex.Y, Cz - Cos(H) * R * Sign, H, Sign / R, Index, From + 2 * Corner.Reach * Fraction)
		end
	end

	for Index = 1, Count - 1 do
		local Start = Corners[Index] and Corners[Index].Reach or 0
		local Finish = Lengths[Index] - (Corners[Index + 1] and Corners[Index + 1].Reach or 0)
		Straight(Index, Start, Finish)
		if Corners[Index + 1] then Arc(Index + 1) end
	end
	local Last = P[Count]
	Emit(Last.X, Last.Y, Last.Z, Atan2(Uz[Count - 1], Ux[Count - 1]), 0, Count - 1, Cumulative[Count])

	local Total = #Xs
	local Offsets = table.create(Total, 0)
	local Shifted = false
	for Index = 1, Total do
		local Value = LaneAt(Along[Index])
		Offsets[Index] = Value
		if Value ~= 0 then Shifted = true end
	end

	if Shifted then
		local Upper, Lower = table.create(Total, Huge), table.create(Total, -Huge)
		local Tightest = MinRadius * 0.9
		for Index = 1, Total do
			local K = Ks[Index]
			if K ~= 0 then
				local Room = Max(0, 1 / Abs(K) - Tightest)
				if K > 0 then Upper[Index] = Room else Lower[Index] = -Room end
			end
		end
		local Base = table.create(Total, 0)
		for Index = 2, Total do
			Base[Index] = Base[Index - 1] + Sqrt((Xs[Index] - Xs[Index - 1]) ^ 2 + (Zs[Index] - Zs[Index - 1]) ^ 2)
		end
		for Index = 2, Total do
			local Step = (Base[Index] - Base[Index - 1]) * Slope
			Upper[Index] = Min(Upper[Index], Upper[Index - 1] + Step)
			Lower[Index] = Max(Lower[Index], Lower[Index - 1] - Step)
		end
		for Index = Total - 1, 1, -1 do
			local Step = (Base[Index + 1] - Base[Index]) * Slope
			Upper[Index] = Min(Upper[Index], Upper[Index + 1] + Step)
			Lower[Index] = Max(Lower[Index], Lower[Index + 1] - Step)
		end
		for Index = 1, Total do
			local Value = Offsets[Index]
			if Value > Upper[Index] then Value = Upper[Index] elseif Value < Lower[Index] then Value = Lower[Index] end
			local H, K = Hs[Index], Ks[Index]
			Xs[Index] -= Sin(H) * Value
			Zs[Index] += Cos(H) * Value
			if K ~= 0 then
				local Bent = 1 / K - Value
				Ks[Index] = Abs(Bent) > 1e-6 and 1 / Bent or K
			end
			Offsets[Index] = Value
		end
		local Headings = table.create(Total, 0)
		for Index = 1, Total do
			local A, B = Max(1, Index - 1), Min(Total, Index + 1)
			local Dx, Dz = Xs[B] - Xs[A], Zs[B] - Zs[A]
			Headings[Index] = Dx * Dx + Dz * Dz > 1e-8 and Atan2(Dz, Dx) or Hs[Index]
		end
		Hs = Headings
	end

	local S = table.create(Total, 0)
	for Index = 2, Total do
		local Dx, Dz = Xs[Index] - Xs[Index - 1], Zs[Index] - Zs[Index - 1]
		S[Index] = S[Index - 1] + Sqrt(Dx * Dx + Dz * Dz)
	end
	return { X = Xs, Y = Ys, Z = Zs, H = Hs, K = Ks, D = Ds, S = S, Source = Os, Offset = Offsets, Length = S[Total] }
end

function Reference.Nearest(Path, X, Z, From, To)
	local Xs, Zs = Path.X, Path.Z
	local Best, BestDistance = From or 1, Huge
	for Index = From or 1, To or #Xs do
		local Dx, Dz = Xs[Index] - X, Zs[Index] - Z
		local Distance = Dx * Dx + Dz * Dz
		if Distance < BestDistance then Best, BestDistance = Index, Distance end
	end
	return Best, Sqrt(BestDistance)
end

function Reference.Ahead(Path, Index, Distance)
	local S = Path.S
	local Target = S[Index] + Distance
	local Last = #S
	while Index < Last and S[Index] < Target do Index += 1 end
	return Index
end

function Reference.Slice(Path, From, To, Into)
	Into = Into or { X = {}, Y = {}, Z = {}, H = {}, K = {}, D = {} }
	for Index = From, To do
		local N = #Into.X + 1
		Into.X[N], Into.Y[N], Into.Z[N], Into.H[N], Into.K[N], Into.D[N] = Path.X[Index], Path.Y[Index], Path.Z[Index], Path.H[Index], Path.K[Index], Path.D[Index]
	end
	return Into
end

return Reference
end
Modules.Regions = function(Require)
local Heap = Require("Heap")

local Regions = {}

local Sqrt, Huge = math.sqrt, math.huge
local Shift = 65536
local Slots = 4096

function Regions.Label(Map, Tile, Data, Radius, Costs, MaskKey)
	local Cache = Data.Regions
	if not Cache then
		Cache = {}
		Data.Regions = Cache
	end
	local Labels = Cache[MaskKey]
	if Labels then return Labels end
	local Size, Cell = Map.Size, Map.Cell
	local Total = Tile.Spans
	local Clear, Surface, ColumnOf = Data.Clear, Tile.Surface, Tile.Column
	local E, W, S, N = Data.E, Data.W, Data.S, Data.N
	local Region = table.create(Total, 0)
	local SumX, SumY, SumZ, Weight, Border = {}, {}, {}, {}, {}
	local Count = 0
	local Stack = {}
	local Key = Tile.Key
	local BaseX, BaseZ = Tile.Tx * Size, Tile.Tz * Size
	for Seed = 1, Total do
		if Region[Seed] == 0 and Clear[Seed] >= Radius and Costs[Surface[Seed]] < Huge then
			Count += 1
			local Id = Count
			local Ax, Ay, Az, Members = 0, 0, 0, 0
			local Edges = {}
			Region[Seed] = Id
			local Top = 1
			Stack[1] = Seed
			while Top > 0 do
				local Span = Stack[Top]
				Top -= 1
				local Column = ColumnOf[Span] - 1
				local Lz = Column // Size
				local Lx = Column - Lz * Size
				Ax += Lx
				Az += Lz
				Ay += Tile.Floor[Span]
				Members += 1
				for Dir = 1, 4 do
					local Next, Across, Other
					if Dir == 1 then
						Next, Across, Other = E[Span], Lx == Size - 1, Key + Shift
					elseif Dir == 2 then
						Next, Across, Other = W[Span], Lx == 0, Key - Shift
					elseif Dir == 3 then
						Next, Across, Other = S[Span], Lz == Size - 1, Key + 1
					else
						Next, Across, Other = N[Span], Lz == 0, Key - 1
					end
					if Next ~= 0 then
						if Across then
							Edges[#Edges + 1] = Other
							Edges[#Edges + 1] = Next
						elseif Region[Next] == 0 and Clear[Next] >= Radius and Costs[Surface[Next]] < Huge then
							Region[Next] = Id
							Top += 1
							Stack[Top] = Next
						end
					end
				end
			end
			SumX[Id] = (BaseX + Ax / Members + 0.5) * Cell
			SumZ[Id] = (BaseZ + Az / Members + 0.5) * Cell
			SumY[Id] = Ay / Members
			Weight[Id] = Members
			Border[Id] = Edges
			if Count >= Slots - 1 then break end
		end
	end
	Labels = { Region = Region, Count = Count, X = SumX, Y = SumY, Z = SumZ, Members = Weight, Border = Border }
	Cache[MaskKey] = Labels
	return Labels
end

function Regions.MaskKey(Radius, Costs)
	local Parts = { tostring(Radius) }
	for Index = 1, #Costs do
		if Costs[Index] == Huge then Parts[#Parts + 1] = tostring(Index) end
	end
	return table.concat(Parts, "|")
end

function Regions.Flood(Context, FromKey, FromSpan, ToKey, ToSpan, Limit)
	local Map, Load, Radius, Costs = Context.Map, Context.Load, Context.Radius, Context.Costs
	local MaskKey = Regions.MaskKey(Radius, Costs)
	local Labelled = {}

	local function Labels(Key)
		local Value = Labelled[Key]
		if not Value then
			local Entry = Load(Key)
			Value = Regions.Label(Map, Entry[1], Entry[2], Radius, Costs, MaskKey)
			Labelled[Key] = Value
		end
		return Value
	end

	local FromRegion = Labels(FromKey).Region[FromSpan]
	if FromRegion == 0 then return "NoRegion" end
	local Target = ToKey * Slots + Labels(ToKey).Region[ToSpan]
	local First = FromKey * Slots + FromRegion
	if First == Target then return "Reached" end
	local Queue, Seen = { First }, { [First] = true }
	local Head = 1
	while Head <= #Queue do
		if Head > Limit then return "Limit" end
		local Node = Queue[Head]
		Head += 1
		local Key = Node // Slots
		local Edges = Labels(Key).Border[Node - Key * Slots]
		for Index = 1, #Edges, 2 do
			local OtherKey = Edges[Index]
			local OtherRegion = Labels(OtherKey).Region[Edges[Index + 1]]
			if OtherRegion ~= 0 then
				local Next = OtherKey * Slots + OtherRegion
				if Next == Target then return "Reached" end
				if not Seen[Next] then
					Seen[Next] = true
					Queue[#Queue + 1] = Next
				end
			end
		end
	end
	return "Exhausted"
end

function Regions.Corridor(Context, StartKey, StartSpan, GoalKey, GoalSpan, Options)
	Options = Options or {}
	local Map, Load, Radius, Costs, Yield = Context.Map, Context.Load, Context.Radius, Context.Costs, Context.Yield
	local MaskKey = Regions.MaskKey(Radius, Costs)
	local Labelled = {}

	local function Labels(Key)
		local Value = Labelled[Key]
		if not Value then
			local Entry = Load(Key)
			Value = Regions.Label(Map, Entry[1], Entry[2], Radius, Costs, MaskKey)
			Labelled[Key] = Value
		end
		return Value
	end

	local StartRegion = Labels(StartKey).Region[StartSpan]
	local GoalRegion = Labels(GoalKey).Region[GoalSpan]
	if StartRegion == 0 or GoalRegion == 0 then return nil, "NoRegion" end
	local StartNode = StartKey * Slots + StartRegion
	local GoalNode = GoalKey * Slots + GoalRegion
	if StartNode == GoalNode then return { [StartKey] = true }, "Same", { StartNode } end

	local function Center(Node)
		local Key = Node // Slots
		local Id = Node - Key * Slots
		local L = Labels(Key)
		return L.X[Id], L.Y[Id], L.Z[Id]
	end

	local Gx, Gy, Gz = Center(GoalNode)
	local Sx, Sy, Sz = Center(StartNode)
	local Limit = Options.MaxRegions or 6000
	local Sides = {}
	for Side = 1, 2 do
		local Open = Heap.new()
		local Tx, Ty, Tz = Gx, Gy, Gz
		if Side == 2 then Tx, Ty, Tz = Sx, Sy, Sz end
		local Root = Side == 1 and StartNode or GoalNode
		Sides[Side] = { Open = Open, G = { [Root] = 0 }, Parent = {}, Closed = {}, Tx = Tx, Ty = Ty, Tz = Tz, Count = 0 }
		Open.Push(Root, 0)
	end

	local Meet
	local Expanded = 0
	local Exhausted
	while not Meet do
		local Progress = false
		for Side = 1, 2 do
			local State = Sides[Side]
			local Other = Sides[3 - Side]
			local Open = State.Open
			local Node
			while Open.Size() > 0 do
				local Candidate = Open.Pop()
				if not State.Closed[Candidate] then
					Node = Candidate
					break
				end
			end
			if not Node then
				Exhausted = Side
				break
			end
			Progress = true
			State.Closed[Node] = true
			State.Count += 1
			Expanded += 1
			if Other.Closed[Node] then
				Meet = Node
				break
			end
			if Expanded % 16 == 0 and Yield and not Yield() then return nil, "Timeout" end
			if Expanded > Limit then return nil, "Limit" end
			local Key = Node // Slots
			local Id = Node - Key * Slots
			local L = Labels(Key)
			local Edges = L.Border[Id]
			local Base = State.G[Node]
			local X, Y, Z = L.X[Id], L.Y[Id], L.Z[Id]
			local Seen = {}
			for Index = 1, #Edges, 2 do
				local OtherKey, OtherSpan = Edges[Index], Edges[Index + 1]
				local OtherRegion = Labels(OtherKey).Region[OtherSpan]
				if OtherRegion ~= 0 then
					local Next = OtherKey * Slots + OtherRegion
					if not Seen[Next] and not State.Closed[Next] then
						Seen[Next] = true
						local Nx, Ny, Nz = Center(Next)
						local Dx, Dy, Dz = Nx - X, Ny - Y, Nz - Z
						local Cost = Base + Sqrt(Dx * Dx + Dy * Dy + Dz * Dz)
						local Old = State.G[Next]
						if not Old or Cost < Old then
							State.G[Next] = Cost
							State.Parent[Next] = Node
							local Hx, Hy, Hz = Nx - State.Tx, Ny - State.Ty, Nz - State.Tz
							Open.Push(Next, Cost + Sqrt(Hx * Hx + Hy * Hy + Hz * Hz))
						end
					end
				end
			end
		end
		if Exhausted or not Progress then break end
	end

	if not Meet then
		local Reached = {}
		for Node in next, Sides[1].Closed do Reached[Node // Slots] = true end
		return nil, "Unreachable", Reached
	end

	local Chain = {}
	local Node = Meet
	while Node do
		table.insert(Chain, 1, Node)
		Node = Sides[1].Parent[Node]
	end
	Node = Sides[2].Parent[Meet]
	while Node do
		Chain[#Chain + 1] = Node
		Node = Sides[2].Parent[Node]
	end

	local Corridor = {}
	local Pad = Options.CorridorPad or 1
	for Index = 1, #Chain do
		local Key = Chain[Index] // Slots
		local A = Key // Shift
		local B = Key - A * Shift
		for Dx = -Pad, Pad do
			for Dz = -Pad, Pad do
				Corridor[(A + Dx) * Shift + B + Dz] = true
			end
		end
	end
	return Corridor, "Found", Chain
end

return Regions
end
Modules.RobloxSource = function(Require)
local Geometry = Require("Geometry")
local Raster = Require("Raster")
local Surface = Require("Surface")

local RobloxSource = {}
RobloxSource.__index = RobloxSource

local Workspace = game:GetService("Workspace")
local Raycast = Workspace.Raycast
local BoundsInBox = Workspace.GetPartBoundsInBox
local Vector3New, CFrameNew = Vector3.new, CFrame.new
local Water = Enum.Material.Water
local BoxFidelity = Enum.CollisionFidelity.Box
local HullFidelity = Enum.CollisionFidelity.Hull

local KindByShape = {
	[Enum.PartType.Block] = Geometry.Block,
	[Enum.PartType.Wedge] = Geometry.Wedge,
	[Enum.PartType.CornerWedge] = Geometry.CornerWedge,
	[Enum.PartType.Cylinder] = Geometry.Cylinder,
	[Enum.PartType.Ball] = Geometry.Ball,
}

function RobloxSource.new(Options)
	Options = Options or {}
	local Overlap = OverlapParams.new()
	Overlap.FilterType = Enum.RaycastFilterType.Exclude
	Overlap.FilterDescendantsInstances = Options.Ignore or {}
	Overlap.RespectCanCollide = true
	if Options.CollisionGroup then Overlap.CollisionGroup = Options.CollisionGroup end
	local Single = RaycastParams.new()
	Single.FilterType = Enum.RaycastFilterType.Include
	local Wet = RaycastParams.new()
	Wet.FilterType = Enum.RaycastFilterType.Include
	Wet.FilterDescendantsInstances = { Workspace.Terrain }
	Wet.IgnoreWater = false
	local Dry = RaycastParams.new()
	Dry.FilterType = Enum.RaycastFilterType.Include
	Dry.FilterDescendantsInstances = { Workspace.Terrain }
	Dry.IgnoreWater = true
	local self = setmetatable({
		Overlap = Overlap,
		Single = Single,
		Wet = Wet,
		Dry = Dry,
		Classify = Options.Classify,
		Terrain = Options.Terrain ~= false,
		Cache = {},
		Cached = 0,
		CacheLimit = Options.CacheLimit or 60000,
		Convex = false,
	}, RobloxSource)
	self.MeshSampler = function(S, Px, Pz, Index, Emit, Thin)
		self:SampleMesh(S, Px, Pz, Index, Emit, Thin)
	end
	return self
end

function RobloxSource:SetIgnore(List)
	self.Overlap.FilterDescendantsInstances = List
end

function RobloxSource:Entry(Part)
	local Entry = self.Cache[Part]
	if Entry then return Entry end
	local Kind, Convex = Geometry.Block, true
	if Part:IsA("Part") then
		Kind = KindByShape[Part.Shape] or Geometry.Block
	else
		local Class = Part.ClassName
		if Class == "WedgePart" then
			Kind = Geometry.Wedge
		elseif Class == "CornerWedgePart" then
			Kind = Geometry.CornerWedge
		elseif Class == "MeshPart" or Part:IsA("PartOperation") then
			local Ok, Fidelity = pcall(function() return Part.CollisionFidelity end)
			if not (Ok and Fidelity == BoxFidelity) then
				Kind = Geometry.Mesh
				Convex = Ok and Fidelity == HullFidelity
			end
		end
	end
	local Code = self.Classify and self.Classify(Part)
	if Code == false then
		Entry = { Skip = true }
	else
		if Code == nil then
			local Parent = Part.Parent
			Code = Surface.FromName(Part.Name) or (Parent and Parent ~= Workspace and Surface.FromName(Parent.Name)) or Surface.FromMaterial(Part.Material.Name)
		end
		Entry = { Kind = Kind, Convex = Convex, Surface = Code }
	end
	if self.Cached >= self.CacheLimit then
		table.clear(self.Cache)
		self.Cached = 0
	end
	self.Cache[Part] = Entry
	self.Cached += 1
	return Entry
end

function RobloxSource:SampleMesh(S, Px, Pz, Index, Emit, Thin)
	local Params = self.Single
	local Top, Bottom = S.MaxY + 0.25, S.MinY - 0.25
	local Hit = Raycast(Workspace, Vector3New(Px, Top, Pz), Vector3New(0, Bottom - Top, 0), Params)
	if not Hit then
		if Thin then Emit(Index, S.MinY, S.MaxY, S.Surface) end
		return
	end
	local High = Hit.Position.Y
	local Up = Raycast(Workspace, Vector3New(Px, Bottom, Pz), Vector3New(0, Top - Bottom, 0), Params)
	local Low = Up and Up.Position.Y or S.MinY
	if self.Convex or Low >= High then
		Emit(Index, Low < High and Low or S.MinY, High, S.Surface)
		return
	end
	local Tops, Bottoms = { High }, { Low }
	local Y = High - 0.02
	for _ = 1, 3 do
		if Y <= Bottom then break end
		local Next = Raycast(Workspace, Vector3New(Px, Y, Pz), Vector3New(0, Bottom - Y, 0), Params)
		if not Next then break end
		local Value = Next.Position.Y
		Tops[#Tops + 1] = Value
		Y = Value - 0.02
	end
	Y = Low + 0.02
	for _ = 1, 3 do
		if Y >= Top then break end
		local Next = Raycast(Workspace, Vector3New(Px, Y, Pz), Vector3New(0, Top - Y, 0), Params)
		if not Next then break end
		local Value = Next.Position.Y
		Bottoms[#Bottoms + 1] = Value
		Y = Value + 0.02
	end
	local Count = #Tops
	if Count == 1 or Count ~= #Bottoms then
		Emit(Index, Low, High, S.Surface)
		return
	end
	table.sort(Tops)
	table.sort(Bottoms)
	for I = 1, Count do
		if Bottoms[I] < Tops[I] then Emit(Index, Bottoms[I], Tops[I], S.Surface) end
	end
end

function RobloxSource:Sample(Info, Emit, Yield)
	local Cell, Size = Info.Cell, Info.Size
	local Width = Cell * Size
	local Center = CFrameNew(Info.X0 + Width * 0.5, (Info.MinY + Info.MaxY) * 0.5, Info.Z0 + Width * 0.5)
	local Parts = BoundsInBox(Workspace, Center, Vector3New(Width, Info.MaxY - Info.MinY, Width), self.Overlap)
	local Single = self.Single
	for Index = 1, #Parts do
		local Part = Parts[Index]
		local Entry = self:Entry(Part)
		if not Entry.Skip and (Part.Anchored or Part:IsGrounded()) then
			local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Part.CFrame:GetComponents()
			local PartSize = Part.Size
			local Shape = Geometry.Shape(Entry.Kind, X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22, PartSize.X, PartSize.Y, PartSize.Z, Entry.Surface)
			if Entry.Kind == Geometry.Mesh then
				Single.FilterDescendantsInstances = { Part }
				self.Convex = Entry.Convex
				Raster.Shape(Shape, Info, Emit, self.MeshSampler)
			else
				Raster.Shape(Shape, Info, Emit)
			end
		end
		if Yield and Index % 24 == 0 then Yield() end
	end
	if self.Terrain then self:SampleTerrain(Info, Emit, Yield) end
end

function RobloxSource:SampleTerrain(Info, Emit, Yield)
	local Cell, Size = Info.Cell, Info.Size
	local X0, Z0 = Info.X0, Info.Z0
	local Top, Bottom = Info.MaxY, Info.MinY
	local Down = Vector3New(0, Bottom - Top, 0)
	local Wet, Dry = self.Wet, self.Dry
	local Step = Size * Cell / 5
	local Any = false
	for I = 0, 4 do
		for J = 0, 4 do
			if Raycast(Workspace, Vector3New(X0 + (I + 0.5) * Step, Top, Z0 + (J + 0.5) * Step), Down, Wet) then
				Any = true
				break
			end
		end
		if Any then break end
	end
	if not Any then return end
	for Row = 0, Size - 1 do
		local Pz = Z0 + (Row + 0.5) * Cell
		local Base = Row * Size + 1
		for Column = 0, Size - 1 do
			local Px = X0 + (Column + 0.5) * Cell
			local Hit = Raycast(Workspace, Vector3New(Px, Top, Pz), Down, Wet)
			if Hit then
				local Y = Hit.Position.Y
				local Material = Hit.Material
				if Material == Water then
					local Bed = Raycast(Workspace, Vector3New(Px, Y - 0.05, Pz), Vector3New(0, Bottom - Y, 0), Dry)
					Emit(Base + Column, (Bed and Bed.Position.Y or Y - 60) - 8, Y, Surface.Water)
				else
					Emit(Base + Column, Y - 8, Y, Surface.FromMaterial(Material.Name))
				end
			end
		end
		if Yield then Yield() end
	end
end

return RobloxSource
end
Modules.Scheduler = function(Require)
local Scheduler = {}
Scheduler.__index = Scheduler

local Request = {}
Request.__index = Request

local Huge = math.huge

function Scheduler.new(Options)
	Options = Options or {}
	return setmetatable({
		Jobs = {},
		Budget = Options.Budget or 0.002,
		Clock = Options.Clock or os.clock,
		Waiter = Options.Waiter,
		Deadline = Huge,
		Turn = 0,
	}, Scheduler)
end

function Scheduler:Spawn(Fn, Timeout)
	local Job = setmetatable({
		Status = "Running",
		Scheduler = self,
		Started = self.Clock(),
		Timeout = Timeout,
		Cpu = 0,
		Slices = 0,
	}, Request)
	Job.Thread = coroutine.create(function()
		local Ok, Result = pcall(Fn, Job)
		if Job.Status ~= "Running" then return end
		if Ok then
			Job.Result = Result
			Job.Status = "Done"
		else
			Job.Error = Result
			Job.Status = "Failed"
		end
	end)
	Job.Yield = function()
		return Job:Check()
	end
	self.Jobs[#self.Jobs + 1] = Job
	return Job
end

function Scheduler:Step(Budget)
	local Jobs = self.Jobs
	local Count = #Jobs
	if Count == 0 then return end
	local Clock = self.Clock
	local Began = Clock()
	if not Budget then
		Budget = self.Budget
		for Index = 1, Count do
			local Wanted = Jobs[Index].Budget
			if Wanted and Wanted > Budget and Jobs[Index].Status == "Running" then Budget = Wanted end
		end
	end
	local Deadline = Began + Budget
	self.Turn = self.Turn % Count + 1
	local First = self.Turn
	for Offset = 0, Count - 1 do
		local Job = Jobs[(First + Offset - 1) % Count + 1]
		if Job.Status == "Running" then
			local Now = Clock()
			if Now >= Deadline then break end
			self.Deadline = Now + (Deadline - Now) / (Count - Offset)
			local Ok, Err = coroutine.resume(Job.Thread)
			Job.Cpu += Clock() - Now
			Job.Slices += 1
			if not Ok and Job.Status == "Running" then
				Job.Error = Err
				Job.Status = "Failed"
			end
		end
	end
	self.Deadline = Huge
	local Spent = Clock() - Began
	self.LastStep = Spent
	if Spent > (self.MaxStep or 0) then self.MaxStep = Spent end
	local Write = 0
	for Read = 1, #Jobs do
		local Job = Jobs[Read]
		if Job.Status == "Running" then
			Write += 1
			Jobs[Write] = Job
		end
	end
	for Index = #Jobs, Write + 1, -1 do Jobs[Index] = nil end
end

function Scheduler:Cancel()
	for _, Job in next, self.Jobs do Job:Cancel() end
	table.clear(self.Jobs)
end

function Request:Check()
	if self.Status ~= "Running" then return false end
	local Owner = self.Scheduler
	local Clock = Owner.Clock
	if Clock() >= Owner.Deadline then
		coroutine.yield()
		if self.Status ~= "Running" then return false end
	end
	if self.Timeout and Clock() - self.Started > self.Timeout then
		self.TimedOut = true
		return false
	end
	return true
end

function Request:Cancel()
	if self.Status == "Running" then self.Status = "Cancelled" end
end

function Request:IsDone()
	return self.Status ~= "Running"
end

function Request:Await(Timeout)
	local Owner = self.Scheduler
	local Clock = Owner.Clock
	local Limit = Timeout and Clock() + Timeout or Huge
	local Waiter = Owner.Waiter
	while self.Status == "Running" do
		if Clock() > Limit then
			self:Cancel()
			return nil, "Timeout"
		end
		if Waiter then
			Waiter()
		else
			Owner:Step(Huge)
		end
	end
	return self.Result, self.Status, self.Error
end

Scheduler.Request = Request

return Scheduler
end
Modules.ShapeSource = function(Require)
local Geometry = Require("Geometry")
local Raster = Require("Raster")

local ShapeSource = {}
ShapeSource.__index = ShapeSource

function ShapeSource.new(Shapes)
	local self = setmetatable({ Shapes = {} }, ShapeSource)
	for Index = 1, Shapes and #Shapes or 0 do self:Add(Shapes[Index]) end
	return self
end

function ShapeSource:Add(Shape)
	self.Shapes[#self.Shapes + 1] = Shape
	return Shape
end

function ShapeSource:Box(X, Y, Z, Sx, Sy, Sz, Code, Yaw, Kind)
	local R00, R01, R02, R10, R11, R12, R20, R21, R22 = Geometry.Rotation(Yaw or 0)
	return self:Add(Geometry.Shape(Kind or Geometry.Block, X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22, Sx, Sy, Sz, Code or 1))
end

function ShapeSource:Sample(Info, Emit)
	local Shapes = self.Shapes
	for Index = 1, #Shapes do Raster.Shape(Shapes[Index], Info, Emit) end
end

return ShapeSource
end
Modules.Spans = function(Require)
local Spans = {}

local Huge = math.huge
local MergeGap = 0.05
local MinHeadroom = 0.5
local MaxSpans = 65535

function Spans.Build(Tile, Intervals, Columns)
	local Count = table.create(Columns, 0)
	local First = table.create(Columns, 0)
	local FloorY, CeilY, SurfaceOf, ColumnOf = {}, {}, {}, {}
	local B, T, S = {}, {}, {}
	local Total = 0
	for Column = 1, Columns do
		local List = Intervals[Column]
		if List then
			local N = #List // 3
			for I = 1, N do
				local Bottom, Top, Code = List[I * 3 - 2], List[I * 3 - 1], List[I * 3]
				local J = I - 1
				while J >= 1 and B[J] > Bottom do
					B[J + 1], T[J + 1], S[J + 1] = B[J], T[J], S[J]
					J -= 1
				end
				B[J + 1], T[J + 1], S[J + 1] = Bottom, Top, Code
			end
			local W = 1
			for I = 2, N do
				if B[I] <= T[W] + MergeGap then
					if T[I] > T[W] then
						T[W] = T[I]
						S[W] = S[I]
					end
				else
					W += 1
					B[W], T[W], S[W] = B[I], T[I], S[I]
				end
			end
			local Made = 0
			First[Column] = Total + 1
			for I = 1, W do
				local Low = T[I]
				local High = I < W and B[I + 1] or Huge
				if High - Low >= MinHeadroom and Total < MaxSpans then
					Total += 1
					Made += 1
					FloorY[Total] = Low
					CeilY[Total] = High
					SurfaceOf[Total] = S[I]
					ColumnOf[Total] = Column
				end
			end
			Count[Column] = Made
		end
	end
	Tile.Count = Count
	Tile.First = First
	Tile.Floor = FloorY
	Tile.Ceil = CeilY
	Tile.Surface = SurfaceOf
	Tile.Column = ColumnOf
	Tile.Spans = Total
	return Tile
end

function Spans.Same(A, B)
	if A.Spans ~= B.Spans then return false end
	local AF, BF, AC, BC, AS, BS, AO, BO = A.Floor, B.Floor, A.Ceil, B.Ceil, A.Surface, B.Surface, A.Column, B.Column
	for I = 1, A.Spans do
		if AF[I] ~= BF[I] or AC[I] ~= BC[I] or AS[I] ~= BS[I] or AO[I] ~= BO[I] then return false end
	end
	return true
end

return Spans
end
Modules.Surface = function(Require)
local Surface = {
	Default = 1,
	Road = 2,
	Pavement = 3,
	Natural = 4,
	Water = 5,
	Wood = 6,
	Curb = 7,
	Ice = 8,
}

Surface.Count = 8
Surface.Names = { "Default", "Road", "Pavement", "Natural", "Water", "Wood", "Curb", "Ice" }

Surface.Materials = {
	Asphalt = Surface.Road,
	Concrete = Surface.Pavement,
	Pavement = Surface.Pavement,
	Brick = Surface.Pavement,
	Cobblestone = Surface.Pavement,
	Slate = Surface.Pavement,
	Granite = Surface.Pavement,
	Marble = Surface.Pavement,
	Limestone = Surface.Pavement,
	Basalt = Surface.Pavement,
	Sandstone = Surface.Pavement,
	DiamondPlate = Surface.Pavement,
	Metal = Surface.Pavement,
	CorrodedMetal = Surface.Pavement,
	Foil = Surface.Pavement,
	CeramicTiles = Surface.Pavement,
	Grass = Surface.Natural,
	LeafyGrass = Surface.Natural,
	Ground = Surface.Natural,
	Mud = Surface.Natural,
	Sand = Surface.Natural,
	Snow = Surface.Natural,
	Rock = Surface.Natural,
	Pebble = Surface.Natural,
	Salt = Surface.Natural,
	CrackedLava = Surface.Natural,
	Ice = Surface.Ice,
	Glacier = Surface.Ice,
	Wood = Surface.Wood,
	WoodPlanks = Surface.Wood,
	Water = Surface.Water,
}

Surface.Hints = {
	{ "curb", Surface.Curb },
	{ "kerb", Surface.Curb },
	{ "sidewalk", Surface.Pavement },
	{ "pavement", Surface.Pavement },
	{ "walkway", Surface.Pavement },
	{ "footpath", Surface.Pavement },
	{ "crosswalk", Surface.Road },
	{ "road", Surface.Road },
	{ "street", Surface.Road },
	{ "asphalt", Surface.Road },
	{ "highway", Surface.Road },
	{ "parking", Surface.Road },
	{ "water", Surface.Water },
	{ "grass", Surface.Natural },
	{ "dirt", Surface.Natural },
	{ "sand", Surface.Natural },
	{ "mud", Surface.Natural },
}

function Surface.FromMaterial(Name)
	return Surface.Materials[Name] or Surface.Default
end

function Surface.FromName(Name)
	local Lower = string.lower(Name)
	local Hints = Surface.Hints
	for Index = 1, #Hints do
		local Hint = Hints[Index]
		if string.find(Lower, Hint[1], 1, true) then return Hint[2] end
	end
	return nil
end

function Surface.CostArray(Defaults, Overrides)
	local Costs = table.create(Surface.Count, 1)
	for Name, Code in next, Surface do
		if type(Code) == "number" and Code >= 1 and Code <= Surface.Count and Name ~= "Count" then
			local Value = Overrides and Overrides[Name]
			if Value == nil then Value = Defaults[Name] end
			Costs[Code] = Value or 1
		end
	end
	return Costs
end

return Surface
end
Modules.Task = function(Require)
local Task = {}
Task.__index = Task

function Task.new(Clock, Waiter)
	return setmetatable({ Status = "Running", Clock = Clock or os.clock, Waiter = Waiter }, Task)
end

function Task:Cancel()
	if self.Status == "Running" then self.Status = "Cancelled" end
	local Inner = self.Inner
	if Inner and Inner.Cancel then Inner:Cancel() end
end

function Task:IsDone()
	return self.Status ~= "Running"
end

function Task:Finish(Status, Result, Err)
	if self.Status ~= "Running" then return end
	self.Result = Result
	self.Error = Err
	self.Status = Status
end

function Task:Await(Timeout)
	local Clock = self.Clock
	local Limit = Timeout and Clock() + Timeout or math.huge
	while self.Status == "Running" do
		if Clock() > Limit then
			self:Cancel()
			return nil, "Timeout"
		end
		self.Waiter()
	end
	return self.Result, self.Status, self.Error
end

return Task
end
Modules.World = function(Require)
local Spans = Require("Spans")

local World = {}
World.__index = World

local Floor, Ceil, Min, Abs, Huge = math.floor, math.ceil, math.min, math.abs, math.huge
local Offset, Shift = 32768, 65536

World.Shift = Shift

function World.Key(Tx, Tz)
	return (Tx + Offset) * Shift + (Tz + Offset)
end

function World.Unkey(Key)
	local A = Key // Shift
	return A - Offset, Key - A * Shift - Offset
end

function World.new(Source, Options)
	Options = Options or {}
	return setmetatable({
		Source = Source,
		Cell = Options.CellSize or 1,
		Size = Options.TileSize or 32,
		MinY = Options.MinY or -500,
		MaxY = Options.MaxY or 3000,
		Life = Options.TileLife or 30,
		Limit = Options.MaxTiles or 500,
		Clock = Options.Clock or os.clock,
		Tiles = {},
		TileCount = 0,
		Generation = 0,
		Stats = { Sampled = 0, SampleTime = 0, Profiled = 0, ProfileTime = 0 },
	}, World)
end

function World:TileOf(X, Z)
	local Span = self.Size * self.Cell
	return Floor(X / Span), Floor(Z / Span)
end

function World:Sample(Tx, Tz, Yield)
	local Cell, Size = self.Cell, self.Size
	local Key = World.Key(Tx, Tz)
	local Info = {
		Tx = Tx,
		Tz = Tz,
		X0 = Tx * Size * Cell,
		Z0 = Tz * Size * Cell,
		Size = Size,
		Cell = Cell,
		MinY = self.MinY,
		MaxY = self.MaxY,
	}
	local Intervals = {}
	local function Emit(Index, Bottom, Top, Code)
		local List = Intervals[Index]
		if List then
			local N = #List
			List[N + 1] = Bottom
			List[N + 2] = Top
			List[N + 3] = Code
		else
			Intervals[Index] = { Bottom, Top, Code }
		end
	end
	local Start = self.Clock()
	if self.Source then self.Source:Sample(Info, Emit, Yield) end
	if Yield then Yield() end
	local Tile = Spans.Build({ Key = Key, Tx = Tx, Tz = Tz, X0 = Info.X0, Z0 = Info.Z0, Profiles = {} }, Intervals, Size * Size)
	local Now = self.Clock()
	local Stats = self.Stats
	Stats.Sampled += 1
	Stats.SampleTime += Now - Start
	local Old = self.Tiles[Key]
	if Old and Spans.Same(Old, Tile) then
		Old.Time = Now
		Old.Used = Now
		Old.Stale = nil
		return Old
	end
	self.Generation += 1
	Tile.Generation = self.Generation
	Tile.Time = Now
	Tile.Used = Now
	if not Old then self.TileCount += 1 end
	self.Tiles[Key] = Tile
	if self.TileCount > self.Limit then self:Evict() end
	return Tile
end

function World:GetTile(Tx, Tz, Yield)
	local Tile = self.Tiles[World.Key(Tx, Tz)]
	if Tile and not Tile.Stale then
		Tile.Used = self.Clock()
		return Tile
	end
	return self:Sample(Tx, Tz, Yield)
end

function World:FloorAt(X, Z, Y, Tolerance, Yield)
	local Cell, Size = self.Cell, self.Size
	local Cx, Cz = Floor(X / Cell), Floor(Z / Cell)
	local Tx, Tz = Cx // Size, Cz // Size
	local Tile = self:GetTile(Tx, Tz, Yield)
	local Column = (Cz - Tz * Size) * Size + (Cx - Tx * Size) + 1
	local Count = Tile.Count[Column]
	if Count == 0 then return nil end
	local First = Tile.First[Column]
	local Floors = Tile.Floor
	local Best, BestGap = First, Huge
	for Span = First, First + Count - 1 do
		local Gap = Abs(Floors[Span] - Y)
		if Gap < BestGap then Best, BestGap = Span, Gap end
	end
	if BestGap > Tolerance then return nil end
	return Floors[Best], Tile.Surface[Best]
end

function World:Refresh(MinX, MinZ, MaxX, MaxZ, Yield, MaxAge)
	local Age = MaxAge or self.Life
	local Now = self.Clock()
	local Ax, Az = self:TileOf(MinX, MinZ)
	local Bx, Bz = self:TileOf(MaxX, MaxZ)
	local Tiles = self.Tiles
	for Tz = Az, Bz do
		for Tx = Ax, Bx do
			local Tile = Tiles[World.Key(Tx, Tz)]
			if Tile and Now - Tile.Time > Age then self:Sample(Tx, Tz, Yield) end
		end
	end
end

function World:Invalidate(MinX, MinZ, MaxX, MaxZ)
	local Ax, Az = self:TileOf(MinX, MinZ)
	local Bx, Bz = self:TileOf(MaxX, MaxZ)
	local Tiles = self.Tiles
	for Tz = Az, Bz do
		for Tx = Ax, Bx do
			local Tile = Tiles[World.Key(Tx, Tz)]
			if Tile then
				Tile.Time = -Huge
				Tile.Stale = true
			end
		end
	end
end

function World:Evict()
	local List = {}
	for _, Tile in next, self.Tiles do List[#List + 1] = Tile end
	table.sort(List, function(A, B) return A.Used < B.Used end)
	local Now = self.Clock()
	local Target = Floor(self.Limit * 0.9)
	for I = 1, #List do
		if self.TileCount <= Target then break end
		local Tile = List[I]
		if Now - Tile.Used < 5 then break end
		self.Tiles[Tile.Key] = nil
		self.TileCount -= 1
	end
end

function World:Clear()
	table.clear(self.Tiles)
	self.TileCount = 0
end

function World:Fresh(Tile, Data)
	local Stamps = Data.Stamps
	local Tiles = self.Tiles
	local Tx, Tz = Tile.Tx, Tile.Tz
	local Index = 0
	for Dz = -1, 1 do
		for Dx = -1, 1 do
			Index += 1
			local Other = Tiles[World.Key(Tx + Dx, Tz + Dz)]
			if not Other or Other.Generation ~= Stamps[Index] then return false end
		end
	end
	return true
end

function World:Ready(Key, Profile, Yield)
	local Tile = self.Tiles[Key]
	if not Tile or Tile.Stale then
		local Tx, Tz = World.Unkey(Key)
		Tile = self:Sample(Tx, Tz, Yield)
	end
	Tile.Used = self.Clock()
	local Data = Tile.Profiles[Profile.Key]
	if Data and self:Fresh(Tile, Data) then return Tile, Data end
	Data = self:BuildProfile(Tile, Profile, Yield)
	Tile.Profiles[Profile.Key] = Data
	return Tile, Data
end

function World:BuildProfile(Tile, Profile, Yield)
	local Start = self.Clock()
	local Size, Cell = self.Size, self.Cell
	local Margin = Min(Size, Ceil(Profile.Cap / Cell) + 1)
	local Width = Size + Margin * 2
	local Tx, Tz = Tile.Tx, Tile.Tz
	local Around = table.create(9)
	for Dz = -1, 1 do
		for Dx = -1, 1 do
			Around[(Dz + 1) * 3 + Dx + 2] = (Dx == 0 and Dz == 0) and Tile or self:GetTile(Tx + Dx, Tz + Dz, Yield)
			if Yield then Yield() end
		end
	end
	local Stamps = table.create(9)
	for I = 1, 9 do Stamps[I] = Around[I].Generation end

	local Columns = Width * Width
	local RFirst = table.create(Columns, 0)
	local RCount = table.create(Columns, 0)
	local RFloor, RCeil, RSpan = {}, {}, {}
	local Total = 0
	for Rz = 0, Width - 1 do
		local Gz = Rz - Margin
		local Dz = Gz < 0 and -1 or (Gz >= Size and 1 or 0)
		local RowBase = (Gz - Dz * Size) * Size + 1
		local Line = Rz * Width + 1
		for Rx = 0, Width - 1 do
			local Gx = Rx - Margin
			local Dx = Gx < 0 and -1 or (Gx >= Size and 1 or 0)
			local Source = Around[(Dz + 1) * 3 + Dx + 2]
			local Column = RowBase + Gx - Dx * Size
			local N = Source.Count[Column]
			if N > 0 then
				local RIndex = Line + Rx
				local F = Source.First[Column]
				local SF, SC = Source.Floor, Source.Ceil
				RFirst[RIndex] = Total + 1
				RCount[RIndex] = N
				for I = F, F + N - 1 do
					Total += 1
					RFloor[Total] = SF[I]
					RCeil[Total] = SC[I]
					RSpan[Total] = I
				end
			end
		end
	end
	if Yield then Yield() end

	local Height, Step = Profile.Height, Profile.Step
	local Walk = table.create(Total, false)
	for I = 1, Total do Walk[I] = RCeil[I] - RFloor[I] >= Height end
	local CE, CW, CS, CN = table.create(Total, 0), table.create(Total, 0), table.create(Total, 0), table.create(Total, 0)

	local function Link(I, NIndex)
		local N = RCount[NIndex]
		if N == 0 then return 0 end
		local F = RFirst[NIndex]
		local MyFloor, MyCeil = RFloor[I], RCeil[I]
		if N == 1 then
			if not Walk[F] then return 0 end
			local OtherFloor = RFloor[F]
			local Gap = OtherFloor - MyFloor
			if Gap > Step or Gap < -Step then return 0 end
			local OtherCeil = RCeil[F]
			local Low = MyCeil < OtherCeil and MyCeil or OtherCeil
			local High = MyFloor > OtherFloor and MyFloor or OtherFloor
			return Low - High >= Height and F or 0
		end
		local Best, BestGap = 0, Huge
		for J = F, F + N - 1 do
			if Walk[J] then
				local OtherFloor = RFloor[J]
				local Gap = Abs(OtherFloor - MyFloor)
				if Gap <= Step and Gap < BestGap then
					local OtherCeil = RCeil[J]
					local Low = MyCeil < OtherCeil and MyCeil or OtherCeil
					local High = MyFloor > OtherFloor and MyFloor or OtherFloor
					if Low - High >= Height then Best, BestGap = J, Gap end
				end
			end
		end
		return Best
	end

	for Rz = 0, Width - 1 do
		local Line = Rz * Width + 1
		for Rx = 0, Width - 1 do
			local RIndex = Line + Rx
			local N = RCount[RIndex]
			if N > 0 then
				local F = RFirst[RIndex]
				for I = F, F + N - 1 do
					if Walk[I] then
						if Rx < Width - 1 then CE[I] = Link(I, RIndex + 1) end
						if Rx > 0 then CW[I] = Link(I, RIndex - 1) end
						if Rz < Width - 1 then CS[I] = Link(I, RIndex + Width) end
						if Rz > 0 then CN[I] = Link(I, RIndex - Width) end
					end
				end
			end
		end
		if Yield and Rz % 8 == 7 then Yield() end
	end

	local Dist = table.create(Total, 0)
	for I = 1, Total do
		if Walk[I] and CE[I] ~= 0 and CW[I] ~= 0 and CS[I] ~= 0 and CN[I] ~= 0 then Dist[I] = 1e9 end
	end
	for Rz = 0, Width - 1 do
		local Line = Rz * Width + 1
		for Rx = 0, Width - 1 do
			local RIndex = Line + Rx
			local N = RCount[RIndex]
			if N > 0 then
				local F = RFirst[RIndex]
				for I = F, F + N - 1 do
					local D = Dist[I]
					if D > 0 then
						local A = CW[I]
						if A ~= 0 then
							local V = Dist[A] + 5
							if V < D then D = V end
							local B = CN[A]
							if B ~= 0 then
								V = Dist[B] + 7
								if V < D then D = V end
							end
						end
						A = CN[I]
						if A ~= 0 then
							local V = Dist[A] + 5
							if V < D then D = V end
							local B = CE[A]
							if B ~= 0 then
								V = Dist[B] + 7
								if V < D then D = V end
							end
						end
						Dist[I] = D
					end
				end
			end
		end
	end
	if Yield then Yield() end
	for Rz = Width - 1, 0, -1 do
		local Line = Rz * Width + 1
		for Rx = Width - 1, 0, -1 do
			local RIndex = Line + Rx
			local N = RCount[RIndex]
			if N > 0 then
				local F = RFirst[RIndex]
				for I = F + N - 1, F, -1 do
					local D = Dist[I]
					if D > 0 then
						local A = CE[I]
						if A ~= 0 then
							local V = Dist[A] + 5
							if V < D then D = V end
							local B = CS[A]
							if B ~= 0 then
								V = Dist[B] + 7
								if V < D then D = V end
							end
						end
						A = CS[I]
						if A ~= 0 then
							local V = Dist[A] + 5
							if V < D then D = V end
							local B = CW[A]
							if B ~= 0 then
								V = Dist[B] + 7
								if V < D then D = V end
							end
						end
						Dist[I] = D
					end
				end
			end
		end
	end
	if Yield then Yield() end

	local Count = Tile.Spans
	local Clear = table.create(Count, -1)
	local E, W, S, N = table.create(Count, 0), table.create(Count, 0), table.create(Count, 0), table.create(Count, 0)
	local Cap = Profile.Cap
	local TFirst, TCount = Tile.First, Tile.Count
	for Lz = 0, Size - 1 do
		local Line = (Lz + Margin) * Width + Margin + 1
		local Base = Lz * Size + 1
		for Lx = 0, Size - 1 do
			local Column = Base + Lx
			local K = TCount[Column]
			if K > 0 then
				local RF = RFirst[Line + Lx]
				local TF = TFirst[Column]
				for J = 0, K - 1 do
					local R = RF + J
					if Walk[R] then
						local Sp = TF + J
						local Value = (Dist[R] / 5 + 0.5) * Cell
						Clear[Sp] = Value < Cap and Value or Cap
						local C = CE[R]
						if C ~= 0 then E[Sp] = RSpan[C] end
						C = CW[R]
						if C ~= 0 then W[Sp] = RSpan[C] end
						C = CS[R]
						if C ~= 0 then S[Sp] = RSpan[C] end
						C = CN[R]
						if C ~= 0 then N[Sp] = RSpan[C] end
					end
				end
			end
		end
	end

	local Stats = self.Stats
	Stats.Profiled += 1
	Stats.ProfileTime += self.Clock() - Start
	return { Clear = Clear, E = E, W = W, S = S, N = N, Stamps = Stamps }
end

function World:Locate(X, Y, Z, Profile, Yield, Below, Above)
	local Cell, Size = self.Cell, self.Size
	local Cx, Cz = Floor(X / Cell), Floor(Z / Cell)
	local Tx, Tz = Cx // Size, Cz // Size
	local Key = World.Key(Tx, Tz)
	local Tile, Data = self:Ready(Key, Profile, Yield)
	local Column = (Cz - Tz * Size) * Size + (Cx - Tx * Size) + 1
	local N = Tile.Count[Column]
	if N == 0 then return nil end
	local F = Tile.First[Column]
	local Upper, Lower = Y + (Above or 1.5), Y - (Below or 8)
	local Best, BestFloor = 0, -Huge
	local Floors, Clear = Tile.Floor, Data.Clear
	for I = F, F + N - 1 do
		local Value = Floors[I]
		if Value <= Upper and Value >= Lower and Value > BestFloor and Clear[I] >= 0 then
			Best, BestFloor = I, Value
		end
	end
	if Best == 0 then return nil end
	return Key, Best
end

function World:Position(Tile, Span)
	local Size, Cell = self.Size, self.Cell
	local Column = Tile.Column[Span] - 1
	local Lz = Column // Size
	return (Tile.Tx * Size + Column - Lz * Size + 0.5) * Cell, Tile.Floor[Span], (Tile.Tz * Size + Lz + 0.5) * Cell
end

return World
end
return Require("Init")
