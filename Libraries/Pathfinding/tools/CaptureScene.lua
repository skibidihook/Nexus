--!nocheck
--!nolint UnknownGlobal, DeprecatedGlobal, BuiltinGlobalWrite
local Name, Center, Radius = ...
local Pathfinding = loadstring(readfile("Pathfinding.lua"), "=Pathfinding")()
local Players = game:GetService("Players")
local Character = Players.LocalPlayer.Character
local Root = Character and Character:FindFirstChild("HumanoidRootPart")
Center = Center or (Root and Root.Position)
Radius = Radius or 96
local Source = Pathfinding.Internal.RobloxSource.new({ Ignore = { Character } })
local Map = Pathfinding.Internal.World.new(Source, {})
local Data = Pathfinding.FixtureSource.Capture(Source, Map, Center.X - Radius, Center.Z - Radius, Center.X + Radius, Center.Z + Radius)
local File = `PathfindingScene_{Name or "Capture"}.lua`
writefile(File, Pathfinding.FixtureSource.Serialize(Data))
Pathfinding.Destroy()
return File, Center
