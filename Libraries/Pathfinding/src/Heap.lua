local Heap = {}

function Heap.new()
	local Items, Keys, Size = {}, {}, 0
	local Object = {}

	function Object.Push(Item, Key)
		Size += 1
		local Index = Size
		while Index > 1 do
			local Parent = Index // 2
			local ParentKey = Keys[Parent]
			if ParentKey <= Key then break end
			Items[Index] = Items[Parent]
			Keys[Index] = ParentKey
			Index = Parent
		end
		Items[Index] = Item
		Keys[Index] = Key
	end

	function Object.Pop()
		if Size == 0 then return nil end
		local Top, TopKey = Items[1], Keys[1]
		local LastItem, LastKey = Items[Size], Keys[Size]
		Size -= 1
		if Size > 0 then
			local Index = 1
			while true do
				local Child = Index * 2
				if Child > Size then break end
				local ChildKey = Keys[Child]
				if Child < Size then
					local RightKey = Keys[Child + 1]
					if RightKey < ChildKey then
						Child += 1
						ChildKey = RightKey
					end
				end
				if ChildKey >= LastKey then break end
				Items[Index] = Items[Child]
				Keys[Index] = ChildKey
				Index = Child
			end
			Items[Index] = LastItem
			Keys[Index] = LastKey
		end
		return Top, TopKey
	end

	function Object.Size()
		return Size
	end

	function Object.TopKey()
		return Size > 0 and Keys[1] or nil
	end

	function Object.Clear()
		Size = 0
		table.clear(Items)
		table.clear(Keys)
	end

	return Object
end

return Heap
