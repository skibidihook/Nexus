local CreateMover = require("../src/HumanoidMover")
local T = require("./Framework")
local Vector = vector.create

local function Fixture(Step)
    local State = { Time = 0, Frames = 0, Direction = Vector(0, 0, 0) }
    local Root = { Position = Vector(0, 3, 0), Parent = {} }
    local Character = {}
    function Character:FindFirstChild(Name) return Name == "HumanoidRootPart" and Root or nil end
    local Humanoid = { Parent = Character, Health = 100, WalkSpeed = 16 }
    function Humanoid:Move(Direction) State.Direction = Direction end
    local Handle = { Status = "Running" }
    local Mover = CreateMover({
        Humanoid = Humanoid,
        Vector = Vector,
        Offset = 3,
        Clock = function() return State.Time end,
        Waiter = function()
            State.Time += 1 / 60
            State.Frames += 1
            local Proposed = Root.Position + State.Direction * Humanoid.WalkSpeed / 60
            Root.Position = Step and Step(State, Root.Position, Proposed, Handle) or Proposed
            if State.Frames > 2000 then error("mover exceeded fixture frame limit") end
        end,
    })
    return Mover, Root, Handle, State
end

T.Case("reaches a waypoint instead of stopping at MoveTo tolerance", function()
    local Mover, Root, Handle, State = Fixture()
    T.Equal(Mover({ Vector(0, 0, 0), Vector(6, 0, 0) }, Handle), "Arrived")
    T.True(math.abs(Root.Position.X - 6) <= 0.5)
    T.Equal(vector.magnitude(State.Direction), 0)
end)

T.Case("turns around a wall without cutting the corner", function()
    local Mover, Root, Handle = Fixture(function(State, Previous, Proposed)
        if Proposed.X >= 3 and Proposed.X <= 7 and Proposed.Z <= 2 then return Previous end
        return Proposed
    end)
    T.Equal(Mover({ Vector(0, 0, 0), Vector(2, 0, 3), Vector(8, 0, 3), Vector(8, 0, 0) }, Handle), "Arrived")
    T.True(vector.magnitude(Root.Position - Vector(8, 3, 0)) <= 0.5)
end)

T.Case("cancellation stops the humanoid immediately", function()
    local Mover, Root, Handle, State = Fixture(function(Current, Previous, Proposed, CurrentHandle)
        if Current.Frames == 2 then CurrentHandle.Status = "Cancelled" end
        return Proposed
    end)
    T.Equal(Mover({ Vector(0, 0, 0), Vector(20, 0, 0) }, Handle), "Cancelled")
    T.Equal(vector.magnitude(State.Direction), 0)
end)

T.Case("blocked motion reports its target and stops", function()
    local Mover, Root, Handle, State = Fixture(function(Current, Previous) return Previous end)
    T.Equal(Mover({ Vector(0, 0, 0), Vector(20, 0, 0) }, Handle), "Stuck")
    T.True(State.Time < 1.6)
    T.Equal(Handle.StuckTarget.X, 20)
    T.Equal(vector.magnitude(State.Direction), 0)
end)

T.Case("jitter is not mistaken for progress toward the waypoint", function()
    local Mover, Root, Handle, State = Fixture(function(Current)
        return Vector(Current.Frames % 2 == 0 and 0 or 0.6, 3, 0)
    end)
    T.Equal(Mover({ Vector(0, 0, 0), Vector(20, 0, 0) }, Handle), "Stuck")
    T.True(State.Time < 1.7)
end)

T.Case("another floor is not reported as arrival", function()
    local Mover, Root, Handle = Fixture()
    T.Equal(Mover({ Vector(0, 0, 0), Vector(0, 20, 0) }, Handle), "Stuck")
end)

T.Finish("HumanoidMover")
