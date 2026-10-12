local Task = {}
Task.__index = Task

function Task.new(Clock, Waiter)
	return setmetatable({ Status = "Running", Clock = Clock or os.clock, Waiter = Waiter }, Task)
end

function Task:Cancel()
	if self.Status == "Running" then self.Status = "Cancelled" end
	local Inner = self.Inner
	if Inner and Inner.Cancel then Inner:Cancel() end
end

function Task:IsDone()
	return self.Status ~= "Running"
end

function Task:Finish(Status, Result, Err)
	if self.Status ~= "Running" then return end
	self.Result = Result
	self.Error = Err
	self.Status = Status
end

function Task:Await(Timeout)
	local Clock = self.Clock
	local Limit = Timeout and Clock() + Timeout or math.huge
	while self.Status == "Running" do
		if Clock() > Limit then
			self:Cancel()
			return nil, "Timeout"
		end
		self.Waiter()
	end
	return self.Result, self.Status, self.Error
end

return Task
