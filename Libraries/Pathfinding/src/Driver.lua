local CarPlanner = Require("CarPlanner")
local Controller = Require("Controller")
local Reference = Require("Reference")
local LaneModule = Require("Lanes")

local Driver = {}

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Sqrt, Atan2, Abs, Max, Min, Cos, Sin, Floor, Pi = math.sqrt, math.atan2, math.abs, math.max, math.min, math.cos, math.sin, math.floor, math.pi

local function Resolve(Value)
	if type(Value) == "function" then return Value() end
	return Value
end

local function Wrap(Angle)
	return (Angle + Pi) % (2 * Pi) - Pi
end

function Driver.Region(Value)
	if not Value then return nil end
	local CF, Size = Value.CFrame, Value.Size
	local Right = CF.RightVector
	local Angle = Atan2(Right.Z, Right.X)
	return { X = CF.Position.X, Y = CF.Position.Y, Z = CF.Position.Z, HalfX = Size.X * 0.5, HalfZ = Size.Z * 0.5, Cos = Cos(Angle), Sin = Sin(Angle) }
end

function Driver.Blocked(Map, MinX, MinZ, MaxX, MaxZ, Y, Height, Inflate, Ignore, Into, Self)
	local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = Ignore or {}
	Params.RespectCanCollide = true
	local Center = CFrame.new((MinX + MaxX) * 0.5, Y + Height * 0.5, (MinZ + MaxZ) * 0.5)
	local Parts = Workspace:GetPartBoundsInBox(Center, Vector3.new(MaxX - MinX, Height, MaxZ - MinZ), Params)
	local Blocked = Into or {}
	local Cell = Map.Cell
	local Marked = 0
	local SelfRoot = Self and Self.AssemblyRootPart
	for Index = 1, #Parts do
		local Part = Parts[Index]
		if not Part.Anchored and not Part:IsGrounded() and (not SelfRoot or Part.AssemblyRootPart ~= SelfRoot) then
			local Position, Size = Part.Position, Part.Size
			local Model = Part:FindFirstAncestorOfClass("Model")
			local Person = Model ~= nil and Model:FindFirstChildOfClass("Humanoid") ~= nil
			local Reach = Sqrt(Size.X * Size.X + Size.Z * Size.Z) * 0.5 + (Person and Inflate * 0.4 or Inflate)
			for Cx = Floor((Position.X - Reach) / Cell), Floor((Position.X + Reach) / Cell) do
				for Cz = Floor((Position.Z - Reach) / Cell), Floor((Position.Z + Reach) / Cell) do
					Blocked[(Cx + 1048576) * 2097152 + Cz + 1048576] = true
					Marked += 1
				end
			end
		end
	end
	return Blocked, Marked
end

function Driver.Drive(Pathfinding, Map, Car, Options)
	local Scheduler = Pathfinding.Scheduler
	local Input = Options.Input
	local Region = Driver.Region(Options.Region)
	local RoutePoints = Options.Route
	local GoalValue = Options.Goal
	local GoalPosition, GoalHeading
	if typeof(GoalValue) == "CFrame" then
		GoalPosition = GoalValue.Position
		local Look = GoalValue.LookVector
		GoalHeading = Options.GoalHeading ~= false and Atan2(Look.Z, Look.X) or nil
	elseif typeof(GoalValue) == "Vector3" then
		GoalPosition = GoalValue
	elseif Region then
		GoalPosition = Vector3.new(Region.X, Region.Y, Region.Z)
	elseif RoutePoints and #RoutePoints > 0 then
		GoalPosition = RoutePoints[#RoutePoints]
	end
	local Arrive = Options.Arrive or 4
	local Ignore = Options.Ignore or {}
	local Budget = Options.Budget or 0.004
	local Lanes = Options.Lanes
	local LaneSide = type(Lanes) == "table" and Lanes.Side or 1
	local Fallback = Options.LaneOffset or 0
	local Laned = Lanes ~= nil or Fallback ~= 0
	local RoughTrust = Options.RoughTrust or 30
	local CautionSpeed = Options.CautionSpeed or 10
	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude
	RayParams.FilterDescendantsInstances = Ignore

	local function Run(Handle)
		if not GoalPosition then Handle:Finish("Failed", nil, "NoGoal"); return end
		if not Input.Begin() then Handle:Finish("Failed", nil, "NoInput"); return end
		local Started = os.clock()
		local Status = "Starting"
		local Speed, History = 0, {}
		local Ref, Cursor, Validated, Validation = nil, 1, 0, nil
		local Blocks = {}
		local Plan, PlanRef, Drive
		local Pending, PendingInfo, RouteJob, Connect
		local LaneJob, LanePoints, LaneOptions
		local Failures, Stucks, Reach, Parks = 0, 0, 0, 0
		local StuckSince
		local RetryAt = 0
		local Dynamic, DynamicUntil = {}, 0
		Handle.PlanLog = {}
		Handle.Blocks = Blocks

		local function Report(Text)
			if Text ~= Status then
				Status = Text
				Handle.Phase = Text
				if Options.OnStatus then pcall(Options.OnStatus, Text) end
			end
		end

		local function Ground(Position)
			local Hit = Workspace:Raycast(Position + Vector3.new(0, 2, 0), Vector3.new(0, -30, 0), RayParams)
			return Hit and Hit.Position.Y or Position.Y - Car.Height * 0.5
		end

		local function Finalize(Profile)
			Ref = Reference.Build(LanePoints, {
				CornerRadius = Options.CornerRadius or 18,
				LaneOffset = Fallback,
				LaneProfile = Profile,
				MinRadius = Car.TurnRadius * 1.25,
				Spacing = 0.8,
			})
			Handle.Reference = Ref
			Handle.Lanes = Profile
			Cursor, Validated = 1, 1
		end

		local function Constant()
			return Fallback
		end

		local function BuildReference(Points)
			local Trimmed, Lateral, Ux, Uz = false, 0, 1, 0
			if Laned and Options.TrimGoal ~= false then
				Points, Trimmed, Lateral, Ux, Uz = Reference.Trim(Points, GoalPosition.X, GoalPosition.Z, { Reach = Options.TrimReach or 24, Side = LaneSide })
			end
			if not Trimmed then
				local Last = Points[#Points]
				if not Last or (Last.X - GoalPosition.X) ^ 2 + (Last.Z - GoalPosition.Z) ^ 2 > 1 then
					Points = table.clone(Points)
					Points[#Points + 1] = GoalPosition
				end
			end
			Handle.Trimmed = Trimmed
			LanePoints = Reference.Clean(Points)
			local Count = #LanePoints
			if not Laned or Count < 2 then
				Finalize(nil)
				return
			end
			local Taper
			if not Trimmed then
				local Total = 0
				for Index = 2, Count do
					local A, B = LanePoints[Index - 1], LanePoints[Index]
					Total += Sqrt((B.X - A.X) ^ 2 + (B.Z - A.Z) ^ 2)
				end
				local A, B = LanePoints[Count - 1], LanePoints[Count]
				Taper = Total - Sqrt((B.X - A.X) ^ 2 + (B.Z - A.Z) ^ 2)
			end
			LaneOptions = { Step = Options.LaneStep or 4, Fallback = Fallback, TaperFrom = Taper, PullIn = Options.PullIn }
			if Trimmed then
				if Region then
					local End = LanePoints[Count]
					local Nx, Nz = -Uz, Ux
					local Lo, Hi = math.huge, -math.huge
					for _, Along in next, { -Region.HalfX, Region.HalfX } do
						for _, Across in next, { -Region.HalfZ, Region.HalfZ } do
							local Px = Region.X + Along * Region.Cos - Across * Region.Sin
							local Pz = Region.Z + Along * Region.Sin + Across * Region.Cos
							local Value = (Px - End.X) * Nx + (Pz - End.Z) * Nz
							Lo, Hi = Min(Lo, Value), Max(Hi, Value)
						end
					end
					local Inset = Min(3, (Hi - Lo) * 0.25)
					LaneOptions.EndRange = { Lo + Inset, Hi - Inset }
				else
					LaneOptions.EndOffset = Lateral
				end
			end
			if not Lanes then
				Finalize(LaneModule.Profile(LanePoints, Constant, LaneOptions))
				return
			end
			Report("Laning")
			LaneJob = Scheduler:Spawn(function(Job)
				local Finder = Lanes
				if type(Lanes) == "table" then
					local Config = table.clone(Lanes)
					if Lanes.Physical ~= false then
						local Costs, RoadCost, Yield = Car.CostArray, Lanes.RoadCost or 1, Job.Yield
						Config.Scanner = LaneModule.Scanner(function(X, Z, Y, Tolerance)
							local FloorY, Code = Map:FloorAt(X, Z, Y, Tolerance, Yield)
							if FloorY then return true, FloorY, Code end
							return nil
						end, function(Code)
							return Costs[Code] <= RoadCost
						end, Lanes)
					end
					Finder = LaneModule.Finder(Config)
				end
				return LaneModule.Profile(LanePoints, Finder, LaneOptions, Job.Yield)
			end, Options.LaneTimeout or 8)
			LaneJob.Budget = Options.LaneBudget or Budget
		end

		local function Search(A, B)
			Report("Routing")
			local Agent = { Kind = "Route", Radius = Car.Width * 0.5 + Car.Margin + (Options.RoutePadding or 1.5), Profile = Car.Profile, CostArray = Car.CostArray }
			local Job = Pathfinding.FindPath(Map, Agent, Vector3.new(A.X, Ground(A), A.Z), B, { Timeout = Options.RouteTimeout or 25, Budget = Budget, MaxNodes = 250000, Tolerance = 12 })
			return Job
		end

		local function Inside(X, Z)
			if not Region then return false end
			local Dx, Dz = X - Region.X, Z - Region.Z
			return Abs(Dx * Region.Cos + Dz * Region.Sin) <= Region.HalfX and Abs(-Dx * Region.Sin + Dz * Region.Cos) <= Region.HalfZ
		end

		local function GoalFor(Index)
			if Index >= #Ref.X then
				return { X = GoalPosition.X, Y = Ref.Y[#Ref.Y], Z = GoalPosition.Z, Heading = GoalHeading, Region = Region, Tolerance = Arrive * 0.75 }, true
			end
			return { X = Ref.X[Index], Y = Ref.Y[Index], Z = Ref.Z[Index], Heading = Ref.H[Index], Tolerance = 2.5, HeadingTolerance = math.rad(15) }, false
		end

		local function LaneNear(From, To)
			local Points = {}
			for Index = Max(1, From), Min(#Ref.X, To), 5 do
				Points[#Points + 1] = { X = Ref.X[Index], Z = Ref.Z[Index] }
			end
			if #Points < 2 then return nil end
			return { Points = Points, Offset = 0, Weight = Options.LaneWeight or 0.12 }
		end

		local function PastBlocks(Target)
			for _, Block in next, Blocks do
				if Block.Outcome ~= "Trusted" and Target >= Block[1] - 8 and Target <= Block[2] then return Reference.Ahead(Ref, Block[2], 25 + (Block.Extra or 0)) end
			end
			return Target
		end

		local function Rejoin(Start, Target, Prefix, Block)
			Target = PastBlocks(Target)
			local Goal, IsFinal = GoalFor(Target)
			if os.clock() > DynamicUntil then table.clear(Dynamic) end
			local Pad = 50
			Driver.Blocked(Map, Min(Start.X, Goal.X) - Pad, Min(Start.Z, Goal.Z) - Pad, Max(Start.X, Goal.X) + Pad, Max(Start.Z, Goal.Z) + Pad, Start.Y, Car.Height + 4, Car.CircleRadius + Car.Margin, Ignore, Dynamic, Resolve(Options.Body))
			local Relax = Block ~= nil and Block.Relax == true
			local PlanOptions = {
				Lane = LaneNear(Cursor, Target + 10),
				Blocked = next(Dynamic) and Dynamic or nil,
				MaxNodes = (Options.MaxNodes or 12000) * (Relax and 2 or 1),
				Margin = Relax and Min(Car.Margin, 0.25) or nil,
			}
			Pending = Scheduler:Spawn(function(Job)
				return CarPlanner.Plan(Map, Car, Start, Goal, PlanOptions, Job.Yield)
			end, Options.PlanTimeout or 6)
			Pending.Budget = Budget
			PendingInfo = { Target = Target, Prefix = Prefix, Final = IsFinal, Block = Block }
			Handle.Plans = (Handle.Plans or 0) + 1
			Report((Prefix or Block) and "Detouring" or "Joining")
		end

		local function Caution(Path, Sources)
			local Caps
			for _, Block in next, Blocks do
				if Block.Outcome == "Caution" then
					for Index = 1, #Path.X do
						local Source = Sources[Index]
						if Source and Source >= Block[1] - 12 and Source <= Block[2] + 4 then
							Caps = Caps or {}
							Caps[Index] = CautionSpeed
						end
					end
				end
			end
			Path.Cap = Caps
		end

		local function Compose(Joined, Info, CurrentSpeed)
			local Path = { X = {}, Y = {}, Z = {}, H = {}, D = {}, K = {} }
			local Sources = {}
			local function Push(X, Y, Z, H, D, K, Source)
				local N = #Path.X + 1
				Path.X[N], Path.Y[N], Path.Z[N], Path.H[N], Path.D[N], Path.K[N] = X, Y, Z, H, D, K
				Sources[N] = Source
			end
			if Info.Prefix and Plan then
				for Index = Info.Prefix[1], Info.Prefix[2] do
					Push(Plan.X[Index], Plan.Y[Index], Plan.Z[Index], Plan.H[Index], Plan.D[Index], Plan.K[Index], PlanRef[Index])
				end
			end
			for Index = #Path.X > 0 and 2 or 1, #Joined.X do
				Push(Joined.X[Index], Joined.Y[Index], Joined.Z[Index], Joined.H[Index], Joined.D[Index], Joined.K[Index], 0)
			end
			if not Info.Final then
				for Index = Info.Target + 1, #Ref.X do
					Push(Ref.X[Index], Ref.Y[Index], Ref.Z[Index], Ref.H[Index], 1, Ref.K[Index], Index)
				end
			end
			Path.EndSpeed = 0
			Caution(Path, Sources)
			Controller.Profile(Path, Car, { StartSpeed = Max(Abs(CurrentSpeed), 4) })
			Plan, PlanRef = Path, Sources
			Drive = Controller.new(Path, Car, { Arrive = Arrive, Decel = Options.Decel })
			Report("Driving")
		end

		local function Remaining(Points, X, Z)
			if #Points < 2 then return table.clone(Points), Sqrt((Points[1].X - X) ^ 2 + (Points[1].Z - Z) ^ 2) end
			local BestIndex, BestT, Best = 1, 0, math.huge
			for Index = 1, #Points - 1 do
				local A, B = Points[Index], Points[Index + 1]
				local Ex, Ez = B.X - A.X, B.Z - A.Z
				local LengthSq = Ex * Ex + Ez * Ez
				local T = LengthSq > 1e-6 and math.clamp(((X - A.X) * Ex + (Z - A.Z) * Ez) / LengthSq, 0, 1) or 0
				local Distance = (X - A.X - Ex * T) ^ 2 + (Z - A.Z - Ez * T) ^ 2
				if Distance < Best then BestIndex, BestT, Best = Index, T, Distance end
			end
			local A, B = Points[BestIndex], Points[BestIndex + 1]
			local Out = { Vector3.new(A.X + (B.X - A.X) * BestT, A.Y + (B.Y - A.Y) * BestT, A.Z + (B.Z - A.Z) * BestT) }
			for Index = BestIndex + 1, #Points do Out[#Out + 1] = Points[Index] end
			return Out, Sqrt(Best)
		end

		local Origin = Resolve(Options.Body)
		if not Origin then Handle:Finish("Failed", nil, "NoBody"); return end
		local From = Origin.Position
		if RoutePoints and #RoutePoints >= 1 then
			local Points, Gap = Remaining(RoutePoints, From.X, From.Z)
			if Gap > 40 and Options.GlobalRoute ~= false then
				Connect = Points
				RouteJob = Search(From, Points[1])
			else
				BuildReference(Points)
			end
		elseif (GoalPosition.X - From.X) ^ 2 + (GoalPosition.Z - From.Z) ^ 2 > 40 * 40 and Options.GlobalRoute ~= false then
			RouteJob = Search(From, GoalPosition)
		else
			BuildReference({ From })
		end

		while Handle.Status == "Running" do
			RunService.Heartbeat:Wait()
			local Now = os.clock()
			if Options.Alive and not Options.Alive() then Handle:Finish("Cancelled"); return end
			if Now - Started > (Options.Timeout or 240) then Handle:Finish("Failed", Plan, "Timeout"); return end
			local Body = Resolve(Options.Body)
			if not (Body and Body.Parent) then Handle:Finish("Failed", nil, "NoBody"); return end
			local Frame = Body.CFrame
			local Position = Frame.Position
			local Look = Frame.LookVector
			local Heading = Atan2(Look.Z, Look.X)
			History[#History + 1] = { Now, Position.X, Position.Z }
			while #History > 2 and Now - History[2][1] >= 0.12 do table.remove(History, 1) end
			local Oldest = History[1]
			if Oldest and Now - Oldest[1] > 0.02 then
				Speed = ((Position.X - Oldest[2]) * Cos(Heading) + (Position.Z - Oldest[3]) * Sin(Heading)) / (Now - Oldest[1])
			end
			Handle.Speed = Speed
			if Options.Telemetry then
				local Log = Options.Telemetry
				Log[#Log + 1] = { Now - Started, Position.X, Position.Z, Heading, Speed, Input.Steer or 0, Input.Throttle or 0, Status }
			end

			local function Hold()
				Input.Set(0, Abs(Speed) > 1 and (Speed > 0 and -0.6 or 0.6) or 0)
			end

			local Near = (Position.X - GoalPosition.X) ^ 2 + (Position.Z - GoalPosition.Z) ^ 2
			if Abs(Speed) < 2.5 and (Inside(Position.X, Position.Z) or Near <= Arrive * Arrive) and Now - Started > 1 then
				Input.Set(0, 0)
				Handle:Finish("Done", Plan)
				return
			end

			if RouteJob then
				if RouteJob.Status == "Running" then
					Hold()
					continue
				end
				local Found = RouteJob.Result
				Handle.Route = Found
				RouteJob = nil
				local Points = (Found and Found.Points and #Found.Points >= 2) and table.clone(Found.Points) or { Position }
				if Connect then
					local Start = (Points[#Points] - Connect[1]).Magnitude < 4 and 2 or 1
					for Index = Start, #Connect do Points[#Points + 1] = Connect[Index] end
					Connect = nil
				end
				BuildReference(Points)
			end

			if LaneJob then
				if LaneJob.Status == "Running" then
					Hold()
					continue
				end
				local Profile = LaneJob.Status == "Done" and LaneJob.Result or LaneModule.Profile(LanePoints, Constant, LaneOptions)
				Handle.LaneCpu = LaneJob.Cpu
				Handle.LaneError = LaneJob.Error
				LaneJob = nil
				Finalize(Profile)
			end
			if not Ref then
				Hold()
				continue
			end

			if Validation and Validation.Status ~= "Running" then
				local First = Validation.Range[1]
				local Tail = Blocks[#Blocks]
				local Continued = false
				for _, Found in next, Validation.Result or {} do
					if Tail and Tail.Open and not Continued and Found[1] <= First then
						Tail[2] = Found[2]
						Tail.Hit = Tail.Hit or Found.Hit
						Tail.Open = Found.Open
						Continued = true
					else
						Blocks[#Blocks + 1] = { Found[1], Found[2], Hit = Found.Hit, Open = Found.Open }
					end
				end
				if Tail and Tail.Open and not Continued then Tail.Open = nil end
				Validated = Validation.Range[2]
				Validation = nil
				local Last = #Ref.X
				for _, Block in next, Blocks do
					if Validated >= Last then Block.Open = nil end
					if not Block.Open and not Block.Hit and not Block.Outcome and Ref.S[Block[2]] - Ref.S[Block[1]] >= RoughTrust then
						Block.Outcome = "Trusted"
						Block.Handled = true
					end
				end
			end
			local Count = #Ref.X
			if not Validation and Validated < Count and Ref.S[Validated] - Ref.S[Cursor] < (Options.ValidateAhead or 260) then
				local First = Validated
				local Last = Reference.Ahead(Ref, First, Options.ValidateChunk or 160)
				local CheckOptions = { Blocked = next(Dynamic) and Dynamic or nil }
				Validation = Scheduler:Spawn(function(Job)
					return CarPlanner.Validate(Map, Car, Ref, First, Last, CheckOptions, Job.Yield)
				end, 10)
				Validation.Budget = Budget
				Validation.Range = { First, Last }
			end

			Cursor = Reference.Nearest(Ref, Position.X, Position.Z, Max(1, Cursor - 25), Min(Count, Cursor + 300))

			if Pending and Pending.Status ~= "Running" then
				local Finished, Info = Pending, PendingInfo
				local Result = Finished.Result
				Pending, PendingInfo = nil, nil
				Handle.PlanCpu = (Handle.PlanCpu or 0) + Finished.Cpu
				local Block = Info.Block
				table.insert(Handle.PlanLog, string.format("%s %s exp=%d pts=%d %s", (Info.Prefix or Block) and "detour" or "join", Result and Result.Status or "Failed", Result and Result.Expanded or 0, Result and Result.X and #Result.X or 0, Result and Result.Diagnostics or ""))
				if Result and Result.Complete and Result.X and #Result.X < 2 and Info.Final then
					Input.Set(0, 0)
					Handle:Finish("Done", Plan)
					return
				elseif Result and Result.Complete and Result.X and #Result.X >= 1 then
					Failures, Reach = 0, 0
					if Block then Block.Outcome = "Detoured" end
					Compose(Result, Info, Speed)
				elseif Block and Drive then
					if Result and Result.Status == "BadGoal" and (Block.Extra or 0) < 75 then
						Block.Extra = (Block.Extra or 0) + 25
						Block.Handled = nil
					elseif Block.Hit and not Block.Relax then
						Block.Relax = true
						Block.Handled = nil
					else
						Block.Outcome = Block.Hit and "Caution" or "Accepted"
						if Block.Hit then
							Caution(Plan, PlanRef)
							Controller.Profile(Plan, Car, { StartSpeed = Plan.V[1] })
						end
					end
					Report("Driving")
				else
					Failures += 1
					Reach += 25
					RetryAt = Now + 0.6
					if Failures >= (Options.MaxFailures or 8) then Handle:Finish("Failed", Result, Result and Result.Status or "PlanFailed"); return end
					if not Info.Prefix then Drive, Plan = nil, nil end
				end
			end

			if not Drive then
				if not Pending and Now >= RetryAt and Validated >= Min(Count, Reference.Ahead(Ref, Cursor, 50)) then
					local Target = Reference.Ahead(Ref, Cursor, 30 + Abs(Speed) * 0.6 + Reach)
					local Offset = Sqrt((Ref.X[Cursor] - Position.X) ^ 2 + (Ref.Z[Cursor] - Position.Z) ^ 2)
					if Offset < 2 and Abs(Wrap(Heading - Ref.H[Cursor])) < 0.35 and Speed > -1 and Reach == 0 then
						Compose({ X = { Position.X }, Y = { Ref.Y[Cursor] }, Z = { Position.Z }, H = { Heading }, D = { 1 }, K = { 0 } }, { Target = Cursor }, Speed)
					else
						Rejoin({ X = Position.X, Y = Ground(Position), Z = Position.Z, Heading = Heading, Direction = Speed < -1 and -1 or 1, Moving = Abs(Speed) > 4 }, Target, nil)
					end
				end
				if not Drive then
					Hold()
					continue
				end
			end

			if not Pending then
				for _, Block in next, Blocks do
					if not Block.Handled and not Block.Open and Block[2] >= Cursor then
						local Gap = Ref.S[Max(Block[1], Cursor)] - Ref.S[Cursor]
						if Gap < Max(70, Abs(Speed) * 2.5) then
							Block.Handled = true
							Block.Attempts = (Block.Attempts or 0) + 1
							local Beyond = Reference.Ahead(Ref, Block[2], 25 + (Block.Extra or 0))
							local Ahead = Plan.S[Drive.Index] + Max(8, Abs(Speed) * 0.9)
							local Splice = Drive.Index
							while Splice < #Plan.X and Plan.S[Splice] < Ahead do Splice += 1 end
							local SpliceRef = PlanRef[Splice] or 0
							if Gap > 25 and SpliceRef > 0 and SpliceRef < Block[1] then
								local Start = { X = Plan.X[Splice], Y = Plan.Y[Splice], Z = Plan.Z[Splice], Heading = Plan.H[Splice], Direction = Plan.D[Splice], Moving = (Plan.V[Splice] or 0) > 4 }
								Rejoin(Start, Beyond, { Drive.Index, Splice }, Block)
							else
								Rejoin({ X = Position.X, Y = Ground(Position), Z = Position.Z, Heading = Heading, Direction = Speed < -1 and -1 or 1, Moving = Abs(Speed) > 4 }, Beyond, nil, Block)
							end
							break
						end
					end
				end
			end

			local Steer, Throttle, State = Drive:Update(Position.X, Position.Z, Heading, Speed)
			if State == "Arrived" then
				if Region and not Inside(Position.X, Position.Z) and Parks < (Options.MaxParks or 2) then
					Parks += 1
					if Pending then Pending:Cancel() end
					Drive, Plan = nil, nil
					Rejoin({ X = Position.X, Y = Ground(Position), Z = Position.Z, Heading = Heading, Direction = 1, Moving = false }, #Ref.X, nil)
					Report("Parking")
					continue
				end
				Input.Set(0, 0)
				Handle:Finish("Done", Plan)
				return
			elseif State == "Deviated" then
				Drive, Plan = nil, nil
				Report("Recovering")
				continue
			end

			local Dir = Throttle >= 0 and 1 or -1
			if Abs(Speed) > 2 then Dir = Speed > 0 and 1 or -1 end
			local Brake = Speed * Speed / (2 * Car.Decel) + 4
			local Forward = Vector3.new(Cos(Heading), 0, Sin(Heading))
			local Eye = Position + Vector3.new(0, 1, 0)
			local Hit = Workspace:Blockcast(CFrame.lookAt(Eye, Eye + Forward * Dir), Vector3.new(Car.Width - 1, Max(1, Car.Height - Car.StepHeight - 2.5), 2), Forward * Dir * (Car.Length * 0.5 + Brake), RayParams)
			if Hit and Hit.Instance and not Hit.Instance.Anchored and not Hit.Instance:IsGrounded() and Hit.Instance.AssemblyRootPart ~= Body.AssemblyRootPart then
				Throttle = -Dir * Min(1, Abs(Speed) / 10 + 0.2)
				Steer = 0
				if Abs(Speed) < 1.5 then
					local Spot = Hit.Instance.Position
					local Spread = Car.CircleRadius + Car.Margin + Hit.Instance.Size.Magnitude * 0.5
					for Cx = Floor((Spot.X - Spread) / Map.Cell), Floor((Spot.X + Spread) / Map.Cell) do
						for Cz = Floor((Spot.Z - Spread) / Map.Cell), Floor((Spot.Z + Spread) / Map.Cell) do
							Dynamic[(Cx + 1048576) * 2097152 + Cz + 1048576] = true
						end
					end
					DynamicUntil = os.clock() + 6
					Drive, Plan = nil, nil
					Reach += 30
					Report("Blocked")
				end
			end

			if Abs(Throttle) > 0.3 and Abs(Speed) < 0.8 then
				StuckSince = StuckSince or Now
				if Now - StuckSince > (Options.StuckTime or 2) then
					StuckSince = nil
					if Near <= (Arrive * 3) ^ 2 then
						Input.Set(0, 0)
						Handle:Finish("Done", Plan)
						return
					end
					Stucks += 1
					if Stucks >= (Options.MaxStucks or 5) then Handle:Finish("Failed", Plan, "Stuck"); return end
					Map:Invalidate(Position.X - 40, Position.Z - 40, Position.X + 40, Position.Z + 40)
					Drive, Plan = nil, nil
					Report("Unsticking")
				end
			else
				StuckSince = nil
			end

			if Drive then Input.Set(Steer, Throttle) end
		end
	end

	return Pathfinding.Spawn(function(Handle)
		local Ok, Err = pcall(Run, Handle)
		Input.Finish()
		if not Ok then Handle:Finish("Failed", nil, Err) end
	end)
end

return Driver
