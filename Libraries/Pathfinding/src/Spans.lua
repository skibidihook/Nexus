local Spans = {}

local Huge = math.huge
local MergeGap = 0.05
local MinHeadroom = 0.5
local MaxSpans = 65535

function Spans.Build(Tile, Intervals, Columns, Yield)
	local Count = table.create(Columns, 0)
	local First = table.create(Columns, 0)
	local FloorY, CeilY, SurfaceOf, ColumnOf = {}, {}, {}, {}
	local B, T, S = {}, {}, {}
	local Total = 0
	for Column = 1, Columns do
		if Yield then Yield() end
		local List = Intervals[Column]
		if List then
			local N = #List // 3
			for I = 1, N do
				if Yield and I % 32 == 0 then Yield() end
				local Bottom, Top, Code = List[I * 3 - 2], List[I * 3 - 1], List[I * 3]
				local J = I - 1
				while J >= 1 and B[J] > Bottom do
					if Yield and J % 32 == 0 then Yield() end
					B[J + 1], T[J + 1], S[J + 1] = B[J], T[J], S[J]
					J -= 1
				end
				B[J + 1], T[J + 1], S[J + 1] = Bottom, Top, Code
			end
			local W = 1
			for I = 2, N do
				if Yield and I % 32 == 0 then Yield() end
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
				if Yield and I % 32 == 0 then Yield() end
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
