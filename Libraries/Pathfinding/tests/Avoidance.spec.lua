local Avoidance = require("../src/Avoidance")
local T = require("./Framework")
local V = vector.create

T.Case("a distant endpoint does not make a crossing route safe", function()
    T.True(not Avoidance.RouteClear({ V(-100, 0, 0), V(150, 0, 0) }, V(0, 0, 0), 35))
end)

T.Case("an arc around the threat keeps its clearance", function()
    T.True(Avoidance.RouteClear({ V(-100, 0, 0), V(-100, 0, 100), V(100, 0, 100) }, V(0, 0, 0), 35))
end)

T.Case("moving directly away is allowed when already too close", function()
    T.True(Avoidance.RouteClear({ V(15, 0, 0), V(80, 0, 0) }, V(0, 0, 0), 35))
end)

T.Case("a close start cannot move toward the boss before escaping", function()
    T.True(not Avoidance.RouteClear({ V(15, 0, 0), V(5, 0, 0), V(80, 0, 0) }, V(0, 0, 0), 35))
end)

T.Case("a boss moving into a previously safe segment invalidates it", function()
    local Points = { V(0, 0, 50), V(100, 0, 50) }
    T.True(Avoidance.RouteClear(Points, V(50, 0, 0), 35))
    T.True(not Avoidance.RouteClear(Points, V(50, 0, 45), 35))
end)

T.Case("a player at the west arena edge has a short escape", function()
    local Origin, Threat = V(-184, 8, -126), V(-131, 8, -126)
    local Candidates = Avoidance.EscapeGoals(Origin, Threat, V(201.7, 15, 221))
    T.True(#Candidates > 0)
    T.True(Candidates[1].Short)
    T.True(Avoidance.RouteClear({ Origin, Candidates[1].Goal }, Threat, 35))
    for _, Candidate in Candidates do
        T.True(math.abs(Candidate.Goal.X) <= 185.7 and math.abs(Candidate.Goal.Z) <= 205)
    end
end)

T.Case("a close boss does not remove every edge escape", function()
    local Origin, Threat = V(-184, 8, -126), V(-170, 8, -126)
    local Candidates = Avoidance.EscapeGoals(Origin, Threat, V(201.7, 15, 221))
    T.True(#Candidates > 0)
    for _, Candidate in Candidates do T.True(Avoidance.RouteClear({ Origin, Candidate.Goal }, Threat, 35)) end
end)

T.Case("edge clamping does not fill retreat slots with overlapping goals", function()
    local Origin, Threat = V(0, 8, 207), V(-6, 8, 162)
    local Candidates = Avoidance.EscapeGoals(Origin, Threat, V(201.7, 15, 222.7))
    T.True(#Candidates >= 2)
    for Index, Candidate in Candidates do
        for Other = 1, Index - 1 do
            local Delta = Candidate.Goal - Candidates[Other].Goal
            T.True(math.sqrt(Delta.X * Delta.X + Delta.Z * Delta.Z) >= 16,
                "retreat goals overlap the same eight-stud arrival region")
        end
    end
end)

T.Case("an early escape can leave an edge pocket toward the arena interior", function()
    local Origin, Threat = V(0, 8, 207), V(0, 8, 0)
    local Hint, Accept = Avoidance.EscapeRegion(Origin, Threat, V(202, 15, 223))
    T.True(Hint.Z < Origin.Z)
    T.True(Accept(V(0, 5, 182)))
    T.True(not Accept(V(0, 5, 230)))
    T.True(not Accept(V(0, 5, 206)))
end)

T.Case("a close-threat escape must increase separation", function()
    local Origin, Threat = V(0, 8, 0), V(0, 8, -50)
    local _, Accept = Avoidance.EscapeRegion(Origin, Threat, V(202, 15, 223))
    T.True(not Accept(V(0, 5, -15)))
    T.True(Accept(V(0, 5, 15)))
end)

T.Finish("Avoidance")
