#!/usr/bin/env luajit
require 'ext'

local magkeys = table{'A', 'B', 'C', 'M', 'X'}
local isvalid = magkeys:mapi(function(v,k) return k,v end):setmetatable(nil)
local totalFlareLevel = 1

local magsPerMonth = {}
local magsPerYear = {}
local allFlaresPerMonth = {}

local fs = table()
for f in path'nc_txt':dir() do
	fs:insert(f.path)
end
fs:sort()
for _,f in ipairs(fs) do
--print('f', f)
	local year, month
	local filetype
	local y,m,d,ver = f:match'^dn_xrsf%-l2%-flsum_g16_d(%d%d%d%d)(%d%d)(%d%d)_v(%d%-%d%-%d)%.txt$'
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
	--magsPerMonth[yearAndMonth] = magsPerMonth[yearAndMonth] or {}
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
					magsPerMonth[yearAndMonth] = magsPerMonth[yearAndMonth] or {}
					magsPerMonth[yearAndMonth][x] = (magsPerMonth[yearAndMonth][x] or 0) + 1
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
					magsPerMonth[yearAndMonth] = magsPerMonth[yearAndMonth] or {}
					magsPerMonth[yearAndMonth][x] = (magsPerMonth[yearAndMonth][x] or 0) + 1
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

local f = path'flares-per-type-per-year.txt':open'w'
f:write('# year A B C M X\n')
for y=1975,os.date'*t'.year do
	local row = magsPerYear[''..y] or {}
	f:write(y)
	for _,k in ipairs(magkeys) do
		f:write('\t', row[k] or 0)
	end
	f:write'\n'
end
f:close()
--print(tolua(magsPerYear))

local allMonths = table.keys(allFlaresPerMonth):sort()
local f = path'flares-per-type-per-month.txt':open'w'
f:write('# month A B C M X\n')
for i=allMonths[1],allMonths:last() do
	local row = magsPerMonth[i]
	f:write(
		('%04d-%02d'):format(i/12, i%12+1), 
		'\t')
	for _,k in ipairs(magkeys) do
		f:write('\t', row and row[k] or 0)
	end
	f:write'\n'
end
f:close()

local f = path'totalflares-per-month.txt':open'w'
f:write'# year-month\n'
for i=allMonths[1],allMonths:last() do
	f:write(
		('%04d-%02d'):format(i/12, i%12+1), 
		'\t', 
		allFlaresPerMonth[i] or 0, 
		'\n'
	)
end
f:close()
