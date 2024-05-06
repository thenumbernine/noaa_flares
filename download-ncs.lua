#!/usr/bin/env lua
local path = require 'ext.path'
-- which should I use, _science or not _science?
-- not _science:
local url = 'https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes16/l2/data/xrsf-l2-flsum/'
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
	for _,ver in ipairs(versReversed) do
		-- TODO instead search for *any* file with this timestamp of *any* version
		-- but you only have to take this into account when version suffixes change
		local fn = 'dn_xrsf-l2-flsum_g16_d'..year..ms..ds..ver..'.nc'
		if path'nc'(fn):exists() then
			print(fn..' exists')
			return
		else
			print(fn..' ... downloading')
			--assert(
				os.execute('cd nc && wget '..url..year..'/'..ms..'/'..fn)
			--)
		end
	end
end
