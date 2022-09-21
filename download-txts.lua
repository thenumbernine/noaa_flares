#!/usr/bin/env lua
local file = require 'ext.file'
file'txt':mkdir(true)
local url = 'https://www.ngdc.noaa.gov/stp/space-weather/solar-data/solar-features/solar-flares/x-rays/goes/xrs/'
for year=1975,2016 do
	os.execute('cd txt && wget '..url..'goes-xrs-report_'..year..'.txt')
end
os.execute('cd txt && wget '..url..'goes-xrs-report_2015_modifiedreplacedmissingrows.txt')
os.execute('cd txt && wget '..url..'goes-xrs-report_2017-input-ytd.txt')
os.execute('cd txt && wget '..url..'goes-xrs-report_2017-ytd.txt')
