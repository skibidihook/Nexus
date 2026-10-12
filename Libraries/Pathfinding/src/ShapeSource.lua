local Geometry = Require("Geometry")
local Raster = Require("Raster")

local ShapeSource = {}
ShapeSource.__index = ShapeSource

function ShapeSource.new(Shapes)
	local self = setmetatable({ Shapes = {} }, ShapeSource)
	for Index = 1, Shapes and #Shapes or 0 do self:Add(Shapes[Index]) end
	return self
end

function ShapeSource:Add(Shape)
	self.Shapes[#self.Shapes + 1] = Shape
	return Shape
end

function ShapeSource:Box(X, Y, Z, Sx, Sy, Sz, Code, Yaw, Kind)
	local R00, R01, R02, R10, R11, R12, R20, R21, R22 = Geometry.Rotation(Yaw or 0)
	return self:Add(Geometry.Shape(Kind or Geometry.Block, X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22, Sx, Sy, Sz, Code or 1))
end

function ShapeSource:Sample(Info, Emit)
	local Shapes = self.Shapes
	for Index = 1, #Shapes do Raster.Shape(Shapes[Index], Info, Emit) end
end

return ShapeSource
