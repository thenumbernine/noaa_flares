#!/usr/bin/env luajit
require 'ext'

local magkeys = table{'A', 'B', 'C', 'M', 'X'}
local isvalid = magkeys:mapi(function(v,k) return k,v end):setmetatable(nil)
local totalFlareLevel = 1

local secondsPerDay = 60 * 60 * 24
local synodicMonth = 29.530	-- days for the moon to orbit the Earth relative to Sun

local magsPerMoonDay = {}
local magsPerUniqueDay = {}
local magsPerMonth = {}
local magsPerYear = {}
local allFlaresPerMonth = {}

local fs = table()
for f in path'nc_txt':dir() do
	fs:insert(f.path)
end
fs:sort()
for _,f in ipairs(fs) do
	if select(2, path(f):getext()) == 'txt' then
	--print('f', f)
		local year, month
		local filetype
		local y,m,d,ver = f:match'^dn_xrsf%-l2%-flsum_g16_d(%d%d%d%d)(%d%d)(%d%d)_v(%d%-%d%-%d)%.txt$'
	--print(y,m,d)
		local yearAndMonth
		local uniqueDay
		local moonDay
		if y then
			filetype = 'dn'
			year = y
			month = m
			yearAndMonth = month-1 + 12 * year
			local dayTime = os.time{year=year, month=month, day=d} / secondsPerDay
			uniqueDay = math.floor(dayTime) 	-- TODO use julian day
			moonDay = math.floor(uniqueDay % synodicMonth)
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
						if uniqueDay then
							magsPerUniqueDay[uniqueDay] = magsPerUniqueDay[uniqueDay] or {}
							magsPerUniqueDay[uniqueDay][x] = (magsPerUniqueDay[uniqueDay][x] or 0) + 1
						end
						if moonDay then
							magsPerMoonDay[moonDay] = magsPerMoonDay[moonDay] or {}
							magsPerMoonDay[moonDay][x] = (magsPerMoonDay[moonDay][x] or 0) + 1
						end
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
					local d = l:sub(10,11)
					local day = assert(tonumber(d))
					local dayTime = (
						os.time{year=year, month=month, day=day}
						or error("failed to get os.time() for "..tolua{year=y2, month=month, day=day})
					) / secondsPerDay
					uniqueDay = math.floor(dayTime) 	-- TODO use julian day
					local synodicMonth = 29.530	-- days for the moon to orbit the Earth relative to Sun
					moonDay = math.floor(uniqueDay % synodicMonth)
					-- lots of spaces within the values, values are strings, can't really tell where columns end
					-- i'll just hope they are at the same indentation ...
					x = l:sub(60,60)
					assert(x)
					if not isvalid[x] then
						io.stderr:write('file: '..f..' line: '..line..' col 60 is '..('%q'):format(x)..'\n')
					else
--print(x)
						if uniqueDay then
							magsPerUniqueDay[uniqueDay] = magsPerUniqueDay[uniqueDay] or {}
							magsPerUniqueDay[uniqueDay][x] = (magsPerUniqueDay[uniqueDay][x] or 0) + 1
						end
						if moonDay then
							magsPerMoonDay[moonDay] = magsPerMoonDay[moonDay] or {}
							magsPerMoonDay[moonDay][x] = (magsPerMoonDay[moonDay][x] or 0) + 1
						end
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

local f = path'flares-per-type-per-unique-day.txt':open'w'
f:write('# day A B C M X\n')
for _,i in ipairs(table.keys(magsPerUniqueDay):sort()) do
	local row = magsPerUniqueDay[i]
	f:write(
		i,--('%d'):format(i), 	-- TODO convert with os.time to a day or something
		'\t')
	for _,k in ipairs(magkeys) do
		f:write('\t', row and row[k] or 0)
	end
	f:write'\n'
end
f:close()

print'magsPerMoonDay'
print(tolua(magsPerMoonDay))

local f = path'flares-per-type-per-moon-day.txt':open'w'
f:write('# day A B C M X\n')
for _,i in ipairs(table.keys(magsPerMoonDay):sort()) do
	local row = magsPerMoonDay[i]
	f:write(
		i,--('%d'):format(i), 	-- TODO convert with os.time to a day or something
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

print('current moon phase day:', (os.time() / secondsPerDay) % synodicMonth)

f:close()
