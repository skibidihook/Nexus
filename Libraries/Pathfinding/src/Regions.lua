local Heap = Require("Heap")

local Regions = {}

local Sqrt, Huge = math.sqrt, math.huge
local Shift = 65536
local Slots = 4096

function Regions.Label(Map, Tile, Data, Radius, Costs, MaskKey, Yield)
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
		if Yield and Seed % 32 == 0 then Yield() end
		if Region[Seed] == 0 and Clear[Seed] >= Radius and Costs[Surface[Seed]] < Huge then
			Count += 1
			local Id = Count
			local Ax, Ay, Az, Members = 0, 0, 0, 0
			local Edges = {}
			Region[Seed] = Id
			local Top = 1
			Stack[1] = Seed
			while Top > 0 do
				if Yield and Members % 32 == 0 then Yield() end
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
			Value = Regions.Label(Map, Entry[1], Entry[2], Radius, Costs, MaskKey, Context.Yield)
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
		if Context.Yield then Context.Yield() end
		if Head > Limit then return "Limit" end
		local Node = Queue[Head]
		Head += 1
		local Key = Node // Slots
		local Edges = Labels(Key).Border[Node - Key * Slots]
		for Index = 1, #Edges, 2 do
			if Context.Yield and Index % 32 == 1 then Context.Yield() end
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
			Value = Regions.Label(Map, Entry[1], Entry[2], Radius, Costs, MaskKey, Context.Yield)
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
				if Yield then Yield() end
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
				if Yield and Index % 32 == 1 then Yield() end
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
		if Yield then Yield() end
		table.insert(Chain, 1, Node)
		Node = Sides[1].Parent[Node]
	end
	Node = Sides[2].Parent[Meet]
	while Node do
		Chain[#Chain + 1] = Node
		if Yield then Yield() end
		Node = Sides[2].Parent[Node]
	end

	local Corridor = {}
	local Pad = Options.CorridorPad or 1
	for Index = 1, #Chain do
		if Yield then Yield() end
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
