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
