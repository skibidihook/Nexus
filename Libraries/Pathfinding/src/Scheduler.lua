local Scheduler = {}
Scheduler.__index = Scheduler

local Request = {}
Request.__index = Request

local Huge = math.huge

function Scheduler.new(Options)
	Options = Options or {}
	return setmetatable({
		Jobs = {},
		Budget = Options.Budget or 0.002,
		Clock = Options.Clock or os.clock,
		Waiter = Options.Waiter,
		Deadline = Huge,
		Turn = 0,
	}, Scheduler)
end

function Scheduler:Spawn(Fn, Timeout)
	local Job = setmetatable({
		Status = "Running",
		Scheduler = self,
		Started = self.Clock(),
		Timeout = Timeout,
		Cpu = 0,
		Slices = 0,
	}, Request)
	Job.Thread = coroutine.create(function()
		local Ok, Result = pcall(Fn, Job)
		if Job.Status ~= "Running" then return end
		if Ok then
			Job.Result = Result
			Job.Status = "Done"
		else
			Job.Error = Result
			Job.Status = "Failed"
		end
	end)
	Job.Yield = function()
		return Job:Check()
	end
	self.Jobs[#self.Jobs + 1] = Job
	return Job
end

function Scheduler:Step(Budget)
	local Jobs = self.Jobs
	local Count = #Jobs
	if Count == 0 then return end
	local Clock = self.Clock
	local Began = Clock()
	if not Budget then
		Budget = self.Budget
		for Index = 1, Count do
			local Wanted = Jobs[Index].Budget
			if Wanted and Wanted > Budget and Jobs[Index].Status == "Running" then Budget = Wanted end
		end
	end
	local Deadline = Began + Budget
	self.Turn = self.Turn % Count + 1
	local First = self.Turn
	for Offset = 0, Count - 1 do
		local Job = Jobs[(First + Offset - 1) % Count + 1]
		if Job.Status == "Running" then
			local Now = Clock()
			if Now >= Deadline then break end
			self.Deadline = Now + (Deadline - Now) / (Count - Offset)
			local Ok, Err = coroutine.resume(Job.Thread)
			Job.Cpu += Clock() - Now
			Job.Slices += 1
			if not Ok and Job.Status == "Running" then
				Job.Error = Err
				Job.Status = "Failed"
			end
		end
	end
	self.Deadline = Huge
	local Spent = Clock() - Began
	self.LastStep = Spent
	if Spent > (self.MaxStep or 0) then self.MaxStep = Spent end
	local Write = 0
	for Read = 1, #Jobs do
		local Job = Jobs[Read]
		if Job.Status == "Running" then
			Write += 1
			Jobs[Write] = Job
		end
	end
	for Index = #Jobs, Write + 1, -1 do Jobs[Index] = nil end
end

function Scheduler:Cancel()
	for _, Job in next, self.Jobs do Job:Cancel() end
	table.clear(self.Jobs)
end

function Request:Check()
	if self.Status ~= "Running" then return false end
	local Owner = self.Scheduler
	local Clock = Owner.Clock
	if Clock() >= Owner.Deadline then
		coroutine.yield()
		if self.Status ~= "Running" then return false end
	end
	if self.Timeout and Clock() - self.Started > self.Timeout then
		self.TimedOut = true
		return false
	end
	return true
end

function Request:Cancel()
	if self.Status == "Running" then self.Status = "Cancelled" end
end

function Request:IsDone()
	return self.Status ~= "Running"
end

function Request:Await(Timeout)
	local Owner = self.Scheduler
	local Clock = Owner.Clock
	local Limit = Timeout and Clock() + Timeout or Huge
	local Waiter = Owner.Waiter
	while self.Status == "Running" do
		if Clock() > Limit then
			self:Cancel()
			return nil, "Timeout"
		end
		if Waiter then
			Waiter()
		else
			Owner:Step(Huge)
		end
	end
	return self.Result, self.Status, self.Error
end

Scheduler.Request = Request

return Scheduler
