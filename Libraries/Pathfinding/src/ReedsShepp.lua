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
