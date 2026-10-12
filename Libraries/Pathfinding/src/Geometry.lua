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
