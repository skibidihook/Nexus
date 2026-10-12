local Movers = {}

local RunService = game:GetService("RunService")

local function Resolve(Value)
	if type(Value) == "function" then return Value() end
	return Value
end

function Movers.RootOffset(Character)
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	local Root = Character and Character:FindFirstChild("HumanoidRootPart")
	if not (Humanoid and Root) then return 3 end
	if Humanoid.RigType == Enum.HumanoidRigType.R15 then return Humanoid.HipHeight + Root.Size.Y * 0.5 end
	return Root.Size.Y * 0.5 + 2
end

function Movers.Lerp(Options)
	Options = Options or {}
	return function(Points, Handle)
		local Root = Resolve(Options.Root)
		if not (Root and Root.Parent) then return "NoRoot" end
		local Offset = Options.Offset or Movers.RootOffset(Root.Parent)
		local Speed = Options.Speed or 20
		local Current = Root.Position
		for Index = 2, #Points do
			local Target = Points[Index] + Vector3.new(0, Offset, 0)
			local Start = Index == 2 and Current or Points[Index - 1] + Vector3.new(0, Offset, 0)
			local Delta = Target - Start
			local Distance = Delta.Magnitude
			if Distance > 0.05 then
				local Flat = Vector3.new(Delta.X, 0, Delta.Z)
				local Rotation = Flat.Magnitude > 0.1 and CFrame.lookAt(Vector3.zero, Flat).Rotation or Root.CFrame.Rotation
				local Duration = Distance / Resolve(Speed)
				local Elapsed = 0
				while Elapsed < Duration do
					Elapsed += RunService.Heartbeat:Wait()
					if Handle.Status ~= "Running" then return "Cancelled" end
					Root = Resolve(Options.Root)
					if not (Root and Root.Parent) then return "NoRoot" end
					Root.CFrame = CFrame.new(Start:Lerp(Target, math.min(Elapsed / Duration, 1))) * Rotation
					Root.AssemblyLinearVelocity = Vector3.zero
				end
			end
			Handle.Progress = Index
		end
		return "Arrived"
	end
end

function Movers.Humanoid(Options)
	Options = Options or {}
	return function(Points, Handle)
		local Humanoid = Resolve(Options.Humanoid)
		local Root = Humanoid and Humanoid.Parent and Humanoid.Parent:FindFirstChild("HumanoidRootPart")
		if not (Humanoid and Root) then return "NoRoot" end
		local Reach = Options.Reach or 1.5
		local StuckTime = Options.StuckTime or 1.2
		for Index = 2, #Points do
			local Target = Points[Index]
			local Last, LastMoved = Root.Position, os.clock()
			local Deadline = os.clock() + (Target - Root.Position).Magnitude / math.max(Humanoid.WalkSpeed, 1) * 2 + 2
			Humanoid:MoveTo(Target)
			while true do
				RunService.Heartbeat:Wait()
				if Handle.Status ~= "Running" then
					Humanoid:Move(Vector3.zero)
					return "Cancelled"
				end
				if not Root.Parent or Humanoid.Health <= 0 then return "NoRoot" end
				local Position = Root.Position
				local Flat = Vector3.new(Target.X - Position.X, 0, Target.Z - Position.Z)
				if Flat.Magnitude <= Reach then break end
				if (Position - Last).Magnitude > 0.5 then
					Last, LastMoved = Position, os.clock()
				elseif os.clock() - LastMoved > StuckTime then
					return "Stuck"
				end
				if os.clock() > Deadline then return "Stuck" end
				Humanoid:MoveTo(Target)
			end
			Handle.Progress = Index
		end
		return "Arrived"
	end
end

function Movers.Callback(Fn)
	return function(Points, Handle)
		return Fn(Points, Handle) or "Arrived"
	end
end

return Movers
