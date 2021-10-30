#!/usr/bin/env luajit
--[[
trying to follow http://web.mit.edu/fwtools_v3.1.0/www/H5.intro.html
--]]
local hdf5 = require 'ffi.hdf5'
local class = require 'ext.class'
local ffi = require 'ffi'

ffi.cdef[[
typedef struct hdf5_file_hid_t {
	hid_t hid;
} hdf5_file_hid_t;
]]
local hdf5_file_hid_t = ffi.metatype('hdf5_file_hid_t', {
	__gc = function(self)
		if self.hid > 0 then
			hdf5.H5Fclose(self.hid)
			self.hid = 0
		end
	end,
})



local HDF5 = class()

function HDF5:init(args)
	if args.filename then
		local mode = args.mode or hdf5.H5F_ACC_RDONLY
		local access = args.access or hdf5.H5P_DEFAULT
		self.hid = hdf5.H5Fopen(args.filename, mode, access)
		if self.hid < 0 then
			hdf5.H5Eerror(ffi.C.stderr)
			os.exit(1)
		end
		self.hidPtr = hdf5_file_hid_t()
		self.hidPtr.hid = self.hid
	end
end

--function HDF5:

local hobj = HDF5{filename=fn}
print(hobj)
