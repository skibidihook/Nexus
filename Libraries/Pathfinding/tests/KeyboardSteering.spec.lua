local Steering = require("../src/KeyboardSteering")
local T = require("./Framework")
local Vector = vector.create

T.Case("world forward uses W for a matching camera", function()
    local Keys = Steering.Keys(Vector(0, 0, -1), Vector(0, 0, -1), Vector(1, 0, 0))
    T.True(Keys.W)
    T.True(not Keys.S and not Keys.A and not Keys.D)
end)

T.Case("turning the camera changes keys without changing the goal", function()
    local Keys = Steering.Keys(Vector(0, 0, -1), Vector(1, 0, 0), Vector(0, 0, 1))
    T.True(Keys.A)
    T.True(not Keys.W and not Keys.S and not Keys.D)
end)

T.Case("diagonal travel holds two keys", function()
    local Keys = Steering.Keys(Vector(0.707, 0, -0.707), Vector(0, 0, -1), Vector(1, 0, 0))
    T.True(Keys.W and Keys.D)
end)

T.Case("a stopped mover releases every key", function()
    T.Equal(next(Steering.Keys(Vector(0, 0, 0), Vector(0, 0, -1), Vector(1, 0, 0))), nil)
end)

T.Case("camera pitch does not change horizontal steering", function()
    local Keys = Steering.Keys(Vector(0, 0, -1), Vector(0, 0.99, -0.1), Vector(1, 0, 0))
    T.True(Keys.W)
end)

T.Finish("KeyboardSteering")
