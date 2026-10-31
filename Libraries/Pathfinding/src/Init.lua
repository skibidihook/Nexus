local Surface = Require("Surface")
local Geometry = Require("Geometry")
local Agent = Require("Agent")
local World = Require("World")
local GridSearch = Require("GridSearch")
local SchedulerModule = Require("Scheduler")
local ShapeSource = Require("ShapeSource")

local IsRoblox = typeof ~= nil and game ~= nil and typeof(game) == "Instance"

local Pathfinding = {
	Version = "0.1.1",
	IsRoblox = IsRoblox,
	Surface = Surface,
	Geometry = Geometry,
	Agent = Agent,
	Avoidance = Require("Avoidance"),
	ShapeSource = ShapeSource,
	FixtureSource = Require("FixtureSource"),
	Lanes = Require("Lanes"),
	Internal = {
		Heap = Require("Heap"),
		Raster = Require("Raster"),
		Spans = Require("Spans"),
		World = World,
		GridSearch = GridSearch,
		Scheduler = SchedulerModule,
		Regions = Require("Regions"),
		ReedsShepp = Require("ReedsShepp"),
		CarPlanner = Require("CarPlanner"),
		Controller = Require("Controller"),
		Reference = Require("Reference"),
	},
}

local Scheduler = SchedulerModule.new({ Waiter = IsRoblox and task.wait or nil })
Pathfinding.Scheduler = Scheduler

Pathfinding.World = {}

local Watched = {}

function Pathfinding.Watch(Map, Root)
	local function Touch(Item)
		if Item:IsA("BasePart") and Item.CanCollide then
			local Position = Item.Position
			local Reach = Item.Size.Magnitude * 0.5 + 2
			Map:Invalidate(Position.X - Reach, Position.Z - Reach, Position.X + Reach, Position.Z + Reach)
		end
	end
	Root = Root or workspace
	Map.Connections = { Root.DescendantAdded:Connect(Touch), Root.DescendantRemoving:Connect(Touch) }
	Watched[#Watched + 1] = Map
	return Map
end

function Pathfinding.Unwatch(Map)
	for _, Connection in next, Map.Connections or {} do Connection:Disconnect() end
	Map.Connections = nil
	local Index = table.find(Watched, Map)
	if Index then table.remove(Watched, Index) end
end

function Pathfinding.World.new(Options)
	Options = Options or {}
	local Source = Options.Source
	if not Source and IsRoblox then Source = Require("RobloxSource").new(Options) end
	local Map = World.new(Source, Options)
	if IsRoblox and not Options.Source and Options.Watch ~= false then Pathfinding.Watch(Map) end
	return Map
end

function Pathfinding.FindPath(Map, Who, From, To, Options)
	Options = Options or {}
	local Job = Scheduler:Spawn(function(Job)
		local Reach = Map.Size * Map.Cell
		Map:Refresh(From.X - Reach, From.Z - Reach, From.X + Reach, From.Z + Reach, Job.Yield)
		Map:Refresh(To.X - Reach, To.Z - Reach, To.X + Reach, To.Z + Reach, Job.Yield)
		return GridSearch.Find(Map, Who, From, To, Options, Job.Yield)
	end, Options.Timeout or 10)
	Job.Budget = Options.Budget
	return Job
end

function Pathfinding.PlanCar(Map, Car, Start, Goal, Options)
	Options = Options or {}
	local CarPlanner = Require("CarPlanner")
	local Job = Scheduler:Spawn(function(Job)
		return CarPlanner.Plan(Map, Car, Start, Goal, Options, Job.Yield)
	end, Options.Timeout or 8)
	Job.Budget = Options.Budget
	return Job
end

function Pathfinding.Prepare(Map, Who, Center, Radius, Options)
	Options = Options or {}
	local Job = Scheduler:Spawn(function(Job)
		local Size = Map.Size * Map.Cell
		local Ax, Az = Map:TileOf(Center.X - Radius, Center.Z - Radius)
		local Bx, Bz = Map:TileOf(Center.X + Radius, Center.Z + Radius)
		local Count = 0
		for Tz = Az, Bz do
			for Tx = Ax, Bx do
				local Dx = Center.X - math.clamp(Center.X, Tx * Size, (Tx + 1) * Size)
				local Dz = Center.Z - math.clamp(Center.Z, Tz * Size, (Tz + 1) * Size)
				if Dx * Dx + Dz * Dz <= Radius * Radius then
					Map:Ready(World.Key(Tx, Tz), Who.Profile, Job.Yield)
					Count += 1
					if not Job:Check() then return Count end
				end
			end
		end
		return Count
	end, Options.Timeout or 30)
	Job.Budget = Options.Budget
	return Job
end

local Tasks = {}

function Pathfinding.Destroy()
	if Pathfinding.Connection then
		Pathfinding.Connection:Disconnect()
		Pathfinding.Connection = nil
	end
	Scheduler:Cancel()
	for Handle in next, Tasks do Handle:Cancel() end
	table.clear(Tasks)
	for _, Map in next, table.clone(Watched) do Pathfinding.Unwatch(Map) end
	if Pathfinding.Overlay then pcall(Pathfinding.Overlay.Destroy) end
end

if IsRoblox then
	local TaskModule = Require("Task")
	local Movers = Require("Movers")
	local Driver = Require("Driver")
	Pathfinding.Movers = Movers
	Pathfinding.Overlay = Require("Overlay")
	Pathfinding.Inputs = Require("Inputs")
	Pathfinding.Driver = Driver
	Pathfinding.Internal.RobloxSource = Require("RobloxSource")

	local function Resolve(Value)
		if type(Value) == "function" then return Value() end
		return Value
	end

	local function Spawn(Body)
		local Handle = TaskModule.new(os.clock, task.wait)
		Tasks[Handle] = true
		task.spawn(function()
			local Ok, Err = pcall(Body, Handle)
			if not Ok then Handle:Finish("Failed", nil, Err) end
			if Handle.Status == "Running" then Handle:Finish("Done") end
			Tasks[Handle] = nil
		end)
		return Handle
	end
	Pathfinding.Spawn = Spawn

	function Pathfinding.Walk(Map, Who, Options)
		Options = Options or {}
		local SearchOptions = table.clone(Options)
		SearchOptions.Blocked = table.clone(Options.Blocked or {})
		local Mover = Options.Mover or Movers.Lerp({ Root = Options.Root, Speed = Options.Speed })
		return Spawn(function(Handle)
			local Attempts = 0
			while Handle.Status == "Running" do
				Attempts += 1
				Handle.Attempts = Attempts
				local Root = Resolve(Options.Root)
				local From = Options.From and Resolve(Options.From) or (Root and Root.Position)
				if not From then Handle:Finish("Failed", nil, "NoRoot"); return end
				local Goal = Resolve(Options.Goal)
				local Request = Pathfinding.FindPath(Map, Who, From, Goal, SearchOptions)
				Handle.Inner = Request
				local Path = Request:Await(Options.PlanTimeout or 15)
				Handle.Inner = nil
				if Handle.Status ~= "Running" then return end
				if not Path or #Path.Points == 0 then Handle:Finish("Failed", Path, Path and Path.Status or "PlanFailed"); return end
				Handle.Path = Path
				if Options.OnPath then pcall(Options.OnPath, Path) end
				if not Path.Complete and not Options.AllowPartial then
					Handle:Finish(Path.Status or "Unreachable", Path, "IncompleteRoute")
					return
				end
				if Map.Source and Map.Source.ValidatePath and Options.Validate ~= false then
					local Validation = Scheduler:Spawn(function(Job)
						return table.pack(Map.Source:ValidatePath(Path.Points, Who, Path.Actions, Job.Yield))
					end, Options.PlanTimeout or 15)
					Handle.Inner = Validation
					local Checked, ValidationStatus, ValidationError = Validation:Await(Options.PlanTimeout or 15)
					Handle.Inner = nil
					if Handle.Status ~= "Running" then return end
					if not Checked then Handle:Finish("Failed", Path, ValidationError or ValidationStatus); return end
					local Valid, Position, Blocker = table.unpack(Checked, 1, Checked.n)
					if not Valid then
						Handle.Blocker = Blocker
						Handle.BlockedPosition = Position
						if Attempts >= (Options.Attempts or 4) then Handle:Finish("Failed", Path, "BlockedRoute"); return end
						local Reach = Who.Radius + Map.Cell
						Map:Invalidate(Position.X - Reach, Position.Z - Reach, Position.X + Reach, Position.Z + Reach)
						for X = math.floor((Position.X - Reach) / Map.Cell), math.floor((Position.X + Reach) / Map.Cell) do
							for Z = math.floor((Position.Z - Reach) / Map.Cell), math.floor((Position.Z + Reach) / Map.Cell) do
								if ((X + 0.5) * Map.Cell - Position.X) ^ 2 + ((Z + 0.5) * Map.Cell - Position.Z) ^ 2 <= Reach ^ 2 then
									SearchOptions.Blocked[(X + 1048576) * 2097152 + Z + 1048576] = true
								end
							end
						end
						continue
					end
				end
				local Outcome = Mover(Path.Points, Handle)
				if Handle.Status ~= "Running" then return end
				if Outcome == "Threat" then Handle:Finish("Cancelled", Path, "Threat"); return end
				if Outcome == "Arrived" and Path.Complete then Handle:Finish("Done", Path); return end
				if Outcome == "Arrived" and Path.Status == "Unreachable" then Handle:Finish("Unreachable", Path); return end
				if Outcome == "NoRoot" or Attempts >= (Options.Attempts or 4) then
					Handle:Finish(Outcome == "Arrived" and "Partial" or "Failed", Path, Outcome)
					return
				end
				if Outcome == "Stuck" then
					local Here = Resolve(Options.Root)
					if Here then
						local P = Here.Position
						Map:Invalidate(P.X - 24, P.Z - 24, P.X + 24, P.Z + 24)
						if Handle.StuckTarget then
							local Target = Handle.StuckTarget
							local X, Z = math.floor(Target.X / Map.Cell), math.floor(Target.Z / Map.Cell)
							SearchOptions.Blocked[(X + 1048576) * 2097152 + Z + 1048576] = true
						end
					end
				end
			end
		end)
	end

	function Pathfinding.Drive(Map, Car, Options)
		return Driver.Drive(Pathfinding, Map, Car, Options)
	end

	Pathfinding.Connection = game:GetService("RunService").Heartbeat:Connect(function()
		pcall(Scheduler.Step, Scheduler)
	end)
end

return Pathfinding
