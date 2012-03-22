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
	local stack = {''}
	repeat
		local i = line:find('[<!]')
		if i == nil then 
			para = hml:append_span(para, cook_(line), prev_style)
			return para, missing_styles
		end

		local j, k, m = line:find('^<!!(.-) +', i)
		if j then
			if j > 1 then 
				para = hml:append_span(para, cook_(line:sub(1, j-1)), stack[#stack])
			end

			line = line:sub(k+1)

			if hml.doc.char_styles[m] == nil then
				missing_styles[m] = true
				m = ''
			end
			stack[#stack+1] = m
		else
			j, k = line:find('^!!>', i)
			if j then
				para = hml:append_span(para, cook_(line:sub(1, j-1)), stack[#stack])
				table.remove(stack)
				if #stack == 0 then stack[1] = '' end
				line = line:sub(k+1)
			else
				para = hml:append_span(para, cook_(line:sub(1, i)), stack[#stack])
				line = line:sub(i+1)
			end
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

print('missing styles:')
for k, v in pairs(missing_styles.para) do
	print(k)
end

for k, v in pairs(missing_styles.char) do
	print(k)
end
