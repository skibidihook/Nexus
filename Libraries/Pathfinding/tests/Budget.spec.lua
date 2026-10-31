local Pathfinding = require("../Pathfinding")
local T = require("./Framework")

T.Case("raster yields inside a mesh without changing samples", function()
    local Geometry = Pathfinding.Geometry
    local Shape = Geometry.Shape(Geometry.Mesh, 8, 1, 8, 1, 0, 0, 0, 1, 0, 0, 0, 1, 16, 2, 16, 1)
    local Info = { Cell = 1, Size = 16, X0 = 0, Z0 = 0, MinY = -10, MaxY = 10 }
    local Expected, Actual, Checks = {}, {}, 0
    local Sampler = function(_, _, _, Index, Emit) Emit(Index, 0, 2, 1) end
    Pathfinding.Internal.Raster.Shape(Shape, Info, function(Index, Bottom, Top) Expected[Index] = { Bottom, Top } end, Sampler)
    Pathfinding.Internal.Raster.Shape(Shape, Info, function(Index, Bottom, Top) Actual[Index] = { Bottom, Top } end, Sampler, function() Checks += 1 end)
    T.True(Checks >= 64)
    for Index = 1, 256 do
        T.Equal(Actual[Index][1], Expected[Index][1])
        T.Equal(Actual[Index][2], Expected[Index][2])
    end
end)

T.Case("cold world search resumes across slices with identical route", function()
    local Source = Pathfinding.ShapeSource.new()
    Source:Box(0, -0.5, 0, 160, 1, 160)
    Source:Box(0, 3, 0, 2, 6, 40)
    local Agent = Pathfinding.Agent.Walker({ Radius = 1.5, Height = 5 })
    local From, Goal = { X = -20, Y = 0, Z = 0 }, { X = 20, Y = 0, Z = 0 }
    local Expected = Pathfinding.Internal.GridSearch.Find(Pathfinding.World.new({ Source = Source, TileSize = 16 }), Agent, From, Goal)
    local Checks, Slices, Actual = 0, 0, nil
    local Thread = coroutine.create(function()
        Actual = Pathfinding.Internal.GridSearch.Find(Pathfinding.World.new({ Source = Source, TileSize = 16 }), Agent, From, Goal, {}, function()
            Checks += 1
            if Checks % 32 == 0 then coroutine.yield() end
            return true
        end)
    end)
    while coroutine.status(Thread) ~= "dead" do
        Slices += 1
        local Ok, Error = coroutine.resume(Thread)
        T.True(Ok, Error)
        T.True(Slices < 10000)
    end
    T.True(Slices > 10)
    T.Equal(Actual.Status, Expected.Status)
    T.Equal(Actual.Complete, Expected.Complete)
    T.Equal(#Actual.Points, #Expected.Points)
    for Index = 1, #Actual.Points do T.Equal(Actual.Points[Index], Expected.Points[Index]) end
end)

T.Finish("Budget")
