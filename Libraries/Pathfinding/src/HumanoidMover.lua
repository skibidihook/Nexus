local function Resolve(Value)
    if type(Value) == "function" then return Value() end
    return Value
end

return function(Options)
    local Clock = Options.Clock or os.clock
    local Waiter = Options.Waiter
    local MakeVector = Options.Vector or (Vector3 and Vector3.new) or vector.create
    local Zero = MakeVector(0, 0, 0)
    return function(Points, Handle)
        local Humanoid = Resolve(Options.Humanoid)
        local Root = Humanoid and Humanoid.Parent and Humanoid.Parent:FindFirstChild("HumanoidRootPart")
        if not (Humanoid and Root and Root.Parent and Humanoid.Health > 0) then return "NoRoot" end
        local Reach = Options.Reach or 0.5
        local VerticalReach = Options.VerticalReach or 3
        local StuckTime = Options.StuckTime or 1.5
        local function Move(Direction)
            if Options.ApplyMove then Options.ApplyMove(Humanoid, Direction) else Humanoid:Move(Direction, false) end
        end
        local function Finish(Outcome)
            Move(Zero)
            return Outcome
        end
        for Index = 2, #Points do
            local Target = Points[Index]
            local Position = Root.Position
            local Dx, Dz = Target.X - Position.X, Target.Z - Position.Z
            local BestDistance = math.sqrt(Dx * Dx + Dz * Dz)
            local LastProgress = Clock()
            local Deadline = Clock() + BestDistance / math.max(Humanoid.WalkSpeed, 1) * 3 + 3
            Handle.Target = Target
            if Handle.Status ~= "Running" then return Finish("Cancelled") end
            if Options.Actions and Options.Actions[Index] == "Jump" and Options.Jump then Options.Jump(Humanoid) end
            while true do
                if Handle.Status ~= "Running" then return Finish("Cancelled") end
                if not Root.Parent or Humanoid.Health <= 0 then return Finish("NoRoot") end
                Position = Root.Position
                Dx, Dz = Target.X - Position.X, Target.Z - Position.Z
                local Distance = math.sqrt(Dx * Dx + Dz * Dz)
                Handle.TargetDistance = Distance
                local Offset = Resolve(Options.Offset) or 3
                if Distance <= Reach and math.abs(Position.Y - Target.Y - Offset) <= VerticalReach then break end
                if Distance < BestDistance - (Options.ProgressEpsilon or 0.1) then
                    BestDistance, LastProgress = Distance, Clock()
                elseif Clock() - LastProgress > StuckTime or Clock() > Deadline then
                    Handle.StuckPosition = Position
                    Handle.StuckTarget = Target
                    return Finish("Stuck")
                end
                if Distance > 0.01 then Move(MakeVector(Dx / Distance, 0, Dz / Distance)) else Move(Zero) end
                Waiter()
            end
            Handle.Progress = Index
        end
        return Finish("Arrived")
    end
end
