local Surface = {
	Default = 1,
	Road = 2,
	Pavement = 3,
	Natural = 4,
	Water = 5,
	Wood = 6,
	Curb = 7,
	Ice = 8,
}

Surface.Count = 8
Surface.Names = { "Default", "Road", "Pavement", "Natural", "Water", "Wood", "Curb", "Ice" }

Surface.Materials = {
	Asphalt = Surface.Road,
	Concrete = Surface.Pavement,
	Pavement = Surface.Pavement,
	Brick = Surface.Pavement,
	Cobblestone = Surface.Pavement,
	Slate = Surface.Pavement,
	Granite = Surface.Pavement,
	Marble = Surface.Pavement,
	Limestone = Surface.Pavement,
	Basalt = Surface.Pavement,
	Sandstone = Surface.Pavement,
	DiamondPlate = Surface.Pavement,
	Metal = Surface.Pavement,
	CorrodedMetal = Surface.Pavement,
	Foil = Surface.Pavement,
	CeramicTiles = Surface.Pavement,
	Grass = Surface.Natural,
	LeafyGrass = Surface.Natural,
	Ground = Surface.Natural,
	Mud = Surface.Natural,
	Sand = Surface.Natural,
	Snow = Surface.Natural,
	Rock = Surface.Natural,
	Pebble = Surface.Natural,
	Salt = Surface.Natural,
	CrackedLava = Surface.Natural,
	Ice = Surface.Ice,
	Glacier = Surface.Ice,
	Wood = Surface.Wood,
	WoodPlanks = Surface.Wood,
	Water = Surface.Water,
}

Surface.Hints = {
	{ "curb", Surface.Curb },
	{ "kerb", Surface.Curb },
	{ "sidewalk", Surface.Pavement },
	{ "pavement", Surface.Pavement },
	{ "walkway", Surface.Pavement },
	{ "footpath", Surface.Pavement },
	{ "crosswalk", Surface.Road },
	{ "road", Surface.Road },
	{ "street", Surface.Road },
	{ "asphalt", Surface.Road },
	{ "highway", Surface.Road },
	{ "parking", Surface.Road },
	{ "water", Surface.Water },
	{ "grass", Surface.Natural },
	{ "dirt", Surface.Natural },
	{ "sand", Surface.Natural },
	{ "mud", Surface.Natural },
}

function Surface.FromMaterial(Name)
	return Surface.Materials[Name] or Surface.Default
end

function Surface.FromName(Name)
	local Lower = string.lower(Name)
	local Hints = Surface.Hints
	for Index = 1, #Hints do
		local Hint = Hints[Index]
		if string.find(Lower, Hint[1], 1, true) then return Hint[2] end
	end
	return nil
end

function Surface.CostArray(Defaults, Overrides)
	local Costs = table.create(Surface.Count, 1)
	for Name, Code in next, Surface do
		if type(Code) == "number" and Code >= 1 and Code <= Surface.Count and Name ~= "Count" then
			local Value = Overrides and Overrides[Name]
			if Value == nil then Value = Defaults[Name] end
			Costs[Code] = Value or 1
		end
	end
	return Costs
end

return Surface
