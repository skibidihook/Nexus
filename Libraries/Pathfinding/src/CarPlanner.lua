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
