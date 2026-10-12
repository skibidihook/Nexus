local Geometry = Require("Geometry")
local Raster = Require("Raster")
local Surface = Require("Surface")

local RobloxSource = {}
RobloxSource.__index = RobloxSource

local Workspace = game:GetService("Workspace")
local Raycast = Workspace.Raycast
local BoundsInBox = Workspace.GetPartBoundsInBox
local Vector3New, CFrameNew = Vector3.new, CFrame.new
local Water = Enum.Material.Water
local BoxFidelity = Enum.CollisionFidelity.Box
local HullFidelity = Enum.CollisionFidelity.Hull

local KindByShape = {
	[Enum.PartType.Block] = Geometry.Block,
	[Enum.PartType.Wedge] = Geometry.Wedge,
	[Enum.PartType.CornerWedge] = Geometry.CornerWedge,
	[Enum.PartType.Cylinder] = Geometry.Cylinder,
	[Enum.PartType.Ball] = Geometry.Ball,
}

function RobloxSource.new(Options)
	Options = Options or {}
	local Overlap = OverlapParams.new()
	Overlap.FilterType = Enum.RaycastFilterType.Exclude
	Overlap.FilterDescendantsInstances = Options.Ignore or {}
	Overlap.RespectCanCollide = true
	if Options.CollisionGroup then Overlap.CollisionGroup = Options.CollisionGroup end
	local Single = RaycastParams.new()
	Single.FilterType = Enum.RaycastFilterType.Include
	local Wet = RaycastParams.new()
	Wet.FilterType = Enum.RaycastFilterType.Include
	Wet.FilterDescendantsInstances = { Workspace.Terrain }
	Wet.IgnoreWater = false
	local Dry = RaycastParams.new()
	Dry.FilterType = Enum.RaycastFilterType.Include
	Dry.FilterDescendantsInstances = { Workspace.Terrain }
	Dry.IgnoreWater = true
	local self = setmetatable({
		Overlap = Overlap,
		Single = Single,
		Wet = Wet,
		Dry = Dry,
		Classify = Options.Classify,
		Terrain = Options.Terrain ~= false,
		Cache = {},
		Cached = 0,
		CacheLimit = Options.CacheLimit or 60000,
		Convex = false,
	}, RobloxSource)
	self.MeshSampler = function(S, Px, Pz, Index, Emit, Thin)
		self:SampleMesh(S, Px, Pz, Index, Emit, Thin)
	end
	return self
end

function RobloxSource:SetIgnore(List)
	self.Overlap.FilterDescendantsInstances = List
end

function RobloxSource:Entry(Part)
	local Entry = self.Cache[Part]
	if Entry then return Entry end
	local Kind, Convex = Geometry.Block, true
	if Part:IsA("Part") then
		Kind = KindByShape[Part.Shape] or Geometry.Block
	else
		local Class = Part.ClassName
		if Class == "WedgePart" then
			Kind = Geometry.Wedge
		elseif Class == "CornerWedgePart" then
			Kind = Geometry.CornerWedge
		elseif Class == "MeshPart" or Part:IsA("PartOperation") then
			local Ok, Fidelity = pcall(function() return Part.CollisionFidelity end)
			if not (Ok and Fidelity == BoxFidelity) then
				Kind = Geometry.Mesh
				Convex = Ok and Fidelity == HullFidelity
			end
		end
	end
	local Code = self.Classify and self.Classify(Part)
	if Code == false then
		Entry = { Skip = true }
	else
		if Code == nil then
			local Parent = Part.Parent
			Code = Surface.FromName(Part.Name) or (Parent and Parent ~= Workspace and Surface.FromName(Parent.Name)) or Surface.FromMaterial(Part.Material.Name)
		end
		Entry = { Kind = Kind, Convex = Convex, Surface = Code }
	end
	if self.Cached >= self.CacheLimit then
		table.clear(self.Cache)
		self.Cached = 0
	end
	self.Cache[Part] = Entry
	self.Cached += 1
	return Entry
end

function RobloxSource:SampleMesh(S, Px, Pz, Index, Emit, Thin)
	local Params = self.Single
	local Top, Bottom = S.MaxY + 0.25, S.MinY - 0.25
	local Hit = Raycast(Workspace, Vector3New(Px, Top, Pz), Vector3New(0, Bottom - Top, 0), Params)
	if not Hit then
		if Thin then Emit(Index, S.MinY, S.MaxY, S.Surface) end
		return
	end
	local High = Hit.Position.Y
	local Up = Raycast(Workspace, Vector3New(Px, Bottom, Pz), Vector3New(0, Top - Bottom, 0), Params)
	local Low = Up and Up.Position.Y or S.MinY
	if self.Convex or Low >= High then
		Emit(Index, Low < High and Low or S.MinY, High, S.Surface)
		return
	end
	local Tops, Bottoms = { High }, { Low }
	local Y = High - 0.02
	for _ = 1, 3 do
		if Y <= Bottom then break end
		local Next = Raycast(Workspace, Vector3New(Px, Y, Pz), Vector3New(0, Bottom - Y, 0), Params)
		if not Next then break end
		local Value = Next.Position.Y
		Tops[#Tops + 1] = Value
		Y = Value - 0.02
	end
	Y = Low + 0.02
	for _ = 1, 3 do
		if Y >= Top then break end
		local Next = Raycast(Workspace, Vector3New(Px, Y, Pz), Vector3New(0, Top - Y, 0), Params)
		if not Next then break end
		local Value = Next.Position.Y
		Bottoms[#Bottoms + 1] = Value
		Y = Value + 0.02
	end
	local Count = #Tops
	if Count == 1 or Count ~= #Bottoms then
		Emit(Index, Low, High, S.Surface)
		return
	end
	table.sort(Tops)
	table.sort(Bottoms)
	for I = 1, Count do
		if Bottoms[I] < Tops[I] then Emit(Index, Bottoms[I], Tops[I], S.Surface) end
	end
end

function RobloxSource:Sample(Info, Emit, Yield)
	local Cell, Size = Info.Cell, Info.Size
	local Width = Cell * Size
	local Center = CFrameNew(Info.X0 + Width * 0.5, (Info.MinY + Info.MaxY) * 0.5, Info.Z0 + Width * 0.5)
	local Parts = BoundsInBox(Workspace, Center, Vector3New(Width, Info.MaxY - Info.MinY, Width), self.Overlap)
	local Single = self.Single
	for Index = 1, #Parts do
		local Part = Parts[Index]
		local Entry = self:Entry(Part)
		if not Entry.Skip and (Part.Anchored or Part:IsGrounded()) then
			local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Part.CFrame:GetComponents()
			local PartSize = Part.Size
			local Shape = Geometry.Shape(Entry.Kind, X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22, PartSize.X, PartSize.Y, PartSize.Z, Entry.Surface)
			if Entry.Kind == Geometry.Mesh then
				Single.FilterDescendantsInstances = { Part }
				self.Convex = Entry.Convex
				Raster.Shape(Shape, Info, Emit, self.MeshSampler)
			else
				Raster.Shape(Shape, Info, Emit)
			end
		end
		if Yield and Index % 24 == 0 then Yield() end
	end
	if self.Terrain then self:SampleTerrain(Info, Emit, Yield) end
end

function RobloxSource:SampleTerrain(Info, Emit, Yield)
	local Cell, Size = Info.Cell, Info.Size
	local X0, Z0 = Info.X0, Info.Z0
	local Top, Bottom = Info.MaxY, Info.MinY
	local Down = Vector3New(0, Bottom - Top, 0)
	local Wet, Dry = self.Wet, self.Dry
	local Step = Size * Cell / 5
	local Any = false
	for I = 0, 4 do
		for J = 0, 4 do
			if Raycast(Workspace, Vector3New(X0 + (I + 0.5) * Step, Top, Z0 + (J + 0.5) * Step), Down, Wet) then
				Any = true
				break
			end
		end
		if Any then break end
	end
	if not Any then return end
	for Row = 0, Size - 1 do
		local Pz = Z0 + (Row + 0.5) * Cell
		local Base = Row * Size + 1
		for Column = 0, Size - 1 do
			local Px = X0 + (Column + 0.5) * Cell
			local Hit = Raycast(Workspace, Vector3New(Px, Top, Pz), Down, Wet)
			if Hit then
				local Y = Hit.Position.Y
				local Material = Hit.Material
				if Material == Water then
					local Bed = Raycast(Workspace, Vector3New(Px, Y - 0.05, Pz), Vector3New(0, Bottom - Y, 0), Dry)
					Emit(Base + Column, (Bed and Bed.Position.Y or Y - 60) - 8, Y, Surface.Water)
				else
					Emit(Base + Column, Y - 8, Y, Surface.FromMaterial(Material.Name))
				end
			end
		end
		if Yield then Yield() end
	end
end

return RobloxSource
