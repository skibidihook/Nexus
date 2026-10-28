local KeyboardSteering = {}

function KeyboardSteering.Keys(Direction, Forward, Right)
    local Length = math.sqrt(Forward.X * Forward.X + Forward.Z * Forward.Z)
    local SideLength = math.sqrt(Right.X * Right.X + Right.Z * Right.Z)
    if Length < 0.001 or SideLength < 0.001 then return {} end
    local Front = (Direction.X * Forward.X + Direction.Z * Forward.Z) / Length
    local Side = (Direction.X * Right.X + Direction.Z * Right.Z) / SideLength
    local Keys = {}
    if Front > 0.3 then Keys.W = true elseif Front < -0.3 then Keys.S = true end
    if Side > 0.3 then Keys.D = true elseif Side < -0.3 then Keys.A = true end
    return Keys
end

return KeyboardSteering
