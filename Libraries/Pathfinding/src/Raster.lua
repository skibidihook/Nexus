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
