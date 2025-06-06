#!/usr/bin/env lua
local path = require 'ext.path'
local table = require 'ext.table'
-- which should I use, _science or not _science?
-- not _science:
-- ok this was the old url ...
-- https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes16/l2/data/xrsf-l2-flsum/2021/01/dn_xrsf-l2-flsum_g16_d20210101_v2-1-0.nc
-- .. but starting 2023-04-04 they changed allll of them (backlog too) from _v2-1-0.nc to _v2-2-0.nc
--[[ TODO start at todays date and search backwards
local ver = '_v2-1-0'
for year=2017,2021 do
	for month=1,12 do
		local ms = ('%02d'):format(month)
		for day=1,31 do
			local ds = ('%02d'):format(day)
			local fn = 'dn_xrsf-l2-flsum_g16_d'..year..ms..ds..ver..'.nc'
			if not path(fn):exists() then
				assert(os.execute('cd nc && wget '..url..year..'/'..ms..'/'..fn))
			end
		end
	end
end
--]]
local function echo(...)
	print(...)
	return ...
end
local versReversed = {
	'_v2-2-0',
	'_v2-1-0',
}
local today = os.date'*t'
path'nc':mkdir(true)
for t=os.time{year=today.year, month=today.month, day=today.day},0,-24*60*60 do
	-- earliest v2-2-0 is dn_xrsf-l2-flsum_g16_d20190515_v2-2-0.nc
	local d = os.date('*t', t)
	local year = d.year
	local ms = ('%02d'):format(d.month)
	local ds = ('%02d'):format(d.day)

	for _,goes in ipairs{
		'18',	-- goes18 starts up getting xrsf flsum in 2022
		'16',	-- goes16 stopped 2025-04-07
	} do
		for _,ver in ipairs(versReversed) do	-- I forget when goes16 switched to v2.2.0 from v2.1.0
			-- TODO goes16 doesn't have xrsf-l2-flsum anymore,but it's in goes18
			local url = 'https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes'..goes..'/l2/data/xrsf-l2-flsum/'

			-- TODO instead search for *any* file with this timestamp of *any* version
			-- but you only have to take this into account when version suffixes change

			-- TODO with goes18 this is gonna have 'g18'

			local fn = 'dn_xrsf-l2-flsum_g'..goes..'_d'..year..ms..ds..ver..'.nc'
			if path'nc'(fn):exists() then
				print(fn..' exists')
				return
			else
				print(fn..' ... downloading')
				-- TODO break on ctrl-c only
				local result = table.pack(os.execute('cd nc && wget '..url..year..'/'..ms..'/'..fn))
				print(result:unpack())
				if not result[1] then
					if result[3] == 8 then
						-- failed to download, try again
					else
						error(result[2])
					end
				else
					-- succeeded for this day - don't need to try any more versions / goes-#s
					goto done
				end
			end
		end
	end
::done::
end
