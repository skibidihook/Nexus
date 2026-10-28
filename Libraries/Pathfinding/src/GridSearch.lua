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
		if Key ~= KeyB or Span ~= SpanB then return false end
		if Map.Source and Map.Source.ValidatePath and Options.Validate ~= false then
			local Path = { MakeVector((Ax + 0.5) * Cell, Ya, (Az + 0.5) * Cell), MakeVector((Bx + 0.5) * Cell, Yb, (Bz + 0.5) * Cell) }
			return Map.Source:ValidatePath(Path, Agent, { "Walk", Yb - Ya > Agent.StepHeight and "Jump" or "Walk" })
		end
		return true
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
	local GoalRadius = Options.GoalRadius or 0
	local GoalHeightOffset = Options.GoalHeightOffset or 0
	local GoalTest = Options.GoalTest

	local SKey, SSpan = Nearest(From.X, From.Y, From.Z, Options.Below, Options.Above)
	if not SKey then
		return { Status = "NoStart", Complete = false, Points = {}, Expanded = 0, Time = Map.Clock() - Started }
	end

	local GoalX, GoalY, GoalZ = To.X, To.Y, To.Z
	local TargetX, TargetZ = GoalX, GoalZ
	local GoalNode, Relocated
	if not GoalTest then
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
	local CurrentX, CurrentZ
	local LinkCache = {}
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
		if (GoalRadius > 0 or Options.ValidateLinks) and Map.Source and Map.Source.ValidatePath and Options.Validate ~= false then
			local X, Z = (Cx + 0.5) * Cell, (Cz + 0.5) * Cell
			if Options.ValidateLinks or (X - GoalX) ^ 2 + (Z - GoalZ) ^ 2 < (GoalRadius + 12) ^ 2 then
				local Key = tostring(CurrentNode) .. ":" .. tostring(NNode)
				local Valid = LinkCache[Key]
				if Valid == nil then
					Valid = Map.Source:ValidatePath({ MakeVector(CurrentX, CurrentY, CurrentZ), MakeVector(X, NY, Z) }, Agent, { "Walk", NY - CurrentY > Agent.StepHeight and "Jump" or "Walk" })
					LinkCache[Key] = Valid == true
				end
				if not Valid then return end
			end
		end
		local Cost = CurrentBase + Unit * Cell * (CurrentCost + NCost) * 0.5 + Abs(NY - CurrentY) * ClimbWeight
		if NY - CurrentY > Agent.StepHeight + 0.01 then Cost += Options.JumpCost or 0 end
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
				local HeightGap = Y + GoalHeightOffset - GoalY
				local InRange = GoalRadius > 0 and Planar * Planar + HeightGap * HeightGap <= GoalRadius * GoalRadius
				local Accepted = GoalTest and GoalTest(MakeVector(X, Y, Z), G[Node])
				if Accepted or (not GoalTest and (InRange or Node == GoalNode or (not GoalNode and Planar <= Tolerance and Abs(Y - GoalY) <= VerticalTolerance))) then
					Found = Node
					if GoalTest then GoalX, GoalY, GoalZ = X, Y, Z end
					return "Found"
				end
				CurrentNode, CurrentBase, CurrentCost, CurrentY = Node, G[Node], Costs[Tile.Surface[Span]], Y
				CurrentX, CurrentZ = X, Z
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
		local StartFloor = Entries[SKey][1].Floor[SSpan]
		local GoalFloor = Entries[GoalKey][1].Floor[GoalNode - GoalKey * Shift]
		if Abs(GoalFloor - StartFloor) <= Agent.StepHeight and Visible(Start, GoalNode, Max(StartCost, GoalCost) * (Options.SmoothCostSlack or 1.3) + 1e-6, Options.SmoothMargin or Cell * 0.5, Options.VerticalSlack or 1) then
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
	local NodeHeight = table.create(Count)
	for Index = 1, Count do
		local K = Chain[Index] // Shift
		local Entry = Entries[K] or Load(K)
		NodeCost[Index] = Costs[Entry[1].Surface[Chain[Index] - K * Shift]]
		NodeHeight[Index] = Entry[1].Floor[Chain[Index] - K * Shift]
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
		local function CanSmooth(A, B)
			if B == A + 1 then return true end
			for Index = A + 1, B do
				if Abs(NodeHeight[Index] - NodeHeight[Index - 1]) > Agent.StepHeight + 0.01 then return false end
			end
			return true
		end
		local Anchor = 1
		while Anchor < Count do
			local Good, Bad = Anchor + 1, nil
			local Stride = 2
			while true do
				local Probe = Min(Anchor + Stride, Count)
				if Probe <= Good then break end
				if CanSmooth(Anchor, Probe) and Visible(Chain[Anchor], Chain[Probe], Limit(Anchor, Probe), SmoothMargin, Slack) then
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
					if CanSmooth(Anchor, Middle) and Visible(Chain[Anchor], Chain[Middle], Limit(Anchor, Middle), SmoothMargin, Slack) then
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
	local Actions = table.create(#Kept, "Walk")
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
		if Index > 1 then
			for Raw = Kept[Index - 1] + 1, Kept[Index] do
				if NodeHeight[Raw] - NodeHeight[Raw - 1] > Agent.StepHeight + 0.01 then Actions[Index] = "Jump"; break end
			end
		end
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
		Actions = Actions,
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
