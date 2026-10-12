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
