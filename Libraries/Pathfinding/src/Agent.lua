local Surface = Require("Surface")

local Agent = {}

local Huge, Sqrt, Max, Ceil, Floor, Abs = math.huge, math.sqrt, math.max, math.ceil, math.floor, math.abs

local WalkerCosts = {
	Default = 1,
	Road = 1,
	Pavement = 1,
	Natural = 1.1,
	Water = Huge,
	Wood = 1,
	Curb = 1,
	Ice = 1.3,
}

local CarCosts = {
	Default = 3,
	Road = 1,
	Pavement = 5,
	Natural = 6,
	Water = Huge,
	Wood = 12,
	Curb = 20,
	Ice = 3,
}

local function Round(Value)
	return Floor(Value * 100 + 0.5) / 100
end

local function Profile(Height, Step, Cap, Jump, Drop)
	Jump, Drop = Jump or Step, Drop or Step
	return { Key = `{Round(Height)}|{Round(Step)}|{Round(Cap)}|{Round(Jump)}|{Round(Drop)}`, Height = Height, Step = Step, Cap = Cap, Jump = Jump, Drop = Drop }
end

function Agent.Walker(Options)
	Options = Options or {}
	local Radius = Options.Radius or 1.5
	local Height = Options.Height or 5
	local Step = Options.StepHeight or 2.1
	local Costs = Surface.CostArray(WalkerCosts, Options.Costs)
	if Options.CanSwim then Costs[Surface.Water] = Options.SwimCost or 3 end
	return {
		Kind = "Walker",
		Radius = Radius,
		Height = Height,
		StepHeight = Step,
		CostArray = Costs,
		Profile = Profile(Height, Step, Max(Radius + 2, 3), Max(Step, Options.JumpHeight or Step), Max(Step, Options.MaxDrop or Step)),
	}
end

function Agent.Car(Options)
	Options = Options or {}
	local Width = Options.Width or 8
	local Length = Options.Length or 18
	local Height = Options.Height or 7
	local Step = Options.StepHeight or 1.2
	local Margin = Options.Margin or 0.5
	local Half = Width * 0.5
	local Rows = Options.CircleRows or 2
	local Columns = Options.CircleColumns or 5
	local CellAlong, CellAcross = Length / Columns, Width / Rows
	local CircleRadius = Sqrt((CellAlong * 0.5) ^ 2 + (CellAcross * 0.5) ^ 2)
	local OuterRadius = Sqrt(Half * Half + (Length * 0.5) ^ 2)
	local Circles = {}
	for Column = 1, Columns do
		for Row = 1, Rows do
			Circles[#Circles + 1] = { (Column - 0.5) * CellAlong - Length * 0.5, (Row - 0.5) * CellAcross - Half }
		end
	end
	table.sort(Circles, function(A, B)
		local Ea, Eb = Abs(A[1]) + Abs(A[2]), Abs(B[1]) + Abs(B[2])
		if Ea ~= Eb then return Ea > Eb end
		return A[1] < B[1] or (A[1] == B[1] and A[2] < B[2])
	end)
	local MaxSpeed = Options.MaxSpeed or 40
	local YawRate = Options.YawRate
	local TurnRadius = Options.TurnRadius
	local Reserve = Options.SteerReserve or 0.85
	local SpeedLimit
	if YawRate then
		local Speeds, Curvatures = {}, {}
		local Tightest, TightestSpeed = 0, 1
		for Speed = 1, Ceil(MaxSpeed) do
			local Curvature = YawRate(Speed) / Speed
			Speeds[#Speeds + 1] = Speed
			Curvatures[#Curvatures + 1] = Curvature
			if Curvature > Tightest then Tightest, TightestSpeed = Curvature, Speed end
		end
		TurnRadius = TurnRadius or 1 / Tightest
		SpeedLimit = function(Curvature)
			local Need = Abs(Curvature) / Reserve
			for Index = #Speeds, 1, -1 do
				if Curvatures[Index] >= Need then return Speeds[Index] end
				if Speeds[Index] <= TightestSpeed then break end
			end
			return TightestSpeed
		end
	end
	return {
		Kind = "Car",
		Width = Width,
		Length = Length,
		Height = Height,
		StepHeight = Step,
		Margin = Margin,
		Radius = Half + Margin,
		InnerRadius = Half,
		CircleRadius = CircleRadius,
		OuterRadius = OuterRadius,
		Circles = Circles,
		TurnRadius = TurnRadius or 14,
		ReversePenalty = Options.ReversePenalty,
		MaxReverse = Options.MaxReverse,
		ShortcutCost = Options.ShortcutCost,
		YawRate = YawRate,
		SpeedLimit = SpeedLimit,
		MaxSpeed = MaxSpeed,
		ReverseSpeed = Options.ReverseSpeed or 20,
		LateralAccel = Options.LateralAccel or 30,
		Accel = Options.Accel or 18,
		Decel = Options.Decel or 30,
		CostArray = Surface.CostArray(CarCosts, Options.Costs),
		Profile = Profile(Height, Step, Ceil(OuterRadius + Margin + 1)),
	}
end

function Agent.BloxburgYaw(MaxYaw)
	MaxYaw = MaxYaw or 1.85
	local Cos, Pi = math.cos, math.pi
	return function(Speed)
		Speed = Abs(Speed)
		if Speed < 0.1 then return 0 end
		if Speed <= 15 then return MaxYaw * (Cos(Pi * (Speed - 15) / 15) + 1) * 0.5 end
		return MaxYaw * (Cos(0.023271056693257727 * (Speed - 15)) * 0.5 + 1.5) * 0.5
	end
end

function Agent.BloxburgTaxi(Options)
	Options = Options or {}
	return Agent.Car({
		Width = Options.Width or 8.2,
		Length = Options.Length or 19.3,
		Height = Options.Height or 7.8,
		StepHeight = Options.StepHeight or 1.2,
		MaxSpeed = Options.MaxSpeed or 48,
		ReverseSpeed = Options.ReverseSpeed or 25,
		YawRate = Options.YawRate or Agent.BloxburgYaw(Options.MaxYaw),
		Accel = Options.Accel or 22,
		Decel = Options.Decel or 28,
		LateralAccel = Options.LateralAccel or 80,
		ReversePenalty = Options.ReversePenalty or 3,
		MaxReverse = Options.MaxReverse or 40,
		ShortcutCost = Options.ShortcutCost or 4,
		Costs = Options.Costs,
	})
end

return Agent
