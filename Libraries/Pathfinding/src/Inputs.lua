local Inputs = {}

local Sqrt, Abs = math.sqrt, math.abs
local Zero = Vector3.zero

local function Edge(Steer, Throttle, SignS, SignT)
	local Sx, Cz
	if Throttle >= 0.98 then
		Sx = Steer > 0.02 and 0.05 + 0.6 * Steer or 0
		Cz = Sqrt(1 - Sx * Sx)
	else
		Cz = Throttle > 0.02 and 0.05 + 0.6 * Throttle or 0
		Sx = Sqrt(1 - Cz * Cz)
	end
	return Vector3.new(SignS * Sx, 0, -SignT * Cz)
end

function Inputs.MoveVector(Controls, Options)
	Options = Options or {}
	local Adapter = { Steer = 0, Throttle = 0, Accumulator = 0, Active = false }
	local Saved

	function Adapter.Vector()
		local Steer, Throttle = Adapter.Steer, Adapter.Throttle
		local A, B = Abs(Steer), Abs(Throttle)
		if A < 0.02 and B < 0.02 then return Zero end
		local SignS = Steer >= 0 and 1 or -1
		local SignT = Throttle >= 0 and 1 or -1
		if B >= 0.98 or A >= 0.98 then
			return Edge(A, B, SignS, SignT)
		end
		local Weight, EdgeS, EdgeT
		if A <= B then
			Weight, EdgeS, EdgeT = B, A / B, 1
		else
			Weight, EdgeS, EdgeT = A, 1, B / A
		end
		Adapter.Accumulator += Weight
		if Adapter.Accumulator >= 1 then
			Adapter.Accumulator -= 1
			return Edge(EdgeS, EdgeT, SignS, SignT)
		end
		return Zero
	end

	local Override = function()
		return Adapter.Vector()
	end

	function Adapter.Begin()
		if Adapter.Active then return true end
		local Target = type(Controls) == "function" and Controls() or Controls
		if not Target then return false end
		Adapter.Target = Target
		Saved = rawget(Target, "GetMoveVector")
		rawset(Target, "GetMoveVector", Override)
		Adapter.Active = true
		return true
	end

	function Adapter.Set(Steer, Throttle)
		Adapter.Steer = Steer
		Adapter.Throttle = Throttle
	end

	function Adapter.Finish()
		Adapter.Steer, Adapter.Throttle = 0, 0
		if Adapter.Active and Adapter.Target then
			if rawget(Adapter.Target, "GetMoveVector") == Override then rawset(Adapter.Target, "GetMoveVector", Saved) end
		end
		Adapter.Active = false
	end

	return Adapter
end

function Inputs.PlayerControls()
	local Players = game:GetService("Players")
	local PlayerScripts = Players.LocalPlayer:FindFirstChild("PlayerScripts")
	local Module = PlayerScripts and PlayerScripts:FindFirstChild("PlayerModule")
	if not Module then return nil end
	local Ok, Loaded = pcall(require, Module)
	if not (Ok and type(Loaded) == "table") then return nil end
	local Fine, Controls = pcall(Loaded.GetControls, Loaded)
	return Fine and Controls or nil
end

function Inputs.VehicleSeat(Seat)
	local Adapter = { Active = false }
	function Adapter.Begin()
		Adapter.Active = true
		return true
	end
	function Adapter.Set(Steer, Throttle)
		local Target = type(Seat) == "function" and Seat() or Seat
		if not Target then return end
		pcall(function()
			Target.ThrottleFloat = Throttle
			Target.SteerFloat = Steer
			Target.Throttle = Throttle > 0.1 and 1 or (Throttle < -0.1 and -1 or 0)
			Target.Steer = Steer > 0.1 and 1 or (Steer < -0.1 and -1 or 0)
		end)
	end
	function Adapter.Finish()
		Adapter.Set(0, 0)
		Adapter.Active = false
	end
	return Adapter
end

function Inputs.Callback(Fn)
	local Adapter = { Active = false }
	function Adapter.Begin()
		Adapter.Active = true
		return true
	end
	function Adapter.Set(Steer, Throttle)
		Fn(Steer, Throttle)
	end
	function Adapter.Finish()
		Fn(0, 0)
		Adapter.Active = false
	end
	return Adapter
end

return Inputs
