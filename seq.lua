local mt = {}
mt.__index = mt

mt.current = function(self)
	return self.data[self.cursor]
end

mt.next = function(self, offset)
	offset = offset or 1
	self.cursor = self.cursor + offset
	return self.data[self.cursor]
end

mt.prev = function(self, offset)
	offset = offset or 1
	self.cursor = self.cursor - offset
	return self.data[self.cursor]
end

mt.unget = mt.prev

mt.seek = function(self, offset)
	self.cursor = offset
end

mt.reset = function(self)
	mt.seek(self, 1)
end

mt.iter = function(self, func)
	self:prev()
	return function()
		return self:next()
	end
end

local function array_to_sequence(t)
	local inst = {}
	setmetatable(inst, mt)
	inst.data = t
	inst.count = #t
	inst.cursor = 1
	return inst
end

local util = {
	explode = function(src,sep) -- ref. http://lua-users.org/wiki/SplitJoin
		local result = {}
		local cur = 0
		if (#src == 1) then return {src} end
		while true do
			local i = string.find(src, sep, cur, true)
			if i then
				table.insert(result, src:sub(cur, i-1))
				cur = i + 1
			else
				table.insert(result, src:sub(cur))
				break
			end
		end
		return result
	end
	, load_lines = function(filename)
		local t = {}
		for line in io.lines(filename) do
			table.insert(t, line)
		end
		return t
	end

	, load_text = function(filename)
		return io.open(filename):read'*a'
	end

	, trim = function(s)
	  -- from PiL2 20.4
	  return (s:gsub("^%s*(.-)%s*$", "%1"))
	end
}

local function new_from_file(filename)
	return array_to_sequence(
		util.load_lines(filename)
	)
end
----------------------------------------
return {
	new = array_to_sequence
,	new_from_file = new_from_file
,	util = util
}
