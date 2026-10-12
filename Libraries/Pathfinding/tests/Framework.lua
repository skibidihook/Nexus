local Framework = {}

local Passed, Failed = 0, 0

function Framework.Case(Name, Fn)
	local Start = os.clock()
	local Ok, Err = xpcall(Fn, debug.traceback)
	local Ms = (os.clock() - Start) * 1000
	if Ok then
		Passed += 1
		print(string.format("  ok    %-60s %8.2f ms", Name, Ms))
	else
		Failed += 1
		print(`  FAIL  {Name}\n{Err}`)
	end
end

function Framework.True(Value, Message)
	if not Value then error(Message or "expected true", 2) end
end

function Framework.Equal(A, B, Message)
	if A ~= B then error(`{Message or "not equal"}: {A} ~= {B}`, 2) end
end

function Framework.Near(A, B, Tolerance, Message)
	if type(A) ~= "number" or type(B) ~= "number" or math.abs(A - B) > (Tolerance or 1e-6) then
		error(`{Message or "not near"}: {A} vs {B}`, 2)
	end
end

function Framework.Finish(Name)
	print(`{Name}: {Passed} passed, {Failed} failed`)
	if Failed > 0 then error(`{Failed} failure(s) in {Name}`, 0) end
end

return Framework
