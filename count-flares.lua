#!/usr/bin/env luajit
require 'ext'

local magkeys = table{'A', 'B', 'C', 'M', 'X'}
local isvalid = magkeys:mapi(function(v,k) return k,v end):setmetatable(nil)
local totalFlareLevel = 1

local magsPerYear = {}
local allFlaresPerMonth = {}

for f in file'nc_txt':dir() do
--print('f', f)
	local year, month
	local filetype
	local y,m,d = f:match'^dn_xrsf%-l2%-flsum_g16_d(%d%d%d%d)(%d%d)(%d%d)_v2%-1%-0%.txt$'
--print(y,m,d)
	local yearAndMonth
	if y then
		filetype = 'dn'
		year = y
		month = m
		yearAndMonth = month-1 + 12 * year
	else
		year = f:match'^goes%-xrs%-report_(%d%d%d%d).*%.txt$'
		if year then
			filetype = 'report'
		end
	end
	assert(year)
	assert(filetype)
	magsPerYear[year] = magsPerYear[year] or {}
	local line = 1
	for l in io.lines('nc_txt/'..f) do
		if #l == 0
		or (#l == 1 and l:byte() == 0x1a)
		then
		else
			local x
			if filetype == 'dn' then
				local w = l:split'%s+'
				if w[3] == 'EVENT_PEAK' then
					x = w[6]:sub(1,1)
					assert(x)
					assert(isvalid[x])
	--print(x)
					magsPerYear[year][x] = (magsPerYear[year][x] or 0) + 1
					if isvalid[x] >= totalFlareLevel then
						allFlaresPerMonth[yearAndMonth] = (allFlaresPerMonth[yearAndMonth] or 0) + 1
					end
				end
			elseif filetype == 'report' then
				local y2 = l:sub(6,7)
				y2 = tonumber(y2) or error(f..":"..line..": couldn't convert year to number: "..y2.." for line: "..l:hexdump())
				if y2 ~= year % 100 then
					error("filename says year is "..year.." but column says year is "..y2)
				end
				local m = l:sub(8,9)
				local month = assert(tonumber(m))
				yearAndMonth = month-1 + 12 * year
				--local d = l:sub(10,11)
				-- lots of spaces within the values, values are strings, can't really tell where columns end
				-- i'll just hope they are at the same indentation ...
				x = l:sub(60,60)
				assert(x)
				if not isvalid[x] then
	io.stderr:write('file: '..f..' line: '..line..' col 60 is '..('%q'):format(x)..'\n')
				else
	--print(x)
					magsPerYear[year][x] = (magsPerYear[year][x] or 0) + 1
					if isvalid[x] >= totalFlareLevel then
						allFlaresPerMonth[yearAndMonth] = (allFlaresPerMonth[yearAndMonth] or 0) + 1
					end
				end
			end
		end
		line = line + 1 
	end
--	do break end
end

local f = file'flares.txt':open'w'
f:write('# year A B C M X\n')
for y=1975,2022 do
	local row = magsPerYear[''..y] or {}
	f:write(y)
	for _,k in ipairs(magkeys) do
		f:write('\t', row[k] or 0)
	end
	f:write'\n'
end
f:close()
--print(tolua(magsPerYear))

local f = file'totalflares-per-month.txt':open'w'
f:write'# year-month\n'
for i=table.inf(table.keys(allFlaresPerMonth)),table.sup(table.keys(allFlaresPerMonth)) do
	f:write(
		('%04d-%02d'):format(i/12, i%12+1), 
		'\t', 
		allFlaresPerMonth[i] or 0, 
		'\n'
	)
end
f:close()
