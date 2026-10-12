local FixtureSource = {}
FixtureSource.__index = FixtureSource

function FixtureSource.new(Data)
	return setmetatable({ Data = Data }, FixtureSource)
end

function FixtureSource:Sample(Info, Emit)
	local Tile = self.Data.Tiles[`{Info.Tx},{Info.Tz}`]
	if not Tile then return end
	for Column, List in next, Tile do
		for Index = 1, #List, 3 do
			Emit(Column, List[Index], List[Index + 1], List[Index + 2])
		end
	end
end

function FixtureSource.Capture(Source, Map, MinX, MinZ, MaxX, MaxZ, Yield)
	local Ax, Az = Map:TileOf(MinX, MinZ)
	local Bx, Bz = Map:TileOf(MaxX, MaxZ)
	local Size, Cell = Map.Size, Map.Cell
	local Tiles = {}
	for Tz = Az, Bz do
		for Tx = Ax, Bx do
			local Columns = {}
			local Info = { Tx = Tx, Tz = Tz, X0 = Tx * Size * Cell, Z0 = Tz * Size * Cell, Size = Size, Cell = Cell, MinY = Map.MinY, MaxY = Map.MaxY }
			Source:Sample(Info, function(Column, Bottom, Top, Code)
				local List = Columns[Column]
				if not List then
					List = {}
					Columns[Column] = List
				end
				List[#List + 1] = Bottom
				List[#List + 1] = Top
				List[#List + 1] = Code
			end, Yield)
			Tiles[`{Tx},{Tz}`] = Columns
		end
	end
	return { Cell = Cell, Size = Size, Tiles = Tiles }
end

local function Number(Value)
	if Value == math.huge then return "math.huge" end
	if Value == -math.huge then return "-math.huge" end
	return string.format("%.3f", Value):gsub("%.?0+$", "")
end

function FixtureSource.Serialize(Data)
	local Parts = { "return { Cell = ", tostring(Data.Cell), ", Size = ", tostring(Data.Size), ", Tiles = {\n" }
	for Key, Columns in next, Data.Tiles do
		Parts[#Parts + 1] = `["{Key}"] = \{`
		for Column, List in next, Columns do
			local Values = table.create(#List)
			for Index = 1, #List do Values[Index] = Number(List[Index]) end
			Parts[#Parts + 1] = `[{Column}] = \{{table.concat(Values, ",")}},`
		end
		Parts[#Parts + 1] = "},\n"
	end
	Parts[#Parts + 1] = "} }\n"
	return table.concat(Parts)
end

return FixtureSource
