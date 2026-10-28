local Movers = {}
local HumanoidMover = Require("HumanoidMover")
local KeyboardSteering = Require("KeyboardSteering")

local RunService = game:GetService("RunService")

local function Resolve(Value)
	if type(Value) == "function" then return Value() end
	return Value
end

function Movers.RootOffset(Character)
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	local Root = Character and Character:FindFirstChild("HumanoidRootPart")
	if not (Humanoid and Root) then return 3 end
	if Humanoid.RigType == Enum.HumanoidRigType.R15 then return Humanoid.HipHeight + Root.Size.Y * 0.5 end
	return Root.Size.Y * 0.5 + 2
end

function Movers.Lerp(Options)
	Options = Options or {}
	return function(Points, Handle)
		local Root = Resolve(Options.Root)
		if not (Root and Root.Parent) then return "NoRoot" end
		local Offset = Options.Offset or Movers.RootOffset(Root.Parent)
		local Speed = Options.Speed or 20
		local Current = Root.Position
		for Index = 2, #Points do
			local Target = Points[Index] + Vector3.new(0, Offset, 0)
			local Start = Index == 2 and Current or Points[Index - 1] + Vector3.new(0, Offset, 0)
			local Delta = Target - Start
			local Distance = Delta.Magnitude
			if Distance > 0.05 then
				local Flat = Vector3.new(Delta.X, 0, Delta.Z)
				local Rotation = Flat.Magnitude > 0.1 and CFrame.lookAt(Vector3.zero, Flat).Rotation or Root.CFrame.Rotation
				local Duration = Distance / Resolve(Speed)
				local Elapsed = 0
				while Elapsed < Duration do
					Elapsed += RunService.Heartbeat:Wait()
					if Handle.Status ~= "Running" then return "Cancelled" end
					Root = Resolve(Options.Root)
					if not (Root and Root.Parent) then return "NoRoot" end
					Root.CFrame = CFrame.new(Start:Lerp(Target, math.min(Elapsed / Duration, 1))) * Rotation
					Root.AssemblyLinearVelocity = Vector3.zero
				end
			end
			Handle.Progress = Index
		end
		return "Arrived"
	end
end

function Movers.Humanoid(Options)
    Options = table.clone(Options or {})
    Options.Waiter = Options.Waiter or function() RunService.Heartbeat:Wait() end
    Options.Offset = Options.Offset or function()
        local Humanoid = Resolve(Options.Humanoid)
        return Movers.RootOffset(Humanoid and Humanoid.Parent)
    end
    return function(Points, Handle)
        local Direction = Vector3.zero
        local Humanoid = Resolve(Options.Humanoid)
        local Connection
        Connection = RunService.PreSimulation:Connect(function()
            if Handle.Status ~= "Running" or not (Humanoid and Humanoid.Parent and Humanoid.Health > 0) then
                Connection:Disconnect()
                if Humanoid and Humanoid.Parent then Humanoid:Move(Vector3.zero, false) end
                return
            end
            if Humanoid.Parent:GetAttribute("Hiding") or Humanoid.Parent:GetAttribute("IsInjured") then
                Humanoid:Move(Vector3.zero, false)
                return
            end
            Humanoid:Move(Direction, false)
        end)
        local Settings = table.clone(Options)
        Settings.Actions = Settings.Actions or (Handle.Path and Handle.Path.Points == Points and Handle.Path.Actions)
        Settings.Jump = Settings.Jump or function(Body) Body.Jump = true end
        Settings.ApplyMove = function(Body, Value) Direction = Value; Body:Move(Value, false) end
        local Ok, Outcome = pcall(HumanoidMover(Settings), Points, Handle)
        Connection:Disconnect()
        if Humanoid and Humanoid.Parent then Humanoid:Move(Vector3.zero, false) end
        if not Ok then error(Outcome, 0) end
        return Outcome
    end
end

function Movers.Callback(Fn)
	return function(Points, Handle)
		return Fn(Points, Handle) or "Arrived"
	end
end

function Movers.Keyboard(Options)
    Options = table.clone(Options or {})
    local Input = Options.Input or game:GetService("VirtualInputManager")
    Options.Waiter = Options.Waiter or function() RunService.Heartbeat:Wait() end
    Options.Offset = Options.Offset or function()
        local Humanoid = Resolve(Options.Humanoid)
        return Movers.RootOffset(Humanoid and Humanoid.Parent)
    end
    return function(Points, Handle)
        local Held = {}
        local function SetKeys(Keys)
            for _, Name in next, { "W", "A", "S", "D" } do
                local Down = Keys[Name] == true
                if Down ~= (Held[Name] == true) then
                    Input:SendKeyEvent(Down, Enum.KeyCode[Name], false, game)
                    Held[Name] = Down
                end
            end
        end
        local Connection
        local function Release()
            SetKeys({})
            if Held.Space then Input:SendKeyEvent(false, Enum.KeyCode.Space, false, game); Held.Space = false end
        end
        Connection = RunService.Heartbeat:Connect(function()
            if Handle.Status ~= "Running" then
                pcall(Release)
                Connection:Disconnect()
            end
        end)
        local Settings = table.clone(Options)
        Settings.Actions = Settings.Actions or (Handle.Path and Handle.Path.Points == Points and Handle.Path.Actions)
        Settings.Jump = Settings.Jump or function()
            Held.Space = true
            Input:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.delay(0.1, function()
                if Held.Space then pcall(Input.SendKeyEvent, Input, false, Enum.KeyCode.Space, false, game); Held.Space = false end
            end)
        end
        Settings.ApplyMove = function(Body, Direction)
            local Camera = workspace.CurrentCamera
            if not Camera or Body.Parent:GetAttribute("Hiding") or Body.Parent:GetAttribute("IsInjured") then SetKeys({}); return end
            SetKeys(KeyboardSteering.Keys(Direction, Camera.CFrame.LookVector, Camera.CFrame.RightVector))
        end
        local Ok, Outcome = pcall(HumanoidMover(Settings), Points, Handle)
        Connection:Disconnect()
        local Released, ReleaseError = pcall(Release)
        if not Ok then error(Outcome, 0) end
        if not Released then error(ReleaseError, 0) end
        return Outcome
    end
end

return Movers
