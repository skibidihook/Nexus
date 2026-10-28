local Avoidance = {}

function Avoidance.SegmentDistance(First, Second, Threat)
    local X, Z = Second.X - First.X, Second.Z - First.Z
    local Length = X * X + Z * Z
    local Ratio = Length > 0 and math.clamp(((Threat.X - First.X) * X + (Threat.Z - First.Z) * Z) / Length, 0, 1) or 0
    local Dx, Dz = First.X + X * Ratio - Threat.X, First.Z + Z * Ratio - Threat.Z
    return math.sqrt(Dx * Dx + Dz * Dz)
end

function Avoidance.RouteClear(Points, Threat, Radius)
    for Index = 2, #Points do
        local First, Second = Points[Index - 1], Points[Index]
        local Distance = Avoidance.SegmentDistance(First, Second, Threat)
        if Distance < Radius then
            local X, Z = First.X - Threat.X, First.Z - Threat.Z
            local StartDistance = math.sqrt(X * X + Z * Z)
            local DirectionX, DirectionZ = Second.X - First.X, Second.Z - First.Z
            if StartDistance >= Radius or X * DirectionX + Z * DirectionZ <= 0 then return false, Index, Distance end
        end
    end
    return true
end

function Avoidance.EscapeGoals(Origin, Threat, HalfSize, Options)
    Options = Options or {}
    local MakeVector = (Vector3 and Vector3.new) or vector.create
    local Margin = Options.Margin or 16
    local Clearance = Options.Clearance or 35
    local function Distance(First, Second)
        return math.sqrt((First.X - Second.X) ^ 2 + (First.Z - Second.Z) ^ 2)
    end
    local StartingDistance = Distance(Origin, Threat)
    local Candidates = {}
    local function Add(Goal)
        Goal = MakeVector(math.clamp(Goal.X, -HalfSize.X + Margin, HalfSize.X - Margin), Origin.Y, math.clamp(Goal.Z, -HalfSize.Z + Margin, HalfSize.Z - Margin))
        local Travel = Distance(Origin, Goal)
        local Separation = Distance(Goal, Threat)
        if Travel <= 20 or Separation <= (Options.MinSeparation or 65) then return end
        if StartingDistance < 150 and not Avoidance.RouteClear({ Origin, Goal }, Threat, Clearance) then return end
        local CenterDistance = math.sqrt(Goal.X * Goal.X + Goal.Z * Goal.Z)
        local Score = Separation - Travel * 0.8 - math.max(0, CenterDistance - 160) * 0.7
        table.insert(Candidates, { Goal = Goal, Score = Score, Short = Travel < 130 })
    end
    for _, Radius in next, { 50, 85, 120 } do
        for Index = 0, 11 do
            local Angle = Index * math.pi / 6
            Add(Origin + MakeVector(math.cos(Angle) * Radius, 0, math.sin(Angle) * Radius))
        end
    end
    for _, Offset in next, { MakeVector(-140, 0, -140), MakeVector(140, 0, -140), MakeVector(-140, 0, 140), MakeVector(140, 0, 140), MakeVector(-140, 0, 0), MakeVector(140, 0, 0), MakeVector(0, 0, -140), MakeVector(0, 0, 140) } do Add(Offset) end
    table.sort(Candidates, function(First, Second)
        if StartingDistance < 150 and First.Short ~= Second.Short then return First.Short end
        return First.Score > Second.Score
    end)
	local Selected = {}
	local Spacing = Options.GoalSpacing or 16
	for _, Candidate in Candidates do
		local Distinct = true
		for _, Previous in Selected do
			if Distance(Candidate.Goal, Previous.Goal) < Spacing then Distinct = false; break end
		end
		if Distinct then table.insert(Selected, Candidate) end
	end
	return Selected
end

function Avoidance.EscapeRegion(Origin, Threat, HalfSize, Options)
    Options = Options or {}
    local MakeVector = (Vector3 and Vector3.new) or vector.create
    local Dx, Dz = Origin.X - Threat.X, Origin.Z - Threat.Z
    local Separation = math.sqrt(Dx * Dx + Dz * Dz)
    local Reach = Options.Reach or (Separation < 90 and 12 or 24)
    local Margin = Options.Margin or 4
    local Minimum = Separation < 90 and Separation + 6 or math.max(75, Separation - 32)
    local Edge = math.min(HalfSize.X - math.abs(Origin.X), HalfSize.Z - math.abs(Origin.Z))
    local X, Z
    if Edge < 48 then
        X, Z = -Origin.X, -Origin.Z
    else
        X, Z = Dx * 0.5 - Dz, Dz * 0.5 + Dx
    end
    local Length = math.sqrt(X * X + Z * Z)
    if Length < 0.01 then X, Z, Length = 1, 0, 1 end
    local Hint = MakeVector(Origin.X + X / Length * Reach, Origin.Y, Origin.Z + Z / Length * Reach)
    local function Accept(Point)
        if math.abs(Point.X) > HalfSize.X - Margin or math.abs(Point.Z) > HalfSize.Z - Margin then return false end
        local Travel = math.sqrt((Point.X - Origin.X) ^ 2 + (Point.Z - Origin.Z) ^ 2)
        local Distance = math.sqrt((Point.X - Threat.X) ^ 2 + (Point.Z - Threat.Z) ^ 2)
        return Travel >= Reach and Distance >= Minimum
    end
    return Hint, Accept
end

return Avoidance
