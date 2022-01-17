#!/usr/bin/env lua
local os = require 'ext.os'
-- which should I use, _science or not _science?
local url = 'https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes16/l2/data/xrsf-l2-flsum/'
-- https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes16/l2/data/xrsf-l2-flsum/2021/01/dn_xrsf-l2-flsum_g16_d20210101_v2-1-0.nc
--[[ TODO start at todays date and search backwards
for year=2017,2021 do
	for month=1,12 do
		local ms = ('%02d'):format(month)
		for day=1,31 do
			local ds = ('%02d'):format(day)
			local fn = 'dn_xrsf-l2-flsum_g16_d'..year..ms..ds..'_v2-1-0.nc'
			if not os.fileexists(fn) then
				os.execute('cd nc && wget '..url..year..'/'..ms..'/'..fn)
			end
		end
	end
end
--]]
local today = os.date'*t'
for t=os.time{year=today.year, month=today.month, day=today.day},0,-24*60*60 do
	local d = os.date('*t', t)
	local year = d.year
	local ms = ('%02d'):format(d.month)
	local ds = ('%02d'):format(d.day)
	local fn = 'dn_xrsf-l2-flsum_g16_d'..year..ms..ds..'_v2-1-0.nc'
	if os.fileexists('nc/'..fn) then
		print(fn..' exists')
		break
	else
		print(fn..' ... downloading')
		os.execute('cd nc && wget '..url..year..'/'..ms..'/'..fn)
	end
end
