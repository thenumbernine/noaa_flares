#!/usr/bin/env luajit
local os = require 'ext.os'
local file = require 'ext.file'
local table = require 'ext.table'
local fs = table()
for f in file'nc':dir() do
	fs:insert(f)
end
fs:sort()
for _,f in ipairs(fs) do
	local base, ext = file(f):getext()
	if ext ~= 'nc' then
		io.stderr:write("found file "..tostring(f).." with extension "..tostring(ext)..'\n')
	else
		--io.write(base, ' ', ext)
		local dst = 'nc_txt/'..base..'.txt'
		io.write(dst)
		if file(dst):exists()
		and file(dst):attr().size > 0
		then	-- TODO check timestamp?
			print(' ... exists')
		else
			os.execute('../netcdf/test.lua nc/'..f..' > '..dst)
			print(' ... done')
		end
	end
end
