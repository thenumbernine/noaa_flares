#!/usr/bin/env luajit
local os = require 'ext.os'
local io = require 'ext.io'
for f in os.listdir'nc' do
	local base, ext = io.getfileext(f)
	assert(ext == 'nc')
	print(base, ext)
	os.execute('../netcdf/test.lua nc/'..f..' > nc_txt/'..base..'.txt')
end
