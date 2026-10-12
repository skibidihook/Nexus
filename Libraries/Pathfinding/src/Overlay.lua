local Overlay = {}

local Container
local Drawn = {}

local function Folder()
	if Container and Container.Parent then return Container end
	local Parent = (gethui and gethui()) or game:GetService("CoreGui")
	Container = Instance.new("Folder")
	Container.Name = "PathfindingOverlay"
	Container.Parent = Parent
	return Container
end

local function Segment(A, B, Color, Width)
	local Delta = B - A
	local Length = Delta.Magnitude
	if Length < 0.01 then return end
	local Box = Instance.new("BoxHandleAdornment")
	Box.Adornee = workspace.Terrain
	Box.AlwaysOnTop = true
	Box.ZIndex = 5
	Box.Color3 = Color
	Box.Transparency = 0.15
	Box.Size = Vector3.new(Width, Width, Length)
	Box.CFrame = CFrame.lookAt(A + Delta * 0.5, B)
	Box.Parent = Folder()
	Drawn[#Drawn + 1] = Box
	return Box
end

function Overlay.Path(Points, Color, Lift)
	local Offset = Vector3.new(0, Lift or 0.5, 0)
	local Made = {}
	for Index = 1, #Points - 1 do
		Made[#Made + 1] = Segment(Points[Index] + Offset, Points[Index + 1] + Offset, Color or Color3.fromRGB(0, 255, 140), 0.35)
	end
	for Index = 1, #Points do
		local Dot = Instance.new("SphereHandleAdornment")
		Dot.Adornee = workspace.Terrain
		Dot.AlwaysOnTop = true
		Dot.ZIndex = 6
		Dot.Radius = 0.45
		Dot.Color3 = Index == #Points and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
		Dot.CFrame = CFrame.new(Points[Index] + Offset)
		Dot.Parent = Folder()
		Drawn[#Drawn + 1] = Dot
		Made[#Made + 1] = Dot
	end
	return Made
end

function Overlay.Cells(Map, Profile, Center, Radius, Need)
	local Cell, Size = Map.Cell, Map.Size
	local Count = 0
	for X = math.floor((Center.X - Radius) / Cell), math.floor((Center.X + Radius) / Cell) do
		for Z = math.floor((Center.Z - Radius) / Cell), math.floor((Center.Z + Radius) / Cell) do
			local Tx, Tz = X // Size, Z // Size
			local Key = (Tx + 32768) * 65536 + (Tz + 32768)
			local Tile, Data = Map:Ready(Key, Profile)
			local Column = (Z - Tz * Size) * Size + (X - Tx * Size) + 1
			local First = Tile.First[Column]
			for Span = First, First + Tile.Count[Column] - 1 do
				local FloorY = Tile.Floor[Span]
				if math.abs(FloorY - Center.Y) < 12 then
					local Clear = Data.Clear[Span]
					local Box = Instance.new("BoxHandleAdornment")
					Box.Adornee = workspace.Terrain
					Box.AlwaysOnTop = false
					Box.Size = Vector3.new(Cell * 0.9, 0.1, Cell * 0.9)
					Box.CFrame = CFrame.new((X + 0.5) * Cell, FloorY + 0.08, (Z + 0.5) * Cell)
					Box.Transparency = 0.45
					if Clear < 0 then
						Box.Color3 = Color3.fromRGB(90, 90, 90)
					elseif Clear < (Need or 1.5) then
						Box.Color3 = Color3.fromRGB(255, 60, 60)
					else
						Box.Color3 = Color3.fromRGB(60, 120 + math.min(Clear, 8) * 16, 255)
					end
					Box.Parent = Folder()
					Drawn[#Drawn + 1] = Box
					Count += 1
				end
			end
		end
	end
	return Count
end

function Overlay.Clear()
	for Index = 1, #Drawn do
		local Item = Drawn[Index]
		if Item.Parent then Item:Destroy() end
	end
	table.clear(Drawn)
end

function Overlay.Destroy()
	Overlay.Clear()
	if Container then
		Container:Destroy()
		Container = nil
	end
end

return Overlay
