local seq = require'seq'
local strf = string.format
local hmlbuilder = require'luahml_builder'
local luahml = require'luahml'

local function append_chars(hml, para, line, missing_styles)
	local function cook_(str)
		str = str:gsub('&', '&amp;')	
		str = str:gsub('&amp;#(x?[0-9a-fA-F]+);', '&#%1;')	
		str = str:gsub('<', '&lt;')
		str = str:gsub('\t', '<TAB/>')
		return str
	end
	repeat
		local i, j, m = line:find('<!!(.-) +')
		if i then
			if i > 1 then
				para = hml:append_span(para, cook_(line:sub(1, i-1)), '')
			end

			if hml.doc.char_styles[m] == nil then
				missing_styles[m] = true
				m = ''
			end

			local i2, j2, m2 = line:find('!!>')
			if i2 then
				para = hml:append_span(para, cook_(line:sub(j+1, i2-1)), m)
				line = line:sub(j2+1)
			else
				para = hml:append_span(para, cook_(line:sub(i)), '')
				line = ''
			end
		else
			para = hml:append_span(para, cook_(line), '')
			line = ''
		end
	until #line == 0

	return para, missing_styles
end

local function convert(infile, outfile, tplfile)
	local doc_, err = luahml.load(tplfile)
--print(doc_, err); os.exit(-1)
	local hml = hmlbuilder.make_buildable(doc_)
	local lines = seq.new_from_file(infile)
	local missing_styles = {para = {}, char = {} }

	for line in lines:iter() do
		line = line:gsub('^ *', '')
		local para_style = 'Normal'
		local i, j, m = line:find('^](.-) ')
		if i then
			para_style = m
			line = line:sub(j+1)
		end

		if hml.doc.para_styles[para_style] == nil then
			line = '(!!missing style: ' .. para_style .. ')' .. line
			missing_styles.para[para_style] = true
			para_style = 'Normal'
		end

		local para = hml:make_para(para_style)

		para = append_chars(hml, para, line, missing_styles.char)

		hml:append_para(para)
	end
	hml:save(outfile)
	return missing_styles
end

local infile = arg[1] or 'test.txt'
local outfile = arg[2] or 'test.hml'
local tplfile = arg[3] or 'tpl.hml'

local missing_styles = convert(infile, outfile, tplfile)

for k, v in pairs(missing_styles.para) do
	print(k)
end

for k, v in pairs(missing_styles.char) do
	print(k)
end
