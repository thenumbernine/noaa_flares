#!/usr/bin/env luajit
local os = require 'ext.os'
local path = require 'ext.path'
local table = require 'ext.table'
local fs = table()
for f in path'nc':dir() do
	fs:insert(f)
end
fs:sort()
for _,f in ipairs(fs) do
	local base, ext = path(f):getext()
	if ext ~= 'nc' then
		io.stderr:write("found file "..tostring(f).." with extension "..tostring(ext)..'\n')
	else
		--io.write(base, ' ', ext)
		local dst = path'nc_txt'/(base..'.txt')
		io.write(dst.path)
		if dst:exists()
		and dst:attr().size > 0
		then	-- TODO check timestamp?
			print(' ... exists')
		else
			os.execute('../netcdf/test.lua nc/'..f..' > '..dst:escape())
			print(' ... done')
		end
	end
end
