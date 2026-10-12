local Lanes = {}

local Sqrt, Abs, Min, Max, Floor, Ceil = math.sqrt, math.abs, math.min, math.max, math.floor, math.ceil
local Offset, Shift = 32768, 65536

local function Key(Cx, Cz)
	return (Cx + Offset) * Shift + (Cz + Offset)
end

function Lanes.Index(Lines, Options)
	Options = Options or {}
	local Cell = Options.Cell or 32
	local Buckets = {}
	local Kept = {}
	for Index = 1, #Lines do
		local Line = Lines[Index]
		local Dx, Dz = Line.Bx - Line.Ax, Line.Bz - Line.Az
		local Length = Sqrt(Dx * Dx + Dz * Dz)
		if Length > 0.5 then
			Line.Ux, Line.Uz, Line.Length, Line.Stamp = Dx / Length, Dz / Length, Length, 0
			Kept[#Kept + 1] = Line
			local Pieces = Max(1, Ceil(Length / (Cell * 0.5)))
			local Last
			for Piece = 0, Pieces do
				local T = Piece / Pieces
				local Slot = Key(Floor((Line.Ax + Dx * T) / Cell), Floor((Line.Az + Dz * T) / Cell))
				if Slot ~= Last then
					local Bucket = Buckets[Slot]
					if not Bucket then
						Bucket = {}
						Buckets[Slot] = Bucket
					end
					if Bucket[#Bucket] ~= Line then Bucket[#Bucket + 1] = Line end
					Last = Slot
				end
			end
		end
	end
	return { Cell = Cell, Buckets = Buckets, Lines = Kept, Stamp = 0 }
end

function Lanes.Near(Index, X, Y, Z, Ux, Uz, Options, Into)
	local Reach = Options.Reach or 30
	local Parallel = Options.Parallel or 0.966
	local Slack = Options.Slack or 6
	local Rise = Options.Rise or 8
	local Cell = Index.Cell
	local Buckets = Index.Buckets
	Index.Stamp += 1
	local Stamp = Index.Stamp
	local Nx, Nz = -Uz, Ux
	local Pad = Reach + Cell * 0.5
	local Count = 0
	for Cx = Floor((X - Pad) / Cell), Floor((X + Pad) / Cell) do
		for Cz = Floor((Z - Pad) / Cell), Floor((Z + Pad) / Cell) do
			local Bucket = Buckets[Key(Cx, Cz)]
			if Bucket then
				for Slot = 1, #Bucket do
					local Line = Bucket[Slot]
					if Line.Stamp ~= Stamp then
						Line.Stamp = Stamp
						local Dot = Ux * Line.Ux + Uz * Line.Uz
						if Dot >= Parallel or Dot <= -Parallel then
							local T = (X - Line.Ax) * Line.Ux + (Z - Line.Az) * Line.Uz
							local Level = Line.Ay and Line.Ay + (Line.By - Line.Ay) * Min(1, Max(0, T / Line.Length)) or Line.Y
							if T >= -Slack and T <= Line.Length + Slack and (not Y or not Level or Abs(Level - Y) <= Rise) then
								local Lateral = (Line.Ax + Line.Ux * T - X) * Nx + (Line.Az + Line.Uz * T - Z) * Nz
								if Lateral >= -Reach and Lateral <= Reach then
									Count += 1
									local Item = Into[Count]
									if Item then
										Item.Offset, Item.Divider = Lateral, Line.Divider == true
									else
										Into[Count] = { Offset = Lateral, Divider = Line.Divider == true }
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return Count
end

function Lanes.Scanner(Probe, IsRoad, Options)
	Options = Options or {}
	local Reach = Options.ScanReach or 30
	local Tolerance = Options.ScanTolerance or 1.7
	local Settle = Options.Settle or 6
	return function(X, Y, Z, Ux, Uz, From)
		local Nx, Nz = -Uz, Ux
		local _, Settled = Probe(X, Z, Y, Settle)
		local Level = Settled or Y
		local function Road(Lateral)
			local Clear, FloorY, Code = Probe(X + Nx * Lateral, Z + Nz * Lateral, Level, Tolerance)
			if Clear and IsRoad(Code) then
				Level = FloorY
				return true
			end
			return false
		end
		if From then
			local Lateral = Ceil(From)
			while Lateral <= Reach and not Road(Lateral) do Lateral += 1 end
			if Lateral > Reach then return nil end
			while Lateral <= Reach and Road(Lateral) do Lateral += 1 end
			return Lateral <= Reach and Lateral - 0.5 or nil
		end
		local Base = Level
		if Road(0) then
			local Right = 1
			while Right <= Reach and Road(Right) do Right += 1 end
			Level = Base
			local Left = 1
			while Left <= Reach and Road(-Left) do Left += 1 end
			return true, Left <= Reach and 0.5 - Left or nil, Right <= Reach and Right - 0.5 or nil
		end
		local Start = 1
		while Start <= Reach and not Road(Start) do Start += 1 end
		if Start > Reach then return false end
		local Finish = Start + 1
		while Finish <= Reach and Road(Finish) do Finish += 1 end
		return false, Start - 0.5, Finish <= Reach and Finish - 0.5 or nil
	end
end

function Lanes.Pick(Found, Count, Scan, Options)
	local MinLane = Options.MinLane or 6
	local MaxHalf = Options.MaxHalf or 13
	local DividerReach = Options.DividerReach or 20
	local MaxRoad = Options.MaxRoad or 48
	local Inner, Outer
	local Painted = true
	for Index = 1, Count do
		local Item = Found[Index]
		local Value = Item.Offset
		if Item.Divider and Value >= -DividerReach and Value <= DividerReach and (not Inner or Value > Inner) then Inner = Value end
	end
	if Inner then
		for Index = 1, Count do
			local Value = Found[Index].Offset
			if Value >= Inner + MinLane and (not Outer or Value < Outer) then Outer = Value end
		end
		if not Outer and Scan then
			local Edge = Scan(Inner + 0.5)
			if Edge and Edge >= Inner + MinLane then Outer = Edge end
			Painted = false
		end
	elseif Scan then
		Painted = false
		local CenterRoad, A, B = Scan()
		if CenterRoad then
			if A and B and B - A <= MaxRoad then Inner, Outer = (A + B) * 0.5, B end
		elseif A and B and B - A <= MaxRoad * 0.5 then
			Inner, Outer = A, B
		end
		if Inner then
			for Index = 1, Count do
				local Value = Found[Index].Offset
				if Value >= Inner + MinLane and Value < Outer then Outer = Value end
			end
		end
	end
	if not (Inner and Outer) or Outer - Inner < MinLane then return nil end
	return Inner + Min((Outer - Inner) * 0.5, MaxHalf), Painted
end

function Lanes.Finder(Options)
	Options = Options or {}
	local Index = Options.Index
	local Scanner = Options.Scanner
	local Side = Options.Side or 1
	local MaxShift = Options.MaxShift or 24
	local Found = {}
	return function(X, Y, Z, Ux, Uz)
		if Side < 0 then Ux, Uz = -Ux, -Uz end
		local Count = Index and Lanes.Near(Index, X, Y, Z, Ux, Uz, Options, Found) or 0
		local Scan
		if Scanner then
			Scan = function(From)
				return Scanner(X, Y, Z, Ux, Uz, From)
			end
		end
		local Value, Painted = Lanes.Pick(Found, Count, Scan, Options)
		if not Value or Abs(Value) > MaxShift then return nil end
		return Value * Side, Painted
	end
end

function Lanes.Profile(Points, Finder, Options, Yield)
	Options = Options or {}
	local Step = Options.Step or 4
	local Count = #Points
	local Cumulative = table.create(Count, 0)
	for Index = 2, Count do
		local A, B = Points[Index - 1], Points[Index]
		Cumulative[Index] = Cumulative[Index - 1] + Sqrt((B.X - A.X) ^ 2 + (B.Z - A.Z) ^ 2)
	end
	local Total = Cumulative[Count] or 0
	local Samples = Floor(Total / Step) + 1
	local Raw = table.create(Samples, false)
	local Painted = table.create(Samples, false)
	local Owner = table.create(Samples, 0)
	local Segment = 1
	for Sample = 1, Samples do
		local S = (Sample - 1) * Step
		while Segment < Count - 1 and Cumulative[Segment + 1] < S do Segment += 1 end
		Owner[Sample] = Segment
		local A, B = Points[Segment], Points[Segment + 1]
		if A and B then
			local Length = Cumulative[Segment + 1] - Cumulative[Segment]
			if Length > 1e-6 then
				local T = Min(1, Max(0, (S - Cumulative[Segment]) / Length))
				local Ux, Uz = (B.X - A.X) / Length, (B.Z - A.Z) / Length
				local Value, FromPaint = Finder(A.X + (B.X - A.X) * T, A.Y + (B.Y - A.Y) * T, A.Z + (B.Z - A.Z) * T, Ux, Uz)
				if Value then
					Raw[Sample] = Value
					Painted[Sample] = FromPaint ~= false
				end
			end
		end
		if Yield and Sample % 8 == 0 and Yield() == false then break end
	end

	local Bridge = Floor((Options.Bridge or 160) / Step)
	local Narrower = Options.Narrower or 1.5
	local LastPaint
	for Sample = 1, Samples do
		if Raw[Sample] and Painted[Sample] then
			if LastPaint and Sample - LastPaint > 1 and Sample - LastPaint - 1 <= Bridge then
				local From, To = Raw[LastPaint], Raw[Sample]
				for Gap = LastPaint + 1, Sample - 1 do
					local Expected = From + (To - From) * (Gap - LastPaint) / (Sample - LastPaint)
					local Value = Raw[Gap]
					if not (Value and Abs(Value) < Abs(Expected) - Narrower) then Raw[Gap] = false end
				end
			end
			LastPaint = Sample
		end
	end

	local MinReadings = Options.MinReadings or 3
	local Group = {}
	local First = 1
	while First <= Samples do
		if Raw[First] and Painted[First] then
			First += 1
		else
			local Last = First
			while Last < Samples and Owner[Last + 1] == Owner[First] and not (Raw[Last + 1] and Painted[Last + 1]) do Last += 1 end
			table.clear(Group)
			for Sample = First, Last do
				if Raw[Sample] then Group[#Group + 1] = Raw[Sample] end
			end
			local Value = false
			if #Group >= MinReadings then
				table.sort(Group)
				Value = Group[(#Group + 1) // 2]
			end
			for Sample = First, Last do Raw[Sample] = Value end
			First = Last + 1
		end
	end

	local Known = 0
	for Sample = 1, Samples do
		if Raw[Sample] then Known += 1 end
	end

	local Values = table.create(Samples, 0)
	local Fallback = Options.Fallback or 0
	if Known == 0 then
		for Sample = 1, Samples do Values[Sample] = Fallback end
	else
		local Median = Options.Median or 2
		local Window = {}
		for Sample = 1, Samples do
			if Raw[Sample] then
				table.clear(Window)
				for Near = Max(1, Sample - Median), Min(Samples, Sample + Median) do
					if Raw[Near] then Window[#Window + 1] = Raw[Near] end
				end
				table.sort(Window)
				Values[Sample] = Window[(#Window + 1) // 2]
			end
		end
		local Previous
		for Sample = 1, Samples do
			if Raw[Sample] then
				if Previous and Sample - Previous > 1 then
					local From, To = Values[Previous], Values[Sample]
					for Gap = Previous + 1, Sample - 1 do
						Values[Gap] = From + (To - From) * (Gap - Previous) / (Sample - Previous)
					end
				elseif not Previous then
					for Gap = 1, Sample - 1 do Values[Gap] = Values[Sample] end
				end
				Previous = Sample
			end
		end
		for Gap = Previous + 1, Samples do Values[Gap] = Values[Previous] end
	end

	local Radius = Options.Smooth or 5
	local Buffer = table.create(Samples, 0)
	for _ = 1, 2 do
		for Sample = 1, Samples do
			local Sum, Weight = 0, 0
			for Near = Max(1, Sample - Radius), Min(Samples, Sample + Radius) do
				Sum += Values[Near]
				Weight += 1
			end
			Buffer[Sample] = Sum / Weight
		end
		Values, Buffer = Buffer, Values
	end

	local Taper = Options.TaperFrom
	if Taper and Taper < Total then
		for Sample = 1, Samples do
			local S = (Sample - 1) * Step
			if S > Taper then Values[Sample] *= Max(0, 1 - (S - Taper) / (Total - Taper)) end
		end
	end

	local Target = Options.EndOffset
	local Range = Options.EndRange
	if not Target and Range then Target = Min(Range[2], Max(Range[1], Values[Samples])) end
	if Target and Samples > 1 then
		local Shift = Abs(Target - Values[Samples])
		local PullIn = Max(Options.PullIn or 40, Shift * (Options.PullInRatio or 4))
		local Begin = Max(1, Samples - Floor(PullIn / Step))
		local From = Values[Begin]
		local Span = Max(1, Samples - Begin)
		for Sample = Begin, Samples do
			local T = (Sample - Begin) / Span
			Values[Sample] = From + (Target - From) * T * T * (3 - 2 * T)
		end
	end
	return { Step = Step, Values = Values, Known = Known, Samples = Samples, Length = Total, End = Target }
end

function Lanes.Collect(Roots, Options, Yield)
	Options = Options or {}
	local Patterns = Options.Patterns or { "line" }
	local MinLength = Options.MinLength or 2
	local MaxWidth = Options.MaxWidth or 2
	local MaxThickness = Options.MaxThickness or 0.6
	local Lines = {}
	local Seen = 0
	for _, Root in next, Roots do
		for _, Item in next, Root:GetDescendants() do
			Seen += 1
			if Yield and Seen % 600 == 0 then Yield() end
			if Item:IsA("BasePart") then
				local Lower = string.lower(Item.Name)
				local Match = false
				for _, Pattern in next, Patterns do
					if string.find(Lower, string.lower(Pattern), 1, true) then
						Match = true
						break
					end
				end
				if Match then
					local Frame, Size = Item.CFrame, Item.Size
					local Axes = { { Frame.RightVector, Size.X }, { Frame.UpVector, Size.Y }, { Frame.LookVector, Size.Z } }
					local Up, UpDot = 1, -1
					for Slot = 1, 3 do
						local Dot = Abs(Axes[Slot][1].Y)
						if Dot > UpDot then Up, UpDot = Slot, Dot end
					end
					local Long, Wide
					for Slot = 1, 3 do
						if Slot ~= Up then
							if not Long or Axes[Slot][2] > Long[2] then
								Wide = Long
								Long = Axes[Slot]
							else
								Wide = Axes[Slot]
							end
						end
					end
					if Long[2] >= MinLength and Wide[2] <= MaxWidth and Axes[Up][2] <= MaxThickness then
						local Center = Frame.Position
						local Axis = Long[1]
						if Axis.X * Axis.X + Axis.Z * Axis.Z > 0.25 then
							local Half = Long[2] * 0.5
							local Ax, Ay, Az = Axis.X * Half, Axis.Y * Half, Axis.Z * Half
							local Color = Item.Color
							local Divider = string.find(Lower, "yellow", 1, true) ~= nil or (Color.R > 0.7 and Color.G > 0.5 and Color.B < 0.35)
							Lines[#Lines + 1] = { Ax = Center.X - Ax, Az = Center.Z - Az, Bx = Center.X + Ax, Bz = Center.Z + Az, Ay = Center.Y - Ay, By = Center.Y + Ay, Y = Center.Y, Divider = Divider }
						end
					end
				end
			end
		end
	end
	return Lanes.Index(Lines, Options)
end

return Lanes
