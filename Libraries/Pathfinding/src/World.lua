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
