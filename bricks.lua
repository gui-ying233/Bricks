local Bricks = { version = "0.0.1" }

local _voidElems = {
	area = true,
	base = true,
	br = true,
	col = true,
	embed = true,
	hr = true,
	img = true,
	input = true,
	link = true,
	meta = true,
	param = true,
	source = true,
	track = true,
	wbr = true,
}

local _attr = {
	attributes = true,
	id = true,
	classList = true,
	className = true,
	style = true,
	dataset = true,
	children = true,
	parentElement = true,
}
local function escape(s)
	return s:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

local function split(s, sep)
	local t = {}
	if not sep or sep == "" then
		for j = 1, #s do
			t[j] = s:sub(j, j)
		end
		return t
	end
	local i = 1
	while i <= #s do
		local j = s:find(sep, i, true)
		if not j then
			t[#t + 1] = s:sub(i)
			break
		end
		t[#t + 1] = s:sub(i, j - 1)
		i = j + #sep
	end
	return t
end

local function isEmpty(s)
	return not s or s:match("^%s*$")
end

function Bricks:new(raw)
	local o
	if type(raw) == "string" then
		o = { raw = raw }
	elseif type(raw) == "table" then
		o = raw
	else
		error("Uncaught TypeError: raw must be a string or a table")
	end
	setmetatable(o, {
		__index = function(s, k)
			if _attr[k] and s["_" .. k] then
				return s["_" .. k]
			elseif _attr[k] then
				return s["__get" .. k:sub(1, 1):upper() .. k:sub(2)](s)
			else
				return Bricks[k]
			end
		end
	})
	return o
end

function Bricks:__getElementByTagName(tagName)
	if isEmpty(tagName) then
		return nil
	elseif self.outerHTML then
		return nil
	end
	local r = self.innerHTML or self.raw
	local c = r:find("<!--", 1, true)
	local i = r:find("<" .. tagName .. "[%s>]")
	if c and c < i then
		i = r:find("<" .. tagName .. "[%s>]", r:find("-->", c, true) + 3)
	end
	local s = i
	local b = 0
	local m
	while i and i <= #r do
		if r:sub(i, i + #tagName) == "<" .. tagName then
			if _voidElems[tagName] then
				self.tagName = tagName:upper()
				self._index = s
				self.outerHTML = r:sub(s, r:find(">", i))
				self.innerHTML = ""
				return self
			end
			m = r:sub(i + #tagName, i + #tagName)
			b = b + 1
		elseif r:sub(i, i + #tagName + 2):find("</" .. escape(tagName) .. "[%s>]") then
			if b == 1 and s then
				self.tagName = tagName:upper()
				self._index = s
				self.outerHTML = r:sub(s, i + #tagName + 2)
				self.innerHTML = self.outerHTML:match("^<" .. tagName .. ".->(.*)</" .. tagName .. ">$")
				return self
			elseif b > 1 then
				b = b - 1
				m = r:sub(i + #tagName + 2, i + #tagName + 2)
			end
		end
		if ("</" .. tagName):find(m, 1, true) then
			i = i + #tagName
		else
			i = i + 1
		end
		c = r:find("<!--", i, true)
		i = r:find("</?" .. tagName, i)
		if c and c < i then
			i = r:find("</?" .. tagName, r:find("-->", c, true) + 3)
		end
	end
	return nil
end

function Bricks:getElementsByTagName(tagName)
	if isEmpty(tagName) then
		return nil
	end
	local l = {}
	local r = self.innerHTML or self.raw
	local i = 1
	while i < #r - #tagName do
		local e = Bricks:new(r:sub(i)):__getElementByTagName(tagName:lower())
		if not e then
			break
		end
		i = i + e._index
		e.raw = self.raw
		l[#l + 1] = e
	end
	return l
end

function Bricks:getElementById(id)
	if isEmpty(id) then
		return nil
	elseif self.outerHTML then
		return { self }
	end
	local r = self.innerHTML or self.raw
	local i = r:find("<[^/][^>]-%s+[^>]*[iI][dD]%s*=(['\"])%s*" .. escape(id) .. "%s*%1")
	while i and i <= #r - #id - 13 do
		local t = r:match("<([^/][^>]-)%s+[^>]*[iI][dD]%s*=(['\"])%s*" .. escape(id) .. "%s*%2", i)
		local e = Bricks:new(r:sub(i)):__getElementByTagName(t)
		e.raw = self.raw
		if e and e.id == id then
			return e
		end
		i = r:find("<[^/][^>]-%s+[^>]*[iI][dD]%s*=(['\"])%s*" .. escape(id) .. "%s*%1", i + 1)
	end
	return nil
end

function Bricks:getElementsByClassName(classNames)
	if isEmpty(classNames) then
		return nil
	elseif self.outerHTML then
		return { self }
	end
	local l = {}
	local r = self.innerHTML or self.raw
	classNames = classNames:gsub("%s+", " ")
	local f = split(escape(classNames), " ")[1]
	local i = r:find("<[^/][^>]-%s+[^>]*[cC][lL][aA][sS][sS]%s*=(['\"])[^%1]-" .. f .. "[^%1]-[%s\"]")
	while i and i <= #r - #classNames - 16 do
		local t = r:match(
			"<([^/][^>]-)%s+[^>]*[cC][lL][aA][sS][sS]%s*=(['\"])[^%2]-" .. f .. "[^%2]-%2",
			i)
		local e = Bricks:new(r:sub(i)):__getElementByTagName(t)
		if e then
			local m = { [" "] = {} }
			for _, v in ipairs(e.classList) do
				for _, w in ipairs(split(classNames, " ")) do
					if v == w and not m[v] then
						m[v] = true
						m[" "][#m[" "] + 1] = v
					end
					if #m[" "] == #split(classNames, " ") then
						e.raw = self.raw
						l[#l + 1] = e
						break
					end
				end
				if #m[" "] == #split(classNames, " ") then
					break
				end
			end
		end
		i = r:find(
			"<[^/][^>]-%s+[^>]*[cC][lL][aA][sS][sS]%s*=(['\"])%s*[^%1]-" .. f .. "[^%1]-%1",
			i + 1)
	end
	return l
end

function Bricks:__getAttributes()
	local a = {}
	local r = self.outerHTML:match("<" .. self.tagName:lower() .. "%s+(.-)>")
	if not r then
		return a
	end
	local i = 1
	local k = ""
	local v = ""
	local q = ""
	while i <= #r do
		local c = r:sub(i, i)
		if (c == '"' or c == "'" and q == "") or (c == q and q ~= "") then
			q = q == "" and c or ""
		elseif c == " " and q == "" then
			if k ~= "" then
				if not a[k] then
					a[k] = v
				end
				k = ""
				v = ""
			elseif v ~= "" and not a[v:lower()] then
				a[v:lower()] = true
				v = ""
			end
		elseif c == "=" and q == "" then
			k = v:lower()
			v = ""
		else
			v = v .. c
		end
		i = i + 1
	end
	if k ~= "" and not a[k] then
		a[k] = v
	elseif v ~= "" and not a[v:lower()] then
		a[v:lower()] = true
	end
	self._attributes = a
	return a
end

function Bricks:getAttribute(name)
	if isEmpty(name) then
		return nil
	elseif not self._attributes then
		self._attributes = self:__getAttributes()
	end
	return self._attributes[name:lower()]
end

function Bricks:__getId()
	self._id = self:getAttribute("id")
	return self._id
end

function Bricks:__getClassList()
	local c = self:getAttribute("class")
	local l = {}
	if not c then
		return l
	end
	local i = 1
	local s = ""
	while i <= #c do
		local x = c:sub(i, i)
		if x:match("%s") then
			if s ~= "" then
				l[#l + 1] = s
				s = ""
			end
		else
			s = s .. x
		end
		i = i + 1
	end
	if s ~= "" then
		l[#l + 1] = s
	end
	self._classList = l
	return l
end

function Bricks:__getClassName()
	self._className = table.concat(self.classList, " ")
	return self._className
end

function Bricks:__getStyle()
	local s = self:getAttribute("style")
	local c = {}
	if not s then
		return c
	end
	local i = 1
	local k = ""
	local v = ""
	local q = ""
	while i <= #s do
		local x = s:sub(i, i)
		if (x == '"' or x == "'" and q == "") or (x == q and q ~= "") then
			q = q == "" and x or ""
			v = v .. x
		elseif x == ";" and q == "" then
			if k ~= "" then
				c[k] = v:match("^%s*(.-)%s*$")
				k = ""
				v = ""
			end
		elseif x == ":" and q == "" then
			if v:match("-") then
				local l, r = v:match("(.+)-(.+)")
				v = l:lower() .. r:sub(1, 1):upper() .. r:sub(2)
			end
			k = v:match("^%s*(.-)%s*$")
			v = ""
		else
			v = v .. x
		end
		i = i + 1
	end
	c.cssText = (function()
		local t = {}
		for a, b in pairs(c) do
			if a:match("[A-Z]") then
				local l, r = a:match("(.+)([A-Z].+)")
				t[#t + 1] = l:lower() .. "-" .. r:lower() .. ": " .. b
			else
				t[#t + 1] = a .. ": " .. b
			end
		end
		return table.concat(t, "; ") .. ";"
	end)()
	self._style = c
	return c
end

function Bricks:__getDataset()
	local d = {}
	local a = self._attributes
	for k, v in pairs(a) do
		if k:match("^data%-") then
			d[k:match("^data%-(.+)")] = v
		end
	end
	self._dataset = d
	return d
end

function Bricks:__getChildren()
	local l = {}
	local r = self.innerHTML or self.raw
	local i = r:find("<[^/>]")
	local b = 0
	local s = i
	while i and i <= #r do
		local t = r:match("<([^>]-)[%s>]", i)
		if t:sub(1, 1) == "/" then
			if b == 1 then
				local e = Bricks:new(r:sub(s, i + #t + 2)):__getElementByTagName(t:sub(2))
				e.raw = self.raw
				l[#l + 1] = e
				s = r:find("<[^/>]", i)
			end
			b = b - 1
		else
			if _voidElems[t:lower()] then
				if b == 0 then
					local e = Bricks:new(r:sub(s, r:find(">", i))):__getElementByTagName(t)
					e.raw = self.raw
					l[#l + 1] = e
					s = r:find("<[^/>]", i)
				end
			else
				b = b + 1
			end
		end
		i = r:find("<[^>]", i + 1)
	end
	self._children = l
	return l
end

function Bricks:__getParentElement()
	local o = self.outerHTML
	if not o then
		return nil
	end
	local r = self.raw
	local i, j = r:find(o, self._index, true)
	local l = r:sub(1, i - 1)
	local u = {}
	local f = l:find("<[^/>]-[%s>]")
	while f and f <= i do
		local t = l:match("<([^>]-)[%s>]", f)
		if t:sub(1, 1) ~= "/" and not _voidElems[t:lower()] then
			u[#u + 1] = { t, f }
		elseif u[#u][1] == t:sub(2) then
			u[#u] = nil
		end
		f = l:find("<[^>]-[%s>]", f + 1)
	end
	if #u == 0 then
		return nil
	end
	local m = r:sub(j + 1)
	f = m:find("</?%s*" .. escape(u[#u][1]) .. "[%s>]")
	local b = 0
	while f and f <= #m do
		local t = m:match("<(/?%s*" .. escape(u[#u][1]) .. ")[%s>]", f)
		if t:sub(1, 1) == "/" then
			if b == 0 then
				break
			end
			b = b - 1
		elseif not _voidElems[t:lower()] then
			b = b + 1
		end
		f = m:find("</?%s*" .. escape(u[#u][1]) .. "[%s>]", f + 1)
	end
	if not f then
		return nil
	end
	local e = Bricks:new(l:sub(u[#u][2]) .. o .. m:sub(1, f + #u[#u][1] + 2)):__getElementByTagName(u[#u][1])
	e.raw = self.raw
	self._parentElement = e
	return e
end

return Bricks
