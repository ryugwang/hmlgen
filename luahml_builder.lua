local xselec = require'xselec' -- see https://github.com/ryugwang/xselec
local luahml = require'luahml' -- see https://github.com/ryugwang/luahml
local strf = string.format

local function make_para(self, para_style_name)
	local para_style = self.doc.para_styles[para_style_name]
	local xml = strf([[<P ParaShape="%s" Style="%s"></P>]]
		, para_style.ParaShape, para_style.Id
	)
	local node = xselec.load_from_string(xml)
	return node
end

local function append_span(self, p, str, char_style_name)
	local para_style = self.doc.para_styles[p.attr.Style]
	local char_style = self.doc.char_styles[char_style_name]

	local char_style_str = ''
	local char_shape = para_style.CharShape
	if char_style then
		char_style_str = strf([[ Style="%s"]], char_style.Id)
		char_shape = char_style.CharShape
	end

	local xml, err = strf([[<TEXT CharShape="%s"><CHAR%s>%s</CHAR></TEXT>]]
		, char_shape, char_style_str, str
	)
	table.insert(p, xselec.load_from_string(xml))
	return p
end

local function append_para(self, p)
	table.insert(self.last_section, p)
end

local function make_buildable(doc)
	local t = { doc = doc}
	t.make_para = make_para
	t.append_span = append_span
	t.append_para = append_para
	t.save = function(self, filename) self.doc:save(filename) end
	t.output = function(self, puts) self.doc:output(puts) end
	
	local sections = doc.node'BODY>SECTION'
	t.last_section = sections[#sections]
	
	return t
end

return {
	make_buildable = make_buildable
}
