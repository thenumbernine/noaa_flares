#!/usr/bin/env luajit
local os = require 'ext.os'
local file = require 'ext.file'
for f in file'nc':dir() do
	local base, ext = file(f):getext()
	assert(ext == 'nc')
	--io.write(base, ' ', ext)
	local dst = 'nc_txt/'..base..'.txt'
	io.write(dst)
	if file(dst):exists() then	-- TODO check timestamp?
		print(' ... exists')
	else
		os.execute('../netcdf/test.lua nc/'..f..' > '..dst)
		print(' ... done')
	end
end
